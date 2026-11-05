import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/state/app_state.dart';
import 'widgets/app_image.dart';

class ChatRoomScreen extends StatefulWidget {
  final int conversationId;
  final String peerName;
  final String adTitle;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
    required this.adTitle,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final AppState _state = AppState();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;

  // Exact Triply-AI assistant.tsx + Apolo Official Brand Red (#E31B23) tokens
  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _chatBlue = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _incomingBubble = Color(0xFFF1F2F4);
  static const Color _incomingText = Color(0xFF1A2436);
  static const Color _inputFill = Color(0xFFF2F3F5);
  static const Color _divider = Color(0xFFECEEF1);

  @override
  void initState() {
    super.initState();
    _loadMessages(scrollToBottom: true);
    _msgCtrl.addListener(_onInputChanged);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _loadMessages(silent: true);
    });
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.removeListener(_onInputChanged);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadMessages({bool silent = false, bool scrollToBottom = false}) async {
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
          if (scrollToBottom || hasNew) {
            _scrollToEnd();
          }
        }
        return;
      }
    } catch (_) {}
    if (!silent && mounted) setState(() => _loading = false);
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      final res = await _state.api.dio.post(
        '/chat/conversations/${widget.conversationId}/messages',
        data: {'body': text},
      );
      if (res.data is Map && res.data['status'] == 'success') {
        await _loadMessages(scrollToBottom: true);
      }
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _sendPhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
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

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final topInset = MediaQuery.of(context).padding.top;
    final bool canSend = _msgCtrl.text.trim().isNotEmpty && !_sending;
    final String initial = widget.peerName.trim().isNotEmpty
        ? widget.peerName.trim()[0].toUpperCase()
        : 'A';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header (Exact assistant.tsx layout)
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 10, 20, 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: _ink,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6BA5F8), Color(0xFF3A6EDA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.peerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.adTitle.isNotEmpty
                            ? widget.adTitle
                            : s.tr('محادثة مباشرة', 'Discussion en direct'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _loadMessages(scrollToBottom: true),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _inputFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF3A4252),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: _divider),

          // Messages List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _chatBlue),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: _incomingBubble,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              s.tr(
                                'ابدأ المحادثة بخصوص الإعلان، واطرح أي سؤال على المعلن.',
                                'Démarrez la discussion concernant cette annonce.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: _incomingText,
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (_, idx) {
                          final m = _messages[idx];
                          final bool isMine = m['is_mine'] == true;
                          final attachUrl = m['attachment_url'] ?? m['attachment'];
                          final String body = (m['body'] ?? '').toString();

                          return Align(
                            alignment: isMine
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.82,
                              ),
                              decoration: BoxDecoration(
                                color: isMine ? _chatBlue : _incomingBubble,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (attachUrl != null)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: body.isNotEmpty ? 8 : 0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: AppImage(
                                          url: attachUrl.toString(),
                                          height: 170,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  if (body.isNotEmpty)
                                    Text(
                                      body,
                                      style: TextStyle(
                                        color: isMine ? Colors.white : _incomingText,
                                        fontSize: 15,
                                        height: 1.4,
                                        fontWeight: isMine
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Input Bar (Exact assistant.tsx pill input + 52x52 arrow.up circle)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _sendPhoto,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: _inputFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        color: _ink,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: _inputFill,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        onSubmitted: (_) => _sendText(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: _ink,
                        ),
                        decoration: InputDecoration(
                          hintText: s.tr('اكتب رسالتك...', 'Écrire un message...'),
                          hintStyle: const TextStyle(
                            color: Color(0xFF9AA2AF),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: canSend ? _sendText : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: canSend ? _chatBlue : _inputFill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        size: 22,
                        color: canSend ? Colors.white : const Color(0xFF9AA2AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
