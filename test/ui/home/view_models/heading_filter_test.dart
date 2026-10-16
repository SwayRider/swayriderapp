import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/ui/home/view_models/heading_filter.dart';

/// The shortest angle between two bearings.
double _diff(double a, double b) {
  final d = ((a - b) % 360 + 360) % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  late DateTime now;
  late HeadingFilter filter;

  void advance(Duration d) => now = now.add(d);

  /// Feeds [heading] at 30 Hz for [span], stepping every 100 ms like the app
  /// does, and returns every bearing the filter emitted.
  List<double> run(
    double Function(int i) heading,
    Duration span, {
    double? accuracy,
  }) {
    final out = <double>[];
    final samples = span.inMilliseconds ~/ 33;
    for (var i = 0; i < samples; i++) {
      filter.addCompass(heading(i), accuracy: accuracy);
      advance(const Duration(milliseconds: 33));
      if (i % 3 == 2) {
        final b = filter.step();
        if (b != null) out.add(b);
      }
    }
    return out;
  }

  setUp(() {
    now = DateTime(2026, 10, 16, 14);
    filter = HeadingFilter(clock: () => now);
  });

  test('nothing to show before the first reading', () {
    expect(filter.step(), isNull);
    expect(filter.bearing, isNull);
    expect(filter.compassUnreliable, isFalse);
  });

  test('the first reading is shown as it is', () {
    filter.addCompass(123);
    expect(filter.step(), closeTo(123, 1e-9));
    expect(filter.bearing, closeTo(123, 1e-9));
  });

  test('headings outside 0-360 are folded (Android reports -180..180)', () {
    filter.addCompass(-90);
    expect(filter.step(), closeTo(270, 1e-9));
  });

  test('invalid readings are ignored', () {
    filter.addCompass(double.nan);
    filter.addCompass(double.infinity);
    expect(filter.step(), isNull);
  });

  group('circular averaging', () {
    test('359 and 1 degrees average to north, not south', () {
      final out = run((i) => i.isEven ? 359 : 1, const Duration(seconds: 2));
      expect(out, isNotEmpty);
      for (final b in out) {
        expect(_diff(b, 0), lessThan(3), reason: '$b');
      }
    });

    test('a turn through north never swings through south', () {
      // turn from 350 up through 0 to 20
      final out = run((i) => (350 + i * 0.4) % 360, const Duration(seconds: 3));
      for (var i = 1; i < out.length; i++) {
        expect(_diff(out[i], out[i - 1]), lessThan(20), reason: 'step $i');
      }
    });
  });

  group('jitter', () {
    test('a still device with ±8 degrees of noise shows a still map', () {
      final rng = math.Random(7);
      double noisy(int i) => 100 + (rng.nextDouble() * 16 - 8);

      // the first second may settle, then the map must stay put
      final settling = run(noisy, const Duration(seconds: 2));
      for (final b in settling) {
        expect(_diff(b, 100), lessThan(6), reason: '$b');
      }
      final later = run(noisy, const Duration(seconds: 20));
      expect(
        later,
        isEmpty,
        reason: 'a device lying still must not turn the map',
      );
    });

    test('small drifts below the dead band do not move the map', () {
      filter.addCompass(90);
      expect(filter.step(), isNotNull);
      advance(const Duration(seconds: 2));
      filter.addCompass(91.5);
      advance(const Duration(seconds: 1));
      expect(filter.step(), isNull);
    });

    test('a real turn is followed until it has arrived', () {
      filter.addCompass(90);
      filter.step();
      final out = run((_) => 150, const Duration(seconds: 4));
      expect(out, isNotEmpty);
      // it stops inside the dead band (3 degrees) of the heading
      expect(_diff(out.last, 150), lessThanOrEqualTo(3));
    });
  });

  test('the turning speed is limited', () {
    filter.addCompass(0);
    filter.step();
    var previous = 0.0;
    var worst = 0.0;
    for (var i = 0; i < 40; i++) {
      filter.addCompass(180); // a sudden half turn
      advance(const Duration(milliseconds: 100));
      final b = filter.step();
      if (b != null) {
        worst = math.max(worst, _diff(b, previous));
        previous = b;
      }
    }
    expect(worst, lessThanOrEqualTo(12.0 + 1e-6)); // 120 deg/s * 0.1 s
    expect(previous, greaterThan(60));
  });

  group('accuracy', () {
    test('readings with 45 degrees or worse are ignored', () {
      filter.addCompass(90, accuracy: 15);
      filter.step();
      advance(const Duration(seconds: 1));
      final out = run((_) => 200, const Duration(seconds: 2), accuracy: 45);
      expect(out, isEmpty);
      expect(filter.bearing, closeTo(90, 1e-9));
    });

    test('unknown accuracy (null) is accepted', () {
      filter.addCompass(40, accuracy: null);
      expect(filter.step(), closeTo(40, 1e-9));
    });

    test('compassUnreliable turns on after a few seconds of bad readings', () {
      filter.addCompass(90, accuracy: 15);
      filter.addCompass(95, accuracy: 45);
      expect(filter.compassUnreliable, isFalse);
      advance(const Duration(seconds: 2));
      filter.addCompass(95, accuracy: 45);
      expect(filter.compassUnreliable, isFalse);
      advance(const Duration(seconds: 2));
      expect(filter.compassUnreliable, isTrue);
    });

    test('a good reading clears it', () {
      filter.addCompass(95, accuracy: 45);
      advance(const Duration(seconds: 4));
      expect(filter.compassUnreliable, isTrue);
      filter.addCompass(95, accuracy: 15);
      expect(filter.compassUnreliable, isFalse);
    });

    test('medium accuracy (30) is smoothed more slowly than high (15)', () {
      double afterHalfSecond(double accuracy) {
        final f = HeadingFilter(clock: () => now);
        f.addCompass(0, accuracy: accuracy);
        f.step();
        final t0 = now;
        // 50 degrees to the side, within the limits of the dead band logic
        for (var i = 0; i < 15; i++) {
          f.addCompass(50, accuracy: accuracy);
          advance(const Duration(milliseconds: 33));
          f.step();
        }
        final shown = f.bearing!;
        now = t0;
        return shown;
      }

      final fast = afterHalfSecond(15);
      final slow = afterHalfSecond(30);
      expect(slow, lessThan(fast));
    });
  });

  group('GPS course', () {
    test('takes over above 3 m/s and ignores the compass', () {
      filter.addCompass(90);
      filter.step();

      for (var i = 0; i < 30; i++) {
        filter.addCourse(270, 8);
        filter.addCompass(90); // the disturbed compass keeps saying 90
        advance(const Duration(milliseconds: 100));
        filter.step();
      }

      expect(filter.usingCourse, isTrue);
      expect(_diff(filter.bearing!, 270), lessThan(5));
    });

    test(
      'hysteresis: stays on the course until the speed falls below 1.5 m/s',
      () {
        filter.addCourse(270, 5);
        expect(filter.usingCourse, isTrue);
        filter.addCourse(270, 2.0); // slower than entering, faster than leaving
        expect(filter.usingCourse, isTrue);
        filter.addCourse(270, 1.0);
        expect(filter.usingCourse, isFalse);
        filter.addCourse(270, 2.0); // not fast enough to enter again
        expect(filter.usingCourse, isFalse);
      },
    );

    test('back to the compass when it stops', () {
      filter.addCourse(270, 6);
      for (var i = 0; i < 10; i++) {
        filter.addCourse(270, 6);
        advance(const Duration(milliseconds: 100));
        filter.step();
      }
      filter.addCourse(270, 0.2);
      expect(filter.usingCourse, isFalse);
      final out = run((_) => 180, const Duration(seconds: 5));
      expect(out, isNotEmpty);
      expect(_diff(out.last, 180), lessThanOrEqualTo(3));
    });

    test('an unknown course (-1) is ignored', () {
      filter.addCompass(40);
      filter.step();
      filter.addCourse(-1, 8);
      advance(const Duration(seconds: 1));
      expect(filter.step(), isNull);
    });

    test('a bad compass does not count against us while the course drives', () {
      filter.addCourse(100, 8);
      filter.addCompass(10, accuracy: 45);
      advance(const Duration(seconds: 5));
      expect(filter.compassUnreliable, isFalse);
    });
  });

  test('without new readings the bearing just holds', () {
    filter.addCompass(75);
    filter.step();
    advance(const Duration(minutes: 5));
    expect(filter.step(), isNull);
    expect(filter.bearing, closeTo(75, 1e-9));
  });

  test('reset forgets everything', () {
    filter.addCompass(75);
    filter.step();
    filter.reset();
    expect(filter.bearing, isNull);
    expect(filter.step(), isNull);
    filter.addCompass(10);
    expect(filter.step(), closeTo(10, 1e-9));
  });
}
