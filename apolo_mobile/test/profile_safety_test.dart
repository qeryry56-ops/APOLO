import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/profile_screen.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/screens/call_screen.dart';
import 'package:apolo_mobile/screens/privacy_compliance_screen.dart';

class SafetyAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  SafetyAdapter(this.reply);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    requests.add(options);
    return await reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody body(Object value, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(value), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

void main() {
  final state = AppState();
  late Dio original;
  late SafetyAdapter adapter;
  var fail = true;
  Map<String, dynamic> user = {};
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'apolo_profile_name': 'Other account',
      'apolo_profile_bio': 'Private old bio'
    });
    original = state.api.dio;
    fail = true;
    user = {'id': 7, 'name': 'Server name', 'bio': '', 'phone': ''};
    adapter = SafetyAdapter((request) {
      if (request.method == 'PUT' ||
          request.method == 'DELETE' ||
          (request.method == 'POST' && request.path.contains('/messages'))) {
        return body({'status': fail ? 'error' : 'success'}, fail ? 500 : 200);
      }
      if (request.path == '/auth/profile') {
        return body({'status': 'success', 'user': user});
      }
      if (request.path.endsWith('/messages')) {
        return body({'status': 'success', 'messages': []});
      }
      return body({'status': 'success', 'data': []});
    });
    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = adapter;
    state.currentUser = user;
    await state.api.setToken('test-token');
  });
  tearDown(() async {
    state.api.dio = original;
    state.currentUser = null;
    await state.api.setToken(null);
  });
  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: screen));
    await tester.pumpAndSettle();
  }

  testWidgets('guest profile never loads private ads or cached identity',
      (tester) async {
    state.currentUser = null;
    await state.api.setToken(null);
    await show(tester, const ProfileScreen());
    expect(find.byKey(const Key('profile-sign-in')), findsOneWidget);
    expect(find.text('Other account'), findsNothing);
    expect(adapter.requests, isEmpty);
  });
  testWidgets('profile failure retains server values and ignores legacy cache',
      (tester) async {
    await show(tester, const ProfileScreen());
    expect(find.text('Other account'), findsNothing);
    expect(find.text('+28%'), findsNothing);
    await tester.tap(find.text('Server name'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(3));
    await tester.enterText(find.byType(TextField).first, 'Unsaved name');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(state.currentUser?['name'], 'Server name');
    expect(find.byKey(const Key('profile-save')), findsOneWidget);
    fail = false;
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(state.currentUser?['name'], 'Unsaved name');
    expect(
        (await SharedPreferences.getInstance()).getString('apolo_profile_name'),
        'Other account');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets(
      'failed text stays a draft, media sends nothing, initial draft is not sent',
      (tester) async {
    await show(
        tester,
        const ChatRoomScreen(
            conversationId: 42, peerName: 'Peer', initialDraft: 'Draft'));
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat-draft')))
            .controller!
            .text,
        'Draft');
    expect(find.text('Draft'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('chat-draft')), '');
    await tester.pump();
    final count = adapter.requests.length;
    await tester.tap(find.byIcon(CupertinoIcons.mic_fill));
    await tester.pumpAndSettle();
    expect(adapter.requests.length, count);
    expect(find.text('Online'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('calls remain unavailable rather than auto connecting',
      (tester) async {
    await show(tester, const CallScreen(peerName: 'Peer', isVideo: true));
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(const Key('calls-unavailable')), findsOneWidget);
    expect(find.text('00:08'), findsNothing);
  });
  testWidgets('failed account deletion retains session, success clears it',
      (tester) async {
    await show(tester, const PrivacyComplianceScreen(initialTab: 1));
    final button = find.byKey(const Key('privacy-delete-account'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف حسابي وبياناتي'));
    await tester.pumpAndSettle();
    expect(state.isLoggedIn, isTrue);
    expect(adapter.requests.where((r) => r.path == '/auth/logout'), isEmpty);
    fail = false;
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف حسابي وبياناتي'));
    await tester.pumpAndSettle();
    expect(state.isLoggedIn, isFalse);
  });
}
