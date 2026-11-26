import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import '../add_friends_screen.dart';

/// Dedicated screen for sharing Apolo.ma with friends or copying the official link.
class SettingsShareAppScreen extends StatefulWidget {
  const SettingsShareAppScreen({super.key});

  @override
  State<SettingsShareAppScreen> createState() => _SettingsShareAppScreenState();
}

class _SettingsShareAppScreenState extends State<SettingsShareAppScreen> {
  final AppState _state = AppState();
  bool _copied = false;

  static const String _shareUrl = 'https://apolo.ma';

  Future<void> _copyLink() async {
    if (mounted) {
      setState(() => _copied = true);
    }
    try {
      await Clipboard.setData(const ClipboardData(text: _shareUrl));
    } catch (_) {}
  }

  Future<void> _shareNow() async {
    final s = _state.s;
    final shareText = s.tr(
      'اكتشف Apolo.ma — سوقك الأول للإعلانات المبوبة والمتاجر فالمغرب: $_shareUrl',
      'Découvrez Apolo.ma — la marketplace marocaine n°1 d’annonces et boutiques : $_shareUrl',
      'Check out Apolo.ma — Morocco’s classifieds & stores marketplace: $_shareUrl',
    );
    try {
      await Share.share(shareText, subject: AppConfig.appName);
    } catch (_) {
      await _copyLink();
    }
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
                      'مشاركة التطبيق',
                      'Partager l’app',
                      'Share App',
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
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: palette.ink,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      CupertinoIcons.sparkles,
                                      size: 28,
                                      color: palette.onInk,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    AppConfig.appName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: palette.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s.tr(
                                      'سوقك الأول للإعلانات المبوبة والمتاجر فالمغرب. شارك التطبيق مع أصدقائك وعائلتك.',
                                      'La marketplace marocaine pour acheter, vendre et découvrir les boutiques officielles.',
                                      'Morocco’s marketplace for classifieds and official stores. Share with friends and family.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.45,
                                      color: palette.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.bg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _shareUrl,
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: palette.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_copied) ...[
                              const SizedBox(height: 16),
                              ApoloDlAlert(
                                message: s.tr(
                                  'تم نسخ رابط التطبيق بنجاح: $_shareUrl',
                                  'Lien copié avec succès : $_shareUrl',
                                  'App link copied: $_shareUrl',
                                ),
                                type: ApoloDlAlertType.success,
                              ),
                            ],
                            const SizedBox(height: 20),
                            ApoloDlButton(
                              key: const Key('share-app-now'),
                              label: s.tr(
                                'مشاركة الآن',
                                'Partager maintenant',
                                'Share now',
                              ),
                              leadingIcon:
                                  CupertinoIcons.arrowshape_turn_up_right_fill,
                              variant: ApoloDlButtonVariant.primary,
                              fullWidth: true,
                              onPressed: _shareNow,
                            ),
                            const SizedBox(height: 10),
                            ApoloDlButton(
                              key: const Key('share-app-copy-link'),
                              label: s.tr(
                                'نسخ الرابط',
                                'Copier le lien',
                                'Copy link',
                              ),
                              leadingIcon: CupertinoIcons.doc_on_clipboard,
                              variant: ApoloDlButtonVariant.secondary,
                              fullWidth: true,
                              onPressed: _copyLink,
                            ),
                            const SizedBox(height: 10),
                            ApoloDlButton(
                              key: const Key('share-app-add-friends'),
                              label: s.tr(
                                'أضف أصدقاءك (Contacts)',
                                'Ajouter des amis',
                                'Add your friends',
                              ),
                              leadingIcon: CupertinoIcons.person_2_fill,
                              variant: ApoloDlButtonVariant.secondary,
                              fullWidth: true,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AddFriendsScreen(),
                                ),
                              ),
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
