import '../../../domain/models/feedback/feedback_submission.dart';
import '../../../utils/result.dart';

/// Sends a rider's feedback, plus the telemetry trace it is about, to the
/// backend.
abstract class FeedbackRepository {
  /// Sends [feedback] with the last [sessionCount] recorded sessions (the
  /// current one first).
  Future<Result<void>> submit(
    FeedbackSubmission feedback, {
    int sessionCount = 1,
  });
}
