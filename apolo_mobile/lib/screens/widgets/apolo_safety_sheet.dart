import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/firebase_chat_service.dart';
import '../../core/state/app_state.dart';
import 'app_image.dart';

/// Unified 2026 Safety & Reporting Sheet for Messages, Chats, Ads, Stores, and Users.
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
          ? s.tr('الإبلاغ عن هذه الرسالة', 'Signaler ce message', 'Report message')
          : s.tr('الإبلاغ عن المحادثة', 'Signaler la conversation', 'Report chat');
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
      headerTitle = s.tr('الإبلاغ عن هذا الإعلان', 'Signaler cette annonce', 'Report listing');
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
          ? s.tr('الإبلاغ عن هذا المتجر', 'Signaler cette boutique', 'Report store')
          : s.tr('الإبلاغ عن هذا الحساب', 'Signaler ce compte', 'Report user');
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

  final blockTargetKey = (reportedUserId != null && reportedUserId.trim().isNotEmpty)
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
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
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
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
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
                        CupertinoIcons.exclamationmark_triangle_fill,
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
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                          if (targetName.trim().isNotEmpty)
                            Text(
                              targetName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (messageExcerpt != null && messageExcerpt.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"${messageExcerpt.trim()}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF374151),
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
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFFF2F3F7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            active
                                ? CupertinoIcons.check_mark_circled_solid
                                : CupertinoIcons.circle,
                            size: 18,
                            color: active ? Colors.white : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? Colors.white : const Color(0xFF0A0A0A),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F7),
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
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0A0A0A),
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
                          'Additional details (optional)...',
                        ),
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
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
                                  ? const Color(0xFF0A0A0A)
                                  : const Color(0xFFF2F3F7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: alsoBlock
                                    ? const Color(0xFF0A0A0A)
                                    : const Color(0xFFD1D5DB),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: alsoBlock
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.tr(
                                'حظر هذا الحساب أيضاً',
                                'Bloquer aussi ce compte',
                                'Also block this account',
                              ),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0A0A0A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31B23),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    onPressed: submitting
                        ? null
                        : () async {
                            setModalState(() => submitting = true);
                            final chosen = s.tr(
                              reasons[selectedReason]['ar']!,
                              reasons[selectedReason]['fr']!,
                              reasons[selectedReason]['en']!,
                            );
                            final myUserId =
                                int.tryParse('${state.currentUser?['id'] ?? 0}') ??
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
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            s.tr(
                              'إرسال البلاغ الآن',
                              'Envoyer le signalement',
                              'Submit Report',
                            ),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
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

  notesCtrl.dispose();

  if (result == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0A0A0A),
        content: Text(
          s.tr(
            'تم إرسال بلاغك للإدارة بنجاح ✓',
            'Signalement envoyé à notre équipe ✓',
            'Report submitted successfully ✓',
          ),
        ),
      ),
    );
  }
  return result;
}

/// Shows the user's blocked accounts with 1-tap Unblock controls.
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

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.tr(
                    'الحسابات المحظورة',
                    'Comptes bloqués',
                    'Blocked Accounts',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.tr(
                    'يمكنك إلغاء حظر أي مستخدم أو متجر في أي وقت.',
                    'Débloquez un utilisateur ou une boutique à tout moment.',
                    'You can unblock any user or store anytime.',
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A0A0A),
                        strokeWidth: 2.2,
                      ),
                    ),
                  )
                else if (blocked.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.shield_lefthalf_fill,
                          size: 32,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.tr(
                            'لا توجد حسابات محظورة حالياً',
                            'Aucun compte bloqué pour le moment',
                            'No blocked accounts yet',
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
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
                        final name = (item['name'] ?? 'Apolo User').toString();
                        final avatar = (item['avatar'] ?? '').toString();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0A0A0A),
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                child: avatar.isNotEmpty
                                    ? AppImage(
                                        url: avatar,
                                        width: 38,
                                        height: 38,
                                        fit: BoxFit.cover,
                                      )
                                    : Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          color: Colors.white,
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
                                    color: Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0A0A0A),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
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
                                child: Text(
                                  s.tr(
                                    'إلغاء الحظر',
                                    'Débloquer',
                                    'Unblock',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
        );
      },
    ),
  );
}
