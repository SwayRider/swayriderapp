import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/speech_service.dart';
import 'package:swayriderapp/domain/navigation/announcer.dart';
import 'package:swayriderapp/domain/navigation/prompt_queue.dart';

/// Speech whose phrases only end when the test says so.
class _ManualSpeech implements SpeechService {
  final started = <String>[];
  final _done = <Completer<void>>[];
  int stops = 0;

  @override
  Future<void> speak(String text, {required String language}) {
    started.add(text);
    final done = Completer<void>();
    _done.add(done);
    return done.future;
  }

  void finishCurrent() => _done[started.length - 1].complete();

  @override
  Future<void> stop() async {
    stops++;
    for (final d in _done) {
      if (!d.isCompleted) d.complete();
    }
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _ManualSpeech speech;
  late PromptQueue queue;

  setUp(() {
    speech = _ManualSpeech();
    queue = PromptQueue(speech: speech, language: 'nl-NL');
  });

  test('speaks prompts one after the other without cutting any off', () async {
    queue.add(const [Utterance('one'), Utterance('two')]);
    await settle();
    expect(speech.started, ['one']);

    speech.finishCurrent();
    await settle();
    expect(speech.started, ['one', 'two']);
  });

  test('prompts added while speaking wait their turn', () async {
    queue.add(const [Utterance('one')]);
    await settle();
    queue.add(const [Utterance('two')]);
    await settle();
    expect(speech.started, ['one']);
    expect(queue.pending, 1);

    speech.finishCurrent();
    await settle();
    expect(speech.started, ['one', 'two']);
  });

  test('drops queued prompts for maneuvers the rider has passed', () async {
    queue.update(100);
    queue.add(const [
      Utterance('one', validUntilMeters: 500),
      Utterance('stale', validUntilMeters: 400),
      Utterance('fresh', validUntilMeters: 900),
    ]);
    await settle();
    queue.update(450);
    speech.finishCurrent();
    await settle();

    expect(speech.started, ['one', 'fresh']);
  });

  test('an arrival prompt is never stale', () async {
    queue.add(const [Utterance('one'), Utterance('arrived', isArrival: true)]);
    await settle();
    queue.update(1e9);
    speech.finishCurrent();
    await settle();

    expect(speech.started, ['one', 'arrived']);
  });

  test('stop clears the queue, silences, and the queue works again', () async {
    queue.add(const [Utterance('one'), Utterance('two')]);
    await settle();
    await queue.stop();
    await settle();

    expect(speech.stops, 1);
    expect(speech.started, ['one']);

    queue.add(const [Utterance('three')]);
    await settle();
    expect(speech.started, ['one', 'three']);
  });

  test(
    'clear drops the waiting prompts but not the one being spoken',
    () async {
      queue.add(const [Utterance('one'), Utterance('two')]);
      await settle();
      queue.clear();
      expect(queue.pending, 0);

      speech.finishCurrent();
      await settle();
      expect(speech.started, ['one']);
      expect(speech.stops, 0);

      queue.add(const [Utterance('three')]);
      await settle();
      expect(speech.started, ['one', 'three']);
    },
  );
}
