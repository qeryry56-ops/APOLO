import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/dl_qr_code.dart';
import '../widgets/dl_settings_kit.dart';
import 'ad_detail_screen.dart';
import 'seller_profile_screen.dart';

/// Dynamic Layer v5.1 QR scanner screen (`Share profile / Default` scan view).
/// Features a minimal top bar, large rounded 1:1 camera viewfinder, centered
/// instruction caption, and bottom flash / concentric shutter / gallery controls.
class ScanProfileCodeScreen extends StatefulWidget {
  const ScanProfileCodeScreen({
    super.key,
    this.enableLiveCamera = true,
    this.onCodeScanned,
  });

  final bool enableLiveCamera;
  final void Function(String rawValue)? onCodeScanned;

  @override
  State<ScanProfileCodeScreen> createState() => _ScanProfileCodeScreenState();
}

class _ScanProfileCodeScreenState extends State<ScanProfileCodeScreen> {
  final AppState _state = AppState();
  MobileScannerController? _controller;
  bool _isHandlingCode = false;
  bool _pickingGallery = false;

  bool get _shouldUseLiveScanner =>
      widget.enableLiveCamera &&
      !WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (_shouldUseLiveScanner) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        controller.dispose();
      } catch (_) {}
    }
    super.dispose();
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

      final controller = _controller;
      if (!kIsWeb && controller != null) {
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

  void _onShutterPressed() {
    HapticFeedback.mediumImpact();
    final s = _state.s;
    final controller = _controller;
    final cameraActive = controller != null &&
        controller.value.isRunning &&
        controller.value.error == null;

    if (!cameraActive) {
      _openManualCodeSheet();
      return;
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
    final s = _state.s;

    if (widget.onCodeScanned != null) {
      widget.onCodeScanned!(trimmed);
      if (mounted) _isHandlingCode = false;
      return;
    }

    final target = ApoloProfileQrParser.parse(trimmed);
    switch (target.type) {
      case ApoloQrTargetType.user:
        final sellerId = target.id!;
        final myId = int.tryParse('${_state.currentUser?['id'] ?? ''}');
        if (myId != null && myId == sellerId) {
          _showSnack(
            s.tr(
              'هذا هو ملفك الشخصي الحالي',
              'Ceci est déjà votre profil',
              'This is your own profile',
            ),
          );
          _isHandlingCode = false;
          if (mounted) await Navigator.of(context).maybePop();
          return;
        }

        String name = s.tr(
          'مستخدم Apolo #$sellerId',
          'Membre Apolo #$sellerId',
          'Apolo Member #$sellerId',
        );
        String? avatar;
        String? phone;
        String? city;

        try {
          final res = await _state.api.dio.get(
            '/ads',
            queryParameters: {'per_page': 1, 'seller_id': sellerId},
          );
          if (res.data is Map && res.data['data'] is List) {
            final list = res.data['data'] as List;
            if (list.isNotEmpty && list.first is Map) {
              final firstAd = Map<String, dynamic>.from(list.first as Map);
              final user = firstAd['user'] is Map
                  ? Map<String, dynamic>.from(firstAd['user'] as Map)
                  : null;
              final fetchedName =
                  (user?['name'] ?? firstAd['seller_name'] ?? '')
                      .toString()
                      .trim();
              if (fetchedName.isNotEmpty) name = fetchedName;
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

        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SellerProfileScreen(
              sellerId: sellerId,
              sellerName: name,
              sellerAvatar: avatar,
              sellerPhone: phone,
              sellerCity: city,
            ),
          ),
        );
        return;

      case ApoloQrTargetType.ad:
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AdDetailScreen(adId: target.id!),
          ),
        );
        return;

      case ApoloQrTargetType.handle:
      case ApoloQrTargetType.external:
      case ApoloQrTargetType.unknown:
        final palette = ApoloDlPalette.of(context);
        if (!mounted) return;
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
          contentTitle: target.type == ApoloQrTargetType.handle
              ? '@${target.handle}'
              : s.tr('تمت قراءة الرمز', 'Code détecté', 'Code Detected'),
          contentDescription: target.rawValue,
          actions: [
            ApoloDlButton(
              label: s.tr('نسخ', 'Copier', 'Copy'),
              variant: ApoloDlButtonVariant.primary,
              borderRadius: 999,
              fullWidth: true,
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: target.rawValue));
                } catch (_) {}
                if (mounted) {
                  Navigator.of(context).pop();
                  _showSnack(
                    s.tr('تم النسخ', 'Copié', 'Copied'),
                  );
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
        if (mounted) {
          setState(() => _isHandlingCode = false);
        }
        return;
    }
  }

  Widget _buildCameraFallback(ApoloDlPalette palette, AppStrings s) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openManualCodeSheet,
      child: ColoredBox(
        color: palette.groupCard,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.camera,
                  size: 32,
                  color: palette.iconMuted,
                ),
                const SizedBox(height: 10),
                Text(
                  s.tr(
                    'اضغط لإدخال رابط الحساب يدوياً',
                    'Appuyez pour saisir un lien de profil',
                    'Tap to enter a profile link',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewfinder(ApoloDlPalette palette, AppStrings s) {
    final Widget inner;
    if (_shouldUseLiveScanner && _controller != null) {
      inner = MobileScanner(
        controller: _controller!,
        fit: BoxFit.cover,
        onDetect: _onDetect,
        placeholderBuilder: (_) => ColoredBox(color: palette.groupCard),
        errorBuilder: (context, error) => _buildCameraFallback(palette, s),
      );
    } else {
      inner = ColoredBox(color: palette.groupCard);
    }

    return ConstrainedBox(
      key: const Key('scan-code-viewfinder'),
      constraints: const BoxConstraints(maxWidth: 332),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: palette.groupCard,
            child: inner,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(ApoloDlPalette palette) {
    final controller = _controller;

    final Widget flashControl = controller != null
        ? ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, _) {
              final torchOn = state.torchState == TorchState.on;
              return _ScannerCircleControl(
                key: const Key('scan-code-flash-btn'),
                icon:
                    torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                backgroundColor: torchOn ? palette.ink : palette.pill,
                iconColor: torchOn ? palette.onInk : palette.ink,
                onPressed: _toggleTorch,
              );
            },
          )
        : _ScannerCircleControl(
            key: const Key('scan-code-flash-btn'),
            icon: Icons.flash_off_rounded,
            backgroundColor: palette.pill,
            iconColor: palette.ink,
            onPressed: _toggleTorch,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            flashControl,
            const SizedBox(width: 28),
            _ConcentricShutterButton(
              key: const Key('scan-code-shutter-btn'),
              ringColor: palette.ink,
              innerColor: palette.ink,
              onPressed: _onShutterPressed,
            ),
            const SizedBox(width: 28),
            _ScannerCircleControl(
              key: const Key('scan-code-gallery-btn'),
              icon: Icons.image_outlined,
              backgroundColor: palette.pill,
              iconColor: palette.ink,
              onPressed: _pickImageAndAnalyze,
            ),
          ],
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
                                key: const Key('scan-code-back-btn'),
                                icon: backIcon,
                                tooltip: MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                              const Spacer(),
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
                                        24, 12, 24, 16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildViewfinder(palette, s),
                                        const SizedBox(height: 20),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 288,
                                          ),
                                          child: Text(
                                            s.tr(
                                              'ضع الرمز في المنطقة العلوية.',
                                              'Placez le code dans la zone supérieure.',
                                              'Place the code in the upper area.',
                                            ),
                                            key: const Key('scan-code-hint'),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
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
                      _buildBottomControls(palette),
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

class _ScannerCircleControl extends StatelessWidget {
  const _ScannerCircleControl({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(
              icon,
              size: 21,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcentricShutterButton extends StatefulWidget {
  const _ConcentricShutterButton({
    required this.ringColor,
    required this.innerColor,
    required this.onPressed,
    super.key,
  });

  final Color ringColor;
  final Color innerColor;
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
          width: 66,
          height: 66,
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.ringColor,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.innerColor,
            ),
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
