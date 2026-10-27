import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';

import '../../data/services/speech_service.dart';
import '../../data/services/telemetry/telemetry_service.dart';
import 'announcer.dart';

/// Speaks prompts one after the other, so a new prompt never cuts off the
/// one being spoken, and drops queued prompts that went stale because the
/// rider has already passed the maneuver they announce.
///
/// The exception is a *pre* prompt (see [Utterance.isPre]): it is the last
/// instruction before a maneuver, so it pushes aside everything that is not
/// a pre prompt, including the prompt being spoken. Pre prompts never push
/// each other aside; they are spoken one after the other.
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
  Utterance? _current;

  /// Number of prompts waiting to be spoken (not counting the current one).
  int get pending => _pending.length;

  /// Adds [utterances] to the end of the queue and starts speaking if idle.
  /// A pre prompt first drops the waiting prompts that are not pre prompts
  /// and cuts off a prompt being spoken that is not one either.
  void add(Iterable<Utterance> utterances) {
    var interrupt = false;
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
      if (u.isPre) {
        _dropWaiting((p) => !p.isPre, 'preempted');
        final playing = _current;
        if (_speaking && playing != null && !playing.isPre) interrupt = true;
      }
      _pending.add(u);
    }
    if (interrupt) _interrupt();
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

  /// Cuts off the prompt being spoken. The pump that was speaking it ends
  /// with its generation, and a new one takes over the queue.
  void _interrupt() {
    _recordDropped([?_current], 'preempted');
    _generation++;
    _speaking = false;
    unawaited(_speech.stop());
  }

  void _dropWaiting(bool Function(Utterance) test, String reason) {
    final dropped = _pending.where(test).toList();
    _recordDropped(dropped, reason);
    _pending.removeWhere(test);
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
        _current = next;
        _log.info('Speaking: ${next.text}');
        _telemetry.record('prompt_start', {
          'id': _ids[next],
          'alongM': _alongMeters,
        });
        await _speech.speak(next.text, language: _language);
        if (identical(_current, next)) _current = null;
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
