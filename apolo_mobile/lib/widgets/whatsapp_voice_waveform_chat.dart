import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';

/// Represents a single WhatsApp-style voice message item in the chat.
class VoiceWaveformMessage {
  final String id;
  final String audioPathOrUrl;
  final Duration duration;
  final bool isMine;
  final String senderName;
  final String timestamp;

  const VoiceWaveformMessage({
    required this.id,
    required this.audioPathOrUrl,
    required this.duration,
    required this.isMine,
    this.senderName = 'Lucia',
    this.timestamp = '',
  });
}

/// Shared waveform & remote file cache to prevent re-downloading or recalculating
/// waveform amplitudes on repeated playback (Requirement 5: Performance Optimization).
class VoiceWaveformCache {
  VoiceWaveformCache._();
  static final VoiceWaveformCache instance = VoiceWaveformCache._();

  final Map<String, List<double>> _waveformCache = <String, List<double>>{};
  final Map<String, String> _localFileCache = <String, String>{};
  final Dio _dio = Dio();

  List<double>? getCachedWaveform(String key) => _waveformCache[key];

  void saveWaveform(String key, List<double> data) {
    if (data.isNotEmpty) {
      _waveformCache[key] = List<double>.unmodifiable(data);
    }
  }

  /// For online URLs, downloads the file to local cache first instead of streaming directly.
  Future<String> resolveLocalAudioPath(String pathOrUrl) async {
    if (!pathOrUrl.startsWith('http://') && !pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final cachedPath = _localFileCache[pathOrUrl];
    if (cachedPath != null && await File(cachedPath).exists()) {
      return cachedPath;
    }
    final tempDir = await getTemporaryDirectory();
    final safeHash = pathOrUrl.hashCode.abs();
    final ext = pathOrUrl.toLowerCase().endsWith('.mp3')
        ? 'mp3'
        : (pathOrUrl.toLowerCase().endsWith('.wav') ? 'wav' : 'm4a');
    final targetPath = '${tempDir.path}/voice_cache_$safeHash.$ext';
    await _dio.download(pathOrUrl, targetPath);
    _localFileCache[pathOrUrl] = targetPath;
    return targetPath;
  }
}

/// Formats a [Duration] into `mm:ss` (e.g. `00:14`, `01:05`).
String formatVoiceMmSs(Duration d) {
  final totalSec = d.inSeconds < 0 ? 0 : d.inSeconds;
  final mins = (totalSec ~/ 60).toString().padLeft(2, '0');
  final secs = (totalSec % 60).toString().padLeft(2, '0');
  return '$mins:$secs';
}

/// Complete WhatsApp-style Voice Messaging Screen using `audio_waveforms ^2.0.2`:
/// - Live recording waveform (`RecorderController` + `AudioWaveforms`) with `mm:ss` timer
/// - Playback bubbles (`PlayerController` + `AudioFileWaveforms`) with tap/drag seek
/// - Single active playback enforced via `pauseAllPlayers()`
/// - Waveform data caching + download-before-play for remote URLs
/// - Adaptive `UpdateFrequency` (`50ms` high-end / `200ms` low-end)
/// - Dark/Light mode + optional GTA 6 Vice City theme & Lucia avatar
class WhatsAppVoiceMessagingScreen extends StatefulWidget {
  final bool isHighEndDevice;
  final bool enableGta6Theme;
  final WaveformType initialWaveformType;
  final List<VoiceWaveformMessage> initialMessages;

  const WhatsAppVoiceMessagingScreen({
    super.key,
    this.isHighEndDevice = true,
    this.enableGta6Theme = true,
    this.initialWaveformType = WaveformType.fitWidth,
    this.initialMessages = const <VoiceWaveformMessage>[],
  });

  @override
  State<WhatsAppVoiceMessagingScreen> createState() =>
      _WhatsAppVoiceMessagingScreenState();
}

class _WhatsAppVoiceMessagingScreenState
    extends State<WhatsAppVoiceMessagingScreen> {
  late final RecorderController _recorderController;
  final List<VoiceWaveformMessage> _messages = <VoiceWaveformMessage>[];

  Timer? _recordTimer;
  Duration _recordingDuration = Duration.zero;
  bool _isRecording = false;
  late WaveformType _waveformType;
  late bool _gta6Theme;
  String? _statusNotice;

  @override
  void initState() {
    super.initState();
    _waveformType = widget.initialWaveformType;
    _gta6Theme = widget.enableGta6Theme;
    _messages.addAll(widget.initialMessages);

    _recorderController = RecorderController()
      ..overrideAudioSession = true;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    // Always dispose RecorderController to prevent memory leaks (Requirement 5)
    _recorderController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    // Requirement 1: Request microphone permission before recording
    final hasPermission = await _recorderController.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _statusNotice = appL10n.voiceMicPermissionRequired;
        });
      }
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorderController.record(path: filePath);
      _recordTimer?.cancel();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _statusNotice = null;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecording) return;
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _statusNotice = appL10n.voiceCouldNotStartRecording;
        });
      }
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    HapticFeedback.lightImpact();
    _recordTimer?.cancel();

    final recordedDuration = _recordingDuration.inSeconds > 0
        ? _recordingDuration
        : const Duration(seconds: 1);

    // Requirement 2: Return file path on stop recording
    final String? path = await _recorderController.stop();

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });

    if (path == null || path.isEmpty) return;

    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    setState(() {
      _messages.add(
        VoiceWaveformMessage(
          id: 'vm_${now.microsecondsSinceEpoch}',
          audioPathOrUrl: path,
          duration: recordedDuration,
          isMine: true,
          senderName: 'Lucia',
          timestamp: '$hh:$mm',
        ),
      );
    });
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    HapticFeedback.selectionClick();
    _recordTimer?.cancel();
    final path = await _recorderController.stop();
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = _gta6Theme
        ? (isDark ? const Color(0xFF12081F) : const Color(0xFFFFF5FA))
        : (isDark ? const Color(0xFF0B141A) : const Color(0xFFEFEAE2));
    final appBarColor = _gta6Theme
        ? (isDark ? const Color(0xFF1D0C30) : const Color(0xFFFFFFFF))
        : (isDark ? const Color(0xFF1F2C34) : const Color(0xFFFFFFFF));
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Row(
          children: [
            // Bonus GTA 6 Character Avatar (Lucia)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _gta6Theme
                    ? const LinearGradient(
                        colors: [Color(0xFFFF2E93), Color(0xFFFF9F1C)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF128C7E), Color(0xFF25D366)],
                      ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'L',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _gta6Theme ? 'Lucia · Vice City' : context.l10n.voiceChatTitle,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                Text(
                  _waveformType == WaveformType.fitWidth
                      ? 'Waveform: fitWidth'
                      : 'Waveform: longScroll',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.voiceToggleWaveformTooltip,
            onPressed: () {
              setState(() {
                _waveformType = _waveformType == WaveformType.fitWidth
                    ? WaveformType.long
                    : WaveformType.fitWidth;
              });
            },
            icon: Icon(
              _waveformType == WaveformType.fitWidth
                  ? CupertinoIcons.waveform
                  : CupertinoIcons.slider_horizontal_3,
            ),
          ),
          IconButton(
            tooltip: context.l10n.voiceToggleThemeTooltip,
            onPressed: () => setState(() => _gta6Theme = !_gta6Theme),
            icon: Icon(
              _gta6Theme ? CupertinoIcons.sparkles : CupertinoIcons.paintbrush,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statusNotice != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFEF2F2),
              child: Text(
                _statusNotice!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.voiceTapMicEmptyPrompt,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: WhatsAppVoiceBubble(
                          key: ValueKey<String>(msg.id),
                          message: msg,
                          waveformType: _waveformType,
                          isHighEndDevice: widget.isHighEndDevice,
                          enableGta6Theme: _gta6Theme,
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Recorder Composer Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: appBarColor,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_isRecording) ...[
                    // Cancel Recording Button
                    IconButton(
                      key: const Key('wa-voice-cancel'),
                      onPressed: _cancelRecording,
                      icon: const Icon(
                        CupertinoIcons.trash_fill,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    // Live mm:ss Recording Timer (Requirement 2)
                    Text(
                      formatVoiceMmSs(_recordingDuration),
                      key: const Key('wa-voice-timer'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Live Animated AudioWaveforms Widget (Requirement 2)
                    Expanded(
                      child: AudioWaveforms(
                        key: const Key('wa-live-waveform'),
                        enableGesture: false,
                        size: const Size(double.infinity, 44),
                        recorderController: _recorderController,
                        waveStyle: WaveStyle(
                          waveColor: _gta6Theme
                              ? const Color(0xFFFF2E93)
                              : const Color(0xFF25D366),
                          extendWaveform: true,
                          showMiddleLine: false,
                          spacing: 5,
                          waveThickness: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Stop & Send Button
                    GestureDetector(
                      key: const Key('wa-voice-stop-send'),
                      onTap: _stopRecordingAndSend,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _gta6Theme
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF2E93),
                                    Color(0xFF00E5FF)
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF128C7E),
                                    Color(0xFF25D366)
                                  ],
                                ),
                        ),
                        child: const Icon(
                          CupertinoIcons.arrow_up,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: AlignmentDirectional.centerStart,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          context.l10n.voiceTapMicInputHint,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Microphone Button (Requirement 6)
                    GestureDetector(
                      key: const Key('wa-voice-mic-btn'),
                      onTap: _startRecording,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _gta6Theme
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF2E93),
                                    Color(0xFFFF9F1C)
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF128C7E),
                                    Color(0xFF25D366)
                                  ],
                                ),
                        ),
                        child: const Icon(
                          CupertinoIcons.mic_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual WhatsApp-style Voice Message Bubble with `PlayerController` + `AudioFileWaveforms`:
/// - Calls `pauseAllPlayers()` before starting playback (only 1 plays at a time)
/// - Caches extracted `waveformData` in [VoiceWaveformCache]
/// - Downloads remote audio files before preparing player
/// - Supports `WaveformType.fitWidth` & `WaveformType.long`, tap/drag seek, Dark/Light & GTA 6 theme
class WhatsAppVoiceBubble extends StatefulWidget {
  final VoiceWaveformMessage message;
  final WaveformType waveformType;
  final bool isHighEndDevice;
  final bool enableGta6Theme;

  const WhatsAppVoiceBubble({
    super.key,
    required this.message,
    this.waveformType = WaveformType.fitWidth,
    this.isHighEndDevice = true,
    this.enableGta6Theme = true,
  });

  @override
  State<WhatsAppVoiceBubble> createState() => _WhatsAppVoiceBubbleState();
}

class _WhatsAppVoiceBubbleState extends State<WhatsAppVoiceBubble> {
  late final PlayerController _playerController;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<int>? _currentDurationSub;

  List<double> _cachedWaveform = const <double>[];
  bool _isPrepared = false;
  bool _isPreparing = false;
  bool _isPlaying = false;
  int _currentMs = 0;
  int _totalMs = 0;

  @override
  void initState() {
    super.initState();
    _totalMs = widget.message.duration.inMilliseconds;

    // Requirement 5: 50ms (UpdateFrequency.high) for high-end, 200ms (UpdateFrequency.low) for low-end
    _playerController = PlayerController()
      ..updateFrequency = widget.isHighEndDevice
          ? UpdateFrequency.high
          : UpdateFrequency.low;

    _cachedWaveform = VoiceWaveformCache.instance
            .getCachedWaveform(widget.message.audioPathOrUrl) ??
        const <double>[];

    _playerStateSub = _playerController.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.isPlaying;
      });
    });

    _currentDurationSub =
        _playerController.onCurrentDurationChanged.listen((ms) {
      if (!mounted) return;
      setState(() {
        _currentMs = ms;
      });
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _currentDurationSub?.cancel();
    // Always dispose PlayerController to prevent memory leaks (Requirement 5)
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _ensurePrepared() async {
    if (_isPrepared || _isPreparing) return;
    setState(() => _isPreparing = true);

    try {
      // Requirement 5: Download online files first before playing (never stream directly)
      final localPath = await VoiceWaveformCache.instance
          .resolveLocalAudioPath(widget.message.audioPathOrUrl);

      // Requirement 5: Use cached waveformData if available to avoid recalculation
      List<double>? waveform = VoiceWaveformCache.instance
          .getCachedWaveform(widget.message.audioPathOrUrl);

      if (waveform == null || waveform.isEmpty) {
        waveform = await _playerController.waveformExtraction
            .extractWaveformData(path: localPath, noOfSamples: 56);
        VoiceWaveformCache.instance
            .saveWaveform(widget.message.audioPathOrUrl, waveform);
      }

      await _playerController.preparePlayer(
        path: localPath,
        shouldExtractWaveform: false,
      );
      await _playerController.setFinishMode(finishMode: FinishMode.pause);

      final maxMs = _playerController.maxDuration;
      if (mounted) {
        setState(() {
          _cachedWaveform = waveform ?? const <double>[];
          if (maxMs > 0) _totalMs = maxMs;
          _isPrepared = true;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.selectionClick();
    if (_isPlaying) {
      await _playerController.pausePlayer();
      return;
    }

    await _ensurePrepared();
    if (!_isPrepared) return;

    // Requirement 4: Pause all other players before starting playback (WhatsApp behavior)
    await _playerController.pauseAllPlayers();
    await _playerController.startPlayer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMine = widget.message.isMine;

    final BoxDecoration bubbleDecoration;
    if (widget.enableGta6Theme) {
      bubbleDecoration = BoxDecoration(
        gradient: isMine
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A148C), Color(0xFFD81B60)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF1F1638), Color(0xFF2B1C4D)]
                    : const [Color(0xFFFFFFFF), Color(0xFFFFF0F7)],
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMine
              ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
              : const Color(0xFFFF2E93).withValues(alpha: 0.25),
        ),
      );
    } else {
      bubbleDecoration = BoxDecoration(
        color: isMine
            ? (isDark ? const Color(0xFF005C4B) : const Color(0xFFD9FDD3))
            : (isDark ? const Color(0xFF1F2C34) : Colors.white),
        borderRadius: BorderRadius.circular(18),
      );
    }

    final liveWaveColor = widget.enableGta6Theme
        ? (isMine ? const Color(0xFF00E5FF) : const Color(0xFFFF2E93))
        : const Color(0xFF25D366);
    final fixedWaveColor = (isMine && widget.enableGta6Theme)
        ? Colors.white.withValues(alpha: 0.35)
        : (isDark
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.22));
    final metaTextColor = (isMine && widget.enableGta6Theme)
        ? Colors.white70
        : (isDark ? Colors.white60 : Colors.black54);

    final currentDurStr = formatVoiceMmSs(Duration(milliseconds: _currentMs));
    final totalDurStr = formatVoiceMmSs(Duration(milliseconds: _totalMs));

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 12, 8),
        decoration: bubbleDecoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play / Pause Button (min 44x44px touch target)
            GestureDetector(
              key: Key('wa-play-btn-${widget.message.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlayback,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: liveWaveColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: _isPreparing
                        ? const CupertinoActivityIndicator(
                            color: Colors.white,
                            radius: 9,
                          )
                        : Icon(
                            _isPlaying
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_fill,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Static -> Animated Filling Waveform + Duration Readout (Requirement 3 & 6)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AudioFileWaveforms(
                    key: Key('wa-file-waveform-${widget.message.id}'),
                    size: const Size(190, 34),
                    playerController: _playerController,
                    waveformType: widget.waveformType,
                    enableSeekGesture: true,
                    waveformData: _cachedWaveform,
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: fixedWaveColor,
                      liveWaveColor: liveWaveColor,
                      seekLineColor: liveWaveColor,
                      showSeekLine: true,
                      spacing: 5,
                      waveThickness: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '$currentDurStr / $totalDurStr',
                          key: Key('wa-duration-${widget.message.id}'),
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: metaTextColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (widget.message.timestamp.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.message.timestamp,
                          textDirection: TextDirection.ltr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: metaTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
