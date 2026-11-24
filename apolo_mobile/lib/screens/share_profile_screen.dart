import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/state/app_state.dart';
import '../widgets/dl_qr_code.dart';
import '../widgets/dl_settings_kit.dart';
import 'scan_profile_code_screen.dart';

/// Dynamic Layer v5.1 `Share profile / Default` screen.
/// Displays a rounded `#EEEEEE` QR card with the user's real ISO/IEC 18004 QR code,
/// name, `@handle`, privacy caption, native top-right share trigger, and bottom
/// `Scan code` pill CTA launching [ScanProfileCodeScreen].
class ShareProfileScreen extends StatefulWidget {
  const ShareProfileScreen({
    required this.displayName,
    required this.handle,
    required this.profileUrl,
    super.key,
    this.userId,
    this.enableLiveCamera = true,
  });

  final String displayName;
  final String handle;
  final String profileUrl;
  final int? userId;
  final bool enableLiveCamera;

  @override
  State<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends State<ShareProfileScreen> {
  final AppState _state = AppState();

  String get _normalizedHandle {
    final trimmed = widget.handle.trim();
    if (trimmed.isEmpty) return '@apolo_user';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  Future<void> _copyProfileLink() async {
    HapticFeedback.selectionClick();
    final s = _state.s;
    try {
      await Clipboard.setData(ClipboardData(text: widget.profileUrl));
    } catch (_) {}
    _showSnack(
      s.tr(
        'تم نسخ رابط الملف الشخصي',
        'Lien du profil copié',
        'Profile link copied',
      ),
    );
  }

  Future<void> _shareNative() async {
    HapticFeedback.selectionClick();
    final s = _state.s;
    final name = widget.displayName.trim();
    final handle = _normalizedHandle;
    final url = widget.profileUrl;
    final shareText = s.tr(
      'شوف حساب $name ($handle) على Apolo.ma:\n$url',
      'Découvrez le profil de $name ($handle) sur Apolo.ma :\n$url',
      'Check out $name ($handle) on Apolo.ma:\n$url',
    );
    try {
      await Share.share(shareText, subject: name);
    } catch (_) {
      await _copyProfileLink();
    }
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanProfileCodeScreen(
          enableLiveCamera: widget.enableLiveCamera,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;
        final palette = ApoloDlPalette.of(context);
        final backIcon =
            isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 56,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              ApoloDlIconCircleButton(
                                key: const Key('share-profile-back-btn'),
                                icon: backIcon,
                                tooltip: MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                              const Spacer(),
                              Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: const Key('share-profile-native-btn'),
                                  onTap: _shareNative,
                                  customBorder: const CircleBorder(),
                                  child: Tooltip(
                                    message: s.tr(
                                      'مشاركة الرابط',
                                      'Partager le lien',
                                      'Share link',
                                    ),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                        child: Icon(
                                          CupertinoIcons
                                              .arrowshape_turn_up_right_fill,
                                          size: 22,
                                          color: palette.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 12, 24, 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: _copyProfileLink,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 276,
                                            ),
                                            child: Container(
                                              key: const Key(
                                                  'share-profile-qr-card'),
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      22, 22, 22, 20),
                                              decoration: BoxDecoration(
                                                color: palette.groupCard,
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  AspectRatio(
                                                    aspectRatio: 1,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      child: ApoloDlQrCode(
                                                        key: const Key(
                                                            'share-profile-qr-code'),
                                                        data: widget.profileUrl,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 18),
                                                  Text(
                                                    widget.displayName.trim(),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: palette.ink,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    _normalizedHandle,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textDirection:
                                                        TextDirection.ltr,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: palette.muted,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 288,
                                          ),
                                          child: Text(
                                            s.tr(
                                              'رمز QR الخاص بك خاص. إذا شاركته مع شخص ما، يمكنه مسحه بالكاميرا للوصول إلى ملفك الشخصي.',
                                              'Votre code QR est privé. Si vous le partagez, la personne pourra le scanner avec sa caméra pour voir votre profil.',
                                              'Your QR code is private. If you share it with someone, that person can scan it with their camera to view your profile.',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              height: 1.48,
                                              color: palette.muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Center(
                          child: ApoloDlButton(
                            key: const Key('share-profile-scan-btn'),
                            label: s.tr(
                              'مسح الرمز',
                              'Scanner le code',
                              'Scan code',
                            ),
                            leadingIcon: Icons.qr_code_scanner_rounded,
                            variant: ApoloDlButtonVariant.primary,
                            size: ApoloDlButtonSize.md,
                            height: 48,
                            borderRadius: 999,
                            fullWidth: false,
                            onPressed: _openScanner,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
