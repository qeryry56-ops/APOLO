import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
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
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages(scrollToBottom: true);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _loadMessages(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      final res = await _state.api.dio.post(
        '/chat/conversations/${widget.conversationId}/messages',
        data: {'body': text},
      );
      if (res.data is Map && res.data['status'] == 'success') {
        await _loadMessages(scrollToBottom: true);
      }
    } catch (_) {}
  }

  Future<void> _sendPhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.peerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.adTitle.isNotEmpty)
              Text(
                widget.adTitle,
                style: const TextStyle(fontSize: 11.5, color: AppConfig.textSecondary),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadMessages(scrollToBottom: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, idx) {
                      final m = _messages[idx];
                      final bool isMine = m['is_mine'] == true;
                      final attachUrl = m['attachment_url'] ?? m['attachment'];
                      return Align(
                        alignment: isMine
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMine ? AppConfig.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isMine
                                ? null
                                : Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (attachUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AppImage(
                                      url: attachUrl.toString(),
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              if (m['body'] != null && m['body'].toString().isNotEmpty)
                                Text(
                                  m['body'].toString(),
                                  style: TextStyle(
                                    color: isMine ? Colors.white : AppConfig.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sendPhoto,
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppConfig.primary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onSubmitted: (_) => _sendText(),
                      decoration: InputDecoration(
                        hintText: s.tr('اكتب رسالتك هنا...', 'Écrivez votre message...'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppConfig.primary,
                    child: IconButton(
                      onPressed: _sendText,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
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
