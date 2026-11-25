import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/services/firebase_chat_service.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'business_switch_screen.dart';
import 'widgets/ad_card.dart';
import 'widgets/apolo_safety_sheet.dart';
import 'widgets/app_image.dart';
import 'widgets/kinetic_widgets.dart';
import 'widgets/skeleton_loader.dart';

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

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _red = Color(0xFF0A0A0A);
  static const Color _badgeBg = Color(0xFFE8EAEE);
  static const Color _pillBg = Color(0xFFF2F3F7);
  static const Color _border = Color(0xFFE5E7EB);

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: _ink,
                ),
                title: Text(
                  s.tr('الإبلاغ عن هذا المتجر', 'Signaler cette boutique',
                      'Report store'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
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
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.nosign,
                  color: Color(0xFFE31B23),
                ),
                title: Text(
                  s.tr('حظر هذا المتجر', 'Bloquer cette boutique', 'Block store'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE31B23),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final myUserId =
                      int.tryParse('${_state.currentUser?['id'] ?? 0}') ?? 0;
                  await FirebaseChatService.instance.blockTarget(
                    myUserId: myUserId,
                    targetId: widget.subdomain,
                    targetName: storeName,
                    targetAvatar: storeLogo,
                    targetType: 'store',
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: _ink,
                      content: Text(
                        s.tr('تم حظر المتجر بنجاح', 'Boutique bloquée',
                            'Store blocked'),
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOrderSheet() {
    final s = _state.s;
    final nameCtrl = TextEditingController(
        text: _state.currentUser?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(
        text: _state.currentUser?['phone']?.toString() ?? '');
    final cityCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    int? selectedAdId =
        _ads.isNotEmpty ? int.tryParse(_ads.first['id'].toString()) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: _badgeBg, shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: _red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.tr('طلب سريع من المتجر', 'Commande directe',
                          'Direct Store Order'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing:
                            AppTypography.trackingForContext(context, -0.4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_ads.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: selectedAdId,
                  decoration: InputDecoration(
                      labelText: s.tr('اختر المنتج', 'Choisir le produit')),
                  items: _ads
                      .map((a) => DropdownMenuItem<int>(
                            value: int.tryParse(a['id'].toString()),
                            child: Text(a['title'].toString(),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => selectedAdId = v,
                ),
              const SizedBox(height: 10),
              TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      labelText: s.tr('الاسم الكامل', 'Nom complet'))),
              const SizedBox(height: 10),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: s.tr('رقم الهاتف', 'Téléphone'))),
              const SizedBox(height: 10),
              TextField(
                  controller: cityCtrl,
                  decoration:
                      InputDecoration(labelText: s.tr('المدينة', 'Ville'))),
              const SizedBox(height: 10),
              TextField(
                  controller: locCtrl,
                  decoration: InputDecoration(
                      labelText: s.tr('العنوان', 'Adresse de livraison'))),
              const SizedBox(height: 10),
              TextField(
                  controller: msgCtrl,
                  decoration: InputDecoration(
                      labelText: s.tr('ملاحظات الطلب', 'Notes'))),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () async {
                    if (selectedAdId == null ||
                        nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      final encoded = Uri.encodeComponent(widget.subdomain);
                      final res = await _state.api.dio
                          .post('/stores/$encoded/order', data: {
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
                      });
                      if (mounted &&
                          res.data is Map &&
                          res.data['status'] == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppConfig.success,
                            content: Text(s.tr('تم إرسال طلبك للمتجر بنجاح!',
                                'Commande envoyée avec succès !')),
                          ),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Text(
                    s.tr('تأكيد الطلب الآن', 'Confirmer la commande'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F3F7),
        body: StoreDetailSkeleton(),
      );
    }
    final store = _store;
    if (store == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(backgroundColor: const Color(0xFFF2F3F7), elevation: 0),
        body: Center(
            child: Text(s.tr('المتجر غير موجود', 'Boutique introuvable'))),
      );
    }
    final logo = store['logo_url'] ?? store['logo'];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      floatingActionButton:
          (_ads.isNotEmpty && store['direct_order_enabled'] != false)
              ? FloatingActionButton.extended(
              onPressed: _openOrderSheet,
              backgroundColor: const Color(0xFF0A0A0A),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.shopping_bag_outlined, size: 20),
              label: Text(
                s.tr('اطلب الآن', 'Commander'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Top bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    PressableScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 17, color: _ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (store['name'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing:
                              AppTypography.trackingForContext(context, -0.4),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: store['is_pro_plus'] == true
                            ? const Color(0xFFFEF3C7)
                            : _badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            store['is_pro_plus'] == true
                                ? CupertinoIcons.checkmark_seal_fill
                                : CupertinoIcons.briefcase_fill,
                            size: 14,
                            color: store['is_pro_plus'] == true
                                ? const Color(0xFFD97706)
                                : _red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store['is_pro_plus'] == true ? 'PRO+' : 'Business',
                            style: TextStyle(
                              color: store['is_pro_plus'] == true
                                  ? const Color(0xFF92400E)
                                  : _red,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PressableScale(
                      onTap: () => _showStoreSafetySheet(store),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.ellipsis,
                          size: 18,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Store Profile Showcase Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
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
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: _border, width: 1.5),
                                      ),
                                      child: AppAvatar(
                                        url: logo?.toString(),
                                        radius: 40,
                                        fallbackIcon: Icons.storefront_rounded,
                                      ),
                                    ),
                                    PositionedDirectional(
                                      bottom: 2,
                                      end: 2,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _ink,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2.5),
                                        ),
                                        child: const Icon(Icons.check_rounded,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  (store['name'] ?? '').toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                    letterSpacing:
                                        AppTypography.trackingForContext(
                                            context, -0.4),
                                  ),
                                ),
                                const SizedBox(height: 6),
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
                                        color: _pillBg,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        businessCategory,
                                        style: const TextStyle(
                                          fontSize: 11.8,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
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
                                          color: _pillBg,
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
                                                      : const Color(0xFFEF4444),
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
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: _ink,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (location.isNotEmpty || mapsUrl.isNotEmpty) ...[
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
                                        const Icon(
                                          CupertinoIcons.location_solid,
                                          size: 13,
                                          color: _ink,
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
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: _ink,
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
                                    style: const TextStyle(
                                        color: _muted,
                                        fontSize: 13.5,
                                        height: 1.4),
                                  ),
                                ],
                                if (phone.isNotEmpty || _ads.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      if (phone.isNotEmpty) ...[
                                        Expanded(
                                          child: PressableScale(
                                            onTap: () async {
                                              final cleanPhone = phone.replaceAll(
                                                  RegExp(r'[^0-9+]'), '');
                                              if (cleanPhone.isEmpty) return;
                                              final uri =
                                                  Uri.parse('tel:$cleanPhone');
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri);
                                              }
                                            },
                                            child: Container(
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: _pillBg,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons.phone_fill,
                                                    size: 15,
                                                    color: _ink,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      s.tr('اتصال', 'Appeler',
                                                          'Call'),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: _ink,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_ads.isNotEmpty &&
                                            directOrderAllowed)
                                          const SizedBox(width: 10),
                                      ],
                                      if (_ads.isNotEmpty &&
                                          directOrderAllowed)
                                        Expanded(
                                          child: PressableScale(
                                            onTap: _openOrderSheet,
                                            child: Container(
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: _ink,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons.bag_fill,
                                                    size: 15,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      s.tr('طلب مباشر',
                                                          'Commander', 'Order'),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
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
                                ],
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _pillBg,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              '${_ads.length}',
                                              textDirection: TextDirection.ltr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: _ink,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures()
                                                  ]),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              s.tr('المنتجات', 'Produits'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: _muted,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          width: 1, height: 28, color: _border),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              '100%',
                                              textDirection: TextDirection.ltr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: _ink,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures()
                                                  ]),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              s.tr('موثوق', 'Vérifié'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: _muted,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          width: 1, height: 28, color: _border),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            const Text(
                                              '24/48h',
                                              textDirection: TextDirection.ltr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: _ink,
                                                  fontFeatures: [
                                                    FontFeature.tabularFigures()
                                                  ]),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              s.tr('التوصيل', 'Livraison'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: _muted,
                                                  fontWeight: FontWeight.w600),
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  s.tr('منتجات المتجر', 'Catalogue de la boutique',
                      'Store Catalog'),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing:
                        AppTypography.trackingForContext(context, -0.4),
                  ),
                ),
              ),
            ),

            // Products Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
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
    );
  }
}
