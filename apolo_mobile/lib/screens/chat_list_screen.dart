import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/state/app_state.dart';
import 'chat_room_screen.dart';
import 'auth_screen.dart';
import 'widgets/app_image.dart';
import 'widgets/chat_utils.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AppState _state = AppState();
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _conversations = [];
  bool _loading = true;
  bool _unreadOnly = false;
  Timer? _pollTimer;

  static const Color _ink = Color(0xFF0F1B2D);
  static const Color _red = Color(0xFFE31B23);
  static const Color _muted = Color(0xFF8A94A6);
  static const Color _fill = Color(0xFFF2F3F5);
  static const Color _divider = Color(0xFFEFF1F4);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _loadConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _state.isLoggedIn) _loadConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchCtrl.dispose();
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

  int _unreadOf(dynamic c) => int.tryParse((c['unread_count'] ?? 0).toString()) ?? 0;

  List<dynamic> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _conversations.where((c) {
      if (_unreadOnly && _unreadOf(c) == 0) return false;
      if (q.isEmpty) return true;
      final name = (c['other_user']?['name'] ?? '').toString().toLowerCase();
      final ad = (c['ad']?['title'] ?? '').toString().toLowerCase();
      final msg = (c['latest_message']?['body'] ?? '').toString().toLowerCase();
      return name.contains(q) || ad.contains(q) || msg.contains(q);
    }).toList();
  }

  void _openConversation(dynamic conv) {
    final s = _state.s;
    final peer = conv['other_user'] ?? {};
    final ad = conv['ad'] ?? {};
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: int.tryParse(conv['id'].toString()) ?? 0,
          peerName: (peer['name'] ?? s.tr('مستخدم أبولو', 'Utilisateur Apolo')).toString(),
          adTitle: (ad['title'] ?? '').toString(),
          peerAvatar: (peer['avatar_url'] ?? peer['avatar'])?.toString(),
          adImage: chatAdImage(ad),
          adPrice: (ad['price_formatted'] ?? '').toString(),
        ),
      ),
    ).then((_) => _loadConversations(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    final topInset = MediaQuery.of(context).padding.top;

    if (!_state.isLoggedIn) return _buildLoggedOut(s);

    final items = _filtered;
    final totalUnread = _conversations.fold<int>(0, (a, c) => a + _unreadOf(c));

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _red,
        onRefresh: () => _loadConversations(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.messages,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: _ink,
                            ),
                          ),
                        ),
                        _circleBtn(CupertinoIcons.arrow_clockwise, () => _loadConversations()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Search pill
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.search, size: 18, color: _muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(fontSize: 15.5, color: _ink),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: s.tr('ابحث في المحادثات', 'Rechercher une discussion'),
                                hintStyle: const TextStyle(color: _muted, fontSize: 15.5),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: _searchCtrl.clear,
                              child: const Icon(CupertinoIcons.xmark_circle_fill,
                                  size: 18, color: Color(0xFFB4BAC4)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Filter chips
                    Row(
                      children: [
                        _chip(s.tr('الكل', 'Toutes'), !_unreadOnly,
                            () => setState(() => _unreadOnly = false)),
                        const SizedBox(width: 8),
                        _chip(
                          totalUnread > 0
                              ? '${s.tr('غير مقروءة', 'Non lues')} · $totalUnread'
                              : s.tr('غير مقروءة', 'Non lues'),
                          _unreadOnly,
                          () => setState(() => _unreadOnly = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate((_, __) => const _SkeletonRow(), childCount: 7),
              )
            else if (items.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(s))
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, idx) => _buildRow(items[idx], idx == items.length - 1),
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(dynamic conv, bool isLast) {
    final s = _state.s;
    final peer = conv['other_user'] ?? {};
    final ad = conv['ad'] ?? {};
    final lastMsg = conv['latest_message'];
    final unread = _unreadOf(conv);
    final avatar = (peer['avatar_url'] ?? peer['avatar'])?.toString();
    final adImg = chatAdImage(ad);
    final peerName = (peer['name'] ?? s.tr('مستخدم أبولو', 'Utilisateur Apolo')).toString();
    final adTitle = (ad['title'] ?? '').toString();
    final bool lastIsMine = lastMsg != null && lastMsg['is_mine'] == true;
    final bool hasAttachment = lastMsg != null &&
        (lastMsg['attachment_url'] ?? lastMsg['attachment']) != null;
    final String body = (lastMsg?['body'] ?? '').toString();
    final String preview = lastMsg == null
        ? s.tr('ابدأ المحادثة الآن', 'Démarrer la discussion')
        : (body.isEmpty && hasAttachment ? s.tr('صورة', 'Photo') : body);
    final DateTime? time =
        parseChatDate(lastMsg?['created_at'] ?? conv['updated_at'] ?? conv['last_message_at']);

    return InkWell(
      onTap: () => _openConversation(conv),
      splashColor: _red.withValues(alpha: 0.04),
      highlightColor: _fill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + ad thumbnail badge
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _avatar(avatar, peerName, 27),
                  if (adImg != null)
                    PositionedDirectional(
                      end: -4,
                      bottom: -2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                          color: _fill,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AppImage(url: adImg, width: 26, height: 26, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: isLast ? null : const Border(bottom: BorderSide(color: _divider)),
                ),
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
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700,
                              color: _ink,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (time != null)
                          Text(
                            formatChatListTime(time, s),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                              color: unread > 0 ? _red : _muted,
                            ),
                          ),
                      ],
                    ),
                    if (adTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        adTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5B6576),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lastIsMine) ...[
                          Icon(
                            lastMsg['is_read'] == true || lastMsg['read_at'] != null
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 16,
                            color: lastMsg['is_read'] == true || lastMsg['read_at'] != null
                                ? _red
                                : _muted,
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (hasAttachment) ...[
                          const Icon(CupertinoIcons.photo, size: 15, color: _muted),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                              color: unread > 0 ? _ink : _muted,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _red,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? url, String name, double radius) {
    if (url != null && url.trim().isNotEmpty) {
      return AppAvatar(url: url, radius: radius, iconColor: _red);
    }
    return ChatInitialAvatar(name: name, size: radius * 2);
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: _fill, shape: BoxShape.circle),
        child: Icon(icon, size: 19, color: _ink),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _ink : _fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF3A4252),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(dynamic s) {
    final bool filtering = _searchCtrl.text.isNotEmpty || _unreadOnly;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFEECEE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              filtering ? CupertinoIcons.search : CupertinoIcons.chat_bubble_2_fill,
              color: _red,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtering
                ? s.tr('ما كاين حتى نتيجة', 'Aucun résultat')
                : s.tr('لا توجد محادثات حالياً', 'Aucune conversation'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 6),
          Text(
            filtering
                ? s.tr('جرب كلمة أخرى أو بدل الفلتر.', 'Essayez un autre mot ou filtre.')
                : s.tr(
                    'افتح أي إعلان واضغط على زر الدردشة لبدء محادثة فورية.',
                    'Ouvrez une annonce et appuyez sur Discuter pour démarrer une conversation.',
                  ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14.5, height: 1.45, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOut(dynamic s) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEECEE),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 36, color: _red),
              ),
              const SizedBox(height: 22),
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
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
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
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F2F4),
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(color: Color(0xFFF1F2F4), shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [bar(120, 14), const Spacer(), bar(34, 10)]),
                const SizedBox(height: 8),
                bar(90, 10),
                const SizedBox(height: 8),
                bar(double.infinity, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
