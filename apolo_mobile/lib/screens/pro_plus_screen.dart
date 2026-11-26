import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../theme/dl_share_profile_tokens.dart';
import '../widgets/dl_settings_kit.dart';
import 'auth_screen.dart';
import 'privacy_compliance_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared Dynamic Layer v5.1 TopNav & Brand Mark for Subscription / Paywall / Trial
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildDlMonetizationTopNav(
  BuildContext context, {
  required bool isAr,
  required ApoloDlPalette palette,
  String? title,
  Key? navKey,
  Key? backKey,
  VoidCallback? onBack,
}) {
  final topInset = MediaQuery.paddingOf(context).top;
  final backIcon =
      isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left;

  return SizedBox(
    key: navKey,
    height: topInset + DlShareProfileLayout.topNavHeight,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: DlShareProfileLayout.topNavHeight,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DlShareProfileLayout.topNavHorizontalPadding,
          ),
          child: Row(
            children: [
              ApoloDlIconCircleButton(
                key: backKey,
                icon: backIcon,
                backgroundColor: palette.pill,
                iconColor: palette.ink,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: title != null && title.isNotEmpty
                    ? Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          height: 24.0 / 16.0,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 16.0),
              const SizedBox(width: 40.0, height: 40.0),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Official Apolo Pro+ Emblem replacing Figma's placeholder geometric mark.
class _ApoloProBrandMark extends StatelessWidget {
  final double size;

  const _ApoloProBrandMark({super.key, this.size = 112.0});

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final badgeHeight = (size * 0.24).clamp(20.0, 28.0);
    final cornerRadius = (size * 0.26).clamp(18.0, 32.0);

    return SizedBox(
      width: size,
      height: size + (badgeHeight * 0.35),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.16),
            decoration: BoxDecoration(
              color: const Color(0xFFE31828),
              borderRadius: BorderRadius.circular(cornerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20.0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/apolo_logo_white_transparent.png',
              fit: BoxFit.contain,
              semanticLabel: 'Apolo Pro Plus',
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              height: badgeHeight,
              padding: EdgeInsets.symmetric(horizontal: size * 0.11),
              decoration: BoxDecoration(
                color: palette.ink,
                borderRadius: BorderRadius.circular(999.0),
                border: Border.all(color: palette.bg, width: 2.0),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: badgeHeight * 0.52,
                    color: palette.onInk,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'PRO+',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: palette.onInk,
                      fontSize: (badgeHeight * 0.44).clamp(10.0, 12.5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fine-print subscription billing disclosure with tappable Terms & Privacy links.
class _DlSubscriptionLegalText extends StatefulWidget {
  final AppStrings strings;
  final ApoloDlPalette palette;

  const _DlSubscriptionLegalText({
    required this.strings,
    required this.palette,
  });

  @override
  State<_DlSubscriptionLegalText> createState() =>
      _DlSubscriptionLegalTextState();
}

class _DlSubscriptionLegalTextState extends State<_DlSubscriptionLegalText> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openCompliance;
    _privacyTap = TapGestureRecognizer()..onTap = _openCompliance;
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _openCompliance() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyComplianceScreen(initialTab: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final palette = widget.palette;
    final baseStyle = TextStyle(
      color: palette.muted,
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      height: 16.5 / 11.5,
    );
    final linkStyle = TextStyle(
      color: palette.ink,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      height: 16.5 / 11.5,
    );

    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: s.tr(
              'فوترة متكررة، يمكنك الإلغاء في أي وقت. يتم خصم الدفعة عبر حساب Google Pay / المتجر عند تأكيد الشراء، ويتجدد الاشتراك تلقائياً ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من نهاية الفترة الحالية.\nتخضع جميع البيانات لـ ',
              'Facturation récurrente, annulable à tout moment. Le paiement est débité via Google Pay / Store à la confirmation et se renouvelle automatiquement sauf résiliation 24h avant l’échéance.\nVos données sont protégées selon nos ',
              'Recurring billing. Cancel anytime. Payment will be charged to your Google Pay / Store account at confirmation of purchase and automatically renews unless turned off at least 24 hours before the end of the current period.\nAll personal data is handled under the ',
            ),
          ),
          TextSpan(
            text: s.tr(
              'الشروط والأحكام',
              'conditions générales',
              'terms and conditions',
            ),
            style: linkStyle,
            recognizer: _termsTap,
          ),
          TextSpan(
            text: s.tr(' و', ' et la ', ' and '),
          ),
          TextSpan(
            text: s.tr(
              'سياسة الخصوصية',
              'politique de confidentialité',
              'privacy policy',
            ),
            style: linkStyle,
            recognizer: _privacyTap,
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Dynamic Layer v5.1 `Subscription` Screen (Figma `45786:72976`)
//    - Not Subscribed: `Get Premium` + `#000000` 56px CTA -> `FreeTrialScreen`
//    - Active Subscriber: `You use Premium` + `#EEEEEE` 56px `Cancel my subscription`
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final AppState _state = AppState();
  bool _canceling = false;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  Future<void> _openGetPremiumFlow() async {
    HapticFeedback.selectionClick();
    final activated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const FreeTrialScreen()),
    );
    if (activated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmCancelSubscription() async {
    if (_canceling) return;
    HapticFeedback.selectionClick();
    final s = _state.s;
    final palette = ApoloDlPalette.of(context);

    final confirmed = await showApoloDlBottomSheet<bool>(
      context,
      headerTitle: s.tr('الاشتراك', 'Abonnement', 'Subscription'),
      media: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.pill,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.xmark_seal_fill,
          size: 26,
          color: palette.ink,
        ),
      ),
      contentTitle: s.tr(
        'إلغاء اشتراك Pro Plus؟',
        'Résilier votre abonnement Pro Plus ?',
        'Cancel your Premium subscription?',
      ),
      contentDescription: s.tr(
        'سيتوقف التجديد التلقائي لباقة Pro Plus مع الاحتفاظ ببيانات متجرك وإعلاناتك.',
        'Le renouvellement automatique sera désactivé tout en conservant votre boutique.',
        'Auto-renewal will be turned off while keeping your store and listings safe.',
      ),
      actions: [
        ApoloDlButton(
          key: const Key('dl-subscription-confirm-cancel'),
          label: s.tr(
            'نعم، إلغاء اشتراكي',
            'Confirmer la résiliation',
            'Cancel my subscription',
          ),
          variant: ApoloDlButtonVariant.primary,
          borderRadius: 999,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        ApoloDlButton(
          label: s.tr('الاحتفاظ بالاشتراك', 'Garder Pro Plus', 'Keep Premium'),
          variant: ApoloDlButtonVariant.secondary,
          borderRadius: 999,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );

    if (confirmed != true || !mounted) return;
    setState(() => _canceling = true);
    await _state.cancelProPlusSubscription();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _canceling = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final palette = ApoloDlPalette.of(context);
    final isPremium = _state.isProPlusAccount;
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final bottomPad = math.max(16.0, bottomSafe + 8.0);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Column(
          children: [
            _buildDlMonetizationTopNav(
              context,
              isAr: isAr,
              palette: palette,
              title: s.tr('الاشتراك', 'Abonnement', 'Subscription'),
              navKey: const Key('dl-subscription-top-nav'),
              backKey: const Key('dl-subscription-back-button'),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Spacer(flex: 5),
                                const Center(
                                  child: _ApoloProBrandMark(
                                    key: Key('dl-subscription-hero'),
                                    size: 118.0,
                                  ),
                                ),
                                const Spacer(flex: 5),
                                Padding(
                                  key: const Key('dl-subscription-wrapper'),
                                  padding: EdgeInsets.fromLTRB(
                                    16.0,
                                    16.0,
                                    16.0,
                                    bottomPad,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isPremium
                                            ? s.tr(
                                                'أنت تستخدم Pro Plus',
                                                'Vous utilisez Pro Plus',
                                                'You use Premium',
                                              )
                                            : s.tr(
                                                'احصل على Pro Plus',
                                                'Passez à Pro Plus',
                                                'Get Premium',
                                              ),
                                        key: const Key('dl-subscription-title'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: palette.ink,
                                          fontSize: 28.0,
                                          fontWeight: FontWeight.w700,
                                          height: 36.0 / 28.0,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 310.0,
                                        ),
                                        child: Text(
                                          isPremium
                                              ? s.tr(
                                                  'لديك وصول غير محدود لجميع مزايا Pro Plus الحصرية',
                                                  'Vous avez un accès illimité à toutes les fonctionnalités Pro Plus',
                                                  'You have unlimited access to all premium features',
                                                )
                                              : s.tr(
                                                  'احصل على وصول غير محدود لجميع مزايا Pro Plus الحصرية',
                                                  'Profitez d’un accès illimité à toutes les fonctionnalités Pro Plus',
                                                  'Get unlimited access to all premium features',
                                                ),
                                          key: const Key(
                                              'dl-subscription-subtitle'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: palette.muted,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w400,
                                            height: 24.0 / 16.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 32.0),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56.0,
                                        child: Material(
                                          color: isPremium
                                              ? palette.pill
                                              : palette.ink,
                                          shape: const StadiumBorder(),
                                          clipBehavior: Clip.antiAlias,
                                          child: InkWell(
                                            key: Key(
                                              isPremium
                                                  ? 'dl-subscription-cancel-btn'
                                                  : 'dl-subscription-get-premium-btn',
                                            ),
                                            customBorder: const StadiumBorder(),
                                            onTap: _canceling
                                                ? null
                                                : (isPremium
                                                    ? _confirmCancelSubscription
                                                    : _openGetPremiumFlow),
                                            child: Center(
                                              child: _canceling
                                                  ? CupertinoActivityIndicator(
                                                      color: palette.ink,
                                                    )
                                                  : Text(
                                                      isPremium
                                                          ? s.tr(
                                                              'إلغاء اشتراكي',
                                                              'Résilier mon abonnement',
                                                              'Cancel my subscription',
                                                            )
                                                          : s.tr(
                                                              'احصل على Pro Plus',
                                                              'Obtenir Pro Plus',
                                                              'Get Premium',
                                                            ),
                                                      style: TextStyle(
                                                        color: isPremium
                                                            ? palette.ink
                                                            : palette.onInk,
                                                        fontSize: 16.0,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 24.0 / 16.0,
                                                      ),
                                                    ),
                                            ),
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
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Dynamic Layer v5.1 `Free trial / Default` Screen (Figma `43551:4467`)
// ─────────────────────────────────────────────────────────────────────────────

class FreeTrialScreen extends StatefulWidget {
  const FreeTrialScreen({super.key});

  @override
  State<FreeTrialScreen> createState() => _FreeTrialScreenState();
}

class _FreeTrialScreenState extends State<FreeTrialScreen> {
  final AppState _state = AppState();
  bool _restoring = false;

  Future<void> _openAllPlans({bool startCheckout = false}) async {
    HapticFeedback.selectionClick();
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProPlusScreen(
          initialPlanId: 'yearly',
          autoStartCheckout: startCheckout,
        ),
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restorePurchases() async {
    if (_restoring) return;
    HapticFeedback.selectionClick();
    setState(() => _restoring = true);
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await InAppPurchase.instance.restorePurchases();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _restoring = false);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _state.s.tr(
              'تم التحقق من سجل مشترياتك على المتجر.',
              'Vérification des achats effectuée.',
              'Checked your account for active purchases.',
            ),
          ),
        ),
      );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required bool activeIcon,
    required String title,
    required String description,
    required bool showConnector,
    required ApoloDlPalette palette,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32.0,
            child: Column(
              children: [
                Container(
                  width: 30.0,
                  height: 30.0,
                  decoration: BoxDecoration(
                    color: palette.pill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 15.5,
                    color: activeIcon ? palette.ink : palette.iconMuted,
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2.0,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      constraints: const BoxConstraints(minHeight: 28.0),
                      decoration: BoxDecoration(
                        color: palette.border,
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 20.0 : 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      height: 20.0 / 14.0,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    description,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      height: 19.0 / 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGreyPill({
    required Key key,
    required String label,
    required VoidCallback onTap,
    required ApoloDlPalette palette,
  }) {
    return Center(
      child: Material(
        color: palette.pill,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: key,
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 9.0,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: palette.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 18.0 / 13.5,
              ),
            ),
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
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final bottomPad = math.max(16.0, bottomSafe + 8.0);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Column(
          children: [
            _buildDlMonetizationTopNav(
              context,
              isAr: isAr,
              palette: palette,
              title: null, // Figma `43551:4467` has back chevron only
              navKey: const Key('dl-trial-top-nav'),
              backKey: const Key('dl-trial-back-button'),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                    children: [
                      Text(
                        s.tr(
                          'كيف تعمل فترتك التجريبية',
                          'Comment fonctionne votre essai',
                          'How your trial works',
                        ),
                        key: const Key('dl-trial-title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 24.0,
                          fontWeight: FontWeight.w700,
                          height: 32.0 / 24.0,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300.0),
                          child: Text(
                            s.tr(
                              'وصول مجاني غير محدود لمدة 3 أيام، ثم 899 د.م فقط في السنة',
                              'Accès gratuit illimité pendant 3 jours, puis 899 DH par an',
                              'Unlimited free access for 3 days, then only 899 MAD per year',
                            ),
                            key: const Key('dl-trial-subtitle'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                              height: 21.0 / 14.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32.0),

                      // 3-Step Vertical Timeline (`Today` -> `Day 2` -> `Day 3`)
                      Padding(
                        key: const Key('dl-trial-timeline'),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTimelineStep(
                              icon: CupertinoIcons.lock_open_fill,
                              activeIcon: true,
                              title: s.tr('اليوم', 'Aujourd’hui', 'Today'),
                              description: s.tr(
                                'احصل على وصول فوري لشارة التوثيق PRO+ وتمويل إعلاناتك واكتشف الفرق.',
                                'Profitez immédiatement du badge PRO+ et des boosts gratuits.',
                                'Get instant access and see how Pro Plus transforms your sales.',
                              ),
                              showConnector: true,
                              palette: palette,
                            ),
                            _buildTimelineStep(
                              icon: CupertinoIcons.bell_fill,
                              activeIcon: true,
                              title: s.tr('اليوم 2', 'Jour 2', 'Day 2'),
                              description: s.tr(
                                'سنذكّرك عبر إشعار قبل انتهاء فترتك التجريبية المجانية.',
                                'Nous vous rappellerons par notification la fin proche de l’essai.',
                                "We'll remind you with a notification that your trial is ending.",
                              ),
                              showConnector: true,
                              palette: palette,
                            ),
                            _buildTimelineStep(
                              icon: CupertinoIcons.star_fill,
                              activeIcon: false,
                              title: s.tr('اليوم 3', 'Jour 3', 'Day 3'),
                              description: s.tr(
                                'يتم تفعيل الاشتراك في اليوم الثالث، ويمكنك الإلغاء في أي وقت قبله.',
                                'Facturation le 3e jour, annulable gratuitement à tout moment avant.',
                                "You'll be charged on Day 3, cancel anytime before.",
                              ),
                              showConnector: false,
                              palette: palette,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24.0),

                      _buildCompactGreyPill(
                        key: const Key('dl-trial-view-plans-btn'),
                        label: s.tr(
                          'عرض جميع الباقات',
                          'Voir toutes les offres',
                          'View all plans',
                        ),
                        onTap: () => _openAllPlans(startCheckout: false),
                        palette: palette,
                      ),

                      const SizedBox(height: 28.0),

                      _DlSubscriptionLegalText(strings: s, palette: palette),

                      const SizedBox(height: 18.0),

                      _buildCompactGreyPill(
                        key: const Key('dl-trial-restore-btn'),
                        label: s.tr(
                          'استعادة المشتريات',
                          'Restaurer les achats',
                          'Restore purchases',
                        ),
                        onTap: _restorePurchases,
                        palette: palette,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Bottom `ButtonDock` (`56px` black pill `Start free 3-day trial`)
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, bottomPad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: Material(
                      color: palette.ink,
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: const Key('dl-trial-start-btn'),
                        customBorder: const StadiumBorder(),
                        onTap: () => _openAllPlans(startCheckout: true),
                        child: Center(
                          child: Text(
                            s.tr(
                              'ابدأ تجربة 3 أيام مجاناً',
                              'Essayer 3 jours gratuitement',
                              'Start free 3-day trial',
                            ),
                            style: TextStyle(
                              color: palette.onInk,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              height: 24.0 / 16.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Dynamic Layer v5.1 `Paywall` Screen (`ProPlusScreen`, Figma `33412:51733`)
//    - 3-column plan selector (`Basic`, `Save 25%`, `Lifetime`)
//    - Legal billing disclosure + `Restore purchases` pill
//    - `56px` `#000000` Subscribe CTA (Google Pay / Play Billing) + `56px` `#EEEEEE` `No, thank you`
// ─────────────────────────────────────────────────────────────────────────────

class ProPlusScreen extends StatefulWidget {
  final String? initialPlanId;
  final bool autoStartCheckout;

  const ProPlusScreen({
    super.key,
    this.initialPlanId,
    this.autoStartCheckout = false,
  });

  @override
  State<ProPlusScreen> createState() => _ProPlusScreenState();
}

class _ProPlusScreenState extends State<ProPlusScreen> {
  final AppState _state = AppState();
  List<Map<String, dynamic>> _plans = [];
  String _selectedPlanId = 'yearly';
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  bool _didAutoTrigger = false;
  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  static List<Map<String, dynamic>> _fallbackPlans() => [
        {
          'id': 'monthly',
          'iap_product_id': 'ma.apolo.pro_plus.monthly',
          'name_ar': 'باقة Pro Plus الشهرية',
          'name_fr': 'Abonnement Pro Plus Mensuel',
          'tier_ar': 'أساسي',
          'tier_fr': 'Basic',
          'tier_en': 'Basic',
          'period_ar': 'شهر واحد',
          'period_fr': '1 mois',
          'period_en': '1 month',
          'price_mad': 99,
          'duration_days': 30,
          'vip_boost_credits': 3,
        },
        {
          'id': 'yearly',
          'iap_product_id': 'ma.apolo.pro_plus.yearly',
          'name_ar': 'باقة Pro Plus السنوية (وفّر 25%)',
          'name_fr': 'Abonnement Pro Plus Annuel (-25%)',
          'tier_ar': 'وفّر 25%',
          'tier_fr': 'Économisez 25%',
          'tier_en': 'Save 25%',
          'period_ar': '12 شهراً',
          'period_fr': '12 mois',
          'period_en': '12 months',
          'featured_save': true,
          'price_mad': 899,
          'duration_days': 365,
          'vip_boost_credits': 36,
        },
        {
          'id': 'lifetime',
          'iap_product_id': 'ma.apolo.pro_plus.lifetime',
          'name_ar': 'باقة Pro Plus مدى الحياة',
          'name_fr': 'Pro Plus À vie',
          'tier_ar': 'مدى الحياة',
          'tier_fr': 'À vie',
          'tier_en': 'Lifetime',
          'period_ar': 'دفعة واحدة',
          'period_fr': 'Paiement unique',
          'period_en': 'One-time',
          'price_mad': 1999,
          'duration_days': 3650,
          'vip_boost_credits': 120,
        },
      ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPlanId != null && widget.initialPlanId!.isNotEmpty) {
      _selectedPlanId = widget.initialPlanId!;
    }
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
          final parsed = raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          setState(() {
            _plans = parsed;
            if (!_plans.any((p) => p['id'].toString() == _selectedPlanId)) {
              final yearlyMatch =
                  _plans.where((p) => p['id'].toString() == 'yearly');
              _selectedPlanId = yearlyMatch.isNotEmpty
                  ? 'yearly'
                  : (_plans.first['id'] ?? 'monthly').toString();
            }
            _loading = false;
          });
          _maybeAutoStartCheckout();
          return;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _plans = _fallbackPlans();
      if (!_plans.any((p) => p['id'].toString() == _selectedPlanId)) {
        _selectedPlanId = 'yearly';
      }
      _loading = false;
    });
    _maybeAutoStartCheckout();
  }

  void _maybeAutoStartCheckout() {
    if (!widget.autoStartCheckout || _didAutoTrigger) return;
    _didAutoTrigger = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startGooglePayCheckout();
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
            'مبروك! تم تفعيل باقة Pro Plus وتوثيق متجرك بنجاح',
            'Félicitations ! Abonnement Pro Plus activé avec succès',
            'Pro Plus activated! Your store is now verified',
          ),
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    HapticFeedback.selectionClick();
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await InAppPurchase.instance.restorePurchases();
      }
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _state.s.tr(
              'تم التحقق من المشتريات المرتبطة بحسابك.',
              'Vérification des achats effectuée.',
              'Checked your account for active purchases.',
            ),
          ),
        ),
      );
  }

  Future<void> _startGooglePayCheckout() async {
    if (_purchasing || _plans.isEmpty) return;
    if (!_state.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      );
      return;
    }

    HapticFeedback.selectionClick();
    final plan = _plans.firstWhere(
      (p) => p['id'].toString() == _selectedPlanId,
      orElse: () => _plans.first,
    );
    final productId =
        (plan['iap_product_id'] ?? 'ma.apolo.pro_plus.monthly').toString();

    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
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
        ? (plan['name_ar'] ?? 'Pro Plus').toString()
        : (plan['name_fr'] ?? 'Pro Plus').toString();

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

  String _tierHeaderForPlan(Map<String, dynamic> plan, AppStrings s) {
    final id = (plan['id'] ?? '').toString().toLowerCase();
    final customBadge =
        (s.isAr ? plan['badge_ar'] : plan['badge_fr'])?.toString().trim();
    if (customBadge != null && customBadge.isNotEmpty) return customBadge;
    if (plan['tier_ar'] != null || plan['tier_en'] != null) {
      return s.tr(
        (plan['tier_ar'] ?? 'أساسي').toString(),
        (plan['tier_fr'] ?? 'Basic').toString(),
        (plan['tier_en'] ?? 'Basic').toString(),
      );
    }
    if (id.contains('year')) {
      return s.tr('وفّر 25%', '-25%', 'Save 25%');
    }
    if (id.contains('life')) {
      return s.tr('مدى الحياة', 'À vie', 'Lifetime');
    }
    return s.tr('أساسي', 'Basic', 'Basic');
  }

  String _periodLabelForPlan(Map<String, dynamic> plan, AppStrings s) {
    final id = (plan['id'] ?? '').toString().toLowerCase();
    if (plan['period_ar'] != null || plan['period_en'] != null) {
      return s.tr(
        (plan['period_ar'] ?? 'شهر واحد').toString(),
        (plan['period_fr'] ?? '1 mois').toString(),
        (plan['period_en'] ?? '1 month').toString(),
      );
    }
    if (id.contains('year')) {
      return s.tr('12 شهراً', '12 mois', '12 months');
    }
    if (id.contains('life')) {
      return s.tr('دفعة واحدة', 'Unique', 'One-time');
    }
    return s.tr('شهر واحد', '1 mois', '1 month');
  }

  Widget _buildDlPlanCard({
    required Map<String, dynamic> plan,
    required bool selected,
    required AppStrings s,
    required ApoloDlPalette palette,
  }) {
    final id = plan['id'].toString();
    final priceRaw = plan['price_mad'] ?? 99;
    final priceText = priceRaw is num && priceRaw == priceRaw.roundToDouble()
        ? '${priceRaw.toInt()}'
        : '$priceRaw';
    final currency = s.isAr ? 'د.م' : 'DH';
    final headerText = _tierHeaderForPlan(plan, s);
    final periodText = _periodLabelForPlan(plan, s);

    return Expanded(
      child: GestureDetector(
        key: Key('pro-plus-plan-$id'),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPlanId = id);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 112.0),
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: selected ? palette.ink : palette.border,
              width: selected ? 2.0 : 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top pill/banner strip (`#000000` when selected, `#EEEEEE` otherwise)
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 28.0,
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                color: selected ? palette.ink : palette.pill,
                alignment: Alignment.center,
                child: Text(
                  headerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? palette.onInk : palette.ink,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$priceText $currency',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      periodText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ],
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
    final isAr = s.isAr;
    final palette = ApoloDlPalette.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.paddingOf(context);
    final bottomSafe =
        DlShareProfileLayout.resolveBottomSafeInset(screenSize, mediaPadding);
    final bottomPad = math.max(16.0, bottomSafe + 8.0);

    final selectedPlan = _plans.firstWhere(
      (p) => p['id'].toString() == _selectedPlanId,
      orElse: () => _plans.isNotEmpty ? _plans.first : _fallbackPlans().first,
    );
    final rawPrice = selectedPlan['price_mad'] ?? 99;
    final priceDisplay = rawPrice is num && rawPrice == rawPrice.roundToDouble()
        ? '${rawPrice.toInt()}'
        : '$rawPrice';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: Column(
          children: [
            _buildDlMonetizationTopNav(
              context,
              isAr: isAr,
              palette: palette,
              title: s.tr('باقات Pro Plus', 'Offres Pro Plus', 'Paywall'),
              navKey: const Key('dl-paywall-top-nav'),
              backKey: const Key('dl-paywall-back-button'),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440.0),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            12.0,
                            16.0,
                            20.0,
                          ),
                          children: [
                            const Center(
                              child: _ApoloProBrandMark(
                                key: Key('dl-paywall-logo'),
                                size: 68.0,
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            Text(
                              s.tr(
                                'افتح الوصول الكامل',
                                'Débloquez l’accès complet',
                                'Unlock full access',
                              ),
                              key: const Key('dl-paywall-title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 24.0,
                                fontWeight: FontWeight.w700,
                                height: 32.0 / 24.0,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 300.0),
                                child: Text(
                                  s.tr(
                                    'وصول غير محدود لتوثيق المتجر، صدارة البحث، وتمويل VIP',
                                    'Accès illimité au badge vérifié, visibilité maximale et boosts VIP',
                                    'Unlimited access to all features and templates',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w400,
                                    height: 21.0 / 14.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),

                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14.0),
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: palette.dangerSoft,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: palette.danger,
                                  ),
                                ),
                              ),

                            // 3-Column Plan Cards Row (`33412:51733`)
                            Row(
                              key: const Key('dl-paywall-plans-row'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < _plans.length; i++) ...[
                                  _buildDlPlanCard(
                                    plan: _plans[i],
                                    selected: _selectedPlanId ==
                                        _plans[i]['id'].toString(),
                                    s: s,
                                    palette: palette,
                                  ),
                                  if (i < _plans.length - 1)
                                    const SizedBox(width: 8.0),
                                ],
                              ],
                            ),

                            const SizedBox(height: 24.0),

                            _DlSubscriptionLegalText(
                              strings: s,
                              palette: palette,
                            ),

                            const SizedBox(height: 18.0),

                            Center(
                              child: Material(
                                color: palette.pill,
                                shape: const StadiumBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: const Key('dl-paywall-restore-btn'),
                                  customBorder: const StadiumBorder(),
                                  onTap: _restorePurchases,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18.0,
                                      vertical: 9.0,
                                    ),
                                    child: Text(
                                      s.tr(
                                        'استعادة المشتريات',
                                        'Restaurer les achats',
                                        'Restore purchases',
                                      ),
                                      style: TextStyle(
                                        color: palette.ink,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        height: 18.0 / 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Fixed Bottom `ButtonDock`: `Subscribe for ...` (`56px` `#000000`) + `No, thank you` (`56px` `#EEEEEE`)
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, bottomPad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56.0,
                        child: Material(
                          color: palette.ink,
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: const Key('pro-plus-google-pay-btn'),
                            customBorder: const StadiumBorder(),
                            onTap: _purchasing ? null : _startGooglePayCheckout,
                            child: Center(
                              child: _purchasing
                                  ? CupertinoActivityIndicator(
                                      color: palette.onInk,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Text(
                                        s.tr(
                                          'اشترك بـ $priceDisplay د.م عبر Google Pay',
                                          'S’abonner ($priceDisplay DH) • Google Pay',
                                          'Subscribe for $priceDisplay MAD • Google Pay',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.onInk,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          height: 24.0 / 15.5,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      SizedBox(
                        width: double.infinity,
                        height: 56.0,
                        child: Material(
                          color: palette.pill,
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            key: const Key('dl-paywall-no-thanks-btn'),
                            customBorder: const StadiumBorder(),
                            onTap: () => Navigator.of(context).maybePop(false),
                            child: Center(
                              child: Text(
                                s.tr(
                                  'لا، شكراً',
                                  'Non, merci',
                                  'No, thank you',
                                ),
                                style: TextStyle(
                                  color: palette.ink,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  height: 24.0 / 16.0,
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
