import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
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
    final nameCtrl = TextEditingController(text: _state.currentUser?['name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: _state.currentUser?['phone']?.toString() ?? '');
    final cityCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    int? selectedAdId = _ads.isNotEmpty ? int.tryParse(_ads.first['id'].toString()) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.tr('طلب سريع من المتجر', 'Commander auprès de la boutique'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_ads.isNotEmpty)
              DropdownButtonFormField<int>(
                value: selectedAdId,
                decoration: InputDecoration(labelText: s.tr('اختر المنتج', 'Choisir le produit')),
                items: _ads
                    .map((a) => DropdownMenuItem<int>(
                          value: int.tryParse(a['id'].toString()),
                          child: Text(a['title'].toString(), overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => selectedAdId = v,
              ),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: s.tr('الاسم الكامل', 'Nom complet'))),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.tr('رقم الهاتف', 'Téléphone'))),
            const SizedBox(height: 10),
            TextField(controller: cityCtrl, decoration: InputDecoration(labelText: s.tr('المدينة', 'Ville'))),
            const SizedBox(height: 10),
            TextField(controller: locCtrl, decoration: InputDecoration(labelText: s.tr('العنوان', 'Adresse de livraison'))),
            const SizedBox(height: 10),
            TextField(controller: msgCtrl, decoration: InputDecoration(labelText: s.tr('ملاحظات الطلب', 'Notes'))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedAdId == null || nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final res = await _state.api.dio.post('/stores/${widget.subdomain}/order', data: {
                      'ad_id': selectedAdId,
                      'full_name': nameCtrl.text.trim(),
                      'phone_number': phoneCtrl.text.trim(),
                      'city': cityCtrl.text.trim().isNotEmpty ? cityCtrl.text.trim() : 'Casablanca',
                      'location': locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : '-',
                      'message': msgCtrl.text.trim(),
                    });
                    if (mounted && res.data is Map && res.data['status'] == 'success') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppConfig.success, content: Text(s.tr('تم إرسال طلبك للمتجر بنجاح!', 'Commande envoyée avec succès !'))),
                      );
                    }
                  } catch (_) {}
                },
                child: Text(s.tr('تأكيد الطلب', 'Confirmer la commande')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final store = _store;
    if (store == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(s.tr('المتجر غير موجود', 'Boutique introuvable'))));
    }
    final logo = store['logo_url'] ?? store['logo'];

    return Scaffold(
      appBar: AppBar(title: Text((store['name'] ?? '').toString())),
      floatingActionButton: _ads.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openOrderSheet,
              backgroundColor: AppConfig.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(s.tr('اطلب الآن', 'Commander')),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppAvatar(
                    url: logo?.toString(),
                    radius: 42,
                    fallbackIcon: Icons.store,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (store['name'] ?? '').toString(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (store['description'] ?? '').toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppConfig.textSecondary, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, idx) => AdCard(ad: Map<String, dynamic>.from(_ads[idx])),
                childCount: _ads.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
