import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';

/// Dedicated screen for choosing the Apolo app interface & catalog language.
class SettingsLanguageScreen extends StatefulWidget {
  const SettingsLanguageScreen({super.key});

  @override
  State<SettingsLanguageScreen> createState() => _SettingsLanguageScreenState();
}

class _SettingsLanguageScreenState extends State<SettingsLanguageScreen> {
  final AppState _state = AppState();
  bool _busy = false;
  String? _error;

  Future<void> _selectLanguage(String code) async {
    if (_busy || _state.locale.languageCode == code) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _state.setLocale(Locale(code));
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = _state.s.tr(
            'تعذر حفظ اللغة. أعد المحاولة.',
            'Impossible d’enregistrer la langue. Réessayez.',
            'Could not save language. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;
        final currentCode = _state.locale.languageCode;
        final palette = ApoloDlPalette.of(context);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'لغة التطبيق',
                      'Langue de l’app',
                      'App language',
                    ),
                    size: ApoloDlTopNavSize.md,
                  ),
                  if (_busy)
                    LinearProgressIndicator(
                      minHeight: 2,
                      color: palette.ink,
                      backgroundColor: palette.separator,
                    ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                          children: [
                            Text(
                              s.tr(
                                'اختر لغة واجهة التطبيق والإعلانات. سيتم تطبيق التغيير فوراً على كامل التطبيق.',
                                'Choisissez la langue de l’application et du catalogue. Le changement est appliqué immédiatement.',
                                'Choose the language for the app interface and listings. Changes apply immediately across the app.',
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_error != null) ...[
                              ApoloDlAlert(
                                message: _error!,
                                type: ApoloDlAlertType.danger,
                              ),
                              const SizedBox(height: 14),
                            ],
                            ApoloDlLineItem(
                              key: const Key('lang-option-ar'),
                              title: 'العربية',
                              description:
                                  'العربية المغربية · من اليمين إلى اليسار (RTL)',
                              type: ApoloDlLineItemType.radio,
                              state: _busy
                                  ? ApoloDlLineItemState.disabled
                                  : ApoloDlLineItemState.normal,
                              value: currentCode == 'ar',
                              onChanged: (_) => _selectLanguage('ar'),
                            ),
                            ApoloDlLineItem(
                              key: const Key('lang-option-fr'),
                              title: 'Français',
                              description: 'Interface en français (LTR)',
                              type: ApoloDlLineItemType.radio,
                              state: _busy
                                  ? ApoloDlLineItemState.disabled
                                  : ApoloDlLineItemState.normal,
                              value: currentCode == 'fr',
                              onChanged: (_) => _selectLanguage('fr'),
                            ),
                            ApoloDlLineItem(
                              key: const Key('lang-option-en'),
                              title: 'English',
                              description: 'English interface (LTR)',
                              type: ApoloDlLineItemType.radio,
                              state: _busy
                                  ? ApoloDlLineItemState.disabled
                                  : ApoloDlLineItemState.normal,
                              value: currentCode == 'en',
                              showSeparator: false,
                              onChanged: (_) => _selectLanguage('en'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
