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

  testWidgets('renders forgot password screen with clean input and sends reset',
      (tester) async {
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

    // Verify initial components
    expect(find.text('user@apolo.ma'), findsOneWidget);
    expect(find.byKey(const Key('forgot-email')), findsOneWidget);
    expect(find.byKey(const Key('forgot-submit')), findsOneWidget);

    // Tap submit button
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();

    // Verify success feedback state
    expect(adapter.requests, isNotEmpty);
    expect(adapter.requests.first.path, '/auth/forgot-password');
    expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
  });
}
