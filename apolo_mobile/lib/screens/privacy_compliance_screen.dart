import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/state/app_state.dart';
import '../widgets/dl_settings_kit.dart';
import '../l10n/l10n.dart';

/// Opens an in-app Dynamic Layer v5.1 modal bottom sheet allowing the user to
/// report AI-generated content or policy violations without leaving the app
/// (Apple App Store & Google Play 2026 Compliance).
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
      'en': 'Inaccurate or misleading AI content',
    },
    {
      'ar': 'محتوى مسيء أو غير لائق أو مخالف للسياسات',
      'fr': 'Contenu offensant, inapproprié ou interdit',
      'en': 'Offensive, inappropriate, or prohibited content',
    },
    {
      'ar': 'إعلان احتيالي أو انتهاك لشروط المنصة',
      'fr': 'Annonce frauduleuse ou violation des règles',
      'en': 'Fraudulent listing or policy violation',
    },
    {
      'ar': 'خلل تقني في اقتراحات المساعد الذكي',
      'fr': 'Problème technique avec l’assistant IA',
      'en': 'Technical issue with AI suggestions',
    },
  ];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
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
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEEEEEE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          CupertinoIcons.flag_fill,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.tr(
                                'الإبلاغ عن محتوى أو مخالفة',
                                'Signaler un contenu IA / Règles',
                                appL10n.privacyComplianceReportAiPolicyIssue,
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            if (featureContext != null &&
                                featureContext.isNotEmpty)
                              Text(
                                featureContext,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ApoloDlIconCircleButton(
                        icon: CupertinoIcons.xmark,
                        iconSize: 16,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.tr(
                      'نلتزم بسلامة المحتوى وفق معايير App Store و Google Play. اختر سبب البلاغ للمراجعة الفورية:',
                      'Conformément aux règles App Store et Google Play, sélectionnez le motif du signalement :',
                      appL10n.privacyComplianceSelectReasonSubmitThisReport,
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF757575),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(reasons.length, (idx) {
                    final active = selectedReason == idx;
                    final label = s.tr(
                      reasons[idx]['ar']!,
                      reasons[idx]['fr']!,
                      reasons[idx]['en']!,
                    );
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setModalState(() => selectedReason = idx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFEEEEEE)
                              : const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            ApoloDlRadio(selected: active),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      cursorColor: Colors.black,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: s.tr(
                          'أضف تفاصيل إضافية (اختياري)...',
                          'Détails supplémentaires (optionnel)...',
                          appL10n.privacyComplianceAdditionalDetailsOptional,
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ApoloDlButton(
                    label: submitting
                        ? s.tr('جاري الإرسال...', 'Envoi en cours...', appL10n.authSending)
                        : s.tr(
                            'إرسال البلاغ الآن',
                            'Envoyer le signalement',
                            appL10n.privacyComplianceSubmitReport,
                          ),
                    leadingIcon: CupertinoIcons.paperplane_fill,
                    variant: ApoloDlButtonVariant.primary,
                    borderRadius: 999,
                    height: 50,
                    fullWidth: true,
                    isLoading: submitting,
                    onPressed: submitting
                        ? null
                        : () async {
                            setModalState(() => submitting = true);
                            final chosen = s.tr(
                              reasons[selectedReason]['ar']!,
                              reasons[selectedReason]['fr']!,
                              reasons[selectedReason]['en']!,
                            );
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.black,
                                    content: Text(
                                      s.tr(
                                        'تعذر إرسال البلاغ. حاول مجدداً.',
                                        'Signalement non envoyé. Réessayez.',
                                        appL10n.privacyComplianceCouldNotSendReportPlease,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.black,
                                  content: Text(
                                    s.tr(
                                      'تم إرسال بلاغك بنجاح داخل التطبيق ✓',
                                      'Signalement envoyé avec succès ✓',
                                      appL10n.privacyComplianceReportSubmittedSuccessfully,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Dynamic Layer v5.1 Privacy, Terms & Account Data Center:
/// - `initialTab: 0` -> Privacy Policy (`سياسة الخصوصية`)
/// - `initialTab: 2` -> Terms & Policies (`الشروط والسياسات`)
/// - `initialTab: 1` -> Account Data & Permanent Deletion (`البيانات والحذف`)
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

  // Strict Dynamic Layer v5.1 Tokens
  static const Color _dlBg = Color(0xFFFFFFFF);
  static const Color _dlSurface = Color(0xFFF6F6F6);
  static const Color _dlPill = Color(0xFFEEEEEE);
  static const Color _dlInk = Color(0xFF000000);
  static const Color _dlMuted = Color(0xFF757575);
  static const Color _dlDanger = Color(0xFFE31B23);

  static const String privacyUrl = 'https://apolo.ma/privacy.html';
  static const String termsUrl = 'https://apolo.ma/terms.html';
  static const String deleteAccountUrl = 'https://apolo.ma/delete-account.html';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  Future<void> _openExternalUrl(String url) async {
    HapticFeedback.selectionClick();
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
            behavior: SnackBarBehavior.floating,
            backgroundColor: _dlInk,
            content: Text(
              _state.s.tr(
                'تم نسخ الرابط: $url',
                'Lien copié : $url',
                appL10n.privacyComplianceLinkCopiedUrl(url),
              ),
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
        builder: (ctx) => Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: _dlBg,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              s.tr(
                'تأكيد حذف الحساب نهائياً',
                'Confirmer la suppression du compte',
                appL10n.privacyComplianceConfirmAccountDeletion,
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _dlInk,
              ),
            ),
            content: Text(
              s.tr(
                'هل أنت متأكد من حذف حسابك وجميع بياناتك الشخصية وإعلاناتك ومحادثاتك نهائياً من خوادم Apolo.ma؟ لا يمكن التراجع عن هذا الإجراء.',
                'Voulez-vous vraiment supprimer définitivement votre compte, vos données personnelles, vos annonces et vos messages des serveurs Apolo.ma ?',
                appL10n.privacyComplianceAreYouSureYouWant,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: _dlMuted,
                height: 1.45,
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: _dlPill,
                  foregroundColor: _dlInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  s.tr('إلغاء', 'Annuler', appL10n.cancelButton),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _dlDanger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  s.tr(
                    'حذف حسابي وبياناتي',
                    'Supprimer définitivement',
                    appL10n.privacyComplianceDeletePermanently,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConfig.success,
          content: Text(
            s.tr(
              'تم حذف الحساب والبيانات بنجاح.',
              'Votre compte et vos données ont été supprimés.',
              appL10n.privacyComplianceAccountDataHaveBeenDeleted,
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _dlInk,
            content: Text(
              s.tr(
                'تعذر تأكيد حذف الحساب. لم يتم تسجيل خروجك. حاول مجدداً.',
                'Suppression non confirmée. Vous restez connecté. Réessayez.',
                appL10n.privacyComplianceCouldNotConfirmDeletionYou,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
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
            key: const Key('dl-privacy-policies-screen'),
            backgroundColor: _dlBg,
            body: SafeArea(
              child: Column(
                children: [
                  ApoloDlTopNav(
                    title: s.tr(
                      'الخصوصية والشروط',
                      'Confidentialité & Conditions',
                      appL10n.privacyCompliancePrivacyPolicies,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: Column(
                          children: [
                            // Dynamic Layer v5.1 3-Segment Pill Switcher
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                              child: Container(
                                key: const Key('dl-legal-segmented-tabs'),
                                height: 44,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _dlPill,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    _buildTabPill(
                                      key: const Key('dl-legal-tab-privacy'),
                                      tabId: 0,
                                      label: s.tr(
                                        'الخصوصية',
                                        'Confidentialité',
                                        appL10n.privacyCompliancePrivacy,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildTabPill(
                                      key: const Key('dl-legal-tab-policies'),
                                      tabId: 2,
                                      label: s.tr(
                                        'الشروط والسياسات',
                                        'Conditions',
                                        appL10n.privacyCompliancePolicies,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _buildTabPill(
                                      key: const Key('dl-legal-tab-data'),
                                      tabId: 1,
                                      label: s.tr(
                                        'حذف البيانات',
                                        'Données',
                                        appL10n.privacyComplianceDataDelete,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: switch (_selectedTab) {
                                2 => _buildPoliciesAndTermsView(s),
                                1 => _buildDeleteAccountView(s),
                                _ => _buildPrivacyPolicyView(s),
                              },
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

  Widget _buildTabPill({
    required Key key,
    required int tabId,
    required String label,
  }) {
    final active = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = tabId);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: active ? _dlInk : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : _dlInk,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHero({
    required AppStrings s,
    required IconData icon,
    required String badgeText,
    required String headline,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _dlSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _dlInk,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _dlBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _dlInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _dlInk,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13.5,
              color: _dlMuted,
              height: 1.48,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyView(AppStrings s) {
    return ListView(
      key: const Key('dl-privacy-list'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        _buildSummaryHero(
          s: s,
          icon: CupertinoIcons.lock_shield_fill,
          badgeText: s.tr(
            'محدث 2026 · القانون 09-08 (CNDP)',
            'Mis à jour 2026 · Loi 09-08 (CNDP)',
            appL10n.privacyComplianceUpdated2026Law0908,
          ),
          headline: s.tr(
            'خصوصيتك وبياناتك تحت تحكمك الكامل',
            'Vos données restent sous votre contrôle',
            appL10n.privacyCompliancePrivacyFullyControl,
          ),
          description: s.tr(
            'لا نبيع بياناتك الشخصية لأي طرف إعلاني خارجي. تُستخدم المعلومات حصرياً لتشغيل حسابك، إعلاناتك، محادثاتك، وإشعارات الهاتف على تطبيق Apolo (ma.apolo.apoloMobile).',
            'Nous ne vendons jamais vos données personnelles. Vos informations servent uniquement à vos annonces, messages et notifications sur Apolo (ma.apolo.apoloMobile).',
            appL10n.privacyComplianceWeNeverSellPersonalData,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          number: '01',
          icon: CupertinoIcons.person_crop_circle_badge_checkmark,
          title: s.tr(
            'البيانات التي نجمعها',
            'Données collectées',
            appL10n.privacyComplianceDataWeCollect,
          ),
          body: s.tr(
            '• الهوية والحساب: الاسم، البريد الإلكتروني، رقم الهاتف، أو مصادقة Google / Apple الآمنة.\n'
                '• الإعلانات والمتاجر: الصور، العناوين، الأوصاف، الأسعار بالدرهم، والمدينة المختارة.\n'
                '• المحادثات الفورية: الرسائل النصية، الصور، والتفاعلات المتبادلة بين البائع والمشتري.\n'
                '• رموز إشعارات الهاتف (FCM / APNs): لإيصال تنبيهات الرسائل والمكالمات إلى هاتفك، ويتم تعطيلها تلقائياً عند تسجيل الخروج.',
            '• Compte & Identité : Nom, e-mail, téléphone ou authentification Google / Apple.\n'
                '• Annonces & Boutiques : Photos, titres, descriptions, prix et ville choisie.\n'
                '• Messagerie : Messages, images et réactions échangés entre acheteurs et vendeurs.\n'
                '• Jetons de notification (FCM / APNs) : Pour recevoir vos alertes mobiles, désactivés automatiquement à la déconnexion.',
            appL10n.privacyComplianceAccountIdentityNameEmailPhone,
          ),
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          number: '02',
          icon: CupertinoIcons.slider_horizontal_3,
          title: s.tr(
            'أذونات الهاتف والتحكم بها',
            'Autorisations de l’appareil',
            appL10n.privacyComplianceDevicePermissionsControls,
          ),
          body: s.tr(
            '• الإشعارات: اختيارية لتلقي تنبيهات الرسائل الفورية على iOS و Android ويمكن إيقافها في أي وقت.\n'
                '• الكاميرا والمعرض: تُطلب فقط عندما تختار رفع صورة لإعلانك أو إرسال صورة في المحادثة.\n'
                '• الموقع التقريبي: يُستخدم لعرض الإعلانات القريبة من مدينتك دون تتبع موقعك في الخلفية.',
            '• Notifications : Optionnelles pour les nouveaux messages sur iOS et Android.\n'
                '• Caméra & Photos : Utilisées uniquement lors de l’ajout d’images à une annonce ou un message.\n'
                '• Localisation approximative : Filtrage par ville/zone sans suivi en arrière-plan.',
            appL10n.privacyComplianceNotificationsOptionalOsAlertsNew,
          ),
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          number: '03',
          icon: CupertinoIcons.sparkles,
          title: s.tr(
            'سلامة الذكاء الاصطناعي والإبلاغ الفوري',
            'Sécurité IA & Signalement',
            appL10n.privacyComplianceAiSafetyAppReporting,
          ),
          body: s.tr(
            'يوفر التطبيق أدوات مساعدة ذكية لتنظيم الإعلانات والبحث، ويتيح زر إبلاغ فوري داخل التطبيق لمراجعة أي محتوى غير دقيق أو مخالف دون مغادرة التطبيق.',
            'L’application intègre un bouton de signalement direct permettant de signaler tout contenu généré par IA ou toute annonce inappropriée.',
            appL10n.privacyComplianceSmartListingSearchToolsInclude,
          ),
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          number: '04',
          icon: CupertinoIcons.envelope_badge_fill,
          title: s.tr(
            'حقوقك القانونية والتواصل معنا',
            'Vos droits & Contact (CNDP)',
            appL10n.privacyComplianceLegalRightsContact,
          ),
          body: s.tr(
            'وفقاً للقانون المغربي 09-08 ومعايير App Store و Google Play، يحق لك الاطلاع على بياناتك، تصحيحها، حظر المستخدمين المزعجين، أو حذف حسابك نهائياً.\n'
                '• البريد الرسمي: support@apolo.ma / contact@apolo.ma\n'
                '• الموقع الرسمي: https://apolo.ma',
            'Conformément à la loi marocaine 09-08 et aux règles App Store / Google Play, vous disposez d’un droit d’accès, de rectification et de suppression.\n'
                '• Email : support@apolo.ma / contact@apolo.ma\n'
                '• Site web : https://apolo.ma',
            appL10n.privacyComplianceUnderMoroccanLaw0908,
          ),
        ),
        const SizedBox(height: 18),
        ApoloDlButton(
          key: const Key('dl-open-ai-report'),
          label: s.tr(
            'الإبلاغ عن محتوى أو مخالفة داخل التطبيق',
            'Signaler un contenu dans l’application',
            appL10n.privacyComplianceReportAiPolicyIssueApp,
          ),
          leadingIcon: CupertinoIcons.flag_fill,
          variant: ApoloDlButtonVariant.primary,
          borderRadius: 999,
          height: 48,
          fullWidth: true,
          onPressed: () => showAiContentReportSheet(
            context,
            featureContext: 'Privacy & Policies Center',
          ),
        ),
        const SizedBox(height: 10),
        ApoloDlButton(
          key: const Key('dl-open-privacy-web'),
          label: s.tr(
            'فتح سياسة الخصوصية على الويب',
            'Ouvrir la politique web',
            appL10n.privacyComplianceOpenWebPrivacyPolicy,
          ),
          leadingIcon: CupertinoIcons.globe,
          variant: ApoloDlButtonVariant.secondary,
          borderRadius: 999,
          height: 48,
          fullWidth: true,
          onPressed: () => _openExternalUrl(privacyUrl),
        ),
      ],
    );
  }

  Widget _buildPoliciesAndTermsView(AppStrings s) {
    return ListView(
      key: const Key('dl-policies-list'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        _buildSummaryHero(
          s: s,
          icon: CupertinoIcons.doc_checkmark_fill,
          badgeText: s.tr(
            'شروط الاستخدام وسياسات البيع 2026',
            'Conditions Générales 2026',
            appL10n.privacyComplianceTermsUseMarketplaceRules,
          ),
          headline: s.tr(
            'قواعد واضحة لبيع وشراء آمن بالمغرب',
            'Des règles claires pour acheter et vendre en confiance',
            appL10n.privacyComplianceClearRulesSafeBuyingSelling,
          ),
          description: s.tr(
            'باستخدامك لتطبيق Apolo.ma، فإنك توافق على شروط النشر، قواعد المحادثة الآمنة، وسياسات التوثيق والرتب.',
            'En utilisant Apolo.ma, vous acceptez nos règles de publication, de messagerie respectueuse et de sécurité.',
            appL10n.privacyComplianceByUsingApoloYouAgree,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          number: '01',
          icon: CupertinoIcons.checkmark_seal_fill,
          title: s.tr(
            'الأهلية ومصداقية الحساب والشارات',
            'Authenticité du compte & Badges',
            appL10n.privacyComplianceAccountIntegrityVerifiedBadges,
          ),
          body: s.tr(
            '• يجب أن تكون معلومات الحساب والمتجر حقيقية ومحدثة.\n'
                '• شارة التوثيق الزرقاء ورتب البائعين (Bronze إلى Champion) تُمنح حصرياً عبر نظام Apolo الرسمي ويُمنع انتحال صفة المتاجر أو الإدارة.',
            '• Les informations du profil et de la boutique doivent être exactes.\n'
                '• Le badge vérifié et les rangs vendeurs (Bronze à Champion) sont attribués uniquement par Apolo ; toute usurpation est interdite.',
            appL10n.privacyComplianceAccountStoreDetailsMustRemain,
          ),
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          number: '02',
          icon: CupertinoIcons.tag_fill,
          title: s.tr(
            'سياسة نشر الإعلانات والسلع الممنوعة',
            'Règles d’annonces & Produits interdits',
            appL10n.privacyComplianceListingRulesProhibitedItems,
          ),
          body: s.tr(
            '• يجب أن يعكس الإعلان منتجاً أو خدمة حقيقية بصور واضحة وسعر صادق.\n'
                '• يُمنع منعاً كلياً نشر السلع المقلدة، الأسلحة، المواد غير القانونية أو الطبية الخاضعة للوصفة، الوثائق الرسمية، أو الإعلانات الوهمية.',
            '• Chaque annonce doit présenter un bien réel avec des photos authentiques et un prix honnête.\n'
                '• Sont strictement interdits : contrefaçons, armes, substances illicites, médicaments sur ordonnance, documents officiels et arnaques.',
            appL10n.privacyComplianceListingsMustRepresentRealItems,
          ),
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          number: '03',
          icon: CupertinoIcons.shield_lefthalf_fill,
          title: s.tr(
            'المعاملات الآمنة وآداب الدردشة',
            'Transactions sûres & Messagerie',
            appL10n.privacyComplianceSafeTransactionsChatConduct,
          ),
          body: s.tr(
            '• ننصح دائماً بالمعاينة المباشرة في مكان عمومي وعدم إرسال أي تسبيق مالي قبل استلام المنتج.\n'
                '• يُمنع الإزعاج، الرسائل العشوائية (Spam)، أو الإساءة في الدردشة؛ يمكنك حظر أي مستخدم أو الإبلاغ عنه بضغطة واحدة.',
            '• Privilégiez les rencontres dans un lieu public et ne versez jamais d’acompte avant d’avoir vérifié l’article.\n'
                '• Le spam et le harcèlement sont interdits ; bloquez ou signalez tout abus en un geste.',
            appL10n.privacyComplianceAlwaysInspectItemsPersonSafe,
          ),
        ),
        const SizedBox(height: 10),
        _buildInfoCard(
          number: '04',
          icon: CupertinoIcons.bolt_fill,
          title: s.tr(
            'اشتراكات Pro+ وترقية الإعلانات (Boost)',
            'Abonnements Pro+ & Boosts',
            appL10n.privacyComplianceProSubscriptionsListingBoosts,
          ),
          body: s.tr(
            '• تتم فوترة باقات Pro+ ومزايا الترويج بوضوح عبر حساب متجرك (App Store / Google Play).\n'
                '• يمكنك إدارة أو إلغاء التجديد التلقائي في أي وقت قبل 24 ساعة من انتهاء الفترة الحالية من إعدادات المتجر.',
            '• Les offres Pro+ et Boost sont facturées de manière transparente via l’App Store ou Google Play.\n'
                '• Vous pouvez annuler le renouvellement automatique jusqu’à 24h avant l’échéance dans les réglages de votre store.',
            appL10n.privacyComplianceProPlansBoostUpgradesAre,
          ),
        ),
        const SizedBox(height: 18),
        ApoloDlButton(
          key: const Key('dl-open-terms-web'),
          label: s.tr(
            'فتح الشروط والأحكام الكاملة على الويب',
            'Ouvrir les conditions sur le web',
            appL10n.privacyComplianceOpenWebTermsPolicies,
          ),
          leadingIcon: CupertinoIcons.doc_text,
          variant: ApoloDlButtonVariant.secondary,
          borderRadius: 999,
          height: 48,
          fullWidth: true,
          onPressed: () => _openExternalUrl(termsUrl),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountView(AppStrings s) {
    return ListView(
      key: const Key('dl-delete-list'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        _buildSummaryHero(
          s: s,
          icon: CupertinoIcons.trash_fill,
          badgeText: s.tr(
            'حذف فوري · App Store & Google Play',
            'Suppression directe · App Store & Play',
            appL10n.privacyComplianceInstantErasureAppStorePlay,
          ),
          headline: s.tr(
            'حذف الحساب والبيانات الشخصية نهائياً',
            'Suppression définitive du compte et des données',
            appL10n.privacyCompliancePermanentAccountDataDeletion,
          ),
          description: s.tr(
            'يمكنك مسح حسابك وكافة بياناتك مباشرة من داخل التطبيق بضغطة واحدة، أو تقديم طلب عبر الرابط الخارجي دون تسجيل الدخول.',
            'Effacez votre compte et toutes vos données directement dans l’application, ou via notre lien web dédié.',
            appL10n.privacyComplianceEraseAccountAllAssociatedPersonal,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          number: '01',
          icon: CupertinoIcons.xmark_shield_fill,
          title: s.tr(
            'ما الذي يتم حذفه فوراً؟',
            'Données supprimées immédiatement',
            appL10n.privacyComplianceWhatGetsPermanentlyDeleted,
          ),
          body: s.tr(
            '• معلومات الملف الشخصي (الاسم، البريد الإلكتروني، رقم الهاتف، وربط Google / Apple).\n'
                '• جميع الإعلانات المنشورة، الصور، وبيانات المتجر.\n'
                '• سجل المحادثات والرسائل، قائمة المفضلة، ورموز إشعارات الهاتف (Push Tokens).',
            '• Informations du profil (nom, e-mail, téléphone et liaison OAuth).\n'
                '• Toutes vos annonces publiées, photos et données de boutique.\n'
                '• Historique des discussions, favoris et jetons de notifications mobiles.',
            appL10n.privacyComplianceProfileCredentialsNameEmailPhone,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            key: const Key('privacy-delete-account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dlDanger,
              disabledBackgroundColor: _dlPill,
              disabledForegroundColor: _dlMuted,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: _deleting || !_state.isLoggedIn
                ? null
                : _handleInAppAccountDeletion,
            icon: const Icon(CupertinoIcons.trash, size: 18),
            label: Text(
              s.tr(
                'حذف حسابي وجميع بياناتي الآن (داخل التطبيق)',
                'Supprimer mon compte maintenant (In-App)',
                appL10n.privacyComplianceDeleteMyAccountNowApp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (!_state.isLoggedIn) ...[
          const SizedBox(height: 10),
          Text(
            s.tr(
              'سجّل الدخول لحذف حسابك مباشرة من التطبيق، أو استخدم رابط الحذف الخارجي أدناه.',
              'Connectez-vous pour supprimer votre compte dans l’app, ou utilisez le lien externe ci-dessous.',
              appL10n.privacyComplianceSignDeleteAccountDirectlyApp,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: _dlMuted,
            ),
          ),
        ],
        const SizedBox(height: 10),
        ApoloDlButton(
          key: const Key('dl-open-delete-web'),
          label: s.tr(
            'رابط حذف الحساب والبيانات على الويب',
            'Lien web externe de suppression',
            appL10n.privacyComplianceExternalWebDataDeletionLink,
          ),
          leadingIcon: CupertinoIcons.arrow_up_right_square,
          variant: ApoloDlButtonVariant.secondary,
          borderRadius: 999,
          height: 48,
          fullWidth: true,
          onPressed: () => _openExternalUrl(deleteAccountUrl),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String number,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dlSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _dlBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: _dlInk, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _dlInk,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _dlMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              color: _dlMuted,
              height: 1.52,
            ),
          ),
        ],
      ),
    );
  }
}
