import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/navigation/announcer.dart';
import 'package:swayriderapp/domain/navigation/spoken_distance.dart';

RouteManeuver maneuver(int type, {String? alert, String? pre, String? post}) =>
    RouteManeuver(
      type: type,
      instruction: 'instr',
      beginShapeIndex: 0,
      endShapeIndex: 0,
      verbalAlert: alert,
      verbalPre: pre,
      verbalPost: post,
    );

void main() {
  // depart at 0 m, turn left at 2000 m, turn right at 2200 m, arrive 4000 m.
  Announcer build({String language = 'en-US'}) => Announcer(
    language: language,
    maneuvers: [
      maneuver(2, pre: 'Drive north.'),
      maneuver(
        15,
        alert: 'Turn left.',
        pre: 'Turn left onto A.',
        post: 'Go on.',
      ),
      maneuver(
        10,
        alert: 'Turn right.',
        pre: 'Turn right onto B.',
        post: 'Long.',
      ),
      maneuver(4, pre: 'You have arrived.'),
    ],
    maneuverDistances: [0, 2000, 2200, 4000],
  );

  test('speaks the start instruction once', () {
    final a = build();
    expect(a.update(alongMeters: 0, speedMps: 0)?.text, 'Drive north.');
    expect(a.update(alongMeters: 5, speedMps: 0), isNull);
  });

  test('stays quiet far from the next maneuver', () {
    final a = build();
    a.update(alongMeters: 0, speedMps: 20);
    expect(a.update(alongMeters: 500, speedMps: 20), isNull);
  });

  test('alert comes first with a distance prefix, then pre once', () {
    final a = build();
    a.update(alongMeters: 0, speedMps: 20);

    // 20 m/s => alert at 600 m, pre at 160 m.
    final alert = a.update(alongMeters: 1450, speedMps: 20);
    expect(alert?.text, 'In 550 meters, turn left.');
    expect(a.update(alongMeters: 1500, speedMps: 20), isNull);

    final pre = a.update(alongMeters: 1850, speedMps: 20);
    expect(pre?.text, 'Turn left onto A.');
    expect(a.update(alongMeters: 1900, speedMps: 20), isNull);
  });

  test('Dutch alerts use the Dutch prefix', () {
    final a = build(language: 'nl-NL');
    a.update(alongMeters: 0, speedMps: 20);
    expect(
      a.update(alongMeters: 1450, speedMps: 20)?.text,
      'Over 550 meter, turn left.',
    );
  });

  test('skips the alert when the previous stretch is too short', () {
    final a = build();
    a.update(alongMeters: 0, speedMps: 20);
    a.update(alongMeters: 1850, speedMps: 20); // pre of turn 1
    // Turn 2 is only 200 m after turn 1: no alert, straight to pre.
    expect(a.update(alongMeters: 2010, speedMps: 20), isNull);
    expect(
      a.update(alongMeters: 2100, speedMps: 20)?.text,
      'Turn right onto B.',
    );
  });

  test('post instruction only when the next maneuver is far enough', () {
    final a = build();
    // 10 m/s => alert at 300 m, pre at 80 m.
    a.update(alongMeters: 0, speedMps: 10);
    a.update(alongMeters: 1930, speedMps: 10); // pre of turn 1
    // Passed turn 1 but turn 2 is < 300 m away: post is dropped and the
    // alert for turn 2 is skipped (too little room).
    expect(a.update(alongMeters: 2040, speedMps: 10), isNull);

    a.update(alongMeters: 2130, speedMps: 10); // pre of turn 2
    final post = a.update(alongMeters: 2240, speedMps: 10);
    expect(post?.text, 'Long.');
  });

  test('a GPS jump only returns the most relevant phrase', () {
    final a = build();
    final u = a.update(alongMeters: 1900, speedMps: 20);
    expect(u?.text, 'Turn left onto A.');
    // The start prompt was swallowed along the way.
    expect(a.update(alongMeters: 1905, speedMps: 20), isNull);
  });

  test('arrival is announced within 50 m and flagged', () {
    final a = build();
    a.update(alongMeters: 3000, speedMps: 20);
    final u = a.update(alongMeters: 3960, speedMps: 5);
    expect(u?.text, 'You have arrived.');
    expect(u?.isArrival, isTrue);
  });

  test('spokenDistance rounds naturally', () {
    expect(spokenDistance(120, 'en-US'), '100 meters');
    expect(spokenDistance(480, 'nl-NL'), '500 meter');
    expect(spokenDistance(990, 'en-US'), '1 kilometer');
    expect(spokenDistance(1500, 'en-US'), '1.5 kilometer');
    expect(spokenDistance(1500, 'nl-NL'), '1,5 kilometer');
    expect(spokenDistance(12400, 'en-US'), '12 kilometer');
  });
}
