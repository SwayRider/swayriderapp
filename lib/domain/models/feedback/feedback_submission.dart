/// What the rider can say went wrong; sent as stable ids so the backend and
/// the triage tooling can label issues without parsing the comment.
enum FeedbackTag {
  wrongTurn('wrong-turn'),
  lateVoice('late-voice'),
  badReroute('bad-reroute'),
  wrongRoute('wrong-route'),
  badSearch('bad-search'),
  other('other');

  const FeedbackTag(this.id);

  final String id;
}

/// Where the report was started from.
enum FeedbackTrigger {
  /// The popup shown when a navigation ends or is stopped.
  navigationEnd('navigation_end'),

  /// "Report a problem" in the profile menu.
  manual('manual');

  const FeedbackTrigger(this.id);

  final String id;
}

/// A rider's feedback on a session, sent together with its telemetry trace.
class FeedbackSubmission {
  const FeedbackSubmission({
    required this.trigger,
    this.stars,
    this.tags = const {},
    this.comment = '',
    this.reportProblem = false,
  });

  final FeedbackTrigger trigger;

  /// 1-5, or `null` when the rider did not rate.
  final int? stars;
  final Set<FeedbackTag> tags;
  final String comment;

  /// Whether the backend should open an issue for this report; a stored trace
  /// alone is kept either way.
  final bool reportProblem;

  Map<String, Object?> toJson() => {
    'trigger': trigger.id,
    'stars': stars,
    'tags': [for (final t in tags) t.id],
    'comment': comment,
    'reportProblem': reportProblem,
  };
}
