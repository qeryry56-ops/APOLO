import 'dart:async';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'chat_room_screen.dart';
import 'auth_screen.dart';
import 'widgets/app_image.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AppState _state = AppState();
  List<dynamic> _conversations = [];
  bool _loading = true;
  Timer? _pollTimer;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _blue = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _border = Color(0xFFEDEFF3);

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _state.isLoggedIn) {
        _loadConversations(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!_state.isLoggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!silent) setState(() => _loading = true);
    try {
      final res = await _state.api.dio.get('/chat/conversations');
      if (res.data is Map && res.data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _conversations = res.data['data'] ?? [];
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (!silent && mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final topInset = MediaQuery.of(context).padding.top;

    if (!_state.isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF1FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 32,
                    color: _blue,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  s.messages,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.tr(
                    'سجل دخولك باش تواصل مباشرة مع البائعين والمشترين',
                    'Connectez-vous pour discuter directement avec les vendeurs et acheteurs',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.45, color: _muted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ).then((_) => _loadConversations()),
                    child: Text(
                      s.login,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _blue,
        onRefresh: () => _loadConversations(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 120),
          children: [
            Text(
              s.messages,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _conversations.isEmpty
                  ? s.tr('رسائلك المباشرة مع المعلنين', 'Vos discussions en direct')
                  : s.tr(
                      '${_conversations.length} محادثات نشطة',
                      '${_conversations.length} conversations actives',
                    ),
              style: const TextStyle(fontSize: 14.5, color: _muted),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(color: _blue)),
              )
            else if (_conversations.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEECEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: _blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.tr('لا توجد محادثات حالياً', 'Aucune conversation'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.tr(
                        'افتح أي إعلان واضغط على زر الدردشة لبدء محادثة فورية.',
                        'Ouvrez une annonce et appuyez sur Discuter pour démarrer une conversation.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.4,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_conversations.length, (idx) {
                final conv = _conversations[idx];
                final int id = int.tryParse(conv['id'].toString()) ?? 0;
                final peer = conv['other_user'] ?? {};
                final ad = conv['ad'] ?? {};
                final lastMsg = conv['latest_message'];
                final int unread =
                    int.tryParse((conv['unread_count'] ?? 0).toString()) ?? 0;
                final avatar = peer['avatar_url'] ?? peer['avatar'];
                final String peerName =
                    (peer['name'] ?? s.tr('مستخدم أبولو', 'Utilisateur Apolo')).toString();
                final String adTitle = (ad['title'] ?? '').toString();
                final String previewText = lastMsg != null
                    ? (lastMsg['body'] ?? s.tr('صورة مرفقة', 'Photo jointe')).toString()
                    : s.tr('ابدأ المحادثة الآن', 'Démarrer la discussion');

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          conversationId: id,
                          peerName: peerName,
                          adTitle: adTitle,
                        ),
                      ),
                    ).then((_) => _loadConversations(silent: true));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: unread > 0 ? _blue.withValues(alpha: 0.35) : _border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ink.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AppAvatar(
                          url: avatar?.toString(),
                          radius: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      peerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _blue,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (adTitle.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEECEE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    adTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                previewText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight:
                                      unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                  color: unread > 0 ? _ink : _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9BA3B0),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
