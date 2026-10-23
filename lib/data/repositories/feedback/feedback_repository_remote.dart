import 'dart:io';

import 'package:logging/logging.dart';

import '../../../domain/models/feedback/feedback_submission.dart';
import '../../../utils/result.dart';
import '../../services/api/feedback_api_client.dart';
import '../../services/telemetry/telemetry_service.dart';
import '../auth/auth_repository.dart';
import 'feedback_repository.dart';

/// [FeedbackRepository] backed by [FeedbackApiClient]; the trace comes from
/// the [TelemetryService]'s session files.
class FeedbackRepositoryRemote implements FeedbackRepository {
  FeedbackRepositoryRemote({
    required this._feedbackApiClient,
    required this._telemetry,
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    _feedbackApiClient.authHeaderProvider = authRepository.authHeaderProvider;
  }

  final FeedbackApiClient _feedbackApiClient;
  final TelemetryService _telemetry;
  final AuthRepository _authRepository;
  final _log = Logger('FeedbackRepositoryRemote');

  @override
  Future<Result<void>> submit(
    FeedbackSubmission feedback, {
    int sessionCount = 1,
  }) async {
    // Recorded before the files are read, so it is part of the upload.
    _telemetry.record('feedback', feedback.toJson());
    final List<SessionBundle> sessions;
    try {
      final files = (await _telemetry.sessionFiles()).take(sessionCount);
      sessions = [
        for (final file in files)
          SessionBundle(
            id: file.uri.pathSegments.last.replaceAll('.jsonl', ''),
            gzipped: gzip.encode(await file.readAsBytes()),
          ),
      ];
    } on Exception catch (e) {
      _log.warning('Could not read telemetry sessions: $e');
      return Result.error(e);
    }
    return _authRepository.withAuthRetry(
      () => _feedbackApiClient.submit(feedback: feedback, sessions: sessions),
    );
  }
}
