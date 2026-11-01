import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';

class BoostSheet extends StatefulWidget {
  final int adId;
  final String adTitle;

  const BoostSheet({super.key, required this.adId, required this.adTitle});

  @override
  State<BoostSheet> createState() => _BoostSheetState();
}

class _BoostSheetState extends State<BoostSheet> {
  final AppState _state = AppState();
  List<dynamic> _plans = [];
  String _selectedPlanId = 'vip';
  bool _loading = true;
  bool _purchasing = false;
  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
      _iapSub = purchaseUpdated.listen(_onPurchaseUpdate, onDone: () => _iapSub?.cancel(), onError: (_) {});
    }
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final res = await _state.api.dio.get('/boost/plans');
      if (res.data is Map && res.data['status'] == 'success') {
        setState(() {
          _plans = res.data['plans'] ?? [];
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _plans = [
        {
          'id': 'highlight',
          'iap_product_id': 'ma.apolo.boost.highlight',
          'name_ar': 'إعلان مميز (7 أيام)',
          'name_fr': 'Annonce Mise en avant (7 jours)',
          'price_mad': 49,
          'duration_days': 7,
          'features_ar': ['ظهور أعلى نتائج البحث', 'شارة مميز ذهبية', 'مشاهدات مضاعفة 3x'],
          'features_fr': ['En tête des résultats', 'Badge spécial', '3x plus de vues'],
        },
        {
          'id': 'vip',
          'iap_product_id': 'ma.apolo.boost.vip',
          'name_ar': 'باقة VIP الذهبية (15 يوم)',
          'name_fr': 'Pack VIP Or (15 jours)',
          'price_mad': 99,
          'duration_days': 15,
          'features_ar': ['الظهور في الصفحة الرئيسية VIP', 'أولوية قصوى في البحث', 'شارة VIP ذهبية', 'مشاهدات مضاعفة 7x'],
          'features_fr': ['Affichage accueil VIP', 'Priorité maximale', 'Badge VIP Or', '7x plus de vues'],
        }
      ];
      _loading = false;
    });
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> detailsList) async {
    for (final details in detailsList) {
      if (details.status == PurchaseStatus.purchased || details.status == PurchaseStatus.restored) {
        await _verifyWithBackend(
          planId: _selectedPlanId,
          transactionId: details.purchaseID ?? 'IAP_${DateTime.now().millisecondsSinceEpoch}',
          receiptData: details.verificationData.serverVerificationData,
        );
        if (details.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(details);
        }
      } else if (details.status == PurchaseStatus.error || details.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _purchasing = false);
      }
    }
  }

  Future<void> _startPurchase() async {
    final plan = _plans.firstWhere((p) => p['id'] == _selectedPlanId, orElse: () => _plans.first);
    final String productId = (plan['iap_product_id'] ?? plan['product_id']).toString();
    setState(() => _purchasing = true);

    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        final bool available = await InAppPurchase.instance.isAvailable();
        if (available) {
          final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({productId});
          if (response.productDetails.isNotEmpty) {
            final param = PurchaseParam(productDetails: response.productDetails.first);
            await InAppPurchase.instance.buyConsumable(purchaseParam: param);
            return;
          }
        }
      }
      // Fallback for Staging / Sandbox / Web testing
      await _verifyWithBackend(
        planId: _selectedPlanId,
        transactionId: 'STG_${DateTime.now().millisecondsSinceEpoch}',
        receiptData: 'STAGING_SANDBOX_RECEIPT',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_state.s.tr('تعذر إتمام عملية الدفع', 'Erreur lors du paiement'))),
        );
      }
    }
  }

  Future<void> _verifyWithBackend({
    required String planId,
    required String transactionId,
    required String receiptData,
  }) async {
    try {
      final res = await _state.api.dio.post(
        '/ads/${widget.adId}/boost/verify-iap',
        data: {
          'plan': planId,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'transaction_id': transactionId,
          'receipt_data': receiptData,
        },
      );
      if (mounted) {
        setState(() => _purchasing = false);
        if (res.data is Map && res.data['status'] == 'success') {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppConfig.success,
              content: Text(res.data['message']?.toString() ?? _state.s.tr('تم تمييز إعلانك بنجاح!', 'Annonce boostée avec succès !')),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _loading
          ? const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppConfig.vipGold, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.tr('ميّز إعلانك وضاعف مبيعاتك', 'Boostez votre annonce et vendez plus vite'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.adTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppConfig.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ..._plans.map((plan) {
                  final String id = plan['id'].toString();
                  final bool selected = _selectedPlanId == id;
                  final String name = (s.isAr ? plan['name_ar'] : plan['name_fr']).toString();
                  final List features = (s.isAr ? plan['features_ar'] : plan['features_fr']) ?? [];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlanId = id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: selected ? AppConfig.vipGold.withValues(alpha: 0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? AppConfig.vipGold : const Color(0xFFE2E8F0),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConfig.vipGold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${plan['price_mad']} MAD',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...features.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 15, color: AppConfig.success),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(f.toString(), style: const TextStyle(fontSize: 12.5))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.vipGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _purchasing ? null : _startPurchase,
                    icon: _purchasing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.workspace_premium),
                    label: Text(
                      s.tr('تفعيل التمييز الآن', 'Activer le Boost maintenant'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
