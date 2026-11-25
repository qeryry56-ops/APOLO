import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/notification_badge.dart';
import 'account_security_screen.dart';
import 'auth_screen.dart';
import 'business_switch_screen.dart';
import 'forgot_password_screen.dart';
import 'intent_onboarding_screen.dart';
import 'notifications_screen.dart';
import 'privacy_compliance_screen.dart';
import 'pro_plus_screen.dart';
import 'settings/settings_app_data_screen.dart';
import 'settings/settings_blocked_accounts_screen.dart';
import 'settings/settings_bug_report_screen.dart';
import 'settings/settings_language_screen.dart';
import 'settings/settings_rate_app_screen.dart';
import 'settings/settings_share_app_screen.dart';
import 'settings/settings_suggestion_screen.dart';
import 'settings/settings_zone_screen.dart';
import 'stores_screen.dart';
import 'support_screen.dart';
import 'widgets/quick_replies_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenEditProfile;
  const SettingsScreen({super.key, this.onOpenEditProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _state = AppState();
  bool _busy = false;
  String? _error;

  Future<void> _logout() async {
    final s = _state.s;
    final palette = ApoloDlPalette.of(context);
    final confirmed = await showApoloDlBottomSheet<bool>(
      context,
      headerTitle: s.logout,
      media: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.power,
          size: 26,
          color: palette.danger,
        ),
      ),
      contentTitle: s.tr(
        'تسجيل الخروج؟',
        'Se déconnecter ?',
        'Sign out of Apolo?',
      ),
      contentDescription: s.tr(
        'ستنتهي جلستك على هذا الجهاز. قد تحتاج لتسجيل الدخول مجدداً.',
        'Votre session sur cet appareil sera fermée. Vous devrez vous reconnecter.',
        'Your session on this device will end. You may need to sign in again.',
      ),
      actions: [
        ApoloDlButton(
          key: const Key('settings-confirm-logout'),
          label: s.logout,
          variant: ApoloDlButtonVariant.danger,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        ApoloDlButton(
          label: s.tr('إلغاء', 'Annuler', 'Cancel'),
          variant: ApoloDlButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _state.logout();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = s.tr(
            'تعذر إغلاق الجلسة المحلية. أعد المحاولة.',
            'Impossible de fermer la session locale. Réessayez.',
            'Could not close local session. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmSwitchToPersonal() async {
    final s = _state.s;
    final palette = ApoloDlPalette.of(context);
    final confirmed = await showApoloDlBottomSheet<bool>(
      context,
      headerTitle: s.tr(
        'العودة إلى حساب شخصي',
        'Revenir au compte personnel',
        'Switch to Personal Account',
      ),
      media: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.groupCard,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.person_crop_circle,
          size: 28,
          color: palette.ink,
        ),
      ),
      contentTitle: s.tr(
        'إيقاف وضع الأعمال مؤقتاً؟',
        'Masquer votre boutique temporairement ?',
        'Pause your Business store?',
      ),
      contentDescription: s.tr(
        'سيتم إخفاء متجرك مؤقتاً من قسم المتاجر دون حذف أي بيانات أو ردود سريعة. يمكنك العودة لحساب Business في أي وقت بضغطة زر.',
        'Votre boutique sera masquée sans supprimer vos données ni vos réponses rapides. Vous pourrez réactiver Business à tout moment.',
        'Your store will be hidden without deleting any data or quick replies. You can switch back anytime.',
      ),
      actions: [
        ApoloDlButton(
          key: const Key('settings-confirm-switch-personal'),
          label: s.tr(
            'نعم، العودة لحساب شخصي',
            'Revenir en Personnel',
            'Switch to Personal',
          ),
          variant: ApoloDlButtonVariant.primary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        ApoloDlButton(
          label: s.tr('إلغاء', 'Annuler', 'Cancel'),
          variant: ApoloDlButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _state.switchToPersonal();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConfig.success,
          content: Text(
            s.tr(
              'تم إرجاع حسابك إلى حساب شخصي مع حفظ إعدادات متجرك.',
              'Compte repassé en mode Personnel (boutique sauvegardée).',
              'Switched back to Personal (store data saved).',
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = s.tr(
            'تعذر تغيير نوع الحساب حالياً. حاول مجدداً.',
            'Impossible de changer le type de compte. Réessayez.',
            'Could not switch account type. Please try again.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleEditProfileTap() {
    HapticFeedback.selectionClick();
    if (!_state.isLoggedIn) {
      _open(const AuthScreen());
    } else if (widget.onOpenEditProfile != null) {
      widget.onOpenEditProfile!.call();
    } else {
      _open(const AccountSecurityScreen());
    }
  }

  String _resolveHandle() {
    final raw = (_state.currentUser?['username'] ?? '').toString().trim();
    if (raw.isNotEmpty) {
      return raw.startsWith('@') ? raw : '@$raw';
    }
    return '@apolo_user';
  }

  String _languageDisplayLabel(AppStrings s) {
    if (s.isAr) return 'العربية';
    if (s.isEn) return 'English';
    return 'Français';
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
        final userEmail =
            (_state.currentUser?['email'] ?? '').toString().trim();

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr('الإعدادات', 'Paramètres', 'Settings'),
                    size: ApoloDlTopNavSize.md,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                          children: [
                            // Group 1: General
                            ApoloDlSettingsGroup(
                              title: s.tr('عام', 'Général', 'General'),
                              isFirst: true,
                              children: [
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-edit-profile'),
                                  icon: CupertinoIcons.person_crop_circle_fill,
                                  title: s.tr(
                                    'تعديل الملف الشخصي',
                                    'Modifier le profil',
                                    'Edit profile',
                                  ),
                                  trailingText: isLoggedIn
                                      ? _resolveHandle()
                                      : s.tr('زائر', 'Invité', 'Guest'),
                                  disabled: _busy,
                                  onTap: _handleEditProfileTap,
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-security'),
                                  icon: Icons.lock_outline,
                                  title: s.tr(
                                    'البريد وكلمة المرور',
                                    'E-mail et mot de passe',
                                    'Email & password',
                                  ),
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const AccountSecurityScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-forgot-password'),
                                  icon: CupertinoIcons.question_circle_fill,
                                  title: s.tr(
                                    'نسيت كلمة المرور؟',
                                    'Mot de passe oublié ?',
                                    'Forgot password?',
                                  ),
                                  disabled: _busy,
                                  onTap: () => _open(
                                    ForgotPasswordScreen(
                                      initialEmail: userEmail.isNotEmpty
                                          ? userEmail
                                          : null,
                                    ),
                                  ),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-stores'),
                                  icon: CupertinoIcons.rosette,
                                  title: s.tr(
                                    'المتاجر الرسمية (PRO)',
                                    'Boutiques officielles (PRO)',
                                    'Official Stores (PRO)',
                                  ),
                                  disabled: _busy,
                                  onTap: () => _open(const StoresScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-zone'),
                                  icon: CupertinoIcons.location_solid,
                                  title: s.tr(
                                    'منطقة الإعلانات (GPS)',
                                    'Zone des annonces',
                                    'Marketplace Zone',
                                  ),
                                  trailingText: _state.hasActiveZone
                                      ? _state.activeZoneBadgeLabel(s)
                                      : s.allCities,
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const SettingsZoneScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-language'),
                                  icon: CupertinoIcons.globe,
                                  title: s.tr(
                                    'لغة التطبيق',
                                    'Langue de l’app',
                                    'App language',
                                  ),
                                  trailingText: _languageDisplayLabel(s),
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const SettingsLanguageScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-notifications'),
                                  icon: CupertinoIcons.bell_fill,
                                  title: s.tr(
                                    'مركز الإشعارات',
                                    'Notifications',
                                    'Notifications',
                                  ),
                                  trailingBadge: NotificationBadge(
                                    count: _state.unreadNotificationsCount,
                                    type: NotificationBadgeType.number,
                                    variant: NotificationBadgeVariant.red,
                                  ),
                                  disabled: _busy,
                                  onTap: () {
                                    _state
                                        .clearUnreadNotificationsOptimistically(
                                      syncRemote: false,
                                    );
                                    _open(const NotificationsScreen());
                                  },
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key(
                                    'settings-row-intent-onboarding',
                                  ),
                                  icon: CupertinoIcons.sparkles,
                                  title: s.tr(
                                    'هدف استخدام Apolo',
                                    'Objectif d’utilisation',
                                    'App usage goal',
                                  ),
                                  disabled: _busy,
                                  onTap: () => _open(
                                    const ApoloIntentOnboardingScreen(),
                                  ),
                                ),
                              ],
                            ),

                            if (isLoggedIn)
                              ApoloDlSettingsGroup(
                                title: s.tr(
                                  'نوع الحساب والأعمال',
                                  'Compte et outils Business',
                                  'Account & Business Tools',
                                ),
                                children: [
                                  if (!_state.isBusinessAccount)
                                    ApoloDlGroupedItem(
                                      key: const Key(
                                          'settings-switch-to-business'),
                                      icon: CupertinoIcons.briefcase_fill,
                                      title: s.tr(
                                        'التحويل إلى حساب احترافي (Business)',
                                        'Passer au compte professionnel',
                                        'Switch to Business Account',
                                      ),
                                      trailingText: s.tr(
                                        'مجاني',
                                        'Gratuit',
                                        'Free',
                                      ),
                                      disabled: _busy,
                                      onTap: () =>
                                          _open(const BusinessSwitchScreen()),
                                    )
                                  else ...[
                                    ApoloDlGroupedItem(
                                      key: const Key('settings-edit-business'),
                                      icon: CupertinoIcons.briefcase_fill,
                                      title: s.tr(
                                        'إعدادات المتجر والهوية التجارية',
                                        'Identité et horaires de la boutique',
                                        'Store Identity & Working Hours',
                                      ),
                                      trailingText: _state.isProPlusAccount
                                          ? 'PRO+'
                                          : 'Business',
                                      disabled: _busy,
                                      onTap: () => _open(
                                        const BusinessSwitchScreen(
                                          isEditing: true,
                                        ),
                                      ),
                                    ),
                                    ApoloDlGroupedItem(
                                      key: const Key('settings-quick-replies'),
                                      icon: CupertinoIcons.bolt_fill,
                                      title: s.tr(
                                        'الردود السريعة في الشات',
                                        'Réponses rapides (Chat)',
                                        'Chat Quick Replies',
                                      ),
                                      trailingText:
                                          '${_state.quickReplies.length}',
                                      disabled: _busy,
                                      onTap: () =>
                                          QuickRepliesManagerSheet.show(
                                              context),
                                    ),
                                    ApoloDlGroupedItem(
                                      key: const Key('settings-pro-plus'),
                                      icon: CupertinoIcons.sparkles,
                                      title: _state.isProPlusAccount
                                          ? s.tr(
                                              'إدارة اشتراك Pro Plus 👑',
                                              'Gérer mon abonnement Pro Plus 👑',
                                              'Manage Pro Plus 👑',
                                            )
                                          : s.tr(
                                              'الترقية إلى Pro Plus (توثيق وصدارة) 👑',
                                              'Passer à Pro Plus (Vérifié) 👑',
                                              'Upgrade to Pro Plus 👑',
                                            ),
                                      disabled: _busy,
                                      onTap: () => _open(const ProPlusScreen()),
                                    ),
                                    ApoloDlGroupedItem(
                                      key: const Key(
                                          'settings-switch-to-personal'),
                                      icon: CupertinoIcons.arrow_2_circlepath,
                                      title: s.tr(
                                        'العودة إلى حساب شخصي (Personal)',
                                        'Revenir au compte personnel',
                                        'Switch back to Personal',
                                      ),
                                      disabled: _busy,
                                      onTap: _confirmSwitchToPersonal,
                                    ),
                                  ],
                                ],
                              ),

                            // Group 2: Support
                            ApoloDlSettingsGroup(
                              title: s.tr('الدعم', 'Support', 'Support'),
                              children: [
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-bug-report'),
                                  icon: CupertinoIcons
                                      .exclamationmark_square_fill,
                                  title: s.tr(
                                    'الإبلاغ عن مشكلة',
                                    'Signaler un problème',
                                    'Report problem',
                                  ),
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const SettingsBugReportScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-suggestion'),
                                  icon: CupertinoIcons.chat_bubble_text_fill,
                                  title: s.tr(
                                    'تقديم اقتراح',
                                    'Faire une suggestion',
                                    'Make a suggestion',
                                  ),
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const SettingsSuggestionScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-support'),
                                  icon: Icons.help_outline,
                                  title: s.tr(
                                    'الدعم والمساعدة',
                                    'Support',
                                    'Support',
                                  ),
                                  disabled: _busy,
                                  onTap: () => _open(const SupportScreen()),
                                ),
                              ],
                            ),

                            // Group 3: About
                            ApoloDlSettingsGroup(
                              title:
                                  s.tr('حول التطبيق', 'À propos', 'About'),
                              children: [
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-share-app'),
                                  icon: CupertinoIcons
                                      .arrowshape_turn_up_right_fill,
                                  title: s.tr(
                                    'مشاركة التطبيق',
                                    'Partager l’app',
                                    'Share App',
                                  ),
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const SettingsShareAppScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-rate-app'),
                                  icon: CupertinoIcons.star_fill,
                                  title: s.tr(
                                    'تقييم التطبيق',
                                    'Noter l’app',
                                    'Rate App',
                                  ),
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const SettingsRateAppScreen()),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-blocked'),
                                  icon: CupertinoIcons.nosign,
                                  title: s.tr(
                                    'الحسابات المحظورة',
                                    'Comptes bloqués',
                                    'Blocked accounts',
                                  ),
                                  disabled: _busy,
                                  onTap: () => _open(
                                    const SettingsBlockedAccountsScreen(),
                                  ),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-terms'),
                                  icon: CupertinoIcons.doc_text_fill,
                                  title: s.tr(
                                    'شروط الاستخدام',
                                    'Conditions d’utilisation',
                                    'Terms of Service',
                                  ),
                                  disabled: _busy,
                                  onTap: () => _open(
                                    const PrivacyComplianceScreen(
                                      initialTab: 0,
                                    ),
                                  ),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-privacy'),
                                  icon: CupertinoIcons.lock_shield_fill,
                                  title: s.tr(
                                    'سياسة الخصوصية',
                                    'Politique de confidentialité',
                                    'Privacy Policy',
                                  ),
                                  disabled: _busy,
                                  onTap: () => _open(
                                    const PrivacyComplianceScreen(
                                      initialTab: 0,
                                    ),
                                  ),
                                ),
                                ApoloDlGroupedItem(
                                  key: const Key('settings-row-app-data'),
                                  icon: CupertinoIcons.shield_fill,
                                  title: s.tr(
                                    'التراخيص وبيانات التطبيق',
                                    'Licences et données de l’app',
                                    'Licenses & app data',
                                  ),
                                  disabled: _busy,
                                  onTap: () =>
                                      _open(const SettingsAppDataScreen()),
                                ),
                              ],
                            ),

                            // Group 4: Danger Zone
                            ApoloDlSettingsGroup(
                              title: s.tr(
                                'منطقة الخطر',
                                'Zone de danger',
                                'Danger Zone',
                              ),
                              children: isLoggedIn
                                  ? [
                                      ApoloDlGroupedItem(
                                        key: const Key(
                                          'settings-row-delete-account',
                                        ),
                                        icon: CupertinoIcons.trash_fill,
                                        title: s.tr(
                                          'حذف الحساب',
                                          'Supprimer le compte',
                                          'Delete account',
                                        ),
                                        disabled: _busy,
                                        onTap: () => _open(
                                          const PrivacyComplianceScreen(
                                            initialTab: 1,
                                          ),
                                        ),
                                      ),
                                      ApoloDlGroupedItem(
                                        key: const ValueKey('settings-logout'),
                                        icon: CupertinoIcons.power,
                                        title: s.logout,
                                        disabled: _busy,
                                        onTap: _logout,
                                      ),
                                    ]
                                  : [
                                      ApoloDlGroupedItem(
                                        key: const ValueKey('settings-login'),
                                        icon: CupertinoIcons
                                            .person_crop_circle_badge_checkmark,
                                        title: s.login,
                                        disabled: _busy,
                                        onTap: () => _open(const AuthScreen()),
                                      ),
                                    ],
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              ApoloDlAlert(
                                message: _error!,
                                type: ApoloDlAlertType.danger,
                              ),
                            ],

                            const SizedBox(height: 22),
                            Center(
                              child: Text(
                                '${AppConfig.appName} · v${AppConfig.appVersion}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: palette.muted,
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
          ),
        );
      },
    );
  }
}
