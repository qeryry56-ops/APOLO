import 'package:flutter/material.dart';

import '../core/state/app_state.dart';
import 'account_security_screen.dart';
import 'auth_screen.dart';
import 'privacy_compliance_screen.dart';
import 'support_screen.dart';

/// A modern, minimalist settings screen faithfully implementing the Figma design:
/// - Light clean canvas background (#F8F9FA)
/// - Grouped rounded card containers (16px border radius)
/// - Section 1 "ACCOUNT": Edit Profile, Saved content, Notification settings, Change password
/// - Section 2 "OTHER SETTING": App Language, Terms & conditions, Privacy policy, Help & Support, Deactivate account
/// - Soft red pill action button at the bottom (LOGIN / LOGOUT)
/// - Interactive, responsive, and bidirectional (RTL / Arabic support)
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
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _sectionLabel = Color(0xFF8E95A5);
  static const Color _divider = Color(0xFFF1F5F9);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _dangerBg = Color(0xFFFEE2E2);

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
        setState(() => _error = _state.s.tr(
            'تعذر حفظ اللغة. أعد المحاولة.',
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
            style: FilledButton.styleFrom(backgroundColor: _danger),
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
        setState(() => _error = s.tr(
            'تعذر إغلاق الجلسة المحلية. أعد المحاولة.',
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
                  isAr ? Icons.chevron_right : Icons.chevron_left,
                  color: _textPrimary,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                s.tr('الإعدادات', 'Setting'),
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      // Section 1: ACCOUNT
                      _buildSectionTitle(s.tr('الحساب', 'ACCOUNT')),
                      _buildCard([
                        _buildItem(
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
                        _buildItem(
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
                        _buildItem(
                          icon: Icons.notifications_none_rounded,
                          title: s.tr('إعدادات الإشعارات', 'Notification settings'),
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
                        _buildItem(
                          icon: Icons.lock_outline,
                          title: s.tr('أمان الحساب وكلمة المرور', 'Change password'),
                          onTap: () => _open(const AccountSecurityScreen()),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Section 2: OTHER SETTING
                      _buildSectionTitle(s.tr('إعدادات أخرى', 'OTHER SETTING')),
                      _buildCard([
                        _buildItem(
                          icon: Icons.language_rounded,
                          title: s.tr('لغة التطبيق', 'App Language'),
                          trailingText: s.isAr ? 'العربية' : 'Français',
                          onTap: _busy ? null : _language,
                        ),
                        _buildItem(
                          icon: Icons.article_outlined,
                          title: s.tr('الشروط والأحكام', 'Terms & conditions'),
                          onTap: () => _open(const PrivacyComplianceScreen(initialTab: 0)),
                        ),
                        _buildItem(
                          icon: Icons.policy_outlined,
                          title: s.tr('سياسة الخصوصية', 'Privacy policy'),
                          onTap: () => _open(const PrivacyComplianceScreen(initialTab: 0)),
                        ),
                        _buildItem(
                          icon: Icons.help_outline,
                          title: s.tr('المساعدة والدعم', 'Help & Support'),
                          onTap: () => _open(const SupportScreen()),
                        ),
                        if (_state.isLoggedIn)
                          _buildItem(
                            icon: Icons.delete_outline,
                            title: s.tr('تعطيل الحساب', 'Deactivate account'),
                            isDanger: true,
                            showChevron: false,
                            onTap: () => _open(const PrivacyComplianceScreen(initialTab: 1)),
                          ),
                      ]),

                      const SizedBox(height: 32),

                      // Bottom Pill Button (LOGIN / LOGOUT)
                      SizedBox(
                        height: 52,
                        child: TextButton(
                          key: ValueKey(_state.isLoggedIn ? 'settings-logout' : 'settings-login'),
                          onPressed: _busy
                              ? null
                              : (_state.isLoggedIn
                                  ? _logout
                                  : () => _open(const AuthScreen())),
                          style: TextButton.styleFrom(
                            backgroundColor: _dangerBg,
                            foregroundColor: _danger,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: Text(
                            _state.isLoggedIn ? s.logout.toUpperCase() : s.login.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
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
                                color: _danger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _sectionLabel,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final list = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i < children.length - 1) {
        list.add(const Divider(height: 1, thickness: 1, color: _divider));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: list),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? trailingText,
    bool isDanger = false,
    bool showChevron = true,
  }) {
    final color = isDanger ? _danger : _textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText,
                  style: const TextStyle(
                    color: _sectionLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (showChevron)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
