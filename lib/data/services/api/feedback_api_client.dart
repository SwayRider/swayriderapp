import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../domain/models/feedback/feedback_submission.dart';
import '../../../utils/result.dart';
import 'auth_header_provider.dart';
import 'unauthorized_exception.dart';

/// One telemetry session file, gzipped, as sent to the backend.
class SessionBundle {
  const SessionBundle({required this.id, required this.gzipped});

  final String id;
  final List<int> gzipped;
}

class FeedbackApiClient {
  FeedbackApiClient({
    String? scheme,
    String? host,
    int? port,
    String? path,
    HttpClient Function()? clientFactory,
  }) : _scheme = scheme ?? 'http',
       _host = host ?? 'localhost',
       _port = port ?? 8080,
       _path = path ?? '',
       _clientFactory = clientFactory ?? HttpClient.new;

  final String _scheme;
  final String _host;
  final int _port;
  final String _path;
  final HttpClient Function() _clientFactory;

  AuthHeaderProvider? _authHeaderProvider;

  set authHeaderProvider(AuthHeaderProvider authHeaderProvider) =>
      _authHeaderProvider = authHeaderProvider;

  /// Trace bundles are far larger than API calls; allow for a slow mobile
  /// upload.
  static const _requestTimeout = Duration(seconds: 60);

  Uri get _uri => Uri(scheme: _scheme, host: _host, port: _port, path: _path);

  /// Sends [feedback] with the telemetry [sessions] it refers to.
  ///
  /// Wire format: see [encodeFeedbackMultipart].
  Future<Result<void>> submit({
    required FeedbackSubmission feedback,
    required List<SessionBundle> sessions,
  }) async {
    final client = _clientFactory()..connectionTimeout = _requestTimeout;
    try {
      final boundary = 'swayrider-${DateTime.now().microsecondsSinceEpoch}';
      final request = await client.postUrl(_uri).timeout(_requestTimeout);
      final header = _authHeaderProvider?.call();
      if (header != null) {
        request.headers.add(HttpHeaders.authorizationHeader, header);
      }
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );
      request.add(
        encodeFeedbackMultipart(
          feedback: feedback,
          sessions: sessions,
          boundary: boundary,
        ),
      );
      final response = await request.close().timeout(_requestTimeout);
      await response.drain<void>();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Result.ok(null);
      } else if (response.statusCode == 401) {
        return const Result.error(UnauthorizedException());
      } else {
        return Result.error(
          HttpException('Feedback error (${response.statusCode})'),
        );
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }
}

/// Builds the `multipart/form-data` body of a feedback report: a `feedback`
/// part with the report as JSON (plus the ids of the sessions and the
/// platform), then one `session` part per trace, each the gzipped JSONL file
/// named after its session id.
Uint8List encodeFeedbackMultipart({
  required FeedbackSubmission feedback,
  required List<SessionBundle> sessions,
  required String boundary,
}) {
  final out = BytesBuilder();
  void text(String value) => out.add(utf8.encode(value));

  text('--$boundary\r\n');
  text('Content-Disposition: form-data; name="feedback"\r\n');
  text('Content-Type: application/json\r\n\r\n');
  text(
    jsonEncode({
      ...feedback.toJson(),
      'sessionIds': [for (final s in sessions) s.id],
      'platform': Platform.operatingSystem,
    }),
  );
  text('\r\n');
  for (final session in sessions) {
    text('--$boundary\r\n');
    text(
      'Content-Disposition: form-data; name="session"; '
      'filename="${session.id}.jsonl.gz"\r\n',
    );
    text('Content-Type: application/gzip\r\n\r\n');
    out.add(session.gzipped);
    text('\r\n');
  }
  text('--$boundary--\r\n');
  return out.toBytes();
}
