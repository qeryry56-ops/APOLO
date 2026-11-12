import 'package:dio/dio.dart';
import '../core/config/app_config.dart';

/// Website origin only: no undocumented account route is guessed.
Uri get accountWebsite => Uri.parse(AppConfig.prodBaseUrl)
    .replace(path: '/', query: null, fragment: null);

class AccountValidation {
  static String normalizeDigits(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.split('').map((c) {
      final index = arabic.indexOf(c);
      final other = persian.indexOf(c);
      return index >= 0
          ? '$index'
          : other >= 0
              ? '$other'
              : c;
    }).join();
  }

  static bool email(String value) {
    final text = value.trim();
    if (text.length > 254 || text.contains('..')) return false;
    return RegExp(
                r'^[a-zA-Z0-9][a-zA-Z0-9._%+\-]*@[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)+$')
            .hasMatch(text) &&
        !text.split('@').first.endsWith('.');
  }

  static String? phone(String value) {
    final text =
        normalizeDigits(value).trim().replaceAll(RegExp(r'[\s().-]'), '');
    if (RegExp(r'^0[5-7][0-9]{8}$').hasMatch(text)) {
      return '+212${text.substring(1)}';
    }
    if (RegExp(r'^00212[5-7][0-9]{8}$').hasMatch(text)) {
      return '+${text.substring(2)}';
    }
    if (RegExp(r'^\+212[5-7][0-9]{8}$').hasMatch(text)) return text;
    return null;
  }

  static bool password(String value) =>
      value.length >= 8 && value.trim().isNotEmpty;
  static bool otp(String value) =>
      RegExp(r'^[0-9]{6}$').hasMatch(normalizeDigits(value).trim());
}

class AccountFailure implements Exception {
  final String kind;
  const AccountFailure(this.kind);
}

class AccountSession {
  final String token;
  final Map<String, dynamic> user;
  final bool requiresOtp;
  const AccountSession(this.token, this.user, {required this.requiresOtp});
}

/// Only routes already referenced by the local application. Pending tokens stay
/// on this isolated client, never ApiClient/setToken or SharedPreferences.
class AccountAuth {
  final Dio dio;
  AccountAuth({Dio? client, String locale = 'fr'})
      : dio = client ??
            Dio(BaseOptions(
              baseUrl: AppConfig.currentBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                'Accept': 'application/json',
                'Accept-Language': locale
              },
            ));
  Map<String, dynamic> _payload(Response<dynamic> response) {
    if (response.data is! Map) throw const AccountFailure('response');
    final root = Map<String, dynamic>.from(response.data as Map);
    if (root['success'] == false ||
        root['status'] == 'error' ||
        root['status'] == 'failed') {
      throw const AccountFailure('rejected');
    }
    return root;
  }

  AccountSession _session(Response<dynamic> response,
      {bool registration = false}) {
    final root = _payload(response);
    final data = root['data'] is Map
        ? Map<String, dynamic>.from(root['data'] as Map)
        : root;
    final token = data['token'] ??
        data['access_token'] ??
        root['token'] ??
        root['access_token'];
    final user = data['user'] ?? root['user'];
    if (token is! String ||
        token.trim().isEmpty ||
        user is! Map ||
        user['id'] == null) {
      throw const AccountFailure('response');
    }
    return AccountSession(token, Map<String, dynamic>.from(user),
        requiresOtp: registration ||
            root['requires_otp'] == true ||
            data['requires_otp'] == true ||
            user['email_verified_at'] == null);
  }

  Future<AccountSession> login(String email, String password) async {
    if (!AccountValidation.email(email) || password.isEmpty) {
      throw const AccountFailure('validation');
    }
    return _session(await dio.post('/auth/login', data: {
      'login': email.trim(),
      'email': email.trim(),
      'password': password
    }));
  }

  Future<AccountSession> register(
      {required String name,
      required String email,
      required String phone,
      required String password,
      required String confirmation}) async {
    final normalizedPhone = AccountValidation.phone(phone);
    if (name.trim().length < 2 ||
        !AccountValidation.email(email) ||
        normalizedPhone == null ||
        !AccountValidation.password(password) ||
        password != confirmation) {
      throw const AccountFailure('validation');
    }
    return _session(
        await dio.post('/auth/register', data: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': normalizedPhone,
          'password': password,
          'password_confirmation': confirmation,
          'referral_source': 'mobile_app'
        }),
        registration: true);
  }

  Future<AccountSession> verify(AccountSession pending, String code) async {
    if (!AccountValidation.otp(code)) throw const AccountFailure('validation');
    final root = _payload(await dio.post('/auth/otp/verify',
        data: {'code': AccountValidation.normalizeDigits(code).trim()},
        options:
            Options(headers: {'Authorization': 'Bearer ${pending.token}'})));
    if (root['status'] != 'success') throw const AccountFailure('verification');
    final data = root['data'] is Map ? root['data'] as Map : root;
    final user = data['user'];
    return AccountSession(
        pending.token,
        user is Map && user['id'] != null
            ? Map<String, dynamic>.from(user)
            : pending.user,
        requiresOtp: false);
  }

  Future<void> resend(AccountSession pending) async {
    final root = _payload(await dio.post('/auth/otp/resend',
        options:
            Options(headers: {'Authorization': 'Bearer ${pending.token}'})));
    if (root['status'] != 'success') throw const AccountFailure('verification');
  }

  Future<Map<String, dynamic>> taxonomy() async {
    final root = _payload(await dio.get('/taxonomy'));
    if (root['status'] != 'success') throw const AccountFailure('response');
    return root;
  }

  Future<AccountSession> onboard(AccountSession pending, String type, int city,
      Set<int> categories) async {
    if (pending.requiresOtp ||
        !['individual', 'pro'].contains(type) ||
        city <= 0 ||
        categories.isEmpty ||
        categories.any((id) => id <= 0)) {
      throw const AccountFailure('validation');
    }
    final options =
        Options(headers: {'Authorization': 'Bearer ${pending.token}'});
    final root = _payload(await dio.post('/auth/onboarding',
        data: {
          'account_type': type,
          'preferred_city_id': city,
          'category_interests': categories.toList(),
        },
        options: options));
    if (root['status'] != 'success') throw const AccountFailure('response');
    final profile = _payload(await dio.get('/auth/profile', options: options));
    final user = profile['user'];
    if (user is! Map ||
        user['id'] != pending.user['id'] ||
        (user['onboarding_completed'] != true &&
            user['onboarding_completed'] != 1)) {
      throw const AccountFailure('response');
    }
    return AccountSession(pending.token, Map<String, dynamic>.from(user),
        requiresOtp: false);
  }

  Future<void> requestPasswordReset(String email) async {
    if (!AccountValidation.email(email)) {
      throw const AccountFailure('validation');
    }
    try {
      final res = await dio.post('/auth/forgot-password', data: {
        'email': email.trim(),
        'login': email.trim(),
      });
      _payload(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback for standard Laravel password reset route
        final res = await dio.post('/auth/password/email', data: {
          'email': email.trim(),
        });
        _payload(res);
      } else {
        rethrow;
      }
    }
  }

  Future<void> resetPasswordWithToken({
    required String email,
    required String token,
    required String password,
    required String confirmation,
  }) async {
    if (!AccountValidation.email(email) ||
        !AccountValidation.password(password) ||
        password != confirmation) {
      throw const AccountFailure('validation');
    }
    final res = await dio.post('/auth/password/reset', data: {
      'email': email.trim(),
      'token': token.trim(),
      'password': password,
      'password_confirmation': confirmation,
    });
    _payload(res);
  }

  void close() => dio.close(force: true);
}

String accountError(Object error, bool ar) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 429) {
      return ar
          ? 'محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.'
          : 'Trop de tentatives. Patientez avant de réessayer.';
    }
    if (status == 401 || status == 403) {
      return ar
          ? 'تعذر تأكيد بيانات الدخول أو رمز التحقق.'
          : 'Identifiants ou code de vérification refusés.';
    }
    if (status == 422) {
      return ar
          ? 'تحقق من البيانات المدخلة. قد يكون البريد مستخدماً بالفعل.'
          : 'Vérifiez les informations. Cette adresse est peut-être déjà utilisée.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ar
          ? 'تعذر الاتصال. تحقق من الإنترنت وأعد المحاولة.'
          : 'Connexion impossible. Vérifiez Internet et réessayez.';
    }
  }
  return ar
      ? 'لم يتم تأكيد العملية. أعد المحاولة أو استخدم الموقع.'
      : 'L’opération n’a pas été confirmée. Réessayez ou utilisez le site.';
}
