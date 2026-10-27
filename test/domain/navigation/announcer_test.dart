import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/route/route_lane.dart';
import 'package:swayriderapp/domain/models/route/route_maneuver.dart';
import 'package:swayriderapp/domain/navigation/announcer.dart';
import 'package:swayriderapp/domain/navigation/prompt_phrases.dart';
import 'package:swayriderapp/domain/navigation/spoken_distance.dart';

RouteManeuver maneuver(
  int type, {
  String? alert,
  String? pre,
  String? post,
  List<RouteLane> lanes = const [],
}) => RouteManeuver(
  type: type,
  instruction: 'instr',
  beginShapeIndex: 0,
  endShapeIndex: 0,
  verbalAlert: alert,
  verbalPre: pre,
  verbalPost: post,
  lanes: lanes,
);

List<String> texts(List<Utterance> u) => [for (final x in u) x.text];

/// The route from `test/fixtures/route_olmen_leuven.json`.
class FixtureRoute {
  FixtureRoute._(this.json);

  factory FixtureRoute.load() => FixtureRoute._(
    jsonDecode(File('test/fixtures/route_olmen_leuven.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  final Map<String, dynamic> json;

  List<Map<String, dynamic>> get raw =>
      (json['maneuvers'] as List).cast<Map<String, dynamic>>();

  double get total => (json['total'] as num).toDouble();

  double distance(int i) => (raw[i]['distance'] as num).toDouble();

  Announcer announcer() => Announcer(
    language: json['language'] as String,
    maneuvers: [
      for (final m in raw)
        RouteManeuver(
          type: m['type'] as int,
          instruction: m['instruction'] as String,
          beginShapeIndex: 0,
          endShapeIndex: 0,
          verbalAlert: m['alert'] as String?,
          verbalPre: m['pre'] as String?,
          verbalPost: m['post'] as String?,
          lanes: [
            for (final l in m['lanes'] as List)
              RouteLane(
                directions: (l as Map)['directions'] as int,
                valid: l['valid'] as int?,
                active: l['active'] as int?,
              ),
          ],
        ),
    ],
    maneuverDistances: [for (var i = 0; i < raw.length; i++) distance(i)],
  );
}

/// What is said where, when the rider follows [speedAt] (m/s by position),
/// with one fix per second.
List<({double along, double toNext, String text})> ride(
  FixtureRoute route,
  double Function(double along) speedAt, {
  double from = 0,
  double? to,
}) {
  final a = route.announcer();
  final said = <({double along, double toNext, String text})>[];
  var along = from;
  final end = to ?? route.total;
  while (along <= end) {
    final speed = speedAt(along);
    final next = [
      for (var i = 0; i < route.raw.length; i++)
        if (route.distance(i) > along) route.distance(i) - along,
    ];
    for (final u in a.update(alongMeters: along, speedMps: speed)) {
      said.add((
        along: along,
        toNext: next.isEmpty ? 0 : next.first,
        text: u.text,
      ));
    }
    along += speed < 1 ? 1 : speed;
  }
  return said;
}

void main() {
  // depart at 0 m, turn left at 2000 m, turn right at 3000 m, arrive 5000 m.
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
    maneuverDistances: [0, 2000, 3000, 5000],
  );

  test('speaks the start instruction once', () {
    final a = build();
    expect(texts(a.update(alongMeters: 0, speedMps: 0)), ['Drive north.']);
    expect(a.update(alongMeters: 5, speedMps: 0), isEmpty);
  });

  test('stays quiet far from the next maneuver', () {
    final a = build();
    a.update(alongMeters: 0, speedMps: 20);
    expect(a.update(alongMeters: 500, speedMps: 20), isEmpty);
  });

  test('alert comes first with a distance prefix, then pre once', () {
    final a = build();
    a.update(alongMeters: 0, speedMps: 20);

    // 20 m/s => alert at 600 m, pre at 160 m.
    final alert = a.update(alongMeters: 1450, speedMps: 20);
    expect(texts(alert), ['In 550 meters, Turn left.']);
    expect(alert.single.validUntilMeters, 2000);
    expect(a.update(alongMeters: 1500, speedMps: 20), isEmpty);

    final pre = a.update(alongMeters: 1850, speedMps: 20);
    expect(texts(pre), ['Turn left.']);
    expect(pre.single.isPre, isTrue);
    expect(alert.single.isPre, isFalse);
    expect(a.update(alongMeters: 1900, speedMps: 20), isEmpty);
  });

  test('Dutch alerts use the Dutch prefix', () {
    final a = build(language: 'nl-NL');
    a.update(alongMeters: 0, speedMps: 20);
    expect(texts(a.update(alongMeters: 1450, speedMps: 20)), [
      'Over 550 meter, Turn left.',
    ]);
  });

  test('a maneuver right behind another is chained, not dropped', () {
    final a = Announcer(
      language: 'en-US',
      maneuvers: [
        maneuver(2, pre: 'Drive.'),
        maneuver(15, alert: 'Turn left.', pre: 'Turn left onto A.'),
        maneuver(10, alert: 'Turn right.', pre: 'Turn right onto B.'),
        maneuver(4, pre: 'Arrived.'),
      ],
      maneuverDistances: [0, 2000, 2300, 4000],
    );
    a.update(alongMeters: 0, speedMps: 20);

    expect(texts(a.update(alongMeters: 1400, speedMps: 20)), [
      'In 600 meters, Turn left. Then: Turn right.',
    ]);
    // The second maneuver's alert is covered by the chain...
    expect(a.update(alongMeters: 1700, speedMps: 20), isEmpty);
    // ...but both still get their own pre prompt.
    expect(texts(a.update(alongMeters: 1850, speedMps: 20)), ['Turn left.']);
    expect(texts(a.update(alongMeters: 2150, speedMps: 20)), ['Turn right.']);
  });

  test('a pre prompt is not chained and waits for the maneuver before it', () {
    final a = Announcer(
      language: 'en-US',
      maneuvers: [
        maneuver(2, pre: 'Drive.'),
        maneuver(15, pre: 'Turn left onto A.'),
        maneuver(10, pre: 'Turn right onto B.'),
        maneuver(4, pre: 'Arrived.'),
      ],
      maneuverDistances: [0, 2000, 2100, 4000],
    );
    a.update(alongMeters: 0, speedMps: 20);
    expect(texts(a.update(alongMeters: 1850, speedMps: 20)), [
      'Turn left onto A.',
    ]);
    // The second one is due (150 m ahead) but the first is still ahead.
    expect(a.update(alongMeters: 1950, speedMps: 20), isEmpty);
    expect(texts(a.update(alongMeters: 2010, speedMps: 20)), [
      'Turn right onto B.',
    ]);
  });

  test('post instruction only when the next maneuver is far enough', () {
    final a = Announcer(
      language: 'en-US',
      maneuvers: [
        maneuver(2, pre: 'Drive.'),
        maneuver(15, pre: 'Left.', post: 'Go on.'),
        maneuver(10, pre: 'Right.', post: 'Long.'),
        maneuver(4, pre: 'Arrived.'),
      ],
      maneuverDistances: [0, 2000, 2200, 4000],
    );
    a.update(alongMeters: 0, speedMps: 10);
    a.update(alongMeters: 1930, speedMps: 10); // pre of the left turn
    // Passed the left turn, but the right one is < 300 m away: no post, the
    // right turn's own alert is not skipped either.
    expect(texts(a.update(alongMeters: 2040, speedMps: 10)), [
      'In 150 meters, Right.',
    ]);

    final post = a.update(alongMeters: 2240, speedMps: 10);
    expect(texts(post), ['Long.']);
    expect(post.single.validUntilMeters, 4000);
  });

  test('a GPS jump drops the outdated start phrase', () {
    final a = build();
    expect(texts(a.update(alongMeters: 1900, speedMps: 20)), ['Turn left.']);
    expect(a.update(alongMeters: 1905, speedMps: 20), isEmpty);
  });

  test('arrival is announced within 50 m and flagged', () {
    final a = build();
    a.update(alongMeters: 3000, speedMps: 20);
    final u = a.update(alongMeters: 4960, speedMps: 5);
    expect(texts(u), ['You have arrived.']);
    expect(u.single.isArrival, isTrue);
    expect(u.single.isPre, isTrue);
  });

  group('arrival', () {
    Announcer home({double turnAt = 2000}) => Announcer(
      language: 'en-US',
      maneuvers: [
        maneuver(2, pre: 'Drive.'),
        maneuver(15, alert: 'Turn left.', pre: 'Turn left onto A.'),
        maneuver(
          6,
          alert: 'Your destination is on the left.',
          pre: 'Your destination is on the left.',
        ),
      ],
      maneuverDistances: [0, turnAt, 5000],
    );

    test('is announced 500 m ahead, then again within 50 m', () {
      final a = home();
      a.update(alongMeters: 0, speedMps: 20);
      a.update(alongMeters: 2100, speedMps: 20); // past the turn

      expect(a.update(alongMeters: 4400, speedMps: 20), isEmpty);
      final early = a.update(alongMeters: 4500, speedMps: 20);
      expect(texts(early), ['In 500 meters, Your destination is on the left.']);
      expect(early.single.isArrival, isFalse);
      expect(a.update(alongMeters: 4600, speedMps: 20), isEmpty);

      final last = a.update(alongMeters: 4960, speedMps: 5);
      expect(texts(last), ['Your destination is on the left.']);
      expect(last.single.isArrival, isTrue);
    });

    test('a slow rider hears it from 250 m', () {
      final a = home();
      a.update(alongMeters: 0, speedMps: 5);
      a.update(alongMeters: 2100, speedMps: 5);

      expect(a.update(alongMeters: 4700, speedMps: 5), isEmpty);
      expect(texts(a.update(alongMeters: 4750, speedMps: 5)), [
        'In 250 meters, Your destination is on the left.',
      ]);
    });

    test('is not announced twice when the first fix is already close', () {
      final a = home();
      expect(texts(a.update(alongMeters: 4970, speedMps: 5)), [
        'Your destination is on the left.',
      ]);
      expect(a.update(alongMeters: 4980, speedMps: 5), isEmpty);
    });

    test('a last turn right before it is chained, not announced twice', () {
      final a = home(turnAt: 4800);
      a.update(alongMeters: 0, speedMps: 20);

      expect(texts(a.update(alongMeters: 4200, speedMps: 20)), [
        'In 600 meters, Turn left. Then: Your destination is on the left.',
      ]);
      // The destination's own early announcement is covered by the chain.
      expect(a.update(alongMeters: 4510, speedMps: 20), isEmpty);
    });
  });

  test('a replacement route does not announce the departure again', () {
    final a = Announcer(
      language: 'en-US',
      speakDeparture: false,
      maneuvers: [
        maneuver(2, pre: 'Drive north.'),
        maneuver(15, alert: 'Turn left.', pre: 'Turn left onto A.'),
        maneuver(4, pre: 'Arrived.'),
      ],
      maneuverDistances: [0, 2000, 4000],
    );
    expect(a.update(alongMeters: 0, speedMps: 0), isEmpty);
    a.update(alongMeters: 0, speedMps: 20);
    expect(texts(a.update(alongMeters: 1850, speedMps: 20)), ['Turn left.']);
  });

  test('keeps the capital of street names', () {
    final a = Announcer(
      language: 'nl-NL',
      maneuvers: [
        maneuver(2, pre: 'Rij.'),
        maneuver(26, alert: 'Joanna-Maria Artoisplein opgaan.'),
        maneuver(4, pre: 'Aangekomen.'),
      ],
      maneuverDistances: [0, 2000, 4000],
    );
    a.update(alongMeters: 0, speedMps: 20);
    expect(texts(a.update(alongMeters: 1450, speedMps: 20)), [
      'Over 550 meter, Joanna-Maria Artoisplein opgaan.',
    ]);
  });

  group('highway exits', () {
    // 33 m/s ~ 120 km/h on a long motorway stretch.
    Announcer motorway() => Announcer(
      language: 'nl-NL',
      maneuvers: [
        maneuver(2, pre: 'Rij.'),
        maneuver(
          20,
          alert: 'Afslag nemen.',
          pre: 'Afslag Knooppunt Lummen nemen naar E314.',
        ),
        maneuver(4, pre: 'Aangekomen.'),
      ],
      maneuverDistances: [0, 20000, 30000],
    );

    test('warn about 4 km ahead with the descriptive text', () {
      final a = motorway();
      a.update(alongMeters: 0, speedMps: 33);
      expect(a.update(alongMeters: 15000, speedMps: 33), isEmpty);
      final far = a.update(alongMeters: 16100, speedMps: 33);
      expect(texts(far), [
        'Over 4 kilometer, Afslag Knooppunt Lummen nemen naar E314.',
      ]);
      expect(far.single.isPre, isFalse);
    });

    test('then alert at about 2 km and pre at about 500 m', () {
      final a = motorway();
      a.update(alongMeters: 0, speedMps: 33);
      a.update(alongMeters: 16100, speedMps: 33);
      expect(a.update(alongMeters: 17000, speedMps: 33), isEmpty);
      expect(texts(a.update(alongMeters: 18100, speedMps: 33)), [
        'Over 2 kilometer, Afslag Knooppunt Lummen nemen naar E314.',
      ]);
      expect(a.update(alongMeters: 19400, speedMps: 33), isEmpty);
      final pre = a.update(alongMeters: 19510, speedMps: 33);
      // A motorway exit says where it leads.
      expect(texts(pre), ['Afslag Knooppunt Lummen nemen naar E314.']);
      expect(pre.single.isPre, isTrue);
    });

    test('the pre prompt of a turn is only the short instruction', () {
      final a = Announcer(
        language: 'nl-NL',
        maneuvers: [
          maneuver(2, pre: 'Rij.'),
          maneuver(
            10,
            alert: 'Rechts afslaan.',
            pre: 'Rechts afslaan naar Dorpsstraat richting Leuven.',
          ),
          maneuver(4, pre: 'Aangekomen.'),
        ],
        maneuverDistances: [0, 20000, 30000],
      );
      a.update(alongMeters: 0, speedMps: 33);
      a.update(alongMeters: 19200, speedMps: 33); // the alert
      expect(texts(a.update(alongMeters: 19760, speedMps: 33)), [
        'Rechts afslaan.',
      ]);
    });

    /// Distance to the exit at which its pre prompt is spoken when riding
    /// at [kmh], one fix every 5 m.
    double preDistance(double kmh) {
      final a = motorway();
      for (var along = 0.0; along < 20000; along += 5) {
        for (final u in a.update(alongMeters: along, speedMps: kmh / 3.6)) {
          if (u.isPre) return 20000 - along;
        }
      }
      fail('no pre prompt at $kmh km/h');
    }

    test('the pre prompt comes at least 12 s ahead at 118 km/h', () {
      expect(preDistance(118) / (118 / 3.6), greaterThanOrEqualTo(12));
      expect(preDistance(118), lessThanOrEqualTo(500));
    });

    test('the pre prompt distance scales with the speed', () {
      expect(preDistance(80), inInclusiveRange(325, 340));
      expect(preDistance(100), inInclusiveRange(410, 425));
      expect(preDistance(118), inInclusiveRange(485, 500));
      expect(preDistance(160), inInclusiveRange(495, 500));
    });

    test('are not warned about early when riding slowly', () {
      final a = motorway();
      a.update(alongMeters: 0, speedMps: 12);
      expect(a.update(alongMeters: 18000, speedMps: 12), isEmpty);
    });

    test('braking for the exit does not pull the warnings closer', () {
      final a = motorway();
      for (var i = 0; i < 5; i++) {
        a.update(alongMeters: 15000.0 + i * 30, speedMps: 33);
      }
      // 90 km/h on the exit, but the cruise speed is still remembered.
      expect(a.update(alongMeters: 16300, speedMps: 25), isNotEmpty);
    });

    test('the pre prompt of a close exit waits for the junction before it', () {
      final a = Announcer(
        language: 'nl-NL',
        maneuvers: [
          maneuver(2, pre: 'Rij.'),
          maneuver(20, alert: 'Knooppunt.', pre: 'Knooppunt lang.'),
          maneuver(20, alert: 'Afslag.', pre: 'Afslag lang.'),
          maneuver(4, pre: 'Aangekomen.'),
        ],
        // The exit is 422 m behind the junction: its 500 m pre prompt would
        // come before the junction otherwise.
        maneuverDistances: [0, 20000, 20422, 30000],
      );
      final said = <({double along, Utterance u})>[];
      for (var along = 0.0; along < 20600; along += 33) {
        for (final u in a.update(alongMeters: along, speedMps: 33)) {
          said.add((along: along, u: u));
        }
      }
      final junction = said.where(
        (s) => s.u.isPre && s.u.text == 'Knooppunt lang.',
      );
      expect(junction, hasLength(1));
      final exit = said.where((s) => s.u.isPre && s.u.text == 'Afslag lang.');
      expect(exit, hasLength(1));
      expect(exit.single.along, greaterThanOrEqualTo(20000));
      // The far warning is the junction alone; its alert carries the exit.
      final spoken = [
        for (final s in said)
          if (s.u.text.contains('Knooppunt lang.')) s.u.text,
      ];
      expect(spoken.first, 'Over 4 kilometer, Knooppunt lang.');
      expect(spoken[1], endsWith('Daarna: Afslag.'));
    });
  });

  group('lane guidance and slowing down', () {
    final threeLanes = [
      const RouteLane(directions: RouteLane.left, active: RouteLane.left),
      const RouteLane(directions: RouteLane.left, active: RouteLane.left),
      const RouteLane(directions: RouteLane.right),
    ];

    Announcer withLanes() => Announcer(
      language: 'nl-NL',
      maneuvers: [
        maneuver(2, pre: 'Rij.'),
        maneuver(
          15,
          alert: 'Links afslaan.',
          pre: 'Links afslaan richting Leuven.',
          lanes: threeLanes,
        ),
        maneuver(4, pre: 'Aangekomen.'),
      ],
      maneuverDistances: [0, 5000, 8000],
    );

    test('the pre prompt names the lanes', () {
      final a = withLanes();
      a.update(alongMeters: 0, speedMps: 20);
      final alert = a.update(alongMeters: 4400, speedMps: 20);
      expect(texts(alert), [
        'Over 600 meter, Links afslaan. Gebruik de linker twee rijstroken',
      ]);
      expect(texts(a.update(alongMeters: 4850, speedMps: 20)), [
        'Links afslaan. Gebruik de linker twee rijstroken',
      ]);
    });

    test(
      'the alert of a turn is the short text, the lanes, then the chain',
      () {
        final a = Announcer(
          language: 'nl-NL',
          maneuvers: [
            maneuver(2, pre: 'Rij.'),
            maneuver(
              15,
              alert: 'Links afslaan.',
              pre: 'Links afslaan. Daarna rechts.',
              lanes: threeLanes,
            ),
            maneuver(10, alert: 'Rechts afslaan.', pre: 'Rechts afslaan.'),
            maneuver(4, pre: 'Aangekomen.'),
          ],
          maneuverDistances: [0, 5000, 5300, 8000],
        );
        a.update(alongMeters: 0, speedMps: 20);
        expect(texts(a.update(alongMeters: 4400, speedMps: 20)), [
          'Over 600 meter, Links afslaan. Gebruik de linker twee rijstroken. '
              'Daarna: Rechts afslaan.',
        ]);
        // The pre prompt is the short text and the lanes, without the chain.
        expect(texts(a.update(alongMeters: 4850, speedMps: 20)), [
          'Links afslaan. Gebruik de linker twee rijstroken',
        ]);
      },
    );

    test('the alert of a motorway exit is the full text, lanes, then the '
        'chained move', () {
      final a = Announcer(
        language: 'nl-NL',
        maneuvers: [
          maneuver(2, pre: 'Rij.'),
          maneuver(
            20,
            alert: 'Afslag 18 nemen.',
            pre: 'Afslag 18 nemen naar N26 richting Leuven.',
            lanes: threeLanes,
          ),
          maneuver(15, alert: 'Links afslaan.', pre: 'Links afslaan lang.'),
          maneuver(4, pre: 'Aangekomen.'),
        ],
        maneuverDistances: [0, 20000, 20400, 30000],
      );
      a.update(alongMeters: 0, speedMps: 33);
      a.update(alongMeters: 16100, speedMps: 33); // the far warning
      expect(texts(a.update(alongMeters: 18100, speedMps: 33)), [
        'Over 2 kilometer, Afslag 18 nemen naar N26 richting Leuven. '
            'Gebruik de linker twee rijstroken. Daarna: Links afslaan.',
      ]);
      // The pre prompt: the same full text and the lanes, no chain.
      expect(texts(a.update(alongMeters: 19510, speedMps: 33)), [
        'Afslag 18 nemen naar N26 richting Leuven. '
            'Gebruik de linker twee rijstroken',
      ]);
    });

    test('a standing rider still hears the pre prompt 150 m ahead', () {
      final a = withLanes();
      a.update(alongMeters: 0, speedMps: 0);
      expect(a.update(alongMeters: 4800, speedMps: 0), isNotEmpty);
    });

    test('laneHint: single lane, all lanes and odd selections are silent', () {
      const lane = RouteLane(directions: 2, active: 2);
      expect(laneHint(const [lane], 'nl-NL'), isNull);
      expect(laneHint(const [lane, lane], 'nl-NL'), isNull);
      expect(
        laneHint(const [lane, RouteLane(directions: 2), lane], 'nl-NL'),
        isNull,
      );
      expect(laneHint(const [RouteLane(directions: 2)], 'nl-NL'), isNull);
    });

    test('laneHint: left, right and middle in both languages', () {
      const on = RouteLane(directions: 2, active: 2);
      const off = RouteLane(directions: 2);
      expect(
        laneHint(const [on, off, off], 'nl-NL'),
        'Gebruik de linkerrijstrook',
      );
      expect(
        laneHint(const [off, on, on], 'nl-NL'),
        'Gebruik de rechter twee rijstroken',
      );
      expect(laneHint(const [off, on, off], 'en-US'), 'Use the middle lane');
      expect(laneHint(const [on, on, off], 'en-US'), 'Use the left two lanes');
    });
  });

  group('the Olmen - Leuven ride', () {
    final route = FixtureRoute.load();

    // 120 km/h on the motorways, 90 km/h through the interchange.
    double motorwaySpeed(double along) {
      if (along > 19000 && along < 21000) return 25;
      return along > 7900 && along < 62000 ? 33.3 : 20;
    }

    test('warns about Knooppunt Lummen about 4 km ahead, the alert chains '
        'the second move', () {
      final said = ride(route, motorwaySpeed);
      final lummen = said.where((s) => s.text.contains('Lummen')).toList();
      expect(lummen.first.toNext, inInclusiveRange(3800, 4100));
      expect(lummen.first.text, startsWith('Over 4 kilometer'));
      expect(lummen.first.text, isNot(contains('Rechts aanhouden')));
      expect(lummen[1].text, contains('Rechts aanhouden om E314 op te gaan'));
    });

    test('exit 18 is announced about 4 km ahead, the alert has the left turn '
        'behind it', () {
      final said = ride(route, motorwaySpeed);
      final exit18 = said.where((s) => s.text.contains('Afslag 18')).toList();
      expect(exit18.first.toNext, inInclusiveRange(3800, 4100));
      expect(exit18.first.text, isNot(contains('Links afslaan')));
      expect(exit18[1].text, contains('Links afslaan richting Leuven-Centrum'));
    });

    test('every maneuver is covered at every steady speed', () {
      for (final kmh in [30.0, 50.0, 70.0, 90.0, 120.0]) {
        final said = ride(route, (_) => kmh / 3.6);
        for (var i = 1; i < route.raw.length; i++) {
          final m = route.raw[i];
          // The short text, or on the motorway the full one.
          final highway = (m['type'] as int) >= 17 && m['type'] <= 25;
          final spoken =
              ((highway ? m['pre'] : m['alert']) ?? m['pre']) as String?;
          // Leaving a roundabout is covered by the prompt for entering it.
          if (spoken == null || m['type'] == 27) continue;
          final i0 = said.indexWhere((s) => s.text.contains(spoken));
          expect(
            i0,
            isNonNegative,
            reason: '$kmh km/h: "$spoken" is never said',
          );
          expect(
            said[i0].along,
            lessThanOrEqualTo(route.distance(i)),
            reason: '$kmh km/h: "$spoken" came too late',
          );
        }
      }
    });

    test('braking from 100 km/h to a standstill at the light, the left turn '
        'still gets its pre prompt with lanes in time', () {
      final turn = route.distance(10); // left towards Leuven-Centrum
      double speed(double along) {
        final left = turn - along;
        if (left > 400) return 27.8;
        return (left / 400 * 27.8).clamp(0.0, 27.8);
      }

      final said = ride(route, speed, from: turn - 2500, to: turn);
      // The alert names the lanes too; the last mention is the pre prompt.
      final pre = said.lastWhere(
        (s) => s.text.contains('Gebruik de linker twee rijstroken'),
      );
      // 150 m is the floor; the fix before the threshold can overshoot it
      // by one step (about 10 m/s here). The old 40 m floor said it at
      // the very last moment.
      expect(pre.toNext, greaterThanOrEqualTo(130));
    });
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
