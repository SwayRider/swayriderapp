import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/map/map_style_mode.dart';
import 'package:swayriderapp/ui/home/view_models/auto_variant_resolver.dart';

void main() {
  late DateTime now;
  late AutoVariantResolver resolver;

  const ms = Duration(milliseconds: 1);

  void advance(Duration d) => now = now.add(d);

  /// Lets [span] pass, evaluating every 100 ms like the view model's timer, and
  /// returns how long it took until the variant changed (null if it did not).
  Duration? runFor(
    Duration span, {
    Duration step = const Duration(milliseconds: 100),
  }) {
    var elapsed = Duration.zero;
    while (elapsed < span) {
      advance(step);
      elapsed += step;
      if (resolver.evaluate()) return elapsed;
    }
    return null;
  }

  /// Daylight for a while, so the smoothed level has settled on it.
  void settleAt(double lux, {Duration span = const Duration(seconds: 6)}) {
    resolver.addReading(lux);
    runFor(span);
  }

  setUp(() {
    now = DateTime(2026, 10, 16, 14);
    resolver = AutoVariantResolver(clock: () => now);
  });

  test('starts from the given variant and has no readings', () {
    expect(resolver.variant, MapVariant.light);
    expect(resolver.hasReadings, isFalse);
    expect(resolver.currentLux, isNull);
    expect(resolver.evaluate(), isFalse);
  });

  test('the first reading is taken as it is, no ramp from nothing', () {
    resolver.addReading(80);
    expect(resolver.currentLux, closeTo(80, 0.001));
  });

  test('a dark first reading switches after the debounce, not before', () {
    resolver.addReading(20);
    expect(resolver.evaluate(), isFalse, reason: 'debounce not over yet');
    advance(const Duration(milliseconds: 499));
    expect(resolver.evaluate(), isFalse);
    advance(ms);
    expect(resolver.evaluate(), isTrue);
    expect(resolver.variant, MapVariant.dark);
  });

  group('tunnel', () {
    test(
      'entering from daylight goes dark within about a second and a half',
      () {
        settleAt(10000);
        expect(resolver.variant, MapVariant.light);

        resolver.addReading(5); // the tunnel mouth
        final took = runFor(const Duration(seconds: 5));

        expect(took, isNotNull);
        expect(took!, lessThan(const Duration(milliseconds: 1600)));
        expect(resolver.variant, MapVariant.dark);
      },
    );

    test('leaving it goes light again within two seconds', () {
      settleAt(10000);
      resolver.addReading(5);
      runFor(const Duration(seconds: 5)); // dark inside
      expect(resolver.variant, MapVariant.dark);
      runFor(const Duration(seconds: 6)); // a few seconds inside

      resolver.addReading(10000); // out again
      final took = runFor(const Duration(seconds: 5));

      expect(took, isNotNull);
      expect(took!, lessThan(const Duration(seconds: 2)));
      expect(resolver.variant, MapVariant.light);
    });

    test('a lit tunnel of 80 lx counts as dark', () {
      settleAt(10000);
      resolver.addReading(80);
      expect(runFor(const Duration(seconds: 5)), isNotNull);
      expect(resolver.variant, MapVariant.dark);
    });

    test('a short tunnel of six seconds is followed on both ends', () {
      settleAt(10000);
      resolver.addReading(5);
      expect(runFor(const Duration(seconds: 6)), isNotNull); // dark
      resolver.addReading(10000);
      expect(runFor(const Duration(seconds: 6)), isNotNull); // light again
      expect(resolver.variant, MapVariant.light);
    });
  });

  group('not too jumpy', () {
    test('a shadow of 300 ms does not switch the map', () {
      settleAt(10000);
      resolver.addReading(5);
      expect(runFor(const Duration(milliseconds: 300)), isNull);
      resolver.addReading(10000);
      expect(runFor(const Duration(seconds: 5)), isNull);
      expect(resolver.variant, MapVariant.light);
    });

    test('hysteresis: 300 lx is neither dark enough nor bright enough', () {
      settleAt(10000);
      resolver.addReading(300);
      expect(
        runFor(const Duration(seconds: 10)),
        isNull,
        reason: 'light stays',
      );

      resolver.addReading(5);
      runFor(const Duration(seconds: 5));
      expect(resolver.variant, MapVariant.dark);
      runFor(const Duration(seconds: 6));
      resolver.addReading(300);
      expect(runFor(const Duration(seconds: 10)), isNull, reason: 'dark stays');
      expect(resolver.variant, MapVariant.dark);
    });

    test('a bright petrol station canopy at night (700 lx) stays dark', () {
      settleAt(10000);
      resolver.addReading(5);
      runFor(const Duration(seconds: 5));
      expect(resolver.variant, MapVariant.dark);
      runFor(const Duration(seconds: 6));

      resolver.addReading(700);
      expect(runFor(const Duration(seconds: 15)), isNull);
      expect(resolver.variant, MapVariant.dark);
    });

    test('overcast daylight (3000 lx) is enough to go light again', () {
      settleAt(10000);
      resolver.addReading(5);
      runFor(const Duration(seconds: 5));
      runFor(const Duration(seconds: 6));

      resolver.addReading(3000);
      expect(runFor(const Duration(seconds: 5)), isNotNull);
      expect(resolver.variant, MapVariant.light);
    });

    test('the thresholds are 150 lx (dark) and 1000 lx (light)', () {
      final defaults = AutoVariantResolver();
      expect(defaults.darkBelowLux, 150);
      expect(defaults.lightAboveLux, 1000);
    });

    test('the debounce restarts when the level comes back', () {
      settleAt(10000);
      resolver.addReading(5);
      runFor(
        const Duration(milliseconds: 900),
      ); // crossed, but not yet 500 ms ...
      resolver.addReading(10000); // ... recovers
      runFor(const Duration(seconds: 4));
      expect(resolver.variant, MapVariant.light);
    });

    test('after a switch it stays put for the calm period', () {
      settleAt(10000);
      resolver.addReading(5);
      runFor(const Duration(seconds: 5));
      expect(resolver.variant, MapVariant.dark);

      // Bright again almost at once: held back by the 5 s calm period.
      resolver.addReading(10000);
      final took = runFor(const Duration(seconds: 10));
      expect(took, isNotNull);
      expect(took!, greaterThanOrEqualTo(const Duration(milliseconds: 3000)));
      expect(resolver.variant, MapVariant.light);
    });
  });

  test(
    'a steady dark room needs no new events (the sensor reports on change)',
    () {
      resolver.addReading(2);
      advance(const Duration(minutes: 2));
      expect(resolver.currentLux, closeTo(2, 0.01));
      expect(resolver.evaluate(), isFalse); // starts the debounce
      advance(const Duration(milliseconds: 500));
      expect(resolver.evaluate(), isTrue);
      expect(resolver.variant, MapVariant.dark);
    },
  );

  test('the smoothed level approaches the reading over about a second', () {
    resolver.addReading(10000);
    resolver.addReading(0);
    advance(const Duration(seconds: 1));
    // log10 level 4 -> 0 with time constant 1 s: after 1 s about 1.47 -> ~28 lx
    expect(resolver.currentLux, inInclusiveRange(20, 40));
    advance(const Duration(seconds: 5));
    expect(resolver.currentLux, lessThan(1));
  });

  test('a burst of events (dragging the emulator slider) is not a problem', () {
    settleAt(10000);
    for (var lux = 10000.0; lux > 5; lux *= 0.9) {
      resolver.addReading(lux);
      advance(const Duration(milliseconds: 11));
      resolver.evaluate();
    }
    resolver.addReading(0);
    expect(runFor(const Duration(seconds: 3)), isNotNull);
    expect(resolver.variant, MapVariant.dark);
  });

  test('ignores invalid readings', () {
    resolver.addReading(double.nan);
    resolver.addReading(double.infinity);
    resolver.addReading(-5);
    expect(resolver.hasReadings, isFalse);
  });

  test('reset starts over from the given variant', () {
    resolver.addReading(5);
    runFor(const Duration(seconds: 2));
    expect(resolver.variant, MapVariant.dark);
    resolver.reset(MapVariant.light);
    expect(resolver.variant, MapVariant.light);
    expect(resolver.hasReadings, isFalse);
    resolver.addReading(5);
    expect(
      runFor(const Duration(seconds: 2)),
      isNotNull,
      reason: 'no calm period',
    );
  });

  test('custom thresholds and timings', () {
    resolver = AutoVariantResolver(
      darkBelowLux: 1000,
      lightAboveLux: 2000,
      confirm: Duration.zero,
      clock: () => now,
    );
    resolver.addReading(900);
    expect(resolver.evaluate(), isTrue);
    expect(resolver.variant, MapVariant.dark);
  });
}
