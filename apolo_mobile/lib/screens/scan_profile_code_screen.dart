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
import '../widgets/dl_share_top_nav.dart';
import 'ad_detail_screen.dart';
import 'seller_profile_screen.dart';
import 'store_detail_screen.dart';

/// Dynamic Layer v5.1 QR scanner screen (`Share profile / Default` Camera Scan mode).
/// Uses [DlShareProfileTokens], [DlShareProfileLayout], and [DlShareTopNavigation]
/// to render a `311x311` (`roundedXl`) scan frame, `311x20` instruction text,
/// `56x56` `Buttonicon` controls (`p_16`, `24x24` icons), and `80x80` capture frame.
class ScanProfileCodeScreen extends StatefulWidget {
  const ScanProfileCodeScreen({
    super.key,
    this.title,
    this.enableLiveCamera = true,
    this.onCodeScanned,
  });

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
              'This is your own profile',
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
                    'Apolo Member #$sellerId',
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
        if (myUsername.isNotEmpty &&
            cleanHandle.toLowerCase() == myUsername) {
          showToast(
            s.tr(
              'هذا هو ملفك الشخصي الحالي',
              'Ceci est déjà votre profil',
              'This is your own profile',
            ),
          );
          if (replaceCurrentRoute && context.mounted) {
            await Navigator.of(context).maybePop();
          }
          return;
        }

        // 1. Check if this handle is an official PRO store subdomain
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

        // 2. Search ads for a matching seller account
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
          headerTitle: s.tr('رمز ممسوح', 'Code scanné', 'Scanned Code'),
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
              s.tr('تمت قراءة الرمز', 'Code détecté', 'Code Detected'),
          contentDescription: target.rawValue,
          actions: [
            if (externalUri != null)
              ApoloDlButton(
                label: s.tr('فتح الرابط', 'Ouvrir le lien', 'Open link'),
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
              label: s.tr('نسخ', 'Copier', 'Copy'),
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
                  showToast(s.tr('تم النسخ', 'Copié', 'Copied'));
                }
              },
            ),
            ApoloDlButton(
              label: s.tr('مسح من جديد', 'Scanner encore', 'Scan again'),
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

class _ScanProfileCodeScreenState extends State<ScanProfileCodeScreen> {
  static int _nextWebSessionId = 1;

  final AppState _state = AppState();
  MobileScannerController? _controller;
  late int _webSessionId;
  bool _webCameraStreaming = false;
  bool _webCameraError = false;
  bool _isHandlingCode = false;
  bool _pickingGallery = false;
  bool _webTorchOn = false;

  bool get _shouldUseLiveScanner =>
      widget.enableLiveCamera &&
      (kIsWeb ||
          !WidgetsBinding.instance.runtimeType.toString().contains('Test'));

  @override
  void initState() {
    super.initState();
    _webSessionId = _nextWebSessionId++;
    if (_shouldUseLiveScanner && !kIsWeb) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
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
          'Flashlight is unavailable in this browser',
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
          'Flashlight is unavailable on this camera',
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
          'Could not toggle flashlight right now',
        ),
      );
    }
  }

  Future<void> _pickImageAndAnalyze() async {
    if (_pickingGallery) return;
    _pickingGallery = true;
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
          'No QR code detected in the selected image',
        ),
        action: SnackBarAction(
          label: s.tr('أدخل الرابط', 'Saisir lien', 'Enter link'),
          onPressed: _openManualCodeSheet,
        ),
      );
    } catch (_) {
      _showSnack(
        s.tr(
          'تعذر فتح معرض الصور',
          'Impossible d’ouvrir la galerie',
          'Could not open photo library',
        ),
        action: SnackBarAction(
          label: s.tr('أدخل الرابط', 'Saisir lien', 'Enter link'),
          onPressed: _openManualCodeSheet,
        ),
      );
    } finally {
      _pickingGallery = false;
    }
  }

  Future<void> _onShutterPressed() async {
    HapticFeedback.mediumImpact();
    final s = _state.s;
    final controller = _controller;
    final cameraActive = kIsWeb
        ? (_shouldUseLiveScanner && _webCameraStreaming && !_webCameraError)
        : (controller != null &&
            controller.value.isRunning &&
            controller.value.error == null);

    if (!cameraActive) {
      await _openManualCodeSheet();
      return;
    }

    if (kIsWeb) {
      final captured = await QrWebBridge.captureLiveVideoQr();
      if (captured != null && captured.trim().isNotEmpty) {
        await handleScannedPayload(captured.trim());
        return;
      }
    }

    _showSnack(
      s.tr(
        'وجّه الكاميرا نحو رمز QR أو أدخل الرابط يدوياً',
        'Pointez la caméra vers le code QR ou saisissez le lien',
        'Point camera at a QR code or paste a link',
      ),
      action: SnackBarAction(
        label: s.tr('أدخل الرابط', 'Saisir lien', 'Enter link'),
        onPressed: _openManualCodeSheet,
      ),
    );
  }

  Future<void> _openManualCodeSheet() async {
    if (!mounted) return;
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

    _isHandlingCode = true;

    if (widget.onCodeScanned != null) {
      widget.onCodeScanned!(trimmed);
      if (mounted) _isHandlingCode = false;
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

  Widget _buildCameraFallback(DlShareProfileTokens tokens, AppStrings s) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: kIsWeb ? _retryWebCamera : _openManualCodeSheet,
      child: ColoredBox(
        color: tokens.cardBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.camera,
                  size: 32,
                  color: tokens.mutedInk,
                ),
                const SizedBox(height: 10),
                Text(
                  kIsWeb
                      ? s.tr(
                          'اضغط لتفعيل الكاميرا واسمح بالوصول في المتصفح',
                          'Appuyez pour activer la caméra dans le navigateur',
                          'Tap to enable camera access in your browser',
                        )
                      : s.tr(
                          'اضغط لإدخال رابط الحساب يدوياً',
                          'Appuyez pour saisir un lien de profil',
                          'Tap to enter a profile link',
                        ),
                  textAlign: TextAlign.center,
                  style: tokens.textSmRegular,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder(
    DlShareProfileTokens tokens,
    AppStrings s, {
    double maxSide = DlShareProfileLayout.scanFrameSize,
  }) {
    if (kIsWeb && _shouldUseLiveScanner) {
      final Widget webChild;
      if (_webCameraError) {
        webChild = _buildCameraFallback(tokens, s);
      } else {
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
        webChild = htmlView ?? ColoredBox(color: tokens.cardBackground);
      }

      return ConstrainedBox(
        key: const Key('scan-code-viewfinder'),
        constraints: BoxConstraints(
          maxWidth: maxSide,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radii.roundedXl),
            child: webChild,
          ),
        ),
      );
    }

    final Widget inner;
    if (_shouldUseLiveScanner && _controller != null) {
      inner = MobileScanner(
        controller: _controller!,
        fit: BoxFit.cover,
        onDetect: _onDetect,
        placeholderBuilder: (_) => ColoredBox(color: tokens.cardBackground),
        errorBuilder: (context, error) => _buildCameraFallback(tokens, s),
      );
    } else {
      inner = ColoredBox(color: tokens.cardBackground);
    }

    return ConstrainedBox(
      key: const Key('scan-code-viewfinder'),
      constraints: BoxConstraints(
        maxWidth: maxSide,
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radii.roundedXl),
          child: ColoredBox(
            color: tokens.cardBackground,
            child: inner,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(DlShareProfileTokens tokens) {
    final controller = _controller;

    final Widget flashControl = controller != null
        ? ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, _) {
              final torchOn =
                  kIsWeb ? _webTorchOn : (state.torchState == TorchState.on);
              return _ScannerCircleControl(
                key: const Key('scan-code-flash-btn'),
                icon: torchOn
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_rounded,
                backgroundColor:
                    torchOn ? tokens.ink : tokens.pillBackground,
                iconColor:
                    torchOn ? tokens.scaffoldBackground : tokens.ink,
                borderRadius: tokens.radii.roundedFull,
                onPressed: _toggleTorch,
              );
            },
          )
        : _ScannerCircleControl(
            key: const Key('scan-code-flash-btn'),
            icon: _webTorchOn
                ? Icons.flashlight_on_rounded
                : Icons.flashlight_off_rounded,
            backgroundColor:
                _webTorchOn ? tokens.ink : tokens.pillBackground,
            iconColor: _webTorchOn ? tokens.scaffoldBackground : tokens.ink,
            borderRadius: tokens.radii.roundedFull,
            onPressed: _toggleTorch,
          );

    return SizedBox(
      key: const Key('scan-code-controls-bar'),
      width: double.infinity,
      height: DlShareProfileLayout.bottomBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final horizontalPadding = maxW < 320.0
              ? 12.0
              : DlShareProfileLayout.bottomBarPadding;
          final controlsGap = maxW < 320.0
              ? ((maxW - 24.0 - 192.0) / 2.0)
                  .clamp(8.0, DlShareProfileLayout.cameraControlsGap)
              : DlShareProfileLayout.cameraControlsGap;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: DlShareProfileLayout.bottomBarPadding,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  flashControl,
                  SizedBox(width: controlsGap),
                  _ConcentricShutterButton(
                    key: const Key('scan-code-shutter-btn'),
                    outerColor: tokens.captureOuterColor,
                    gapColor: tokens.captureGapColor,
                    innerColor: tokens.captureInnerColor,
                    borderRadius: tokens.radii.roundedFull,
                    onPressed: _onShutterPressed,
                  ),
                  SizedBox(width: controlsGap),
                  _ScannerCircleControl(
                    key: const Key('scan-code-gallery-btn'),
                    icon: Icons.image_rounded,
                    backgroundColor: tokens.pillBackground,
                    iconColor: tokens.ink,
                    borderRadius: tokens.radii.roundedFull,
                    onPressed: _pickImageAndAnalyze,
                  ),
                ],
              ),
            ),
          );
        },
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
        final screenSize = MediaQuery.sizeOf(context);
        final bottomInset =
            DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: tokens.scaffoldBackground,
            body: Column(
              children: [
                DlShareTopNavigation(
                  tokens: tokens,
                  headerKey: const Key('scan-code-header'),
                  wrapperKey: const Key('scan-code-top-wrapper'),
                  backButtonKey: const Key('scan-code-back-btn'),
                  titleKey: const Key('scan-code-title'),
                  title: widget.title,
                  onBack: () => Navigator.of(context).maybePop(),
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
                                final horizontalPadding =
                                    constraints.maxWidth < 348.0
                                        ? DlShareProfileLayout.p16
                                        : DlShareProfileLayout
                                            .screenHorizontalPadding;
                                final maxViewfinderSide =
                                    constraints.maxHeight < 395.0
                                        ? (constraints.maxHeight - 84.0).clamp(
                                            180.0,
                                            DlShareProfileLayout.scanFrameSize,
                                          )
                                        : DlShareProfileLayout.scanFrameSize;
                                final actualSide = (constraints.maxWidth -
                                        horizontalPadding * 2)
                                    .clamp(0.0, maxViewfinderSide);
                                final groupHeight = actualSide +
                                    DlShareProfileLayout.sectionGap +
                                    DlShareProfileLayout.scanInstructionHeight;
                                final topGap = ((constraints.maxHeight -
                                            groupHeight) *
                                        (121.0 / 167.0))
                                    .clamp(0.0, double.infinity);

                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        horizontalPadding,
                                        topGap,
                                        horizontalPadding,
                                        16,
                                      ),
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Column(
                                          key: const Key('scan-code-content'),
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildViewfinder(
                                              tokens,
                                              s,
                                              maxSide: maxViewfinderSide,
                                            ),
                                            const SizedBox(
                                              height: DlShareProfileLayout
                                                  .sectionGap,
                                            ),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: DlShareProfileLayout
                                                    .scanInstructionWidth,
                                                minHeight: DlShareProfileLayout
                                                    .scanInstructionHeight,
                                              ),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: Text(
                                                  s.tr(
                                                    'ضع الرمز في المنطقة العلوية.',
                                                    'Placez le code dans la zone supérieure.',
                                                    'Place the code in the upper area.',
                                                  ),
                                                  key: const Key(
                                                      'scan-code-hint'),
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
                          _buildBottomControls(tokens),
                          if (bottomInset > 0) SizedBox(height: bottomInset),
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

class _ScannerCircleControl extends StatelessWidget {
  const _ScannerCircleControl({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.borderRadius,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double borderRadius;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DlShareProfileLayout.p16),
          child: SizedBox(
            width: DlShareProfileLayout.cameraIconSize,
            height: DlShareProfileLayout.cameraIconSize,
            child: Center(
              child: Icon(
                icon,
                size: DlShareProfileLayout.cameraIconSize,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcentricShutterButton extends StatefulWidget {
  const _ConcentricShutterButton({
    required this.outerColor,
    required this.gapColor,
    required this.innerColor,
    required this.borderRadius,
    required this.onPressed,
    super.key,
  });

  final Color outerColor;
  final Color gapColor;
  final Color innerColor;
  final double borderRadius;
  final VoidCallback onPressed;

  @override
  State<_ConcentricShutterButton> createState() =>
      _ConcentricShutterButtonState();
}

class _ConcentricShutterButtonState extends State<_ConcentricShutterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          width: DlShareProfileLayout.captureOuterSize,
          height: DlShareProfileLayout.captureOuterSize,
          decoration: BoxDecoration(
            color: widget.outerColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Stack(
            alignment: Alignment.topLeft,
            textDirection: TextDirection.ltr,
            children: [
              Positioned(
                top: DlShareProfileLayout.captureWhiteTop,
                left: DlShareProfileLayout.captureWhiteLeft,
                width: DlShareProfileLayout.captureWhiteSize,
                height: DlShareProfileLayout.captureWhiteSize,
                child: Container(
                  key: const Key('scan-code-shutter-ring-white'),
                  decoration: BoxDecoration(
                    color: widget.gapColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),
              Positioned(
                top: DlShareProfileLayout.captureInnerTop,
                left: DlShareProfileLayout.captureInnerLeft,
                width: DlShareProfileLayout.captureInnerSize,
                height: DlShareProfileLayout.captureInnerSize,
                child: Container(
                  key: const Key('scan-code-shutter-core'),
                  decoration: BoxDecoration(
                    color: widget.innerColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          'Please enter a link or handle',
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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const SizedBox(width: 40, height: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.tr(
                              'فتح ملف شخصي بالرابط',
                              'Ouvrir un profil par lien',
                              'Open profile link',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ApoloDlIconCircleButton(
                          icon: CupertinoIcons.xmark,
                          iconSize: 18,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                ),
                const ApoloDlSeparator(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.tr(
                          'ألصق رابط ملف Apolo أو اسم المستخدم لفتحه مباشرة.',
                          'Collez le lien d’un profil Apolo ou un identifiant @.',
                          'Paste an Apolo profile link or @handle to open it directly.',
                        ),
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const Key('scan-manual-input'),
                        controller: _inputController,
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        decoration: InputDecoration(
                          hintText: 'https://apolo.ma/users/42',
                          errorText: _errorText,
                          filled: true,
                          fillColor: palette.groupCard,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 18),
                      ApoloDlButton(
                        key: const Key('scan-manual-submit'),
                        label: s.tr('فتح', 'Ouvrir', 'Open'),
                        variant: ApoloDlButtonVariant.primary,
                        borderRadius: 999,
                        fullWidth: true,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
