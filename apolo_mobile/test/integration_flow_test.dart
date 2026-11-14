import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryBackend {
  final Map<String, Map<String, dynamic>> usersByToken = {};
  final Set<int> favorites = {101};
  int unreadCount = 2;

  Future<ResponseBody> handle(RequestOptions options) async {
    final path = options.path;
    final method = options.method.toUpperCase();
    final auth = options.headers['Authorization']?.toString() ?? '';
    final token = auth.startsWith('Bearer ') ? auth.substring(7) : '';

    if (method == 'GET' && path == '/taxonomy') {
      return _json({
        'status': 'success',
        'categories': [
          {'id': 1, 'name': 'Auto', 'name_ar': 'سيارات', 'name_fr': 'Véhicules', 'slug': 'auto'},
          {'id': 2, 'name': 'Immo', 'name_ar': 'عقارات', 'name_fr': 'Immobilier', 'slug': 'immo'},
        ],
        'cities': [
          {'id': 1, 'name': 'Casablanca', 'name_ar': 'الدار البيضاء', 'name_fr': 'Casablanca'},
          {'id': 2, 'name': 'Rabat', 'name_ar': 'الرباط', 'name_fr': 'Rabat'},
        ],
      });
    }

    if (method == 'POST' && path == '/auth/register') {
      final data = Map<String, dynamic>.from(options.data as Map);
      const newToken = 'tok-reg-1';
      final user = {
        'id': 55,
        'name': data['name'],
        'email': data['email'],
        'phone': data['phone'],
        'email_verified_at': null,
        'onboarding_completed': 0,
      };
      usersByToken[newToken] = user;
      return _json({
        'status': 'success',
        'requires_otp': true,
        'otp_sent': true,
        'token': newToken,
        'user': user,
      }, 201);
    }

    if (method == 'POST' && path == '/auth/otp/verify') {
      final user = usersByToken[token];
      if (user == null) return _json({'status': 'error', 'message': 'Unauthorized'}, 401);
      final data = Map<String, dynamic>.from(options.data as Map);
      if (data['code'] != '123456') {
        return _json({'status': 'error', 'message': 'Invalid OTP'}, 422);
      }
      user['email_verified_at'] = '2026-11-14T12:00:00Z';
      return _json({'status': 'success', 'user': user});
    }

    if (method == 'POST' && path == '/auth/onboarding') {
      final user = usersByToken[token];
      if (user == null) return _json({'status': 'error', 'message': 'Unauthorized'}, 401);
      final data = Map<String, dynamic>.from(options.data as Map);
      user['account_type'] = data['account_type'];
      user['preferred_city_id'] = data['preferred_city_id'];
      user['category_interests'] = data['category_interests'];
      user['onboarding_completed'] = 1;
      return _json({'status': 'success', 'user': user});
    }

    if (method == 'GET' && path == '/auth/profile') {
      final user = usersByToken[token];
      if (user == null) return _json({'status': 'error', 'message': 'Unauthorized'}, 401);
      return _json({'status': 'success', 'user': user});
    }

    if (method == 'GET' && path == '/notifications') {
      if (!usersByToken.containsKey(token)) return _json({'status': 'error'}, 401);
      return _json({'status': 'success', 'unread_count': unreadCount, 'notifications': []});
    }

    if (method == 'GET' && path == '/favorites') {
      if (!usersByToken.containsKey(token)) return _json({'status': 'error'}, 401);
      return _json({
        'status': 'success',
        'data': favorites.map((id) => {'id': id, 'title': 'Ad $id'}).toList(),
      });
    }

    final favMatch = RegExp(r'^/favorites/(\d+)/toggle$').firstMatch(path);
    if (method == 'POST' && favMatch != null) {
      if (!usersByToken.containsKey(token)) return _json({'status': 'error'}, 401);
      final adId = int.parse(favMatch.group(1)!);
      if (adId == 999) {
        return _json({'status': 'error', 'message': 'Server failure'}, 500);
      }
      if (favorites.contains(adId)) {
        favorites.remove(adId);
        return _json({'status': 'success', 'is_favorite': false});
      } else {
        favorites.add(adId);
        return _json({'status': 'success', 'is_favorite': true});
      }
    }

    if (method == 'POST' && path == '/auth/logout') {
      usersByToken.remove(token);
      return _json({'status': 'success'});
    }

    return _json({'status': 'error', 'message': 'Not found: $method $path'}, 404);
  }

  ResponseBody _json(Object data, [int status = 200]) => ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
}

class _BackendAdapter implements HttpClientAdapter {
  final _InMemoryBackend backend;
  _BackendAdapter(this.backend);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      backend.handle(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  late HttpClientAdapter originalAdapter;
  late _InMemoryBackend backend;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalAdapter = appState.api.dio.httpClientAdapter;
    backend = _InMemoryBackend();
    appState.api.dio.httpClientAdapter = _BackendAdapter(backend);
    await appState.initialize(loadRemote: false);
  });

  tearDown(() async {
    appState.api.dio.httpClientAdapter = originalAdapter;
    await appState.api.setToken(null);
    appState.currentUser = null;
    appState.favoriteAdIds.clear();
    appState.unreadNotificationsCount = 0;
  });

  test('Flutter client <-> API full lifecycle: register, OTP, onboard, session, taxonomy, favorites & rollback, logout', () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1/api/v1',
      validateStatus: (status) => status != null && status < 500,
    ));
    dio.httpClientAdapter = _BackendAdapter(backend);
    final auth = AccountAuth(client: dio, locale: 'ar');

    // 1. Register
    final pending = await auth.register(
      name: 'ياسين العلمي',
      email: 'yassine@apolo.ma',
      phone: '0611223344',
      password: 'Password123!',
      confirmation: 'Password123!',
    );
    expect(pending.requiresOtp, isTrue);
    expect(pending.token, 'tok-reg-1');

    // 2. Verify OTP
    final verified = await auth.verify(pending, '123456');
    expect(verified.requiresOtp, isFalse);

    // 3. Complete Onboarding
    final completed = await auth.onboard(verified, 'individual', 1, {1, 2});
    expect(completed.user['onboarding_completed'], 1);

    // 4. Sync AppState session & load taxonomy, favorites, unread notifications
    await appState.setAuthSession(completed.token, completed.user);
    await appState.fetchTaxonomy();
    expect(appState.categories, hasLength(2));
    expect(appState.cities, hasLength(2));

    await appState.fetchFavoritesIds();
    expect(appState.favoriteAdIds, {101});

    await appState.fetchUnreadNotificationsCount();
    expect(appState.unreadNotificationsCount, 2);

    // 5. Toggle favorite persists via API
    await appState.toggleFavorite(202, categoryId: 1);
    expect(appState.favoriteAdIds, {101, 202});
    expect(backend.favorites, {101, 202});

    // 6. Failed toggle on ad 999 rolls back optimistic favorite state
    await appState.toggleFavorite(999, categoryId: 1);
    expect(appState.favoriteAdIds.contains(999), isFalse);

    // 7. Logout clears AppState & invalidates backend token
    await appState.logout();
    expect(appState.isLoggedIn, isFalse);
    expect(appState.favoriteAdIds, isEmpty);
    expect(appState.unreadNotificationsCount, 0);
    expect(backend.usersByToken.containsKey(completed.token), isFalse);
  });
}
