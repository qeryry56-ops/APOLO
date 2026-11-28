import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/state/app_state.dart';
import '../../widgets/dl_settings_kit.dart';
import '../../l10n/l10n.dart';

/// Instagram-Style Quick Replies Manager Sheet (إدارة الردود السريعة ورسالة الترحيب).
class QuickRepliesManagerSheet extends StatefulWidget {
  const QuickRepliesManagerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuickRepliesManagerSheet(),
    );
  }

  @override
  State<QuickRepliesManagerSheet> createState() =>
      _QuickRepliesManagerSheetState();
}

class _QuickRepliesManagerSheetState extends State<QuickRepliesManagerSheet> {
  final AppState _state = AppState();
  late List<Map<String, dynamic>> _replies;
  late final TextEditingController _greetingCtrl;
  final TextEditingController _shortcutCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _replies = _state.quickReplies
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _greetingCtrl = TextEditingController(text: _state.autoGreeting);
  }

  @override
  void dispose() {
    _greetingCtrl.dispose();
    _shortcutCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _addReply() {
    final shortcut = _shortcutCtrl.text.trim();
    final text = _bodyCtrl.text.trim();
    if (text.isEmpty) return;
    final maxAllowed = _state.isProPlusAccount ? 25 : 8;
    if (_replies.length >= maxAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _state.s.tr(
              'وصلت للحد الأقصى ($maxAllowed ردود). رقِّ إلى Pro Plus لردود غير محدودة!',
              'Limite atteinte ($maxAllowed). Passez à Pro Plus pour plus !',
              appL10n.quickRepliesLimitReachedMaxallowedUpgradePro(maxAllowed),
            ),
          ),
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _replies.add({
        'id': 'qr_${DateTime.now().millisecondsSinceEpoch}',
        'shortcut': shortcut.isNotEmpty
            ? shortcut
            : (text.length > 16 ? text.substring(0, 16) : text),
        'text': text,
      });
      _shortcutCtrl.clear();
      _bodyCtrl.clear();
    });
  }

  Future<void> _saveAll() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _state.saveBusinessQuickReplies(
        replies: _replies,
        autoGreetingText: _greetingCtrl.text,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConfig.success,
          content: Text(
            _state.s.tr(
              'تم حفظ الردود السريعة ورسالة الترحيب بنجاح ⚡',
              'Réponses rapides enregistrées ⚡',
              appL10n.quickRepliesQuickRepliesSaved,
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final isAr = s.isAr;
    final palette = ApoloDlPalette.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 22),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
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
                    color: palette.separator,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(CupertinoIcons.bolt_fill, color: palette.ink, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.tr(
                        'الردود السريعة للشات (Quick Replies)',
                        'Réponses rapides (Chat)',
                        appL10n.quickRepliesChatQuickReplies,
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                s.tr(
                  'تظهر هذه الاختصارات فوق لوحة المفاتيح في محادثاتك للرد على الزبناء بضغطة واحدة.',
                  'Ces raccourcis apparaissent au-dessus du clavier dans vos conversations.',
                  appL10n.quickRepliesTapAnyShortcutInsideChat,
                ),
                style: TextStyle(fontSize: 12.8, color: palette.muted),
              ),
              const SizedBox(height: 14),

              // Existing Replies List
              ..._replies.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: palette.groupCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: palette.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚡ ${item['shortcut'] ?? ''}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: palette.bg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (item['text'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.trash,
                          size: 17,
                          color: palette.danger,
                        ),
                        onPressed: () {
                          setState(() => _replies.removeAt(idx));
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              // Add New Quick Reply Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.groupCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tr('إضافة رد سريع جديد', 'Nouvelle réponse rapide', appL10n.quickRepliesAddQuickReply),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            key: const Key('qr-shortcut-input'),
                            controller: _shortcutCtrl,
                            decoration: InputDecoration(
                              hintText: s.tr('العنوان (مثال: الثمن)', 'Titre', appL10n.quickRepliesLabel),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            key: const Key('qr-body-input'),
                            controller: _bodyCtrl,
                            decoration: InputDecoration(
                              hintText: s.tr('نص الرسالة...', 'Message...', appL10n.quickRepliesReplyText),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          key: const Key('qr-add-btn'),
                          onPressed: _addReply,
                          icon: Icon(
                            CupertinoIcons.plus_circle_fill,
                            color: palette.ink,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Text(
                s.tr(
                  'رسالة الترحيب التلقائية للزبناء الجدد',
                  'Message d’accueil automatique',
                  appL10n.quickRepliesAutoGreetingMessage,
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.groupCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _greetingCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: s.tr(
                      'مرحباً بك في متجرنا! كيف يمكننا مساعدتك؟',
                      'Bienvenue dans notre boutique !',
                      appL10n.quickRepliesWelcomeStore,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),
              ApoloDlButton(
                key: const Key('qr-save-btn'),
                label: _saving
                    ? s.tr('جاري الحفظ...', 'Enregistrement...', appL10n.savingLabel)
                    : s.tr('حفظ الردود السريعة', 'Enregistrer', appL10n.quickRepliesSaveQuickReplies),
                variant: ApoloDlButtonVariant.primary,
                borderRadius: 999,
                fullWidth: true,
                onPressed: _saving ? null : _saveAll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal 1-Tap Quick Replies Strip shown above ChatInput for Business / Pro Plus sellers.
class BusinessQuickRepliesBar extends StatelessWidget {
  final List<Map<String, dynamic>> replies;
  final ValueChanged<String> onSelectReply;
  final VoidCallback onManageTap;
  final bool isAr;

  const BusinessQuickRepliesBar({
    super.key,
    required this.replies,
    required this.onSelectReply,
    required this.onManageTap,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();

    return Container(
      key: const Key('chat-business-quick-replies-bar'),
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFECEEF2), width: 0.8),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, idx) {
          if (idx == replies.length) {
            return GestureDetector(
              key: const Key('chat-manage-quick-replies-btn'),
              onTap: onManageTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEF2),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.slider_horizontal_3,
                      size: 13,
                      color: Color(0xFF0A0A0A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppState().s.tr('تعديل', 'Gérer', appL10n.quickRepliesManage),
                      style: const TextStyle(
                        fontSize: 11.8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final item = replies[idx];
          final shortcut = (item['shortcut'] ?? '').toString().trim();
          final body = (item['text'] ?? '').toString().trim();

          return GestureDetector(
            key: Key('chat-qr-chip-$idx'),
            onTap: () {
              HapticFeedback.selectionClick();
              onSelectReply(body);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2E6EE), width: 1),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.bolt_fill,
                    size: 12,
                    color: Color(0xFF0A0A0A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    shortcut.isNotEmpty ? shortcut : body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A0A0A),
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
}
