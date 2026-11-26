import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/dl_settings_kit.dart';
import 'add_friends_screen.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'privacy_compliance_screen.dart';
import 'pro_plus_screen.dart';
import 'settings/apolo_account_center_screen.dart';
import 'settings/settings_app_data_screen.dart';
import 'settings/settings_blocked_accounts_screen.dart';
import 'settings/settings_bug_report_screen.dart';
import 'settings/settings_language_screen.dart';
import 'settings/settings_saved_ads_screen.dart';
import 'settings/settings_share_app_screen.dart';
import 'settings/settings_suggestion_screen.dart';
import 'settings/settings_zone_screen.dart';
import 'support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onEditProfile,
    this.onOpenEditProfile,
  });

  final VoidCallback? onEditProfile;
  final VoidCallback? onOpenEditProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppState _state = AppState();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChange);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchFocusChange() {
    if (!mounted) return;
    setState(() => _searchFocused = _searchFocus.hasFocus);
  }

  void _onSearchChanged() {
    final next = _searchCtrl.text.trim();
    if (next == _query) return;
    setState(() => _query = next);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  String _languageDisplayLabel(String lang) {
    switch (lang) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  bool _matchesQuery(List<String> terms) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    for (final term in terms) {
      if (term.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  Future<void> _confirmLogout(AppStrings s) async {
    final palette = ApoloDlPalette.of(context);
    final confirmed = await showApoloDlBottomSheet<bool>(
      context,
      headerTitle: s.tr('تسجيل الخروج', 'Déconnexion', 'Log out'),
      media: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.square_arrow_right,
          color: palette.danger,
          size: 26,
        ),
      ),
      contentTitle: s.tr(
        'هل تريد تسجيل الخروج؟',
        'Se déconnecter de votre compte ?',
        'Log out of your account?',
      ),
      contentDescription: s.tr(
        'يمكنك إعادة تسجيل الدخول في أي وقت للوصول إلى إعلاناتك ومحادثاتك.',
        'Vous pourrez vous reconnecter à tout moment pour retrouver vos annonces.',
        'You can sign back in anytime to access your listings and messages.',
      ),
      actions: [
        ApoloDlButton(
          key: const Key('settings-confirm-logout'),
          label: s.tr('تسجيل الخروج', 'Se déconnecter', 'Log out'),
          variant: ApoloDlButtonVariant.danger,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 10),
        ApoloDlButton(
          label: s.tr('إلغاء', 'Annuler', 'Cancel'),
          variant: ApoloDlButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );

    if (confirmed != true || !mounted) return;
    await _state.logout();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;
        final palette = ApoloDlPalette.of(context);
        final isLoggedIn = _state.isLoggedIn;

        final showAccountCenter = _matchesQuery([
          'Apolo Account',
          'Your account',
          'Account',
          'Password',
          'Security',
          'Personal details',
          'Business',
          'Store',
          'مركز حساب أبولو',
          'حسابي',
          'Espace Compte Apolo',
          'Mot de passe',
        ]);

        final howYouUseItems = <Widget>[
          if (_matchesQuery([
            'Saved',
            'Favorites',
            'Bookmarks',
            'المحفوظات',
            'المفضلة',
            'Enregistrés',
            'Favoris',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-saved'),
              icon: CupertinoIcons.bookmark,
              title: s.tr('المحفوظات', 'Enregistrés', 'Saved'),
              trailingText: isLoggedIn && _state.favoriteAdIds.isNotEmpty
                  ? '${_state.favoriteAdIds.length}'
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsSavedAdsScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'Marketplace Zone',
            'Zone',
            'Location',
            'City',
            'Radius',
            'نطاق السوق',
            'Zone Marketplace',
            'Ville',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-zone'),
              icon: CupertinoIcons.location,
              title: s.tr(
                'نطاق السوق',
                'Zone Marketplace',
                'Marketplace Zone',
              ),
              trailingText: _state.activeZoneBadgeLabel(s),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsZoneScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'Notifications',
            'Alerts',
            'الإشعارات',
            'التنبيهات',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-notifications'),
              icon: CupertinoIcons.bell,
              title: s.tr('الإشعارات', 'Notifications', 'Notifications'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'App language',
            'Language',
            'English',
            'Français',
            'العربية',
            'لغة التطبيق',
            'Langue',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-language'),
              icon: CupertinoIcons.globe,
              title: s.tr('لغة التطبيق', 'Langue', 'App language'),
              trailingText: _languageDisplayLabel(s.lang),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsLanguageScreen(),
                ),
              ),
            ),
        ];

        final subscriptionItems = <Widget>[
          if (_matchesQuery([
            'Apolo Pro+',
            'Pro Plus',
            'Subscriptions',
            'Premium',
            'Not subscribed',
            'الاشتراكات',
            'Abonnements',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-pro-plus'),
              icon: CupertinoIcons.sparkles,
              title: 'Apolo Pro+',
              trailingText: _state.isProPlusAccount
                  ? s.tr('مفعل PRO+', 'PRO+ Actif', 'PRO+ Active')
                  : s.tr('غير مشترك', 'Non abonné', 'Not subscribed'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProPlusScreen()),
              ),
            ),
          if (isLoggedIn &&
              _matchesQuery([
                'VIP Boost Credits',
                'Boost',
                'Credits',
                'رصيد التمويل VIP',
                'Crédits Boost VIP',
              ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-vip-credits'),
              icon: CupertinoIcons.bolt_fill,
              title: s.tr(
                'رصيد التمويل VIP',
                'Crédits Boost VIP',
                'VIP Boost Credits',
              ),
              trailingText: '${_state.vipBoostCredits}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProPlusScreen()),
              ),
            ),
        ];

        final communityItems = <Widget>[
          if (_matchesQuery([
            'Add your friends',
            'Friends',
            'Invite',
            'إضافة الأصدقاء',
            'Ajouter des amis',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-add-friends'),
              icon: CupertinoIcons.person_add,
              title: s.tr(
                'إضافة الأصدقاء',
                'Ajouter des amis',
                'Add your friends',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddFriendsScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'Share App',
            'Share Apolo',
            'مشاركة التطبيق',
            'Partager',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-share-app'),
              icon: CupertinoIcons.share,
              title: s.tr(
                'مشاركة التطبيق',
                'Partager l’application',
                'Share App',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsShareAppScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'Blocked accounts',
            'Block',
            'الحسابات المحظورة',
            'Comptes bloqués',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-blocked'),
              icon: CupertinoIcons.nosign,
              title: s.tr(
                'الحسابات المحظورة',
                'Comptes bloqués',
                'Blocked accounts',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsBlockedAccountsScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'Privacy & Terms',
            'Privacy',
            'Terms',
            'الخصوصية والشروط',
            'Confidentialité',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-privacy'),
              icon: CupertinoIcons.lock_shield,
              title: s.tr(
                'الخصوصية والشروط',
                'Confidentialité et conditions',
                'Privacy & Terms',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyComplianceScreen(),
                ),
              ),
            ),
        ];

        final supportItems = <Widget>[
          if (_matchesQuery([
            'Help & Support',
            'Help',
            'Support',
            'المساعدة والدعم',
            'Aide',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-help'),
              icon: CupertinoIcons.question_circle,
              title: s.tr(
                'المساعدة والدعم',
                'Aide et support',
                'Help & Support',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
              ),
            ),
          if (_matchesQuery([
            'Report a problem',
            'Bug report',
            'Problem',
            'الإبلاغ عن مشكلة',
            'Signaler un problème',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-bug-report'),
              icon: CupertinoIcons.ant,
              title: s.tr(
                'الإبلاغ عن مشكلة',
                'Signaler un problème',
                'Report a problem',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsBugReportScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'Make a suggestion',
            'Feedback',
            'Suggestion',
            'تقديم اقتراح',
            'Faire une suggestion',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-suggestion'),
              icon: CupertinoIcons.lightbulb,
              title: s.tr(
                'تقديم اقتراح',
                'Faire une suggestion',
                'Make a suggestion',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsSuggestionScreen(),
                ),
              ),
            ),
          if (_matchesQuery([
            'App data & licenses',
            'App data',
            'Licenses',
            'بيانات التطبيق والتراخيص',
            'Données et licences',
          ]))
            ApoloDlGroupedItem(
              key: const Key('settings-row-app-data'),
              icon: CupertinoIcons.doc_text,
              title: s.tr(
                'بيانات التطبيق والتراخيص',
                'Données et licences',
                'App data & licenses',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsAppDataScreen(),
                ),
              ),
            ),
        ];

        final showSessionSection = isLoggedIn
            ? _matchesQuery([
                'Log out',
                'Sign out',
                'Account',
                'تسجيل الخروج',
                'Se déconnecter',
              ])
            : _matchesQuery([
                'Log in',
                'Sign in',
                'Create account',
                'Register',
                'Account',
                'تسجيل الدخول',
                'إنشاء حساب',
                'Se connecter',
              ]);

        final hasAnyResult = showAccountCenter ||
            howYouUseItems.isNotEmpty ||
            subscriptionItems.isNotEmpty ||
            communityItems.isNotEmpty ||
            supportItems.isNotEmpty ||
            showSessionSection;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'الإعدادات والنشاط',
                      'Paramètres et activité',
                      'Settings and activity',
                    ),
                    showSeparator: false,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          children: [
                            _buildSearchField(palette, s),
                            if (!hasAnyResult)
                              Padding(
                                padding: const EdgeInsets.only(top: 28),
                                child: ApoloDlEmptyState(
                                  icon: CupertinoIcons.search,
                                  headline: s.tr(
                                    'لا توجد نتائج',
                                    'Aucun résultat',
                                    'No matching settings',
                                  ),
                                  description: s.tr(
                                    'جرّب البحث بكلمة أخرى مثل: المحفوظات، اللغة، أو Pro+.',
                                    'Essayez un autre mot-clé comme : langue, favoris ou Pro+.',
                                    'Try another keyword such as Saved, Language, or Pro+.',
                                  ),
                                ),
                              )
                            else ...[
                              if (showAccountCenter) ...[
                                ApoloDlSectionHeader(
                                  isFirst: true,
                                  title: s.tr(
                                    'حسابك',
                                    'Votre compte',
                                    'Your account',
                                  ),
                                ),
                                _buildAccountHeroCard(palette, s),
                              ],
                              if (howYouUseItems.isNotEmpty)
                                ApoloDlSettingsGroup(
                                  isFirst: !showAccountCenter,
                                  title: s.tr(
                                    'كيف تستخدم Apolo',
                                    'Comment vous utilisez Apolo',
                                    'How you use Apolo',
                                  ),
                                  children: howYouUseItems,
                                ),
                              if (subscriptionItems.isNotEmpty)
                                ApoloDlSettingsGroup(
                                  title: s.tr(
                                    'الاشتراكات',
                                    'Abonnements',
                                    'Subscriptions',
                                  ),
                                  children: subscriptionItems,
                                ),
                              if (communityItems.isNotEmpty)
                                ApoloDlSettingsGroup(
                                  title: s.tr(
                                    'المجتمع والخصوصية',
                                    'Communauté et confidentialité',
                                    'Community & Privacy',
                                  ),
                                  children: communityItems,
                                ),
                              if (supportItems.isNotEmpty)
                                ApoloDlSettingsGroup(
                                  title: s.tr('الدعم', 'Support', 'Support'),
                                  children: supportItems,
                                ),
                              if (showSessionSection) ...[
                                ApoloDlSectionHeader(
                                  title: s.tr('الحساب', 'Compte', 'Account'),
                                ),
                                if (isLoggedIn)
                                  ApoloDlButton(
                                    key: const Key('settings-logout'),
                                    label: s.tr(
                                      'تسجيل الخروج',
                                      'Se déconnecter',
                                      'Log out',
                                    ),
                                    variant: ApoloDlButtonVariant.dangerSoft,
                                    fullWidth: true,
                                    leadingIcon:
                                        CupertinoIcons.square_arrow_right,
                                    onPressed: () => _confirmLogout(s),
                                  )
                                else ...[
                                  ApoloDlButton(
                                    key: const Key('settings-login'),
                                    label: s.tr(
                                      'تسجيل الدخول',
                                      'Se connecter',
                                      'Log in',
                                    ),
                                    fullWidth: true,
                                    onPressed: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AuthScreen(
                                          initialIsLogin: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ApoloDlButton(
                                    key: const Key('settings-register'),
                                    label: s.tr(
                                      'إنشاء حساب',
                                      'Créer un compte',
                                      'Create account',
                                    ),
                                    variant: ApoloDlButtonVariant.secondary,
                                    fullWidth: true,
                                    onPressed: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => const AuthScreen(
                                          initialIsLogin: false,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField(ApoloDlPalette palette, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: palette.pill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _searchFocused ? palette.ink : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 18,
              color: _searchFocused ? palette.ink : palette.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const Key('settings-search-field'),
                controller: _searchCtrl,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: palette.ink,
                ),
                decoration: InputDecoration(
                  hintText: s.tr('بحث', 'Rechercher', 'Search'),
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: palette.muted,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                key: const Key('settings-search-clear'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _searchCtrl.clear();
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 18,
                    color: palette.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountHeroCard(ApoloDlPalette palette, AppStrings s) {
    return Material(
      color: palette.groupCard,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('settings-row-apolo-account'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ApoloAccountCenterScreen(
              onEditProfile: widget.onOpenEditProfile ?? widget.onEditProfile,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.person_crop_circle_fill,
                  color: AppConfig.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tr(
                        'مركز حساب أبولو',
                        'Espace Compte Apolo',
                        'Apolo Account',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.tr(
                        'كلمة المرور، الأمان، البيانات الشخصية، المتجر والأعمال',
                        'Mot de passe, sécurité, infos personnelles, boutique & pro',
                        'Password, security, personal details, store & business',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                s.isAr
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                size: 16,
                color: palette.iconMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
