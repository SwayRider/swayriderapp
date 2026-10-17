import '../models/route/route_lane.dart';

/// Small localized fragments used to build spoken prompts, in the route's
/// language (`nl-NL` or anything else = English), like [inDistancePrefix].
bool _dutch(String language) => language.startsWith('nl');

/// Joins a prompt with the maneuver that follows it closely:
/// "Take the exit. Then: keep right."
String thenPhrase(String first, String next, String language) =>
    '${_stripPeriod(first)}. ${_dutch(language) ? 'Daarna' : 'Then'}: $next';

/// Which lanes to use ("Use the left two lanes"), or `null` when there is
/// nothing useful to say: no lane data, a single lane, all lanes valid, or
/// a selection that is not simply left / right / middle.
String? laneHint(List<RouteLane> lanes, String language) {
  final total = lanes.length;
  if (total < 2) return null;
  final used = [
    for (var i = 0; i < total; i++)
      if (lanes[i].isActive) i,
  ];
  if (used.isEmpty || used.length == total) return null;
  final contiguous = used.last - used.first == used.length - 1;
  if (!contiguous) return null;

  final count = used.length;
  final dutch = _dutch(language);
  if (used.first == 0) {
    return dutch
        ? (count == 1
              ? 'Gebruik de linkerrijstrook'
              : 'Gebruik de linker ${_number(count, true)} rijstroken')
        : (count == 1
              ? 'Use the left lane'
              : 'Use the left ${_number(count, false)} lanes');
  }
  if (used.last == total - 1) {
    return dutch
        ? (count == 1
              ? 'Gebruik de rechterrijstrook'
              : 'Gebruik de rechter ${_number(count, true)} rijstroken')
        : (count == 1
              ? 'Use the right lane'
              : 'Use the right ${_number(count, false)} lanes');
  }
  if (count == 1 && total == 3) {
    return dutch ? 'Gebruik de middelste rijstrook' : 'Use the middle lane';
  }
  return null;
}

String _number(int n, bool dutch) {
  const nl = {2: 'twee', 3: 'drie', 4: 'vier'};
  const en = {2: 'two', 3: 'three', 4: 'four'};
  return (dutch ? nl : en)[n] ?? '$n';
}

String _stripPeriod(String text) =>
    text.endsWith('.') ? text.substring(0, text.length - 1) : text;
