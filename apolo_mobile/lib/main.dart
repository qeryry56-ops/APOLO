import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/app_config.dart';
import 'core/state/app_state.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().initialize();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(
    ApoloMobileApp(hasSeenWelcome: hasSeenWelcome),
  );
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      setState(() => _passedWelcome = true);
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
          style: const TextStyle(
            fontFamily: AppConfig.fontPrimary,
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
      home: _passedWelcome
          ? const MainShell()
          : WelcomeScreen(
              onContinueAsGuest: _onCompleteWelcome,
            ),
    );
  }
}
