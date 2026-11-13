import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../theme/app_typography.dart';

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

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _red = Color(0xFFE31B23);
  static const Color _badgeBg = Color(0xFFFEECEE);
  static const Color _border = Color(0xFFE7EAF0);

  @override
  void initState() {
    super.initState();
    _loadPlans();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          InAppPurchase.instance.purchaseStream;
      _iapSub = purchaseUpdated.listen(_onPurchaseUpdate,
          onDone: () => _iapSub?.cancel(), onError: (_) {});
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
        if (!mounted) return;
        setState(() {
          _plans = (res.data['plans'] is List ? res.data['plans'] as List : [])
              .whereType<Map>()
              .toList();
          if (_plans.isNotEmpty) {
            _selectedPlanId = _plans.first['id'].toString();
          }
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _plans = [];
      _loading = false;
    });
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> detailsList) async {
    for (final details in detailsList) {
      if (details.status == PurchaseStatus.purchased ||
          details.status == PurchaseStatus.restored) {
        final matching = _plans.where((p) =>
            (p['iap_product_id'] ?? p['product_id']) == details.productID);
        if (matching.isEmpty ||
            details.purchaseID == null ||
            details.verificationData.serverVerificationData.isEmpty) {
          continue;
        }
        final verified = await _verifyWithBackend(
          planId: matching.first['id'].toString(),
          transactionId: details.purchaseID!,
          receiptData: details.verificationData.serverVerificationData,
        );
        if (verified && details.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(details);
        }
      } else if (details.status == PurchaseStatus.error ||
          details.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _purchasing = false);
      }
    }
  }

  Future<void> _startPurchase() async {
    if (_purchasing || _plans.isEmpty || !_state.isLoggedIn) return;
    final plan = _plans.firstWhere((p) => p['id'] == _selectedPlanId,
        orElse: () => _plans.first);
    final String productId =
        (plan['iap_product_id'] ?? plan['product_id']).toString();
    setState(() => _purchasing = true);

    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final bool available = await InAppPurchase.instance.isAvailable();
        if (available) {
          final ProductDetailsResponse response =
              await InAppPurchase.instance.queryProductDetails({productId});
          if (response.productDetails.isNotEmpty) {
            final param =
                PurchaseParam(productDetails: response.productDetails.first);
            final started = await InAppPurchase.instance
                .buyConsumable(purchaseParam: param);
            if (!started) throw StateError('Purchase did not start');
            return;
          }
        }
      }
      throw StateError('Purchases unavailable on this platform');
    } catch (e) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_state.s
                  .tr('تعذر إتمام عملية الدفع', 'Erreur lors du paiement'))),
        );
      }
    }
  }

  Future<bool> _verifyWithBackend({
    required String planId,
    required String transactionId,
    required String receiptData,
  }) async {
    try {
      final res = await _state.api.dio.post(
        '/ads/${widget.adId}/boost/verify-iap',
        data: {
          'plan': planId,
          'platform':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'transaction_id': transactionId,
          'receipt_data': receiptData,
        },
      );
      if (mounted) {
        setState(() => _purchasing = false);
        if (res.data is Map && res.data['status'] == 'success') {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context, true);
          messenger.showSnackBar(
            SnackBar(
              backgroundColor: AppConfig.success,
              content: Text(res.data['message']?.toString() ??
                  _state.s.tr('تم تمييز إعلانك بنجاح!',
                      'Annonce boostée avec succès !')),
            ),
          );
          return true;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _purchasing = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_state.s.tr(
              'لم يتم تأكيد الدفع. تواصل مع الدعم قبل إعادة الشراء.',
              'Paiement non confirmé. Contactez l’assistance avant de racheter.'))));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: _loading
          ? const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: _red)))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          color: _badgeBg, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.bolt_rounded, color: _red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.tr('ميّز إعلانك وضاعف مبيعاتك',
                                'Boostez votre annonce'),
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: AppTypography.trackingForContext(
                                    context, -0.4)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.adTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_plans.isEmpty)
                  Text(s.tr('العروض غير متوفرة حالياً. أعد المحاولة لاحقاً.',
                      'Les offres sont indisponibles. Réessayez plus tard.')),
                if (kIsWeb)
                  Text(s.tr('الشراء من الويب غير متاح حالياً.',
                      'Les achats sur le Web ne sont pas disponibles.')),
                ..._plans.map((plan) {
                  final String id = plan['id'].toString();
                  final bool selected = _selectedPlanId == id;
                  final String name =
                      (s.isAr ? plan['name_ar'] : plan['name_fr']).toString();
                  final List features =
                      (s.isAr ? plan['features_ar'] : plan['features_fr']) ??
                          [];
                  return GestureDetector(
                    onTap: _purchasing
                        ? null
                        : () => setState(() => _selectedPlanId = id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? _badgeBg.withValues(alpha: 0.55)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _red : _border,
                          width: selected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
                                      color: _ink,
                                      letterSpacing:
                                          AppTypography.trackingForContext(
                                              context, -0.2)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      selected ? _red : const Color(0xFFF1F3F7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${plan['price_mad']} MAD',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: selected ? Colors.white : _ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...features.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 16,
                                        color: selected
                                            ? _red
                                            : AppConfig.success),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        f.toString(),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _ink,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _purchasing ||
                            _plans.isEmpty ||
                            kIsWeb ||
                            !_state.isLoggedIn
                        ? null
                        : _startPurchase,
                    icon: _purchasing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bolt_rounded, size: 20),
                    label: Text(
                      s.tr('تفعيل التمييز الآن', 'Activer le Boost maintenant'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15.5),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
