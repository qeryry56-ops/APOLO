import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/state/app_state.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().initialize(loadRemote: false);
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(
    ApoloMobileApp(hasSeenWelcome: hasSeenWelcome),
  );
  unawaited(AppState().refreshRemote());
}

class ApoloMobileApp extends StatefulWidget {
  final bool hasSeenWelcome;
  const ApoloMobileApp({super.key, this.hasSeenWelcome = false});

  @override
  State<ApoloMobileApp> createState() => _ApoloMobileAppState();
}

class _ApoloMobileAppState extends State<ApoloMobileApp> {
  final AppState _state = AppState();
  late bool _passedWelcome;

  @override
  void initState() {
    super.initState();
    _passedWelcome = widget.hasSeenWelcome || _state.isLoggedIn;
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

  void _onCompleteWelcome() async {
    if (mounted) setState(() => _passedWelcome = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (_) {
      // Storage failure must not block entering the app.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      locale: _state.locale,
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily:
                _state.s.isAr ? 'IBMPlexSansArabic' : AppConfig.fontPrimary,
            fontFamilyFallback: AppConfig.fontFallback,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      supportedLocales: const [
        Locale('ar'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppConfig.buildTheme(_state.locale),
      home: SplashScreen(
        hasSeenWelcome: _passedWelcome,
        onCompleteWelcome: _onCompleteWelcome,
      ),
    );
  }
}
