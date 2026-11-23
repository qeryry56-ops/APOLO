import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import 'package:apolo_mobile/screens/otp_verification_screen.dart';

class _FakeSmsRetriever implements SmsRetriever {
  final Completer<String?> completer = Completer<String?>();
  bool disposed = false;

  @override
  bool get listenForMultipleSms => false;

  @override
  Future<String?> getSmsCode() => completer.future;

  @override
  Future<void> dispose() async {
    disposed = true;
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }
}

void main() {
  testWidgets(
      'auto-submits 6-digit numeric code, shows green verified state on success, and enforces 30s resend countdown',
      (tester) async {
    String? verifiedCode;
    bool succeeded = false;
    int resendCalls = 0;
    final fakeSms = _FakeSmsRetriever();

    await tester.pumpWidget(
      MaterialApp(
        home: OtpVerificationScreen(
          destination: '+212 612 345 678',
          smsRetriever: fakeSms,
          onVerify: (code) async {
            verifiedCode = code;
            return code == '123456';
          },
          onResend: () async {
            resendCalls++;
          },
          onSuccess: () => succeeded = true,
        ),
      ),
    );

    final pinput = tester.widget<Pinput>(find.byKey(const Key('otp-pinput')));
    expect(pinput.length, 6);
    expect(pinput.keyboardType, TextInputType.number);
    expect(find.text('Resend code in 30s'), findsOneWidget);

    // Advance 30 seconds -> Resend button becomes active
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Resend code'), findsOneWidget);

    await tester.tap(find.byKey(const Key('otp-resend-button')));
    await tester.pump();
    expect(resendCalls, 1);
    expect(find.text('Resend code in 30s'), findsOneWidget);

    // Enter valid 6-digit code -> auto-submits via onCompleted & shows green verified checkmark
    await tester.enterText(find.byKey(const Key('otp-pinput')), '123456');
    await tester.pumpAndSettle();

    expect(verifiedCode, '123456');
    expect(succeeded, isTrue);
    expect(find.byKey(const Key('otp-verified-icon')), findsOneWidget);
    expect(find.byKey(const Key('otp-verified-badge')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(fakeSms.disposed, isTrue);
  });

  testWidgets(
      'invalid OTP triggers shake, red border for 2s, shows "Code incorrect, try again", and clears fields after shake',
      (tester) async {
    final fakeSms = _FakeSmsRetriever();

    await tester.pumpWidget(
      MaterialApp(
        home: OtpVerificationScreen(
          destination: 'amine@apolo.ma',
          smsRetriever: fakeSms,
          onVerify: (code) async => false,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('otp-pinput')), '999999');
    await tester.pump();

    // Error state & message immediately shown
    expect(find.text('Code incorrect, try again'), findsOneWidget);
    expect(
      tester.widget<Pinput>(find.byKey(const Key('otp-pinput'))).forceErrorState,
      isTrue,
    );

    // Shake finishes (420ms) -> fields are cleared, red border remains for 2s
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester
          .widget<Pinput>(find.byKey(const Key('otp-pinput')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester.widget<Pinput>(find.byKey(const Key('otp-pinput'))).forceErrorState,
      isTrue,
    );

    // After 2 seconds -> red error border resets
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.widget<Pinput>(find.byKey(const Key('otp-pinput'))).forceErrorState,
      isFalse,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Android SmsRetriever auto-fills 6-digit OTP and auto-submits',
      (tester) async {
    final fakeSms = _FakeSmsRetriever();
    String? verifiedCode;

    await tester.pumpWidget(
      MaterialApp(
        home: OtpVerificationScreen(
          destination: '+212 600 000 000',
          smsRetriever: fakeSms,
          onVerify: (code) async {
            verifiedCode = code;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    // Simulate incoming Android SMS OTP via SmsRetriever
    fakeSms.completer.complete('654321');
    await tester.pumpAndSettle();

    expect(verifiedCode, '654321');
    expect(find.byKey(const Key('otp-verified-badge')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
