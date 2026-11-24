import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_qr_code.dart';
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

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: tokens.scaffoldBackground,
            body: Column(
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
                            child: Transform.flip(
                              flipX: isAr,
                              child: Icon(
                                CupertinoIcons.arrowshape_turn_up_right_fill,
                                size: DlShareProfileLayout.cameraIconSize,
                                color: tokens.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxW = constraints.maxWidth;
                                final horizontalPadding = maxW < 348.0
                                    ? DlShareProfileLayout.p16
                                    : DlShareProfileLayout
                                        .screenHorizontalPadding;
                                final cardPadding = maxW < 316.0
                                    ? 24.0
                                    : DlShareProfileLayout.outerCardPadding;
                                final innerQrSize = maxW < 316.0
                                    ? (maxW -
                                            horizontalPadding * 2 -
                                            cardPadding * 2)
                                        .clamp(
                                            140.0,
                                            DlShareProfileLayout.innerQrSize)
                                    : DlShareProfileLayout.innerQrSize;
                                final qrCodeSize = maxW < 316.0
                                    ? innerQrSize *
                                        (DlShareProfileLayout.qrCodeSize /
                                            DlShareProfileLayout.innerQrSize)
                                    : DlShareProfileLayout.qrCodeSize;
                                final qrCodeOffset =
                                    (innerQrSize - qrCodeSize) / 2.0;

                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          horizontalPadding,
                                          DlShareProfileLayout.p16,
                                          horizontalPadding,
                                          0,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: _copyProfileLink,
                                              child: Container(
                                                key: const Key(
                                                    'share-profile-qr-card'),
                                                padding:
                                                    EdgeInsets.all(cardPadding),
                                                decoration: BoxDecoration(
                                                  color: tokens.cardBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    tokens.radii.rounded5Xl,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      key: const Key(
                                                          'share-profile-qr-inner'),
                                                      width: innerQrSize,
                                                      height: innerQrSize,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            tokens.qrBackground,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          tokens
                                                              .radii.roundedXl,
                                                        ),
                                                      ),
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.topLeft,
                                                        textDirection:
                                                            TextDirection.ltr,
                                                        children: [
                                                          Positioned(
                                                            top: qrCodeOffset,
                                                            left: qrCodeOffset,
                                                            width: qrCodeSize,
                                                            height: qrCodeSize,
                                                            child: SizedBox(
                                                              key: const Key(
                                                                  'share-profile-qr-code-box'),
                                                              width: qrCodeSize,
                                                              height:
                                                                  qrCodeSize,
                                                              child:
                                                                  ApoloDlQrCode(
                                                                key: const Key(
                                                                    'share-profile-qr-code'),
                                                                data: widget
                                                                    .profileUrl,
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
                                                      height:
                                                          DlShareProfileLayout
                                                              .sectionGap,
                                                    ),
                                                    ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                        maxWidth: innerQrSize,
                                                      ),
                                                      child: Column(
                                                        key: const Key(
                                                            'share-profile-identity-group'),
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
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
                                                                widget
                                                                    .displayName
                                                                    .trim(),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                strutStyle:
                                                                    const StrutStyle(
                                                                  fontSize:
                                                                      DlShareProfileTypography
                                                                          .fontSize3,
                                                                  height: DlShareProfileTypography
                                                                          .fontLineHeight3 /
                                                                      DlShareProfileTypography
                                                                          .fontSize3,
                                                                  forceStrutHeight:
                                                                      true,
                                                                ),
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
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textDirection:
                                                                    TextDirection
                                                                        .ltr,
                                                                strutStyle:
                                                                    const StrutStyle(
                                                                  fontSize:
                                                                      DlShareProfileTypography
                                                                          .fontSize3,
                                                                  height: DlShareProfileTypography
                                                                          .fontLineHeight3 /
                                                                      DlShareProfileTypography
                                                                          .fontSize3,
                                                                  forceStrutHeight:
                                                                      true,
                                                                ),
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
                                              height: DlShareProfileLayout
                                                  .sectionGap,
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
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                DlShareProfileLayout.scanButtonBarPadding,
                                DlShareProfileLayout.scanButtonBarPadding,
                                DlShareProfileLayout.scanButtonBarPadding,
                                DlShareProfileLayout.scanButtonBarPadding +
                                    mediaPadding.bottom,
                              ),
                              child: Center(
                                child: _ShareScanCodeButton(
                                  key: const Key('share-profile-scan-btn'),
                                  label: s.tr(
                                    'مسح الرمز',
                                    'Scanner le code',
                                    'Scan code',
                                  ),
                                  tokens: tokens,
                                  onPressed: _openScanner,
                                ),
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
        );
      },
    );
  }
}

class _ShareScanCodeButton extends StatefulWidget {
  const _ShareScanCodeButton({
    required this.label,
    required this.tokens,
    required this.onPressed,
    super.key,
  });

  final String label;
  final DlShareProfileTokens tokens;
  final VoidCallback onPressed;

  @override
  State<_ShareScanCodeButton> createState() => _ShareScanCodeButtonState();
}

class _ShareScanCodeButtonState extends State<_ShareScanCodeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final radius = BorderRadius.circular(tokens.radii.roundedFull);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Material(
        color: tokens.primaryButtonBackground,
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
          child: SizedBox(
            height: DlShareProfileLayout.scanButtonHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DlShareProfileLayout.scanButtonHorizontalPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DlScanViewfinderIcon(
                    size: DlShareProfileLayout.scanButtonIconSize,
                    color: tokens.primaryButtonForeground,
                  ),
                  const SizedBox(width: DlShareProfileLayout.scanButtonIconGap),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      strutStyle: const StrutStyle(
                        fontSize: DlShareProfileTypography.fontSize3,
                        height: DlShareProfileTypography.fontLineHeight3 /
                            DlShareProfileTypography.fontSize3,
                        forceStrutHeight: true,
                      ),
                      style: tokens.textBaseBold.copyWith(
                        color: tokens.primaryButtonForeground,
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
  }
}

/// Exact Dynamic Layer v5.1 `iconset/scan` `24x24` vector icon:
/// four rounded corner brackets with a centered horizontal scan bar.
class _DlScanViewfinderIcon extends StatelessWidget {
  const _DlScanViewfinderIcon({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DlScanViewfinderPainter(color: color),
      ),
    );
  }
}

class _DlScanViewfinderPainter extends CustomPainter {
  const _DlScanViewfinderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const min = 3.5;
    const max = 20.5;
    const r = 2.5;
    const arm = 4.5;

    final path = Path()
      // Top-left bracket
      ..moveTo(min * s, (min + arm) * s)
      ..lineTo(min * s, (min + r) * s)
      ..arcToPoint(
        Offset((min + r) * s, min * s),
        radius: Radius.circular(r * s),
      )
      ..lineTo((min + arm) * s, min * s)
      // Top-right bracket
      ..moveTo((max - arm) * s, min * s)
      ..lineTo((max - r) * s, min * s)
      ..arcToPoint(
        Offset(max * s, (min + r) * s),
        radius: Radius.circular(r * s),
      )
      ..lineTo(max * s, (min + arm) * s)
      // Bottom-left bracket
      ..moveTo(min * s, (max - arm) * s)
      ..lineTo(min * s, (max - r) * s)
      ..arcToPoint(
        Offset((min + r) * s, max * s),
        radius: Radius.circular(r * s),
      )
      ..lineTo((min + arm) * s, max * s)
      // Bottom-right bracket
      ..moveTo((max - arm) * s, max * s)
      ..lineTo((max - r) * s, max * s)
      ..arcToPoint(
        Offset(max * s, (max - r) * s),
        radius: Radius.circular(r * s),
      )
      ..lineTo(max * s, (max - arm) * s)
      // Center scan line
      ..moveTo(7.0 * s, 12.0 * s)
      ..lineTo(17.0 * s, 12.0 * s);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DlScanViewfinderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
