import 'dart:async';

import 'package:flutter/material.dart';

/// Callback signature for emitting `{ 'typing': bool }` to Firebase / backend.
typedef TypingSignalEmitter = FutureOr<void> Function(Map<String, dynamic> payload);

/// Complete Typing Indicator Controller for Flutter + Firebase real-time chat.
///
/// Implements:
/// 1. **TYPING START SIGNAL**:
///    - Emits `{'typing': true}` only once per typing session (never on every keystroke).
///    - Uses a 1.2s debounce (`1–2s` window) so quick type-and-delete bursts never spam Firebase.
/// 2. **TYPING STOP SIGNAL**:
///    - Immediately emits `{'typing': false}` when the user sends a message or clears all text.
///    - Auto-emits `{'typing': false}` after `4s` (`3–5s` window) of keystroke inactivity.
/// 3. **EDGE CASES**:
///    - Types 1 character and puts phone down -> stays active until inactivity timeout sends stop.
///    - Sends message -> cancels pending timers and immediately emits `{'typing': false}`.
///    - Navigates away / disposes -> immediately emits `{'typing': false}` if currently typing.
/// 4. **PERFORMANCE**:
///    - Never broadcasts typing status to groups with `100+` members (`memberCount >= 100`).
///    - Throttles typing broadcasts to max 1 event per `2 seconds` per user.
class TypingIndicatorController {
  final TypingSignalEmitter onEmit;
  final int memberCount;
  final Duration startDebounce;
  final Duration inactivityTimeout;
  final Duration throttleInterval;
  final DateTime Function() _now;

  TypingIndicatorController({
    required this.onEmit,
    this.memberCount = 2,
    this.startDebounce = const Duration(milliseconds: 1200),
    this.inactivityTimeout = const Duration(seconds: 4),
    this.throttleInterval = const Duration(seconds: 2),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  /// Performance rule: Do not broadcast typing status to groups with 100+ members.
  static const int maxGroupMembersForTyping = 100;

  Timer? _debounceTimer;
  Timer? _inactivityTimer;
  Timer? _trailingThrottleTimer;

  bool _isBroadcastingTyping = false;
  bool _hasPendingStart = false;
  DateTime? _lastEmitAt;
  bool _disposed = false;

  bool get isBroadcastingTyping => _isBroadcastingTyping;
  bool get isAllowedForGroup => memberCount < maxGroupMembersForTyping;

  /// Call this whenever the chat input text changes.
  void onTextChanged(String text) {
    if (_disposed || !isAllowedForGroup) return;

    final hasText = text.trim().isNotEmpty;
    if (!hasText) {
      // User deleted all text -> cancel any pending debounced start & emit stop immediately
      _debounceTimer?.cancel();
      _inactivityTimer?.cancel();
      _hasPendingStart = false;
      if (_isBroadcastingTyping) {
        _emitTypingState(false);
      }
      return;
    }

    // Reset the 4-second inactivity timeout on every keystroke
    _resetInactivityTimeout();

    // Already broadcasting `{typing: true}` -> do NOT re-emit on every keystroke
    if (_isBroadcastingTyping) return;

    // First keystroke (or continuing before debounce completes):
    // Start 1.2s debounce so rapid type+delete doesn't spam Firebase
    if (!_hasPendingStart) {
      _hasPendingStart = true;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(startDebounce, () {
        _hasPendingStart = false;
        if (!_disposed && !_isBroadcastingTyping) {
          _emitTypingState(true);
        }
      });
    }
  }

  /// Edge case: User sends a message -> hide dots immediately + send `{typing: false}`.
  void onMessageSent() {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _inactivityTimer?.cancel();
    _trailingThrottleTimer?.cancel();
    _hasPendingStart = false;
    if (_isBroadcastingTyping) {
      _emitTypingState(false, bypassThrottle: true);
    }
  }

  /// Edge case: User navigates away from chat -> send `{typing: false}`.
  void onLeaveChat() {
    if (_disposed) return;
    _debounceTimer?.cancel();
    _inactivityTimer?.cancel();
    _trailingThrottleTimer?.cancel();
    _hasPendingStart = false;
    if (_isBroadcastingTyping) {
      _emitTypingState(false, bypassThrottle: true);
    }
  }

  void _resetInactivityTimeout() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () {
      _debounceTimer?.cancel();
      _hasPendingStart = false;
      if (!_disposed && _isBroadcastingTyping) {
        _emitTypingState(false);
      }
    });
  }

  void _emitTypingState(bool typing, {bool bypassThrottle = false}) {
    if (_disposed || !isAllowedForGroup) return;
    if (_isBroadcastingTyping == typing) return;

    final now = _now();
    if (!bypassThrottle && _lastEmitAt != null) {
      final elapsed = now.difference(_lastEmitAt!);
      if (elapsed < throttleInterval) {
        // Throttle: max 1 event per 2 seconds per user.
        // Schedule trailing emit after remaining throttle window so final state stays accurate.
        final remaining = throttleInterval - elapsed;
        _trailingThrottleTimer?.cancel();
        _trailingThrottleTimer = Timer(remaining, () {
          if (!_disposed && _isBroadcastingTyping != typing) {
            _commitEmit(typing);
          }
        });
        return;
      }
    }

    _trailingThrottleTimer?.cancel();
    _commitEmit(typing);
  }

  void _commitEmit(bool typing) {
    _isBroadcastingTyping = typing;
    _lastEmitAt = _now();
    onEmit(<String, dynamic>{'typing': typing});
  }

  void dispose() {
    if (_disposed) return;
    onLeaveChat();
    _disposed = true;
    _debounceTimer?.cancel();
    _inactivityTimer?.cancel();
    _trailingThrottleTimer?.cancel();
  }
}

/// 3 animated dots fading in sequence on a continuous 1.5-second loop.
class TypingIndicatorDots extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;
  final Duration loopDuration;

  const TypingIndicatorDots({
    super.key,
    this.color = const Color(0xFF6B7280),
    this.dotSize = 6.5,
    this.spacing = 4.0,
    this.loopDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<TypingIndicatorDots> createState() => _TypingIndicatorDotsState();
}

class _TypingIndicatorDotsState extends State<TypingIndicatorDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.loopDuration,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sequential staggered fade curve for dot index 0, 1, 2 within a 1.5s loop.
  double _opacityForDot(int index, double t) {
    final start = index * 0.22;
    final peak = start + 0.25;
    final end = start + 0.50;
    if (t < start || t > end) return 0.25;
    if (t <= peak) {
      final p = (t - start) / (peak - start);
      return 0.25 + 0.75 * Curves.easeOut.transform(p.clamp(0.0, 1.0));
    } else {
      final p = (t - peak) / (end - peak);
      return 1.0 - 0.75 * Curves.easeIn.transform(p.clamp(0.0, 1.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final opacity = _opacityForDot(index, t);
            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? widget.spacing : 0),
              child: Opacity(
                key: Key('typing-dot-$index'),
                opacity: opacity.clamp(0.25, 1.0),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Standalone UI component showing 3 animated dots when [isTyping] is `true`,
/// and hiding immediately when [isTyping] becomes `false` or on receiver timeout.
class TypingIndicatorBubble extends StatefulWidget {
  final bool isTyping;
  final String? label;
  final Duration autoHideTimeout;

  const TypingIndicatorBubble({
    super.key,
    required this.isTyping,
    this.label,
    this.autoHideTimeout = const Duration(seconds: 5),
  });

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble> {
  Timer? _hideTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _syncTimeout();
  }

  @override
  void didUpdateWidget(covariant TypingIndicatorBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTyping != widget.isTyping) {
      _syncTimeout();
    }
  }

  void _syncTimeout() {
    _hideTimer?.cancel();
    _timedOut = false;
    if (widget.isTyping) {
      _hideTimer = Timer(widget.autoHideTimeout, () {
        if (mounted) {
          setState(() => _timedOut = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping || _timedOut) {
      return const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      label: widget.label ?? 'Typing...',
      child: Container(
        key: const Key('typing-indicator-bubble'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TypingIndicatorDots(),
            if (widget.label != null && widget.label!.trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
