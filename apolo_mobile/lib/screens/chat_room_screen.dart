import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/state/app_state.dart';
import 'call_screen.dart';
import 'seller_profile_screen.dart';
import 'widgets/chat_utils.dart';

/// Text messaging; unsupported media actions are explicitly unavailable.
class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final String peerName;
  final int? peerId;
  final String adTitle;
  final String? peerAvatar;
  final String? adImage;
  final String? adPrice;
  final String? initialDraft;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
    this.peerId,
    this.adTitle = '',
    this.peerAvatar,
    this.adImage,
    this.adPrice,
    this.initialDraft,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  final AppState _state = AppState();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focus = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  bool _showCallMenu = false;
  bool _sending = false;
  bool _loadingRequest = false;
  String? _loadError;
  Timer? _pollTimer;
  Object? _accountId;

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _apoloRed = Color(0xFFE31B23);
  static const Color _surfaceGrey = Color(0xFFF3F4F6);
  static const Color _textBlack = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textSubtle = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountId = _state.currentUser?['id'];
    _state.addListener(_onAccountChanged);
    _loadMessages(scrollToBottom: true);

    if (widget.initialDraft != null) _msgCtrl.text = widget.initialDraft!;

    _msgCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _focus.addListener(() {
      if (_focus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToEnd);
      }
    });

    _startPolling();
  }

  void _onAccountChanged() {
    if (!mounted || _accountId == _state.currentUser?['id']) return;
    _accountId = _state.currentUser?['id'];
    setState(() {
      _messages = [];
      _pending.clear();
      _loading = false;
    });
    _msgCtrl.clear();
    _loadMessages();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      if (ModalRoute.of(context)?.isCurrent == true) {
        _loadMessages(silent: true);
      }
    } else {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _state.removeListener(_onAccountChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      setState(() {
        _messages = [];
        _pending.clear();
        _loading = true;
        _loadError = null;
        _msgCtrl.text = widget.initialDraft ?? '';
      });
      _loadMessages(scrollToBottom: true);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _loadMessages(
      {bool silent = false, bool scrollToBottom = false}) async {
    if (_loadingRequest || !mounted) return;
    final conversationId = widget.conversationId;
    final userId = _state.currentUser?['id'];
    _loadingRequest = true;
    try {
      if (!_state.isLoggedIn || conversationId <= 0) {
        throw StateError('Sign in required');
      }
      final res = await _state.api.dio
          .get('/chat/conversations/$conversationId/messages');
      if (res.data is! Map || res.data['status'] != 'success') {
        throw StateError('Messages unavailable');
      }
      final dynamic raw = res.data['messages'] ?? res.data['data'];
      final dynamic incoming = raw is Map ? raw['data'] : raw;
      if (incoming is! List) throw StateError('Invalid messages');
      if (!mounted ||
          conversationId != widget.conversationId ||
          userId != _state.currentUser?['id']) {
        return;
      }
      setState(() {
        _messages = incoming
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
        _loadError = null;
      });
      if (scrollToBottom) _scrollToEnd();
    } catch (_) {
      if (mounted && conversationId == widget.conversationId) {
        setState(() {
          _loading = false;
          _loadError = _state.s.tr('تعذر تحميل الرسائل. حاول مجدداً.',
              'Chargement impossible. Réessayez.');
        });
      }
    } finally {
      _loadingRequest = false;
      if (mounted && conversationId != widget.conversationId) _loadMessages();
    }
  }

  Future<void> _sendText([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty || _sending || !mounted) return;
    if (!_state.isLoggedIn || widget.conversationId <= 0) {
      _notice(_state.s.tr('سجّل الدخول لإرسال رسالة.',
          'Connectez-vous pour envoyer un message.'));
      return;
    }
    final conversationId = widget.conversationId;
    final userId = _state.currentUser?['id'];
    final tempMsg = <String, dynamic>{
      'body': text,
      'is_mine': true,
      'type': 'text',
      'read': false,
      'created_at_time': formatChatClock(DateTime.now()),
      '_pending': true,
    };
    setState(() {
      _sending = true;
      _pending.add(tempMsg);
    });
    _scrollToEnd();
    try {
      final res = await _state.api.dio.post(
          '/chat/conversations/$conversationId/messages',
          data: {'body': text, 'message': text});
      if (res.data is! Map || res.data['status'] != 'success') {
        throw StateError('Send not confirmed');
      }
      if (!mounted ||
          conversationId != widget.conversationId ||
          userId != _state.currentUser?['id']) {
        return;
      }
      final created = res.data['message'];
      setState(() {
        _pending.remove(tempMsg);
        if (created is Map &&
            !_messages
                .any((m) => m['id'] != null && m['id'] == created['id'])) {
          _messages.add(Map<String, dynamic>.from(created));
        }
      });
      if (preset == null && _msgCtrl.text.trim() == text) _msgCtrl.clear();
      await _loadMessages(silent: true);
      _scrollToEnd();
    } catch (_) {
      if (mounted &&
          conversationId == widget.conversationId &&
          userId == _state.currentUser?['id']) {
        if (preset != null && _msgCtrl.text.isEmpty) _msgCtrl.text = text;
        _notice(_state.s.tr(
            'تعذر تأكيد الإرسال. النص محفوظ؛ تحقق من المحادثة قبل إعادة المحاولة.',
            'Envoi non confirmé. Brouillon conservé ; vérifiez la conversation avant de réessayer.'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _pending.remove(tempMsg);
          _sending = false;
        });
      }
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _mediaUnavailable() => _notice(_state.s.tr(
      'الرسائل الصوتية والصور غير متاحة حالياً. لم يتم تسجيل أو إرسال أي ملف.',
      'Les messages vocaux et les photos sont indisponibles. Aucun fichier enregistré ou envoyé.'));

  // ───────────────────────── Voice & Video Calls ─────────────────────────
  void _startCall({required bool isVideo}) {
    setState(() => _showCallMenu = false);
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          peerName: widget.peerName,
          peerAvatar: widget.peerAvatar,
          isVideo: isVideo,
        ),
      ),
    );
  }

  void _openPeerProfile() {
    if (widget.peerId == null || widget.peerId! <= 0) return;
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfileScreen(
          sellerId: widget.peerId!,
          sellerName: widget.peerName,
          sellerAvatar: widget.peerAvatar,
          initialAd: widget.adTitle.isNotEmpty
              ? {
                  'title': widget.adTitle,
                  'price_formatted': widget.adPrice ?? '',
                  'main_image': widget.adImage ?? '',
                }
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = [..._messages, ..._pending];

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Main Chat Column
          Column(
            children: [
              _buildHeader(),
              if (_loadError != null)
                TextButton(
                    onPressed: () => _loadMessages(), child: Text(_loadError!)),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 12),
                      )
                    : GestureDetector(
                        onTap: () {
                          if (_showCallMenu) {
                            setState(() => _showCallMenu = false);
                          }
                          FocusScope.of(context).unfocus();
                        },
                        child: all.isEmpty
                            ? _buildEmptyChatState()
                            : ListView.builder(
                                controller: _scrollCtrl,
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                itemCount: all.length,
                                itemBuilder: (_, idx) {
                                  return _buildMessageBubble(all[idx], idx);
                                },
                              ),
                      ),
              ),
              _buildComposer(),
            ],
          ),

          // Floating Call Dropdown Menu Popup (Matching Reference)
          if (_showCallMenu)
            Positioned(
              top: MediaQuery.of(context).padding.top + 48,
              right: 16,
              child: _buildCallDropdownCard(),
            ),
        ],
      ),
    );
  }

  // ───────────────────────── 1. Header Bar ─────────────────────────

  Widget _buildEmptyChatState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEECEE),
                border: Border.all(
                    color: _apoloRed.withValues(alpha: 0.15), width: 2),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.chat_bubble_2_fill,
                    color: _apoloRed, size: 32),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.peerName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.adTitle.isNotEmpty
                  ? 'محادثة بخصوص: "${widget.adTitle}"'
                  : 'ابدأ المحادثة الآن واطرح استفساراتك مباشرة',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'رسائل سريعة مقترحة:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textSubtle,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickPill('السلام عليكم، واش الإعلان باقي متوفر؟'),
                _buildQuickPill('شحال آخر ثمن من فضلك؟'),
                _buildQuickPill('فين كاين بالضبط باش نشوف السلعة؟'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPill(String text) {
    return InkWell(
      onTap: () => _sendText(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _textBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(8, topInset + 4, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              CupertinoIcons.arrow_left,
              color: _textBlack,
              size: 22,
            ),
          ),
          GestureDetector(
            onTap: widget.peerId != null && widget.peerId! > 0
                ? _openPeerProfile
                : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _surfaceGrey,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child:
                    widget.peerAvatar != null && widget.peerAvatar!.isNotEmpty
                        ? Image.network(
                            widget.peerAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildAvatarFallback(widget.peerName),
                          )
                        : _buildAvatarFallback(widget.peerName),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.peerId != null && widget.peerId! > 0
                  ? _openPeerProfile
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textBlack,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _textSubtle,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _state.s.tr(
                            'حالة الاتصال غير متاحة', 'Statut indisponible'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Right Call Button with dropdown indicator (`📞 ⌵`)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showCallMenu = !_showCallMenu);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _showCallMenu ? _surfaceGrey : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.phone,
                    color: _textBlack,
                    size: 20,
                  ),
                  SizedBox(width: 3),
                  Icon(
                    CupertinoIcons.chevron_down,
                    color: _textBlack,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Call Dropdown Card (Voice & Video)
  Widget _buildCallDropdownCard() {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.phone, color: _apoloRed),
              title: Text(_state.s.tr('مكالمة صوتية — غير متاحة',
                  'Appel vocal — indisponible')),
              onTap: () => _startCall(isVideo: false),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.videocam_fill, color: _apoloRed),
              title: Text(_state.s.tr('مكالمة فيديو — غير متاحة',
                  'Appel vidéo — indisponible')),
              onTap: () => _startCall(isVideo: true),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 2. Message Bubbles ─────────────────────────
  Widget _buildMessageBubble(dynamic m, int index) {
    final bool isMine = m['is_mine'] == true;
    final String body = (m['body'] ?? '').toString();
    final String timeStr = (m['created_at_time'] ?? '').toString();
    final bool isAudio = m['type'] == 'audio';
    final String audioDuration = (m['audio_duration'] ?? '').toString();

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
            decoration: BoxDecoration(
              gradient: isMine
                  ? const LinearGradient(
                      colors: [_apoloRed, Color(0xFFC80E16)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isMine ? null : _surfaceGrey,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: isMine
                      ? _apoloRed.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAudio)
                  _buildAudioBubbleContent(index, audioDuration, isMine)
                else
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.35,
                      color: isMine ? Colors.white : _textBlack,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Spacer(),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isMine ? Colors.white70 : _textSubtle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        m['_pending'] == true
                            ? CupertinoIcons.clock
                            : m['read'] == true
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBubbleContent(int index, String duration, bool isMine) {
    return Text(
        _state.s.tr('رسالة صوتية — التشغيل غير متاح',
            'Message vocal — lecture indisponible'),
        style: TextStyle(color: isMine ? Colors.white : _textBlack));
  }

  Widget _buildComposer() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final canSend = _msgCtrl.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottomInset + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          // Left `+` button in circular soft grey container
          GestureDetector(
            onTap: _mediaUnavailable,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _surfaceGrey,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.plus,
                color: _textBlack,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Pill Text Field (`Type a message...`)
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _surfaceGrey,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat-draft'),
                      controller: _msgCtrl,
                      focusNode: _focus,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: _textBlack,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: _textSubtle,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (!canSend) ...[
                    GestureDetector(
                      onTap: _mediaUnavailable,
                      child: const Icon(
                        CupertinoIcons.camera,
                        color: _textMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Media integration is not available; tapping explains the limitation.
                    GestureDetector(
                      onTap: _mediaUnavailable,
                      child: const Icon(
                        CupertinoIcons.mic_fill,
                        color: _apoloRed,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Apolo Crimson Send Button
          if (canSend) ...[
            const SizedBox(width: 8),
            GestureDetector(
              key: const Key('chat-send'),
              onTap: _sending ? null : () => _sendText(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _apoloRed,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'R',
        style: const TextStyle(
          color: _textBlack,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
