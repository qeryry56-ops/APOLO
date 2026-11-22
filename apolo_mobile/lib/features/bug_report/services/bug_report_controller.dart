import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/state/app_state.dart';
import '../models/bug_report_models.dart';
import '../ui/bug_report_abuse_guide_sheet.dart';
import '../ui/bug_report_composer_screen.dart';
import '../ui/bug_report_consent_screen.dart';
import '../ui/bug_report_entry_sheet.dart';
import '../ui/bug_report_strings.dart';
import '../ui/bug_report_theme.dart';
import 'bug_report_api_service.dart';
import 'bug_report_route_observer.dart';
import 'bug_report_screenshot_service.dart';
import 'bug_report_shake_service.dart';

/// Coordinates the 3-step self-hosted bug reporting flow, shake detection,
/// pre-sheet screenshot capture, and context snapshot collection.
class BugReportController {
  BugReportController._internal() {
    shakeService = BugReportShakeService(
      onShakeDetected: _onShakeTriggered,
      isBlocked: () => isFlowOpen.value,
    );
  }

  static final BugReportController instance = BugReportController._internal();

  /// Attached to root [MaterialApp] so shake triggers & shortcuts always find
  /// an active navigator context.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  late final BugReportShakeService shakeService;
  final BugReportApiService _defaultApiService = const BugReportApiService();
  final ValueNotifier<bool> isFlowOpen = ValueNotifier<bool>(false);

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await shakeService.init();
  }

  void _onShakeTriggered() {
    final navContext = navigatorKey.currentContext;
    if (navContext == null || isFlowOpen.value) return;
    openBugReporter(context: navContext);
  }

  String _resolvePlatformString() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'unknown',
    };
  }

  BugReportContextSnapshot captureContextSnapshot(BuildContext context) {
    final state = AppState();
    final rawUserId = state.currentUser?['id'];
    final parsedUserId = rawUserId is int
        ? rawUserId
        : int.tryParse((rawUserId ?? '').toString());
    final localeCode = state.locale.languageCode;
    final isRtl = localeCode == 'ar' ||
        Directionality.maybeOf(context) == TextDirection.rtl;

    final mq = MediaQuery.maybeOf(context);
    final themeBrightness = Theme.of(context).brightness.name;

    return BugReportContextSnapshot(
      userId: state.isLoggedIn ? parsedUserId : null,
      appVersion: '${AppConfig.appVersion}+${AppConfig.appBuildNumber}',
      platform: _resolvePlatformString(),
      locale: localeCode,
      isRtl: isRtl,
      routeName: BugReportRouteObserver.instance.currentRouteName,
      optionalDeviceMeta: {
        'target_platform': defaultTargetPlatform.name,
        'is_web': kIsWeb,
        'brightness': themeBrightness,
        if (mq != null) ...{
          'viewport_width': mq.size.width.round(),
          'viewport_height': mq.size.height.round(),
          'device_pixel_ratio':
              double.parse(mq.devicePixelRatio.toStringAsFixed(2)),
          'text_scale': double.parse(
            mq.textScaler.scale(1.0).toStringAsFixed(2),
          ),
        },
      },
    );
  }

  Future<void> openBugReporter({
    BuildContext? context,
    VoidCallback? onReportAbuse,
    BugReportApiService? apiService,
    BugReportScreenshotService? screenshotService,
    Future<ScreenshotPickResult> Function()? onPickUpload,
  }) async {
    if (isFlowOpen.value) return;

    final hostContext = context ?? navigatorKey.currentContext;
    if (hostContext == null || !hostContext.mounted) return;

    final nav = Navigator.maybeOf(hostContext, rootNavigator: true) ??
        navigatorKey.currentState;
    if (nav == null) return;

    isFlowOpen.value = true;
    final strings = BugReportStrings(AppState().s);
    final activeShotService =
        screenshotService ?? BugReportScreenshotService.instance;
    final activeApi = apiService ?? _defaultApiService;

    try {
      // 1. Capture route/user context & pre-capture the screen BEFORE the
      // bottom sheet covers the active UI.
      final contextSnapshot = captureContextSnapshot(hostContext);
      final initialScreenshot = await activeShotService.captureCurrentScreen(
        source: BugScreenshotSource.autoCapture,
      );

      if (!nav.mounted) return;

      // 2. Step 1: Entry Bottom Sheet
      final entryAction = await showBugReportEntrySheet(
        nav.context,
        strings: strings,
        shakeEnabled: shakeService.enabled,
        onToggleShake: shakeService.setEnabled,
        isShakeHardwareSupported: shakeService.isHardwareSupported,
      );

      if (entryAction == BugReportEntryAction.reportAbuse) {
        if (onReportAbuse != null) {
          onReportAbuse();
        } else if (nav.mounted) {
          await showBugReportAbuseGuideSheet(nav.context, strings: strings);
        }
        return;
      }

      if (entryAction != BugReportEntryAction.startReport || !nav.mounted) {
        return;
      }

      // 3. Step 2: Explicit Logs & Diagnostics Consent Screen
      final consentDecision = await nav.push<BugReportConsentDecision>(
        MaterialPageRoute<BugReportConsentDecision>(
          fullscreenDialog: true,
          settings: const RouteSettings(name: '/bug_report/consent'),
          builder: (_) => BugReportConsentScreen(
            strings: strings,
            contextSnapshot: contextSnapshot,
          ),
        ),
      );

      if (consentDecision == BugReportConsentDecision.openAbuseGuide) {
        if (onReportAbuse != null) {
          onReportAbuse();
        } else if (nav.mounted) {
          await showBugReportAbuseGuideSheet(nav.context, strings: strings);
        }
        return;
      }

      if ((consentDecision != BugReportConsentDecision.includeLogs &&
              consentDecision != BugReportConsentDecision.skipLogs) ||
          !nav.mounted) {
        return;
      }

      final includeLogs =
          consentDecision == BugReportConsentDecision.includeLogs;

      // 4. Step 3: Issue Composer & Screenshot Screen (non-opaque route so
      // re-capturing reveals the live screen underneath).
      final result = await nav.push<BugReportResult>(
        PageRouteBuilder<BugReportResult>(
          opaque: false,
          settings: const RouteSettings(name: '/bug_report/composer'),
          transitionDuration: const Duration(milliseconds: 240),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, __, ___) => BugReportComposerScreen(
            strings: strings,
            includeLogs: includeLogs,
            contextSnapshot: contextSnapshot,
            initialScreenshot: initialScreenshot,
            apiService: activeApi,
            screenshotService: activeShotService,
            onPickUpload: onPickUpload,
          ),
          transitionsBuilder: (_, anim, __, child) {
            final curved = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );

      if (result != null && nav.mounted) {
        final messenger = ScaffoldMessenger.maybeOf(nav.context);
        final palette = BugReportPalette.of(nav.context);
        messenger?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: palette.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFF0A0A0A),
            content: Text(
              strings.submitSuccess(result.id),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      isFlowOpen.value = false;
    }
  }
}
