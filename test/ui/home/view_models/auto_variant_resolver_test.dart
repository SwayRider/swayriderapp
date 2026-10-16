import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/map/map_style_mode.dart';
import 'package:swayriderapp/ui/home/view_models/auto_variant_resolver.dart';

void main() {
  late DateTime now;
  late AutoVariantResolver resolver;

  void advance(Duration d) => now = now.add(d);

  /// Feeds [lux] and evaluates, like the view model's timer does.
  bool tick(double lux, {Duration after = const Duration(seconds: 5)}) {
    resolver.addReading(lux);
    final changed = resolver.evaluate();
    advance(after);
    return changed;
  }

  setUp(() {
    now = DateTime(2026, 10, 16, 20);
    resolver = AutoVariantResolver(clock: () => now);
  });

  test('starts from the given variant and has no readings', () {
    expect(resolver.variant, MapVariant.light);
    expect(resolver.hasReadings, isFalse);
    expect(resolver.currentLux, isNull);
    expect(resolver.evaluate(), isFalse);
  });

  test('goes dark after two consecutive dark evaluations', () {
    expect(tick(3), isFalse); // first sighting
    expect(resolver.variant, MapVariant.light);
    expect(tick(3), isTrue); // confirmed
    expect(resolver.variant, MapVariant.dark);
  });

  test('a single dark reading among bright ones changes nothing', () {
    for (var i = 0; i < 6; i++) {
      tick(200);
    }
    resolver.addReading(2); // a hand over the sensor
    expect(resolver.evaluate(), isFalse);
    expect(resolver.variant, MapVariant.light);
  });

  test('uses the median of the window, not the last value', () {
    resolver.addReading(500);
    resolver.addReading(400);
    resolver.addReading(1); // outlier
    expect(resolver.currentLux, 400);
  });

  test('an even number of readings averages the middle two', () {
    resolver.addReading(10);
    resolver.addReading(30);
    expect(resolver.currentLux, 20);
  });

  test('hysteresis: between the thresholds the variant stays', () {
    tick(3);
    tick(3);
    expect(resolver.variant, MapVariant.dark);
    advance(const Duration(minutes: 5));
    // 20 lx is above the dark threshold (10) but below the light one (40).
    for (var i = 0; i < 6; i++) {
      expect(tick(20), isFalse);
    }
    expect(resolver.variant, MapVariant.dark);
  });

  test(
    'comes back to light above the upper threshold, after the dwell time',
    () {
      tick(3);
      tick(3);
      expect(resolver.variant, MapVariant.dark);

      // Bright again right away: confirmed, but still inside the dwell time.
      for (var i = 0; i < 4; i++) {
        expect(tick(500), isFalse, reason: 'inside the 60 s dwell time');
      }
      expect(resolver.variant, MapVariant.dark);

      advance(const Duration(seconds: 60));
      expect(tick(500), isTrue);
      expect(resolver.variant, MapVariant.light);
    },
  );

  test('the confirmation count restarts when the reading comes back', () {
    expect(tick(3), isFalse);
    // Back in the middle band before the second confirmation.
    advance(const Duration(seconds: 15)); // old readings leave the window
    expect(tick(25), isFalse);
    expect(tick(3), isFalse, reason: 'counting from one again');
    advance(const Duration(seconds: 15));
    expect(tick(3), isFalse);
    expect(tick(3), isTrue);
  });

  test('a steady room: the last reading still counts after the window', () {
    // The Android sensor reports on change, so a dark room can go quiet.
    resolver.addReading(2);
    advance(const Duration(minutes: 2));
    expect(resolver.currentLux, 2);
    expect(resolver.evaluate(), isFalse); // first confirmation
    expect(resolver.evaluate(), isTrue);
    expect(resolver.variant, MapVariant.dark);
  });

  test('old readings leave the window', () {
    resolver.addReading(1000);
    advance(const Duration(seconds: 11));
    resolver.addReading(100);
    expect(resolver.currentLux, 100);
  });

  test('ignores invalid readings', () {
    resolver.addReading(double.nan);
    resolver.addReading(double.infinity);
    resolver.addReading(-5);
    expect(resolver.hasReadings, isFalse);
  });

  test('reset starts over from the given variant without a dwell time', () {
    tick(3);
    tick(3);
    expect(resolver.variant, MapVariant.dark);
    resolver.reset(MapVariant.light);
    expect(resolver.variant, MapVariant.light);
    expect(resolver.hasReadings, isFalse);
    tick(3);
    expect(tick(3), isTrue, reason: 'no dwell time after a reset');
  });

  test('custom thresholds and confirmations', () {
    resolver = AutoVariantResolver(
      darkBelowLux: 50,
      lightAboveLux: 100,
      confirmations: 1,
      clock: () => now,
    );
    expect(tick(40), isTrue);
    expect(resolver.variant, MapVariant.dark);
  });
}
