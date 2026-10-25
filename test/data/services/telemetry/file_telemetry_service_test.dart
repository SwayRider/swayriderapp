import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/telemetry/telemetry_service.dart';

void main() {
  late Directory dir;
  var now = DateTime.utc(2026, 10, 22, 12);

  FileTelemetryService create({int maxSessions = 10}) => FileTelemetryService(
    directory: () async => dir,
    clock: () => now,
    maxSessions: maxSessions,
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('telemetry_test');
    now = DateTime.utc(2026, 10, 22, 12);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'writes session_meta first, then events, one JSON object per line',
    () async {
      final telemetry = create();
      await telemetry.start(meta: {'platform': 'test'});
      telemetry.record('search_query', {'text': 'leuven'});

      final files = await telemetry.sessionFiles();
      expect(files, hasLength(1));
      final lines = files.single.readAsLinesSync().map(jsonDecode).toList();
      expect(lines.map((l) => l['type']), ['session_meta', 'search_query']);
      expect(lines.first['v'], telemetrySchemaVersion);
      expect(lines.first['data']['platform'], 'test');
      expect(lines.first['data']['sessionId'], telemetry.sessionId);
      expect(lines.last['data'], {'text': 'leuven'});
      expect(lines.last['at'], '2026-10-22T12:00:00.000Z');
    },
  );

  test('keeps events recorded before start finished', () async {
    final telemetry = create();
    telemetry.record('early');
    await telemetry.start();

    final lines = (await telemetry.sessionFiles()).single
        .readAsLinesSync()
        .map(jsonDecode)
        .toList();
    expect(lines.map((l) => l['type']), contains('early'));
  });

  test('prunes the oldest sessions beyond maxSessions', () async {
    for (var i = 0; i < 3; i++) {
      now = now.add(const Duration(hours: 1));
      await create(maxSessions: 2).start();
    }

    final names = dir.listSync().map((e) => e.path.split('/').last).toList()
      ..sort();
    expect(names, hasLength(2));
    expect(names.first, startsWith('2026-10-22T14'));
    expect(names.last, startsWith('2026-10-22T15'));
  });

  test('sessionFiles lists newest first', () async {
    now = now.add(const Duration(hours: 1));
    await create().start();
    now = now.add(const Duration(hours: 1));
    final current = create();
    await current.start();

    final files = await current.sessionFiles();
    expect(files.first.path, contains(current.sessionId!));
    expect(files, hasLength(2));
  });

  test('NoopTelemetryService records nothing', () async {
    const telemetry = NoopTelemetryService();
    telemetry.record('x');
    await telemetry.start();
    expect(telemetry.enabled, isFalse);
    expect(await telemetry.sessionFiles(), isEmpty);
  });
}
