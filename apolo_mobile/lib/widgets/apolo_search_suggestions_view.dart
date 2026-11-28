import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../screens/ad_detail_screen.dart';
import '../screens/seller_profile_screen.dart';
import '../screens/store_detail_screen.dart';
import '../screens/widgets/app_image.dart';
import '../screens/widgets/price_text.dart';
import 'apolo_badges_kit.dart';
import 'dl_settings_kit.dart';
import '../l10n/l10n.dart';

/// Model for a suggested account or verified store card in Dynamic Layer Search (`33215:34358`).
class ApoloSuggestedAccount {
  final int id;
  final String name;
  final String handle;
  final String? avatarUrl;
  final bool isVerified;
  final String? storeSubdomain;

  const ApoloSuggestedAccount({
    required this.id,
    required this.name,
    required this.handle,
    this.avatarUrl,
    this.isVerified = false,
    this.storeSubdomain,
  });

  static const List<ApoloSuggestedAccount> curatedFallbacks =
      <ApoloSuggestedAccount>[
    ApoloSuggestedAccount(
      id: 801,
      name: 'Julia Bentz',
      handle: 'julia.be',
      isVerified: false,
    ),
    ApoloSuggestedAccount(
      id: 802,
      name: 'Joshua Krane',
      handle: 'uxwithjoshua',
      isVerified: false,
    ),
    ApoloSuggestedAccount(
      id: 803,
      name: 'Youssef Alami',
      handle: 'youssef.alami',
      isVerified: false,
    ),
    ApoloSuggestedAccount(
      id: 804,
      name: 'Salma Chraibi',
      handle: 'salma.ch',
      isVerified: false,
    ),
    ApoloSuggestedAccount(
      id: 805,
      name: 'Karim Fassi',
      handle: 'karim.fassi',
      isVerified: false,
    ),
  ];

  static String _sanitizeHandle(String raw, String fallbackName, int id) {
    final cleaned = raw
        .trim()
        .replaceFirst(RegExp(r'^@+'), '')
        .replaceAll(RegExp(r'\s+'), '.')
        .toLowerCase();
    if (cleaned.isNotEmpty) return cleaned;
    final fromName = fallbackName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (fromName.isNotEmpty) return fromName;
    return 'seller.$id';
  }

  static List<ApoloSuggestedAccount> extractFromSources({
    required List<dynamic> stores,
    required List<dynamic> ads,
    int? excludeUserId,
  }) {
    final result = <ApoloSuggestedAccount>[];
    final seenIds = <int>{};
    final seenHandles = <String>{};

    void tryAdd(ApoloSuggestedAccount item) {
      if (item.id <= 0) return;
      if (excludeUserId != null && item.id == excludeUserId) return;
      final normHandle = item.handle.toLowerCase();
      if (seenIds.contains(item.id) || seenHandles.contains(normHandle)) return;
      seenIds.add(item.id);
      seenHandles.add(normHandle);
      result.add(item);
    }

    for (final raw in stores) {
      if (raw is! Map) continue;
      final id = int.tryParse(
            '${raw['user_id'] ?? raw['owner_id'] ?? raw['id'] ?? 0}',
          ) ??
          0;
      final name = (raw['name'] ?? '').toString().trim();
      if (id <= 0 || name.isEmpty) continue;
      final subdomain = (raw['subdomain'] ?? '').toString().trim();
      final avatar = (raw['logo_url'] ?? raw['logo'] ?? '').toString().trim();
      final verified =
          AppConfig.enablePremiumAndBusinessTiers && raw['is_pro_plus'] == true;
      tryAdd(
        ApoloSuggestedAccount(
          id: id,
          name: name,
          handle: _sanitizeHandle(subdomain, name, id),
          avatarUrl: avatar.isNotEmpty ? avatar : null,
          isVerified: verified,
          storeSubdomain: verified && subdomain.isNotEmpty ? subdomain : null,
        ),
      );
    }

    for (final raw in ads) {
      if (raw is! Map) continue;
      final userMap = raw['user'] is Map
          ? Map<String, dynamic>.from(raw['user'] as Map)
          : null;
      final id = int.tryParse(
            '${raw['user_id'] ?? raw['seller_id'] ?? userMap?['id'] ?? 0}',
          ) ??
          0;
      final name = (raw['seller_name'] ??
              userMap?['name'] ??
              raw['store_name'] ??
              '')
          .toString()
          .trim();
      if (id <= 0 || name.isEmpty) continue;
      final rawHandle = (raw['seller_username'] ??
              userMap?['username'] ??
              raw['store_subdomain'] ??
              '')
          .toString();
      final avatar = (raw['seller_avatar'] ??
              userMap?['avatar_url'] ??
              userMap?['avatar'] ??
              '')
          .toString()
          .trim();
      final verified = AppConfig.enablePremiumAndBusinessTiers &&
          (raw['is_pro_plus'] == true ||
              raw['seller_is_pro_plus'] == true ||
              userMap?['is_pro_plus'] == true);
      tryAdd(
        ApoloSuggestedAccount(
          id: id,
          name: name,
          handle: _sanitizeHandle(rawHandle, name, id),
          avatarUrl: avatar.isNotEmpty ? avatar : null,
          isVerified: verified,
        ),
      );
    }

    for (final fallback in curatedFallbacks) {
      if (result.length >= 8) break;
      tryAdd(fallback);
    }

    return result;
  }
}

/// Dynamic Layer v5.1 Search Suggestions View (`33215:34358`) with full Light & Dark Mode
/// and Recent Searches history:
/// - `56px` top bar (`40×40` `#EEEEEE` / `#222226` `<` back button + centered `Search` title)
/// - `48px` `#EEEEEE` / `#222226` pill search input (`Search for usernames`)
/// - `Suggestions` horizontal carousel of `148×196` rounded `20px` account cards
///   with `64×64` avatar/monogram, Name + `ApoloVerifiedBadge`, `@handle`, and
///   live `Follow` (`#2997FF`) / `Followed` (`#EEEEEE` / `#222226`) button
/// - Recent Searches (with 1-tap remove & Clear all) + Popular searches + Live Listing matches.
class ApoloSearchSuggestionsView extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<ApoloSuggestedAccount> accounts;
  final List<Map<String, dynamic>> matchingAds;
  final List<String> recentSearches;
  final ValueChanged<String>? onRemoveRecentSearch;
  final VoidCallback? onClearRecentSearches;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitQuery;

  const ApoloSearchSuggestionsView({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.accounts,
    required this.matchingAds,
    this.recentSearches = const <String>[],
    this.onRemoveRecentSearch,
    this.onClearRecentSearches,
    required this.onBack,
    required this.onChanged,
    required this.onSubmitQuery,
  });

  static const Color _followBlue = Color(0xFF2997FF);

  static List<String> _popularQueries(AppStrings s) {
    if (s.isAr) {
      return const <String>[
        'iPhone 16 Pro Max',
        'شقق الدار البيضاء',
        'Mercedes-Benz',
        'MacBook Pro',
        'فيلا مراكش',
      ];
    }
    if (s.isFr) {
      return const <String>[
        'iPhone 16 Pro Max',
        'Appartement Casablanca',
        'Mercedes-Benz',
        'MacBook Pro',
        'Villa Marrakech',
      ];
    }
    return const <String>[
      'iPhone 16 Pro Max',
      'Casablanca Apartment',
      'Mercedes-Benz',
      'MacBook Pro',
      'Villa Marrakech',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final s = state.s;
    final palette = ApoloDlPalette.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final rawQuery = controller.text.trim();
    final normQuery = rawQuery.toLowerCase().replaceFirst(RegExp(r'^@+'), '');

    final visibleAccounts = normQuery.isEmpty
        ? accounts
        : accounts.where((acc) {
            return acc.name.toLowerCase().contains(normQuery) ||
                acc.handle.toLowerCase().contains(normQuery);
          }).toList();
    final effectiveAccounts = visibleAccounts.isNotEmpty
        ? visibleAccounts
        : accounts.take(4).toList();

    return ColoredBox(
      key: const Key('dl-search-suggestions-screen'),
      color: palette.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dynamic Layer v5.1 Top Nav (`56px`, `40×40` `<` button + centered `Search`)
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: s.tr('رجوع', 'Retour', appL10n.backButton),
                    child: Material(
                      key: const Key('dl-search-back-button'),
                      color: palette.pill,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onBack();
                        },
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: Icon(
                              isRtl
                                  ? CupertinoIcons.chevron_forward
                                  : CupertinoIcons.chevron_back,
                              size: 19,
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.tr('بحث', 'Rechercher', appL10n.searchTitle),
                      key: const Key('dl-search-header-title'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40, height: 40),
                ],
              ),
            ),
          ),

          // 2. Pill Search Bar (`48px` height, `#EEEEEE` / `#222226` fill)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: palette.pill,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 20,
                    color: palette.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const Key('dl-search-input-field'),
                      controller: controller,
                      focusNode: focusNode,
                      cursorColor: palette.ink,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      onSubmitted: onSubmitQuery,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: palette.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: s.tr(
                          'ابحث عن أسماء الحسابات أو الإعلانات',
                          'Rechercher des pseudos ou annonces',
                          appL10n.searchSuggestionsSearchUsernames,
                        ),
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: palette.subtle,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (rawQuery.isNotEmpty)
                    GestureDetector(
                      key: const Key('dl-search-clear-button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.clear();
                        onChanged('');
                      },
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                          child: Icon(
                            CupertinoIcons.clear_circled_solid,
                            size: 18,
                            color: palette.subtle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. Scrollable Suggestions Body
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (effectiveAccounts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Text(
                      s.tr('اقتراحات', 'Suggestions', appL10n.searchSuggestionsSuggestions),
                      key: const Key('dl-search-suggestions-label'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: palette.muted,
                      ),
                    ),
                  ),
                  SizedBox(
                    key: const Key('dl-search-suggestions-carousel'),
                    height: 196,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: effectiveAccounts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final acc = effectiveAccounts[index];
                        final isFollowed = state.isFollowingSeller(acc.id);
                        return _SuggestedAccountCard(
                          account: acc,
                          isFollowed: isFollowed,
                          s: s,
                          palette: palette,
                          onToggleFollow: () {
                            HapticFeedback.selectionClick();
                            state.toggleFollowSeller(acc.id);
                          },
                          onOpenProfile: () {
                            HapticFeedback.lightImpact();
                            FocusScope.of(context).unfocus();
                            if (acc.storeSubdomain != null &&
                                acc.storeSubdomain!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => StoreDetailScreen(
                                    subdomain: acc.storeSubdomain!,
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => SellerProfileScreen(
                                    sellerId: acc.id,
                                    sellerName: acc.name,
                                    sellerHandle: acc.handle,
                                    sellerAvatar: acc.avatarUrl,
                                    isVerified: acc.isVerified,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],

                // 4. Recent Searches + Popular Searches (when input empty) OR Live Listing Matches
                if (rawQuery.isEmpty) ...[
                  if (recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.tr(
                                'عمليات البحث الأخيرة',
                                'Recherches récentes',
                                appL10n.searchSuggestionsRecentSearches,
                              ),
                              key: const Key('dl-recent-searches-label'),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: palette.muted,
                              ),
                            ),
                          ),
                          if (onClearRecentSearches != null)
                            GestureDetector(
                              key: const Key('dl-recent-clear-all'),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onClearRecentSearches!();
                              },
                              child: Text(
                                s.tr('مسح الكل', 'Effacer', appL10n.clearButton),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final item in recentSearches)
                      InkWell(
                        key: Key('dl-recent-query-$item'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          controller.text = item;
                          controller.selection = TextSelection.collapsed(
                            offset: item.length,
                          );
                          onSubmitQuery(item);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: palette.pill,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.clock,
                                  size: 16,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w500,
                                    color: palette.ink,
                                  ),
                                ),
                              ),
                              if (onRemoveRecentSearch != null)
                                GestureDetector(
                                  key: Key('dl-recent-remove-$item'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    onRemoveRecentSearch!(item);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      CupertinoIcons.xmark,
                                      size: 14,
                                      color: palette.subtle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                    child: Text(
                      s.tr(
                        'عمليات بحث مقترحة',
                        'Recherches populaires',
                        appL10n.searchSuggestionsPopularSearches,
                      ),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: palette.muted,
                      ),
                    ),
                  ),
                  for (final suggestion in _popularQueries(s))
                    InkWell(
                      key: Key('dl-popular-query-$suggestion'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.text = suggestion;
                        controller.selection = TextSelection.collapsed(
                          offset: suggestion.length,
                        );
                        onSubmitQuery(suggestion);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: palette.pill,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                CupertinoIcons.search,
                                size: 16,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                suggestion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                            Icon(
                              isRtl
                                  ? CupertinoIcons.arrow_up_left
                                  : CupertinoIcons.arrow_up_right,
                              size: 16,
                              color: palette.subtle,
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.tr('الإعلانات المطابقة', 'Annonces', appL10n.profileListings),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: palette.muted,
                            ),
                          ),
                        ),
                        GestureDetector(
                          key: const Key('dl-search-view-all-results'),
                          onTap: () => onSubmitQuery(rawQuery),
                          child: Text(
                            s.tr('عرض الكل', 'Tout voir', appL10n.homeSeeAll),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _followBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    key: const Key('dl-search-submit-query-row'),
                    onTap: () => onSubmitQuery(rawQuery),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: palette.pill,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              CupertinoIcons.search,
                              size: 17,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${s.tr('البحث عن', 'Rechercher', appL10n.searchTitle)} "$rawQuery"',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: palette.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  for (final ad in matchingAds.take(5))
                    _QuickAdSuggestionTile(ad: ad, palette: palette),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedAccountCard extends StatelessWidget {
  final ApoloSuggestedAccount account;
  final bool isFollowed;
  final AppStrings s;
  final ApoloDlPalette palette;
  final VoidCallback onToggleFollow;
  final VoidCallback onOpenProfile;

  const _SuggestedAccountCard({
    required this.account,
    required this.isFollowed,
    required this.s,
    required this.palette,
    required this.onToggleFollow,
    required this.onOpenProfile,
  });

  Widget _buildMonogram(String name) {
    final trimmed = name.trim();
    final letter = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'A';
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: palette.pill,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: palette.ink,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatar = account.avatarUrl?.trim() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      key: Key('dl-suggestion-card-${account.id}'),
      onTap: onOpenProfile,
      child: Container(
        width: 148,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: isDark ? palette.surfaceSubtle : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: palette.separator,
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            ClipOval(
              child: avatar.isNotEmpty
                  ? AppImage(
                      url: avatar,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      fallback: _buildMonogram(account.name),
                    )
                  : _buildMonogram(account.name),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (account.isVerified) ...[
                  const SizedBox(width: 4),
                  const ApoloVerifiedBadge(size: 15),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '@${account.handle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: palette.subtle,
              ),
            ),
            const Spacer(),
            Semantics(
              button: true,
              selected: isFollowed,
              label: isFollowed
                  ? 'Followed ${account.name}'
                  : 'Follow ${account.name}',
              child: Material(
                key: Key('dl-suggestion-follow-${account.id}'),
                color: isFollowed ? palette.pill : const Color(0xFF2997FF),
                borderRadius: BorderRadius.circular(999),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onToggleFollow,
                  child: SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: Center(
                      child: Text(
                        isFollowed
                            ? s.tr('متابَع', 'Suivi', appL10n.followedButton)
                            : s.tr('متابعة', 'Suivre', appL10n.followButton),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isFollowed ? palette.ink : Colors.white,
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

class _QuickAdSuggestionTile extends StatelessWidget {
  final Map<String, dynamic> ad;
  final ApoloDlPalette palette;

  const _QuickAdSuggestionTile({
    required this.ad,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse('${ad['id'] ?? 0}') ?? 0;
    final title = (ad['title'] ?? '').toString().trim();
    final priceFormatted = (ad['price_formatted'] ??
            ad['nightly_price_display'] ??
            (ad['price'] != null ? '${ad['price']} MAD' : ''))
        .toString()
        .trim();
    String imgUrl = '';
    if (ad['images'] is List && (ad['images'] as List).isNotEmpty) {
      final first = (ad['images'] as List).first;
      imgUrl = first is Map
          ? (first['url'] ?? first['image_path'] ?? '').toString()
          : first.toString();
    } else {
      imgUrl = (ad['main_image'] ?? ad['primary_image'] ?? ad['image'] ?? '')
          .toString();
    }

    return InkWell(
      onTap: id > 0
          ? () {
              FocusScope.of(context).unfocus();
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => AdDetailScreen(adId: id, initialAd: ad),
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: imgUrl.isNotEmpty
                    ? AppImage(url: imgUrl, fit: BoxFit.cover)
                    : Container(
                        color: palette.pill,
                        child: Icon(
                          CupertinoIcons.photo,
                          size: 18,
                          color: palette.subtle,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  if (priceFormatted.isNotEmpty)
                    PriceText(
                      priceFormatted,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
