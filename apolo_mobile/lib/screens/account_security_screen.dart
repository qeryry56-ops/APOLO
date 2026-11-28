import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../account/account_helpers.dart';
import '../core/state/app_state.dart';
import '../widgets/dl_settings_kit.dart';
import '../l10n/l10n.dart';

/// Dynamic Layer v5.1 `Account security` Screen:
/// - Pure `#FFFFFF` canvas + `ApoloDlTopNav`
/// - Flat `#F6F6F6` rounded `20px` cards with `#FFFFFF` borderless inputs
/// - `#000000` primary capsule save CTAs (`50px` height)
class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});
  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _state = AppState();
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _successMessage;

  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlSeparator = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlDanger = Color(0xFFE31B23);
  static const Color _dlSuccess = Color(0xFF15803D);

  @override
  void initState() {
    super.initState();
    final user = _state.currentUser ?? const <String, dynamic>{};
    _emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: user['phone']?.toString() ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveContactInfo() async {
    if (_savingProfile) return;
    HapticFeedback.selectionClick();
    final s = _state.s;
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final name = (_state.currentUser?['name']?.toString() ?? '').trim();
    if (!AccountValidation.email(email)) {
      setState(() {
        _error = s.tr(
          'أدخل بريداً إلكترونياً صالحاً.',
          'Entrez une adresse e-mail valide.',
          appL10n.accountSecurityEnterValidEmailAddress,
        );
        _successMessage = null;
      });
      return;
    }
    final normalizedPhone =
        phone.isEmpty ? null : AccountValidation.phone(phone);
    if (phone.isNotEmpty && normalizedPhone == null) {
      setState(() {
        _error = s.tr(
          'أدخل رقم هاتف مغربي صالح.',
          'Entrez un numéro marocain valide.',
          appL10n.accountSecurityEnterValidPhoneNumber,
        );
        _successMessage = null;
      });
      return;
    }
    setState(() {
      _savingProfile = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final res = await _state.api.dio.put('/auth/profile', data: {
        'name': name.length >= 2 ? name : 'Apolo User',
        'email': email,
        if (normalizedPhone != null) 'phone': normalizedPhone,
      });
      final data = res.data;
      if (data is Map && data['status'] == 'error') {
        throw AccountFailure('server', data['message']?.toString());
      }
      if (data is Map && data['user'] is Map) {
        await _state
            .updateCurrentUser(Map<String, dynamic>.from(data['user'] as Map));
      } else if (_state.currentUser != null) {
        await _state.updateCurrentUser({
          ..._state.currentUser!,
          'email': email,
          if (normalizedPhone != null) 'phone': normalizedPhone,
        });
      }
      if (mounted) {
        setState(() => _successMessage = s.tr(
              'تم تحديث بيانات الاتصال بنجاح.',
              'Coordonnées mises à jour avec succès.',
              appL10n.accountSecurityContactDetailsUpdatedSuccessfully,
            ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = accountError(e, s.isAr));
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (_savingPassword) return;
    HapticFeedback.selectionClick();
    final s = _state.s;
    final currentPassword = _currentPasswordCtrl.text;
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    if (!AccountValidation.password(currentPassword) ||
        !AccountValidation.password(newPassword)) {
      setState(() {
        _error = s.tr(
          'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل.',
          'Le mot de passe doit contenir au moins 8 caractères.',
          appL10n.accountSecurityPasswordMustBeAtLeast,
        );
        _successMessage = null;
      });
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() {
        _error = s.tr(
          'كلمتا المرور غير متطابقتين.',
          'Les mots de passe ne correspondent pas.',
          appL10n.accountSecurityPasswordsDoNotMatch,
        );
        _successMessage = null;
      });
      return;
    }
    setState(() {
      _savingPassword = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final auth = AccountAuth(client: _state.api.dio);
      await auth.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmation: confirmPassword,
      );
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      if (mounted) {
        setState(() => _successMessage = s.tr(
              'تم تحديث كلمة المرور بنجاح.',
              'Mot de passe mis à jour avec succès.',
              appL10n.accountSecurityPasswordUpdatedSuccessfully,
            ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = accountError(e, s.isAr));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Widget _buildDlInput({
    required Key fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _dlBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        child: TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          cursorColor: _dlInk,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: _dlInk,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _dlMuted, fontSize: 13.5),
            prefixIcon: Icon(icon, size: 18, color: _dlInk),
            suffixIcon: suffixIcon,
            filled: false,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState().s;
    final isAr = s.isAr;
    final loggedIn = _state.isLoggedIn;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _dlBg,
        body: SafeArea(
          child: Column(
            children: [
              ApoloDlTopNav(
                title: s.tr(
                  'أمان الحساب',
                  'Sécurité du compte',
                  appL10n.accountSecurityAccountSecurity,
                ),
                showSeparator: false,
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                      children: [
                        // Intro Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _dlSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: _dlBg,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  size: 20,
                                  color: _dlInk,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.tr(
                                        'بيانات الدخول تبقى تحت سيطرتك',
                                        'Gardez la main sur vos accès',
                                        appL10n.accountSecurityStayControlLogin,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: _dlInk,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.tr(
                                        'يمكنك تحديث كلمة المرور أو البريد الإلكتروني أو رقم الهاتف مباشرة من التطبيق.',
                                        'Mettez à jour votre mot de passe, votre adresse e-mail ou votre numéro directement ici.',
                                        appL10n.accountSecurityUpdatePasswordEmailPhoneDirectly,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _dlMuted,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_successMessage != null)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Semantics(
                              liveRegion: true,
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.check_mark_circled_solid,
                                    size: 18,
                                    color: _dlSuccess,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _successMessage!,
                                      style: const TextStyle(
                                        color: _dlInk,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Semantics(
                              liveRegion: true,
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.exclamationmark_circle_fill,
                                    size: 18,
                                    color: _dlDanger,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: _dlDanger,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (loggedIn) ...[
                          ApoloDlSectionHeader(
                            title: s.tr(
                              'بيانات الاتصال',
                              'Coordonnées',
                              appL10n.accountSecurityContactDetails,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildDlInput(
                                  fieldKey: const Key('security-email'),
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  label: s.tr(
                                    'البريد الإلكتروني',
                                    'Adresse e-mail',
                                    appL10n.accountSecurityEmailAddress,
                                  ),
                                  icon: CupertinoIcons.at,
                                ),
                                const SizedBox(height: 10),
                                _buildDlInput(
                                  fieldKey: const Key('security-phone'),
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  label: s.tr(
                                    'رقم الهاتف',
                                    'Numéro de téléphone',
                                    appL10n.accountSecurityPhoneNumber,
                                  ),
                                  icon: CupertinoIcons.phone,
                                ),
                                const SizedBox(height: 14),
                                ApoloDlButton(
                                  key: const Key('security-save-profile'),
                                  label: s.tr(
                                    'حفظ بيانات الاتصال',
                                    'Enregistrer les coordonnées',
                                    appL10n.accountSecuritySaveContactDetails,
                                  ),
                                  variant: ApoloDlButtonVariant.primary,
                                  borderRadius: 999,
                                  height: 50,
                                  fullWidth: true,
                                  isLoading: _savingProfile,
                                  onPressed: _savingProfile
                                      ? null
                                      : _saveContactInfo,
                                ),
                              ],
                            ),
                          ),
                          ApoloDlSectionHeader(
                            title: s.tr(
                              'تغيير كلمة المرور',
                              'Modifier le mot de passe',
                              appL10n.accountSecurityChangePassword,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildDlInput(
                                  fieldKey:
                                      const Key('security-current-password'),
                                  controller: _currentPasswordCtrl,
                                  obscureText: _obscureCurrent,
                                  label: s.tr(
                                    'كلمة المرور الحالية',
                                    'Mot de passe actuel',
                                    appL10n.accountSecurityCurrentPassword,
                                  ),
                                  icon: CupertinoIcons.lock,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureCurrent = !_obscureCurrent,
                                    ),
                                    icon: Icon(
                                      _obscureCurrent
                                          ? CupertinoIcons.eye
                                          : CupertinoIcons.eye_slash,
                                      size: 18,
                                      color: _dlMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildDlInput(
                                  fieldKey: const Key('security-new-password'),
                                  controller: _newPasswordCtrl,
                                  obscureText: _obscureNew,
                                  label: s.tr(
                                    'كلمة المرور الجديدة',
                                    'Nouveau mot de passe',
                                    appL10n.accountSecurityNewPassword,
                                  ),
                                  icon: CupertinoIcons.lock_rotation,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                    icon: Icon(
                                      _obscureNew
                                          ? CupertinoIcons.eye
                                          : CupertinoIcons.eye_slash,
                                      size: 18,
                                      color: _dlMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildDlInput(
                                  fieldKey:
                                      const Key('security-confirm-password'),
                                  controller: _confirmPasswordCtrl,
                                  obscureText: _obscureConfirm,
                                  label: s.tr(
                                    'تأكيد كلمة المرور الجديدة',
                                    'Confirmer le nouveau mot de passe',
                                    appL10n.accountSecurityConfirmNewPassword,
                                  ),
                                  icon: CupertinoIcons.checkmark_shield,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? CupertinoIcons.eye
                                          : CupertinoIcons.eye_slash,
                                      size: 18,
                                      color: _dlMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ApoloDlButton(
                                  key: const Key('security-save-password'),
                                  label: s.tr(
                                    'تحديث كلمة المرور',
                                    'Mettre à jour le mot de passe',
                                    appL10n.accountSecurityUpdatePassword,
                                  ),
                                  variant: ApoloDlButtonVariant.primary,
                                  borderRadius: 999,
                                  height: 50,
                                  fullWidth: true,
                                  isLoading: _savingPassword,
                                  onPressed:
                                      _savingPassword ? null : _changePassword,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ApoloDlSectionHeader(
                            title: s.tr(
                              'إعدادات الأمان',
                              'Options de sécurité',
                              appL10n.accountSecuritySecurityOptions,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: _dlSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: CupertinoIcons.lock,
                                  title: s.tr(
                                    'كلمة المرور',
                                    'Mot de passe',
                                    appL10n.authPasswordPlaceholder,
                                  ),
                                  subtitle: s.tr(
                                    'سجّل الدخول في التطبيق لتعديل هذه البيانات',
                                    'Connectez-vous dans l’application pour modifier ces informations',
                                    appL10n.accountSecuritySignUpdateThisInformation,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: 60,
                                    end: 14,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _dlSeparator,
                                  ),
                                ),
                                _buildInfoRow(
                                  icon: CupertinoIcons.at,
                                  title: s.tr(
                                    'البريد الإلكتروني',
                                    'Adresse e-mail',
                                    appL10n.accountSecurityEmailAddress,
                                  ),
                                  subtitle: s.tr(
                                    'سجّل الدخول في التطبيق لتعديل هذه البيانات',
                                    'Connectez-vous dans l’application pour modifier ces informations',
                                    appL10n.accountSecuritySignUpdateThisInformation,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: 60,
                                    end: 14,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _dlSeparator,
                                  ),
                                ),
                                _buildInfoRow(
                                  icon: CupertinoIcons.phone,
                                  title: s.tr(
                                    'رقم الهاتف',
                                    'Numéro de téléphone',
                                    appL10n.accountSecurityPhoneNumber,
                                  ),
                                  subtitle: s.tr(
                                    'سجّل الدخول في التطبيق لتعديل هذه البيانات',
                                    'Connectez-vous dans l’application pour modifier ces informations',
                                    appL10n.accountSecuritySignUpdateThisInformation,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
            child: Icon(icon, size: 17, color: _dlInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _dlInk,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _dlMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
