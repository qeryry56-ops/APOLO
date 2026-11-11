import 'package:apolo_mobile/account/account_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Arabic contact numbers normalize without reversing digits', () {
    expect(AccountValidation.phone('٠٦١٢٣٤٥٦٧٨'), '+212612345678');
    expect(AccountValidation.phone('۰۰۲۱۲۶۱۲۳۴۵۶۷۸'), '+212612345678');
    expect(AccountValidation.phone('abc12345678'), isNull);
  });
}
