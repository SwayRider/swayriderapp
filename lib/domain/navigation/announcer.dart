import 'dart:math' as math;

import '../models/route/route_maneuver.dart';
import 'prompt_phrases.dart';
import 'spoken_distance.dart';

/// A phrase to be spoken.
class Utterance {
  const Utterance(
    this.text, {
    this.isArrival = false,
    this.isPre = false,
    this.validUntilMeters = double.infinity,
  });

  final String text;
  final bool isArrival;

  /// The last instruction before a maneuver. It has priority over every
  /// other prompt in the queue, as it is the one the rider cannot miss.
  final bool isPre;

  /// Distance along the route after which the phrase is stale (the position
  /// of the maneuver it announces) and should no longer be spoken.
  final double validUntilMeters;
}

/// Decides when each maneuver's spoken instructions are due.
///
/// Per maneuver, at most once each: a *far* warning (highway exits and
/// ramps only, up to 4 km ahead at motorway speed), an *alert* well ahead,
/// the *pre*-transition instruction shortly before the maneuver, and a
/// *post*-transition instruction ("continue for 5 km") after it.
///
/// Distances scale with the rider's *cruise* speed (the current speed or a
/// slowly decaying peak, whichever is higher) so braking for an exit or a
/// traffic light does not pull the prompts closer to the maneuver. A
/// maneuver that follows closely is chained onto the far and alert prompts
/// of the one before it ("Take the exit. Then: turn left"). The alert and
/// the pre prompt name the lanes to use when the road data has them. The
/// pre prompt has no chain, so it is over well before the maneuver: the
/// short text, or for motorway exits and ramps the text that names where
/// they lead. It waits until the maneuver before it has been passed.
class Announcer {
  Announcer({
    required this.maneuvers,
    required this.maneuverDistances,
    required this.language,
    this.speakDeparture = true,
  }) : _farDone = List.filled(maneuvers.length, false),
       _alertDone = List.filled(maneuvers.length, false),
       _preDone = List.filled(maneuvers.length, false),
       _postDone = List.filled(maneuvers.length, false);

  final List<RouteManeuver> maneuvers;

  /// Distance from the route start to each maneuver, parallel to
  /// [maneuvers].
  final List<double> maneuverDistances;

  /// Valhalla language of the verbal instructions, used for the distance
  /// prefix of advance alerts.
  final String language;

  /// Whether the start maneuver ("Head north on ...") is spoken. Off for a
  /// route that replaces one the rider was already following.
  final bool speakDeparture;

  final List<bool> _farDone;
  final List<bool> _alertDone;
  final List<bool> _preDone;
  final List<bool> _postDone;

  double _cruiseMps = 0;

  /// Per-fix decay of the remembered peak speed: about 20 s to fall to a
  /// third at 1 fix per second.
  static const _cruiseDecay = 0.95;

  static const _alertSeconds = 30.0;
  static const _preSeconds = 8.0;
  static const _minAlertMeters = 300.0;
  static const _maxAlertMeters = 1500.0;
  static const _minPreMeters = 120.0;
  static const _minPreMetersWithLanes = 150.0;
  static const _maxPreMeters = 250.0;
  static const _arrivalMeters = 50.0;

  /// The destination is announced ahead of time: about 30 s of travel,
  /// 250 to 500 m.
  static const _minArrivalAlertMeters = 250.0;
  static const _maxArrivalAlertMeters = 500.0;
  static const _postAfterMeters = 30.0;

  /// A post-transition phrase is skipped when the next maneuver is closer
  /// than this, as it would collide with that maneuver's own prompts.
  static const _postMinNextMeters = 300.0;

  /// Highway exits, ramps, stays and merges get an earlier, longer warning
  /// from this cruise speed (80 km/h) up.
  static const _highwayMinMps = 80 / 3.6;
  static const _farSeconds = 120.0;
  static const _minFarMeters = 1500.0;
  static const _maxFarMeters = 4000.0;
  static const _highwayAlertSeconds = 60.0;
  static const _minHighwayAlertMeters = 800.0;
  static const _maxHighwayAlertMeters = 2000.0;

  /// The pre prompt of a motorway maneuver is about 7 s of speech with the
  /// lanes, so it starts early enough to be over before the maneuver.
  static const _highwayPreSeconds = 15.0;
  static const _minHighwayPreMeters = 250.0;
  static const _maxHighwayPreMeters = 500.0;

  /// A maneuver closer than this to the one being announced is chained onto
  /// its prompt.
  static const _chainMeters = 500.0;

  /// Nothing is announced earlier than this, so scanning stops here.
  static const _lookAheadMeters = 4500.0;

  /// Leaving a roundabout is not announced: the prompt for entering it
  /// already names the exit to take.
  static bool _isSilent(RouteManeuver m) => m.type == 27;

  double? _farAt(RouteManeuver m) =>
      m.isHighwayType && _cruiseMps >= _highwayMinMps
      ? (_cruiseMps * _farSeconds).clamp(_minFarMeters, _maxFarMeters)
      : null;

  double _alertAt(RouteManeuver m) =>
      m.isHighwayType && _cruiseMps >= _highwayMinMps
      ? (_cruiseMps * _highwayAlertSeconds).clamp(
          _minHighwayAlertMeters,
          _maxHighwayAlertMeters,
        )
      : (_cruiseMps * _alertSeconds).clamp(_minAlertMeters, _maxAlertMeters);

  double _arrivalAlertAt() => (_cruiseMps * _alertSeconds).clamp(
    _minArrivalAlertMeters,
    _maxArrivalAlertMeters,
  );

  double _preAt(RouteManeuver m) =>
      m.isHighwayType && _cruiseMps >= _highwayMinMps
      ? (_cruiseMps * _highwayPreSeconds).clamp(
          _minHighwayPreMeters,
          _maxHighwayPreMeters,
        )
      : (_cruiseMps * _preSeconds).clamp(
          m.lanes.isEmpty ? _minPreMeters : _minPreMetersWithLanes,
          _maxPreMeters,
        );

  /// Returns the utterances due for the rider at [alongMeters] travelling
  /// at [speedMps], in the order they should be spoken. Everything due is
  /// marked as spoken; a maneuver the rider has skipped over entirely is
  /// considered spoken too.
  List<Utterance> update({
    required double alongMeters,
    required double speedMps,
  }) {
    _cruiseMps = math.max(speedMps, _cruiseMps * _cruiseDecay);
    final due = <Utterance>[];

    // True while an earlier maneuver is still ahead and has not had its pre
    // prompt, or was just announced: later maneuvers then stay quiet until their own pre prompt,
    // so "in 2 km, take the ramp" is not said while exit 18 is still to
    // come.
    var blocked = false;

    // True once an earlier maneuver that is still ahead has been seen: the
    // pre prompt of a later one then waits until that one has been passed.
    var priorAhead = false;

    for (var i = 0; i < maneuvers.length; i++) {
      final m = maneuvers[i];
      final toManeuver = maneuverDistances[i] - alongMeters;

      if (m.isStart) {
        if (!_preDone[i]) {
          _markAll(i);
          final text = m.verbalPre;
          if (text != null && speakDeparture) due.add(Utterance(text));
        }
        continue;
      }

      if (toManeuver > 0 || m.isArrival) {
        if (m.isArrival) {
          final alertAt = _arrivalAlertAt();
          if (!_preDone[i] && toManeuver <= _arrivalMeters) {
            _markAll(i);
            due.add(
              Utterance(
                m.verbalPre ?? m.instruction,
                isArrival: true,
                isPre: true,
              ),
            );
          } else if (!_alertDone[i] && !blocked && toManeuver <= alertAt) {
            // "In 500 meters, your destination is on the left."
            _alertDone[i] = true;
            final text = m.verbalAlert ?? m.verbalPre ?? m.instruction;
            due.add(
              Utterance('${inDistancePrefix(toManeuver, language)}$text'),
            );
          }
          continue;
        }
        if (toManeuver > _lookAheadMeters) break;
        if (_isSilent(m)) {
          _markAll(i);
          continue;
        }
        final utterance = _upcoming(
          i,
          toManeuver,
          early: !blocked,
          holdPre: priorAhead,
        );
        if (utterance != null) due.add(utterance);
        if (utterance != null || !_preDone[i]) blocked = true;
        priorAhead = true;
        continue;
      }

      // Maneuver already passed.
      if (!_postDone[i] && -toManeuver >= _postAfterMeters) {
        _postDone[i] = true;
        final text = m.verbalPost;
        final next = i + 1 < maneuvers.length
            ? maneuverDistances[i + 1] - alongMeters
            : double.infinity;
        if (text != null && next >= _postMinNextMeters) {
          due.add(
            Utterance(
              text,
              validUntilMeters: i + 1 < maneuvers.length
                  ? maneuverDistances[i + 1]
                  : double.infinity,
            ),
          );
        }
      }
      _markAll(i);
    }
    // After a GPS gap or a late first fix the start phrase is outdated as
    // soon as anything else is due.
    if (due.length > 1 && maneuvers.first.isStart) {
      due.removeWhere((u) => u.text == maneuvers.first.verbalPre);
    }
    return due;
  }

  /// The prompt now due for the not yet reached maneuver [i], if any. The
  /// pre prompt is held back while [holdPre] is set.
  Utterance? _upcoming(
    int i,
    double toManeuver, {
    required bool early,
    required bool holdPre,
  }) {
    final m = maneuvers[i];
    final far = _farAt(m);
    final alert = _alertAt(m);
    final pre = _preAt(m);

    if (!_preDone[i] && toManeuver <= pre) {
      if (holdPre) return null;
      _markAll(i);
      // A motorway exit or ramp says where it leads ("take exit 17 towards
      // Leuven"); every other maneuver is just the short instruction.
      final text = m.isHighwayType
          ? m.verbalPre ?? m.verbalAlert ?? m.instruction
          : m.verbalAlert ?? m.verbalPre ?? m.instruction;
      return Utterance(
        _withLanes(m, text),
        isPre: true,
        validUntilMeters: maneuverDistances[i],
      );
    }
    if (!early) return null;
    if (!_alertDone[i] && toManeuver <= alert && toManeuver > pre) {
      _alertDone[i] = true;
      _farDone[i] = true;
      final text = m.verbalAlert ?? m.verbalPre;
      if (text == null) return null;
      return Utterance(
        _chained(
          i,
          _withLanes(m, '${inDistancePrefix(toManeuver, language)}$text'),
        ),
        validUntilMeters: maneuverDistances[i],
      );
    }
    if (far != null &&
        !_farDone[i] &&
        toManeuver <= far &&
        toManeuver > alert) {
      _farDone[i] = true;
      final text = m.verbalPre ?? m.verbalAlert;
      if (text == null) return null;
      return Utterance(
        _chained(i, '${inDistancePrefix(toManeuver, language)}$text'),
        validUntilMeters: maneuverDistances[i],
      );
    }
    return null;
  }

  /// [text] followed by the lanes to use, when the road data has them.
  String _withLanes(RouteManeuver m, String text) {
    final hint = laneHint(m.lanes, language);
    return hint == null ? text : '${_stripPeriod(text)}. $hint';
  }

  /// Appends the maneuver after [i] to [text] when it follows closely, and
  /// marks its far and alert prompts as done so they are not repeated. Its
  /// pre prompt is still spoken.
  String _chained(int i, String text) {
    final j = i + 1;
    if (j >= maneuvers.length) return text;
    final next = maneuvers[j];
    final gap = maneuverDistances[j] - maneuverDistances[i];
    if (gap > _chainMeters) return text;
    if (_isSilent(next)) return text;
    final nextText = next.verbalAlert ?? next.verbalPre ?? next.instruction;
    if (nextText.isEmpty) return text;
    _farDone[j] = true;
    _alertDone[j] = true;
    return thenPhrase(text, nextText, language);
  }

  void _markAll(int i) {
    _farDone[i] = true;
    _alertDone[i] = true;
    _preDone[i] = true;
  }

  static String _stripPeriod(String text) =>
      text.endsWith('.') ? text.substring(0, text.length - 1) : text;
}
