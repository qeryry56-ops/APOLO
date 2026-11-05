import 'package:flutter/material.dart';
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

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _red = Color(0xFFE31B23);
  static const Color _badgeBg = Color(0xFFFEECEE);
  static const Color _pillBg = Color(0xFFF1F3F7);
  static const Color _border = Color(0xFFE7EAF0);

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
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oversized Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  if (canPop) ...[
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 17, color: _ink),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      s.stores,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.9,
                        height: 1.05,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 15, color: _red),
                        const SizedBox(width: 5),
                        Text(
                          'PRO',
                          style: const TextStyle(color: _red, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pill Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _pillBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: _muted, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: (_) => _fetchStores(),
                        style: const TextStyle(color: _ink, fontSize: 14.5, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: s.tr('ابحث عن متجر احترافي معتمد...', 'Rechercher une boutique officielle...'),
                          hintStyle: const TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _fetchStores,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: _red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_rounded, size: 17, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Store Cards List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _red))
                  : _stores.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  color: _badgeBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront_rounded, size: 32, color: _red),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                s.tr('لا توجد متاجر مطابقة حالياً', 'Aucune boutique trouvée'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: _red,
                          onRefresh: _fetchStores,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                            itemCount: _stores.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, idx) {
                              final store = _stores[idx];
                              final logo = store['logo_url'] ?? store['logo'];
                              final int count = int.tryParse((store['active_products_count'] ?? store['ads_count'] ?? 0).toString()) ?? 0;
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
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: _border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _ink.withValues(alpha: 0.045),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: _red.withValues(alpha: 0.25), width: 1.5),
                                            ),
                                            child: AppAvatar(
                                              url: logo?.toString(),
                                              radius: 30,
                                              fallbackIcon: Icons.storefront_rounded,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: _red,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (store['name'] ?? '').toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16.5,
                                                color: _ink,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            if ((store['description'] ?? '').toString().trim().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                (store['description'] ?? '').toString(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.35),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _badgeBg,
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.inventory_2_outlined, size: 13, color: _red),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '$count ${s.tr('منتج', 'produits')}',
                                                        style: const TextStyle(color: _red, fontSize: 11.5, fontWeight: FontWeight.w700),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Row(
                                                  children: [
                                                    Text(
                                                      s.tr('زيارة المتجر', 'Visiter'),
                                                      style: const TextStyle(color: _red, fontSize: 12.5, fontWeight: FontWeight.w700),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Icon(Icons.chevron_right_rounded, size: 17, color: _red),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
      ),
    );
  }
}
