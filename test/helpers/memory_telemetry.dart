import 'dart:io';

import 'package:swayriderapp/data/services/telemetry/telemetry_service.dart';

/// Keeps recorded events in memory so tests can assert on them.
class MemoryTelemetryService implements TelemetryService {
  final events = <({String type, Map<String, Object?> data})>[];

  Iterable<String> get types => events.map((e) => e.type);

  List<Map<String, Object?>> of(String type) => [
    for (final e in events)
      if (e.type == type) e.data,
  ];

  @override
  bool get enabled => true;

  @override
  String? get sessionId => 'test';

  @override
  void record(String type, [Map<String, Object?> payload = const {}]) =>
      events.add((type: type, data: payload));

  @override
  Future<void> start({Map<String, Object?> meta = const {}}) async {}

  @override
  Future<void> flush() async {}

  @override
  Future<List<File>> sessionFiles() async => const [];
}
