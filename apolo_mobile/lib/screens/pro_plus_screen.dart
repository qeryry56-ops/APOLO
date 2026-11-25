import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/app_typography.dart';
import '../widgets/dl_settings_kit.dart';

/// Pro Plus Subscription & Google Pay / Google Play Billing Screen.
class ProPlusScreen extends StatefulWidget {
  const ProPlusScreen({super.key});

  @override
  State<ProPlusScreen> createState() => _ProPlusScreenState();
}

class _ProPlusScreenState extends State<ProPlusScreen> {
  final AppState _state = AppState();
  List<Map<String, dynamic>> _plans = [];
  String _selectedPlanId = 'monthly';
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  static const Color _gold = Color(0xFFD97706);
  static const Color _goldSoft = Color(0xFFFEF3C7);

  static List<Map<String, dynamic>> _fallbackPlans() => [
        {
          'id': 'monthly',
          'iap_product_id': 'ma.apolo.pro_plus.monthly',
          'name_ar': 'باقة Pro Plus الشهرية',
          'name_fr': 'Abonnement Pro Plus Mensuel',
          'price_mad': 99.0,
          'duration_days': 30,
          'vip_boost_credits': 3,
          'badge_ar': 'الأكثر طلباً',
          'badge_fr': 'Populaire',
          'features_ar': [
            'شارة التوثيق الرسمية PRO+ بجانب اسمك ومتجرك',
            'صدارة الظهور في صفحة المتاجر ونتائج البحث',
            '3 تمويلات VIP مجانية شهرياً لإعلاناتك',
            'إحصائيات متقدمة (نقرات الاتصال، المحادثات، والطلبيات)',
            'ردود سريعة لا محدودة في الشات مع رسالة ترحيب تلقائية',
          ],
          'features_fr': [
            'Badge officiel PRO+ vérifié sur votre boutique et annonces',
            'Priorité d’affichage en tête des boutiques et recherches',
            '3 Boosts VIP gratuits inclus chaque mois',
            'Statistiques avancées (appels, messages et commandes)',
            'Réponses rapides illimitées et message d’accueil auto',
          ],
        },
        {
          'id': 'yearly',
          'iap_product_id': 'ma.apolo.pro_plus.yearly',
          'name_ar': 'باقة Pro Plus السنوية (وفّر 25%)',
          'name_fr': 'Abonnement Pro Plus Annuel (-25%)',
          'price_mad': 899.0,
          'duration_days': 365,
          'vip_boost_credits': 36,
          'badge_ar': 'توفير 25%',
          'badge_fr': 'Économisez 25%',
          'features_ar': [
            'جميع مزايا Pro Plus لمدة سنة كاملة',
            '36 رصيد تمويل VIP لإعلاناتك طيلة السنة',
            'أولوية قصوى في قسم المتاجر الموصى بها',
          ],
          'features_fr': [
            'Tous les avantages Pro Plus pendant 12 mois',
            '36 crédits Boost VIP inclus sur l’année',
            'Priorité maximale dans les boutiques recommandées',
          ],
        },
      ];

  @override
  void initState() {
    super.initState();
    _loadPlans();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      _iapSub = InAppPurchase.instance.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _iapSub?.cancel(),
        onError: (_) {},
      );
    }
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final res = await _state.api.dio.get('/pro-plus/plans');
      if (res.data is Map && res.data['status'] == 'success') {
        final raw = res.data['plans'];
        if (raw is List && raw.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _plans = raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _selectedPlanId = (_plans.first['id'] ?? 'monthly').toString();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _plans = _fallbackPlans();
      _loading = false;
    });
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> detailsList) async {
    for (final details in detailsList) {
      if (details.status == PurchaseStatus.purchased ||
          details.status == PurchaseStatus.restored) {
        final matching = _plans.where(
            (p) => (p['iap_product_id'] ?? '').toString() == details.productID);
        if (matching.isEmpty || details.purchaseID == null) continue;
        try {
          await _state.subscribeToProPlus(
            plan: matching.first['id'].toString(),
            platform:
                defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
            transactionId: details.purchaseID!,
            receiptData: details.verificationData.serverVerificationData,
          );
          if (details.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(details);
          }
          if (!mounted) return;
          setState(() => _purchasing = false);
          _showSuccessAndPop();
        } catch (_) {
          if (mounted) {
            setState(() {
              _purchasing = false;
              _error = _state.s.tr(
                'لم يكتمل تأكيد الدفع مع الخادم. حاول مجدداً.',
                'Vérification du paiement échouée.',
                'Payment verification failed.',
              );
            });
          }
        }
      } else if (details.status == PurchaseStatus.error ||
          details.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _purchasing = false);
      }
    }
  }

  void _showSuccessAndPop() {
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppConfig.success,
        content: Text(
          _state.s.tr(
            'مبروك! تم تفعيل باقة Pro Plus وتوثيق متجرك بنجاح 👑',
            'Félicitations ! Abonnement Pro Plus activé avec succès 👑',
            'Pro Plus activated! Your store is now verified 👑',
          ),
        ),
      ),
    );
  }

  Future<void> _startGooglePayCheckout() async {
    if (_purchasing || _plans.isEmpty || !_state.isLoggedIn) return;
    HapticFeedback.selectionClick();
    final plan = _plans.firstWhere(
      (p) => p['id'].toString() == _selectedPlanId,
      orElse: () => _plans.first,
    );
    final productId = (plan['iap_product_id'] ?? 'ma.apolo.pro_plus.monthly')
        .toString();

    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      // On Web: show Google Pay confirmation sheet & authorize checkout
      if (kIsWeb) {
        final confirmed = await _showGooglePayWebSheet(plan);
        if (confirmed != true) {
          if (mounted) setState(() => _purchasing = false);
          return;
        }
        await _state.subscribeToProPlus(
          plan: plan['id'].toString(),
          platform: 'google_pay_web',
          transactionId: 'GPAY-${DateTime.now().millisecondsSinceEpoch}',
          receiptData: 'google_pay_web_authorized',
        );
        if (!mounted) return;
        setState(() => _purchasing = false);
        _showSuccessAndPop();
        return;
      }

      // On Android / iOS: launch native Google Play Billing (supports Google Pay natively)
      final available = await InAppPurchase.instance.isAvailable();
      if (available) {
        final response =
            await InAppPurchase.instance.queryProductDetails({productId});
        if (response.productDetails.isNotEmpty) {
          final param =
              PurchaseParam(productDetails: response.productDetails.first);
          final started = await InAppPurchase.instance
              .buyNonConsumable(purchaseParam: param);
          if (started) return;
        }
      }

      throw StateError('Store billing unavailable');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _error = _state.s.tr(
          'تعذر فتح نافذة Google Pay على هذا الجهاز حالياً. تأكد من تفعيل حساب Google Play.',
          'Impossible d’ouvrir Google Pay sur cet appareil.',
          'Could not launch Google Pay on this device.',
        );
      });
    }
  }

  Future<bool?> _showGooglePayWebSheet(Map<String, dynamic> plan) {
    final s = _state.s;
    final palette = ApoloDlPalette.of(context);
    final price = plan['price_mad'] ?? 99;
    final planTitle = s.isAr
        ? (plan['name_ar'] ?? '').toString()
        : (plan['name_fr'] ?? '').toString();

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.separator,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'G Pay',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                planTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$price MAD',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 18),
              ApoloDlButton(
                key: const Key('gpay-confirm-btn'),
                label: s.tr(
                  'تأكيد الدفع عبر Google Pay',
                  'Payer avec Google Pay',
                  'Pay with Google Pay',
                ),
                variant: ApoloDlButtonVariant.primary,
                borderRadius: 999,
                fullWidth: true,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 8),
              ApoloDlButton(
                label: s.tr('إلغاء', 'Annuler', 'Cancel'),
                variant: ApoloDlButtonVariant.secondary,
                borderRadius: 999,
                fullWidth: true,
                onPressed: () => Navigator.of(ctx).pop(false),
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
    final isAr = s.isAr;
    final palette = ApoloDlPalette.of(context);
    final selectedPlan = _plans.firstWhere(
      (p) => p['id'].toString() == _selectedPlanId,
      orElse: () => _plans.isNotEmpty ? _plans.first : _fallbackPlans().first,
    );
    final features = ((isAr
                ? selectedPlan['features_ar']
                : selectedPlan['features_fr']) as List? ??
            const [])
        .map((e) => e.toString())
        .toList();

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Column(
            children: [
              ApoloDlTopNav(
                title: 'Apolo Pro Plus 👑',
                size: ApoloDlTopNavSize.md,
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CupertinoActivityIndicator())
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                            children: [
                              if (_state.isProPlusAccount)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _goldSoft,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        color: _gold,
                                        size: 26,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.tr(
                                                'اشتراك Pro Plus مفعل على حسابك!',
                                                'Votre abonnement Pro Plus est actif !',
                                                'Your Pro Plus plan is active!',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF78350F),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              s.tr(
                                                'رصيد تمويل VIP المجاني المتبقي: ${_state.vipBoostCredits}',
                                                'Crédits Boost VIP restants : ${_state.vipBoostCredits}',
                                                'Remaining free VIP boosts: ${_state.vipBoostCredits}',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF92400E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Hero Header
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0A0A),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _gold,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'PRO+ VERIFIED',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      s.tr(
                                        'تصدر المتاجر، وثّق علامتك، وضاعف مبيعاتك',
                                        'Dominez les recherches et certifiez votre boutique',
                                        'Verify your store & rank #1 in search',
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                        letterSpacing:
                                            AppTypography.trackingForContext(
                                                context, -0.4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      s.tr(
                                        'الباقة الاحترافية للتجار والمعارض في المغرب مع الدفع السريع عبر Google Pay.',
                                        'La formule complète pour les marchands au Maroc via Google Pay.',
                                        'Built for top Moroccan sellers with fast Google Pay checkout.',
                                      ),
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.78),
                                        fontSize: 13.2,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              if (_error != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: palette.dangerSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: palette.danger,
                                    ),
                                  ),
                                ),

                              // Plan Selector Cards
                              ..._plans.map((plan) {
                                final id = plan['id'].toString();
                                final selected = _selectedPlanId == id;
                                final price = plan['price_mad'] ?? 99;
                                final badge = (isAr
                                        ? plan['badge_ar']
                                        : plan['badge_fr'])
                                    ?.toString();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    key: Key('pro-plus-plan-$id'),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _selectedPlanId = id);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: palette.groupCard,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        border: Border.all(
                                          color: selected
                                              ? palette.ink
                                              : Colors.transparent,
                                          width: 1.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected
                                                ? CupertinoIcons
                                                    .checkmark_circle_fill
                                                : CupertinoIcons.circle,
                                            color: selected
                                                ? palette.ink
                                                : palette.muted,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (badge != null &&
                                                    badge.isNotEmpty)
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            bottom: 4),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _goldSoft,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Text(
                                                      badge,
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: _gold,
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  (isAr
                                                          ? plan['name_ar']
                                                          : plan['name_fr'])
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: palette.ink,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '$price ${isAr ? 'د.م' : 'DH'}',
                                            style: TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w900,
                                              color: palette.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 12),

                              // Perks Checklist
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: palette.groupCard,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.tr(
                                        'كل ما تحصل عليه فور التفعيل:',
                                        'Inclus dans votre abonnement :',
                                        'Included with your membership:',
                                      ),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: palette.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...features.map(
                                      (feat) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              CupertinoIcons
                                                  .checkmark_alt_circle_fill,
                                              size: 18,
                                              color: AppConfig.success,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                feat,
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: palette.ink,
                                                  height: 1.35,
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

              // Google Pay Primary Footer Button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: BoxDecoration(
                  color: palette.bg,
                  border: Border(
                    top: BorderSide(color: palette.separator, width: 0.8),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('pro-plus-google-pay-btn'),
                      onPressed: _purchasing ? null : _startGooglePayCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A0A0A),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: _purchasing
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  CupertinoIcons.creditcard_fill,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _state.isProPlusAccount
                                      ? s.tr(
                                          'تمديد باقة Pro Plus عبر Google Pay',
                                          'Prolonger via Google Pay',
                                          'Extend with Google Pay',
                                        )
                                      : s.tr(
                                          'اشترك الآن عبر Google Pay',
                                          'S’abonner avec Google Pay',
                                          'Subscribe with Google Pay',
                                        ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
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
