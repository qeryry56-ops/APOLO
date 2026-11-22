import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/bug_report/services/bug_report_log_service.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static const String _envelopeSecret = 'apolo_ma_token_v2_key_2026';

  late Dio dio;
  String? _token;
  String _locale = 'ar';

  static String _encodeTokenEnvelope(String raw) {
    final secretBytes = utf8.encode(_envelopeSecret);
    final rawBytes = utf8.encode(raw);
    final out = List<int>.generate(
      rawBytes.length,
      (i) => rawBytes[i] ^ secretBytes[i % secretBytes.length],
    );
    return 'v2:${base64Url.encode(out)}';
  }

  static String? _decodeTokenEnvelope(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (!stored.startsWith('v2:')) return stored;
    try {
      final secretBytes = utf8.encode(_envelopeSecret);
      final encoded = stored.substring(3);
      final bytes = base64Url.decode(encoded);
      final decoded = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ secretBytes[i % secretBytes.length],
      );
      return utf8.decode(decoded);
    } catch (_) {
      return null;
    }
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.effectiveBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Accept-Language': _locale,
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = AppConfig.effectiveBaseUrl;
          options.headers['Accept-Language'] = _locale;
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (err, handler) {
          BugReportLogService.instance.recordApiError(
            method: err.requestOptions.method,
            path: err.requestOptions.path,
            statusCode: err.response?.statusCode,
            errorType: err.type.name,
          );
          return handler.next(err);
        },
      ),
    );
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final secureToken = _decodeTokenEnvelope(prefs.getString('auth_token_secure'));
    _token = secureToken ?? prefs.getString('auth_token');
    _locale = prefs.getString('app_locale') ?? 'ar';
    final savedEnv = prefs.getString('api_base_url');
    if (savedEnv != null && savedEnv.isNotEmpty) {
      AppConfig.currentBaseUrl = savedEnv;
    }
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove('auth_token');
      await prefs.remove('auth_token_secure');
    } else {
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_token_secure', _encodeTokenEnvelope(token));
    }
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale);
  }

  Future<void> setBaseUrl(String url) async {
    AppConfig.currentBaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String get locale => _locale;
}
