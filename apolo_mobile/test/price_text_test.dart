import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:apolo_mobile/screens/ad_reels_screen.dart';
import 'package:apolo_mobile/core/state/app_state.dart';
import 'package:apolo_mobile/screens/widgets/ad_card.dart';
import 'package:apolo_mobile/screens/widgets/price_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child, TextDirection direction, {double scale = 1}) {
  return MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

class _ReelsAdapter implements HttpClientAdapter {
  final String response;
  _ReelsAdapter(this.response);

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    return ResponseBody.fromString(response, 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState().initialize(loadRemote: false);
    AppState().currentUser = null;
    AppState().favoriteAdIds.clear();
    AppState().api.dio.httpClientAdapter =
        _ReelsAdapter('{"status":"success","categories":[],"cities":[]}');
  });

  for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
    for (final price in [
      '1 234 567 890 DH',
      '1 234 567 890,50 MAD',
      '١٢٣٬٤٥٦٬٧٨٩ د.م'
    ]) {
      for (final width in [80.0, 150.0, 280.0]) {
        testWidgets('$direction price $price fits $width', (tester) async {
          await tester.pumpWidget(_app(
            SizedBox(
                width: width,
                child: PriceText(price,
                    style: const TextStyle(
                        fontSize: 31, fontWeight: FontWeight.w900))),
            direction,
            scale: 2,
          ));
          expect(tester.takeException(), isNull);
          final text = tester.widget<Text>(find.text(price));
          expect(text.textDirection, TextDirection.ltr);
          expect(text.data, price);
          final paragraph =
              tester.renderObject<RenderParagraph>(find.text(price));
          expect(paragraph.didExceedMaxLines, isFalse);
          final fit =
              tester.renderObject<RenderFittedBox>(find.byType(FittedBox));
          expect(fit.size.width, lessThanOrEqualTo(width));
          expect(tester.widget<FittedBox>(find.byType(FittedBox)).fit,
              BoxFit.scaleDown);
          final align = tester.widget<Align>(find.descendant(
              of: find.byType(PriceText), matching: find.byType(Align)));
          expect(
              align.alignment,
              direction == TextDirection.rtl
                  ? Alignment.centerRight
                  : Alignment.centerLeft);
        });
      }
    }
  }

  testWidgets('Arabic non-numeric price labels retain RTL direction',
      (tester) async {
    await tester.pumpWidget(_app(
      const PriceText('الثمن عند الطلب'),
      TextDirection.rtl,
    ));
    expect(tester.widget<Text>(find.text('الثمن عند الطلب')).textDirection,
        TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['ar', 'fr']) {
    for (final horizontal in [true, false]) {
      testWidgets(
          '$language compact card uses isolated untruncated price ($horizontal)',
          (tester) async {
        if (language == 'fr') {
          await tester.runAsync(() => AppState().toggleLanguage());
        }
        const price = '1 234 567 890 DH';
        await tester.pumpWidget(_app(
          SizedBox(
            width: horizontal ? 288 : 142,
            height: horizontal ? 126 : 260,
            child: AdCard(horizontal: horizontal, ad: {
              'id': 999,
              'title': language == 'ar'
                  ? 'إعلان بعنوان طويل جداً لاختبار العرض الضيق'
                  : 'Une annonce avec un titre très long pour mobile',
              'price_formatted': price,
              'negotiable': true,
              'category_name': '',
              'city_name': '',
            }),
          ),
          language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        ));
        await tester.pump();
        expect(find.byType(PriceText), findsOneWidget);
        expect(tester.widget<Text>(find.text(price)).textDirection,
            TextDirection.ltr);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('reels empty success is not a network error', (tester) async {
    final dio = AppState().api.dio;
    final original = dio.httpClientAdapter;
    dio.httpClientAdapter = _ReelsAdapter('{"status":"success","data":[]}');
    addTearDown(() => dio.httpClientAdapter = original);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(const AdReelsScreen(), TextDirection.rtl));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد إعلانات في هذا التبويب'), findsOneWidget);
    expect(find.text('تعذر تحميل الإعلانات'), findsNothing);
    expect(find.byIcon(Icons.volume_up), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reels malformed response shows retry, not empty',
      (tester) async {
    final dio = AppState().api.dio;
    final original = dio.httpClientAdapter;
    dio.httpClientAdapter = _ReelsAdapter('{"status":"error"}');
    addTearDown(() => dio.httpClientAdapter = original);
    await tester.pumpWidget(_app(const AdReelsScreen(), TextDirection.rtl));
    await tester.pumpAndSettle();
    expect(find.text('تعذر تحميل الإعلانات'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    dio.httpClientAdapter = _ReelsAdapter('{"status":"success","data":[]}');
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد إعلانات في هذا التبويب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
