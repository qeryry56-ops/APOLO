import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/screens/otp_verification_screen.dart';
import 'package:apolo_mobile/screens/widgets/skeleton_loader.dart';
import 'package:apolo_mobile/widgets/chat_message.dart';
import 'package:apolo_mobile/widgets/ios26_imessage_drawer.dart';
import 'package:apolo_mobile/widgets/voice_recorder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalLocale = state.locale;
    state.currentUser = null;
    state.syncUnreadChatCount(0, notify: false);
    await state.api.setToken(null);
  });

  tearDown(() async {
    state.currentUser = null;
    state.syncUnreadChatCount(0, notify: false);
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
  });

  group('BiDi text direction detection', () {
    test('classifies Arabic, Latin, currency, phone numbers, and mixed strings',
        () {
      expect(
        ChatMessage.detectTextDirection('السلام عليكم، شحال آخر ثمن؟'),
        TextDirection.rtl,
      );
      expect(
        ChatMessage.detectTextDirection('Tissot watch black'),
        TextDirection.ltr,
      );
      expect(
        ChatMessage.detectTextDirection('DH 110.00'),
        TextDirection.ltr,
      );
      expect(
        ChatMessage.detectTextDirection('+212 612-345-678'),
        TextDirection.ltr,
      );
      expect(
        ChatMessage.detectTextDirection('1250.50'),
        TextDirection.ltr,
      );
      expect(
        ChatMessage.detectTextDirection('آخر ثمن هو 110 DH'),
        TextDirection.rtl,
      );
    });
  });

  group('ChatRoomScreen RTL/LTR layout & BiDi across mobile and Chrome widths',
      () {
    for (final localeCode in ['ar', 'en']) {
      for (final viewport in [const Size(360, 800), const Size(1280, 800)]) {
        testWidgets(
            'renders without overflow in $localeCode at ${viewport.width.toInt()}x${viewport.height.toInt()}',
            (tester) async {
          final isRtl = localeCode == 'ar';
          await tester.runAsync(() => state.setLocale(Locale(localeCode)));
          state.syncUnreadChatCount(120, notify: false);

          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(splashFactory: NoSplash.splashFactory),
              home: Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: const ChatRoomScreen(
                  conversationId: 42,
                  adId: 77,
                  peerId: 5,
                  peerName: 'محمد بنعلي — متجر الساعات الأصلية',
                  adTitle: 'Tissot Classic Watch Black — ساعة تيسو أصلية',
                  adPrice: '1 250 000 DH',
                  initialMessages: [
                    {
                      'id': 1,
                      'body': 'السلام عليكم، واش الساعة باقية متوفرة؟',
                      'is_mine': false,
                      'sender_name': 'محمد بنعلي التاجر المعتمد',
                      'created_at_time': '10:15',
                    },
                    {
                      'id': 2,
                      'body': 'Tissot watch black - DH 110.00',
                      'is_mine': true,
                      'sender_name': 'أمين',
                      'created_at_time': '10:16',
                      'read': true,
                    },
                    {
                      'id': 3,
                      'body': '+212 612 345 678',
                      'is_mine': false,
                      'sender_name': 'محمد بنعلي التاجر المعتمد',
                      'created_at_time': '10:17',
                    },
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);

          // 1. Directional back chevron matches LTR/RTL
          final backBtn = find.byKey(const Key('chat-ios26-back-button'));
          expect(backBtn, findsOneWidget);
          expect(
            find.descendant(
              of: backBtn,
              matching: find.byIcon(
                isRtl
                    ? CupertinoIcons.chevron_forward
                    : CupertinoIcons.chevron_back,
              ),
            ),
            findsOneWidget,
          );

          // 2. Unread badge `99+` stays LTR isolated even in Arabic RTL
          final unreadText = tester.widget<Text>(find.text('99+'));
          expect(unreadText.textDirection, TextDirection.ltr);

          // 3. Ad banner price stays LTR isolated
          final priceFinder = find.byKey(const Key('chat-ad-context-price'));
          expect(priceFinder, findsOneWidget);
          final priceDir = Directionality.of(tester.element(priceFinder));
          expect(priceDir, TextDirection.ltr);

          // 4. Outgoing bubble aligns to trailing edge (left in RTL, right in LTR)
          final incomingBox = tester.getRect(
            find.text('السلام عليكم، واش الساعة باقية متوفرة؟'),
          );
          final outgoingBox = tester.getRect(
            find.text('Tissot watch black - DH 110.00'),
          );
          if (isRtl) {
            expect(outgoingBox.left, lessThan(incomingBox.left));
          } else {
            expect(outgoingBox.right, greaterThan(incomingBox.right));
          }

          // 5. Phone number bubble uses LTR textDirection
          final phoneText =
              tester.widget<Text>(find.text('+212 612 345 678'));
          expect(phoneText.textDirection, TextDirection.ltr);
        });
      }
    }
  });

  group('Ios26IMessageDrawer RTL/LTR offer composer & overflow safety', () {
    for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
      testWidgets('offer composer mirrors back icon and isolates price in $dir',
          (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isRtl = dir == TextDirection.rtl;
        String? offered;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: Directionality(
              textDirection: dir,
              child: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: Ios26IMessageDrawer(
                    lang: isRtl ? 'ar' : 'en',
                    hasListingContext: true,
                    listingPrice: '1 250 000 DH',
                    onClose: () {},
                    onPickPhoto: () {},
                    onTakePhoto: () {},
                    onStartVoice: () {},
                    onSendLocation: () {},
                    onSendOffer: (v) => offered = v,
                    onSendSticker: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('ios26-app-offer')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Directional back chevron mirrors in RTL
        expect(
          find.byIcon(
            isRtl
                ? CupertinoIcons.chevron_forward
                : CupertinoIcons.chevron_back,
          ),
          findsOneWidget,
        );

        // Offer TextField isolates LTR digits while aligning to visual start
        final field = tester.widget<TextField>(
          find.byKey(const Key('ios26-offer-input')),
        );
        expect(field.textDirection, TextDirection.ltr);
        expect(field.textAlign, isRtl ? TextAlign.end : TextAlign.start);

        await tester.enterText(
          find.byKey(const Key('ios26-offer-input')),
          '950',
        );
        await tester.tap(find.byKey(const Key('ios26-offer-submit')));
        await tester.pump();
        expect(offered, '950');
      });
    }
  });

  group('VoiceRecorder & VoiceMessagePlayer RTL/LTR behavior', () {
    testWidgets(
        'RTL VoiceRecorder mirrors cancel chevron, keeps timer LTR, and cancels on slide right',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int cancelCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: VoiceRecorder(
                  onSend: (_) {},
                  onCancel: () => cancelCount++,
                ),
              ),
            ),
          ),
        ),
      );

      final micCenter =
          tester.getCenter(find.byKey(const Key('voice-recorder-mic-button')));
      final gesture = await tester.startGesture(micCenter);
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      // In RTL, slide-to-cancel chevron points right (inward from left-edge mic)
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
      final timerText = tester.widget<Text>(
        find.byKey(const Key('voice-recorder-timer')),
      );
      expect(timerText.textDirection, TextDirection.ltr);

      // Slide right >= 80px in RTL cancels recording
      await gesture.moveBy(const Offset(95, 0));
      await tester.pump();
      expect(find.byKey(const Key('voice-recorder-trash-icon')), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(cancelCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'RTL VoiceMessagePlayer keeps waveform timeline, duration, and speed LTR and scrubs accurately',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      double? scrubbed;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: VoiceMessagePlayer(
                    messageKey: 'rtl_audio',
                    durationLabel: '0:12',
                    durationSeconds: 12,
                    onScrub: (p) => scrubbed = p,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final durText = tester.widget<Text>(
        find.byKey(const Key('voice-duration-rtl_audio')),
      );
      expect(durText.textDirection, TextDirection.ltr);

      final speedText = tester.widget<Text>(find.text('1x'));
      expect(speedText.textDirection, TextDirection.ltr);

      // Scrubber thumb lives inside an LTR Directionality so waveform fill matches thumb
      final thumbFinder =
          find.byKey(const Key('voice-scrubber-thumb-rtl_audio'));
      expect(
        Directionality.of(tester.element(thumbFinder)),
        TextDirection.ltr,
      );

      final scrubberBox = tester.getRect(
        find.byKey(const Key('voice-waveform-scrubber-rtl_audio')),
      );
      await tester.dragFrom(
        Offset(scrubberBox.left + 4, scrubberBox.center.dy),
        Offset(scrubberBox.width * 0.6, 0),
      );
      await tester.pump();
      expect(scrubbed, isNotNull);
      expect(scrubbed!, greaterThan(0.45));
    });
  });

  group('Broader screens RTL directionality checks', () {
    for (final dir in [TextDirection.rtl, TextDirection.ltr]) {
      testWidgets('OtpVerificationScreen back chevron mirrors in $dir',
          (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final isRtl = dir == TextDirection.rtl;
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: dir,
              child: OtpVerificationScreen(
                destination: '+212 612-345-678',
                onVerify: (_) async => true,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          find.byIcon(
            isRtl ? CupertinoIcons.chevron_right : CupertinoIcons.chevron_left,
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('AdReelsSkeleton mirrors trailing rail in RTL vs LTR',
        (tester) async {
      Future<double> measureRailX(TextDirection dir) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: dir,
              child: const Scaffold(body: AdReelsSkeleton()),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final circles = find.byWidgetPredicate(
          (w) => w is ShimmerBox && w.shape == BoxShape.circle,
        );
        return tester.getCenter(circles.first).dx;
      }

      final ltrX = await measureRailX(TextDirection.ltr);
      final rtlX = await measureRailX(TextDirection.rtl);
      expect(ltrX, greaterThan(rtlX));
    });
  });
}
