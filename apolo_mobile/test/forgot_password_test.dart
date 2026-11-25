import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/forgot_password_screen.dart';
import 'account_helpers_test.dart' show MockAccountAdapter, json;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppState().currentUser = null;
    await AppState().initialize();
  });

  testWidgets(
      'renders Dynamic Layer v5.1 forgot password screen with exact wrapper geometry and sends reset to OTP step',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = MockAccountAdapter((options) {
      if (options.path == '/auth/forgot-password') {
        return json('{"status":"success","message":"Instructions sent"}');
      }
      return json('{}');
    });
    final client = Dio()..httpClientAdapter = adapter;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: ForgotPasswordScreen(
        initialEmail: 'user@apolo.ma',
        auth: AccountAuth(client: client),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify Dynamic Layer v5.1 layout & filled state
    expect(find.byKey(const Key('forgot-dismiss')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('forgot-dismiss'))),
        const Size(40.0, 40.0));
    final wrapperPad =
        tester.widget<Padding>(find.byKey(const Key('dl-forgot-wrapper')));
    expect(wrapperPad.padding, const EdgeInsets.fromLTRB(16, 32, 16, 32));
    expect(find.byKey(const Key('dl-forgot-helper-text')), findsOneWidget);
    expect(find.text('user@apolo.ma'), findsOneWidget);
    expect(find.byKey(const Key('forgot-email')), findsOneWidget);
    expect(find.byKey(const Key('forgot-submit')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('forgot-submit'))).height, 56.0);

    // Invalid email shows red error and makes zero API calls
    await tester.enterText(find.byKey(const Key('forgot-email')), 'bad-email');
    await tester.pump();
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dl-forgot-error-text')), findsOneWidget);
    expect(adapter.requests, isEmpty);

    // Valid email calls /auth/forgot-password and advances to Step 2 OTP
    await tester.enterText(
        find.byKey(const Key('forgot-email')), 'user@apolo.ma');
    await tester.pump();
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();

    expect(adapter.requests, isNotEmpty);
    expect(adapter.requests.first.path, '/auth/forgot-password');
    expect(find.byKey(const Key('dl-forgot-otp-wrapper')), findsOneWidget);
    expect(find.byKey(const Key('forgot-code')), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('forgot-code')))
            .decoration
            ?.hintText,
        '000000');
  });
}
