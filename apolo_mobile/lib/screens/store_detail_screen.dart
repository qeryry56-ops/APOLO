import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import 'widgets/ad_card.dart';
import 'widgets/app_image.dart';

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

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _red = Color(0xFFE31B23);
  static const Color _badgeBg = Color(0xFFFEECEE);
  static const Color _pillBg = Color(0xFFF1F3F7);
  static const Color _border = Color(0xFFE7EAF0);

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    try {
      final res = await _state.api.dio.get('/stores/${widget.subdomain}');
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
                      final res = await _state.api.dio
                          .post('/stores/${widget.subdomain}/order', data: {
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
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _red)),
      );
    }
    final store = _store;
    if (store == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(),
        body: Center(
            child: Text(s.tr('المتجر غير موجود', 'Boutique introuvable'))),
      );
    }
    final logo = store['logo_url'] ?? store['logo'];

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _ads.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openOrderSheet,
              backgroundColor: _red,
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _pillBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _border),
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
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing:
                              AppTypography.trackingForContext(context, -0.5),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: _red),
                          SizedBox(width: 4),
                          Text('PRO',
                              style: TextStyle(
                                  color: _red,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Store Profile Showcase Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: _ink.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _red.withValues(alpha: 0.3), width: 2),
                            ),
                            child: AppAvatar(
                              url: logo?.toString(),
                              radius: 40,
                              fallbackIcon: Icons.storefront_rounded,
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _red,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
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
                              AppTypography.trackingForContext(context, -0.4),
                        ),
                      ),
                      if ((store['description'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          (store['description'] ?? '').toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: _muted, fontSize: 13.5, height: 1.4),
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
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: _ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.tr('المنتجات', 'Produits'),
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: _muted,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 28, color: _border),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text(
                                    '100%',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: _red),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.tr('موثوق', 'Vérifié'),
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: _muted,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 28, color: _border),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text(
                                    '24/48h',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: _ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.tr('التوصيل', 'Livraison'),
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
