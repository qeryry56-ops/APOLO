import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show VoidCallback, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bug_report_models.dart';
import 'bug_report_log_service.dart';

typedef AccelerometerSample = ({double x, double y, double z});
typedef AccelerometerStreamFactory = Stream<AccelerometerSample> Function();

/// Persistent shake-to-report detector with cooldown, spike windowing,
/// lifecycle pausing, and graceful fallback on desktop Chrome.
class BugReportShakeService with WidgetsBindingObserver {
  static const String prefsKey = 'apolo_bug_report_shake_enabled';

  final double shakeThresholdG;
  final int requiredSpikes;
  final Duration spikeWindow;
  final Duration minSpikeGap;
  final Duration cooldown;
  final bool Function()? isBlocked;
  final VoidCallback onShakeDetected;
  final AccelerometerStreamFactory? _streamFactory;

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  bool _initialized = false;
  bool _observerAttached = false;
  bool _isAppActive = true;
  bool _isHardwareSupported = !kIsWeb;
  bool _disposed = false;

  StreamSubscription<AccelerometerSample>? _subscription;
  final List<DateTime> _recentSpikes = <DateTime>[];
  DateTime? _lastTriggerAt;

  BugReportShakeService({
    required this.onShakeDetected,
    this.isBlocked,
    this.shakeThresholdG = 2.7,
    this.requiredSpikes = 2,
    this.spikeWindow = const Duration(milliseconds: 700),
    this.minSpikeGap = const Duration(milliseconds: 120),
    this.cooldown = const Duration(milliseconds: 3500),
    AccelerometerStreamFactory? streamFactory,
  }) : _streamFactory = streamFactory;

  bool get isHardwareSupported => _isHardwareSupported;
  bool get isListening => _subscription != null;

  Future<void> init() async {
    if (_disposed) return;
    if (!_initialized) {
      try {
        final prefs = await SharedPreferences.getInstance();
        enabled.value = prefs.getBool(prefsKey) ?? true;
      } catch (_) {
        enabled.value = true;
      }
      if (!_observerAttached) {
        WidgetsBinding.instance.addObserver(this);
        _observerAttached = true;
      }
      _initialized = true;
    }
    _syncListener();
  }

  Future<void> setEnabled(bool value) async {
    if (_disposed) return;
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, value);
    } catch (_) {}
    if (!value) {
      _recentSpikes.clear();
    }
    _syncListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;
    if (!_isAppActive) {
      _recentSpikes.clear();
    }
    _syncListener();
  }

  void _syncListener() {
    if (_disposed) return;
    final shouldListen = enabled.value && _isAppActive;

    // On Web, sensors_plus closes its internal singleton controller on cancel
    // without resetting it, so keep the subscription alive once started and
    // gate event processing on `enabled.value && _isAppActive`.
    if (kIsWeb && _streamFactory == null) {
      if (shouldListen && _subscription == null) {
        _startSubscription();
      }
      return;
    }

    if (shouldListen) {
      if (_subscription == null) {
        _startSubscription();
      }
    } else {
      _stopSubscription();
    }
  }

  void _startSubscription() {
    try {
      final factory = _streamFactory;
      final stream = factory != null
          ? factory()
          : accelerometerEventStream().map<AccelerometerSample>(
              (e) => (x: e.x, y: e.y, z: e.z),
            );

      _subscription = stream.listen(
        (sample) {
          if (!enabled.value || !_isAppActive) return;
          if (kIsWeb &&
              (sample.x != 0 || sample.y != 0 || sample.z != 0)) {
            _isHardwareSupported = true;
          }
          processSample(sample.x, sample.y, sample.z);
        },
        onError: (Object error) {
          _isHardwareSupported = false;
          BugReportLogService.instance.log(
            'Accelerometer unavailable: $error',
            level: BugLogLevel.info,
            tag: 'shake',
          );
        },
        cancelOnError: false,
      );
    } catch (e) {
      _isHardwareSupported = false;
      BugReportLogService.instance.log(
        'Failed to start shake listener: $e',
        level: BugLogLevel.info,
        tag: 'shake',
      );
    }
  }

  void _stopSubscription() {
    final sub = _subscription;
    _subscription = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
  }

  /// Evaluates a single accelerometer vector (m/s²) against the shake guards.
  void processSample(double x, double y, double z, {DateTime? now}) {
    if (_disposed || !enabled.value || !_isAppActive) return;
    if (isBlocked?.call() ?? false) {
      _recentSpikes.clear();
      return;
    }

    final timestamp = now ?? DateTime.now();
    if (_lastTriggerAt != null &&
        timestamp.difference(_lastTriggerAt!) < cooldown) {
      return;
    }

    final magnitude = math.sqrt((x * x) + (y * y) + (z * z));
    final gForce = magnitude / 9.80665;
    if (gForce < shakeThresholdG) {
      return;
    }

    if (_recentSpikes.isNotEmpty &&
        timestamp.difference(_recentSpikes.last) < minSpikeGap) {
      return;
    }

    _recentSpikes.removeWhere((t) => timestamp.difference(t) > spikeWindow);
    _recentSpikes.add(timestamp);

    if (_recentSpikes.length >= requiredSpikes) {
      _recentSpikes.clear();
      _lastTriggerAt = timestamp;
      BugReportLogService.instance.log(
        'Shake gesture triggered bug reporter (${gForce.toStringAsFixed(2)}g)',
        level: BugLogLevel.info,
        tag: 'shake',
      );
      onShakeDetected();
    }
  }

  /// Helper for debug/testing environments lacking physical motion sensors.
  void simulateShakeForTesting({DateTime? now}) {
    final base = now ?? DateTime.now();
    processSample(30.0, 0.0, 0.0, now: base);
    processSample(-30.0, 0.0, 0.0, now: base.add(const Duration(milliseconds: 220)));
  }

  void dispose() {
    _disposed = true;
    _stopSubscription();
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
    enabled.dispose();
  }
}
