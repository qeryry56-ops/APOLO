import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  _Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  late HttpClientAdapter original;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    original = state.api.dio.httpClientAdapter;
    await state.api.setToken('test-token');
    state.currentUser = {'id': 1, 'name': 'Test'};
    state.favoriteAdIds = {12};
  });
  tearDown(() async {
    state.api.dio.httpClientAdapter = original;
    state.currentUser = null;
    state.favoriteAdIds.clear();
    await state.api.setToken(null);
  });
  test('profile timeout preserves verified session and favorites', () async {
    state.api.dio.httpClientAdapter = _Adapter((options) async {
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionTimeout);
    });
    await state.fetchMe();
    expect(state.isLoggedIn, isTrue);
    expect(state.favoriteAdIds, {12});
  });
  test('favorites failure cannot log user out', () async {
    state.api.dio.httpClientAdapter = _Adapter((options) async {
      return options.path == '/auth/profile'
          ? jsonBody({
              'status': 'success',
              'user': {'id': 1, 'name': 'Updated'}
            })
          : jsonBody({'status': 'error'}, 500);
    });
    await state.fetchMe();
    expect(state.isLoggedIn, isTrue);
    expect(state.currentUser?['name'], 'Updated');
    expect(state.favoriteAdIds, {12});
  });
  test('profile unauthorized clears credentials and favorites', () async {
    state.api.dio.httpClientAdapter = _Adapter((_) async => jsonBody({}, 401));
    await state.fetchMe();
    expect(state.isLoggedIn, isFalse);
    expect(state.api.isAuthenticated, isFalse);
    expect(state.favoriteAdIds, isEmpty);
  });
  test('local initialization does not wait for network', () async {
    var requests = 0;
    state.api.dio.httpClientAdapter = _Adapter((_) async {
      requests++;
      return jsonBody({});
    });
    await state.initialize(loadRemote: false);
    expect(requests, 0);
    expect(state.isInitialized, isTrue);
  });
}
