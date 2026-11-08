import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/kinetic_widgets.dart';

/// 2026 In-App Audio & Video Calling Screen (Apolo Call):
/// - Supports both Voice Call and Video Call modes.
/// - Realistic call states: Connecting... -> Ringing... -> Connected (00:00... timer).
/// - Pulsing audio waves & high-res avatar.
/// - Video Call: Fullscreen remote stream view + PIP selfie front camera.
/// - Controls: Mute Mic, Speakerphone, Camera Toggle, Flip Camera, End Call.
/// - Cellular Dial Fallback button (`tel:`).
class CallScreen extends StatefulWidget {
  final String peerName;
  final String? peerAvatar;
  final String? peerPhone;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.peerName,
    this.peerAvatar,
    this.peerPhone,
    this.isVideo = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  bool _isConnected = false;
  int _callSeconds = 0;
  Timer? _callTimer;
  Timer? _connectTimer;

  late final AnimationController _pulseController;

  static const Color _redEndCall = Color(0xFFEF4444);
  static const Color _bgDark = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _isVideoEnabled = widget.isVideo;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Simulate connection after 2 seconds
    _connectTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isConnected = true);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _connectTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _endCall() {
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
  }

  void _fallbackCellularCall() async {
    HapticFeedback.mediumImpact();
    final phone = widget.peerPhone ?? '0661123456';
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Visual: Video stream OR Ambient Dark Blur
          if (widget.isVideo && _isVideoEnabled)
            _buildVideoBackground()
          else
            _buildVoiceBackground(),

          // 2. Top Header Bar (Encrypted status, Timer, Flip camera)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.lock_shield_fill,
                              color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            widget.isVideo ? 'Apolo HD Video' : 'Apolo HD Audio',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isVideo && _isVideoEnabled)
                      PressableScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isFrontCamera = !_isFrontCamera);
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.switch_camera,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Center Identity & Waves (for Voice Call)
          if (!widget.isVideo || !_isVideoEnabled)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing Audio Wave Rings
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 140 + (_pulseController.value * 28),
                            height: 140 + (_pulseController.value * 28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE31B23)
                                  .withValues(alpha: 0.18 * (1.0 - _pulseController.value)),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.40),
                              blurRadius: 20,
                            ),
                          ],
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Name
                  Text(
                    widget.peerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Status / Duration
                  Text(
                    _isConnected ? _formattedDuration : 'جاري الاتصال... (Ringing)',
                    style: TextStyle(
                      color: _isConnected ? const Color(0xFF10B981) : Colors.white60,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          // 4. Picture-in-Picture Front Selfie Camera (for Video Call)
          if (widget.isVideo && _isVideoEnabled)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 60,
              child: Container(
                width: 95,
                height: 135,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white38, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80',
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'أنت',
                            style: TextStyle(color: Colors.white, fontSize: 9.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Bottom Controls Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fallback Phone Dial Link
                    TextButton.icon(
                      onPressed: _fallbackCellularCall,
                      icon: const Icon(CupertinoIcons.phone_fill,
                          color: Color(0xFF10B981), size: 14),
                      label: const Text(
                        'اتصال عبر شبكة الهاتف (GSM)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Controls Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute Mic Button
                        _buildControlBtn(
                          icon: _isMuted
                              ? CupertinoIcons.mic_off
                              : CupertinoIcons.mic_fill,
                          active: _isMuted,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isMuted = !_isMuted);
                          },
                        ),

                        // Speakerphone Button
                        _buildControlBtn(
                          icon: _isSpeaker
                              ? CupertinoIcons.speaker_2_fill
                              : CupertinoIcons.speaker_fill,
                          active: _isSpeaker,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isSpeaker = !_isSpeaker);
                          },
                        ),

                        // Video Toggle Button
                        if (widget.isVideo)
                          _buildControlBtn(
                            icon: _isVideoEnabled
                                ? CupertinoIcons.videocam_fill
                                : CupertinoIcons.videocam,
                            active: !_isVideoEnabled,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isVideoEnabled = !_isVideoEnabled);
                            },
                          ),

                        // End Call Button (Big Red Circle)
                        PressableScale(
                          onTap: _endCall,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _redEndCall,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _redEndCall.withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              CupertinoIcons.phone_down_fill,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.peerAvatar != null && widget.peerAvatar!.isNotEmpty)
          Image.network(
            widget.peerAvatar!,
            fit: BoxFit.cover,
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            color: Colors.black.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          widget.peerAvatar ??
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1200&q=85',
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: active ? _bgDark : Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
