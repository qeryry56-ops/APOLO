import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_qr_code.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/dl_share_top_nav.dart';
import 'scan_profile_code_screen.dart';

/// Dynamic Layer v5.1 `Share profile / Default` screen.
/// Uses [DlShareProfileTokens] and [DlShareProfileLayout] to preserve exact
/// Figma geometry (`284x364` rounded-5xl card, `220x220` rounded-xl container,
/// `160x160` QR vector at `(30, 30)`, `24px` identity rows, and `311px` caption).
class ShareProfileScreen extends StatefulWidget {
  const ShareProfileScreen({
    required this.displayName,
    required this.handle,
    required this.profileUrl,
    super.key,
    this.title,
    this.userId,
    this.enableLiveCamera = true,
  });

  final String displayName;
  final String handle;
  final String profileUrl;
  final String? title;
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
        final tokens = DlShareProfileTokens.of(context);
        final mediaPadding = MediaQuery.paddingOf(context);
        final screenHeight = MediaQuery.sizeOf(context).height;
        final bottomInset = screenHeight >= 700
            ? math.max(DlShareProfileLayout.homeIndicatorHeight, mediaPadding.bottom)
            : mediaPadding.bottom;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: tokens.scaffoldBackground,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DlShareProfileLayout.canvasWidth,
                ),
                child: Column(
                  children: [
                    DlShareTopNavigation(
                      tokens: tokens,
                      headerKey: const Key('share-profile-header'),
                      wrapperKey: const Key('share-profile-top-wrapper'),
                      backButtonKey: const Key('share-profile-back-btn'),
                      titleKey: const Key('share-profile-title'),
                      title: widget.title,
                      onBack: () => Navigator.of(context).maybePop(),
                      trailing: Material(
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
                              width: DlShareProfileLayout.topNavActionSize,
                              height: DlShareProfileLayout.topNavActionSize,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons
                                      .arrowshape_turn_up_right_fill,
                                  size: 22,
                                  color: tokens.ink,
                                ),
                              ),
                            ),
                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: DlShareProfileLayout
                                        .screenHorizontalPadding,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: _copyProfileLink,
                                        child: Container(
                                          key: const Key(
                                              'share-profile-qr-card'),
                                          padding: const EdgeInsets.all(
                                            DlShareProfileLayout
                                                .outerCardPadding,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tokens.cardBackground,
                                            borderRadius: BorderRadius.circular(
                                              tokens.radii.rounded5Xl,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                key: const Key(
                                                    'share-profile-qr-inner'),
                                                width: DlShareProfileLayout
                                                    .innerQrSize,
                                                height: DlShareProfileLayout
                                                    .innerQrSize,
                                                decoration: BoxDecoration(
                                                  color: tokens.qrBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    tokens.radii.roundedXl,
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      top: DlShareProfileLayout
                                                          .qrCodeOffset,
                                                      left: DlShareProfileLayout
                                                          .qrCodeOffset,
                                                      width:
                                                          DlShareProfileLayout
                                                              .qrCodeSize,
                                                      height:
                                                          DlShareProfileLayout
                                                              .qrCodeSize,
                                                      child: SizedBox(
                                                        key: const Key(
                                                            'share-profile-qr-code-box'),
                                                        width:
                                                            DlShareProfileLayout
                                                                .qrCodeSize,
                                                        height:
                                                            DlShareProfileLayout
                                                                .qrCodeSize,
                                                        child: ApoloDlQrCode(
                                                          key: const Key(
                                                              'share-profile-qr-code'),
                                                          data:
                                                              widget.profileUrl,
                                                          foregroundColor:
                                                              tokens
                                                                  .qrForeground,
                                                          backgroundColor:
                                                              tokens
                                                                  .qrBackground,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                height: DlShareProfileLayout
                                                    .sectionGap,
                                              ),
                                              ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                  maxWidth: DlShareProfileLayout
                                                      .innerQrSize,
                                                ),
                                                child: Column(
                                                  key: const Key(
                                                      'share-profile-identity-group'),
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      key: const Key(
                                                          'share-profile-display-name'),
                                                      height:
                                                          DlShareProfileLayout
                                                              .identityLineHeight,
                                                      child: Center(
                                                        widthFactor: 1,
                                                        child: Text(
                                                          widget.displayName
                                                              .trim(),
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: tokens
                                                              .textBaseBold,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      key: const Key(
                                                          'share-profile-handle'),
                                                      height:
                                                          DlShareProfileLayout
                                                              .identityLineHeight,
                                                      child: Center(
                                                        widthFactor: 1,
                                                        child: Text(
                                                          _normalizedHandle,
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textDirection:
                                                              TextDirection.ltr,
                                                          style: tokens
                                                              .textBaseRegular,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height:
                                            DlShareProfileLayout.sectionGap,
                                      ),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: DlShareProfileLayout
                                              .privacyMaxWidth,
                                          minHeight: DlShareProfileLayout
                                              .privacyMinHeight,
                                        ),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            s.tr(
                                              'رمز QR الخاص بك خاص. إذا شاركته مع شخص ما، يمكنه مسحه بالكاميرا لإضافتك كجهة اتصال.',
                                              'Votre code QR est privé. Si vous le partagez, la personne pourra le scanner avec sa caméra pour vous ajouter comme contact.',
                                              'Your QR code is private. If you share it with someone, that person can scan it with their camera to add you as a contact.',
                                            ),
                                            key: const Key(
                                                'share-profile-privacy-text'),
                                            textAlign: TextAlign.center,
                                            style: tokens.textSmRegular,
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
                    SizedBox(
                      key: const Key('share-profile-bottom-bar'),
                      height: DlShareProfileLayout.bottomBarHeight,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          DlShareProfileLayout.bottomBarPadding,
                        ),
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
                            borderRadius: tokens.radii.pill,
                            fullWidth: false,
                            onPressed: _openScanner,
                          ),
                        ),
                      ),
                    ),
                    if (bottomInset > 0) SizedBox(height: bottomInset),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
