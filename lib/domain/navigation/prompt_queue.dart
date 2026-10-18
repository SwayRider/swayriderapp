import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';

import '../../data/services/speech_service.dart';
import 'announcer.dart';

/// Speaks prompts one after the other, so a new prompt never cuts off the
/// one being spoken, and drops queued prompts that went stale because the
/// rider has already passed the maneuver they announce.
class PromptQueue {
  PromptQueue({required this._speech, required this._language});

  final SpeechService _speech;
  final String _language;
  final _pending = Queue<Utterance>();
  final _log = Logger('PromptQueue');

  double _alongMeters = 0;
  bool _speaking = false;
  int _generation = 0;

  /// Number of prompts waiting to be spoken (not counting the current one).
  int get pending => _pending.length;

  /// Adds [utterances] to the end of the queue and starts speaking if idle.
  void add(Iterable<Utterance> utterances) {
    _pending.addAll(utterances);
    unawaited(_pump());
  }

  /// Tells the queue where the rider is, so stale prompts can be dropped.
  void update(double alongMeters) => _alongMeters = alongMeters;

  /// Clears the queue and silences the current prompt.
  Future<void> stop() {
    _generation++;
    _speaking = false;
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
        if (next.validUntilMeters < _alongMeters) continue;
        _log.info('Speaking: ${next.text}');
        await _speech.speak(next.text, language: _language);
      }
    } finally {
      if (generation == _generation) _speaking = false;
    }
  }
}
