import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'store_detail_screen.dart';
import 'widgets/app_image.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final AppState _state = AppState();
  List<dynamic> _stores = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    setState(() => _loading = true);
    try {
      final res = await _state.api.dio.get('/stores', queryParameters: {
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
      });
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _stores = res.data['data'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.stores)),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _fetchStores(),
              decoration: InputDecoration(
                hintText: s.tr('ابحث عن متجر احترافي...', 'Rechercher une boutique...'),
                prefixIcon: const Icon(Icons.storefront),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchStores,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _stores.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final store = _stores[idx];
                        final logo = store['logo_url'] ?? store['logo'];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreDetailScreen(subdomain: store['subdomain'].toString()),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                AppAvatar(
                                  url: logo?.toString(),
                                  radius: 30,
                                  fallbackIcon: Icons.store,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (store['name'] ?? '').toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (store['description'] ?? '').toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppConfig.textSecondary, fontSize: 12.5),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory_2_outlined, size: 14, color: AppConfig.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${store['active_products_count'] ?? store['ads_count'] ?? 0} ${s.tr('منتج', 'produits')}',
                                            style: const TextStyle(color: AppConfig.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppConfig.textSecondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
