import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/state/app_state.dart';
import '../../theme/app_typography.dart';
import '../../widgets/dl_settings_kit.dart';
import '../pro_plus_screen.dart';
import 'kinetic_widgets.dart';
import 'skeleton_loader.dart';
import '../../l10n/l10n.dart';

/// Dynamic Layer v5.1 Listing Boost Modal Sheet (`#FFFFFF` canvas, `#F6F6F6` plan cards,
/// `#EEEEEE` pills/circles, `#000000` primary ink & capsule CTAs).
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

  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlPill = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlAmber = Color(0xFFFFB800);

  @override
  void initState() {
    super.initState();
    _loadPlans();
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      final Stream<List<PurchaseDetails>> purchaseUpdated =
          InAppPurchase.instance.purchaseStream;
      _iapSub = purchaseUpdated.listen(
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
        final matching = _plans.where(
          (p) => (p['iap_product_id'] ?? p['product_id']) == details.productID,
        );
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
    HapticFeedback.mediumImpact();
    final plan = _plans.firstWhere(
      (p) => p['id'] == _selectedPlanId,
      orElse: () => _plans.first,
    );
    final String productId =
        (plan['iap_product_id'] ?? plan['product_id']).toString();
    setState(() => _purchasing = true);

    try {
      if (kIsWeb) {
        await _verifyWithBackend(
          planId: plan['id'].toString(),
          transactionId: 'WEB-${DateTime.now().millisecondsSinceEpoch}',
          receiptData: 'web-checkout',
          platformOverride: 'web',
        );
        return;
      }
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
    } catch (_) {
      if (mounted) {
        setState(() => _purchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _dlInk,
            behavior: SnackBarBehavior.floating,
            content: Text(
              _state.s.tr(
                'تعذر إتمام عملية الدفع',
                'Erreur lors du paiement',
                appL10n.boostCouldNotCompletePayment,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _verifyWithBackend({
    required String planId,
    required String transactionId,
    required String receiptData,
    String? platformOverride,
  }) async {
    try {
      final res = await _state.api.dio.post(
        '/ads/${widget.adId}/boost/verify-iap',
        data: {
          'plan': planId,
          'platform': platformOverride ??
              (kIsWeb
                  ? 'web'
                  : (defaultTargetPlatform == TargetPlatform.iOS
                      ? 'ios'
                      : 'android')),
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
              backgroundColor: _dlInk,
              behavior: SnackBarBehavior.floating,
              content: Text(
                res.data['message']?.toString() ??
                    _state.s.tr(
                      'تم تمييز إعلانك بنجاح!',
                      'Annonce boostée avec succès !',
                      appL10n.boostListingBoosted,
                    ),
              ),
            ),
          );
          return true;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _purchasing = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _dlInk,
          behavior: SnackBarBehavior.floating,
          content: Text(
            _state.s.tr(
              'لم يتم تأكيد الدفع. تواصل مع الدعم قبل إعادة الشراء.',
              'Paiement non confirmé. Contactez l’assistance avant de racheter.',
              appL10n.boostPaymentNotConfirmedContactSupport,
            ),
          ),
        ),
      );
    }
    return false;
  }

  Future<void> _redeemProPlusCredit() async {
    if (_purchasing ||
        !_state.isProPlusAccount ||
        _state.vipBoostCredits <= 0) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _purchasing = true);
    try {
      final res =
          await _state.api.dio.post('/ads/${widget.adId}/boost/use-credit');
      if (!mounted) return;
      setState(() => _purchasing = false);
      if (res.data is Map && res.data['status'] == 'success') {
        if (res.data['user'] is Map) {
          await _state.updateCurrentUser(
            Map<String, dynamic>.from(res.data['user'] as Map),
          );
        }
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: _dlInk,
            behavior: SnackBarBehavior.floating,
            content: Text(
              res.data['message']?.toString() ??
                  _state.s.tr(
                    'تم تفعيل VIP مجاناً من رصيد Pro Plus!',
                    'Boost VIP activé via votre crédit Pro Plus !',
                    appL10n.boostVipBoostActivatedUsingPro,
                  ),
            ),
          ),
        );
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final canPurchase = !_purchasing && _plans.isNotEmpty && _state.isLoggedIn;

    return Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: _dlBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const BoostPlansSkeleton()
              : SingleChildScrollView(
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
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: _dlPill,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              CupertinoIcons.bolt_fill,
                              color: _dlInk,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.tr(
                                    'ميّز إعلانك وضاعف مبيعاتك',
                                    'Boostez votre annonce',
                                    appL10n.boostListing,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w800,
                                    color: _dlInk,
                                    letterSpacing:
                                        AppTypography.trackingForContext(
                                            context, -0.4),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.adTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _dlMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ApoloDlIconCircleButton(
                            icon: CupertinoIcons.xmark,
                            iconSize: 16,
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Pro+ Credit Banner or Upgrade Promo
                      if (_state.isProPlusAccount &&
                          _state.vipBoostCredits > 0) ...[
                        PressableScale(
                          key: const Key('boost-use-pro-plus-credit-btn'),
                          onTap: _purchasing ? null : _redeemProPlusCredit,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: _dlInk,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 19,
                                  color: _dlAmber,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    s.tr(
                                      'تفعيل VIP مجاناً من رصيد Pro Plus (${_state.vipBoostCredits})',
                                      'Activer VIP gratuit via Pro Plus (${_state.vipBoostCredits})',
                                      appL10n.boostActivateFreeVipProVipboostcredits(_state.vipBoostCredits),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else if (_state.isLoggedIn &&
                          !_state.isProPlusAccount) ...[
                        PressableScale(
                          key: const Key('boost-open-pro-plus'),
                          onTap: () async {
                            final activated =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (_) => const SubscriptionScreen(),
                              ),
                            );
                            if (activated == true && mounted) {
                              setState(() {});
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: _dlBg,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 18,
                                    color: _dlInk,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.tr(
                                      'احصل على 3 تمويلات VIP مجانية شهرياً مع Apolo Pro+',
                                      '3 Boosts VIP offerts/mois avec Apolo Pro+',
                                      appL10n.boostGet3FreeVipBoosts,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w700,
                                      color: _dlInk,
                                    ),
                                  ),
                                ),
                                Icon(
                                  s.isAr
                                      ? CupertinoIcons.chevron_left
                                      : CupertinoIcons.chevron_right,
                                  size: 15,
                                  color: _dlMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_plans.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            s.tr(
                              'العروض غير متوفرة حالياً. أعد المحاولة لاحقاً.',
                              'Les offres sont indisponibles. Réessayez plus tard.',
                              appL10n.boostPlansAreCurrentlyUnavailablePlease,
                            ),
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: _dlMuted,
                            ),
                          ),
                        ),

                      if (kIsWeb && _plans.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            s.tr(
                              'الدفع الفوري عبر الويب متاح لحسابك.',
                              'Le paiement instantané sur le Web est activé pour votre compte.',
                              appL10n.boostInstantWebCheckoutIsEnabled,
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _dlMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      ..._plans.map((plan) {
                        final String id = plan['id'].toString();
                        final bool selected = _selectedPlanId == id;
                        final String name = (s.isAr
                                ? plan['name_ar']
                                : (s.isEn
                                    ? (plan['name_en'] ?? plan['name_fr'])
                                    : plan['name_fr']))
                            .toString();
                        final List features = (s.isAr
                                ? plan['features_ar']
                                : (s.isEn
                                    ? (plan['features_en'] ??
                                        plan['features_fr'])
                                    : plan['features_fr'])) ??
                            [];
                        return PressableScale(
                          onTap: _purchasing
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedPlanId = id);
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? _dlInk : Colors.transparent,
                                width: 1.8,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ApoloDlRadio(selected: selected),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5,
                                          color: _dlInk,
                                          letterSpacing:
                                              AppTypography.trackingForContext(
                                                  context, -0.2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected ? _dlInk : _dlBg,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${plan['price_mad']} MAD',
                                        textDirection: TextDirection.ltr,
                                        style: TextStyle(
                                          color:
                                              selected ? Colors.white : _dlInk,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (features.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ...features.map(
                                    (f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons
                                                .checkmark_circle_fill,
                                            size: 15,
                                            color: _dlInk,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              f.toString(),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: _dlInk,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 10),
                      PressableScale(
                        onTap: canPurchase ? _startPurchase : null,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: canPurchase ? _dlInk : _dlPill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_purchasing)
                                const CupertinoActivityIndicator(
                                  radius: 9,
                                  color: Colors.white,
                                )
                              else
                                Icon(
                                  CupertinoIcons.bolt_fill,
                                  size: 17,
                                  color: canPurchase ? Colors.white : _dlMuted,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                s.tr(
                                  'تفعيل التمييز الآن',
                                  'Activer le Boost maintenant',
                                  appL10n.boostActivateBoostNow,
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: canPurchase ? Colors.white : _dlMuted,
                                ),
                              ),
                            ],
                          ),
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
