import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';

import '../../data/services/speech_service.dart';
import '../../data/services/telemetry/telemetry_service.dart';
import 'announcer.dart';

/// Speaks prompts one after the other, so a new prompt never cuts off the
/// one being spoken, and drops queued prompts that went stale because the
/// rider has already passed the maneuver they announce.
class PromptQueue {
  PromptQueue({
    required this._speech,
    required this._language,
    this._telemetry = const NoopTelemetryService(),
  });

  final SpeechService _speech;
  final String _language;
  final TelemetryService _telemetry;
  final _ids = Expando<int>('prompt id');
  int _nextId = 0;
  final _pending = Queue<Utterance>();
  final _log = Logger('PromptQueue');

  double _alongMeters = 0;
  bool _speaking = false;
  int _generation = 0;

  /// Number of prompts waiting to be spoken (not counting the current one).
  int get pending => _pending.length;

  /// Adds [utterances] to the end of the queue and starts speaking if idle.
  void add(Iterable<Utterance> utterances) {
    for (final u in utterances) {
      final id = _ids[u] = ++_nextId;
      _telemetry.record('prompt_enqueued', {
        'id': id,
        'text': u.text,
        'isArrival': u.isArrival,
        'validUntilM': u.validUntilMeters.isFinite ? u.validUntilMeters : null,
        'alongM': _alongMeters,
        'queued': _pending.length + (_speaking ? 1 : 0),
      });
      _pending.add(u);
    }
    unawaited(_pump());
  }

  /// Tells the queue where the rider is, so stale prompts can be dropped.
  void update(double alongMeters) => _alongMeters = alongMeters;

  /// Drops the prompts that are waiting; the one being spoken is finished.
  void clear() {
    _recordDropped(_pending, 'cleared');
    _pending.clear();
  }

  /// Clears the queue and silences the current prompt.
  Future<void> stop() {
    _generation++;
    _speaking = false;
    _recordDropped(_pending, 'stopped');
    _pending.clear();
    return _speech.stop();
  }

  Future<void> _pump() async {
    if (_speaking) return;
    _speaking = true;
    final generation = _generation;
    try {
      while (_pending.isNotEmpty && generation == _generation) {
        final next = _pending.removeFirst();
        if (next.validUntilMeters < _alongMeters) {
          _recordDropped([next], 'stale');
          continue;
        }
        _log.info('Speaking: ${next.text}');
        _telemetry.record('prompt_start', {
          'id': _ids[next],
          'alongM': _alongMeters,
        });
        await _speech.speak(next.text, language: _language);
        _telemetry.record('prompt_end', {
          'id': _ids[next],
          'alongM': _alongMeters,
        });
      }
    } finally {
      if (generation == _generation) _speaking = false;
    }
  }

  void _recordDropped(Iterable<Utterance> dropped, String reason) {
    for (final u in dropped) {
      _telemetry.record('prompt_dropped', {
        'id': _ids[u],
        'reason': reason,
        'alongM': _alongMeters,
      });
    }
  }
}
