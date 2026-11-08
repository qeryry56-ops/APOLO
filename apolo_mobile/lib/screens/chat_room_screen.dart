import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/state/app_state.dart';
import 'widgets/app_image.dart';
import 'widgets/chat_utils.dart';

class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final String peerName;
  final String adTitle;
  final String? peerAvatar;
  final String? adImage;
  final String? adPrice;
  final String? initialDraft;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
    required this.adTitle,
    this.peerAvatar,
    this.adImage,
    this.adPrice,
    this.initialDraft,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final AppState _state = AppState();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _messages = [];
  final List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _red = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _incoming = Color(0xFFF5F6F8);
  static const Color _incomingText = Color(0xFF1A2436);
  static const Color _fill = Color(0xFFF2F3F5);

  @override
  void initState() {
    super.initState();
    _loadMessages(scrollToBottom: true);
    if (widget.initialDraft != null && widget.initialDraft!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendText(widget.initialDraft!.trim());
      });
    }
    _msgCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _focus.addListener(() {
      if (_focus.hasFocus) Future.delayed(const Duration(milliseconds: 300), _scrollToEnd);
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && !_isDemo) _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Demo conversations (id >= 9000) run fully offline with a simulated seller.
  bool get _isDemo => widget.conversationId >= 9000;

  List<Map<String, dynamic>> _seedDemoMessages() {
    final now = DateTime.now();
    String ago(int min) => now.subtract(Duration(minutes: min)).toIso8601String();
    return [
      {
        'id': 1,
        'body': _state.s.tr('السلام عليكم، الإعلان باقي متوفر؟', 'Bonjour, l\'annonce est toujours disponible ?'),
        'is_mine': true,
        'is_read': true,
        'created_at': ago(42),
      },
      {
        'id': 2,
        'body': _state.s.tr(
          'وعليكم السلام، أه باقي متوفر وفحالة ممتازة 👌',
          'Bonjour, oui toujours disponible et en excellent état 👌',
        ),
        'is_mine': false,
        'created_at': ago(40),
      },
      {
        'id': 3,
        'body': _state.s.tr(
          'مرحبا بيك فأي وقت تجي تشوفو. الثمن فيه شوية ديال التفاوض.',
          'Vous pouvez passer le voir. Le prix est légèrement négociable.',
        ),
        'is_mine': false,
        'created_at': ago(39),
      },
    ];
  }

  Future<void> _simulateDemoReply(String userText) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final s = _state.s;
    String reply;
    if (userText.contains('💰') || userText.contains('عرض') || userText.contains('Offre')) {
      reply = s.tr(
        'شكراً على العرض 🙏 نقدر نقبلو إلا زدتي شوية، نتلاقاو ونتفاهمو مزيان.',
        'Merci pour l\'offre 🙏 Si vous montez un peu, on peut conclure.',
      );
    } else if (userText.contains('فين') || userText.contains('Où')) {
      reply = s.tr(
        'أنا فكازا، المعاريف. نقدر نتلاقاو اليوم مع 6 العشية 📍',
        'Je suis à Casablanca, Maârif. On peut se voir à 18h 📍',
      );
    } else if (userText.contains('ثمن') || userText.contains('prix')) {
      reply = s.tr(
        'الثمن قابل للتفاوض شوية، قدم ليا عرضك 💬',
        'Le prix est un peu négociable, faites-moi une offre 💬',
      );
    } else {
      reply = s.tr('أه مرحبا، باقي متوفر ✅', 'Oui, toujours disponible ✅');
    }
    setState(() {
      for (final m in _messages) {
        if (m is Map && m['is_mine'] == true) m['is_read'] = true;
      }
      _messages = [
        ..._messages,
        {
          'id': DateTime.now().millisecondsSinceEpoch,
          'body': reply,
          'is_mine': false,
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
    });
    HapticFeedback.selectionClick();
    _scrollToEnd();
  }

  Future<void> _loadMessages({bool silent = false, bool scrollToBottom = false}) async {
    if (_isDemo) {
      if (_messages.isEmpty && mounted) {
        setState(() {
          _messages = _seedDemoMessages();
          _loading = false;
        });
        if (scrollToBottom) _scrollToEnd();
      }
      return;
    }
    try {
      final res = await _state.api.dio.get(
        '/chat/conversations/${widget.conversationId}/messages',
      );
      if (res.data is Map && res.data['status'] == 'success') {
        final List<dynamic> incoming = res.data['messages'] ?? [];
        final bool hasNew = incoming.length > _messages.length;
        if (mounted) {
          setState(() {
            _messages = incoming;
            _loading = false;
          });
          if (scrollToBottom || hasNew) _scrollToEnd();
        }
        return;
      }
    } catch (_) {}
    if (!silent && mounted) setState(() => _loading = false);
  }

  Future<void> _sendText([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    if (preset == null) _msgCtrl.clear();
    // Optimistic bubble
    final pending = <String, dynamic>{
      'body': text,
      'is_mine': true,
      'created_at': DateTime.now().toIso8601String(),
      '_pending': true,
    };
    setState(() {
      _pending.add(pending);
      _sending = true;
    });
    _scrollToEnd();
    if (_isDemo) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      setState(() {
        _pending.remove(pending);
        _messages = [
          ..._messages,
          {
            'id': DateTime.now().millisecondsSinceEpoch,
            'body': text,
            'is_mine': true,
            'created_at': DateTime.now().toIso8601String(),
          },
        ];
        _sending = false;
      });
      _scrollToEnd();
      _simulateDemoReply(text);
      return;
    }
    bool ok = false;
    try {
      final res = await _state.api.dio.post(
        '/chat/conversations/${widget.conversationId}/messages',
        data: {'body': text},
      );
      ok = res.data is Map && res.data['status'] == 'success';
      if (ok) await _loadMessages(scrollToBottom: true);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      if (ok) {
        _pending.remove(pending);
      } else {
        pending['_failed'] = true;
      }
      _sending = _pending.any((p) => p['_failed'] != true);
    });
  }

  void _retry(Map<String, dynamic> p) {
    setState(() => _pending.remove(p));
    _sendText(p['body'].toString());
  }

  Future<void> _sendPhoto(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() => _sending = true);
    try {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap({
        'attachment': MultipartFile.fromBytes(
          bytes,
          filename: file.name.isNotEmpty ? file.name : 'chat_image.jpg',
        ),
      });
      final res = await _state.api.dio.post(
        '/chat/conversations/${widget.conversationId}/messages',
        data: formData,
      );
      if (res.data is Map && res.data['status'] == 'success') {
        await _loadMessages(scrollToBottom: true);
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  void _showAttachSheet() {
    final s = _state.s;
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADDE2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _attachOption(
                      CupertinoIcons.photo_fill_on_rectangle_fill,
                      s.tr('الصور', 'Galerie'),
                      const Color(0xFF4F5BD5),
                      () {
                        Navigator.pop(ctx);
                        _sendPhoto(ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _attachOption(
                      CupertinoIcons.camera_fill,
                      s.tr('الكاميرا', 'Caméra'),
                      _red,
                      () {
                        Navigator.pop(ctx);
                        _sendPhoto(ImageSource.camera);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _openImage(String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _ImageViewer(url: url),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  bool _isMine(dynamic m) => m['is_mine'] == true;

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final all = [..._messages, ..._pending];

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(s),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator(radius: 13))
                : all.isEmpty
                    ? _buildEmpty(s)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        itemCount: all.length,
                        itemBuilder: (_, idx) => _buildMessage(all, idx, s),
                      ),
          ),
          _buildComposer(s),
        ],
      ),
    );
  }

  // ───────────────────────── Header ─────────────────────────
  Widget _buildHeader(dynamic s) {
    final topInset = MediaQuery.of(context).padding.top;
    final hasAd = widget.adTitle.isNotEmpty;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: Colors.white.withValues(alpha: 0.94),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(8, topInset + 6, 14, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        s.isAr ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
                        color: _ink,
                        size: 24,
                      ),
                    ),
                    widget.peerAvatar != null && widget.peerAvatar!.trim().isNotEmpty
                        ? AppAvatar(url: widget.peerAvatar, radius: 21, iconColor: _red)
                        : ChatInitialAvatar(name: widget.peerName, size: 42),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            _sending
                                ? s.tr('جاري الإرسال...', 'Envoi en cours...')
                                : s.tr('محادثة آمنة على أبولو', 'Discussion sécurisée Apolo'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    _headerBtn(CupertinoIcons.ellipsis, () => _showMoreSheet(s)),
                  ],
                ),
              ),
              if (hasAd) _buildAdBar(s),
              Container(height: 0.6, color: const Color(0xFFE6E8EC)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(color: _fill, shape: BoxShape.circle),
        child: Icon(icon, size: 19, color: _ink),
      ),
    );
  }

  Widget _buildAdBar(dynamic s) {
    final hasPrice = widget.adPrice != null && widget.adPrice!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.adImage != null
                ? AppImage(url: widget.adImage, width: 42, height: 42, fit: BoxFit.cover)
                : const Icon(CupertinoIcons.tag_fill, color: _red, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.adTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPrice ? widget.adPrice! : s.tr('الإعلان المعني', 'Annonce concernée'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasPrice ? FontWeight.w800 : FontWeight.w500,
                    color: hasPrice ? _red : _muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.checkmark_shield_fill, size: 18, color: Color(0xFF1FA67A)),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _showMoreSheet(dynamic s) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.peerName),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _loadMessages(scrollToBottom: true);
            },
            child: Text(s.tr('تحديث المحادثة', 'Actualiser la discussion')),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text(s.tr('تم إرسال البلاغ، شكراً لك', 'Signalement envoyé, merci')),
                ),
              );
            },
            child: Text(s.tr('الإبلاغ عن المستخدم', 'Signaler l\'utilisateur')),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.tr('إلغاء', 'Annuler')),
        ),
      ),
    );
  }

  // ───────────────────────── Empty / Quick replies ─────────────────────────
  Widget _buildEmpty(dynamic s) {
    final List<String> quick = [
      s.tr('السلام، واش مازال متوفر؟', 'Bonjour, est-ce toujours disponible ?'),
      s.tr('شحال آخر ثمن؟', 'Quel est votre dernier prix ?'),
      s.tr('فين نقدر نشوفو؟', 'Où peut-on le voir ?'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEECEE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(CupertinoIcons.hand_raised_fill, color: _red, size: 32),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.tr('قل السلام لـ ${widget.peerName}', 'Dites bonjour à ${widget.peerName}'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
        ),
        const SizedBox(height: 6),
        Text(
          s.tr(
            'ما تصيفطش الفلوس قبل ما تشوف السلعة. تواصل دائماً عبر أبولو.',
            "Ne payez jamais avant d'avoir vu l'article. Restez sur Apolo.",
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.45, color: _muted),
        ),
        const SizedBox(height: 24),
        ...quick.map(
          (q) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _sendText(q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE9EBEF)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        q,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                    const Icon(CupertinoIcons.arrow_up_circle_fill, color: _red, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Messages ─────────────────────────
  Widget _buildMessage(List<dynamic> all, int idx, dynamic s) {
    final m = all[idx];
    final bool isMine = _isMine(m);
    final DateTime? time = parseChatDate(m['created_at']);
    final prev = idx > 0 ? all[idx - 1] : null;
    final next = idx < all.length - 1 ? all[idx + 1] : null;
    final DateTime? prevTime = prev != null ? parseChatDate(prev['created_at']) : null;
    final DateTime? nextTime = next != null ? parseChatDate(next['created_at']) : null;

    final bool newDay = time != null && (prevTime == null || !isSameChatDay(time, prevTime));
    final bool groupedWithPrev = prev != null && _isMine(prev) == isMine && !newDay;
    final bool groupedWithNext = next != null &&
        _isMine(next) == isMine &&
        !(time != null && nextTime != null && !isSameChatDay(time, nextTime));

    final attachUrl = m['attachment_url'] ?? m['attachment'];
    final String body = (m['body'] ?? '').toString();
    final bool pending = m['_pending'] == true;
    final bool failed = m['_failed'] == true;
    final bool read = m['is_read'] == true || m['read_at'] != null;

    const big = Radius.circular(20);
    const small = Radius.circular(6);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    // "end" side is where my bubbles sit.
    final Radius topEnd = isMine && groupedWithPrev ? small : big;
    final Radius bottomEnd = isMine && groupedWithNext ? small : (isMine ? small : big);
    final Radius topStart = !isMine && groupedWithPrev ? small : big;
    final Radius bottomStart = !isMine && groupedWithNext ? small : (!isMine ? small : big);
    final radius = BorderRadius.only(
      topLeft: rtl ? topEnd : topStart,
      topRight: rtl ? topStart : topEnd,
      bottomLeft: rtl ? bottomEnd : bottomStart,
      bottomRight: rtl ? bottomStart : bottomEnd,
    );

    final Color fg = isMine ? Colors.white : _incomingText;
    final Color metaColor = isMine ? Colors.white.withValues(alpha: 0.78) : _muted;

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (time != null)
          Text(formatChatClock(time), style: TextStyle(fontSize: 11, color: metaColor)),
        if (isMine) ...[
          const SizedBox(width: 3),
          Icon(
            failed
                ? CupertinoIcons.exclamationmark_circle_fill
                : pending
                    ? CupertinoIcons.clock
                    : (read ? Icons.done_all_rounded : Icons.done_rounded),
            size: 14,
            color: failed ? const Color(0xFFFFD2D4) : metaColor,
          ),
        ],
      ],
    );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
      padding: attachUrl != null && body.isEmpty
          ? const EdgeInsets.all(4)
          : const EdgeInsets.fromLTRB(13, 9, 13, 7),
      decoration: BoxDecoration(
        color: isMine ? (failed ? const Color(0xFFB8141B) : _red) : _incoming,
        gradient: isMine && !failed
            ? const LinearGradient(
                colors: [Color(0xFFEE2A32), Color(0xFFD9141C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: radius,
        boxShadow: isMine
            ? null
            : [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachUrl != null)
            GestureDetector(
              onTap: () => _openImage(attachUrl.toString()),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    AppImage(
                      url: attachUrl.toString(),
                      width: 230,
                      height: 230,
                      fit: BoxFit.cover,
                    ),
                    if (body.isEmpty)
                      PositionedDirectional(
                        end: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: DefaultTextStyle.merge(
                            style: const TextStyle(color: Colors.white),
                            child: IconTheme.merge(
                              data: const IconThemeData(color: Colors.white),
                              child: meta,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (body.isNotEmpty) ...[
            if (attachUrl != null) const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(
                  body,
                  style: TextStyle(color: fg, fontSize: 15.5, height: 1.35),
                ),
                Padding(padding: const EdgeInsets.only(top: 4), child: meta),
              ],
            ),
          ],
        ],
      ),
    );

    return Column(
      children: [
        if (newDay)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EBEF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  formatChatDayLabel(time, s),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5B6576),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: groupedWithNext ? 3 : 10),
          child: Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (failed)
                GestureDetector(
                  onTap: () => _retry(m as Map<String, dynamic>),
                  child: const Padding(
                    padding: EdgeInsetsDirectional.only(end: 6, bottom: 6),
                    child: Icon(CupertinoIcons.arrow_clockwise_circle_fill, color: _red, size: 22),
                  ),
                ),
              Flexible(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('${m['id'] ?? m['created_at']}_$idx'),
                  tween: Tween(begin: pending ? 0.0 : 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(
                    scale: 0.92 + 0.08 * v,
                    alignment: isMine
                        ? AlignmentDirectional.bottomEnd
                        : AlignmentDirectional.bottomStart,
                    child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                  ),
                  child: bubble,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Quick actions bar (Offer + quick replies) ─────────────────────────
  int? _parsePrice(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  String _fmtDh(int v) {
    final str = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return '$buf DH';
  }

  void _showOfferSheet(dynamic s) {
    HapticFeedback.mediumImpact();
    final base = _parsePrice(widget.adPrice);
    final customCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        Widget option(String label, int value) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              _sendText(s.tr('💰 عرض سعر: ${_fmtDh(value)} ($label)', '💰 Offre de prix : ${_fmtDh(value)} ($label)'));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _red)),
                  const SizedBox(height: 4),
                  Text(
                    _fmtDh(value),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: _ink),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDADDE2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.tr('قدم عرض سعر 💰', 'Faire une offre 💰'),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    base != null
                        ? s.tr('الثمن المعلن: ${_fmtDh(base)}', 'Prix affiché : ${_fmtDh(base)}')
                        : s.tr('كتب الثمن لي بغيتي تقترح', 'Indiquez le prix proposé'),
                    style: const TextStyle(fontSize: 13, color: _muted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (base != null) ...[
                    Row(
                      children: [
                        Expanded(child: option('-5%', (base * 0.95).round())),
                        const SizedBox(width: 8),
                        Expanded(child: option('-10%', (base * 0.90).round())),
                        const SizedBox(width: 8),
                        Expanded(child: option('-15%', (base * 0.85).round())),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: s.tr('ثمن آخر...', 'Autre montant...'),
                              hintStyle: const TextStyle(color: _muted),
                            ),
                          ),
                        ),
                        const Text('DH', style: TextStyle(fontWeight: FontWeight.w900, color: _muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      final v = _parsePrice(customCtrl.text);
                      if (v == null || v <= 0) return;
                      Navigator.pop(ctx);
                      _sendText(s.tr('💰 عرض سعر: ${_fmtDh(v)}', '💰 Offre de prix : ${_fmtDh(v)}'));
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(color: _red.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Text(
                        s.tr('إرسال العرض', 'Envoyer l\'offre'),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
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

  Widget _buildQuickBar(dynamic s) {
    final chips = <String>[
      s.tr('واش باقي متوفر؟', 'Toujours disponible ?'),
      s.tr('واش الثمن قابل للتفاوض؟', 'Prix négociable ?'),
      s.tr('فين نقدر نشوف السلعة؟', 'Où peut-on la voir ?'),
      s.tr('نقدر نجي اليوم 👍', 'Je peux passer aujourd\'hui 👍'),
    ];
    return Container(
      height: 46,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
        children: [
          GestureDetector(
            onTap: () => _showOfferSheet(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEE2A32), Color(0xFFD9141C)]),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.tag_fill, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    s.tr('قدم عرض 💰', 'Faire une offre 💰'),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          ...chips.map(
            (c) => Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: GestureDetector(
                onTap: () => _sendText(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Composer ─────────────────────────
  Widget _buildComposer(dynamic s) {
    final bool canSend = _msgCtrl.text.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!canSend) _buildQuickBar(s),
        _buildComposerRow(s, canSend),
      ],
    );
  }

  Widget _buildComposerRow(dynamic s, bool canSend) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E8EC), width: 0.6)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _showAttachSheet,
                child: Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: const BoxDecoration(color: _fill, shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.plus, color: _ink, size: 21),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _fill,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16, color: _ink, height: 1.3),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: s.tr('رسالة...', 'Message...'),
                      hintStyle: const TextStyle(color: Color(0xFF9AA2AF), fontSize: 16),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: canSend
                    ? GestureDetector(
                        key: const ValueKey('send'),
                        onTap: () => _sendText(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFEE2A32), Color(0xFFD9141C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 21),
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey('camera'),
                        onTap: () => _sendPhoto(ImageSource.camera),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(CupertinoIcons.camera, color: _ink, size: 23),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  final String url;
  const _ImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0).abs() > 300) Navigator.pop(context);
              },
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(child: AppImage(url: url, fit: BoxFit.contain)),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
