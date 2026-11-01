import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
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

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!_state.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
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
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    if (!_state.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(s.messages)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.forum_outlined, size: 64, color: AppConfig.primary),
              const SizedBox(height: 14),
              Text(s.tr('سجّل دخولك لعرض رسائلك ومحادثاتك', 'Connectez-vous pour voir vos messages')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())).then((_) => _loadConversations()),
                child: Text(s.login),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.messages)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(child: Text(s.tr('لا توجد محادثات حالياً', 'Aucune conversation')))
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final conv = _conversations[idx];
                      final int id = int.tryParse(conv['id'].toString()) ?? 0;
                      final peer = conv['other_user'] ?? {};
                      final ad = conv['ad'] ?? {};
                      final lastMsg = conv['latest_message'];
                      final int unread = int.tryParse((conv['unread_count'] ?? 0).toString()) ?? 0;
                      final avatar = peer['avatar_url'] ?? peer['avatar'];

                      return Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  conversationId: id,
                                  peerName: (peer['name'] ?? 'Apolo User').toString(),
                                  adTitle: (ad['title'] ?? '').toString(),
                                ),
                              ),
                            ).then((_) => _loadConversations());
                          },
                          leading: AppAvatar(
                            url: avatar?.toString(),
                            radius: 24,
                          ),
                          title: Text(
                            (peer['name'] ?? 'Apolo User').toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ad['title'] != null)
                                Text(
                                  ad['title'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppConfig.primary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              if (lastMsg != null)
                                Text(
                                  (lastMsg['body'] ?? '📷 صورة').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: unread > 0
                              ? CircleAvatar(
                                  radius: 11,
                                  backgroundColor: AppConfig.accent,
                                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              : const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
