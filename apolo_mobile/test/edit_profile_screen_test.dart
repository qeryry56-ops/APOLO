import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/edit_profile_screen.dart';
import 'package:apolo_mobile/screens/profile_screen.dart';
import 'package:apolo_mobile/widgets/apolo_badges_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeEditProfileAdapter implements HttpClientAdapter {
  _FakeEditProfileAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return await handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object payload, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  late Dio originalDio;
  late _FakeEditProfileAdapter adapter;
  Map<String, dynamic>? lastSavedBody;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    lastSavedBody = null;

    adapter = _FakeEditProfileAdapter((options) {
      if (options.method == 'PUT' && options.path == '/auth/profile') {
        final raw = options.data;
        final map = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        lastSavedBody = map;
        return _json({
          'status': 'success',
          'user': {
            ...?state.currentUser,
            ...map,
          },
        });
      }
      if (options.path == '/auth/username/check') {
        final u = options.queryParameters['username']?.toString() ?? '';
        if (u == 'taken_user') {
          return _json({
            'available': false,
            'message': 'Already taken.',
            'suggestions': ['amine_pro', 'amine_ma'],
          });
        }
        return _json({'available': true});
      }
      if (options.path == '/cities') {
        return _json({
          'status': 'success',
          'data': [
            {'id': 1, 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
            {'id': 2, 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
          ],
        });
      }
      if (options.path == '/auth/profile' || options.path == '/auth/me') {
        return _json({'status': 'success', 'user': state.currentUser});
      }
      return _json({'status': 'success', 'data': []});
    });

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://edit-profile.test'))
      ..httpClientAdapter = adapter;
    state.cities = [
      {'id': 1, 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
      {'id': 2, 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
    ];
    state.currentUser = {
      'id': 11,
      'name': 'Amine Elas',
      'username': 'elas_amine',
      'bio': 'Original bio',
      'city': 'Casablanca',
      'city_id': 1,
      'phone': '+212600112233',
      'account_type': 'personal',
      'is_pro_plus': false,
      'is_verified': false,
    };
    await state.api.setToken('valid-token');
    await state.setLocale(const Locale('en'));
  });

  tearDown(() async {
    state.api.dio = originalDio;
    state.currentUser = null;
    state.cities = [];
    await state.api.setToken(null);
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    ThemeMode themeMode = ThemeMode.light,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'updates Name, Username, Bio, City, and Phone from ProfileScreen and persists to AppState',
      (tester) async {
    await pumpApp(tester, const ProfileScreen());
    state.cities = [
      {'id': 1, 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
      {'id': 2, 'name_ar': 'مراكش', 'name_fr': 'Marrakech'},
    ];

    await tester.tap(find.byKey(const Key('profile-edit-btn')));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.byKey(const Key('edit-profile-upgrade-row')), findsOneWidget);
    expect(find.byKey(const Key('edit-profile-business-row')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('edit-profile-name-field')),
      'Amine Studio',
    );
    await tester.enterText(
      find.byKey(const Key('edit-profile-username-field')),
      'amine_studio',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('edit-profile-bio-field')),
      'Curated tech & design gear in Morocco',
    );
    await tester.pump();
    expect(find.text('37/150'), findsOneWidget);

    // Select Marrakech from city sheet
    await tester.ensureVisible(find.byKey(const Key('edit-profile-city-row')));
    await tester.tap(find.byKey(const Key('edit-profile-city-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marrakech'));
    await tester.pumpAndSettle();
    expect(find.text('Marrakech'), findsOneWidget);

    // Edit phone via modal sheet
    await tester.ensureVisible(find.byKey(const Key('edit-profile-phone-row')));
    await tester.tap(find.byKey(const Key('edit-profile-phone-row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-profile-phone-input')),
      '+212699887766',
    );
    await tester.tap(find.byKey(const Key('edit-profile-phone-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('+212699887766'), findsOneWidget);

    // Save changes
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(lastSavedBody?['name'], 'Amine Studio');
    expect(lastSavedBody?['username'], 'amine_studio');
    expect(lastSavedBody?['bio'], 'Curated tech & design gear in Morocco');
    expect(lastSavedBody?['city'], 'Marrakech');
    expect(lastSavedBody?['city_id'], 2);
    expect(lastSavedBody?['phone'], '+212699887766');
    expect(state.currentUser?['name'], 'Amine Studio');
    expect(state.currentUser?['username'], 'amine_studio');
    expect(find.text('Amine Studio'), findsOneWidget);
  });

  testWidgets(
      'renders Dark Mode + Arabic RTL cleanly without overflow and shows Business row for Premium subscriber',
      (tester) async {
    await tester.runAsync(() => state.setLocale(const Locale('ar')));
    state.currentUser = {
      ...?state.currentUser,
      'account_type': 'business',
      'is_pro_plus': true,
      'is_verified': true,
    };

    await pumpApp(
      tester,
      const EditProfileScreen(),
      themeMode: ThemeMode.dark,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('تعديل الملف الشخصي'), findsOneWidget);
    expect(find.byKey(const Key('edit-profile-business-row')), findsOneWidget);
    expect(find.byKey(const Key('edit-profile-upgrade-row')), findsNothing);
    expect(find.byType(ApoloVerifiedBadge), findsWidgets);
  });
}
