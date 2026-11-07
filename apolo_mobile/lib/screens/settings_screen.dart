import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'privacy_compliance_screen.dart';
import 'widgets/kinetic_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenEditProfile;

  const SettingsScreen({super.key, this.onOpenEditProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppState _state = AppState();

  bool _whatsappEnabled = true;
  bool _showPhoneOnAds = true;
  bool _priceAlertsEnabled = true;

  static const Color _primary = Color(0xFFE31B23);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _hairline = Color(0xFFECEEF2);

  @override
  void initState() {
    super.initState();
    _loadSettingsPrefs();
  }

  Future<void> _loadSettingsPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _whatsappEnabled = prefs.getBool('apolo_pref_whatsapp') ?? true;
        _showPhoneOnAds = prefs.getBool('apolo_pref_show_phone') ?? true;
        _priceAlertsEnabled = prefs.getBool('apolo_pref_price_alerts') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _saveBoolPref(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final user = _state.currentUser;
    final name = user?['name']?.toString() ?? (isAr ? 'أمين' : 'Amine');
    final handle = user?['username']?.toString() ??
        user?['email']?.toString().split('@').first ??
        'amine';
    final isPro = _state.accountType == 'pro' || _state.accountType == 'store';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
              color: _ink,
              size: 22,
            ),
          ),
          title: Text(
            isAr ? 'الإعدادات' : 'Paramètres',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
          children: [
            // 1. Account Identity Card
            ScrollReveal(
              child: PressableScale(
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenEditProfile?.call();
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _hairline),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _ink,
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  color: _primary,
                                  size: 15,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '@$handle · ${isAr ? 'تعديل الصورة، الاسم والـ Bio' : 'Photo, nom et bio'}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: _muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
                        size: 16,
                        color: _muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Account & Store Type
            _buildSectionTitle(isAr ? 'الحساب والمتجر' : 'Compte & Boutique'),
            const SizedBox(height: 8),
            _buildGroupCard([
              _buildRowTile(
                isAr: isAr,
                icon: CupertinoIcons.person_crop_circle,
                title: isAr ? 'تعديل البروفايل' : 'Modifier le profil',
                trailingText: isAr ? 'الصورة والـ Bio' : 'Photo & Bio',
                onTap: () {
                  Navigator.pop(context);
                  widget.onOpenEditProfile?.call();
                },
              ),
              _buildDivider(),
              _buildRowTile(
                isAr: isAr,
                icon: CupertinoIcons.bag,
                title: isAr ? 'نوع الحساب' : 'Type de compte',
                trailingText: isPro
                    ? (isAr ? 'متجر Pro' : 'Boutique Pro')
                    : (isAr ? 'حساب فردي' : 'Particulier'),
                onTap: () async {
                  final nextType = isPro ? 'individual' : 'pro';
                  await _state.saveOnboardingPreferences(
                    accType: nextType,
                    cityId: _state.preferredCityId,
                    selectedCategories: _state.categoryInterestWeights.keys.toSet(),
                  );
                  if (mounted) setState(() {});
                },
              ),
              if (!_state.isLoggedIn) ...[
                _buildDivider(),
                _buildRowTile(
                  isAr: isAr,
                  icon: CupertinoIcons.lock_shield,
                  title: isAr ? 'تسجيل الدخول أو إنشاء حساب' : 'Connexion / Inscription',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  }),
                ),
              ],
            ]),

            const SizedBox(height: 24),

            // Section 2: Language & Smart Feed Algorithm
            _buildSectionTitle(isAr ? 'اللغة وخوارزمية العرض' : 'Langue & Algorithme du flux'),
            const SizedBox(height: 8),
            _buildGroupCard([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.globe, color: _ink, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAr ? 'لغة التطبيق' : 'Langue de l’application',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                    _buildLanguagePill('ar', 'العربية', isAr),
                    const SizedBox(width: 6),
                    _buildLanguagePill('fr', 'Français', !isAr),
                  ],
                ),
              ),
              _buildDivider(),
              _buildRowTile(
                isAr: isAr,
                icon: CupertinoIcons.sparkles,
                title: isAr
                    ? 'إعادة ضبط اهتمامات الـ Feed الذكي'
                    : 'Réinitialiser mes recommandations',
                trailingText: '${_state.categoryInterestWeights.length}',
                onTap: () async {
                  _state.categoryInterestWeights.clear();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('apolo_interest_weights');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم تصفير خوارزمية الاهتمامات بنجاح'
                            : 'Vos préférences de flux ont été réinitialisées',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() {});
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Section 3: Notifications & Contact Privacy
            _buildSectionTitle(isAr ? 'الإشعارات والتواصل' : 'Notifications & Contact'),
            const SizedBox(height: 8),
            _buildGroupCard([
              _buildRowTile(
                isAr: isAr,
                icon: CupertinoIcons.bell,
                title: isAr ? 'مركز الإشعارات وحالة الاتصال' : 'Centre de notifications',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: CupertinoIcons.chat_bubble_2,
                title: isAr ? 'استقبال عروض المشترين عبر واتساب' : 'Recevoir les offres via WhatsApp',
                value: _whatsappEnabled,
                onChanged: (v) {
                  setState(() => _whatsappEnabled = v);
                  _saveBoolPref('apolo_pref_whatsapp', v);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: CupertinoIcons.phone,
                title: isAr ? 'إظهار رقم الهاتف في إعلاناتي' : 'Afficher mon numéro sur mes annonces',
                value: _showPhoneOnAds,
                onChanged: (v) {
                  setState(() => _showPhoneOnAds = v);
                  _saveBoolPref('apolo_pref_show_phone', v);
                },
              ),
              _buildDivider(),
              _buildSwitchTile(
                icon: CupertinoIcons.tag,
                title: isAr ? 'تنبيهات تخفيض الأسعار' : 'Alertes baisse de prix',
                value: _priceAlertsEnabled,
                onChanged: (v) {
                  setState(() => _priceAlertsEnabled = v);
                  _saveBoolPref('apolo_pref_price_alerts', v);
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Section 4: Legal, Privacy & Account Deletion (Google Play 2026 Compliance)
            _buildSectionTitle(isAr ? 'الخصوصية والأمان' : 'Confidentialité & Sécurité'),
            const SizedBox(height: 8),
            _buildGroupCard([
              _buildRowTile(
                isAr: isAr,
                icon: CupertinoIcons.flag,
                title: isAr ? 'التبليغ عن محتوى الذكاء الاصطناعي' : 'Signaler un contenu IA',
                onTap: () => showAiContentReportSheet(
                  context,
                  featureContext: 'Settings AI Report',
                ),
              ),
              _buildDivider(),
              _buildRowTile(
                isAr: isAr,
                icon: CupertinoIcons.doc_text,
                title: isAr ? 'سياسة الخصوصية وشروط الاستخدام' : 'Politique de confidentialité',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyComplianceScreen(initialTab: 0),
                  ),
                ),
              ),
              _buildDivider(),
              _buildRowTile(
                isAr: isAr,
                icon: CupertinoIcons.trash,
                title: isAr ? 'حذف الحساب والبيانات نهائياً' : 'Supprimer mon compte',
                titleColor: _primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyComplianceScreen(initialTab: 1),
                  ),
                ),
              ),
            ]),

            if (_state.isLoggedIn) ...[
              const SizedBox(height: 28),
              PressableScale(
                onTap: () async {
                  await _state.logout();
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    s.logout,
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),
            Center(
              child: Text(
                'Apolo.ma · 2026 Edition (API 36)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _muted.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: _muted,
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 48),
      child: Divider(height: 1, thickness: 1, color: _hairline),
    );
  }

  Widget _buildRowTile({
    required bool isAr,
    required IconData icon,
    required String title,
    String? trailingText,
    Color titleColor = _ink,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: titleColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              isAr ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right,
              size: 15,
              color: _muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _ink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: _primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(String code, String label, bool selected) {
    return GestureDetector(
      onTap: () async {
        if (!selected) {
          await _state.toggleLanguage();
          if (mounted) setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _ink : _bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
