import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:device_preview/device_preview.dart';
import 'core/config/app_config.dart';
import 'core/state/app_state.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().initialize();
  runApp(
    DevicePreview(
      enabled: kIsWeb || !kReleaseMode,
      defaultDevice: Devices.ios.iPhone15Pro,
      builder: (context) => const ApoloMobileApp(),
    ),
  );
}

class ApoloMobileApp extends StatefulWidget {
  const ApoloMobileApp({super.key});

  @override
  State<ApoloMobileApp> createState() => _ApoloMobileAppState();
}

class _ApoloMobileAppState extends State<ApoloMobileApp> {
  final AppState _state = AppState();
  bool _passedWelcome = false;

  @override
  void initState() {
    super.initState();
    _passedWelcome = _state.isLoggedIn;
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
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      locale: _state.locale,
      builder: (context, child) {
        final previewed = DevicePreview.appBuilder(context, child);
        return DefaultTextStyle.merge(
          style: const TextStyle(
            fontFamily: AppConfig.fontPrimary,
            fontFamilyFallback: AppConfig.fontFallback,
          ),
          child: previewed,
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
              onContinueAsGuest: () => setState(() => _passedWelcome = true),
            ),
    );
  }
}
