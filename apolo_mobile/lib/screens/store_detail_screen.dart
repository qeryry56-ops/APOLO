import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/apolo_badges_kit.dart';
import '../widgets/dl_settings_kit.dart';
import 'business_switch_screen.dart';
import 'widgets/ad_card.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/skeleton_loader.dart';

/// Dynamic Layer v5.1 Verified Official Storefront (`StoreDetailScreen`):
/// - Pure `#FFFFFF` canvas + `56px` Dynamic Layer Top Nav (`40×40` `#EEEEEE` back & `•••` menu)
/// - Flat `#F6F6F6` rounded `24px` showcase header with `ApoloVerifiedBadge` + `ApoloRankBadge`
/// - `#EEEEEE` `Call` + `#000000` `Order` side-by-side capsule CTAs, `#FFFFFF` 3-column metrics strip,
///   and Dynamic Layer `#FFFFFF` / `#F6F6F6` Direct Store Order & Safety sheets.
class StoreDetailScreen extends StatefulWidget {
  final String subdomain;
  const StoreDetailScreen({super.key, required this.subdomain});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final AppState _state = AppState();
  Map<String, dynamic>? _store;
  List<dynamic> _ads = [];
  bool _loading = true;

  // Strict Dynamic Layer v5.1 Palette Tokens
  Color get _dlBg => ApoloDlPalette.of(context).bg;
  Color get _dlSurface => ApoloDlPalette.of(context).surfaceSubtle;
  Color get _dlPill => ApoloDlPalette.of(context).pill;
  Color get _dlSeparator => ApoloDlPalette.of(context).separator;
  Color get _dlInk => ApoloDlPalette.of(context).ink;
  Color get _dlOnInk => ApoloDlPalette.of(context).onInk;
  Color get _dlMuted => ApoloDlPalette.of(context).muted;
  static const Color _dlDanger = Color(0xFFE31B23);

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    try {
      final encoded = Uri.encodeComponent(widget.subdomain);
      final res = await _state.api.dio.get('/stores/$encoded');
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _store = res.data['store'];
            _ads = res.data['products'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showStoreSafetySheet(Map<String, dynamic> store) {
    HapticFeedback.selectionClick();
    final s = _state.s;
    final storeName = (store['name'] ?? widget.subdomain).toString();
    final storeLogo = (store['logo_url'] ?? store['logo'] ?? '').toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Directionality(
        textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _dlPill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _dlSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          showApoloReportSheet(
                            context,
                            targetType: 'store',
                            targetId: widget.subdomain,
                            targetName: storeName,
                            reportedUserId: widget.subdomain,
                            reportedUserAvatar: storeLogo,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.flag,
                                  size: 16,
                                  color: _dlInk,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.tr(
                                    'الإبلاغ عن هذا المتجر',
                                    'Signaler cette boutique',
                                    'Report store',
                                  ),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: _dlInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.only(start: 60),
                        child: SizedBox(
                          height: 1,
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: _dlSeparator),
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final myUserId = int.tryParse(
                                  '${_state.currentUser?['id'] ?? 0}') ??
                              0;
                          await FirebaseChatService.instance.blockTarget(
                            myUserId: myUserId,
                            targetId: widget.subdomain,
                            targetName: storeName,
                            targetAvatar: storeLogo,
                            targetType: 'store',
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.maybeOf(context)
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: _dlInk,
                                shape: const StadiumBorder(),
                                margin:
                                    const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                content: Text(
                                  s.tr(
                                    'تم حظر المتجر بنجاح',
                                    'Boutique bloquée',
                                    'Store blocked',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.nosign,
                                  size: 16,
                                  color: _dlDanger,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.tr(
                                    'حظر هذا المتجر',
                                    'Bloquer cette boutique',
                                    'Block store',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: _dlDanger,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  InputDecoration _sheetInputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _dlMuted, fontSize: 13.5),
      filled: true,
      fillColor: _dlSurface,
      hoverColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _dlInk, width: 1.5),
      ),
    );
  }

  void _openOrderSheet() {
    final s = _state.s;
    final nameCtrl = TextEditingController(
      text: _state.currentUser?['name']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: _state.currentUser?['phone']?.toString() ?? '',
    );
    final cityCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    int? selectedAdId =
        _ads.isNotEmpty ? int.tryParse(_ads.first['id'].toString()) : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _dlBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Directionality(
        textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _dlPill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _dlPill,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        CupertinoIcons.bag_fill,
                        color: _dlInk,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.tr(
                          'طلب سريع من المتجر',
                          'Commande directe',
                          'Direct Store Order',
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _dlInk,
                        ),
                      ),
                    ),
                    ApoloDlIconCircleButton(
                      icon: CupertinoIcons.xmark,
                      iconSize: 16,
                      backgroundColor: _dlPill,
                      iconColor: _dlInk,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_ads.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: selectedAdId,
                    dropdownColor: _dlBg,
                    decoration: _sheetInputDec(
                      s.tr('اختر المنتج', 'Choisir le produit', 'Select item'),
                    ),
                    items: _ads
                        .map(
                          (a) => DropdownMenuItem<int>(
                            value: int.tryParse(a['id'].toString()),
                            child: Text(
                              a['title'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedAdId = v,
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  cursorColor: _dlInk,
                  decoration: _sheetInputDec(
                    s.tr('الاسم الكامل', 'Nom complet', 'Full name'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  cursorColor: _dlInk,
                  keyboardType: TextInputType.phone,
                  decoration: _sheetInputDec(
                    s.tr('رقم الهاتف', 'Téléphone', 'Phone'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityCtrl,
                  cursorColor: _dlInk,
                  decoration: _sheetInputDec(
                    s.tr('المدينة', 'Ville', 'City'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locCtrl,
                  cursorColor: _dlInk,
                  decoration: _sheetInputDec(
                    s.tr('العنوان', 'Adresse de livraison', 'Delivery address'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  cursorColor: _dlInk,
                  decoration: _sheetInputDec(
                    s.tr('ملاحظات الطلب', 'Notes', 'Order notes'),
                  ),
                ),
                const SizedBox(height: 18),
                ApoloDlButton(
                  label: s.tr(
                    'تأكيد الطلب الآن',
                    'Confirmer la commande',
                    'Confirm order',
                  ),
                  variant: ApoloDlButtonVariant.primary,
                  borderRadius: 999,
                  height: 52,
                  fullWidth: true,
                  onPressed: () async {
                    if (selectedAdId == null ||
                        nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final encoded = Uri.encodeComponent(widget.subdomain);
                      final res = await _state.api.dio.post(
                        '/stores/$encoded/order',
                        data: {
                          'ad_id': selectedAdId,
                          'full_name': nameCtrl.text.trim(),
                          'phone_number': phoneCtrl.text.trim(),
                          'city': cityCtrl.text.trim().isNotEmpty
                              ? cityCtrl.text.trim()
                              : 'Casablanca',
                          'location': locCtrl.text.trim().isNotEmpty
                              ? locCtrl.text.trim()
                              : '-',
                          'message': msgCtrl.text.trim(),
                        },
                      );
                      if (mounted &&
                          res.data is Map &&
                          res.data['status'] == 'success') {
                        ScaffoldMessenger.maybeOf(context)
                          ?..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: _dlInk,
                              shape: const StadiumBorder(),
                              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              content: Text(
                                s.tr(
                                  'تم إرسال طلبك للمتجر بنجاح',
                                  'Commande envoyée avec succès',
                                  'Order submitted successfully',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                      }
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    if (_loading) {
      return Scaffold(
        backgroundColor: _dlBg,
        body: StoreDetailSkeleton(),
      );
    }
    final store = _store;
    if (store == null) {
      return Directionality(
        textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: _dlBg,
          body: SafeArea(
            child: Column(
              children: [
                ApoloDlTopNav(
                  title: s.stores,
                  showSeparator: false,
                ),
                Expanded(
                  child: ApoloDlEmptyState(
                    icon: Icons.storefront_rounded,
                    headline: s.tr(
                      'المتجر غير موجود',
                      'Boutique introuvable',
                      'Store not found',
                    ),
                    description: s.tr(
                      'تحقق من الرابط أو عد إلى قائمة المتاجر الرسمية.',
                      'Vérifiez le lien ou retournez aux boutiques.',
                      'Check the link or browse verified stores.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final logo = store['logo_url'] ?? store['logo'];

    return Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _dlBg,
        floatingActionButton:
            (_ads.isNotEmpty && store['direct_order_enabled'] != false)
                ? FloatingActionButton.extended(
                    onPressed: _openOrderSheet,
                    backgroundColor: _dlInk,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    icon: const Icon(CupertinoIcons.bag_fill, size: 17),
                    label: Text(
                      s.tr('اطلب الآن', 'Commander', 'Order now'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  )
                : null,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // Dynamic Layer v5.1 Top Nav
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ApoloDlIconCircleButton(
                          icon: s.isAr
                              ? CupertinoIcons.chevron_right
                              : CupertinoIcons.chevron_left,
                          backgroundColor: _dlPill,
                          iconColor: _dlInk,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (store['name'] ?? '').toString(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: _dlInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ApoloDlIconCircleButton(
                          icon: CupertinoIcons.ellipsis,
                          backgroundColor: _dlPill,
                          iconColor: _dlInk,
                          onPressed: () => _showStoreSafetySheet(store),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Store Profile Showcase Card (`#F6F6F6` flat card)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Builder(
                    builder: (_) {
                      final coverUrl =
                          (store['cover_url'] ?? '').toString().trim();
                      final location =
                          (store['location'] ?? '').toString().trim();
                      final mapsUrl =
                          (store['maps_url'] ?? '').toString().trim();
                      final workingHours =
                          (store['working_hours'] ?? '').toString().trim();
                      final isOpenNow = store['is_open_now'];
                      final businessCategory = ApoloBusinessCategories.labelFor(
                        store['business_category']?.toString(),
                        s,
                      );
                      final directOrderAllowed =
                          store['direct_order_enabled'] != false;
                      final phone = (store['phone'] ?? '').toString().trim();

                      return Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: _dlSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _dlSeparator),
                        ),
                        child: Column(
                          children: [
                            if (coverUrl.isNotEmpty)
                              SizedBox(
                                height: 112,
                                width: double.infinity,
                                child: AppImage(
                                  url: coverUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: _dlBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: AppAvatar(
                                          url: logo?.toString(),
                                          radius: 38,
                                          fallbackIcon:
                                              Icons.storefront_rounded,
                                        ),
                                      ),
                                      const PositionedDirectional(
                                        bottom: 0,
                                        end: 0,
                                        child: ApoloVerifiedBadge(size: 21),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          (store['name'] ?? '').toString(),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: _dlInk,
                                            letterSpacing: AppTypography
                                                .trackingForContext(
                                              context,
                                              -0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ApoloIdentityBadgesRow(
                                        isVerified: true,
                                        rank: ApoloSellerRank.resolve(
                                          user: store,
                                          listingsCount: _ads.length,
                                          isProPlus:
                                              store['is_pro_plus'] == true,
                                          isBusiness: true,
                                          isVerified: true,
                                        ),
                                        isProPlus: store['is_pro_plus'] == true,
                                        isBusiness: true,
                                        badgeSize: 18,
                                        interactive: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _dlBg,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          businessCategory,
                                          style: TextStyle(
                                            fontSize: 11.8,
                                            fontWeight: FontWeight.w700,
                                            color: _dlInk,
                                          ),
                                        ),
                                      ),
                                      if (workingHours.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _dlBg,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isOpenNow is bool) ...[
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                    color: isOpenNow
                                                        ? AppConfig.success
                                                        : _dlDanger,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                              ],
                                              Text(
                                                isOpenNow == true
                                                    ? s.tr(
                                                        'مفتوح · $workingHours',
                                                        'Ouvert · $workingHours',
                                                        'Open · $workingHours',
                                                      )
                                                    : (isOpenNow == false
                                                        ? s.tr(
                                                            'مغلق · $workingHours',
                                                            'Fermé · $workingHours',
                                                            'Closed · $workingHours',
                                                          )
                                                        : workingHours),
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: _dlInk,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (location.isNotEmpty ||
                                      mapsUrl.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final rawTarget = mapsUrl.isNotEmpty
                                            ? mapsUrl
                                            : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';
                                        final uri = Uri.tryParse(rawTarget);
                                        if (uri != null &&
                                            await canLaunchUrl(uri)) {
                                          await launchUrl(
                                            uri,
                                            mode: LaunchMode.externalApplication,
                                          );
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.location_solid,
                                            size: 13,
                                            color: _dlInk,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              location.isNotEmpty
                                                  ? location
                                                  : s.tr(
                                                      'عرض الموقع على Google Maps',
                                                      'Voir sur Google Maps',
                                                      'Open in Google Maps',
                                                    ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: _dlInk,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if ((store['description'] ?? '')
                                      .toString()
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      (store['description'] ?? '').toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _dlMuted,
                                        fontSize: 13.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (phone.isNotEmpty || _ads.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        if (phone.isNotEmpty) ...[
                                          Expanded(
                                            child: ApoloDlButton(
                                              label: s.tr(
                                                'اتصال',
                                                'Appeler',
                                                'Call',
                                              ),
                                              leadingIcon:
                                                  CupertinoIcons.phone_fill,
                                              variant:
                                                  ApoloDlButtonVariant.tertiary,
                                              borderRadius: 999,
                                              height: 44,
                                              fullWidth: true,
                                              onPressed: () async {
                                                final cleanPhone =
                                                    phone.replaceAll(
                                                  RegExp(r'[^0-9+]'),
                                                  '',
                                                );
                                                if (cleanPhone.isEmpty) return;
                                                final uri = Uri.parse(
                                                  'tel:$cleanPhone',
                                                );
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri);
                                                }
                                              },
                                            ),
                                          ),
                                          if (_ads.isNotEmpty &&
                                              directOrderAllowed)
                                            const SizedBox(width: 10),
                                        ],
                                        if (_ads.isNotEmpty &&
                                            directOrderAllowed)
                                          Expanded(
                                            child: ApoloDlButton(
                                              label: s.tr(
                                                'طلب مباشر',
                                                'Commander',
                                                'Order',
                                              ),
                                              leadingIcon:
                                                  CupertinoIcons.bag_fill,
                                              variant:
                                                  ApoloDlButtonVariant.primary,
                                              borderRadius: 999,
                                              height: 44,
                                              fullWidth: true,
                                              onPressed: _openOrderSheet,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _dlBg,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                '${_ads.length}',
                                                textDirection:
                                                    TextDirection.ltr,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: _dlInk,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures()
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                s.tr(
                                                  'المنتجات',
                                                  'Produits',
                                                  'Products',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: _dlMuted,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 28,
                                          color: _dlSeparator,
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                '100%',
                                                textDirection:
                                                    TextDirection.ltr,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: _dlInk,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures()
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                s.tr(
                                                  'موثوق',
                                                  'Vérifié',
                                                  'Verified',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: _dlMuted,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 28,
                                          color: _dlSeparator,
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                '24/48h',
                                                textDirection:
                                                    TextDirection.ltr,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: _dlInk,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures()
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                s.tr(
                                                  'التوصيل',
                                                  'Livraison',
                                                  'Delivery',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: _dlMuted,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    s.tr(
                      'منتجات المتجر',
                      'Catalogue de la boutique',
                      'Store Catalog',
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                      letterSpacing:
                          AppTypography.trackingForContext(context, -0.3),
                    ),
                  ),
                ),
              ),

              // Products Grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, idx) => AdCard(ad: Map<String, dynamic>.from(_ads[idx])),
                    childCount: _ads.length,
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
