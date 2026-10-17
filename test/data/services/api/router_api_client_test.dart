import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:swayriderapp/data/services/api/router_api_client.dart';
import 'package:swayriderapp/domain/models/route/route_plan.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/fake_http_client.dart';

String _encodeValue(int value) {
  var v = value < 0 ? ~(value << 1) : value << 1;
  final out = StringBuffer();
  while (v >= 0x20) {
    out.writeCharCode((0x20 | (v & 0x1f)) + 63);
    v >>= 5;
  }
  out.writeCharCode(v + 63);
  return out.toString();
}

/// Encodes [points] as a polyline6 string (the router's shape format).
String _encode(List<LatLng> points) {
  final out = StringBuffer();
  var lat = 0;
  var lng = 0;
  for (final p in points) {
    final nextLat = (p.latitude * 1e6).round();
    final nextLng = (p.longitude * 1e6).round();
    out
      ..write(_encodeValue(nextLat - lat))
      ..write(_encodeValue(nextLng - lng));
    lat = nextLat;
    lng = nextLng;
  }
  return out.toString();
}

Map<String, dynamic> _maneuver(
  int type,
  int begin,
  int end, {
  String? pre,
  double length = 0.5,
  int? exitCount,
}) => {
  'type': type,
  'instruction': 'instr $type',
  'begin_shape_index': begin,
  'end_shape_index': end,
  'length': length,
  'time': 30.0,
  'street_names': ['Main Street'],
  'verbal_pre_transition_instruction': ?pre,
  'roundabout_exit_count': ?exitCount,
};

FakeHttpClient _sseClient(Map<String, dynamic> trip) {
  final result = jsonEncode({
    'success': true,
    'data': {'trip': trip},
  });
  return FakeHttpClient(
    FakeHttpClientResponse(
      200,
      'event: queued\ndata: {}\n\nevent: result\ndata: $result\n\n',
    ),
  );
}

void main() {
  const a = LatLng(51.0, 4.0);
  const b = LatLng(51.001, 4.001);
  const c = LatLng(51.002, 4.002);
  const d = LatLng(51.003, 4.003);

  group('RouterApiClient.calculateRoute', () {
    test('merges legs, offsetting maneuver indices and dropping the join '
        'point', () async {
      final client = _sseClient({
        'language': 'nl-NL',
        'summary': {'length': 1.5, 'time': 120.0},
        'legs': [
          {
            'shape': _encode([a, b, c]),
            'maneuvers': [
              _maneuver(1, 0, 1, pre: 'Go'),
              _maneuver(15, 1, 2, pre: 'Turn left'),
            ],
          },
          {
            'shape': _encode([c, d]),
            'maneuvers': [_maneuver(10, 0, 1, pre: 'Turn right')],
          },
        ],
      });
      final api = RouterApiClient(clientFactory: () => client);

      final result = await api.calculateRoute(points: const [a, d]);

      final plan = (result as Ok<RoutePlan>).value;
      expect(plan.path, hasLength(4));
      expect(plan.path.last.latitude, closeTo(d.latitude, 1e-6));
      expect(plan.maneuvers.map((m) => m.beginShapeIndex), [0, 1, 2]);
      expect(plan.maneuvers.map((m) => m.endShapeIndex), [1, 2, 3]);
      expect(plan.maneuvers.last.verbalPre, 'Turn right');
      expect(plan.maneuvers.first.lengthMeters, 500);
      expect(plan.maneuvers.first.streetNames, ['Main Street']);
      expect(plan.distanceMeters, 1500);
      expect(plan.durationSeconds, 120);
      expect(plan.language, 'nl-NL');
      expect(plan.canNavigate, isTrue);
    });

    test('parses lanes, and leaves them empty when absent', () async {
      final client = _sseClient({
        'legs': [
          {
            'shape': _encode([a, b, c]),
            'maneuvers': [
              {
                ..._maneuver(10, 0, 1),
                'lanes': [
                  {'directions': 8, 'active': 8},
                  {'directions': 2, 'valid': 2},
                  {'directions': 64},
                ],
              },
              _maneuver(15, 1, 2),
            ],
          },
        ],
      });
      final api = RouterApiClient(clientFactory: () => client);

      final result = await api.calculateRoute(points: const [a, c]);

      final maneuvers = (result as Ok<RoutePlan>).value.maneuvers;
      final lanes = maneuvers.first.lanes;
      expect(lanes.map((l) => l.directions), [8, 2, 64]);
      expect(lanes.map((l) => l.isActive), [true, true, false]);
      expect(lanes.first.active, 8);
      expect(lanes[1].valid, 2);
      expect(maneuvers.last.lanes, isEmpty);
      expect(maneuvers.first.shifted(3).lanes, lanes);
    });

    group('roundabouts', () {
      List<LatLng> circle(double from, double to) => [
        for (var i = 0; i <= 6; i++)
          LatLng(
            51 + 0.0005 * math.sin(from + (to - from) * i / 6),
            4 + 0.0008 * math.cos(from + (to - from) * i / 6),
          ),
      ];

      Future<RoutePlan> planWith(List<LatLng> shape, int type) async {
        final client = _sseClient({
          'legs': [
            {
              'shape': _encode(shape),
              'maneuvers': [
                _maneuver(type, 0, shape.length - 1, exitCount: 2),
                _maneuver(27, shape.length - 1, shape.length - 1),
              ],
            },
          ],
        });
        final api = RouterApiClient(clientFactory: () => client);
        final result = await api.calculateRoute(
          points: [shape.first, shape.last],
        );
        return (result as Ok<RoutePlan>).value;
      }

      test('counter-clockwise means driving on the right', () async {
        expect((await planWith(circle(0, math.pi), 26)).drivesOnRight, isTrue);
      });

      test('clockwise means driving on the left', () async {
        expect((await planWith(circle(math.pi, 0), 26)).drivesOnRight, isFalse);
      });

      test('no roundabout defaults to the right', () async {
        expect((await planWith(circle(0, math.pi), 10)).drivesOnRight, isTrue);
      });

      test('leaving a roundabout takes the exit of the entry', () async {
        final plan = await planWith(circle(0, math.pi), 26);
        expect(plan.maneuvers[0].roundaboutExitCount, 2);
        expect(plan.maneuvers[1].roundaboutExitCount, 2);
      });
    });

    test('empty verbal strings become null', () async {
      final client = _sseClient({
        'legs': [
          {
            'shape': _encode([a, b]),
            'maneuvers': [
              {
                ..._maneuver(1, 0, 1),
                'verbal_transition_alert_instruction': '',
              },
            ],
          },
        ],
      });
      final api = RouterApiClient(clientFactory: () => client);

      final result = await api.calculateRoute(points: const [a, b]);

      final maneuver = (result as Ok<RoutePlan>).value.maneuvers.single;
      expect(maneuver.verbalAlert, isNull);
      expect(maneuver.verbalPre, isNull);
    });

    test(
      'falls back to the requested language when the response has none',
      () async {
        final client = _sseClient({
          'legs': [
            {
              'shape': _encode([a, b]),
              'maneuvers': [],
            },
          ],
        });
        final api = RouterApiClient(clientFactory: () => client);

        final result = await api.calculateRoute(
          points: const [a, b],
          language: 'nl-NL',
        );

        expect((result as Ok<RoutePlan>).value.language, 'nl-NL');
      },
    );

    test('sends language and km unit in the request body', () async {
      final client = _sseClient({
        'legs': [
          {
            'shape': _encode([a, b]),
            'maneuvers': [],
          },
        ],
      });
      final api = RouterApiClient(clientFactory: () => client);

      await api.calculateRoute(points: const [a, b], language: 'nl-NL');

      final body = jsonDecode(client.lastRequest!.bodyText) as Map;
      expect(body['language'], 'nl-NL');
      expect(body['unit'], 'km');
    });
  });

  test('routeLanguageFor maps nl to nl-NL and everything else to en-US', () {
    expect(routeLanguageFor('nl'), 'nl-NL');
    expect(routeLanguageFor('en'), 'en-US');
    expect(routeLanguageFor('fr'), 'en-US');
  });
}
