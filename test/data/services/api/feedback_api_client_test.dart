import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/api/feedback_api_client.dart';
import 'package:swayriderapp/data/services/api/unauthorized_exception.dart';
import 'package:swayriderapp/domain/models/feedback/feedback_submission.dart';
import 'package:swayriderapp/utils/result.dart';

/// One part of a parsed multipart body.
class _Part {
  _Part(this.headers, this.body);

  final String headers;
  final List<int> body;

  String get text => utf8.decode(body);
}

/// Splits a multipart body into its parts (enough for these tests: the
/// delimiters are ASCII, the part bodies may be binary).
List<_Part> _parseMultipart(List<int> body, String boundary) {
  final delimiter = latin1.encode('--$boundary');
  final parts = <_Part>[];
  var i = _indexOf(body, delimiter, 0);
  while (i != -1) {
    final start = i + delimiter.length;
    // "--" right after the delimiter closes the message.
    if (body[start] == 0x2d && body[start + 1] == 0x2d) break;
    final next = _indexOf(body, delimiter, start);
    // Strip the CRLF after the delimiter and the CRLF before the next one.
    final part = body.sublist(start + 2, next - 2);
    final split = _indexOf(part, latin1.encode('\r\n\r\n'), 0);
    parts.add(
      _Part(latin1.decode(part.sublist(0, split)), part.sublist(split + 4)),
    );
    i = next;
  }
  return parts;
}

int _indexOf(List<int> haystack, List<int> needle, int from) {
  for (var i = from; i <= haystack.length - needle.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}

void main() {
  late HttpServer server;
  late FeedbackApiClient client;
  late Completer<HttpRequest> received;
  late Completer<List<int>> receivedBody;
  var status = 201;

  setUp(() async {
    status = 201;
    received = Completer();
    receivedBody = Completer();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final bytes = await request.fold<List<int>>([], (a, b) => a..addAll(b));
      received.complete(request);
      receivedBody.complete(bytes);
      request.response.statusCode = status;
      await request.response.close();
    });
    client = FeedbackApiClient(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: '/api/v1/feedback',
    )..authHeaderProvider = () => 'Bearer token-1';
  });

  tearDown(() => server.close(force: true));

  const feedback = FeedbackSubmission(
    trigger: FeedbackTrigger.navigationEnd,
    stars: 2,
    tags: {FeedbackTag.lateVoice},
    comment: 'voice came late',
    reportProblem: true,
  );

  // Not valid UTF-8 and containing CRLF, to prove the parts are binary-safe.
  final gzipped = [0x1f, 0x8b, 0x08, 0x00, 0x0d, 0x0a, 0xff, 0xfe, 0x00];

  test(
    'posts a multipart report to the configured path with the token',
    () async {
      final result = await client.submit(
        feedback: feedback,
        sessions: [SessionBundle(id: 'session-1', gzipped: gzipped)],
      );

      expect(result, isA<Ok<void>>());
      final request = await received.future;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/v1/feedback');
      expect(request.headers.value('authorization'), 'Bearer token-1');
      expect(request.headers.contentType?.mimeType, 'multipart/form-data');

      final boundary = request.headers.contentType!.parameters['boundary']!;
      final parts = _parseMultipart(await receivedBody.future, boundary);
      expect(parts, hasLength(2));

      expect(parts[0].headers, contains('name="feedback"'));
      expect(parts[0].headers, contains('application/json'));
      final json = jsonDecode(parts[0].text) as Map<String, dynamic>;
      expect(json['stars'], 2);
      expect(json['trigger'], 'navigation_end');
      expect(json['tags'], ['late-voice']);
      expect(json['comment'], 'voice came late');
      expect(json['reportProblem'], true);
      expect(json['sessionIds'], ['session-1']);
      expect(json['platform'], Platform.operatingSystem);

      expect(parts[1].headers, contains('name="session"'));
      expect(parts[1].headers, contains('filename="session-1.jsonl.gz"'));
      expect(parts[1].headers, contains('application/gzip'));
      expect(parts[1].body, gzipped);
    },
  );

  test('sends every session as its own part, in order', () async {
    await client.submit(
      feedback: feedback,
      sessions: [
        SessionBundle(id: 'a', gzipped: [1, 2, 3]),
        SessionBundle(id: 'b', gzipped: [4, 5]),
      ],
    );

    final request = await received.future;
    final boundary = request.headers.contentType!.parameters['boundary']!;
    final parts = _parseMultipart(await receivedBody.future, boundary);
    expect(parts.map((p) => p.body).skip(1), [
      [1, 2, 3],
      [4, 5],
    ]);
    final json = jsonDecode(parts.first.text) as Map<String, dynamic>;
    expect(json['sessionIds'], ['a', 'b']);
  });

  test('a 401 is reported as unauthorized so the caller can refresh', () async {
    status = 401;

    final result = await client.submit(feedback: feedback, sessions: const []);

    expect((result as Error<void>).error, isA<UnauthorizedException>());
  });

  test('other failures are errors', () async {
    status = 413;

    final result = await client.submit(feedback: feedback, sessions: const []);

    expect(result, isA<Error<void>>());
    expect((result as Error<void>).error.toString(), contains('413'));
  });

  test('an unreachable server is an error, not an exception', () async {
    await server.close(force: true);

    final result = await client.submit(feedback: feedback, sessions: const []);

    expect(result, isA<Error<void>>());
  });
}
