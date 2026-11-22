import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/features/bug_report/models/bug_report_models.dart';
import 'package:apolo_mobile/features/bug_report/services/bug_report_api_service.dart';
import 'package:apolo_mobile/features/bug_report/services/bug_report_controller.dart';
import 'package:apolo_mobile/features/bug_report/services/bug_report_log_service.dart';
import 'package:apolo_mobile/features/bug_report/services/bug_report_route_observer.dart';
import 'package:apolo_mobile/features/bug_report/services/bug_report_screenshot_service.dart';
import 'package:apolo_mobile/features/bug_report/services/bug_report_shake_service.dart';
import 'package:apolo_mobile/features/bug_report/ui/bug_report_composer_screen.dart';
import 'package:apolo_mobile/features/bug_report/ui/bug_report_consent_screen.dart';
import 'package:apolo_mobile/features/bug_report/ui/bug_report_strings.dart';

class _MockAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions, List<int> bodyBytes)
      handler;
  final List<({RequestOptions options, String bodyText})> requests = [];

  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
    }
    final text = utf8.decode(chunks, allowMalformed: true);
    requests.add((options: options, bodyText: text));
    return await handler(options, chunks);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(
  Object data, {
  int status = 200,
  Map<String, List<String>>? extraHeaders,
}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...?extraHeaders,
    },
  );
}

final Uint8List _valid1x1Png = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG sig
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _FakeScreenshotService extends BugReportScreenshotService {
  _FakeScreenshotService() : super();

  @override
  Future<BugScreenshotAttachment?> captureCurrentScreen({
    double? maxPixelRatio,
    BugScreenshotSource source = BugScreenshotSource.autoCapture,
  }) async {
    return BugScreenshotAttachment(
      bytes: _valid1x1Png,
      filename: 'test_capture.png',
      mimeType: 'image/png',
      source: source,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio originalDio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = AppState().api.dio;
    final taxonomyMock = _MockAdapter((opts, bytes) {
      if (opts.path.contains('/taxonomy')) {
        return _jsonResponse({
          'status': 'success',
          'categories': <dynamic>[],
          'cities': <dynamic>[],
        });
      }
      return _jsonResponse({'status': 'success'});
    });
    AppState().api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = taxonomyMock;

    BugReportRouteObserver.instance.reset();
    await AppState().setLocale(const Locale('en'));
    AppState().currentUser = null;
    BugReportLogService.instance.clear();
  });

  tearDown(() {
    AppState().api.dio = originalDio;
    BugReportLogService.instance.clear();
  });

  group('BugReportLogService sanitization & ring buffer', () {
    test('redacts Bearer tokens, JWTs, passwords, OTPs, and query secrets', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NSJ9.signaturepart99';
      final cleaned = BugReportLogService.sanitizeText(
        'Auth Authorization: Bearer mySecretToken123 jwt=$jwt password=letmein otp=884422 https://user:pass@apolo.ma/login?token=leak#frag',
      );

      expect(cleaned, isNot(contains('mySecretToken123')));
      expect(cleaned, isNot(contains(jwt)));
      expect(cleaned, isNot(contains('letmein')));
      expect(cleaned, isNot(contains('884422')));
      expect(cleaned, isNot(contains('pass@')));
      expect(cleaned, isNot(contains('token=leak')));
      expect(cleaned, contains('[REDACTED]'));
    });

    test('strips query strings and enforces bounded ring buffer sizes', () {
      final svc = BugReportLogService.instance;
      svc.recordApiError(
        method: 'post',
        path: '/api/v1/auth/login?token=secret123',
        statusCode: 500,
        errorType: 'badResponse',
      );
      expect(svc.breadcrumbs.single.meta?['path'], '/api/v1/auth/login');

      for (var i = 0; i < 160; i++) {
        svc.log('Entry $i');
      }
      expect(svc.logs.length, BugReportLogService.maxLogEntries);
      expect(svc.breadcrumbs.length, lessThanOrEqualTo(BugReportLogService.maxBreadcrumbEntries));
    });
  });

  group('BugReportShakeService persistence & guards', () {
    test('persists toggle state and applies threshold, spike count, cooldown, and blocker', () async {
      var triggers = 0;
      var blocked = false;
      final controller = StreamController<AccelerometerSample>.broadcast();

      final service = BugReportShakeService(
        onShakeDetected: () => triggers++,
        isBlocked: () => blocked,
        streamFactory: () => controller.stream,
      );
      addTearDown(() async {
        service.dispose();
        await controller.close();
      });

      await service.init();
      expect(service.enabled.value, isTrue);

      final t0 = DateTime(2026, 11, 22, 12, 0, 0);
      // Gentle movement (1g) should not trigger.
      service.processSample(0, 9.81, 0, now: t0);
      service.processSample(0, 9.81, 0, now: t0.add(const Duration(milliseconds: 200)));
      expect(triggers, 0);

      // Single strong spike should not trigger alone.
      service.processSample(30, 0, 0, now: t0.add(const Duration(milliseconds: 400)));
      expect(triggers, 0);

      // Second spike within 700ms and >=120ms after first triggers once.
      service.processSample(-30, 0, 0, now: t0.add(const Duration(milliseconds: 620)));
      expect(triggers, 1);

      // Immediate shake within cooldown (3500ms) is ignored.
      service.processSample(30, 0, 0, now: t0.add(const Duration(milliseconds: 1200)));
      service.processSample(-30, 0, 0, now: t0.add(const Duration(milliseconds: 1450)));
      expect(triggers, 1);

      // Blocked while modal open.
      blocked = true;
      service.processSample(30, 0, 0, now: t0.add(const Duration(seconds: 6)));
      service.processSample(-30, 0, 0, now: t0.add(const Duration(seconds: 6, milliseconds: 220)));
      expect(triggers, 1);

      // Unblocked after cooldown triggers again.
      blocked = false;
      service.processSample(30, 0, 0, now: t0.add(const Duration(seconds: 12)));
      service.processSample(-30, 0, 0, now: t0.add(const Duration(seconds: 12, milliseconds: 220)));
      expect(triggers, 2);

      // Persistence check
      await service.setEnabled(false);
      expect(service.enabled.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(BugReportShakeService.prefsKey), isFalse);
    });
  });

  group('BugReportScreenshotService upload validation', () {
    test('accepts PNG and rejects oversized or invalid format files', () {
      final ok = BugReportScreenshotService.validatePickedImageBytes(
        bytes: _valid1x1Png,
        originalName: 'capture.png',
      );
      expect(ok.attachment?.mimeType, 'image/png');

      final badFmt = BugReportScreenshotService.validatePickedImageBytes(
        bytes: Uint8List.fromList(utf8.encode('<svg></svg>')),
        originalName: 'bad.svg',
      );
      expect(badFmt.error, ScreenshotPickError.unsupportedFormat);

      final tooBig = BugReportScreenshotService.validatePickedImageBytes(
        bytes: Uint8List(BugReportScreenshotService.maxFileSizeBytes + 1),
        originalName: 'huge.png',
      );
      expect(tooBig.error, ScreenshotPickError.fileTooLarge);
    });
  });

  group('BugReportApiService contract & privacy gate', () {
    test('resolves endpoints across production, staging, and Vercel proxy', () {
      expect(
        BugReportApiService.resolveEndpoint('https://apolo.ma/api/v1'),
        'https://apolo.ma/api/support/bug-reports',
      );
      expect(
        BugReportApiService.resolveEndpoint('https://apolo-amber.vercel.app/api/v1'),
        'https://apolo-amber.vercel.app/api/support/bug-reports',
      );
      expect(
        BugReportApiService.resolveEndpoint('https://apolo-amber.vercel.app/apolo-staging-api'),
        'https://apolo-amber.vercel.app/apolo-staging-api/support/bug-reports',
      );
    });

    test('never attaches optional logs or full device_meta when includeLogs is false', () async {
      final adapter = _MockAdapter((opts, bytes) {
        return _jsonResponse({
          'status': 'success',
          'data': {'id': 42, 'status': 'open'},
        }, status: 201);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://apolo.ma/api/v1'))
        ..httpClientAdapter = adapter;
      final api = BugReportApiService(dio: dio);

      final result = await api.submitReport(
        BugReportSubmission(
          description: 'Listing gallery fails to scroll smoothly.',
          includeLogs: false,
          context: const BugReportContextSnapshot(
            userId: 9,
            appVersion: '1.0.0+1',
            platform: 'ios',
            locale: 'fr',
            isRtl: false,
            routeName: '/ad/55',
            optionalDeviceMeta: {'viewport_width': 390, 'secret_key': 'x'},
          ),
          diagnosticsLogs: {
            'logs': [
              {'message': 'should not be sent'},
            ],
          },
        ),
      );

      expect(result.id, 42);
      expect(result.status, 'open');
      final sent = jsonDecode(adapter.requests.single.bodyText) as Map<String, dynamic>;
      expect(sent['include_logs'], isFalse);
      expect(sent.containsKey('diagnostics_logs'), isFalse);
      expect(sent['device_meta'], {'is_rtl': false, 'authenticated': true});
    });

    test('uploads multipart screenshot and diagnostics when includeLogs is true', () async {
      final adapter = _MockAdapter((opts, bytes) {
        return _jsonResponse({
          'status': 'success',
          'data': {'id': 88, 'status': 'open'},
        }, status: 201);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://apolo.ma/api/v1'))
        ..httpClientAdapter = adapter;
      final api = BugReportApiService(dio: dio);

      final result = await api.submitReport(
        BugReportSubmission(
          description: 'Checkout modal overflows on smaller screens.',
          includeLogs: true,
          context: const BugReportContextSnapshot(
            userId: null,
            appVersion: '1.0.0+1',
            platform: 'web',
            locale: 'en',
            isRtl: false,
            routeName: 'main_shell/explore',
            optionalDeviceMeta: {'viewport_width': 375},
          ),
          diagnosticsLogs: {
            'logs': [
              {'message': 'Token Bearer secret123'},
            ],
          },
          screenshot: BugScreenshotAttachment(
            bytes: _valid1x1Png,
            filename: 'auto.png',
            mimeType: 'image/png',
            source: BugScreenshotSource.autoCapture,
          ),
        ),
      );

      expect(result.id, 88);
      final req = adapter.requests.single;
      expect(req.options.path, 'https://apolo.ma/api/support/bug-reports');
      expect(req.bodyText, contains('name="include_logs"'));
      expect(req.bodyText, contains('name="screenshot"'));
      expect(req.bodyText, contains('name="diagnostics_logs"'));
      expect(req.bodyText, isNot(contains('secret123')));
    });

    test('maps 429 rate-limit response with Retry-After header cleanly', () async {
      final adapter = _MockAdapter((opts, bytes) {
        return _jsonResponse(
          {'message': 'Too Many Attempts.'},
          status: 429,
          extraHeaders: {
            'retry-after': ['45'],
          },
        );
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://apolo.ma/api/v1'))
        ..httpClientAdapter = adapter;
      final api = BugReportApiService(dio: dio);

      expect(
        () => api.submitReport(
          const BugReportSubmission(
            description: 'Repeated tap causes freeze',
            includeLogs: false,
            context: BugReportContextSnapshot(
              userId: null,
              appVersion: '1.0.0+1',
              platform: 'web',
              locale: 'en',
              isRtl: false,
              routeName: 'main_shell/home',
            ),
          ),
        ),
        throwsA(
          isA<BugReportApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.retryAfterSeconds, 'retryAfter', 45),
        ),
      );
    });
  });

  group('3-Step Bug Reporter Widget Flow', () {
    testWidgets(
        'completes full flow: entry sheet -> consent opt-in -> composer pre-capture -> error retry -> 201 success',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var failNext = true;
      final adapter = _MockAdapter((opts, bytes) {
        if (failNext) {
          failNext = false;
          return _jsonResponse({'message': 'Temporary outage'}, status: 500);
        }
        return _jsonResponse({
          'status': 'success',
          'data': {'id': 77, 'status': 'open'},
        }, status: 201);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://apolo.ma/api/v1'))
        ..httpClientAdapter = adapter;
      final apiService = BugReportApiService(dio: dio);

      await BugReportController.instance.initialize();
      await BugReportController.instance.shakeService.setEnabled(true);

      await tester.pumpWidget(
        RepaintBoundary(
          key: BugReportScreenshotService.instance.boundaryKey,
          child: MaterialApp(
            navigatorKey: BugReportController.navigatorKey,
            navigatorObservers: [BugReportRouteObserver.instance],
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) => ElevatedButton(
                    key: const Key('open-reporter-trigger'),
                    onPressed: () {
                      BugReportController.instance.openBugReporter(
                        context: ctx,
                        apiService: apiService,
                        screenshotService: _FakeScreenshotService(),
                      );
                    },
                    child: const Text('Trigger'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Step 1 Entry Bottom Sheet
      await tester.tap(find.byKey(const Key('open-reporter-trigger')));
      await tester.pumpAndSettle();

      expect(find.text('Report a technical problem'), findsOneWidget);
      expect(find.byKey(const Key('bug-report-start-cta')), findsOneWidget);
      expect(find.byKey(const Key('bug-report-shake-switch')), findsOneWidget);

      // Toggle Shake preference off & verify persistence
      await tester.tap(find.byKey(const Key('bug-report-shake-switch')));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(BugReportShakeService.prefsKey), isFalse);

      // Proceed to Step 2 Consent Screen
      await tester.tap(find.byKey(const Key('bug-report-start-cta')));
      await tester.pumpAndSettle();

      expect(
        find.text('Would you like to include additional logs and diagnostics?'),
        findsOneWidget,
      );

      // Opt-in via "Include and continue"
      await tester.tap(find.byKey(const Key('bug-report-include-logs-btn')));
      await tester.pumpAndSettle();

      // Step 3 Composer Screen: Send disabled while empty/whitespace
      final sendBtnFinder = find.byKey(const Key('bug-report-send-btn'));
      expect(tester.widget<TextButton>(sendBtnFinder).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('bug-report-description-field')),
        '   ',
      );
      await tester.pump();
      expect(tester.widget<TextButton>(sendBtnFinder).onPressed, isNull);

      // Auto pre-captured screenshot thumbnail is shown
      expect(
        find.byKey(const Key('bug-report-screenshot-thumbnail')),
        findsOneWidget,
      );

      // Enter valid issue description and attempt send -> triggers 500 error
      await tester.enterText(
        find.byKey(const Key('bug-report-description-field')),
        'Search filter modal freezes after tapping city.',
      );
      await tester.pump();
      await tester.tap(sendBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bug-report-error-banner')), findsOneWidget);
      expect(find.byKey(const Key('bug-report-retry-btn')), findsOneWidget);
      // User text and screenshot preserved on failure
      expect(
        find.text('Search filter modal freezes after tapping city.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bug-report-screenshot-thumbnail')),
        findsOneWidget,
      );

      // Retry succeeds (201 Created)
      await tester.tap(find.byKey(const Key('bug-report-retry-btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('#77'), findsOneWidget);
      expect(adapter.requests.length, 2);
      expect(adapter.requests.last.bodyText, contains('name="screenshot"'));
      expect(adapter.requests.last.bodyText, contains('name="diagnostics_logs"'));
    });

    testWidgets(
        'declining logs omits diagnostics and removing screenshot submits JSON only',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adapter = _MockAdapter((opts, bytes) {
        return _jsonResponse({
          'status': 'success',
          'data': {'id': 91, 'status': 'open'},
        }, status: 201);
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://apolo.ma/api/v1'))
        ..httpClientAdapter = adapter;

      await tester.pumpWidget(
        RepaintBoundary(
          key: BugReportScreenshotService.instance.boundaryKey,
          child: MaterialApp(
            navigatorKey: BugReportController.navigatorKey,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  key: const Key('open-reporter-trigger'),
                  onPressed: () {
                    BugReportController.instance.openBugReporter(
                      context: ctx,
                      apiService: BugReportApiService(dio: dio),
                      screenshotService: _FakeScreenshotService(),
                      onPickUpload: () async => const ScreenshotPickResult(
                        error: ScreenshotPickError.fileTooLarge,
                      ),
                    );
                  },
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open-reporter-trigger')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bug-report-start-cta')));
      await tester.pumpAndSettle();

      // Decline optional logs
      await tester.tap(find.byKey(const Key('bug-report-skip-logs-btn')));
      await tester.pumpAndSettle();

      // Dismiss pre-captured thumbnail via × button
      await tester.tap(
        find.byKey(const Key('bug-report-remove-screenshot-btn')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bug-report-screenshot-thumbnail')),
        findsNothing,
      );

      // Trigger upload validation error check
      await tester.tap(find.byKey(const Key('bug-report-upload-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bug-report-error-banner')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('bug-report-description-field')),
        'Button alignment breaks on profile page.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('bug-report-send-btn')));
      await tester.pumpAndSettle();

      final payload =
          jsonDecode(adapter.requests.single.bodyText) as Map<String, dynamic>;
      expect(payload['include_logs'], isFalse);
      expect(payload.containsKey('diagnostics_logs'), isFalse);
    });

    testWidgets(
        'fires custom abuse callback hook and renders cleanly in Dark Mode + RTL Arabic',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(() => AppState().setLocale(const Locale('ar')));
      var abuseHookCalled = false;

      await tester.pumpWidget(
        RepaintBoundary(
          key: BugReportScreenshotService.instance.boundaryKey,
          child: MaterialApp(
            navigatorKey: BugReportController.navigatorKey,
            theme: ThemeData.dark(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  key: const Key('open-reporter-trigger'),
                  onPressed: () {
                    BugReportController.instance.openBugReporter(
                      context: ctx,
                      screenshotService: _FakeScreenshotService(),
                      onReportAbuse: () => abuseHookCalled = true,
                    );
                  },
                  child: const Text('فتح'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open-reporter-trigger')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bug-report-abuse-row')));
      await tester.pumpAndSettle();
      expect(abuseHookCalled, isTrue);

      // Also verify Dark RTL rendering of Step 2 & Step 3 directly
      final strings = BugReportStrings(AppState().s);
      const snapshot = BugReportContextSnapshot(
        userId: 12,
        appVersion: '1.0.0+1',
        platform: 'ios',
        locale: 'ar',
        isRtl: true,
        routeName: 'main_shell/home',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BugReportConsentScreen(
            strings: strings,
            contextSnapshot: snapshot,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BugReportComposerScreen(
            strings: strings,
            includeLogs: true,
            contextSnapshot: snapshot,
            apiService: const BugReportApiService(),
            screenshotService: BugReportScreenshotService.instance,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
