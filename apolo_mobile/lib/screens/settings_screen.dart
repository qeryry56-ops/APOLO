import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/dl_settings_kit.dart';
import '../widgets/notification_badge.dart';
import 'account_security_screen.dart';
import 'auth_screen.dart';
import 'forgot_password_screen.dart';
import 'notifications_screen.dart';
import 'privacy_compliance_screen.dart';
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
