import 'dart:math' as math;

import '../models/route/route_maneuver.dart';
import 'spoken_distance.dart';

/// A phrase to be spoken.
class Utterance {
  const Utterance(this.text, {this.isArrival = false});

  final String text;
  final bool isArrival;
}

/// Decides when each maneuver's spoken instructions are due.
///
/// Per maneuver, at most once each: an advance *alert* well ahead, the
/// *pre*-transition instruction shortly before the maneuver, and a
/// *post*-transition instruction ("continue for 5 km") after it. The
/// distances scale with speed so the rider always gets a similar amount of
/// time to react.
class Announcer {
  Announcer({
    required this.maneuvers,
    required this.maneuverDistances,
    required this.language,
  }) : _alertDone = List.filled(maneuvers.length, false),
       _preDone = List.filled(maneuvers.length, false),
       _postDone = List.filled(maneuvers.length, false);

  final List<RouteManeuver> maneuvers;

  /// Distance from the route start to each maneuver, parallel to
  /// [maneuvers].
  final List<double> maneuverDistances;

  /// Valhalla language of the verbal instructions, used for the distance
  /// prefix of advance alerts.
  final String language;

  final List<bool> _alertDone;
  final List<bool> _preDone;
  final List<bool> _postDone;

  static const _alertSeconds = 30.0;
  static const _preSeconds = 8.0;
  static const _minAlertMeters = 300.0;
  static const _maxAlertMeters = 1500.0;
  static const _minPreMeters = 40.0;
  static const _maxPreMeters = 250.0;
  static const _arrivalMeters = 50.0;
  static const _postAfterMeters = 30.0;

  /// A post-transition phrase is skipped when the next maneuver is closer
  /// than this, as it would collide with that maneuver's own prompts.
  static const _postMinNextMeters = 300.0;

  double _alertDistance(double speed) =>
      (speed * _alertSeconds).clamp(_minAlertMeters, _maxAlertMeters);
  double _preDistance(double speed) =>
      (speed * _preSeconds).clamp(_minPreMeters, _maxPreMeters);

  /// Returns the utterance due for the rider at [alongMeters] travelling at
  /// [speedMps], if any. Everything that is due is marked as spoken, but
  /// only the most relevant phrase is returned so prompts never queue up
  /// after a GPS gap.
  Utterance? update({required double alongMeters, required double speedMps}) {
    Utterance? pre;
    Utterance? alert;
    Utterance? post;
    final alertAt = _alertDistance(speedMps);
    final preAt = _preDistance(speedMps);

    for (var i = 0; i < maneuvers.length; i++) {
      final m = maneuvers[i];
      final toManeuver = maneuverDistances[i] - alongMeters;

      if (m.isStart) {
        if (!_preDone[i]) {
          _preDone[i] = true;
          _alertDone[i] = true;
          final text = m.verbalPre;
          if (text != null) pre ??= Utterance(text);
        }
        continue;
      }

      if (toManeuver > 0 || m.isArrival) {
        final preThreshold = m.isArrival ? _arrivalMeters : preAt;
        if (!_preDone[i] && toManeuver <= preThreshold) {
          _preDone[i] = true;
          _alertDone[i] = true;
          final text = m.verbalPre ?? m.instruction;
          pre = Utterance(text, isArrival: m.isArrival);
        } else if (!_alertDone[i] &&
            !m.isArrival &&
            toManeuver <= alertAt &&
            toManeuver > preAt) {
          _alertDone[i] = true;
          final text = m.verbalAlert ?? m.verbalPre;
          if (text != null && _hasRoomForAlert(i, alertAt)) {
            alert = Utterance(
              '${inDistancePrefix(toManeuver, language)}${_lower(text)}',
            );
          }
        }
        // Only the nearest upcoming maneuver is relevant.
        if (toManeuver > preAt && toManeuver > alertAt) break;
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
          post = Utterance(text);
        }
      }
      // Anything skipped over entirely is considered spoken.
      _preDone[i] = true;
      _alertDone[i] = true;
    }

    return pre ?? alert ?? post;
  }

  /// An advance alert only makes sense when the stretch before the maneuver
  /// is long enough that the alert doesn't land right on top of the previous
  /// maneuver's own prompts.
  bool _hasRoomForAlert(int index, double alertAt) {
    if (index == 0) return true;
    final stretch = maneuverDistances[index] - maneuverDistances[index - 1];
    return stretch >= math.max(alertAt * 1.2, _minAlertMeters);
  }

  static String _lower(String text) =>
      text.isEmpty ? text : text[0].toLowerCase() + text.substring(1);
}
