import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Bump when the shape of recorded events changes in a way readers (the
/// backend metrics, the replay tooling) must know about.
const telemetrySchemaVersion = 1;

/// Records a structured, replayable trace of what the app did: searches,
/// route planning and navigation. See [FileTelemetryService].
///
/// Callers never need to check [enabled]: [record] is a no-op when disabled.
/// Payloads must be JSON-encodable.
abstract class TelemetryService {
  /// Whether events are being recorded.
  bool get enabled;

  /// Id of the current app-run session, or null when disabled or not started.
  String? get sessionId;

  /// Appends an event of [type] with [payload] to the current session.
  void record(String type, [Map<String, Object?> payload = const {}]);

  /// Opens the session file for this app run. Safe to call more than once.
  Future<void> start({Map<String, Object?> meta = const {}});

  /// Flushes buffered events to disk.
  Future<void> flush();

  /// Session files on disk, newest first, including the current one. The
  /// current session is flushed first so it is complete.
  Future<List<File>> sessionFiles();
}

/// Telemetry that records nothing; used when [AppConfig.debugTelemetry] is off.
class NoopTelemetryService implements TelemetryService {
  const NoopTelemetryService();

  @override
  bool get enabled => false;

  @override
  String? get sessionId => null;

  @override
  void record(String type, [Map<String, Object?> payload = const {}]) {}

  @override
  Future<void> start({Map<String, Object?> meta = const {}}) async {}

  @override
  Future<void> flush() async {}

  @override
  Future<List<File>> sessionFiles() async => const [];
}

/// Writes one append-only JSONL file per app run into the app's documents
/// directory (`telemetry/SESSION_ID.jsonl`). Every line is a JSON object with
/// `v` (schema version), `t` (ms since session start, monotonic), `at` (UTC
/// ISO-8601 wall clock), `type` and `data`.
///
/// Old sessions are pruned by count on start so the folder stays bounded.
class FileTelemetryService implements TelemetryService {
  FileTelemetryService({
    Future<Directory> Function()? directory,
    DateTime Function()? clock,
    this.maxSessions = 10,
  }) : _directory = directory ?? _defaultDirectory,
       _clock = clock ?? DateTime.now;

  static final _log = Logger('FileTelemetryService');

  static Future<Directory> _defaultDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/telemetry');
  }

  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;

  /// Number of session files kept on disk, including the current one.
  final int maxSessions;

  final Stopwatch _elapsed = Stopwatch();
  IOSink? _sink;
  File? _file;
  String? _sessionId;
  Future<void>? _starting;

  /// Events recorded before [start] finished opening the file.
  final List<String> _pending = [];

  @override
  bool get enabled => true;

  @override
  String? get sessionId => _sessionId;

  @override
  void record(String type, [Map<String, Object?> payload = const {}]) {
    final line = jsonEncode({
      'v': telemetrySchemaVersion,
      't': _elapsed.elapsedMilliseconds,
      'at': _clock().toUtc().toIso8601String(),
      'type': type,
      'data': payload,
    });
    final sink = _sink;
    if (sink != null) {
      sink.writeln(line);
    } else {
      _pending.add(line);
    }
  }

  @override
  Future<void> start({Map<String, Object?> meta = const {}}) {
    return _starting ??= _open(meta);
  }

  Future<void> _open(Map<String, Object?> meta) async {
    try {
      final dir = await _directory();
      await dir.create(recursive: true);
      final started = _clock().toUtc();
      final id = started
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-')
          .replaceAll('Z', '');
      _sessionId = id;
      _file = File('${dir.path}/$id.jsonl');
      _sink = _file!.openWrite(mode: FileMode.append);
      _elapsed.start();
      record('session_meta', {'sessionId': id, ...meta});
      for (final line in _pending) {
        _sink!.writeln(line);
      }
      _pending.clear();
      await _prune(dir);
    } on Object catch (e, st) {
      // Telemetry must never break the app.
      _log.warning('Could not open telemetry session: $e', e, st);
      _sink = null;
    }
  }

  Future<void> _prune(Directory dir) async {
    final files = await _listSessions(dir);
    for (final stale in files.skip(maxSessions)) {
      try {
        await stale.delete();
      } on Object catch (e) {
        _log.warning('Could not delete ${stale.path}: $e');
      }
    }
  }

  static Future<List<File>> _listSessions(Directory dir) async {
    if (!await dir.exists()) return const [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.jsonl'))
        .cast<File>()
        .toList();
    // File names start with a sortable UTC timestamp.
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  @override
  Future<void> flush() async {
    try {
      await _sink?.flush();
    } on Object catch (e) {
      _log.warning('Could not flush telemetry: $e');
    }
  }

  @override
  Future<List<File>> sessionFiles() async {
    await flush();
    return _listSessions(await _directory());
  }
}
