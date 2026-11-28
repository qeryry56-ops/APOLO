import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import '../../l10n/l10n.dart';

/// Dedicated screen for submitting feature ideas and UX suggestions for Apolo.ma.
class SettingsSuggestionScreen extends StatefulWidget {
  const SettingsSuggestionScreen({super.key});

  @override
  State<SettingsSuggestionScreen> createState() =>
      _SettingsSuggestionScreenState();
}

class _SettingsSuggestionScreenState extends State<SettingsSuggestionScreen> {
  final AppState _state = AppState();
  final TextEditingController _controller = TextEditingController();
  String _selectedTopic = 'feature';
  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  bool _showEmailFallback = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final s = _state.s;
    final text = _controller.text.trim();
    if (text.length < 5) {
      setState(() {
        _submitted = false;
        _showEmailFallback = false;
        _error = s.tr(
          'يرجى كتابة اقتراح من 5 أحرف على الأقل.',
          'Veuillez saisir une suggestion d’au moins 5 caractères.',
          appL10n.settingsSuggestionPleaseEnterSuggestionAtLeast,
        );
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _submitted = false;
      _showEmailFallback = false;
    });

    try {
      final res = await _state.api.dio.post(
        '/reports',
        data: {
          'type': 'feature_suggestion',
          'category': _selectedTopic,
          'details': text,
        },
      );
      final ok = res.statusCode == 200 ||
          res.statusCode == 201 ||
          (res.data is Map && res.data['status'] == 'success');
      if (!ok) {
        throw StateError('Suggestion endpoint rejected request');
      }
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _submitted = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _showEmailFallback = true;
        _error = s.tr(
          'تعذر إرسال الاقتراح عبر الشبكة حالياً. يمكنك المحاولة مجدداً أو إرساله عبر البريد الإلكتروني.',
          'Envoi impossible pour le moment. Réessayez ou envoyez votre suggestion par e-mail.',
          appL10n.settingsSuggestionCouldNotSendOverNetwork,
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openEmailFallback() async {
    final s = _state.s;
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@apolo.ma',
      queryParameters: {
        'subject': 'Apolo.ma Suggestion ($_selectedTopic)',
        'body': _controller.text.trim(),
      },
    );
    try {
      if (!await launchUrl(uri)) {
        throw StateError('No email client');
      }
    } catch (_) {
      if (!mounted) return;
      await Clipboard.setData(const ClipboardData(text: 'support@apolo.ma'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            s.tr(
              'تم نسخ البريد الإلكتروني support@apolo.ma',
              'Adresse support@apolo.ma copiée',
              appL10n.settingsSuggestionCopiedSupportApoloMa,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final palette = ApoloDlPalette.of(context);

        final topics = <({String id, String label})>[
          (
            id: 'feature',
            label: s.tr('ميزة جديدة', 'Nouvelle fonctionnalité', appL10n.settingsSuggestionFeature),
          ),
          (
            id: 'design',
            label: s.tr('تحسين التصميم', 'Design & UI', appL10n.settingsSuggestionDesign),
          ),
          (
            id: 'performance',
            label: s.tr('الأداء والسرعة', 'Performance', appL10n.settingsSuggestionPerformance),
          ),
          (
            id: 'other',
            label: s.tr('أخرى', 'Autre', appL10n.settingsSuggestionOther),
          ),
        ];

        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'تقديم اقتراح',
                      'Faire une suggestion',
                      appL10n.settingsSuggestionMakeSuggestion,
                    ),
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                          children: [
                            Text(
                              s.tr(
                                'شاركنا أفكارك لتحسين تجربة الشراء والبيع على Apolo.ma.',
                                'Partagez vos idées pour améliorer votre expérience sur Apolo.ma.',
                                appL10n.settingsSuggestionShareIdeasHelpUsImprove,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: palette.muted,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              s.tr('نوع الاقتراح', 'Thème', appL10n.settingsSuggestionTopic),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: topics.map((t) {
                                final selected = _selectedTopic == t.id;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedTopic = t.id);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? palette.ink
                                          : palette.groupCard,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      t.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? palette.onInk
                                            : palette.ink,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              s.tr(
                                'تفاصيل الاقتراح',
                                'Votre suggestion',
                                appL10n.settingsSuggestionYourSuggestion,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: palette.groupCard,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme:
                                      const InputDecorationTheme(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                                child: TextField(
                                  key: const Key('suggestion-input'),
                                  controller: _controller,
                                  minLines: 4,
                                  maxLines: 7,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: palette.ink,
                                  ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    hintText: s.tr(
                                      'اكتب فكرتك هنا بوضوح...',
                                      'Décrivez votre idée ici...',
                                      appL10n.settingsSuggestionWriteIdeaHere,
                                    ),
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: palette.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_submitted) ...[
                              const SizedBox(height: 16),
                              ApoloDlAlert(
                                message: s.tr(
                                  'شكراً لك! تم استلام اقتراحك بنجاح.',
                                  'Merci ! Votre suggestion a bien été envoyée.',
                                  appL10n.settingsSuggestionThankYouSuggestionHasBeen,
                                ),
                                type: ApoloDlAlertType.success,
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              ApoloDlAlert(
                                message: _error!,
                                type: ApoloDlAlertType.danger,
                              ),
                            ],
                            const SizedBox(height: 20),
                            ApoloDlButton(
                              key: const Key('suggestion-submit'),
                              label: s.tr(
                                'إرسال الاقتراح',
                                'Envoyer la suggestion',
                                appL10n.settingsSuggestionSubmitSuggestion,
                              ),
                              leadingIcon: CupertinoIcons.paperplane_fill,
                              variant: ApoloDlButtonVariant.primary,
                              fullWidth: true,
                              isLoading: _submitting,
                              onPressed: _submitting ? null : _submit,
                            ),
                            if (_showEmailFallback) ...[
                              const SizedBox(height: 10),
                              ApoloDlButton(
                                label: s.tr(
                                  'إرسال عبر support@apolo.ma',
                                  'Envoyer par e-mail à support@apolo.ma',
                                  appL10n.settingsSuggestionEmailSupportApoloMa,
                                ),
                                leadingIcon: CupertinoIcons.mail,
                                variant: ApoloDlButtonVariant.secondary,
                                fullWidth: true,
                                onPressed: _openEmailFallback,
                              ),
                            ],
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
