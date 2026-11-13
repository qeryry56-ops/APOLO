import 'package:flutter/material.dart';

import '../core/state/app_state.dart';
import 'account_security_screen.dart';
import 'auth_screen.dart';
import 'privacy_compliance_screen.dart';
import 'support_screen.dart';

/// Pixel-perfect implementation of the Figma Setting Screen UI:
/// - Light clean canvas (#F8F9FA)
/// - Top App Bar with back chevron and bold "Setting" title (#0B132B)
/// - Section "ACCOUNT" with white rounded card (16px radius, soft drop shadow):
///     * Edit Profile
///     * Saved content
///     * Notification settings
///     * Change password
/// - Section "OTHER SETTING" with white rounded card:
///     * Terms & conditions
///     * Privacy policy
///     * Help & support
///     * Deactivate account (in vibrant red #E31828 with red trash icon)
/// - Bottom capsule / stadium pill button:
///     * Soft pastel red background (#FDE8E8)
///     * Bold red text (#E31828) "LOGIN" (or "LOGOUT" when authenticated)
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

  static const Color _bg = Color(0xFFF8F9FA);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _sectionLabel = Color(0xFF8E95A5);
  static const Color _divider = Color(0xFFF1F5F9);
  static const Color _red = Color(0xFFE31828);
  static const Color _lightRedBg = Color(0xFFFDE8E8);

  Future<void> _language() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _state.toggleLanguage();
    } catch (_) {
      if (mounted) {
        setState(() => _error = _state.s.tr('تعذر حفظ اللغة. أعد المحاولة.',
            'Impossible d’enregistrer la langue. Réessayez.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final s = _state.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.tr('تسجيل الخروج؟', 'Se déconnecter ?')),
        content: Text(s.tr(
          'ستنتهي جلستك على هذا الجهاز. قد تحتاج لتسجيل الدخول مجدداً.',
          'Votre session sur cet appareil sera fermée. Vous devrez vous reconnecter.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.tr('إلغاء', 'Annuler')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.logout),
          ),
        ],
      ),
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
        setState(() => _error = s.tr('تعذر إغلاق الجلسة المحلية. أعد المحاولة.',
            'Impossible de fermer la session locale. Réessayez.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.s;
        final isAr = s.isAr;

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: _bg,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleSpacing: 0,
              leading: IconButton(
                icon: Icon(
                  isAr
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.arrow_back_ios_new_rounded,
                  color: _textDark,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                s.tr('الإعدادات', 'Paramètres', 'Settings'),
                style: TextStyle(
                  color: _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing:
                      Localizations.maybeLocaleOf(context)?.languageCode == 'ar'
                          ? 0.0
                          : -0.4,
                ),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Section 1: ACCOUNT
                      _buildSectionHeader(s.tr('الحساب', 'ACCOUNT')),
                      _buildCard([
                        _buildRow(
                          icon: Icons.edit_outlined,
                          title: s.tr('تعديل الملف الشخصي', 'Edit Profile'),
                          onTap: () {
                            if (!_state.isLoggedIn) {
                              _open(const AuthScreen());
                            } else if (widget.onOpenEditProfile != null) {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              widget.onOpenEditProfile?.call();
                            }
                          },
                        ),
                        _buildRow(
                          icon: Icons.bookmark_border_rounded,
                          title: s.tr('المحتوى المحفوظ', 'Saved content'),
                          onTap: () {
                            if (!_state.isLoggedIn) {
                              _open(const AuthScreen());
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(s.tr(
                                    'قائمة الإعلانات المفضلة متوفرة في حسابك',
                                    'Les annonces favorites sont dans votre profil',
                                  )),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        _buildRow(
                          icon: Icons.notifications_none_rounded,
                          title: s.tr(
                              'إعدادات الإشعارات', 'Notification settings'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s.tr(
                                  'إشعارات التطبيق مفعلة بالكامل',
                                  'Les notifications de l’application sont activées',
                                )),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildRow(
                          icon: Icons.lock_outline,
                          title: s.tr('تغيير كلمة المرور', 'Change password'),
                          onTap: () => _open(const AccountSecurityScreen()),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Section 2: OTHER SETTING
                      _buildSectionHeader(
                          s.tr('إعدادات أخرى', 'OTHER SETTING')),
                      _buildCard([
                        _buildRow(
                          icon: Icons.article_outlined,
                          title: s.tr('الشروط والأحكام', 'Terms & conditions'),
                          onTap: () => _open(
                              const PrivacyComplianceScreen(initialTab: 0)),
                        ),
                        _buildRow(
                          icon: Icons.folder_outlined,
                          title: s.tr('سياسة الخصوصية', 'Privacy policy'),
                          onTap: () => _open(
                              const PrivacyComplianceScreen(initialTab: 0)),
                        ),
                        _buildRow(
                          icon: Icons.help_outline,
                          title: s.tr('المساعدة والدعم', 'Help & support'),
                          onTap: () => _open(const SupportScreen()),
                        ),
                        _buildRow(
                          icon: Icons.language_rounded,
                          title: s.tr('لغة التطبيق', 'Langue', 'Language'),
                          trailingLabel: s.isAr
                              ? 'العربية'
                              : (s.isEn ? 'English' : 'Français'),
                          onTap: _busy ? null : _language,
                        ),
                        if (_state.isLoggedIn)
                          _buildRow(
                            icon: Icons.delete_outline_rounded,
                            title: s.tr('تعطيل الحساب', 'Deactivate account'),
                            isDanger: true,
                            showChevron: false,
                            onTap: () => _open(
                                const PrivacyComplianceScreen(initialTab: 1)),
                          ),
                      ]),

                      const SizedBox(height: 32),

                      // Bottom Pill Button (LOGIN / LOGOUT)
                      Container(
                        width: double.infinity,
                        height: 54,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                          key: ValueKey(_state.isLoggedIn
                              ? 'settings-logout'
                              : 'settings-login'),
                          onPressed: _busy
                              ? null
                              : (_state.isLoggedIn
                                  ? _logout
                                  : () => _open(const AuthScreen())),
                          style: TextButton.styleFrom(
                            backgroundColor: _lightRedBg,
                            foregroundColor: _red,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: Text(
                            (_state.isLoggedIn ? s.logout : s.login)
                                .toUpperCase(),
                            style: TextStyle(
                              color: _red,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing:
                                  Localizations.maybeLocaleOf(context)
                                              ?.languageCode ==
                                          'ar'
                                      ? 0.0
                                      : 0.8,
                            ),
                          ),
                        ),
                      ),

                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, bottom: 10, top: 6),
      child: Text(
        title,
        style: TextStyle(
          color: _sectionLabel,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing:
              Localizations.maybeLocaleOf(context)?.languageCode == 'ar'
                  ? 0.0
                  : 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final list = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i < children.length - 1) {
        list.add(
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 52, end: 16),
            child: Divider(height: 1, thickness: 1, color: _divider),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: list),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? trailingLabel,
    bool isDanger = false,
    bool showChevron = true,
  }) {
    final textColor = isDanger ? _red : _textDark;
    final iconColor = isDanger ? _red : _textDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: isDanger ? FontWeight.w500 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel,
                  style: const TextStyle(
                    color: _sectionLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (showChevron)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _textDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
