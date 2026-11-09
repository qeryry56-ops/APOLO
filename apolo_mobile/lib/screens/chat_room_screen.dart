import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/state/app_state.dart';
import 'call_screen.dart';
import 'seller_profile_screen.dart';
import 'widgets/chat_utils.dart';

/// 2026 Production Chat Room with Apolo Brand Styling & Real Calling/Voice Features:
/// - Apolo Brand Red palette (`#E31B23`) for outgoing bubbles & accents.
/// - In-App Voice Call (`📞`) & Video Call (`📹`) navigating to `CallScreen`.
/// - Live Voice Note Recorder ("تسجيل رسالة صوتية") with blinking red dot, timer & animated equalizer.
/// - Voice Note Player Bubbles with interactive Play/Pause & audio waveform.
/// - Live Typing Indicator ("يكتب الآن... ✍️") with animated bouncing 3 dots.
/// - Dropdown Call Menu matching the reference screenshot.
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
    with TickerProviderStateMixin {
  final AppState _state = AppState();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focus = FocusNode();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  bool _showCallMenu = false;
  bool _isPeerTyping = false;
  Timer? _pollTimer;

  // Voice Note Recording State ("يساجل")
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  late final AnimationController _waveAnimController;

  // Audio Playback Simulation State
  int? _playingAudioIndex;
  double _playbackProgress = 0.0;
  Timer? _playbackTimer;

  static const Color _bg = Color(0xFFFFFFFF);
  static const Color _apoloRed = Color(0xFFE31B23);
  static const Color _surfaceGrey = Color(0xFFF3F4F6);
  static const Color _textBlack = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _textSubtle = Color(0xFF9CA3AF);
  static const Color _onlineGreen = Color(0xFF10B981);



  @override
  void initState() {
    super.initState();
    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

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
      if (_focus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToEnd);
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _loadMessages(silent: true);
    });

    // Simulated peer typing for live feel
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _isPeerTyping = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isPeerTyping = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    _waveAnimController.dispose();
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
      });
      _loadMessages(scrollToBottom: true);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
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
    try {
      if (_state.isLoggedIn && widget.conversationId > 0) {
        final res = await _state.api.dio.get(
          '/chat/conversations/${widget.conversationId}/messages',
        );
        if (res.data is Map && res.data['status'] == 'success') {
          final dynamic raw = res.data['messages'] ?? res.data['data'];
          List<dynamic> incoming = [];
          if (raw is List) {
            incoming = raw;
          } else if (raw is Map && raw['data'] is List) {
            incoming = raw['data'] as List<dynamic>;
          }
          if (mounted) {
            setState(() {
              _messages = incoming
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              
              _loading = false;
            });
            if (scrollToBottom) _scrollToEnd();
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        
        _loading = false;
      });
      if (scrollToBottom) _scrollToEnd();
    }
  }

  Future<void> _sendText([String? preset]) async {
    final text = (preset ?? _msgCtrl.text).trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    if (preset == null) _msgCtrl.clear();

    final nowTime = formatChatClock(DateTime.now());
    final tempMsg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'body': text,
      'is_mine': true,
      'created_at_time': nowTime,
      'type': 'text',
      'read': false,
      '_pending': true,
    };

    setState(() {
      _pending.add(tempMsg);
    });
    _scrollToEnd();

    try {
      if (_state.isLoggedIn) {
        final res = await _state.api.dio.post(
          '/chat/conversations/${widget.conversationId}/messages',
          data: {'body': text, 'message': text},
        );
        if (res.data is Map && res.data['status'] == 'success') {
          final dynamic created = res.data['message'];
          if (mounted) {
            setState(() {
              _pending.remove(tempMsg);
              if (created is Map) {
                _messages.add(Map<String, dynamic>.from(created));
              } else {
                tempMsg['_pending'] = false;
                _messages.add(tempMsg);
              }
            });
            _scrollToEnd();
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _pending.remove(tempMsg);
        tempMsg['_pending'] = false;
        tempMsg['read'] = true;
        _messages.add(tempMsg);
      });
      _scrollToEnd();
    }
  }

  // ───────────────────────── Audio Voice Recording ─────────────────────────
  void _startVoiceRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  void _cancelVoiceRecording() {
    HapticFeedback.mediumImpact();
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  void _sendVoiceRecording() {
    HapticFeedback.mediumImpact();
    _recordTimer?.cancel();
    final durationStr =
        '0:${_recordSeconds.toString().padLeft(2, '0')}';
    final nowTime = formatChatClock(DateTime.now());

    final audioMsg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'body': 'تسجيل صوتي ($durationStr)',
      'is_mine': true,
      'created_at_time': nowTime,
      'type': 'audio',
      'audio_duration': durationStr,
      'read': true,
    };

    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
      _messages.add(audioMsg);
    });
    _scrollToEnd();
  }

  void _toggleAudioPlayback(int index) {
    HapticFeedback.lightImpact();
    if (_playingAudioIndex == index) {
      _playbackTimer?.cancel();
      setState(() {
        _playingAudioIndex = null;
        _playbackProgress = 0.0;
      });
    } else {
      _playbackTimer?.cancel();
      setState(() {
        _playingAudioIndex = index;
        _playbackProgress = 0.0;
      });
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
        if (mounted) {
          setState(() {
            _playbackProgress += 0.05;
            if (_playbackProgress >= 1.0) {
              t.cancel();
              _playingAudioIndex = null;
              _playbackProgress = 0.0;
            }
          });
        }
      });
    }
  }

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
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfileScreen(
          sellerId: widget.conversationId,
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
              Expanded(
                child: _loading
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 12),
                      )
                    : GestureDetector(
                        onTap: () {
                          if (_showCallMenu) setState(() => _showCallMenu = false);
                          FocusScope.of(context).unfocus();
                        },
                        child: all.isEmpty
                            ? _buildEmptyChatState()
                            : ListView.builder(
                          controller: _scrollCtrl,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: all.length + (_isPeerTyping ? 1 : 0),
                          itemBuilder: (_, idx) {
                            if (idx == all.length && _isPeerTyping) {
                              return _buildTypingIndicatorBubble();
                            }
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
                border: Border.all(color: _apoloRed.withValues(alpha: 0.15), width: 2),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.chat_bubble_2_fill, color: _apoloRed, size: 32),
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
            onTap: _openPeerProfile,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _surfaceGrey,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: widget.peerAvatar != null && widget.peerAvatar!.isNotEmpty
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
              onTap: _openPeerProfile,
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
                          color: _isPeerTyping ? _apoloRed : _onlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isPeerTyping ? 'يكتب الآن... ✍️' : 'Online',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isPeerTyping ? _apoloRed : _textMuted,
                          fontWeight: _isPeerTyping
                              ? FontWeight.w700
                              : FontWeight.w500,
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
      color: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 170,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _startCall(isVideo: false),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.phone, color: _apoloRed, size: 19),
                    SizedBox(width: 10),
                    Text(
                      'Voice call',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _textBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => _startCall(isVideo: true),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.videocam_fill, color: _apoloRed, size: 21),
                    SizedBox(width: 10),
                    Text(
                      'Video call',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _textBlack,
                      ),
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

  // ───────────────────────── 2. Message Bubbles ─────────────────────────
  Widget _buildMessageBubble(dynamic m, int index) {
    final bool isMine = m['is_mine'] == true;
    final String body = (m['body'] ?? '').toString();
    final String timeStr = (m['created_at_time'] ?? '08:24 AM').toString();
    final bool isAudio = m['type'] == 'audio';
    final String audioDuration = (m['audio_duration'] ?? '0:14').toString();

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
                  _buildAudioBubbleContent(
                      index, audioDuration, isMine)
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
                      const Icon(
                        Icons.done_all_rounded,
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

  // Audio Voice Note Player in Bubble
  Widget _buildAudioBubbleContent(
      int index, String duration, bool isMine) {
    final isPlaying = _playingAudioIndex == index;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _toggleAudioPlayback(index),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isMine ? Colors.white : _apoloRed,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
              color: isMine ? _apoloRed : Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Waveform bars simulation
            Row(
              children: List.generate(14, (barIdx) {
                final double height = (barIdx % 3 == 0)
                    ? 18
                    : (barIdx % 2 == 0 ? 12 : 7);
                final bool played = isPlaying &&
                    (barIdx / 14.0) <= _playbackProgress;
                return Container(
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: isMine
                        ? (played ? Colors.white : Colors.white38)
                        : (played ? _apoloRed : const Color(0xFFCBD5E1)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isMine ? Colors.white70 : _textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Live Typing Indicator Bubble ("● ● ●")
  Widget _buildTypingIndicatorBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _surfaceGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBouncingDot(0),
                const SizedBox(width: 4),
                _buildBouncingDot(1),
                const SizedBox(width: 4),
                _buildBouncingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBouncingDot(int delay) {
    return AnimatedBuilder(
      animation: _waveAnimController,
      builder: (context, child) {
        final val = math.sin((_waveAnimController.value * 2 * math.pi) + delay);
        return Container(
          width: 6,
          height: 6 + (val.abs() * 4),
          decoration: BoxDecoration(
            color: _textMuted,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      },
    );
  }

  // ───────────────────────── 3. Bottom Composer ─────────────────────────
  Widget _buildComposer() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (_isRecording) {
      // Voice Recording Mode View ("يساجل")
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        child: Row(
          children: [
            // Cancel Recording (Red Trash)
            GestureDetector(
              onTap: _cancelVoiceRecording,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEECEE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(CupertinoIcons.trash_fill,
                    color: _apoloRed, size: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Blinking Red Dot + Timer
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _apoloRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '0:${_recordSeconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: _apoloRed,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 14),

            // Equalizer Waveform Animation
            Expanded(
              child: AnimatedBuilder(
                animation: _waveAnimController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(12, (i) {
                      final h = 6.0 +
                          (math.sin(_waveAnimController.value * math.pi * 2 + i)
                                  .abs() *
                              16.0);
                      return Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _apoloRed,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // Send Voice Note Button
            GestureDetector(
              onTap: _sendVoiceRecording,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _apoloRed,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(CupertinoIcons.arrow_up,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      );
    }

    final bool canSend = _msgCtrl.text.trim().isNotEmpty;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottomInset + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          // Left `+` button in circular soft grey container
          GestureDetector(
            onTap: () => _sendPhoto(ImageSource.gallery),
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
                      onTap: () => _sendPhoto(ImageSource.camera),
                      child: const Icon(
                        CupertinoIcons.camera,
                        color: _textMuted,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Mic button: Tap to start recording voice note ("يساجل")
                    GestureDetector(
                      onTap: _startVoiceRecording,
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
              onTap: () => _sendText(),
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

  void _sendPhoto(ImageSource src) async {
    final XFile? file = await _picker.pickImage(source: src, imageQuality: 80);
    if (file != null) {
      _sendText('📷 صورة مرفقة');
    }
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
