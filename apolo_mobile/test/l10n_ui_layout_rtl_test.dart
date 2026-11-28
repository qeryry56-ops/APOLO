import 'dart:convert';
import 'dart:typed_data';

import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/l10n/l10n.dart';
import 'package:apolo_mobile/screens/chat_room_screen.dart';
import 'package:apolo_mobile/screens/main_shell.dart';
import 'package:apolo_mobile/screens/post_ad_screen.dart';
import 'package:apolo_mobile/screens/search_screen.dart';
import 'package:apolo_mobile/screens/widgets/accommodation_card.dart';
import 'package:apolo_mobile/screens/widgets/ad_card.dart';
import 'package:apolo_mobile/screens/widgets/explore_listing_card.dart';
import 'package:apolo_mobile/widgets/chat_input.dart';
import 'package:apolo_mobile/widgets/chat_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubL10nHttpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    const sampleCategories = [
      {
        'id': 1,
        'name_ar': 'وسائل النقل',
        'name_fr': 'Véhicules',
        'name_en': 'Vehicles & Parts',
      },
      {
        'id': 4,
        'name_ar': 'هواتف وتقنية',
        'name_fr': 'Téléphones',
        'name_en': 'Phones & Electronics',
      },
    ];
    const sampleCities = [
      {
        'id': 1,
        'name_ar': 'الدار البيضاء',
        'name_fr': 'Casablanca',
        'name_en': 'Casablanca',
      },
      {
        'id': 2,
        'name_ar': 'الرباط',
        'name_fr': 'Rabat',
        'name_en': 'Rabat',
      },
    ];
    final sampleAds = List.generate(
      4,
      (i) => {
        'id': 900 + i,
        'title':
            'iPhone 16 Pro Max 512GB Natural Titanium — Official Warranty #$i',
        'price': 12900 + i * 500,
        'price_formatted': '${12900 + i * 500} DH',
        'condition': i.isEven ? 'new' : 'like_new',
        'negotiable': i.isEven,
        'views_count': 80 + i,
        'category': sampleCategories[1],
        'city': sampleCities[0],
        'images': ['assets/images/cat_other.png'],
      },
    );
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'success',
        'data': sampleAds,
        'categories': sampleCategories,
        'cities': sampleCities,
        'vip_ads': sampleAds,
        'featured_ads': const [],
        'latest_ads': sampleAds,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _buildLocalizedApp({
  required Locale locale,
  required Widget home,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

Future<void> _prepareTestEnv(
  WidgetTester tester, {
  required Locale locale,
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  await state.initialize(loadRemote: false);
  final prevAdapter = state.api.dio.httpClientAdapter;
  state.api.dio.httpClientAdapter = _StubL10nHttpAdapter();
  await tester.runAsync(() => state.setLocale(locale));

  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    state.api.dio.httpClientAdapter = prevAdapter;
    await tester.runAsync(() => state.setLocale(const Locale('en')));
  });
}

void main() {
  const targetLocales = <Locale>[
    Locale('de'), // Longest compound strings
    Locale('ar'), // RTL layout mirroring
    Locale('ja'), // Dense CJK typography
  ];

  group('Product cards localization & overflow resilience (de, ar, ja)', () {
    for (final locale in targetLocales) {
      testWidgets(
        'AdCard (vertical & horizontal), ExploreListingCard, and AccommodationCard fit without overflow in ${locale.languageCode}',
        (tester) async {
          await _prepareTestEnv(
            tester,
            locale: locale,
            size: const Size(360, 900),
          );

          final longAd = <String, dynamic>{
            'id': 8801,
            'title':
                'iPhone 16 Pro Max 512GB Natural Titanium — Original Packaging & Official Warranty Included',
            'price': 18990000,
            'price_formatted': '18 990 000 DH',
            'is_vip': true,
            'is_negotiable': true,
            'negotiable': true,
            'city': {
              'name_ar': 'الدار البيضاء الكبرى - عين الذئاب',
              'name_fr': 'Casablanca - Aïn Diab Corniche',
              'name_en': 'Casablanca - Ain Diab Corniche District',
            },
            'category': {
              'id': 4,
              'name_ar': 'هواتف ذكية وأجهزة إلكترونية متطورة',
              'name_fr': 'Téléphones & Électronique',
              'name_en': 'Smartphones, Tablets & Electronics',
            },
            'seller_name': 'Maximilian von Hohenzollern-Sigmaringen',
            'images': ['assets/images/cat_other.png'],
          };

          await tester.pumpWidget(
            _buildLocalizedApp(
              locale: locale,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 256,
                        child: Row(
                          children: [
                            Expanded(child: AdCard(ad: longAd)),
                            const SizedBox(width: 10),
                            Expanded(child: AdCard(ad: longAd)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AdCard(ad: longAd, horizontal: true),
                      const SizedBox(height: 12),
                      ExploreListingCard(ad: longAd),
                      const SizedBox(height: 12),
                      AccommodationCard(ad: longAd),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);

          // Verify product titles allow up to 2 lines with ellipsis
          final titleTexts = tester
              .widgetList<Text>(
                find.textContaining('iPhone 16 Pro Max 512GB'),
              )
              .toList();
          expect(titleTexts, isNotEmpty);
          for (final t in titleTexts) {
            expect(t.maxLines, 2);
            expect(t.overflow, TextOverflow.ellipsis);
          }

          if (locale.languageCode == 'ar') {
            final dir = Directionality.of(
              tester.element(find.byType(ExploreListingCard)),
            );
            expect(dir, TextDirection.rtl);
          }
        },
      );
    }
  });

  group('Filter chips & SearchScreen localization (de, ar, ja)', () {
    for (final locale in targetLocales) {
      testWidgets(
        'Category, Price, Condition, and Location chips & filter modal render cleanly in ${locale.languageCode}',
        (tester) async {
          await _prepareTestEnv(tester, locale: locale);

          await tester.pumpWidget(
            _buildLocalizedApp(
              locale: locale,
              home: const SearchScreen(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);

          expect(
            find.byKey(const Key('explore-quick-chip-category')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('explore-quick-chip-price')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('explore-quick-chip-condition')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('explore-quick-chip-location')),
            findsOneWidget,
          );

          if (locale.languageCode == 'ar') {
            final dir = Directionality.of(
              tester.element(find.byKey(const Key('dl-explore-screen'))),
            );
            expect(dir, TextDirection.rtl);
          }

          // Open filter sheet via Condition quick chip
          final condChip = find.byKey(const Key('explore-quick-chip-condition'));
          await tester.ensureVisible(condChip);
          await tester.pump();
          await tester.tap(condChip);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Chat screen bubbles, composer & RTL mirroring (de, ar, ja)', () {
    for (final locale in targetLocales) {
      testWidgets(
        'ChatMessage bubbles, ChatInput, and ChatRoomScreen fit and mirror cleanly in ${locale.languageCode}',
        (tester) async {
          await _prepareTestEnv(tester, locale: locale);

          final inputCtrl = TextEditingController();
          addTearDown(inputCtrl.dispose);

          await tester.pumpWidget(
            _buildLocalizedApp(
              locale: locale,
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: const [
                          ChatMessage(
                            messageKey: 'msg-incoming',
                            body: 'Hallo!',
                            isMine: false,
                            senderName: 'Käufer',
                            timestamp: '14:22',
                          ),
                          ChatMessage(
                            messageKey: 'msg-outgoing',
                            body: 'نعم متوفر!',
                            isMine: true,
                            hideAvatarGutter: true,
                            senderName: 'Me',
                            timestamp: '14:23',
                            isEdited: true,
                            deliveryLabel: 'Delivered',
                          ),
                          ChatMessage(
                            messageKey: 'msg-long',
                            body:
                                'Hallo! Ist dieser Artikel noch verfügbar, originalverpackt und verhandelbar bei Abholung heute?',
                            isMine: false,
                            senderName: 'Käufer',
                            timestamp: '14:24',
                          ),
                        ],
                      ),
                    ),
                    ChatInput(controller: inputCtrl),
                  ],
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(tester.takeException(), isNull);

          final incomingDx = tester
              .getCenter(find.byKey(const Key('chat-bubble-msg-incoming')))
              .dx;
          final outgoingDx = tester
              .getCenter(find.byKey(const Key('chat-bubble-msg-outgoing')))
              .dx;
          final attachDx = tester
              .getCenter(find.byKey(const Key('chat-attach-button')))
              .dx;
          final inputCapsuleDx = tester
              .getCenter(find.byKey(const Key('chat-input-capsule')))
              .dx;

          if (locale.languageCode == 'ar') {
            // In RTL: start is on the right (higher dx), end is on the left (lower dx)
            expect(incomingDx, greaterThan(outgoingDx));
            expect(attachDx, greaterThan(inputCapsuleDx));
          } else {
            // In LTR: start is on the left (lower dx), end is on the right (higher dx)
            expect(incomingDx, lessThan(outgoingDx));
            expect(attachDx, lessThan(inputCapsuleDx));
          }

          // Also pump full ChatRoomScreen with ad context banner
          await tester.pumpWidget(
            _buildLocalizedApp(
              locale: locale,
              home: const ChatRoomScreen(
                conversationId: 777,
                peerName: 'Youssef El Mansouri',
                adTitle:
                    'MacBook Pro 16 M3 Max 64GB RAM — Wie neu mit Originalverpackung',
                adPrice: '32 500 DH',
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Sell flow (PostAdScreen) across all 4 steps (de, ar, ja)', () {
    for (final locale in targetLocales) {
      testWidgets(
        'Add Photos, Title, Description, Price & Publish button render cleanly in ${locale.languageCode}',
        (tester) async {
          await _prepareTestEnv(tester, locale: locale);

          final seedAd = <String, dynamic>{
            'id': 501,
            'category_id': 1,
            'city_id': 1,
            'title': 'Mercedes-Benz C220d AMG Line 2023 Top Zustand',
            'description':
                'Scheckheftgepflegt, erste Hand, Panoramadach und volle Garantie inklusive.',
            'price': 385000,
            'negotiable': true,
            'images': ['https://example.com/photo1.jpg'],
          };

          await tester.pumpWidget(
            _buildLocalizedApp(
              locale: locale,
              home: PostAdScreen(initialAd: seedAd),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);

          if (locale.languageCode == 'ar') {
            final dir = Directionality.of(
              tester.element(find.byKey(const Key('post-ad-continue-btn'))),
            );
            expect(dir, TextDirection.rtl);
          }

          // Advance Step 1 -> Step 2 (Add Photos)
          await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull);

          // Advance Step 2 -> Step 3 (Title & Description)
          await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('post-ad-title-field')), findsOneWidget);
          expect(find.byKey(const Key('post-ad-desc-field')), findsOneWidget);

          // Advance Step 3 -> Step 4 (Price, Preview & Publish / Save button)
          await tester.tap(find.byKey(const Key('post-ad-continue-btn')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('post-ad-price-field')), findsOneWidget);
          expect(find.byKey(const Key('post-ad-continue-btn')), findsOneWidget);
        },
      );
    }
  });

  group('Bottom navigation (MainShell) localization & RTL mirroring (de, ar, ja)', () {
    for (final locale in targetLocales) {
      testWidgets(
        'MainShell bottom dock flips tab order and "+" button properly in ${locale.languageCode}',
        (tester) async {
          await _prepareTestEnv(tester, locale: locale);

          await tester.pumpWidget(
            _buildLocalizedApp(
              locale: locale,
              home: const MainShell(),
            ),
          );
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);

          final homeTabDx = tester
              .getCenter(find.byKey(const Key('main-shell-tab-0')))
              .dx;
          final profileTabDx = tester
              .getCenter(find.byKey(const Key('main-shell-tab-4')))
              .dx;
          final postAdBtnDx = tester
              .getCenter(find.byKey(const Key('main-shell-post-ad-btn')))
              .dx;

          if (locale.languageCode == 'ar') {
            // RTL: Home tab is at far right (start), Profile tab to its left, "+" button at far left (end)
            expect(homeTabDx, greaterThan(profileTabDx));
            expect(profileTabDx, greaterThan(postAdBtnDx));
          } else {
            // LTR: Home tab is at far left (start), Profile tab to its right, "+" button at far right (end)
            expect(homeTabDx, lessThan(profileTabDx));
            expect(profileTabDx, lessThan(postAdBtnDx));
          }
        },
      );
    }
  });
}
