import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/services/qr_web_bridge.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_qr_code.dart';
import '../widgets/dl_settings_kit.dart';
import 'ad_detail_screen.dart';
import 'seller_profile_screen.dart';
import 'store_detail_screen.dart';
import '../l10n/l10n.dart';

/// Minimalist Trust Wallet-style full-screen QR Scanner with RTL Arabic support:
/// - Full-screen camera preview (`#000000` / `#121212` dark canvas)
/// - `rgba(0, 0, 0, 0.65)` translucent vignette mask with a centered `270x270` cutout
/// - Four outer rounded corner brackets (`6px` stroke, `28px` radius, `48px` arm, `StrokeCap.round`)
/// - Subtle `#E31B23` animated laser scan pulse inside the frame
/// - Minimalist white top bar (RTL-aware back arrow, `17px w600` title, gallery action)
/// - Centered `"إدخال الرمز يدوياً"` action & subtle glass flashlight toggle above Home Indicator.
class ScanProfileCodeScreen extends StatefulWidget {
  const ScanProfileCodeScreen({
    super.key,
    this.title,
    this.enableLiveCamera = true,
    this.onCodeScanned,
  });

  static const double viewfinderSize = 270.0;
  static const double cornerRadius = 28.0;
  static const double cornerBracketLength = 44.0;
  static const double cornerStrokeWidth = 5.5;
  static const double verticalCenterOffset = -30.0;
  static const Color darkCanvas = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color maskOverlayColor = Color.fromRGBO(0, 0, 0, 0.65);
  static const Color activePulseRed = Color(0xFFE31B23);

  final String? title;
  final bool enableLiveCamera;
  final void Function(String rawValue)? onCodeScanned;

  /// Resolves a parsed [ApoloQrTarget] against live Apolo endpoints and opens
  /// the matching profile, store, or listing screen. Used by both the in-app
  /// QR scanner and cold-start deep links (`SplashScreen`).
  static Future<void> navigateToQrTarget(
    BuildContext context,
    ApoloQrTarget target, {
    bool replaceCurrentRoute = true,
  }) async {
    final state = AppState();
    final s = state.s;

    void showToast(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message),
          ),
        );
    }

    Future<void> openRoute(Widget page) async {
      if (!context.mounted) return;
      final route = MaterialPageRoute<void>(builder: (_) => page);
      if (replaceCurrentRoute) {
        await Navigator.of(context).pushReplacement(route);
      } else {
        await Navigator.of(context).push(route);
      }
    }

    switch (target.type) {
      case ApoloQrTargetType.user:
        final sellerId = target.id!;
        final myId = int.tryParse('${state.currentUser?['id'] ?? ''}');
        if (myId != null && myId == sellerId) {
          showToast(
            s.tr(
              'هذا هو ملفك الشخصي الحالي',
              'Ceci est déjà votre profil',
              appL10n.scanProfileCodeThisIsOwnProfile,
            ),
          );
          if (replaceCurrentRoute && context.mounted) {
            await Navigator.of(context).maybePop();
          }
          return;
        }

        String name = (target.displayName != null &&
                target.displayName!.trim().isNotEmpty)
            ? target.displayName!.trim()
            : (target.handle != null && target.handle!.trim().isNotEmpty
                ? target.handle!.trim()
                : s.tr(
                    'مستخدم Apolo #$sellerId',
                    'Membre Apolo #$sellerId',
                    appL10n.scanProfileCodeApoloMemberSellerid(sellerId),
                  ));
        String? handle = target.handle;
        String? avatar;
        String? phone;
        String? city;
        Map<String, dynamic>? initialAd;

        try {
          final res = await state.api.dio.get(
            '/ads',
            queryParameters: {'per_page': 1, 'seller_id': sellerId},
          );
          if (res.data is Map && res.data['data'] is List) {
            final list = res.data['data'] as List;
            if (list.isNotEmpty && list.first is Map) {
              final firstAd = Map<String, dynamic>.from(list.first as Map);
              initialAd = firstAd;
              final user = firstAd['user'] is Map
                  ? Map<String, dynamic>.from(firstAd['user'] as Map)
                  : null;
              final fetchedName =
                  (user?['name'] ?? firstAd['seller_name'] ?? '')
                      .toString()
                      .trim();
              if (fetchedName.isNotEmpty) name = fetchedName;
              final fetchedUsername =
                  (user?['username'] ?? '').toString().trim();
              if (fetchedUsername.isNotEmpty) handle = fetchedUsername;
              final fetchedAvatar =
                  (user?['avatar'] ?? firstAd['seller_avatar'] ?? '')
                      .toString()
                      .trim();
              if (fetchedAvatar.isNotEmpty) avatar = fetchedAvatar;
              final fetchedPhone =
                  (user?['phone'] ?? firstAd['phone'] ?? '').toString().trim();
              if (fetchedPhone.isNotEmpty) phone = fetchedPhone;
              final rawCity = firstAd['city'] is Map
                  ? firstAd['city']['name']
                  : (firstAd['city_name'] ?? user?['city']);
              final fetchedCity = rawCity?.toString().trim();
              if (fetchedCity != null && fetchedCity.isNotEmpty) {
                city = fetchedCity;
              }
            }
          }
        } catch (_) {}

        await openRoute(
          SellerProfileScreen(
            sellerId: sellerId,
            sellerName: name,
            sellerHandle: handle,
            sellerAvatar: avatar,
            sellerPhone: phone,
            sellerCity: city,
            initialAd: initialAd,
          ),
        );
        return;

      case ApoloQrTargetType.handle:
        final cleanHandle = (target.handle ?? '')
            .trim()
            .replaceFirst(RegExp(r'^@+'), '')
            .trim();
        final myUsername = (state.currentUser?['username'] ?? '')
            .toString()
            .trim()
            .replaceFirst(RegExp(r'^@+'), '')
            .toLowerCase();
        if (myUsername.isNotEmpty && cleanHandle.toLowerCase() == myUsername) {
          showToast(
            s.tr(
              'هذا هو ملفك الشخصي الحالي',
              'Ceci est déjà votre profil',
              appL10n.scanProfileCodeThisIsOwnProfile,
            ),
          );
          if (replaceCurrentRoute && context.mounted) {
            await Navigator.of(context).maybePop();
          }
          return;
        }

        try {
          final encoded = Uri.encodeComponent(cleanHandle);
          final storeRes = await state.api.dio.get('/stores/$encoded');
          if (storeRes.data is Map &&
              storeRes.data['status'] == 'success' &&
              storeRes.data['store'] != null) {
            await openRoute(StoreDetailScreen(subdomain: cleanHandle));
            return;
          }
        } catch (_) {}

        int? matchedSellerId;
        String matchedName = (target.displayName != null &&
                target.displayName!.trim().isNotEmpty)
            ? target.displayName!.trim()
            : cleanHandle;
        String? matchedAvatar;
        String? matchedPhone;
        String? matchedCity;
        Map<String, dynamic>? matchedAd;

        try {
          final searchRes = await state.api.dio.get(
            '/ads',
            queryParameters: {'per_page': 10, 'search': cleanHandle},
          );
          if (searchRes.data is Map && searchRes.data['data'] is List) {
            final list = searchRes.data['data'] as List;
            for (final rawItem in list) {
              if (rawItem is! Map) continue;
              final ad = Map<String, dynamic>.from(rawItem);
              final user = ad['user'] is Map
                  ? Map<String, dynamic>.from(ad['user'] as Map)
                  : null;
              final uHandle =
                  (user?['username'] ?? '').toString().trim().toLowerCase();
              final uName = (user?['name'] ?? ad['seller_name'] ?? '')
                  .toString()
                  .trim();
              final normalizedUName = uName
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                  .replaceAll(RegExp(r'^_+|_+$'), '');
              if (uHandle == cleanHandle.toLowerCase() ||
                  normalizedUName == cleanHandle.toLowerCase()) {
                final uid =
                    int.tryParse('${user?['id'] ?? ad['user_id'] ?? ''}');
                if (uid != null && uid > 0) {
                  matchedSellerId = uid;
                  if (uName.isNotEmpty) matchedName = uName;
                  final av = (user?['avatar'] ?? ad['seller_avatar'] ?? '')
                      .toString()
                      .trim();
                  if (av.isNotEmpty) matchedAvatar = av;
                  final ph = (user?['phone'] ?? ad['phone'] ?? '')
                      .toString()
                      .trim();
                  if (ph.isNotEmpty) matchedPhone = ph;
                  final rawCity = ad['city'] is Map
                      ? ad['city']['name']
                      : (ad['city_name'] ?? user?['city']);
                  final cStr = rawCity?.toString().trim();
                  if (cStr != null && cStr.isNotEmpty) matchedCity = cStr;
                  matchedAd = ad;
                  break;
                }
              }
            }
          }
        } catch (_) {}

        final resolvedId = matchedSellerId ??
            (100000 +
                (cleanHandle
                        .toLowerCase()
                        .codeUnits
                        .fold<int>(0, (h, c) => ((h * 31) + c) & 0x3FFFFFFF) %
                    899999));

        await openRoute(
          SellerProfileScreen(
            sellerId: resolvedId,
            sellerName: matchedName,
            sellerHandle: cleanHandle,
            sellerAvatar: matchedAvatar,
            sellerPhone: matchedPhone,
            sellerCity: matchedCity,
            initialAd: matchedAd,
          ),
        );
        return;

      case ApoloQrTargetType.store:
        await openRoute(StoreDetailScreen(subdomain: target.handle!));
        return;

      case ApoloQrTargetType.ad:
        await openRoute(AdDetailScreen(adId: target.id!));
        return;

      case ApoloQrTargetType.external:
      case ApoloQrTargetType.unknown:
        if (!context.mounted) return;
        final palette = ApoloDlPalette.of(context);
        final externalUri = target.type == ApoloQrTargetType.external
            ? Uri.tryParse(target.rawValue)
            : null;
        await showApoloDlBottomSheet<void>(
          context,
          headerTitle: s.tr('رمز ممسوح', 'Code scanné', appL10n.scanProfileCodeScannedCode),
          media: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.groupCard,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.qrcode,
              size: 28,
              color: palette.ink,
            ),
          ),
          contentTitle:
              s.tr('تمت قراءة الرمز', 'Code détecté', appL10n.scanProfileCodeCodeDetected),
          contentDescription: target.rawValue,
          actions: [
            if (externalUri != null)
              ApoloDlButton(
                label: s.tr('فتح الرابط', 'Ouvrir le lien', appL10n.scanProfileCodeOpenLink),
                variant: ApoloDlButtonVariant.primary,
                borderRadius: 999,
                fullWidth: true,
                onPressed: () async {
                  if (context.mounted) Navigator.of(context).pop();
                  try {
                    await launchUrl(
                      externalUri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                },
              ),
            ApoloDlButton(
              label: s.tr('نسخ', 'Copier', appL10n.adDetailCopy),
              variant: externalUri != null
                  ? ApoloDlButtonVariant.secondary
                  : ApoloDlButtonVariant.primary,
              borderRadius: 999,
              fullWidth: true,
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: target.rawValue));
                } catch (_) {}
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showToast(s.tr('تم النسخ', 'Copié', appL10n.chatRoomCopied));
                }
              },
            ),
            ApoloDlButton(
              label: s.tr('مسح من جديد', 'Scanner encore', appL10n.scanProfileCodeScanAgain),
              variant: ApoloDlButtonVariant.secondary,
              borderRadius: 999,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
        return;
    }
  }

  @override
  State<ScanProfileCodeScreen> createState() => _ScanProfileCodeScreenState();
}

class _ScanProfileCodeScreenState extends State<ScanProfileCodeScreen>
    with SingleTickerProviderStateMixin {
  static int _nextWebSessionId = 1;

  final AppState _state = AppState();
  MobileScannerController? _controller;
  late final AnimationController _laserController;
  late int _webSessionId;
  bool _webCameraStreaming = false;
  bool _webCameraError = false;
  bool _isHandlingCode = false;
  bool _pickingGallery = false;
  bool _webTorchOn = false;

  bool get _isWidgetTest =>
      !kIsWeb &&
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  bool get _shouldUseLiveScanner => widget.enableLiveCamera && !_isWidgetTest;

  @override
  void initState() {
    super.initState();
    _webSessionId = _nextWebSessionId++;
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
      value: 0.5,
    );
    if (!_isWidgetTest) {
      _laserController.repeat(reverse: true);
    }
    if (_shouldUseLiveScanner && !kIsWeb) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || _isWidgetTest) {
      if (_laserController.isAnimating) {
        _laserController.stop();
        _laserController.value = 0.5;
      }
    } else if (!_laserController.isAnimating) {
      _laserController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    if (kIsWeb) {
      QrWebBridge.stopWebScanner();
    }
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  void _retryWebCamera() {
    HapticFeedback.selectionClick();
    setState(() {
      _webCameraError = false;
      _webCameraStreaming = false;
      _webSessionId = _nextWebSessionId++;
    });
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
          action: action,
        ),
      );
  }

  Future<void> _toggleTorch() async {
    final s = _state.s;

    if (kIsWeb) {
      final nextState = await QrWebBridge.toggleWebTorch(_webTorchOn);
      if (nextState != null) {
        HapticFeedback.selectionClick();
        if (mounted) setState(() => _webTorchOn = nextState);
        return;
      }
      _showSnack(
        s.tr(
          'الفلاش غير مدعوم في متصفح هذا الجهاز',
          'Le flash n’est pas pris en charge sur ce navigateur',
          appL10n.scanProfileCodeFlashlightIsUnavailableThisBrowser,
        ),
      );
      return;
    }

    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isRunning ||
        controller.value.torchState == TorchState.unavailable) {
      _showSnack(
        s.tr(
          'الفلاش غير متاح على هذا الجهاز',
          'Le flash est indisponible sur cet appareil',
          appL10n.scanProfileCodeFlashlightIsUnavailableThisCamera,
        ),
      );
      return;
    }

    try {
      HapticFeedback.selectionClick();
      await controller.toggleTorch();
    } catch (_) {
      _showSnack(
        s.tr(
          'تعذر تشغيل الفلاش حالياً',
          'Impossible d’activer le flash pour le moment',
          appL10n.scanProfileCodeCouldNotToggleFlashlightRight,
        ),
      );
    }
  }

  Future<void> _pickImageAndAnalyze() async {
    if (_pickingGallery) return;
    _pickingGallery = true;
    HapticFeedback.selectionClick();
    final s = _state.s;

    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null || !mounted) return;

      if (kIsWeb) {
        try {
          final bytes = await picked.readAsBytes();
          final decoded = await QrWebBridge.decodeImageBytes(bytes);
          if (decoded != null && decoded.trim().isNotEmpty) {
            await handleScannedPayload(decoded.trim());
            return;
          }
        } catch (_) {}
      } else {
        final controller = _controller;
        if (controller != null) {
          try {
            final BarcodeCapture? capture = await controller.analyzeImage(
              picked.path,
              formats: const [BarcodeFormat.qrCode],
            );
            final raw = capture?.barcodes
                .map((b) => (b.rawValue ?? '').trim())
                .firstWhere((v) => v.isNotEmpty, orElse: () => '');
            if (raw != null && raw.isNotEmpty) {
              await handleScannedPayload(raw);
              return;
            }
          } catch (_) {}
        }
      }

      _showSnack(
        s.tr(
          'لم يتم العثور على رمز QR في الصورة المختارة',
          'Aucun code QR détecté dans cette image',
          appL10n.scanProfileCodeNoQrCodeDetectedSelected,
        ),
        action: SnackBarAction(
          label: s.tr('أدخل الرمز', 'Saisir', appL10n.scanProfileCodeEnterCode),
          onPressed: _openManualCodeSheet,
        ),
      );
    } catch (_) {
      _showSnack(
        s.tr(
          'تعذر فتح معرض الصور',
          'Impossible d’ouvrir la galerie',
          appL10n.scanProfileCodeCouldNotOpenPhotoLibrary,
        ),
        action: SnackBarAction(
          label: s.tr('أدخل الرمز', 'Saisir', appL10n.scanProfileCodeEnterCode),
          onPressed: _openManualCodeSheet,
        ),
      );
    } finally {
      _pickingGallery = false;
    }
  }

  Future<void> _openManualCodeSheet() async {
    if (!mounted) return;
    HapticFeedback.selectionClick();
    final palette = ApoloDlPalette.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ManualCodeEntrySheet(
        strings: _state.s,
        isRtl: isRtl,
      ),
    );

    if (submitted != null && submitted.isNotEmpty && mounted) {
      await handleScannedPayload(submitted);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isHandlingCode) return;
    for (final barcode in capture.barcodes) {
      final raw = (barcode.rawValue ?? '').trim();
      if (raw.isNotEmpty) {
        handleScannedPayload(raw);
        return;
      }
    }
  }

  @visibleForTesting
  Future<void> handleScannedPayload(String rawValue) async {
    if (_isHandlingCode) return;
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return;

    setState(() => _isHandlingCode = true);
    HapticFeedback.mediumImpact();

    if (widget.onCodeScanned != null) {
      widget.onCodeScanned!(trimmed);
      if (mounted) setState(() => _isHandlingCode = false);
      return;
    }

    final target = ApoloProfileQrParser.parse(trimmed);
    await ScanProfileCodeScreen.navigateToQrTarget(
      context,
      target,
      replaceCurrentRoute: true,
    );
    if (mounted) {
      setState(() => _isHandlingCode = false);
    }
  }

  Widget _buildFullScreenCameraLayer(AppStrings s) {
    if (!_shouldUseLiveScanner) {
      return const ColoredBox(color: ScanProfileCodeScreen.darkSurface);
    }

    if (kIsWeb) {
      if (_webCameraError) {
        return const ColoredBox(color: ScanProfileCodeScreen.darkSurface);
      }
      final htmlView = QrWebBridge.buildWebScannerView(
        sessionKey: _webSessionId,
        onDetect: (raw) {
          if (raw.isNotEmpty) handleScannedPayload(raw);
        },
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'streaming') {
            if (!_webCameraStreaming || _webCameraError) {
              setState(() {
                _webCameraStreaming = true;
                _webCameraError = false;
              });
            }
          } else if (status.startsWith('error')) {
            if (!_webCameraError) {
              setState(() {
                _webCameraError = true;
                _webCameraStreaming = false;
              });
            }
          }
        },
      );
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: htmlView ??
              const ColoredBox(color: ScanProfileCodeScreen.darkCanvas),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const ColoredBox(color: ScanProfileCodeScreen.darkSurface);
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.expand(
        child: MobileScanner(
          controller: controller,
          fit: BoxFit.cover,
          onDetect: _onDetect,
          placeholderBuilder: (_) =>
              const ColoredBox(color: ScanProfileCodeScreen.darkCanvas),
          errorBuilder: (context, error) =>
              const ColoredBox(color: ScanProfileCodeScreen.darkSurface),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(AppStrings s, bool isAr, double topInset) {
    final effectiveTitle = (widget.title != null && widget.title!.trim().isNotEmpty)
        ? widget.title!.trim()
        : s.tr('مسح رمز QR', 'Scanner le code QR', appL10n.scanProfileCodeScanQrCode);

    return SizedBox(
      key: const Key('scan-code-header'),
      width: double.infinity,
      height: topInset + 56.0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          key: const Key('scan-code-top-wrapper'),
          width: double.infinity,
          height: 56.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('scan-code-back-btn'),
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: SizedBox(
                      width: 44.0,
                      height: 44.0,
                      child: Center(
                        child: Icon(
                          isAr
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    effectiveTitle,
                    key: const Key('scan-code-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17.0,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('scan-code-gallery-btn'),
                    customBorder: const CircleBorder(),
                    onTap: _pickImageAndAnalyze,
                    child: Tooltip(
                      message: s.tr(
                        'اختيار صورة من المعرض',
                        'Choisir une image',
                        appL10n.scanProfileCodePickQrImage,
                      ),
                      child: const SizedBox(
                        width: 44.0,
                        height: 44.0,
                        child: Center(
                          child: Icon(
                            Icons.image_rounded,
                            color: Colors.white,
                            size: 24.0,
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
      ),
    );
  }

  Widget _buildFlashButton() {
    final controller = _controller;
    if (!kIsWeb && controller != null) {
      return ValueListenableBuilder<MobileScannerState>(
        valueListenable: controller,
        builder: (context, state, _) {
          final on = state.torchState == TorchState.on;
          return _GlassTorchButton(
            key: const Key('scan-code-flash-btn'),
            active: on,
            onPressed: _toggleTorch,
          );
        },
      );
    }

    return _GlassTorchButton(
      key: const Key('scan-code-flash-btn'),
      active: _webTorchOn,
      onPressed: _toggleTorch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;
        final mediaPadding = MediaQuery.paddingOf(context);
        final screenSize = MediaQuery.sizeOf(context);
        final bottomInset = DlShareProfileLayout.resolveBottomSafeInset(
          screenSize,
          mediaPadding,
        );

        // Centered 270x270px square window (adapting gracefully only on ultra-small <318px screens)
        final maxAllowedWidth = math.max(180.0, screenSize.width - 48.0);
        final maxAllowedHeight = math.max(
          180.0,
          screenSize.height - (mediaPadding.top + 56.0) - (bottomInset + 148.0),
        );
        final cutoutSide = math.min(
          ScanProfileCodeScreen.viewfinderSize,
          math.min(maxAllowedWidth, maxAllowedHeight),
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: ScanProfileCodeScreen.darkCanvas,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Scaffold(
              backgroundColor: ScanProfileCodeScreen.darkCanvas,
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final fullW = constraints.maxWidth;
                  final fullH = constraints.maxHeight;
                  final topSafeBound = mediaPadding.top + 56.0 + 16.0;
                  final bottomSafeBound =
                      fullH - (bottomInset + 132.0) - 16.0;
                  final desiredCenterY =
                      (fullH / 2.0) + ScanProfileCodeScreen.verticalCenterOffset;
                  final minCenterY = topSafeBound + (cutoutSide / 2.0);
                  final maxCenterY = bottomSafeBound - (cutoutSide / 2.0);
                  final resolvedCenterY = maxCenterY >= minCenterY
                      ? desiredCenterY.clamp(minCenterY, maxCenterY)
                      : fullH / 2.0;

                  final cutoutRect = Rect.fromCenter(
                    center: Offset(fullW / 2.0, resolvedCenterY),
                    width: cutoutSide,
                    height: cutoutSide,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Full-screen live camera preview underneath
                      Positioned.fill(
                        child: _buildFullScreenCameraLayer(s),
                      ),

                      // 2. Single dark translucent overlay (0.65) + rounded cutout + 4 outer convex corner brackets + laser line
                      Positioned.fill(
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(
                              begin: Colors.white,
                              end: _isHandlingCode
                                  ? ScanProfileCodeScreen.activePulseRed
                                  : Colors.white,
                            ),
                            duration: const Duration(milliseconds: 220),
                            builder: (context, animatedBracketColor, _) {
                              return AnimatedBuilder(
                                animation: _laserController,
                                builder: (context, _) {
                                  return SizedBox.expand(
                                    child: CustomPaint(
                                      painter:
                                          _TrustWalletScannerOverlayPainter(
                                        cutoutRect: cutoutRect,
                                        bracketColor:
                                            animatedBracketColor ?? Colors.white,
                                        laserProgress: _laserController.value,
                                        showLaser: !_webCameraError,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),

                      // Semantic / testable viewfinder target positioned at exact cutoutRect
                      Positioned.fromRect(
                        rect: cutoutRect,
                        child: GestureDetector(
                          key: const Key('scan-code-viewfinder'),
                          behavior: HitTestBehavior.translucent,
                          onTap: (kIsWeb && _webCameraError)
                              ? _retryWebCamera
                              : null,
                          child: (kIsWeb && _webCameraError)
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.camera_fill,
                                          color: Colors.white70,
                                          size: 32.0,
                                        ),
                                        const SizedBox(height: 10.0),
                                        Text(
                                          s.tr(
                                            'اضغط لتفعيل الكاميرا',
                                            'Appuyez pour activer la caméra',
                                            appL10n.scanProfileCodeTapEnableCamera,
                                          ),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                      ),

                      // 3. Minimalist Top App Bar
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildTopAppBar(s, isAr, mediaPadding.top),
                      ),

                      // 4. Bottom Action Area ("إدخال الرمز يدوياً" + subtle Torch toggle)
                      Positioned(
                        left: 16.0,
                        right: 16.0,
                        bottom: bottomInset + 24.0,
                        child: Column(
                          key: const Key('scan-code-controls-bar'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFlashButton(),
                            const SizedBox(height: 20.0),
                            Center(
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(999.0),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: const Key('scan-code-manual-btn'),
                                  borderRadius: BorderRadius.circular(999.0),
                                  onTap: _openManualCodeSheet,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18.0,
                                      vertical: 12.0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 18.0,
                                        ),
                                        const SizedBox(width: 8.0),
                                        Flexible(
                                          child: Text(
                                            s.tr(
                                              'إدخال الرمز يدوياً',
                                              'Saisir le code manuellement',
                                              appL10n.scanProfileCodeEnterCodeManually,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w500,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassTorchButton extends StatelessWidget {
  const _GlassTorchButton({
    required this.active,
    required this.onPressed,
    super.key,
  });

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? Colors.white
          : const Color.fromRGBO(255, 255, 255, 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44.0,
          height: 44.0,
          child: Center(
            child: Icon(
              active
                  ? Icons.flashlight_on_rounded
                  : Icons.flashlight_off_rounded,
              size: 20.0,
              color: active ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustWalletScannerOverlayPainter extends CustomPainter {
  const _TrustWalletScannerOverlayPainter({
    required this.cutoutRect,
    required this.bracketColor,
    required this.laserProgress,
    required this.showLaser,
  });

  final Rect cutoutRect;
  final Color bracketColor;
  final double laserProgress;
  final bool showLaser;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const radius = ScanProfileCodeScreen.cornerRadius;
    const arm = ScanProfileCodeScreen.cornerBracketLength;
    const strokeW = ScanProfileCodeScreen.cornerStrokeWidth;

    final rrect = RRect.fromRectAndRadius(
      cutoutRect,
      const Radius.circular(radius),
    );

    // 1. Dark translucent vignette (rgba(0, 0, 0, 0.65)) with crisp cutout
    final maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    final maskPaint = Paint()
      ..color = ScanProfileCodeScreen.maskOverlayColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(maskPath, maskPaint);

    // 2. Horizontal Crimson (#E31B23) laser line + subtle glow strictly clipped inside cutout
    if (showLaser) {
      const margin = 18.0;
      final minY = cutoutRect.top + radius;
      final maxY = cutoutRect.bottom - radius;
      if (maxY > minY) {
        final y = minY + (maxY - minY) * laserProgress;
        final laserRect = Rect.fromLTRB(
          cutoutRect.left + margin,
          y - 1.0,
          cutoutRect.right - margin,
          y + 1.0,
        );
        final glowRect = Rect.fromLTRB(
          cutoutRect.left + margin,
          y - 4.0,
          cutoutRect.right - margin,
          y + 4.0,
        );
        final gradient = LinearGradient(
          colors: [
            ScanProfileCodeScreen.activePulseRed.withValues(alpha: 0.0),
            ScanProfileCodeScreen.activePulseRed.withValues(alpha: 0.85),
            ScanProfileCodeScreen.activePulseRed.withValues(alpha: 0.0),
          ],
        );

        canvas.save();
        canvas.clipRRect(rrect);

        final glowPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              ScanProfileCodeScreen.activePulseRed.withValues(alpha: 0.0),
              ScanProfileCodeScreen.activePulseRed.withValues(alpha: 0.35),
              ScanProfileCodeScreen.activePulseRed.withValues(alpha: 0.0),
            ],
          ).createShader(glowRect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawRect(glowRect, glowPaint);

        final laserPaint = Paint()..shader = gradient.createShader(laserRect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(laserRect, const Radius.circular(2.0)),
          laserPaint,
        );

        canvas.restore();
      }
    }

    // 3. Four outer convex corner brackets (all 4 curving outward cleanly matching RRect radius)
    final l = cutoutRect.left;
    final t = cutoutRect.top;
    final r = cutoutRect.right;
    final b = cutoutRect.bottom;
    final clampedArm = math.min(arm, cutoutRect.width * 0.42);
    final clampedRadius = math.min(radius, clampedArm - 4.0);
    final diameter = clampedRadius * 2.0;

    final bracketPaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cornersPath = Path()
      // Top-Left (convex outward toward top-left)
      ..moveTo(l, t + clampedArm)
      ..lineTo(l, t + clampedRadius)
      ..arcTo(
        Rect.fromLTWH(l, t, diameter, diameter),
        math.pi,
        math.pi / 2.0,
        false,
      )
      ..lineTo(l + clampedArm, t)
      // Top-Right (convex outward toward top-right)
      ..moveTo(r - clampedArm, t)
      ..lineTo(r - clampedRadius, t)
      ..arcTo(
        Rect.fromLTWH(r - diameter, t, diameter, diameter),
        -math.pi / 2.0,
        math.pi / 2.0,
        false,
      )
      ..lineTo(r, t + clampedArm)
      // Bottom-Right (convex outward toward bottom-right)
      ..moveTo(r, b - clampedArm)
      ..lineTo(r, b - clampedRadius)
      ..arcTo(
        Rect.fromLTWH(r - diameter, b - diameter, diameter, diameter),
        0.0,
        math.pi / 2.0,
        false,
      )
      ..lineTo(r - clampedArm, b)
      // Bottom-Left (convex outward toward bottom-left)
      ..moveTo(l + clampedArm, b)
      ..lineTo(l + clampedRadius, b)
      ..arcTo(
        Rect.fromLTWH(l, b - diameter, diameter, diameter),
        math.pi / 2.0,
        math.pi / 2.0,
        false,
      )
      ..lineTo(l, b - clampedArm);

    canvas.drawPath(cornersPath, bracketPaint);
  }

  @override
  bool shouldRepaint(covariant _TrustWalletScannerOverlayPainter oldDelegate) {
    return oldDelegate.cutoutRect != cutoutRect ||
        oldDelegate.bracketColor != bracketColor ||
        oldDelegate.laserProgress != laserProgress ||
        oldDelegate.showLaser != showLaser;
  }
}

class _ManualCodeEntrySheet extends StatefulWidget {
  const _ManualCodeEntrySheet({
    required this.strings,
    required this.isRtl,
  });

  final AppStrings strings;
  final bool isRtl;

  @override
  State<_ManualCodeEntrySheet> createState() => _ManualCodeEntrySheetState();
}

class _ManualCodeEntrySheetState extends State<_ManualCodeEntrySheet> {
  final TextEditingController _inputController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _inputController.text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = widget.strings.tr(
          'المرجو إدخال رابط أو معرف صالح',
          'Veuillez saisir un lien valide',
          appL10n.scanProfileCodePleaseEnterLinkHandle,
        );
      });
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final palette = ApoloDlPalette.of(context);

    return Directionality(
      textDirection: widget.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                s.tr(
                  'إدخال الرمز يدوياً',
                  'Saisir le code manuellement',
                  appL10n.scanProfileCodeEnterCodeManually,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.tr(
                  'الصق رابط الحساب (apolo.ma/users/...) أو اكتب @username',
                  'Collez un lien Apolo ou saisissez @identifiant',
                  appL10n.scanProfileCodePasteApoloProfileLinkEnter,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 16),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  key: const Key('scan-manual-input'),
                  controller: _inputController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'https://apolo.ma/users/77  •  @username',
                    errorText: _errorText,
                    filled: true,
                    fillColor: palette.surfaceSubtle,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.ink, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ApoloDlButton(
                key: const Key('scan-manual-submit'),
                label: s.tr('فتح الحساب', 'Ouvrir le profil', appL10n.scanProfileCodeOpenProfile),
                variant: ApoloDlButtonVariant.primary,
                borderRadius: 999,
                fullWidth: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
