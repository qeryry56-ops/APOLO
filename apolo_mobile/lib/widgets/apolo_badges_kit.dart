import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import 'dl_settings_kit.dart';

/// Official 6-tier seller trust & activity ranks powered by APOLO's Figma badge kit.
enum ApoloSellerRank {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  champion;

  /// Resolves the rank from an explicit backend field if present,
  /// otherwise computes it deterministically from real seller/store signals.
  static ApoloSellerRank resolve({
    Map<String, dynamic>? user,
    int listingsCount = 0,
    int totalViews = 0,
    bool? isProPlus,
    bool? isBusiness,
    bool? isVerified,
  }) {
    final explicitRaw = (user?['rank'] ??
            user?['seller_rank'] ??
            user?['tier'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    for (final value in ApoloSellerRank.values) {
      if (explicitRaw == value.name) {
        return value;
      }
    }

    final effectiveProPlus = isProPlus ??
        (user?['is_pro_plus'] == true || user?['pro_plus'] == true);
    final effectiveBusiness = isBusiness ??
        (user?['account_type']?.toString().toLowerCase() == 'business' ||
            user?['is_business'] == true);
    final effectiveVerified = isVerified ??
        (user?['is_verified'] == true ||
            user?['verified'] == true ||
            user?['phone_verified_at'] != null ||
            effectiveProPlus ||
            effectiveBusiness);

    if (effectiveProPlus && (listingsCount >= 20 || totalViews >= 5000)) {
      return ApoloSellerRank.champion;
    }
    if (effectiveProPlus && (listingsCount >= 10 || totalViews >= 1500)) {
      return ApoloSellerRank.diamond;
    }
    if (effectiveProPlus ||
        (effectiveBusiness && (listingsCount >= 8 || totalViews >= 800))) {
      return ApoloSellerRank.platinum;
    }
    if (effectiveBusiness || listingsCount >= 5 || totalViews >= 400) {
      return ApoloSellerRank.gold;
    }
    if (effectiveVerified || listingsCount >= 2 || totalViews >= 100) {
      return ApoloSellerRank.silver;
    }
    return ApoloSellerRank.bronze;
  }

  String assetPath(Brightness brightness) {
    final suffix = brightness == Brightness.dark ? 'dark' : 'light';
    return 'assets/badges/rank_${name}_$suffix.png';
  }

  String label(AppStrings s) {
    switch (this) {
      case ApoloSellerRank.bronze:
        return s.tr('عضو برونزي', 'Bronze', 'Bronze');
      case ApoloSellerRank.silver:
        return s.tr('بائع فضي', 'Argent', 'Silver');
      case ApoloSellerRank.gold:
        return s.tr('بائع ذهبي', 'Or', 'Gold');
      case ApoloSellerRank.platinum:
        return s.tr('بائع بلاتيني', 'Platine', 'Platinum');
      case ApoloSellerRank.diamond:
        return s.tr('بائع ماسي', 'Diamant', 'Diamond');
      case ApoloSellerRank.champion:
        return s.tr('بطل أبولو', 'Champion', 'Champion');
    }
  }

  String requirementHint(AppStrings s) {
    switch (this) {
      case ApoloSellerRank.bronze:
        return s.tr(
          'بداية الحساب على Apolo',
          'Nouveau membre sur Apolo',
          'Starter member on Apolo',
        );
      case ApoloSellerRank.silver:
        return s.tr(
          'توثيق الحساب أو إعلانان فأكثر',
          'Compte vérifié ou 2+ annonces',
          'Verified account or 2+ listings',
        );
      case ApoloSellerRank.gold:
        return s.tr(
          'متجر أعمال أو +5 إعلانات',
          'Boutique Pro ou 5+ annonces',
          'Business store or 5+ listings',
        );
      case ApoloSellerRank.platinum:
        return s.tr(
          'اشتراك Pro+ أو متجر نشيط (+8 إعلانات)',
          'Pro+ actif ou boutique active (8+)',
          'Active Pro+ or active store (8+)',
        );
      case ApoloSellerRank.diamond:
        return s.tr(
          'Pro+ مع +10 إعلانات أو +1500 مشاهدة',
          'Pro+ avec 10+ annonces ou 1500 vues',
          'Pro+ with 10+ listings or 1,500 views',
        );
      case ApoloSellerRank.champion:
        return s.tr(
          'أعلى رتبة: Pro+ مع +20 إعلاناً أو +5000 مشاهدة',
          'Rang ultime : Pro+ avec 20+ annonces ou 5000 vues',
          'Top tier: Pro+ with 20+ listings or 5,000 views',
        );
    }
  }

  ApoloSellerRank? get nextRank {
    final nextIndex = index + 1;
    if (nextIndex >= ApoloSellerRank.values.length) return null;
    return ApoloSellerRank.values[nextIndex];
  }

  Color get fallbackAccent {
    switch (this) {
      case ApoloSellerRank.bronze:
        return const Color(0xFFB77B3A);
      case ApoloSellerRank.silver:
        return const Color(0xFF8AA8B5);
      case ApoloSellerRank.gold:
        return const Color(0xFFF07E00);
      case ApoloSellerRank.platinum:
        return const Color(0xFF0078F0);
      case ApoloSellerRank.diamond:
        return const Color(0xFFFA28F3);
      case ApoloSellerRank.champion:
        return const Color(0xFFFF2B14);
    }
  }

  double progressToNext({
    required int listingsCount,
    required int totalViews,
    required bool isProPlus,
    required bool isBusiness,
    required bool isVerified,
  }) {
    switch (this) {
      case ApoloSellerRank.bronze:
        final score =
            (listingsCount / 2.0).clamp(0.0, 1.0) * 0.6 +
            (totalViews / 100.0).clamp(0.0, 1.0) * 0.4;
        return (isVerified ? 0.85 : score).clamp(0.15, 0.95);
      case ApoloSellerRank.silver:
        final score =
            (listingsCount / 5.0).clamp(0.0, 1.0) * 0.6 +
            (totalViews / 400.0).clamp(0.0, 1.0) * 0.4;
        return (isBusiness ? 0.9 : score).clamp(0.2, 0.95);
      case ApoloSellerRank.gold:
        final score =
            (listingsCount / 8.0).clamp(0.0, 1.0) * 0.6 +
            (totalViews / 800.0).clamp(0.0, 1.0) * 0.4;
        return (isProPlus ? 0.9 : score).clamp(0.25, 0.95);
      case ApoloSellerRank.platinum:
        final score =
            (listingsCount / 10.0).clamp(0.0, 1.0) * 0.6 +
            (totalViews / 1500.0).clamp(0.0, 1.0) * 0.4;
        return score.clamp(0.3, 0.95);
      case ApoloSellerRank.diamond:
        final score =
            (listingsCount / 20.0).clamp(0.0, 1.0) * 0.6 +
            (totalViews / 5000.0).clamp(0.0, 1.0) * 0.4;
        return score.clamp(0.35, 0.95);
      case ApoloSellerRank.champion:
        return 1.0;
    }
  }
}

/// Official blue verified seal rendered from Figma asset (`verified_blue.png`).
class ApoloVerifiedBadge extends StatelessWidget {
  const ApoloVerifiedBadge({
    super.key,
    this.size = 18.0,
    this.interactive = false,
    this.rank = ApoloSellerRank.silver,
    this.isProPlus = false,
    this.isBusiness = false,
    this.onTap,
  });

  final double size;
  final bool interactive;
  final ApoloSellerRank rank;
  final bool isProPlus;
  final bool isBusiness;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = SizedBox(
      key: const Key('apolo-verified-badge'),
      width: size,
      height: size,
      child: Image.asset(
        'assets/badges/verified_blue.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          CupertinoIcons.checkmark_seal_fill,
          size: size,
          color: const Color(0xFF3897F0),
        ),
      ),
    );

    if (!interactive && onTap == null) return badge;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ??
          () {
            HapticFeedback.selectionClick();
            showApoloTrustAndRankSheet(
              context,
              currentRank: rank,
              isVerified: true,
              isProPlus: isProPlus,
              isBusiness: isBusiness,
            );
          },
      child: badge,
    );
  }
}

/// Official Figma rank shield badge supporting Light/Dark assets + optional label pill.
class ApoloRankBadge extends StatelessWidget {
  const ApoloRankBadge({
    required this.rank,
    super.key,
    this.size = 20.0,
    this.showLabel = false,
    this.interactive = false,
    this.isVerified = false,
    this.isProPlus = false,
    this.isBusiness = false,
    this.onTap,
  });

  final ApoloSellerRank rank;
  final double size;
  final bool showLabel;
  final bool interactive;
  final bool isVerified;
  final bool isProPlus;
  final bool isBusiness;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = ApoloDlPalette.of(context);
    final s = AppState().s;

    final shield = SizedBox(
      key: Key('apolo-rank-badge-${rank.name}'),
      width: size,
      height: size * 1.05,
      child: Image.asset(
        rank.assetPath(brightness),
        width: size,
        height: size * 1.05,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.shield_rounded,
          size: size,
          color: rank.fallbackAccent,
        ),
      ),
    );

    final Widget content = showLabel
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: palette.pill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                shield,
                const SizedBox(width: 5),
                Text(
                  rank.label(s),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ],
            ),
          )
        : shield;

    if (!interactive && onTap == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ??
          () {
            HapticFeedback.selectionClick();
            showApoloTrustAndRankSheet(
              context,
              currentRank: rank,
              isVerified: isVerified,
              isProPlus: isProPlus,
              isBusiness: isBusiness,
            );
          },
      child: content,
    );
  }
}

/// Compact inline verified + rank + PRO+ identity row placed beside names & titles.
class ApoloIdentityBadgesRow extends StatelessWidget {
  const ApoloIdentityBadgesRow({
    required this.rank,
    super.key,
    this.isVerified = false,
    this.isProPlus = false,
    this.isBusiness = false,
    this.badgeSize = 18.0,
    this.showRankLabel = false,
    this.showProPill = false,
    this.interactive = true,
  });

  final bool isVerified;
  final ApoloSellerRank rank;
  final bool isProPlus;
  final bool isBusiness;
  final double badgeSize;
  final bool showRankLabel;
  final bool showProPill;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);

    void openSheet() {
      HapticFeedback.selectionClick();
      showApoloTrustAndRankSheet(
        context,
        currentRank: rank,
        isVerified: isVerified,
        isProPlus: isProPlus,
        isBusiness: isBusiness,
      );
    }

    final row = Row(
      key: const Key('apolo-identity-badges-row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVerified) ...[
          ApoloVerifiedBadge(
            size: badgeSize,
            rank: rank,
            isProPlus: isProPlus,
            isBusiness: isBusiness,
          ),
          const SizedBox(width: 5),
        ],
        ApoloRankBadge(
          rank: rank,
          size: badgeSize + 1,
          showLabel: showRankLabel,
          isVerified: isVerified,
          isProPlus: isProPlus,
          isBusiness: isBusiness,
        ),
        if (showProPill && isProPlus) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: palette.ink,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'PRO+',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.onInk,
              ),
            ),
          ),
        ],
      ],
    );

    if (!interactive) return row;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: openSheet,
      child: row,
    );
  }
}

/// Clean Dynamic Layer v5.1 card displaying current seller rank + progress to next tier.
class ApoloRankProgressCard extends StatelessWidget {
  const ApoloRankProgressCard({
    required this.rank,
    required this.listingsCount,
    required this.totalViews,
    required this.isVerified,
    required this.isProPlus,
    required this.isBusiness,
    super.key,
    this.onTap,
  });

  final ApoloSellerRank rank;
  final int listingsCount;
  final int totalViews;
  final bool isVerified;
  final bool isProPlus;
  final bool isBusiness;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ApoloDlPalette.of(context);
    final s = AppState().s;
    final next = rank.nextRank;
    final progress = rank.progressToNext(
      listingsCount: listingsCount,
      totalViews: totalViews,
      isProPlus: isProPlus,
      isBusiness: isBusiness,
      isVerified: isVerified,
    );

    return Material(
      color: palette.groupCard,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('apolo-rank-progress-card'),
        onTap: onTap ??
            () {
              HapticFeedback.selectionClick();
              showApoloTrustAndRankSheet(
                context,
                currentRank: rank,
                isVerified: isVerified,
                isProPlus: isProPlus,
                isBusiness: isBusiness,
              );
            },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: ApoloRankBadge(rank: rank, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${s.tr('المستوى:', 'Rang :', 'Seller rank:')} ${rank.label(s)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.8,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          ApoloVerifiedBadge(size: 15, rank: rank),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: palette.bg,
                        valueColor: AlwaysStoppedAnimation<Color>(palette.ink),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      next == null
                          ? s.tr(
                              'وصلت لأعلى رتبة على Apolo!',
                              'Vous avez atteint le rang maximal !',
                              'Top rank unlocked on Apolo!',
                            )
                          : '${s.tr('الرتبة التالية:', 'Prochain rang :', 'Next:')} ${next.label(s)} · ${next.requirementHint(s)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.8,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                s.isAr
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                size: 15,
                color: palette.iconMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive bottom sheet explaining verified status and all 6 seller rank tiers.
Future<void> showApoloTrustAndRankSheet(
  BuildContext context, {
  required ApoloSellerRank currentRank,
  required bool isVerified,
  bool isProPlus = false,
  bool isBusiness = false,
}) {
  final palette = ApoloDlPalette.of(context);
  final s = AppState().s;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Directionality(
      textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    ApoloRankBadge(rank: currentRank, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.tr(
                              'التوثيق ورتب البائعين',
                              'Vérification & Rangs',
                              'Trust & Seller Ranks',
                            ),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            '${s.tr('المستوى الحالي:', 'Niveau actuel :', 'Current rank:')} ${currentRank.label(s)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ApoloDlIconCircleButton(
                      icon: CupertinoIcons.xmark,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const ApoloDlSeparator(),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.groupCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ApoloVerifiedBadge(size: 26, rank: currentRank),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVerified
                                      ? s.tr(
                                          'حساب موثوق على Apolo',
                                          'Compte vérifié Apolo',
                                          'Verified Apolo Account',
                                        )
                                      : s.tr(
                                          'شارة التوثيق الزرقاء',
                                          'Badge de vérification',
                                          'Verified Seal',
                                        ),
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isVerified
                                      ? s.tr(
                                          'تم التحقق من بيانات الحساب ورقم الهاتف لتعزيز الثقة والأمان.',
                                          'Identité ou numéro vérifiés pour plus de sécurité.',
                                          'Identity and contact details verified for safer transactions.',
                                        )
                                      : s.tr(
                                          'تظهر الشارة بعد توثيق رقم الهاتف أو تفعيل متجر احترافي.',
                                          'Accordé après vérification du numéro ou boutique Pro.',
                                          'Earned by verifying your phone number or activating a Pro store.',
                                        ),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: palette.muted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.tr(
                        'جميع رتب البائعين',
                        'Tous les rangs vendeur',
                        'All Seller Ranks',
                      ),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.groupCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0;
                              i < ApoloSellerRank.values.length;
                              i++) ...[
                            if (i > 0)
                              const ApoloDlSeparator(indentStart: 62),
                            _RankSheetRow(
                              rank: ApoloSellerRank.values[i],
                              isCurrent:
                                  ApoloSellerRank.values[i] == currentRank,
                              s: s,
                              palette: palette,
                            ),
                          ],
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
  );
}

class _RankSheetRow extends StatelessWidget {
  const _RankSheetRow({
    required this.rank,
    required this.isCurrent,
    required this.s,
    required this.palette,
  });

  final ApoloSellerRank rank;
  final bool isCurrent;
  final AppStrings s;
  final ApoloDlPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: ApoloRankBadge(rank: rank, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank.label(s),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rank.requirementHint(s),
                  style: TextStyle(
                    fontSize: 12.2,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: palette.ink,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                s.tr('الحالي', 'Actuel', 'Current'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.onInk,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
