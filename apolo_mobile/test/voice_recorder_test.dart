import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/widgets/voice_recorder.dart';

void main() {
  final state = AppState();
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalLocale = state.locale;
    state.currentUser = {'id': 9, 'name': 'Amine'};
    await state.api.setToken('voice-test-token');
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    await state.setLocale(originalLocale);
    state.currentUser = null;
    await state.api.setToken(null);
  });

  group('Rule 1: Instant Feedback on Press', () {
    testWidgets(
        'immediately enters recording state, starts timer, scales mic button to 110%, and fires haptic on press',
        (tester) async {
      final hapticCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            hapticCalls.add('${methodCall.arguments}');
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      VoiceRecordingData? sentData;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VoiceRecorder(
                onSend: (data) => sentData = data,
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        ),
      );

      // Before press: scale is 1.0, active recording bar is not shown
      final scaleBefore = tester.widget<AnimatedScale>(
        find.byKey(const Key('voice-recorder-mic-scale')),
      );
      expect(scaleBefore.scale, 1.0);
      expect(find.byKey(const Key('voice-recorder-active-bar')), findsNothing);

      // Press and hold mic button
      final micCenter =
          tester.getCenter(find.byKey(const Key('voice-recorder-mic-button')));
      final gesture = await tester.startGesture(micCenter);
      await tester.pump();

      // 1. Immediately shows recording state & timer before first word is spoken
      expect(find.byKey(const Key('voice-recorder-active-bar')), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-timer')), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);

      // 2. Scales button up to 110% (1.10) past thumb
      final scaleDuring = tester.widget<AnimatedScale>(
        find.byKey(const Key('voice-recorder-mic-scale')),
      );
      expect(scaleDuring.scale, closeTo(1.10, 0.001));

      // 3. Haptic feedback fired on press
      expect(hapticCalls, isNotEmpty);

      // Advance 1.2s while speaking and release to send
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.text('0:01'), findsOneWidget);

      await gesture.up();
      await tester.pump();

      expect(sentData, isNotNull);
      expect(cancelled, isFalse);
    });
  });

  group('Rule 2: Slide to Cancel Threshold', () {
    testWidgets(
        'shows "Slide to cancel", changes to trash icon + "Release to cancel" past 80px left, and deletes on release',
        (tester) async {
      VoiceRecordingData? sentData;
      int cancelCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: VoiceRecorder(
                onSend: (data) => sentData = data,
                onCancel: () => cancelCount++,
              ),
            ),
          ),
        ),
      );

      final micCenter =
          tester.getCenter(find.byKey(const Key('voice-recorder-mic-button')));
      final gesture = await tester.startGesture(micCenter);
      await tester.pump(const Duration(milliseconds: 300));

      // Initially shows "Slide to cancel" and red recording dot
      expect(find.text('Slide to cancel'), findsOneWidget);
      expect(find.text('Release to cancel'), findsNothing);
      expect(find.byKey(const Key('voice-recorder-red-dot')), findsOneWidget);

      // Slide left by 40px (under 80px threshold): still "Slide to cancel"
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      expect(find.text('Slide to cancel'), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-trash-icon')), findsNothing);

      // Slide left by another 50px (total 90px >= 80px threshold):
      // UI changes to trash can icon & text changes to "Release to cancel"
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      expect(find.text('Release to cancel'), findsOneWidget);
      expect(find.text('Slide to cancel'), findsNothing);
      expect(find.byKey(const Key('voice-recorder-trash-icon')), findsOneWidget);

      // Release at trash area -> deletes message, does NOT send
      await gesture.up();
      await tester.pump();

      expect(cancelCount, 1);
      expect(sentData, isNull);
      expect(find.byKey(const Key('voice-recorder-active-bar')), findsNothing);
    });
  });

  group('Rule 3: Lock for Long Messages', () {
    testWidgets(
        'sliding up past threshold locks hands-free mode, frees thumb, replaces mic with STOP button, and requires explicit tap on STOP',
        (tester) async {
      VoiceRecordingData? sentData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: VoiceRecorder(
                onSend: (data) => sentData = data,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      final micCenter =
          tester.getCenter(find.byKey(const Key('voice-recorder-mic-button')));
      final gesture = await tester.startGesture(micCenter);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('voice-recorder-lock-indicator')), findsOneWidget);

      // Slide up past 60px lock threshold
      await gesture.moveBy(const Offset(0, -75));
      await tester.pump();

      // Free thumb (lift finger): recording MUST continue hands-free!
      await gesture.up();
      await tester.pump();

      expect(find.byKey(const Key('voice-recorder-active-bar')), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-locked-badge')), findsOneWidget);
      expect(sentData, isNull);

      // Mic button is replaced by native iOS Voice Capsule with ✕ cancel, Play/Pause, and blue ↑ Send button
      expect(find.byKey(const Key('voice-recorder-mic-button')), findsNothing);
      expect(find.byKey(const Key('voice-recorder-locked-cancel-button')), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-play-pause-button')), findsOneWidget);
      expect(find.byKey(const Key('voice-recorder-stop-button')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('voice-recorder-stop-button')),
          matching: find.byIcon(CupertinoIcons.arrow_up),
        ),
        findsOneWidget,
      );

      // Timer keeps advancing hands-free after thumb release
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('0:02'), findsOneWidget);
      expect(sentData, isNull);

      // Explicit tap on STOP ends recording and sends
      await tester.tap(find.byKey(const Key('voice-recorder-stop-button')));
      await tester.pump();

      expect(sentData, isNotNull);
      expect(sentData!.durationSeconds, greaterThanOrEqualTo(2));
      expect(find.byKey(const Key('voice-recorder-active-bar')), findsNothing);
    });
  });

  group('Rule 4: Mic Check with Waveform', () {
    testWidgets(
        'displays live waveform, shows "Mic muted" warning when flat for 2+ seconds, and prevents sending when no audio detected',
        (tester) async {
      VoiceRecordingData? sentData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: VoiceRecorder(
                simulateMicMuted: true,
                onSend: (data) => sentData = data,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      final micCenter =
          tester.getCenter(find.byKey(const Key('voice-recorder-mic-button')));
      final gesture = await tester.startGesture(micCenter);
      await tester.pump();

      // Waveform is displayed while recording
      expect(find.byKey(const Key('voice-recorder-waveform')), findsOneWidget);

      // After 1.0s of flat waveform (< 2s): no warning yet
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const Key('voice-recorder-mic-muted-warning')),
        findsNothing,
      );

      // After 2.0s+ of flat waveform: "Mic muted" warning appears!
      await tester.pump(const Duration(milliseconds: 1100));
      expect(
        find.byKey(const Key('voice-recorder-mic-muted-warning')),
        findsOneWidget,
      );
      expect(find.text('Mic muted'), findsOneWidget);

      // Slide up to lock and tap STOP while muted -> must prevent sending!
      await gesture.moveBy(const Offset(0, -75));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      await tester.tap(find.byKey(const Key('voice-recorder-stop-button')));
      await tester.pump();

      expect(
        sentData,
        isNull,
        reason: 'Rule 4: Must prevent sending when no audio was detected',
      );
      expect(find.text('Mic muted'), findsOneWidget);
    });
  });

  group('Rule 5: Scrubbable Playback', () {
    testWidgets(
        'shows waveform + duration, scrubs on drag, cycles 1x/1.5x/2x speed, and animates progress',
        (tester) async {
      double? lastScrubbed;
      double? lastSpeed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: VoiceMessagePlayer(
                messageKey: 'm_audio_1',
                durationLabel: '0:10',
                durationSeconds: 10,
                onScrub: (p) => lastScrubbed = p,
                onSpeedChanged: (s) => lastSpeed = s,
              ),
            ),
          ),
        ),
      );

      // Shows duration and initial 1x speed
      expect(find.text('0:10'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);

      // Drag on waveform to scrub to ~50%
      final scrubberFinder =
          find.byKey(const Key('voice-waveform-scrubber-m_audio_1'));
      final scrubberBox = tester.getRect(scrubberFinder);
      await tester.dragFrom(
        Offset(scrubberBox.left + 5, scrubberBox.center.dy),
        Offset(scrubberBox.width * 0.5, 0),
      );
      await tester.pump();

      expect(lastScrubbed, isNotNull);
      expect(lastScrubbed!, greaterThan(0.35));
      expect(lastScrubbed!, lessThan(0.75));

      // Cycle playback speed: 1x -> 1.5x -> 2x -> 1x
      final speedBtn = find.byKey(const Key('voice-speed-button-m_audio_1'));
      await tester.tap(speedBtn);
      await tester.pump();
      expect(find.text('1.5x'), findsOneWidget);
      expect(lastSpeed, 1.5);

      await tester.tap(speedBtn);
      await tester.pump();
      expect(find.text('2x'), findsOneWidget);
      expect(lastSpeed, 2.0);

      await tester.tap(speedBtn);
      await tester.pump();
      expect(find.text('1x'), findsOneWidget);
      expect(lastSpeed, 1.0);

      // Play and verify waveform progress animates forward
      final progressBefore = lastScrubbed!;
      await tester.tap(find.byKey(const Key('voice-play-button-m_audio_1')));
      await tester.pump(const Duration(milliseconds: 500));

      final thumbPosAfterPlay = tester
          .getTopLeft(find.byKey(const Key('voice-scrubber-thumb-m_audio_1')))
          .dx;
      expect(thumbPosAfterPlay, greaterThan(scrubberBox.left + progressBefore * 40));

      // Pause playback cleanly
      await tester.tap(find.byKey(const Key('voice-play-button-m_audio_1')));
      await tester.pump();
    });
  });

  group('Touch Targets (>= 44px) & ChatRoomScreen Integration', () {
    testWidgets(
        'enforces min 44px touch targets and records + plays scrubbable voice message inside ChatRoomScreen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatRoomScreen(
            conversationId: 90,
            peerName: 'Maya',
            initialMessages: [],
          ),
        ),
      );
      await tester.pump();

      // Mic button touch target >= 44x44px
      final micFinder = find.byKey(const Key('voice-recorder-mic-button'));
      final micSize = tester.getSize(micFinder);
      expect(micSize.width, greaterThanOrEqualTo(44.0));
      expect(micSize.height, greaterThanOrEqualTo(44.0));

      // Hold mic button in ChatRoomScreen for 1.5s and release to send
      final gesture = await tester.startGesture(tester.getCenter(micFinder));
      await tester.pump(const Duration(milliseconds: 1500));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Scrubbable VoiceMessagePlayer bubble is added to the chat room!
      expect(find.byType(VoiceMessagePlayer), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
    });
  });
}
