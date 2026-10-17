import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/utils/distance_format.dart';

void main() {
  test('rounds below 1 km to 10 m', () {
    expect(formatDistance(4), '0 m');
    expect(formatDistance(347), '350 m');
    expect(formatDistance(996), '1 km');
  });

  test('uses one decimal below 10 km and whole km above', () {
    expect(formatDistance(1234), '1.2 km');
    expect(formatDistance(9949), '9.9 km');
    expect(formatDistance(12400), '12 km');
  });

  test('uses a decimal comma for Dutch', () {
    expect(formatDistance(1234, languageCode: 'nl'), '1,2 km');
  });
}
