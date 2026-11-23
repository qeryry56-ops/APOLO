import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/media_rtc_bridge.dart';

/// Recorded voice note payload emitted by [VoiceRecorder.onSend].
class VoiceRecordingData {
  final int durationSeconds;
  final String formattedDuration;
  final List<double> waveform;
  final String audioBase64;
  final String audioMime;

  const VoiceRecordingData({
    required this.durationSeconds,
    required this.formattedDuration,
    required this.waveform,
    this.audioBase64 = '',
    this.audioMime = 'audio/webm',
  });
}

/// Reusable, accessible Voice Message Recorder implementing all 5 Voice UX rules:
///
/// 1. **Instant Feedback on Press**:
///    - Immediately starts timer (`0:00`) + animates mic button scale up to `110%` (`1.10`) past thumb.
///    - Enters recording state before first word is spoken.
///    - Triggers haptic feedback (`HapticFeedback.mediumImpact()`) on press.
///
/// 2. **Slide to Cancel Threshold**:
///    - Fixed horizontal threshold (`80px` by default).
///    - Visual indicator `"Slide to cancel"` changes to `"Release to cancel"` past threshold.
///    - UI changes to a red trash can icon past threshold; releasing deletes recording without sending.
///
/// 3. **Lock for Long Messages**:
///    - Sliding up past vertical threshold (`60px` by default) locks recording mode hands-free.
///    - Frees thumb so recording continues after pointer release.
///    - Replaces mic button with an explicit `STOP` button (`min 44x44px`) to prevent accidental end.
///
/// 4. **Mic Check with Waveform**:
///    - Displays real-time audio waveform bars while recording.
///    - If waveform is flat (`< silenceThreshold`) for `2+ seconds`, shows `"Mic muted"` warning.
///    - Prevents sending if no audio was detected.
class VoiceRecorder extends StatefulWidget {
  final ValueChanged<VoiceRecordingData> onSend;
  final VoidCallback onCancel;
  final ValueChanged<bool>? onRecordingStateChanged;
  final VoidCallback? onUnsupportedTap;
  final double Function()? amplitudeProvider;
  final bool simulateMicMuted;
  final double cancelThreshold;
  final double lockThreshold;
  final double silenceThreshold;
  final int barCount;
  final bool compactWhenIdle;

  const VoiceRecorder({
    super.key,
    required this.onSend,
    required this.onCancel,
    this.onRecordingStateChanged,
    this.onUnsupportedTap,
    this.amplitudeProvider,
    this.simulateMicMuted = false,
    this.cancelThreshold = 80.0,
    this.lockThreshold = 60.0,
    this.silenceThreshold = 0.05,
    this.barCount = 24,
    this.compactWhenIdle = false,
  });

  /// Formats seconds into `M:SS` (e.g. `0:05`, `1:24`).
  static String formatDuration(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final mins = safe ~/ 60;
    final secs = (safe % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _surfaceGrey = Color(0xFFF2F3F7);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _dangerRed = Color(0xFFE31B23);
  static const Color _warningAmber = Color(0xFFD97706);

  @override
  State<VoiceRecorder> createState() => VoiceRecorderState();
}

class VoiceRecorderState extends State<VoiceRecorder> {
  static const int _tickMs = 100;
  static const int _flatWarningThresholdMs = 2000;

  Timer? _timer;
  bool _isRecording = false;
  bool _isPressingMic = false;
  bool _isLocked = false;
  bool _isPastCancelThreshold = false;
  bool _isMicMutedWarning = false;
  bool _hasDetectedAudio = false;

  int _elapsedMs = 0;
  int _silentDurationMs = 0;
  int _tickCount = 0;

  Offset _pressOrigin = Offset.zero;
  double _slideLeftPx = 0.0;
  double _slideUpPx = 0.0;

  late List<double> _liveWaveform;
  final List<double> _recordedAmplitudes = <double>[];

  bool get isRecording => _isRecording;
  bool get isLocked => _isLocked;
  bool get isPastCancelThreshold => _isPastCancelThreshold;
  bool get isMicMutedWarning => _isMicMutedWarning;
  bool get hasDetectedAudio => _hasDetectedAudio;
  int get recordSeconds => _elapsedMs ~/ 1000;

  @override
  void initState() {
    super.initState();
    _liveWaveform = List<double>.filled(widget.barCount, 0.04, growable: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setRecordingState(bool active) {
    if (_isRecording != active) {
      _isRecording = active;
      widget.onRecordingStateChanged?.call(active);
    }
  }

  double _sampleAmplitude() {
    if (widget.amplitudeProvider != null) {
      return widget.amplitudeProvider!().clamp(0.0, 1.0);
    }
    if (widget.simulateMicMuted) {
      return 0.02;
    }
    final liveAmp = MediaRtcBridge.getVoiceAmplitude();
    if (liveAmp != null) {
      return liveAmp.clamp(0.0, 1.0);
    }
    // Natural speech envelope when recording without an external mock provider
    final t = _tickCount * 0.48;
    final wave = 0.42 +
        0.28 * math.sin(t) +
        0.18 * math.cos(t * 1.7) +
        0.10 * math.sin(t * 2.9);
    return wave.clamp(0.14, 0.96);
  }

  /// Rule 1: Immediately starts timer, scales mic button to 110%, enters recording UI,
  /// and triggers haptic feedback on pointer down before first word is spoken.
  void _handlePointerDown(PointerDownEvent event) {
    if (_isRecording && _isLocked) return;

    HapticFeedback.mediumImpact();
    _timer?.cancel();

    setState(() {
      _setRecordingState(true);
      _isPressingMic = true;
      _isLocked = false;
      _isPastCancelThreshold = false;
      _isMicMutedWarning = false;
      _hasDetectedAudio = false;
      _elapsedMs = 0;
      _silentDurationMs = 0;
      _tickCount = 0;
      _pressOrigin = event.position;
      _slideLeftPx = 0.0;
      _slideUpPx = 0.0;
      _recordedAmplitudes.clear();
      _liveWaveform =
          List<double>.filled(widget.barCount, 0.04, growable: true);
    });

    if (MediaRtcBridge.isVoiceSupported) {
      MediaRtcBridge.startVoiceRecording();
    }

    _timer = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      if (!mounted || !_isRecording) return;
      _tickCount++;
      final amp = _sampleAmplitude();
      final isSilent = amp < widget.silenceThreshold;

      setState(() {
        _elapsedMs += _tickMs;
        _recordedAmplitudes.add(amp);
        if (_liveWaveform.length >= widget.barCount) {
          _liveWaveform.removeAt(0);
        }
        _liveWaveform.add(amp);

        if (!isSilent) {
          _hasDetectedAudio = true;
          _silentDurationMs = 0;
          _isMicMutedWarning = false;
        } else {
          _silentDurationMs += _tickMs;
          // Rule 4: If waveform is flat for 2+ seconds, show "Mic muted" warning
          if (_silentDurationMs >= _flatWarningThresholdMs) {
            _isMicMutedWarning = true;
          }
        }
      });
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isRecording || _isLocked) return;

    final dx = event.position.dx - _pressOrigin.dx;
    final dy = event.position.dy - _pressOrigin.dy;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Support inward slide-to-cancel in both LTR (slide left: -dx) and RTL (slide right: +dx)
    final nextSlideLeft = (isRtl ? dx : -dx).clamp(0.0, 240.0);
    final nextSlideUp = (-dy).clamp(0.0, 180.0);

    // Rule 3: Slide up past threshold locks recording mode hands-free
    if (nextSlideUp >= widget.lockThreshold &&
        nextSlideLeft < widget.cancelThreshold) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isLocked = true;
        _isPressingMic = false;
        _slideLeftPx = 0.0;
        _slideUpPx = 0.0;
        _isPastCancelThreshold = false;
      });
      return;
    }

    // Rule 2: Slide left past fixed threshold line (e.g. 80px) changes to trash can
    final nextPastCancel = nextSlideLeft >= widget.cancelThreshold;
    if (nextPastCancel != _isPastCancelThreshold) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _slideLeftPx = nextSlideLeft;
      _slideUpPx = nextSlideUp;
      _isPastCancelThreshold = nextPastCancel;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isRecording) return;

    // Rule 3: When locked, freeing thumb keeps recording active hands-free.
    if (_isLocked) {
      setState(() {
        _isPressingMic = false;
      });
      return;
    }

    // Rule 2: Release at trash area = delete message, don't send
    if (_isPastCancelThreshold) {
      cancelRecording();
      return;
    }

    // Quick tap (< 100ms, 0 ticks) when voice bridge is unsupported: clean reset
    if (_elapsedMs == 0 && !MediaRtcBridge.isVoiceSupported) {
      _timer?.cancel();
      setState(() {
        _isPressingMic = false;
        _setRecordingState(false);
      });
      widget.onUnsupportedTap?.call();
      return;
    }

    // Hold mode release: attempt to finish and send
    _attemptFinishAndSend(fromLockedStop: false);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (!_isRecording || _isLocked) return;
    cancelRecording();
  }

  /// Cancels the active recording and invokes [onCancel].
  Future<void> cancelRecording() async {
    _timer?.cancel();
    HapticFeedback.lightImpact();
    if (MediaRtcBridge.isVoiceSupported) {
      await MediaRtcBridge.cancelVoiceRecording();
    }
    if (!mounted) return;
    setState(() {
      _isPressingMic = false;
      _isLocked = false;
      _isPastCancelThreshold = false;
      _isMicMutedWarning = false;
      _hasDetectedAudio = false;
      _elapsedMs = 0;
      _silentDurationMs = 0;
      _slideLeftPx = 0.0;
      _slideUpPx = 0.0;
      _setRecordingState(false);
    });
    widget.onCancel();
  }

  /// Rule 3 & Rule 4: Ends recording when user releases in hold mode or taps STOP in locked mode.
  /// Prevents sending if no audio was detected.
  Future<void> _attemptFinishAndSend({required bool fromLockedStop}) async {
    // Rule 4: Prevent sending if no audio detected
    if (!_hasDetectedAudio) {
      HapticFeedback.vibrate();
      if (fromLockedStop) {
        // Keep locked bar visible with "Mic muted" warning so user knows why send was blocked
        setState(() {
          _isMicMutedWarning = true;
        });
        return;
      } else {
        // In hold mode, stop timer, cancel media stream, show Mic muted warning if held, and DO NOT call onSend
        _timer?.cancel();
        if (MediaRtcBridge.isVoiceSupported) {
          await MediaRtcBridge.cancelVoiceRecording();
        }
        if (!mounted) return;
        setState(() {
          _isPressingMic = false;
          _isLocked = false;
          _isPastCancelThreshold = false;
          _isMicMutedWarning = _elapsedMs >= 200;
          _setRecordingState(false);
        });
        return;
      }
    }

    _timer?.cancel();
    HapticFeedback.lightImpact();

    final durationSec = math.max(1, (_elapsedMs / 1000).ceil());
    final formatted = VoiceRecorder.formatDuration(durationSec);
    final normalizedWaveform = _buildNormalizedWaveform(widget.barCount);

    String base64Audio = '';
    String mimeAudio = 'audio/webm';

    if (MediaRtcBridge.isVoiceSupported) {
      final res = await MediaRtcBridge.stopVoiceRecording();
      if (res != null && res.base64.isNotEmpty) {
        base64Audio = res.base64;
        mimeAudio = res.mime;
      }
    }

    if (!mounted) return;
    setState(() {
      _isPressingMic = false;
      _isLocked = false;
      _isPastCancelThreshold = false;
      _isMicMutedWarning = false;
      _hasDetectedAudio = false;
      _elapsedMs = 0;
      _silentDurationMs = 0;
      _slideLeftPx = 0.0;
      _slideUpPx = 0.0;
      _setRecordingState(false);
    });

    widget.onSend(
      VoiceRecordingData(
        durationSeconds: durationSec,
        formattedDuration: formatted,
        waveform: normalizedWaveform,
        audioBase64: base64Audio,
        audioMime: mimeAudio,
      ),
    );
  }

  List<double> _buildNormalizedWaveform(int targetBars) {
    if (_recordedAmplitudes.isEmpty) {
      return List<double>.filled(targetBars, 0.35);
    }
    if (_recordedAmplitudes.length <= targetBars) {
      final padded = List<double>.from(_recordedAmplitudes);
      while (padded.length < targetBars) {
        padded.add(_recordedAmplitudes[padded.length % _recordedAmplitudes.length]);
      }
      return padded.map((e) => e.clamp(0.12, 1.0)).toList();
    }
    final step = _recordedAmplitudes.length / targetBars;
    return List<double>.generate(targetBars, (i) {
      final idx = (i * step).floor().clamp(0, _recordedAmplitudes.length - 1);
      return _recordedAmplitudes[idx].clamp(0.12, 1.0);
    });
  }

  String _buildSemanticStateLabel() {
    if (!_isRecording) {
      return _isMicMutedWarning
          ? 'Mic muted. No audio detected. Hold mic button to record voice message'
          : 'Hold to record voice message. Slide left to cancel, slide up to lock hands-free';
    }
    final timeStr = VoiceRecorder.formatDuration(recordSeconds);
    final mutedSuffix =
        _isMicMutedWarning ? '. Warning: Mic muted, no audio detected' : '';
    if (_isPastCancelThreshold) {
      return 'Release to cancel voice recording$mutedSuffix';
    }
    if (_isLocked) {
      return 'Recording locked hands-free, $timeStr$mutedSuffix. Tap STOP to end recording';
    }
    return 'Recording voice message, $timeStr$mutedSuffix. Slide left to cancel, slide up to lock';
  }

  Widget _buildWaveformBars() {
    return Semantics(
      key: const Key('voice-recorder-waveform'),
      label: _isMicMutedWarning
          ? 'Flat audio waveform, mic muted'
          : 'Live audio waveform',
      child: SizedBox(
        height: 28,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_liveWaveform.length, (i) {
            final amp = _liveWaveform[i].clamp(0.04, 1.0);
            final barHeight = (4.0 + amp * 22.0).clamp(4.0, 26.0);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 3,
              height: barHeight,
              decoration: BoxDecoration(
                color: _isPastCancelThreshold
                    ? VoiceRecorder._dangerRed.withValues(alpha: 0.45)
                    : (_isMicMutedWarning
                        ? VoiceRecorder._warningAmber
                        : VoiceRecorder._ink),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMicMutedWarningBanner() {
    return Semantics(
      liveRegion: true,
      label: 'Mic muted warning. No audio detected.',
      child: Container(
        key: const Key('voice-recorder-mic-muted-warning'),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.mic_slash_fill,
              size: 14,
              color: Color(0xFFB45309),
            ),
            SizedBox(width: 6),
            Text(
              'Mic muted',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = VoiceRecorder.formatDuration(recordSeconds);

    return Semantics(
      container: true,
      liveRegion: _isRecording,
      label: _buildSemanticStateLabel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isMicMutedWarning) _buildMicMutedWarningBanner(),
          if (_isRecording && !_isLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, right: 4),
              child: Transform.translate(
                offset: Offset(0, -_slideUpPx * 0.35),
                child: Container(
                  key: const Key('voice-recorder-lock-indicator'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: VoiceRecorder._surfaceGrey,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 12,
                        color: VoiceRecorder._ink,
                      ),
                      SizedBox(width: 3),
                      Icon(
                        CupertinoIcons.chevron_up,
                        size: 12,
                        color: VoiceRecorder._textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            mainAxisSize:
                (_isRecording || !widget.compactWhenIdle)
                    ? MainAxisSize.max
                    : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isRecording)
                Expanded(
                  child: Container(
                    key: const Key('voice-recorder-active-bar'),
                    height: 48,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _isPastCancelThreshold
                          ? const Color(0xFFFEF2F2)
                          : VoiceRecorder._surfaceGrey,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isPastCancelThreshold
                            ? VoiceRecorder._dangerRed.withValues(alpha: 0.45)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_isLocked)
                          Semantics(
                            button: true,
                            label: 'Cancel voice recording',
                            child: GestureDetector(
                              key: const Key(
                                  'voice-recorder-locked-cancel-button'),
                              behavior: HitTestBehavior.opaque,
                              onTap: cancelRecording,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                child: const Center(
                                  child: Icon(
                                    CupertinoIcons.trash_fill,
                                    size: 18,
                                    color: VoiceRecorder._dangerRed,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else if (_isPastCancelThreshold)
                          const Icon(
                            CupertinoIcons.trash_fill,
                            key: Key('voice-recorder-trash-icon'),
                            size: 18,
                            color: VoiceRecorder._dangerRed,
                          )
                        else
                          Container(
                            key: const Key('voice-recorder-red-dot'),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: VoiceRecorder._dangerRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          formattedTime,
                          key: const Key('voice-recorder-timer'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _isPastCancelThreshold
                                ? VoiceRecorder._dangerRed
                                : VoiceRecorder._ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _buildWaveformBars()),
                        const SizedBox(width: 10),
                        if (!_isLocked)
                          Transform.translate(
                            offset: Offset(-_slideLeftPx * 0.12, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.chevron_left,
                                  size: 13,
                                  color: _isPastCancelThreshold
                                      ? VoiceRecorder._dangerRed
                                      : VoiceRecorder._textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _isPastCancelThreshold
                                      ? 'Release to cancel'
                                      : 'Slide to cancel',
                                  key: const Key('voice-recorder-cancel-label'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _isPastCancelThreshold
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _isPastCancelThreshold
                                        ? VoiceRecorder._dangerRed
                                        : VoiceRecorder._textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.lock_fill,
                                size: 13,
                                color: VoiceRecorder._textMuted,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Locked',
                                key: Key('voice-recorder-locked-badge'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: VoiceRecorder._textMuted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                )
              else if (!widget.compactWhenIdle)
                Expanded(
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: VoiceRecorder._surfaceGrey,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Hold mic to record voice message',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: VoiceRecorder._textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // Rule 3: When locked, replace mic button with explicit STOP button (min 44x44px).
              // Otherwise keep the press-and-hold Mic button Listener mounted at the exact same slot.
              if (_isRecording && _isLocked)
                Semantics(
                  button: true,
                  label: 'Stop voice recording and send',
                  child: GestureDetector(
                    key: const Key('voice-recorder-stop-button'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _attemptFinishAndSend(fromLockedStop: true),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: VoiceRecorder._dangerRed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.stop_fill,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'STOP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Semantics(
                  button: true,
                  label: 'Record voice message',
                  hint:
                      'Press and hold to record. Slide left to cancel, slide up to lock',
                  child: Listener(
                    key: const Key('voice-recorder-mic-button'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _handlePointerDown,
                    onPointerMove: _handlePointerMove,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: _handlePointerCancel,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      child: AnimatedScale(
                        key: const Key('voice-recorder-mic-scale'),
                        // Rule 1: Animate button scale up (110%) past thumb on press
                        scale: _isPressingMic ? 1.10 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? (_isPastCancelThreshold
                                    ? VoiceRecorder._dangerRed
                                    : const Color(0xFF0088FF))
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _isPastCancelThreshold
                                ? CupertinoIcons.trash_fill
                                : CupertinoIcons.mic,
                            color: _isRecording
                                ? Colors.white
                                : const Color(0xFF8E8E93),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rule 5: Scrubbable Voice Message Playback component for chat bubbles:
/// - Displays waveform + duration inside the message bubble.
/// - Allows dragging or tapping on the waveform to scrub/jump to a specific position (`0.0..1.0`).
/// - Provides playback speed option cycling through `1x`, `1.5x`, and `2x` (`min 44px` touch target).
/// - Animates waveform progress smoothly as audio plays.
class VoiceMessagePlayer extends StatefulWidget {
  final String messageKey;
  final String durationLabel;
  final int? durationSeconds;
  final List<double>? waveform;
  final bool isMine;
  final String audioBase64;
  final String audioMime;
  final bool? externalIsPlaying;
  final double? externalProgress;
  final ValueChanged<double>? onScrub;
  final ValueChanged<double>? onSpeedChanged;
  final VoidCallback? onPlayToggle;

  const VoiceMessagePlayer({
    super.key,
    required this.messageKey,
    required this.durationLabel,
    this.durationSeconds,
    this.waveform,
    this.isMine = true,
    this.audioBase64 = '',
    this.audioMime = 'audio/webm',
    this.externalIsPlaying,
    this.externalProgress,
    this.onScrub,
    this.onSpeedChanged,
    this.onPlayToggle,
  });

  static const List<double> defaultWaveform = <double>[
    0.28,
    0.55,
    0.82,
    0.45,
    0.92,
    0.64,
    0.36,
    0.78,
    0.60,
    0.88,
    0.50,
    0.70,
    0.42,
    0.58,
    0.74,
    0.48,
  ];

  static const List<double> supportedSpeeds = <double>[1.0, 1.5, 2.0];

  static int parseDurationSeconds(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return 5;
    final parts = trimmed.split(':');
    if (parts.length == 2) {
      final mins = int.tryParse(parts[0]) ?? 0;
      final secs = int.tryParse(parts[1]) ?? 0;
      final total = mins * 60 + secs;
      return total > 0 ? total : 5;
    }
    return int.tryParse(trimmed) ?? 5;
  }

  static String formatSpeedLabel(double speed) {
    if (speed == 1.5) return '1.5x';
    if (speed == 2.0) return '2x';
    return '1x';
  }

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  Timer? _playbackTimer;
  bool _internalPlaying = false;
  double _internalProgress = 0.0;
  double _playbackSpeed = 1.0;

  bool get _isPlaying => widget.externalIsPlaying ?? _internalPlaying;
  double get _progress =>
      (widget.externalProgress ?? _internalProgress).clamp(0.0, 1.0);

  int get _totalSeconds =>
      widget.durationSeconds ??
      VoiceMessagePlayer.parseDurationSeconds(widget.durationLabel);

  List<double> get _bars =>
      (widget.waveform != null && widget.waveform!.isNotEmpty)
          ? widget.waveform!
          : VoiceMessagePlayer.defaultWaveform;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    if (widget.onPlayToggle != null) {
      widget.onPlayToggle!();
    }

    if (_isPlaying) {
      _pauseInternal();
      return;
    }

    _startInternalPlayback();
  }

  void _startInternalPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      if (_internalProgress >= 1.0) {
        _internalProgress = 0.0;
      }
      _internalPlaying = true;
    });

    if (widget.audioBase64.isNotEmpty && MediaRtcBridge.isVoiceSupported) {
      MediaRtcBridge.playVoiceMessage(
        widget.messageKey,
        widget.audioBase64,
        widget.audioMime,
        initialProgress: _internalProgress,
        playbackRate: _playbackSpeed,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _internalProgress = p.clamp(0.0, 1.0));
        },
        onEnded: () {
          if (!mounted) return;
          _playbackTimer?.cancel();
          setState(() {
            _internalPlaying = false;
            _internalProgress = 0.0;
          });
        },
      );
      return;
    }

    const tickMs = 50;
    final totalMs = math.max(1000, _totalSeconds * 1000);
    _playbackTimer =
        Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted || !_internalPlaying) {
        timer.cancel();
        return;
      }
      final step = (tickMs * _playbackSpeed) / totalMs;
      final next = _internalProgress + step;
      if (next >= 1.0) {
        timer.cancel();
        setState(() {
          _internalProgress = 1.0;
          _internalPlaying = false;
        });
      } else {
        setState(() {
          _internalProgress = next;
        });
      }
    });
  }

  void _pauseInternal() {
    _playbackTimer?.cancel();
    if (MediaRtcBridge.isVoiceSupported) {
      MediaRtcBridge.pauseVoiceMessage();
    }
    setState(() {
      _internalPlaying = false;
    });
  }

  void _scrubToLocalDx(double localDx, double maxWidth) {
    if (maxWidth <= 0) return;
    final nextProgress = (localDx / maxWidth).clamp(0.0, 1.0);
    setState(() {
      _internalProgress = nextProgress;
    });
    if (MediaRtcBridge.isVoiceSupported) {
      MediaRtcBridge.seekVoiceMessage(widget.messageKey, nextProgress);
    }
    widget.onScrub?.call(nextProgress);
  }

  void _cycleSpeed() {
    HapticFeedback.selectionClick();
    final idx = VoiceMessagePlayer.supportedSpeeds.indexOf(_playbackSpeed);
    final nextSpeed = VoiceMessagePlayer
        .supportedSpeeds[(idx + 1) % VoiceMessagePlayer.supportedSpeeds.length];
    setState(() {
      _playbackSpeed = nextSpeed;
    });
    if (MediaRtcBridge.isVoiceSupported) {
      MediaRtcBridge.setVoicePlaybackRate(nextSpeed);
    }
    widget.onSpeedChanged?.call(nextSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    final progress = _progress;
    final activeSeconds = (_totalSeconds * progress).round();
    final displayDuration = (progress > 0 && progress < 1.0)
        ? VoiceRecorder.formatDuration(activeSeconds)
        : (widget.durationLabel.trim().isNotEmpty
            ? widget.durationLabel.trim()
            : VoiceRecorder.formatDuration(_totalSeconds));
    final speedLabel = VoiceMessagePlayer.formatSpeedLabel(_playbackSpeed);

    // Exact Apple iOS 26 `MessageAudio` colors (`2052:1051`):
    // Outgoing on blue gradient: solid white play circle (#0088FF glyph) + crisp white fine waveform
    // Incoming on gray fill: solid #0088FF play circle (white glyph) + obsidian waveform
    final fgActive = isMine ? Colors.white : const Color(0xFF0A0A0A);
    final fgInactive = isMine
        ? Colors.white.withValues(alpha: progress > 0 ? 0.45 : 0.88)
        : const Color(0xFF0A0A0A).withValues(alpha: progress > 0 ? 0.28 : 0.72);
    final subTextColor = isMine
        ? Colors.white.withValues(alpha: 0.70)
        : const Color(0x993C3C43);

    return Semantics(
      container: true,
      label:
          'Voice message, duration $displayDuration, playback speed $speedLabel',
      child: SizedBox(
        key: Key('voice-message-player-${widget.messageKey}'),
        width: 248,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Exact Apple iOS 26 Play / Pause button (min 44x44px touch target)
            Semantics(
              button: true,
              label: _isPlaying ? 'Pause voice message' : 'Play voice message',
              child: GestureDetector(
                key: Key('voice-play-button-${widget.messageKey}'),
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isMine ? Colors.white : const Color(0xFF0088FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: isMine ? const Color(0xFF0088FF) : Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Scrubbable fine-bar Apple waveform + duration (min 44px touch target height)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width =
                      constraints.maxWidth > 0 ? constraints.maxWidth : 120.0;
                  return Semantics(
                    slider: true,
                    label: 'Voice message waveform scrubber',
                    value: '${(progress * 100).round()}%',
                    child: GestureDetector(
                      key: Key('voice-waveform-scrubber-${widget.messageKey}'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) =>
                          _scrubToLocalDx(d.localPosition.dx, width),
                      onHorizontalDragStart: (d) =>
                          _scrubToLocalDx(d.localPosition.dx, width),
                      onHorizontalDragUpdate: (d) =>
                          _scrubToLocalDx(d.localPosition.dx, width),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 28,
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children:
                                        List.generate(_bars.length, (index) {
                                      final ratio =
                                          (index + 1) / _bars.length;
                                      final isFilled =
                                          progress > 0 && ratio <= progress;
                                      final barH = (4.0 +
                                              _bars[index].clamp(0.1, 1.0) *
                                                  22.0)
                                          .clamp(4.0, 26.0);
                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 60),
                                        width: 2.2,
                                        height: barH,
                                        decoration: BoxDecoration(
                                          color:
                                              isFilled ? fgActive : fgInactive,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      );
                                    }),
                                  ),
                                  Positioned(
                                    left:
                                        (progress * (width - 10)).clamp(0.0, width - 10),
                                    child: Container(
                                      key: Key(
                                          'voice-scrubber-thumb-${widget.messageKey}'),
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: fgActive,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              displayDuration,
                              key: Key('voice-duration-${widget.messageKey}'),
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),

            // Playback speed toggle button (1x, 1.5x, 2x) with min 44x44px touch target
            Semantics(
              button: true,
              label: 'Playback speed $speedLabel, tap to change',
              child: GestureDetector(
                key: Key('voice-speed-button-${widget.messageKey}'),
                behavior: HitTestBehavior.opaque,
                onTap: _cycleSpeed,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.16)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        speedLabel,
                        style: TextStyle(
                          color: isMine ? Colors.white : const Color(0xFF0A0A0A),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
