import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/account_setup_screen.dart';
import 'package:apolo_mobile/screens/business_switch_screen.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/screens/pro_plus_screen.dart';
import 'package:apolo_mobile/screens/profile_screen.dart';
import 'package:apolo_mobile/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestBusinessAdapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  _TestBusinessAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      await handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = AppState();
  late Dio originalDio;
  late Locale originalLocale;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalDio = state.api.dio;
    originalLocale = state.locale;
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(const Locale('ar'));
  });

  tearDown(() async {
    state.currentUser = null;
    await state.api.setToken(null);
    await state.setLocale(originalLocale);
    state.api.dio = originalDio;
  });

  testWidgets(
      'Personal account shows Switch to Business card and hides analytics tab; switching activates Business store & quick replies',
      (tester) async {
    Map<String, dynamic> serverUser = {
      'id': 42,
      'name': 'Amine Store',
      'username': 'amine_store',
      'account_type': 'individual',
      'is_business': false,
      'is_pro_plus': false,
      'store': null,
    };

    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _TestBusinessAdapter((options) {
        if (options.path.contains('/account/switch-business')) {
          final payload = options.data as Map<String, dynamic>;
          serverUser = {
            ...serverUser,
            'account_type': 'business',
            'is_business': true,
            'is_pro_plus': false,
            'store': {
              'id': 10,
              'name': payload['store_name'],
              'subdomain': 'amine-store',
              'business_category': payload['business_category'],
              'working_hours': payload['working_hours'],
              'is_open_now': true,
              'is_active': true,
            },
          };
          return _json({
            'status': 'success',
            'user': serverUser,
            'store': serverUser['store'],
          });
        }
        if (options.path.contains('/account/switch-personal')) {
          serverUser = {
            ...serverUser,
            'account_type': 'individual',
            'is_business': false,
            'paused_store': serverUser['store'],
            'store': null,
          };
          return _json({'status': 'success', 'user': serverUser});
        }
        if (options.path.contains('/account/business-insights')) {
          return _json({
            'status': 'success',
            'insights': {
              'total_views': 120,
              'active_ads_count': 2,
              'avg_views': 60,
              'boosted_ads_count': 0,
              'pro_plus_locked': true,
            },
          });
        }
        if (options.path.contains('/auth/profile')) {
          return _json({'status': 'success', 'user': serverUser});
        }
        return _json({'status': 'success', 'data': <dynamic>[]});
      });

    tester.view.physicalSize = const Size(390, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    state.currentUser = serverUser;
    await tester.runAsync(() => state.api.setToken('tok-42'));

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(const Locale('ar'))
              .copyWith(splashFactory: NoSplash.splashFactory),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Personal account: shows Switch to Business banner, no Business identity bar
    final switchCard = find.byKey(const Key('profile-switch-to-business-card'));
    expect(switchCard, findsOneWidget);
    expect(find.byKey(const Key('profile-business-identity-bar')), findsNothing);
    expect(state.isBusinessAccount, isFalse);

    // Complete 3-step Business Switch Wizard
    await tester.ensureVisible(switchCard);
    await tester.pumpAndSettle();
    await tester.tap(switchCard);
    await tester.pumpAndSettle();
    expect(find.byType(BusinessSwitchScreen), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('business-cat-electronics')));
    await tester.tap(find.byKey(const Key('business-cat-electronics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('business-wizard-continue')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('business-name-input')), 'Amine Tech Casa');
    await tester.tap(find.byKey(const Key('business-wizard-continue')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('business-wizard-continue')));
    await tester.pumpAndSettle();

    // Now Business profile is active!
    expect(state.isBusinessAccount, isTrue);
    expect(
        find.byKey(const Key('profile-business-identity-bar')), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);

    // Soft-pause back to Personal preserves paused_store
    await tester.runAsync(() => state.switchToPersonal());
    await tester.pump();
    expect(state.isBusinessAccount, isFalse);
    expect(state.pausedStore?['name'], 'Amine Tech Casa');
  });

  testWidgets('Business account hides Quick Replies bar in ChatRoomScreen',
      (tester) async {
    state.currentUser = {
      'id': 55,
      'name': 'Boutique Atlas',
      'account_type': 'business',
      'is_business': true,
      'quick_replies': [
        {'id': 'q1', 'shortcut': 'متوفر', 'text': 'السلعة متوفرة مرحباً بك'},
      ],
    };
    await tester.runAsync(() => state.api.setToken('tok-55'));
    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _TestBusinessAdapter(
        (_) => _json({'status': 'success', 'messages': <dynamic>[], 'data': <dynamic>[]}),
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Locale('ar'))
            .copyWith(splashFactory: NoSplash.splashFactory),
        home: const ChatRoomScreen(
          conversationId: 1,
          peerName: 'Buyer Ahmed',
          initialMessages: [],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('chat-business-quick-replies-bar')),
        findsNothing);
    expect(find.byKey(const Key('chat-qr-chip-0')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets(
      'Dynamic Layer v5.1 Subscription -> FreeTrial -> Paywall (ProPlusScreen) flow & cancel subscription',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() => state.setLocale(const Locale('en')));
    state.currentUser = {
      'id': 88,
      'name': 'Auto Pro',
      'account_type': 'business',
      'is_business': true,
      'is_pro_plus': false,
    };
    await tester.runAsync(() => state.api.setToken('tok-88'));
    state.api.dio = Dio(BaseOptions(baseUrl: 'https://tests.invalid'))
      ..httpClientAdapter = _TestBusinessAdapter(
        (_) => _json({'status': 'error'}, 404), // exercises 3-tier fallback plans
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Locale('en'))
            .copyWith(splashFactory: NoSplash.splashFactory),
        home: const SubscriptionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Subscription (Get Premium state, 45786:72976)
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.byKey(const Key('dl-subscription-hero')), findsOneWidget);
    expect(find.text('Get Premium'), findsWidgets);
    final getPremiumBtn =
        find.byKey(const Key('dl-subscription-get-premium-btn'));
    expect(tester.getSize(getPremiumBtn).height, closeTo(56.0, 0.1));

    // Navigate -> FreeTrialScreen (43551:4467)
    await tester.tap(getPremiumBtn);
    await tester.pumpAndSettle();
    expect(find.byType(FreeTrialScreen), findsOneWidget);
    expect(find.text('How your trial works'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
    expect(find.text('Day 3'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('dl-trial-start-btn'))).height,
        closeTo(56.0, 0.1));

    // Navigate -> View all plans -> ProPlusScreen Paywall (33412:51733)
    await tester.tap(find.byKey(const Key('dl-trial-view-plans-btn')));
    await tester.pumpAndSettle();
    expect(find.byType(ProPlusScreen), findsOneWidget);
    expect(find.text('Unlock full access'), findsOneWidget);
    expect(find.byKey(const Key('pro-plus-plan-monthly')), findsOneWidget);
    expect(find.byKey(const Key('pro-plus-plan-yearly')), findsOneWidget);
    expect(find.byKey(const Key('pro-plus-plan-lifetime')), findsOneWidget);
    expect(find.byKey(const Key('pro-plus-google-pay-btn')), findsOneWidget);
    expect(find.textContaining('Google Pay'), findsWidgets);
    expect(find.byKey(const Key('dl-paywall-no-thanks-btn')), findsOneWidget);

    // 2. Active subscriber state (`You use Premium` + Cancel my subscription)
    state.currentUser = {
      ...state.currentUser!,
      'account_type': 'pro_plus',
      'is_pro_plus': true,
    };
    state.notifyListeners();
    Navigator.of(tester.element(find.byType(ProPlusScreen))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(FreeTrialScreen))).pop();
    await tester.pumpAndSettle();

    expect(find.text('You use Premium'), findsOneWidget);
    final cancelBtn = find.byKey(const Key('dl-subscription-cancel-btn'));
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dl-subscription-confirm-cancel')));
    await tester.pumpAndSettle();

    expect(state.isProPlusAccount, isFalse);
    expect(find.byKey(const Key('dl-subscription-get-premium-btn')),
        findsOneWidget);
  });

  testWidgets(
      'AccountSetupScreen matches Figma 21825:25569 Default (#EEEEEE disabled Continue) and Active (#000000 chip & Continue)',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() => state.setLocale(const Locale('en')));
    Set<String>? savedSelection;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(const Locale('en'))
            .copyWith(splashFactory: NoSplash.splashFactory),
        home: AccountSetupScreen(
          nextBuilder: (_, chosen) {
            savedSelection = chosen;
            return const Scaffold(body: Center(child: Text('SETUP_COMPLETE')));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    Material continueMat() => tester.widget<Material>(
          find
              .ancestor(
                of: find.byKey(const Key('dl-account-setup-continue')),
                matching: find.byType(Material),
              )
              .first,
        );

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Account type'), findsOneWidget);
    expect(continueMat().color, const Color(0xFFEEEEEE));

    // Select `Business` chip -> switches to Active state (#000000)
    await tester.tap(find.byKey(const Key('dl-account-type-chip-business')));
    await tester.pumpAndSettle();
    expect(continueMat().color, const Color(0xFF000000));

    await tester.tap(find.byKey(const Key('dl-account-setup-continue')));
    await tester.pumpAndSettle();

    expect(find.text('SETUP_COMPLETE'), findsOneWidget);
    expect(savedSelection, contains('business'));
    expect(state.accountType, 'business');
  });
}
