import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/firebase_chat_service.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import 'app_image.dart';
import '../../l10n/l10n.dart';

/// Unified Dynamic Layer v5.1 Safety & Reporting Sheet for Messages, Chats, Ads, Stores, and Users.
Future<bool?> showApoloReportSheet(
  BuildContext context, {
  required String targetType, // 'message' | 'chat' | 'ad' | 'store' | 'user'
  required String targetId,
  required String targetName,
  String? reportedUserId,
  String? reportedUserAvatar,
  String? messageExcerpt,
}) async {
  final state = AppState();
  final s = state.s;
  final notesCtrl = TextEditingController();
  int selectedReason = 0;
  bool alsoBlock = false;
  bool submitting = false;

  final List<Map<String, String>> reasons;
  final String headerTitle;

  switch (targetType) {
    case 'message':
    case 'chat':
      headerTitle = targetType == 'message'
          ? s.tr('الإبلاغ عن هذه الرسالة', 'Signaler ce message', appL10n.safetyReportMessage)
          : s.tr('الإبلاغ عن المحادثة', 'Signaler la conversation', appL10n.chatListReportChat);
      reasons = [
        {
          'ar': 'تحرش أو كلام مسيء',
          'fr': 'Harcèlement ou propos abusifs',
          'en': 'Harassment or abusive language',
        },
        {
          'ar': 'محاولة نصب أو رابط مشبوه',
          'fr': 'Tentative d\'arnaque ou lien suspect',
          'en': 'Scam attempt or suspicious link',
        },
        {
          'ar': 'سبام أو إزعاج متكرر',
          'fr': 'Spam ou messages indésirables',
          'en': 'Spam or unwanted messages',
        },
        {
          'ar': 'محتوى غير لائق أو مخالف',
          'fr': 'Contenu inapproprié ou interdit',
          'en': 'Inappropriate or prohibited content',
        },
      ];
      break;
    case 'ad':
      headerTitle = s.tr(
          'الإبلاغ عن هذا الإعلان', 'Signaler cette annonce', appL10n.safetyReportListing);
      reasons = [
        {
          'ar': 'إعلان احتيالي أو سلعة وهمية',
          'fr': 'Annonce frauduleuse ou arnaque',
          'en': 'Fraudulent or fake listing',
        },
        {
          'ar': 'ثمن أو صور مضللة',
          'fr': 'Prix ou photos trompeurs',
          'en': 'Misleading price or photos',
        },
        {
          'ar': 'سلعة أو خدمة ممنوعة',
          'fr': 'Article ou service interdit',
          'en': 'Prohibited item or service',
        },
        {
          'ar': 'إعلان مكرر أو سبام',
          'fr': 'Annonce en double ou spam',
          'en': 'Duplicate listing or spam',
        },
      ];
      break;
    default:
      headerTitle = targetType == 'store'
          ? s.tr('الإبلاغ عن هذا المتجر', 'Signaler cette boutique', appL10n.storeDetailReportStore)
          : s.tr('الإبلاغ عن هذا الحساب', 'Signaler ce compte', appL10n.safetyReportUser);
      reasons = [
        {
          'ar': 'متجر أو حساب وهمي / انتحال صفة',
          'fr': 'Faux compte ou usurpation d\'identité',
          'en': 'Fake account or impersonation',
        },
        {
          'ar': 'نصب أو عدم الالتزام بالطلب',
          'fr': 'Arnaque ou non-livraison',
          'en': 'Scam or non-delivery',
        },
        {
          'ar': 'سلوك مسيء أو غير مهني',
          'fr': 'Comportement abusif',
          'en': 'Abusive behavior',
        },
        {
          'ar': 'سلع مقلدة أو مخالفة',
          'fr': 'Articles contrefaits ou interdits',
          'en': 'Counterfeit or prohibited items',
        },
      ];
      break;
  }

  final blockTargetKey =
      (reportedUserId != null && reportedUserId.trim().isNotEmpty)
          ? reportedUserId.trim()
          : targetId.trim();

  final result = await showModalBottomSheet<bool>(
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
                          color: Color(0xFF000000),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerTitle,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000000),
                              ),
                            ),
                            if (targetName.trim().isNotEmpty)
                              Text(
                                targetName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF757575),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ApoloDlIconCircleButton(
                        icon: CupertinoIcons.xmark,
                        iconSize: 16,
                        backgroundColor: const Color(0xFFEEEEEE),
                        iconColor: const Color(0xFF000000),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ],
                  ),
                  if (messageExcerpt != null &&
                      messageExcerpt.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '"${messageExcerpt.trim()}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF525252),
                        ),
                      ),
                    ),
                  ],
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
                              ? const Color(0xFF000000)
                              : const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              active
                                  ? CupertinoIcons.check_mark_circled_solid
                                  : CupertinoIcons.circle,
                              size: 18,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF757575),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF000000),
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Theme(
                      data: Theme.of(ctx).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          filled: false,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      child: TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        cursorColor: const Color(0xFF000000),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF000000),
                        ),
                        decoration: InputDecoration(
                          filled: false,
                          fillColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: s.tr(
                            'أضف تفاصيل إضافية (اختياري)...',
                            'Détails supplémentaires (optionnel)...',
                            appL10n.privacyComplianceAdditionalDetailsOptional,
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (blockTargetKey.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setModalState(() => alsoBlock = !alsoBlock);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: alsoBlock
                                    ? const Color(0xFF000000)
                                    : const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: alsoBlock
                                      ? const Color(0xFF000000)
                                      : const Color(0xFFDCDCDC),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: alsoBlock
                                  ? const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.tr(
                                  'حظر هذا الحساب أيضاً',
                                  'Bloquer aussi ce compte',
                                  appL10n.safetyAlsoBlockThisAccount,
                                ),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ApoloDlButton(
                    label: s.tr(
                      'إرسال البلاغ الآن',
                      'Envoyer le signalement',
                      appL10n.safetySubmitReport,
                    ),
                    variant: ApoloDlButtonVariant.primary,
                    borderRadius: 999,
                    fullWidth: true,
                    height: 52,
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
                            final myUserId = int.tryParse(
                                    '${state.currentUser?['id'] ?? 0}') ??
                                0;
                            try {
                              await FirebaseChatService.instance.submitReport(
                                targetType: targetType,
                                targetId: targetId,
                                targetTitle: targetName,
                                reporterId: myUserId,
                                reportedUserId: reportedUserId ?? '',
                                reason: chosen,
                                details: notesCtrl.text.trim(),
                                messageExcerpt: messageExcerpt ?? '',
                              );
                            } catch (_) {}
                            try {
                              await state.api.dio.post('/reports', data: {
                                'type': targetType,
                                'target_id': targetId,
                                'reason': chosen,
                                'context': targetName,
                                'details': notesCtrl.text.trim(),
                              });
                            } catch (_) {}
                            if (alsoBlock && blockTargetKey.isNotEmpty) {
                              await FirebaseChatService.instance.blockTarget(
                                myUserId: myUserId,
                                targetId: blockTargetKey,
                                targetName: targetName,
                                targetAvatar: reportedUserAvatar ?? '',
                                targetType:
                                    targetType == 'store' ? 'store' : 'user',
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx, true);
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

  notesCtrl.dispose();

  if (result == true && context.mounted) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF000000),
          shape: const StadiumBorder(),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: Text(
            s.tr(
              'تم إرسال بلاغك للإدارة بنجاح',
              'Signalement envoyé à notre équipe',
              appL10n.safetyReportSubmittedSuccessfully,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }
  return result;
}

/// Shows the user's blocked accounts with 1-tap Dynamic Layer v5.1 Unblock controls.
Future<void> showBlockedAccountsSheet(BuildContext context) async {
  final state = AppState();
  final s = state.s;
  final myUserId = int.tryParse('${state.currentUser?['id'] ?? 0}') ?? 0;

  bool loaded = false;
  bool loading = true;
  List<Map<String, dynamic>> blocked =
      FirebaseChatService.instance.blockedList;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        if (!loaded) {
          loaded = true;
          FirebaseChatService.instance
              .loadBlockedTargets(myUserId)
              .then((list) {
            if (ctx.mounted) {
              setModalState(() {
                blocked = list;
                loading = false;
              });
            }
          });
        }

        return Directionality(
          textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.tr(
                                'الحسابات المحظورة',
                                'Comptes bloqués',
                                appL10n.safetyBlockedAccounts,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000000),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              s.tr(
                                'يمكنك إلغاء حظر أي مستخدم أو متجر في أي وقت.',
                                'Débloquez un utilisateur ou une boutique à tout moment.',
                                appL10n.settingsBlockedAccountsYouCanUnblockAnyUser,
                              ),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ApoloDlIconCircleButton(
                        icon: CupertinoIcons.xmark,
                        iconSize: 16,
                        backgroundColor: const Color(0xFFEEEEEE),
                        iconColor: const Color(0xFF000000),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: CircularProgressIndicator(
                          color: Color(0xFF000000),
                          strokeWidth: 2.2,
                        ),
                      ),
                    )
                  else if (blocked.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              CupertinoIcons.shield_lefthalf_fill,
                              size: 22,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            s.tr(
                              'لا توجد حسابات محظورة حالياً',
                              'Aucun compte bloqué pour le moment',
                              appL10n.settingsBlockedAccountsNoBlockedAccountsYet,
                            ),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: blocked.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, idx) {
                          final item = blocked[idx];
                          final id = (item['id'] ?? '').toString();
                          final name =
                              (item['name'] ?? 'Apolo User').toString();
                          final avatar = (item['avatar'] ?? '').toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F6F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEEEEEE),
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child: avatar.isNotEmpty
                                      ? AppImage(
                                          url: avatar,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        )
                                      : Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'A',
                                          style: const TextStyle(
                                            color: Color(0xFF000000),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ),
                                ApoloDlButton(
                                  label: s.tr(
                                    'إلغاء الحظر',
                                    'Débloquer',
                                    appL10n.chatRoomUnblock,
                                  ),
                                  variant: ApoloDlButtonVariant.primary,
                                  size: ApoloDlButtonSize.xs,
                                  borderRadius: 999,
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    await FirebaseChatService.instance
                                        .unblockTarget(
                                      myUserId: myUserId,
                                      targetId: id,
                                    );
                                    setModalState(() {
                                      blocked = FirebaseChatService
                                          .instance.blockedList;
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
