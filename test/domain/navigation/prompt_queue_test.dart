import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/speech_service.dart';
import 'package:swayriderapp/domain/navigation/announcer.dart';
import 'package:swayriderapp/domain/navigation/prompt_queue.dart';

import '../../helpers/memory_telemetry.dart';

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
  group('telemetry', telemetryTests);

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

  group('pre prompts', () {
    test(
      'interrupt a playing alert and clear the other waiting prompts',
      () async {
        queue.add(const [Utterance('alert'), Utterance('post')]);
        await settle();
        queue.add(const [Utterance('pre', isPre: true)]);
        await settle();

        expect(speech.stops, 1);
        expect(speech.started, ['alert', 'pre']);
        expect(queue.pending, 0);
      },
    );

    test('speak before waiting non-pre prompts, which are dropped', () async {
      queue.add(const [Utterance('one'), Utterance('two')]);
      await settle();
      queue.add(const [Utterance('pre', isPre: true), Utterance('three')]);
      await settle();
      speech.finishCurrent();
      await settle();

      expect(speech.started, ['one', 'pre', 'three']);
    });

    test('never interrupt a pre that is playing, and wait behind it', () async {
      queue.add(const [Utterance('first', isPre: true)]);
      await settle();
      queue.add(const [Utterance('second', isPre: true)]);
      await settle();

      expect(speech.stops, 0);
      expect(speech.started, ['first']);
      expect(queue.pending, 1);

      speech.finishCurrent();
      await settle();
      expect(speech.started, ['first', 'second']);
    });

    test('do not remove a pre that is waiting', () async {
      queue.add(const [Utterance('one')]);
      await settle();
      queue.add(const [Utterance('pre 1', isPre: true)]);
      await settle();
      // 'one' was interrupted by the first pre; a second pre then arrives
      // while the first plays.
      queue.add(const [Utterance('alert'), Utterance('pre 2', isPre: true)]);
      await settle();

      expect(speech.started, ['one', 'pre 1']);
      expect(queue.pending, 1);
      speech.finishCurrent();
      await settle();
      expect(speech.started, ['one', 'pre 1', 'pre 2']);
    });

    test('speak at once when nothing is playing', () async {
      queue.add(const [Utterance('pre', isPre: true)]);
      await settle();

      expect(speech.stops, 0);
      expect(speech.started, ['pre']);
    });
  });
}

void telemetryTests() {
  late _ManualSpeech speech;
  late MemoryTelemetryService telemetry;
  late PromptQueue queue;

  setUp(() {
    speech = _ManualSpeech();
    telemetry = MemoryTelemetryService();
    queue = PromptQueue(
      speech: speech,
      language: 'nl-NL',
      telemetry: telemetry,
    );
  });

  test(
    'records enqueue, start and end of each prompt with the same id',
    () async {
      queue.add(const [Utterance('one', validUntilMeters: 100)]);
      await settle();
      speech.finishCurrent();
      await settle();

      expect(telemetry.types, [
        'prompt_enqueued',
        'prompt_start',
        'prompt_end',
      ]);
      final id = telemetry.of('prompt_enqueued').single['id'];
      expect(telemetry.of('prompt_start').single['id'], id);
      expect(telemetry.of('prompt_end').single['id'], id);
      expect(telemetry.of('prompt_enqueued').single['text'], 'one');
      expect(telemetry.of('prompt_enqueued').single['validUntilM'], 100);
    },
  );

  test('records stale prompts as dropped and never as started', () async {
    queue.update(500);
    queue.add(const [Utterance('late', validUntilMeters: 100)]);
    await settle();

    expect(telemetry.of('prompt_dropped').single['reason'], 'stale');
    expect(telemetry.of('prompt_start'), isEmpty);
  });

  test('records queued prompts dropped by clear', () async {
    queue.add(const [Utterance('one'), Utterance('two')]);
    await settle();
    queue.clear();

    final dropped = telemetry.of('prompt_dropped');
    expect(dropped.single['reason'], 'cleared');
    expect(dropped.single['id'], telemetry.of('prompt_enqueued').last['id']);
  });

  test('records the prompts a pre prompt pushed aside as preempted', () async {
    queue.add(const [Utterance('one'), Utterance('two')]);
    await settle();
    queue.add(const [Utterance('pre', isPre: true)]);
    await settle();

    final ids = {
      for (final e in telemetry.of('prompt_enqueued')) e['text']: e['id'],
    };
    final dropped = telemetry.of('prompt_dropped');
    expect({for (final d in dropped) d['id']}, {ids['one'], ids['two']});
    expect({for (final d in dropped) d['reason']}, {'preempted'});
    expect(telemetry.of('prompt_start').last['id'], ids['pre']);
  });
}
