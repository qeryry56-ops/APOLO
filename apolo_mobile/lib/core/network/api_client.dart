import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  String? _token;
  String _locale = 'ar';

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.currentBaseUrl,
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
          options.baseUrl = AppConfig.currentBaseUrl;
          options.headers['Accept-Language'] = _locale;
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _locale = prefs.getString('app_locale') ?? 'ar';
    final savedEnv = prefs.getString('api_base_url');
    if (savedEnv != null && savedEnv.isNotEmpty) {
      AppConfig.currentBaseUrl = savedEnv;
    }
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove('auth_token');
    } else {
      await prefs.setString('auth_token', token);
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
