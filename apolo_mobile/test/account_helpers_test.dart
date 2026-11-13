import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apolo_mobile/account/account_helpers.dart';

class MockAccountAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) reply;
  final List<RequestOptions> requests = [];
  MockAccountAdapter(this.reply);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    requests.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(String value, [int status = 200]) =>
    ResponseBody.fromString(value, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

void main() {
  group('account input validation', () {
    test('email rejects malformed and whitespace-containing addresses', () {
      for (final email in [
        'a@',
        'a @b.ma',
        'a..b@example.ma',
        'a.@example.ma',
        'a@-host.ma',
        'a@host',
        'a\n@host.ma'
      ]) {
        expect(AccountValidation.email(email), isFalse, reason: email);
      }
      expect(AccountValidation.email(' name+ad@example.ma '), isTrue);
    });
    test(
        'normalizes Moroccan numbers and Arabic digits without accepting letters',
        () {
      expect(AccountValidation.phone('٠٦ ١٢ ٣٤ ٥٦ ٧٨'), '+212612345678');
      expect(AccountValidation.phone('00212612345678'), '+212612345678');
      expect(AccountValidation.phone('+212 5 22 12 34 56'), '+212522123456');
      for (final phone in [
        'abcdefghij',
        '061234',
        '+2120612345678',
        '0912345678',
        '+33123456789'
      ]) {
        expect(AccountValidation.phone(phone), isNull);
      }
    });
    test('new password and OTP validation', () {
      expect(AccountValidation.password('        '), isFalse);
      expect(AccountValidation.password('short'), isFalse);
      expect(AccountValidation.password('long passphrase'), isTrue);
      expect(AccountValidation.otp('123abc'), isFalse);
      expect(AccountValidation.otp('12345'), isFalse);
      expect(AccountValidation.otp('۱۲۳۴۵۶'), isTrue);
    });
    test('website derives known HTTPS origin, not guessed account path', () {
      expect(accountWebsite.toString(), 'https://apolo.ma/');
    });
  });

  group('isolated authentication requests', () {
    late Dio dio;
    late AccountAuth auth;
    late MockAccountAdapter adapter;
    void setup(ResponseBody Function(RequestOptions) reply) {
      adapter = MockAccountAdapter(reply);
      dio = Dio(BaseOptions(baseUrl: 'https://local-test.invalid'))
        ..httpClientAdapter = adapter;
      auth = AccountAuth(client: dio);
    }

    tearDown(() => dio.close(force: true));

    test('invalid login never sends a request', () async {
      setup((_) => json('{}'));
      await expectLater(
          auth.login('invalid', 'password'), throwsA(isA<AccountFailure>()));
      expect(adapter.requests, isEmpty);
    });
    test('registration requires explicit matching confirmation', () async {
      setup((_) => json('{}'));
      await expectLater(
          auth.register(
              name: 'Test User',
              email: 'test@example.ma',
              phone: '0612345678',
              password: 'password',
              confirmation: ''),
          throwsA(isA<AccountFailure>()));
      expect(adapter.requests, isEmpty);
    });
    test('registration normalizes phone and never establishes session',
        () async {
      setup((_) =>
          json('{"token":"pending","user":{"id":7,"email_verified_at":null}}'));
      final result = await auth.register(
          name: 'Test User',
          email: 'test@example.ma',
          phone: '0612345678',
          password: 'password',
          confirmation: 'password');
      expect(adapter.requests.single.path, '/auth/register');
      expect(adapter.requests.single.data['phone'], '+212612345678');
      expect(result.requiresOtp, isTrue);
      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    });
    test('login accepts nested verified session only with server user',
        () async {
      setup((_) => json(
          '{"data":{"access_token":"server-token","user":{"id":7,"email_verified_at":"2026-01-01"}}}'));
      final result = await auth.login('test@example.ma', 'old');
      expect(result.requiresOtp, isFalse);
      expect(result.user['id'], 7);
      expect(adapter.requests.single.path, '/auth/login');
    });
    test('missing user cannot become an invented local account', () async {
      setup((_) => json('{"token":"server-token"}'));
      await expectLater(auth.login('test@example.ma', 'password'),
          throwsA(isA<AccountFailure>()));
    });
    test('unverified user always requires OTP even if requires_otp false',
        () async {
      setup((_) =>
          json('{"requires_otp":false,"token":"pending","user":{"id":7}}'));
      expect((await auth.login('test@example.ma', 'password')).requiresOtp,
          isTrue);
    });
    test('OTP requires explicit success, not HTTP 200 alone', () async {
      setup((_) => json('{"message":"invalid code"}'));
      const pending = AccountSession('pending', {'id': 7}, requiresOtp: true);
      await expectLater(
          auth.verify(pending, '123456'), throwsA(isA<AccountFailure>()));
      expect(pending.requiresOtp, isTrue);
      expect(
          adapter.requests.single.headers['Authorization'], 'Bearer pending');
      expect(dio.options.headers.containsKey('Authorization'), isFalse);
    });
    test('OTP normalized and acknowledged by server', () async {
      setup((_) => json('{"status":"success"}'));
      const pending = AccountSession('pending', {'id': 7}, requiresOtp: true);
      final verified = await auth.verify(pending, '١٢٣٤٥٦');
      expect(verified.requiresOtp, isFalse);
      expect(adapter.requests.single.data['code'], '123456');
    });
    test('resend never treats error payload as success', () async {
      setup((_) => json('{"status":"error","message":"try later"}'));
      await expectLater(
          auth.resend(
              const AccountSession('pending', {'id': 7}, requiresOtp: true)),
          throwsA(isA<AccountFailure>()));
    });
    test('401 propagates without fake offline session', () async {
      setup((_) => json('{"message":"Unauthorized"}', 401));
      await expectLater(auth.login('test@example.ma', 'password'),
          throwsA(isA<DioException>()));
    });
    test('onboarding cannot bypass pending verification', () async {
      setup((_) => json('{}'));
      await expectLater(
          auth.onboard(
              const AccountSession('pending', {'id': 7}, requiresOtp: true),
              'individual',
              2,
              {4}),
          throwsA(isA<AccountFailure>()));
      expect(adapter.requests, isEmpty);
    });
    test('onboarding success must be confirmed by authoritative profile',
        () async {
      setup((options) => options.path == '/auth/onboarding'
          ? json('{"status":"success"}')
          : json(
              '{"status":"success","user":{"id":7,"onboarding_completed":true}}'));
      final result = await auth.onboard(
          const AccountSession('pending', {'id': 7}, requiresOtp: false),
          'individual',
          2,
          {4});
      expect(result.user['onboarding_completed'], isTrue);
      expect(adapter.requests.map((r) => r.path),
          ['/auth/onboarding', '/auth/profile']);
      expect(adapter.requests.first.data['preferred_city_id'], 2);
    });
    test('failed onboarding does not fabricate completion or fetch profile',
        () async {
      setup((_) => json('{"status":"error"}'));
      await expectLater(
          auth.onboard(
              const AccountSession('pending', {'id': 7}, requiresOtp: false),
              'individual',
              2,
              {4}),
          throwsA(isA<AccountFailure>()));
      expect(adapter.requests.length, 1);
    });
    test('onboarding refuses unconfirmed profile state', () async {
      setup((options) => options.path == '/auth/onboarding'
          ? json('{"status":"success"}')
          : json(
              '{"status":"success","user":{"id":7,"onboarding_completed":false}}'));
      await expectLater(
          auth.onboard(
              const AccountSession('pending', {'id': 7}, requiresOtp: false),
              'individual',
              2,
              {4}),
          throwsA(isA<AccountFailure>()));
    });
    test('network failure remains failure', () async {
      setup((options) => throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError));
      await expectLater(auth.login('test@example.ma', 'password'),
          throwsA(isA<DioException>()));
    });

    test('login accepts email_verified boolean without triggering OTP',
        () async {
      setup((options) => json(
          '{"token":"ok","user":{"id":10,"name":"Ali","email":"ali@apolo.ma","email_verified":true}}'));
      final session = await auth.login('ali@apolo.ma', 'password');
      expect(session.requiresOtp, isFalse);
      expect(session.otpSent, isFalse);
    });

    test('login propagates otp_sent true/false accurately', () async {
      setup((options) => json(
          '{"token":"pending","requires_otp":true,"otp_sent":false,"user":{"id":11,"email":"b@apolo.ma","email_verified_at":null}}'));
      final failedDispatch = await auth.login('b@apolo.ma', 'password');
      expect(failedDispatch.requiresOtp, isTrue);
      expect(failedDispatch.otpSent, isFalse);

      setup((options) => json(
          '{"token":"pending","requires_otp":true,"otp_sent":true,"user":{"id":11,"email":"b@apolo.ma","email_verified_at":null}}'));
      final okDispatch = await auth.login('b@apolo.ma', 'password');
      expect(okDispatch.requiresOtp, isTrue);
      expect(okDispatch.otpSent, isTrue);
    });
  });
}
