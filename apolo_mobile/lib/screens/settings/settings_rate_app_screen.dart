import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';

/// Dedicated screen for rating the Apolo.ma experience and leaving quick feedback.
class SettingsRateAppScreen extends StatefulWidget {
  const SettingsRateAppScreen({super.key});

  @override
  State<SettingsRateAppScreen> createState() => _SettingsRateAppScreenState();
}

class _SettingsRateAppScreenState extends State<SettingsRateAppScreen> {
  final AppState _state = AppState();
  final TextEditingController _reviewCtrl = TextEditingController();
  int _rating = 5;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  String _ratingCaption(AppStrings s) {
    return switch (_rating) {
      1 => s.tr('يحتاج لتحسين كبير', 'À améliorer', 'Needs work'),
      2 => s.tr('تجربة مقبولة', 'Passable', 'Fair'),
      3 => s.tr('جيد', 'Bien', 'Good'),
      4 => s.tr('ممتاز جداً', 'Très bien', 'Great'),
      5 => s.tr('رائع! شكراً لدعمك', 'Excellent !', 'Awesome!'),
      _ => s.tr('اختر عدد النجوم', 'Choisissez une note', 'Select stars'),
    };
  }

  void _submitRating() {
    final s = _state.s;
    if (_rating <= 0) {
      setState(() {
        _submitted = false;
        _error = s.tr(
          'يرجى اختيار تقييم من 1 إلى 5 نجوم.',
          'Veuillez sélectionner entre 1 et 5 étoiles.',
          'Please select 1 to 5 stars.',
        );
      });
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _error = null;
      _submitted = true;
    });
  }

  Future<void> _openStorePage() async {
    final uri = Uri.parse('https://apolo.ma');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final palette = ApoloDlPalette.of(context);

        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'تقييم التطبيق',
                      'Noter l’app',
                      'Rate App',
                    ),
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: palette.groupCard,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    s.tr(
                                      'كيف هي تجربتك مع Apolo.ma؟',
                                      'Que pensez-vous d’Apolo.ma ?',
                                      'How is your experience with Apolo.ma?',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: palette.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (index) {
                                      final star = index + 1;
                                      final active = star <= _rating;
                                      return IconButton(
                                        key: Key('rate-star-$star'),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _rating = star;
                                            _submitted = false;
                                          });
                                        },
                                        icon: Icon(
                                          active
                                              ? CupertinoIcons.star_fill
                                              : CupertinoIcons.star,
                                          size: 30,
                                          color: active
                                              ? const Color(0xFFF59E0B)
                                              : palette.iconMuted,
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _ratingCaption(s),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: palette.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                  key: const Key('rate-review-input'),
                                  controller: _reviewCtrl,
                                  minLines: 3,
                                  maxLines: 5,
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
                                      'أضف ملاحظة سريعة (اختياري)...',
                                      'Ajouter un commentaire (optionnel)...',
                                      'Add a quick note (optional)...',
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
                                  'شكراً على تقييمك ($_rating/5)! رأيك كيساعدنا نطورو Apolo.ma.',
                                  'Merci pour votre note ($_rating/5) !',
                                  'Thank you for rating us $_rating/5!',
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
                              key: const Key('rate-app-submit'),
                              label: s.tr(
                                'إرسال التقييم',
                                'Envoyer la note',
                                'Submit rating',
                              ),
                              leadingIcon: CupertinoIcons.star_fill,
                              variant: ApoloDlButtonVariant.primary,
                              fullWidth: true,
                              onPressed: _submitRating,
                            ),
                            const SizedBox(height: 10),
                            ApoloDlButton(
                              label: s.tr(
                                'زيارة موقع Apolo.ma',
                                'Visiter Apolo.ma',
                                'Visit Apolo.ma',
                              ),
                              leadingIcon: CupertinoIcons.globe,
                              variant: ApoloDlButtonVariant.secondary,
                              fullWidth: true,
                              onPressed: _openStorePage,
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
