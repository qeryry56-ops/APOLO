import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/services/firebase_chat_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/state/app_state.dart';
import 'features/bug_report/services/bug_report_controller.dart';
import 'features/bug_report/services/bug_report_log_service.dart';
import 'features/bug_report/services/bug_report_route_observer.dart';
import 'features/bug_report/services/bug_report_screenshot_service.dart';
import 'l10n/l10n.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final originalFlutterOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    BugReportLogService.instance.recordFlutterError(details);
    originalFlutterOnError?.call(details);
  };

  final originalPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    BugReportLogService.instance.recordPlatformError(error, stack);
    return originalPlatformOnError?.call(error, stack) ?? false;
  };

  await FirebaseChatService.instance.initialize();
  await AppState().initialize(loadRemote: false);
  await ApoloPushNotificationService.instance.initialize();
  await BugReportController.instance.initialize();

  runApp(const ApoloMobileApp());
  unawaited(AppState().refreshRemote());
}

class ApoloMobileApp extends StatefulWidget {
  final bool hasSeenWelcome;
  const ApoloMobileApp({super.key, this.hasSeenWelcome = true});

  @override
  State<ApoloMobileApp> createState() => _ApoloMobileAppState();
}

class _ApoloMobileAppState extends State<ApoloMobileApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.addListener(_rebuild);
  }

  @override
  void dispose() {
    _state.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = AppTypography.resolveFontFamily(_state.locale);
    final fontFallback = AppTypography.resolveFontFamilyFallback(_state.locale);

    return MaterialApp(
      navigatorKey: BugReportController.navigatorKey,
      navigatorObservers: [BugReportRouteObserver.instance],
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      locale: _state.locale,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor:
              isDark ? const Color(0xFF0A0A0A) : Colors.white,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(
                LogicalKeyboardKey.keyB,
                control: true,
                shift: true,
              ): () => BugReportController.instance.openBugReporter(),
              const SingleActivator(
                LogicalKeyboardKey.keyB,
                meta: true,
                shift: true,
              ): () => BugReportController.instance.openBugReporter(),
            },
            child: RepaintBoundary(
              key: BugReportScreenshotService.instance.boundaryKey,
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontFamilyFallback: fontFallback,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('ar'),
        Locale('es'),
        Locale('de'),
        Locale('ja'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(_state.locale),
      darkTheme: AppTheme.dark(_state.locale),
      themeMode: _state.themeMode,
      home: const SplashScreen(),
    );
  }
}
