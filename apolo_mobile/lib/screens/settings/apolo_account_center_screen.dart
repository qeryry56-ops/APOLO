import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../widgets/apolo_badges_kit.dart';
import '../../widgets/dl_settings_kit.dart';
import '../account_security_screen.dart';
import '../account_setup_screen.dart';
import '../auth_screen.dart';
import '../business_switch_screen.dart';
import '../forgot_password_screen.dart';
import '../privacy_compliance_screen.dart';
import '../widgets/app_image.dart';

class ApoloAccountCenterScreen extends StatefulWidget {
  const ApoloAccountCenterScreen({
    super.key,
    this.onEditProfile,
  });

  final VoidCallback? onEditProfile;

  @override
  State<ApoloAccountCenterScreen> createState() =>
      _ApoloAccountCenterScreenState();
}

class _ApoloAccountCenterScreenState extends State<ApoloAccountCenterScreen> {
  final AppState _state = AppState();
  bool _switchingPersonal = false;

  String _resolveHandle(Map<String, dynamic>? user) {
    final raw = (user?['username'] ?? user?['handle'] ?? '').toString().trim();
    if (raw.isNotEmpty) {
      return raw.startsWith('@') ? raw : '@$raw';
    }
    final name = (user?['name'] ?? '').toString().trim().toLowerCase();
    final slug = name.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return slug.isNotEmpty ? '@$slug' : '@apolo_member';
  }

  Future<void> _handleEditProfile() async {
    if (widget.onEditProfile != null) {
      Navigator.of(context).pop('open_edit_profile');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AccountSecurityScreen()),
    );
  }

  Future<void> _confirmSwitchToPersonal(AppStrings s) async {
    if (_switchingPersonal) return;
    final palette = ApoloDlPalette.of(context);
    final confirmed = await showApoloDlBottomSheet<bool>(
      context,
      headerTitle: s.tr(
        'العودة إلى الحساب الشخصي',
        'Passer au compte personnel',
        'Switch to Personal Account',
      ),
      media: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: palette.pill,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.person_crop_circle,
          color: palette.ink,
          size: 28,
        ),
      ),
      contentTitle: s.tr(
        'هل تريد العودة للحساب الشخصي؟',
        'Revenir au compte personnel ?',
        'Return to a personal account?',
      ),
      contentDescription: s.tr(
        'سيتم إيقاف عرض صفحة المتجر الاحترافي مؤقتاً ويمكنك إعادة تفعيله لاحقاً.',
        'Votre page boutique pro sera masquée. Vous pourrez la réactiver plus tard.',
        'Your business store page will be paused. You can re-enable it anytime.',
      ),
      actions: [
        ApoloDlButton(
          label: s.tr('تأكيد التحويل', 'Confirmer', 'Confirm switch'),
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

    setState(() => _switchingPersonal = true);
    try {
      await _state.switchToPersonal();
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            s.tr(
              'تم التحويل إلى الحساب الشخصي بنجاح.',
              'Compte personnel activé.',
              'Switched to Personal Account.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            s.tr(
              'تعذر تغيير نوع الحساب. حاول مجدداً.',
              'Impossible de changer le type de compte.',
              'Could not switch account type. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _switchingPersonal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;
        final palette = ApoloDlPalette.of(context);
        final user = _state.currentUser;
        final isLoggedIn = _state.isLoggedIn && user != null;
        final name = (user?['name'] ?? s.tr('عضو أبولو', 'Membre Apolo', 'Apolo Member'))
            .toString()
            .trim();
        final email = (user?['email'] ?? '').toString().trim();
        final phone = (user?['phone'] ?? '').toString().trim();
        final avatarUrl =
            (user?['avatar_url'] ?? user?['avatar'] ?? '').toString().trim();
        final handle = _resolveHandle(user);

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: palette.bg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'مركز حساب أبولو',
                      'Espace Compte Apolo',
                      'Apolo Account',
                    ),
                    showSeparator: false,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: isLoggedIn
                              ? [
                                  _buildIdentityCard(
                                    palette: palette,
                                    s: s,
                                    name: name,
                                    handle: handle,
                                    email: email,
                                    phone: phone,
                                    avatarUrl: avatarUrl,
                                  ),
                                  const SizedBox(height: 8),
                                  ApoloDlSettingsGroup(
                                    title: s.tr(
                                      'البيانات الشخصية',
                                      'Informations personnelles',
                                      'Personal details',
                                    ),
                                    children: [
                                      ApoloDlGroupedItem(
                                        key: const Key(
                                          'account-center-edit-profile',
                                        ),
                                        icon: CupertinoIcons.person_crop_circle,
                                        title: s.tr(
                                          'تعديل الملف الشخصي',
                                          'Modifier le profil',
                                          'Edit profile',
                                        ),
                                        onTap: _handleEditProfile,
                                      ),
                                      ApoloDlGroupedItem(
                                        key: const Key(
                                          'account-center-contact',
                                        ),
                                        icon: CupertinoIcons.mail,
                                        title: s.tr(
                                          'البريد الإلكتروني والهاتف',
                                          'E-mail et téléphone',
                                          'Email & phone',
                                        ),
                                        trailingText: email.isNotEmpty
                                            ? email
                                            : (phone.isNotEmpty ? phone : null),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const AccountSecurityScreen(),
                                          ),
                                        ),
                                      ),
                                      ApoloDlGroupedItem(
                                        key: const Key('account-center-setup'),
                                        icon: CupertinoIcons.slider_horizontal_3,
                                        title: s.tr(
                                          'نوع الحساب والتفضيلات',
                                          'Type de compte et préférences',
                                          'Account type & preferences',
                                        ),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const AccountSetupScreen(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ApoloDlSettingsGroup(
                                    title: s.tr(
                                      'كلمة المرور والأمان',
                                      'Mot de passe et sécurité',
                                      'Password & security',
                                    ),
                                    children: [
                                      ApoloDlGroupedItem(
                                        key: const Key(
                                          'account-center-password',
                                        ),
                                        icon: CupertinoIcons.lock,
                                        title: s.tr(
                                          'تغيير كلمة المرور',
                                          'Changer le mot de passe',
                                          'Change password',
                                        ),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const AccountSecurityScreen(),
                                          ),
                                        ),
                                      ),
                                      ApoloDlGroupedItem(
                                        key: const Key(
                                          'account-center-reset-password',
                                        ),
                                        icon: CupertinoIcons.arrow_counterclockwise,
                                        title: s.tr(
                                          'إعادة تعيين كلمة المرور',
                                          'Réinitialiser le mot de passe',
                                          'Reset password',
                                        ),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                ForgotPasswordScreen(
                                              initialEmail: email.isNotEmpty
                                                  ? email
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ApoloDlSettingsGroup(
                                    title: s.tr(
                                      'الأعمال والمتجر',
                                      'Business & Boutique',
                                      'Business & Store',
                                    ),
                                    children: _state.isBusinessAccount
                                        ? [
                                            ApoloDlGroupedItem(
                                              key: const Key(
                                                'account-center-business',
                                              ),
                                              icon: CupertinoIcons.bag,
                                              title: s.tr(
                                                'تعديل ملف المتجر',
                                                'Modifier la boutique',
                                                'Edit Store Profile',
                                              ),
                                              onTap: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const BusinessSwitchScreen(
                                                    isEditing: true,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ApoloDlGroupedItem(
                                              key: const Key(
                                                'account-center-switch-personal',
                                              ),
                                              icon: CupertinoIcons.person,
                                              title: s.tr(
                                                'التحويل إلى حساب شخصي',
                                                'Passer en compte personnel',
                                                'Switch to Personal Account',
                                              ),
                                              disabled: _switchingPersonal,
                                              onTap: () =>
                                                  _confirmSwitchToPersonal(s),
                                            ),
                                          ]
                                        : [
                                            ApoloDlGroupedItem(
                                              key: const Key(
                                                'account-center-business',
                                              ),
                                              icon: CupertinoIcons.bag,
                                              title: s.tr(
                                                'التحويل إلى حساب أعمال',
                                                'Passer en compte Business',
                                                'Switch to Business Account',
                                              ),
                                              onTap: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      const BusinessSwitchScreen(
                                                    isEditing: false,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                  ),
                                  ApoloDlSettingsGroup(
                                    title: s.tr(
                                      'ملكية الحساب',
                                      'Propriété du compte',
                                      'Account ownership',
                                    ),
                                    children: [
                                      ApoloDlGroupedItem(
                                        key: const Key('account-center-delete'),
                                        icon: CupertinoIcons.trash,
                                        title: s.tr(
                                          'حذف الحساب والبيانات',
                                          'Supprimer le compte et les données',
                                          'Delete account & data',
                                        ),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const PrivacyComplianceScreen(
                                              initialTab: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ]
                              : [
                                  _buildGuestCard(palette: palette, s: s),
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

  Widget _buildIdentityCard({
    required ApoloDlPalette palette,
    required AppStrings s,
    required String name,
    required String handle,
    required String email,
    required String phone,
    required String avatarUrl,
  }) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    final contactLine =
        email.isNotEmpty ? email : (phone.isNotEmpty ? phone : handle);
    final isVerified = _state.currentUser?['is_verified'] == true ||
        _state.currentUser?['phone_verified_at'] != null ||
        _state.isBusinessAccount ||
        _state.isProPlusAccount;
    final rank = ApoloSellerRank.resolve(
      user: _state.currentUser,
      isProPlus: _state.isProPlusAccount,
      isBusiness: _state.isBusinessAccount,
      isVerified: isVerified,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.groupCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: palette.bg,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: avatarUrl.isNotEmpty
                ? AppImage(
                    url: avatarUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                  )
                : Text(
                    initial,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ApoloIdentityBadgesRow(
                      isVerified: isVerified,
                      rank: rank,
                      isProPlus: _state.isProPlusAccount,
                      isBusiness: _state.isBusinessAccount,
                      showProPill: true,
                      badgeSize: 16,
                    ),
                    if (_state.isBusinessAccount &&
                        !_state.isProPlusAccount) ...[
                      const SizedBox(width: 6),
                      _StatusPill(
                        label: s.tr('أعمال', 'Pro', 'Business'),
                        background: palette.bg,
                        foreground: palette.ink,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  handle,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                if (contactLine != handle) ...[
                  const SizedBox(height: 2),
                  Text(
                    contactLine,
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard({
    required ApoloDlPalette palette,
    required AppStrings s,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.groupCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.bg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.person_crop_circle,
                  color: palette.ink,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tr(
                        'إدارة حساب أبولو',
                        'Gérer votre compte Apolo',
                        'Manage your Apolo Account',
                      ),
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.tr(
                        'سجّل الدخول للوصول إلى الأمان، البيانات الشخصية، ومتجر الأعمال.',
                        'Connectez-vous pour gérer la sécurité, vos infos et votre boutique.',
                        'Sign in to manage security, personal details, and your store.',
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
            ],
          ),
          const SizedBox(height: 18),
          ApoloDlButton(
            key: const Key('account-center-login'),
            label: s.tr('تسجيل الدخول', 'Se connecter', 'Log in'),
            borderRadius: 999,
            height: 50,
            fullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AuthScreen(initialIsLogin: true),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ApoloDlButton(
            key: const Key('account-center-register'),
            label: s.tr('إنشاء حساب', 'Créer un compte', 'Create account'),
            variant: ApoloDlButtonVariant.secondary,
            borderRadius: 999,
            height: 50,
            fullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AuthScreen(initialIsLogin: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
