import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'account_security_screen.dart';
import 'auth_screen.dart';
import 'privacy_compliance_screen.dart';
import 'support_screen.dart';
import 'widgets/marketplace_zone_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenEditProfile;
  const SettingsScreen({super.key, this.onOpenEditProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _state = AppState();
  bool _busy = false;
  bool _activeStatusOn = true;
  bool _notificationsOn = false;
  String? _error;

  static const Color _bg = Color(0xFFF2F3F7);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF0A0A0A);
  static const Color _sectionLabel = Color(0xFF6B7280);
  static const Color _trailingMuted = Color(0xFF8E8E93);
  static const Color _divider = Color(0xFFF1F2F6);
  static const Color _blueDot = Color(0xFF0866FF);
  static const Color _red = Color(0xFFE31828);
  static const Color _lightRedBg = Color(0xFFFDE8E8);

  Future<void> _language() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
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

  void _handleEditProfileTap() {
    HapticFeedback.selectionClick();
    if (!_state.isLoggedIn) {
      _open(const AuthScreen());
    } else if (widget.onOpenEditProfile != null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      widget.onOpenEditProfile?.call();
    }
  }

  String _resolveHandle() {
    final raw = (_state.currentUser?['username'] ?? '').toString().trim();
    if (raw.isNotEmpty && raw.toLowerCase() != 'amine') {
      return raw.startsWith('@') ? raw : '@$raw';
    }
    return '@apolo_user';
  }

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
              toolbarHeight: 44,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  isAr
                      ? CupertinoIcons.chevron_right
                      : CupertinoIcons.chevron_left,
                  color: _textDark,
                  size: 22,
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                s.tr('الإعدادات', 'Paramètres', 'Settings'),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      // Group 1: Top System & Privacy Card (5 rows, no section title above)
                      _buildCard(
                        isAr: isAr,
                        children: [
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.circle_filled,
                            title: s.tr(
                                'حالة النشاط', 'Statut en ligne', 'Active Status'),
                            trailingLabel: _activeStatusOn
                                ? s.tr('مفعل', 'Activé', 'On')
                                : s.tr('متوقف', 'Désactivé', 'Off'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(
                                  () => _activeStatusOn = !_activeStatusOn);
                            },
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.moon_fill,
                            title:
                                s.tr('المظهر الداكن', 'Mode sombre', 'Dark mode'),
                            trailingLabel:
                                s.tr('تلقائي', 'Système', 'System'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(s.tr(
                                    'المظهر يتبع إعدادات النظام تلقائياً',
                                    'Le thème suit automatiquement le système',
                                    'Theme automatically follows system mode',
                                  )),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.globe,
                            title: s.tr(
                                'لغة التطبيق', 'Langue de l’app', 'App icon & language'),
                            trailingLabel: s.isAr
                                ? 'العربية'
                                : (s.isEn ? 'English' : 'Français'),
                            onTap: _busy ? null : _language,
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: Icons.accessibility_new_rounded,
                            title: s.tr('المنطقة وإمكانية الوصول',
                                'Accessibilité', 'Accessibility'),
                            onTap: () => showMarketplaceZoneSheet(context),
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: Icons.lock_outline,
                            title: s.tr('الخصوصية والأمان',
                                'Confidentialité et sécurité', 'Privacy & safety'),
                            showBlueDot: true,
                            onTap: () => _open(const AccountSecurityScreen()),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Group 2: Standalone Single-Row Card (Family Centre / Account Centre)
                      _buildCard(
                        isAr: isAr,
                        children: [
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.house_fill,
                            title: s.tr(
                                'مركز الحساب والعائلة',
                                'Centre famille et compte',
                                'Family Centre'),
                            onTap: _handleEditProfileTap,
                          ),
                        ],
                      ),

                      // Group 3: Preferences Section
                      _buildSectionHeader(
                        s.tr('التفضيلات', 'Préférences', 'Preferences'),
                      ),
                      _buildCard(
                        isAr: isAr,
                        children: [
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.person_crop_circle_fill,
                            title: s.tr(
                                'الصورة الشخصية', 'Avatar', 'Avatar'),
                            onTap: _handleEditProfileTap,
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.at,
                            title: s.tr('اسم المستخدم', 'Nom d’utilisateur',
                                'Username'),
                            trailingLabel: _resolveHandle(),
                            onTap: _handleEditProfileTap,
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.bell_fill,
                            title: s.tr('الإشعارات والأصوات',
                                'Notifications et sons', 'Notifications and sounds'),
                            trailingLabel: _notificationsOn
                                ? s.tr('مفعل', 'Activé', 'On')
                                : s.tr('متوقف', 'Désactivé', 'Off'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() =>
                                  _notificationsOn = !_notificationsOn);
                            },
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.bag_fill,
                            title: s.tr(
                                'الطلبات والمحفوظات', 'Commandes', 'Orders'),
                            onTap: () {
                              if (!_state.isLoggedIn) {
                                _open(const AuthScreen());
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(s.tr(
                                      'قائمة الإعلانات المفضلة والطلبات متوفرة في حسابك',
                                      'Vos favoris et commandes sont dans votre profil',
                                      'Your saved items and orders are in your profile',
                                    )),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.photo_fill,
                            title: s.tr('الصور والوسائط', 'Photos et médias',
                                'Photos and media'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(s.tr(
                                    'جودة الصور العالية مفعلة تلقائياً',
                                    'La qualité HD des photos est activée',
                                    'High-resolution media upload is enabled',
                                  )),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      // Group 4: Account and support
                      _buildSectionHeader(
                        s.tr('الحساب والدعم', 'Compte et assistance',
                            'Account and support'),
                      ),
                      _buildCard(
                        isAr: isAr,
                        children: [
                          _buildRow(
                            isAr: isAr,
                            icon: Icons.help_outline,
                            title: s.tr('الإبلاغ عن مشكلة',
                                'Signaler un problème', 'Report a problem'),
                            onTap: () => _open(const SupportScreen()),
                          ),
                          _buildRow(
                            isAr: isAr,
                            icon: CupertinoIcons.doc_text_fill,
                            title: s.tr('الشروط وسياسة الخصوصية',
                                'Conditions et confidentialité', 'Terms & privacy'),
                            onTap: () => _open(
                                const PrivacyComplianceScreen(initialTab: 0)),
                          ),
                          if (_state.isLoggedIn)
                            _buildRow(
                              isAr: isAr,
                              icon: CupertinoIcons.trash_fill,
                              title: s.tr('تعطيل الحساب',
                                  'Désactiver le compte', 'Deactivate account'),
                              isDanger: true,
                              showChevron: false,
                              onTap: () => _open(
                                  const PrivacyComplianceScreen(initialTab: 1)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Bottom Pill Button (LOGIN / LOGOUT)
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: isAr ? 0.0 : 0.6,
                            ),
                          ),
                        ),
                      ),

                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),

                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 10, bottom: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: _sectionLabel,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isAr,
    required List<Widget> children,
  }) {
    final list = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i < children.length - 1) {
        list.add(
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 48, end: 14),
            child: Divider(height: 1, thickness: 1, color: _divider),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: list),
    );
  }

  Widget _buildRow({
    required bool isAr,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? trailingLabel,
    bool showBlueDot = false,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (showBlueDot) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _blueDot,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel,
                  textDirection: trailingLabel.startsWith('@')
                      ? TextDirection.ltr
                      : null,
                  style: const TextStyle(
                    color: _trailingMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (showChevron)
                Icon(
                  isAr
                      ? CupertinoIcons.chevron_left
                      : CupertinoIcons.chevron_right,
                  size: 15,
                  color: _trailingMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
