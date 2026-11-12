import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/config/app_config.dart';
import 'core/state/app_state.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState().initialize(loadRemote: false);

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
    final fontFallback =
        AppTypography.resolveFontFamilyFallback(_state.locale);

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      locale: _state.locale,
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: TextStyle(
            fontFamily: fontFamily,
            fontFamilyFallback: fontFallback,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      supportedLocales: const [
        Locale('ar'),
        Locale('fr'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(_state.locale),
      darkTheme: AppTheme.dark(_state.locale),
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
