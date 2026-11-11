import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';

/// Opens an in-app modal bottom sheet allowing the user to report AI-generated
/// content or listings without leaving the app (Google Play 2026 AI Policy).
Future<void> showAiContentReportSheet(
  BuildContext context, {
  String? featureContext,
}) async {
  final state = AppState();
  final s = state.s;
  final notesCtrl = TextEditingController();
  int selectedReason = 0;
  bool submitting = false;

  final reasons = <Map<String, String>>[
    {
      'ar': 'محتوى ذكاء اصطناعي غير دقيق أو مضلل',
      'fr': 'Contenu IA inexact ou trompeur',
    },
    {
      'ar': 'محتوى مسيء أو غير لائق أو مخالف للسياسات',
      'fr': 'Contenu offensant, inapproprié ou interdit',
    },
    {
      'ar': 'إعلان احتيالي أو انتهاك لحقوق الملكية',
      'fr': 'Annonce frauduleuse ou violation de droits',
    },
    {
      'ar': 'خلل تقني في اقتراحات المساعد الذكي',
      'fr': 'Problème technique avec l\'assistant IA',
    },
  ];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEECEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.flag_fill,
                        color: Color(0xFFE31B23),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.tr(
                              'الإبلاغ عن محتوى الذكاء الاصطناعي (AI)',
                              'Signaler un contenu IA',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F1B2D),
                            ),
                          ),
                          if (featureContext != null &&
                              featureContext.isNotEmpty)
                            Text(
                              featureContext,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A94A6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  s.tr(
                    'نلتزم بسلامة المحتوى وفق معايير Google Play. اختر سبب البلاغ ليتم فحصه فوراً داخل التطبيق:',
                    'Conformément aux règles Google Play sur l\'IA, sélectionnez le motif du signalement :',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5A6475),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(reasons.length, (idx) {
                  final active = selectedReason == idx;
                  final label =
                      s.isAr ? reasons[idx]['ar']! : reasons[idx]['fr']!;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setModalState(() => selectedReason = idx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFFEECEE)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active
                              ? const Color(0xFFE31B23)
                              : const Color(0xFFE5E7EB),
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            active
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            size: 19,
                            color: active
                                ? const Color(0xFFE31B23)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w600,
                                color: const Color(0xFF0F1B2D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: s.tr(
                      'أضف تفاصيل إضافية (اختياري)...',
                      'Détails supplémentaires (optionnel)...',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31B23),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: submitting
                        ? null
                        : () async {
                            setModalState(() => submitting = true);
                            final chosen = s.isAr
                                ? reasons[selectedReason]['ar']!
                                : reasons[selectedReason]['fr']!;
                            try {
                              final response = await state.api.dio.post(
                                '/reports',
                                data: {
                                  'type': 'ai_content',
                                  'reason': chosen,
                                  'context':
                                      featureContext ?? 'app_ai_assistant',
                                  'details': notesCtrl.text.trim(),
                                },
                              );
                              if (response.data is! Map ||
                                  response.data['status'] != 'success') {
                                throw StateError('Report not confirmed');
                              }
                            } catch (_) {
                              if (ctx.mounted) {
                                setModalState(() => submitting = false);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(s.tr(
                                      'تعذر إرسال البلاغ. حاول مجدداً.',
                                      'Signalement non envoyé. Réessayez.')),
                                ));
                              }
                              return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppConfig.success,
                                  content: Text(
                                    s.tr(
                                      'تم إرسال بلاغك بنجاح داخل التطبيق. شكراً لمساهمتك في أمان مجتمع Apolo.ma ✓',
                                      'Signalement envoyé avec succès. Merci de contribuer à la sécurité d\'Apolo.ma ✓',
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(CupertinoIcons.paperplane_fill, size: 17),
                    label: Text(
                      submitting
                          ? s.tr('جاري الإرسال...', 'Envoi en cours...')
                          : s.tr('إرسال البلاغ الآن', 'Envoyer le signalement'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class PrivacyComplianceScreen extends StatefulWidget {
  final int initialTab;
  const PrivacyComplianceScreen({super.key, this.initialTab = 0});

  @override
  State<PrivacyComplianceScreen> createState() =>
      _PrivacyComplianceScreenState();
}

class _PrivacyComplianceScreenState extends State<PrivacyComplianceScreen> {
  final AppState _state = AppState();
  late int _selectedTab;
  bool _deleting = false;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _red = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE7EAF0);

  static const String privacyUrl = 'https://apolo.ma/privacy.html';
  static const String deleteAccountUrl = 'https://apolo.ma/delete-account.html';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No URL handler');
      }
    } catch (_) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _state.s.tr('تم نسخ الرابط: $url', 'Lien copié : $url'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleInAppAccountDeletion() async {
    if (_deleting || !_state.isLoggedIn) return;
    setState(() => _deleting = true);
    final userId = _state.currentUser?['id'];
    final s = _state.s;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            s.tr('تأكيد حذف الحساب نهائياً',
                'Confirmer la suppression du compte'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            s.tr(
              'هل أنت متأكد من حذف حسابك وجميع بياناتك الشخصية وإعلاناتك ومحادثاتك نهائياً من خوادم Apolo.ma؟ لا يمكن التراجع عن هذا الإجراء.',
              'Voulez-vous vraiment supprimer définitivement votre compte, vos données personnelles, vos annonces et vos messages des serveurs Apolo.ma ?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.tr('إلغاء', 'Annuler')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                s.tr('حذف حسابي وبياناتي', 'Supprimer définitivement'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true ||
          !mounted ||
          !_state.isLoggedIn ||
          userId != _state.currentUser?['id']) {
        return;
      }
      final response = await _state.api.dio.delete('/auth/account');
      if (response.statusCode != 204 &&
          (response.data is! Map || response.data['status'] != 'success')) {
        throw StateError('Account deletion not confirmed');
      }
      if (userId != _state.currentUser?['id']) return;
      await _state.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppConfig.success,
        content: Text(s.tr('تم حذف الحساب والبيانات بنجاح.',
            'Votre compte et vos données ont été supprimés.')),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.tr(
              'تعذر تأكيد حذف الحساب. لم يتم تسجيل خروجك. حاول مجدداً.',
              'Suppression non confirmée. Vous restez connecté. Réessayez.')),
        ));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _ink,
        title: Text(
          s.tr(
            'الخصوصية وحماية البيانات',
            'Confidentialité & Protection des données',
          ),
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                _buildTabPill(
                  0,
                  s.tr('سياسة الخصوصية', 'Confidentialité'),
                  CupertinoIcons.shield_lefthalf_fill,
                ),
                const SizedBox(width: 8),
                _buildTabPill(
                  1,
                  s.tr('حذف الحساب والبيانات', 'Suppression du compte'),
                  CupertinoIcons.trash_fill,
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildPrivacyPolicyView(s)
                : _buildDeleteAccountView(s),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(int idx, String label, IconData icon) {
    final active = _selectedTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
          decoration: BoxDecoration(
            color: active ? _red : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : _ink,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyView(AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          icon: CupertinoIcons.checkmark_shield_fill,
          title: s.tr(
            '1. البيانات التي نجمعها (Data Collection)',
            '1. Données que nous collectons',
          ),
          body: s.tr(
            '• معلومات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف، أو معرف تسجيل الدخول عبر Google OAuth عند إنشاء حساب.\n'
                '• محتوى الإعلانات: الصور، العناوين، الأوصاف، الأسعار، والمدينة التي تختارها لنشر إعلانك.\n'
                '• الرسائل والمحادثات: الرسائل المتبادلة بين البائع والمشتري داخل نظام الدردشة الآمن في التطبيق.\n'
                '• البيانات التقنية: نوع الجهاز ومعرف الإشعارات لتحسين الأداء وإرسال تنبيهات الرسائل.',
            '• Informations de compte : Nom, adresse e-mail, numéro de téléphone ou identifiant Google OAuth.\n'
                '• Contenu des annonces : Photos, titres, descriptions, prix et ville choisie.\n'
                '• Messagerie : Messages échangés entre acheteurs et vendeurs.\n'
                '• Données techniques : Informations d\'appareil pour la sécurité et les notifications.',
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          icon: CupertinoIcons.gear_alt_fill,
          title: s.tr(
            '2. كيف نستخدم بياناتك (How We Use Data)',
            '2. Comment nous utilisons vos données',
          ),
          body: s.tr(
            '• تمكين نشر وإدارة الإعلانات المبوبة والمتاجر الإلكترونية على منصة Apolo.ma.\n'
                '• تسهيل التواصل المباشر والآمن بين المشترين والبائعين.\n'
                '• حماية المنصة من الإعلانات الاحتيالية أو المحتوى المسيء ومراجعة بلاغات المستخدمين.\n'
                '• لا نقوم ببيع أو تأجير بياناتك الشخصية لأي طرف ثالث لأغراض إعلانية.',
            '• Publier et gérer vos annonces et boutiques sur Apolo.ma.\n'
                '• Permettre la communication directe entre acheteurs et vendeurs.\n'
                '• Prévenir la fraude et modérer les contenus signalés.\n'
                '• Nous ne vendons jamais vos données personnelles à des tiers.',
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          icon: CupertinoIcons.sparkles,
          title: s.tr(
            '3. الذكاء الاصطناعي والإبلاغ عن المحتوى (AI Safety)',
            '3. Intelligence Artificielle & Signalement',
          ),
          body: s.tr(
            'يوفر التطبيق أدوات مساعدة ذكية لتنظيم الإعلانات والبحث. يمكنك في أي وقت الإبلاغ عن أي محتوى ذكاء اصطناعي أو إعلان غير لائق مباشرة من داخل التطبيق عبر زر الإبلاغ دون مغادرة التطبيق.',
            'L\'application intègre un bouton de signalement direct permettant de signaler tout contenu généré par IA ou toute annonce inappropriée sans quitter l\'application.',
          ),
        ),
        const SizedBox(height: 14),
        _buildInfoCard(
          icon: CupertinoIcons.mail_solid,
          title: s.tr(
            '4. التواصل معنا وحقوق المستخدم (Contact & CNDP)',
            '4. Nous contacter & Vos droits',
          ),
          body: s.tr(
            'وفقاً للقانون المغربي 09-08 المتعلق بحماية الأشخاص الذاتيين تجاه معالجة المعطيات ذات الطابع الشخصي ومتطلبات Google Play:\n'
                '• البريد الإلكتروني للدعم والخصوصية: support@apolo.ma / contact@apolo.ma\n'
                '• الموقع الرسمي: https://apolo.ma\n'
                '• يحق لك طلب الاطلاع على بياناتك أو تعديلها أو حذفها نهائياً في أي وقت.',
            'Conformément à la loi 09-08 et aux exigences Google Play :\n'
                '• Email : support@apolo.ma / contact@apolo.ma\n'
                '• Site officiel : https://apolo.ma\n'
                '• Vous disposez d\'un droit d\'accès, de rectification et de suppression définitive.',
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => _openExternalUrl(privacyUrl),
          icon: const Icon(CupertinoIcons.globe, size: 18, color: _red),
          label: Text(
            s.tr(
              'فتح رابط سياسة الخصوصية الخارجي (Web URL)',
              'Ouvrir le lien externe de Politique de Confidentialité',
            ),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => showAiContentReportSheet(
            context,
            featureContext: 'Privacy & AI Compliance Center',
          ),
          icon: const Icon(CupertinoIcons.flag_fill, size: 17),
          label: Text(
            s.tr(
              'الإبلاغ عن محتوى الذكاء الاصطناعي (AI) داخل التطبيق',
              'Signaler un contenu IA dans l\'application',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountView(AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEECEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.trash_fill,
                      color: _red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.tr(
                        'حذف الحساب والبيانات الشخصية نهائياً',
                        'Suppression définitive du compte et des données',
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                s.tr(
                  'عند حذف حسابك، يتم مسح البيانات التالية نهائياً وبشكل فوري:\n'
                      '• معلومات الملف الشخصي (الاسم، البريد الإلكتروني، رقم الهاتف).\n'
                      '• جميع الإعلانات المنشورة والصور المرتبطة بها.\n'
                      '• سجل المحادثات والرسائل والتنبيهات المحفوظة.\n\n'
                      'يمكنك تنفيذ الحذف مباشرة من داخل التطبيق بالزر أدناه، أو عبر الرابط الخارجي المخصص لحذف البيانات على الويب:',
                  'La suppression de votre compte entraîne l\'effacement définitif de :\n'
                      '• Vos informations personnelles (nom, e-mail, téléphone).\n'
                      '• Toutes vos annonces publiées et photos.\n'
                      '• Votre historique de messages et favoris.\n\n'
                      'Vous pouvez supprimer votre compte directement ci-dessous ou via notre formulaire web externe :',
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  key: const Key('privacy-delete-account'),
                  onPressed: _deleting || !_state.isLoggedIn
                      ? null
                      : _handleInAppAccountDeletion,
                  icon: const Icon(CupertinoIcons.trash, size: 18),
                  label: Text(
                    s.tr(
                      'حذف حسابي وجميع بياناتي الآن (داخل التطبيق)',
                      'Supprimer mon compte maintenant (In-App)',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _openExternalUrl(deleteAccountUrl),
                  icon: const Icon(
                    CupertinoIcons.arrow_up_right_square,
                    size: 18,
                    color: _red,
                  ),
                  label: Text(
                    s.tr(
                      'رابط حذف الحساب والبيانات على الموقع (Web)',
                      'Lien web externe de suppression des données',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              color: _muted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
