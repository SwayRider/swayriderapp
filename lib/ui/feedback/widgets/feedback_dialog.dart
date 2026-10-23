import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/feedback/feedback_repository.dart';
import '../../../data/services/telemetry/telemetry_service.dart';
import '../../../domain/models/feedback/feedback_submission.dart';
import '../../../utils/result.dart';
import '../../core/localization/applocalization.dart';

final _log = Logger('FeedbackDialog');

/// Rating of this many stars or fewer ticks "report this as a problem" by
/// itself.
const autoReportMaxStars = 3;

/// Asks the rider for feedback and sends it with the telemetry trace.
///
/// Returns once the dialog is closed; the upload carries on in the
/// background and its outcome is shown in a snackbar. Does nothing when
/// telemetry is off.
///
/// [FeedbackTrigger.navigationEnd] can be skipped (the trace is still sent,
/// without a rating); [FeedbackTrigger.manual] only sends when the rider
/// wrote something, always files a problem, and also sends the last few
/// sessions.
Future<void> reportFeedback(
  BuildContext context, {
  required FeedbackTrigger trigger,
}) async {
  final telemetry = context.read<TelemetryService>();
  if (!telemetry.enabled) return;
  final repository = context.read<FeedbackRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalization.of(context);

  final submission = await showDialog<FeedbackSubmission>(
    context: context,
    barrierDismissible: false,
    builder: (_) => FeedbackDialog(trigger: trigger),
  );
  if (submission == null) return;

  unawaited(
    _upload(
      repository: repository,
      submission: submission,
      messenger: messenger,
      l10n: l10n,
    ),
  );
}

Future<void> _upload({
  required FeedbackRepository repository,
  required FeedbackSubmission submission,
  required ScaffoldMessengerState messenger,
  required AppLocalization l10n,
}) async {
  final result = await repository.submit(
    submission,
    sessionCount: submission.trigger == FeedbackTrigger.manual ? 3 : 1,
  );
  switch (result) {
    case Ok<void>():
      messenger.showSnackBar(SnackBar(content: Text(l10n.feedbackSent)));
    case Error<void>():
      _log.warning('Could not send feedback: ${result.error}');
      messenger.showSnackBar(SnackBar(content: Text(l10n.feedbackFailed)));
  }
}

/// The feedback form: stars, quick tags, a comment and, after a navigation,
/// the "report a problem" choice. Pops a [FeedbackSubmission], or `null`
/// when a manual report is cancelled.
class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key, required this.trigger});

  final FeedbackTrigger trigger;

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _comment = TextEditingController();
  final _tags = <FeedbackTag>{};
  int? _stars;
  bool _reportProblem = false;

  bool get _manual => widget.trigger == FeedbackTrigger.manual;

  /// A manual report needs content; after a navigation everything is optional.
  bool get _canSend =>
      !_manual || _tags.isNotEmpty || _comment.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _rate(int stars) {
    setState(() {
      // Tapping the current rating again clears it.
      _stars = _stars == stars ? null : stars;
      final rated = _stars;
      if (rated != null && rated <= autoReportMaxStars) {
        _reportProblem = true;
      }
    });
  }

  FeedbackSubmission _submission() => FeedbackSubmission(
    trigger: widget.trigger,
    stars: _stars,
    tags: {..._tags},
    comment: _comment.text.trim(),
    reportProblem: _manual || _reportProblem,
  );

  String _tagLabel(AppLocalization l10n, FeedbackTag tag) => switch (tag) {
    FeedbackTag.wrongTurn => l10n.feedbackTagWrongTurn,
    FeedbackTag.lateVoice => l10n.feedbackTagLateVoice,
    FeedbackTag.badReroute => l10n.feedbackTagBadReroute,
    FeedbackTag.wrongRoute => l10n.feedbackTagWrongRoute,
    FeedbackTag.badSearch => l10n.feedbackTagBadSearch,
    FeedbackTag.other => l10n.feedbackTagOther,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return AlertDialog(
      title: Text(_manual ? l10n.feedbackReport : l10n.feedbackTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: Key('feedback-star-$i'),
                    onPressed: () => _rate(i),
                    icon: Icon(
                      i <= (_stars ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in FeedbackTag.values)
                  FilterChip(
                    key: Key('feedback-tag-${tag.id}'),
                    label: Text(_tagLabel(l10n, tag)),
                    selected: _tags.contains(tag),
                    onSelected: (on) =>
                        setState(() => on ? _tags.add(tag) : _tags.remove(tag)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('feedback-comment'),
              controller: _comment,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: l10n.feedbackCommentHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (!_manual)
              CheckboxListTile(
                key: const Key('feedback-report-problem'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _reportProblem,
                onChanged: (on) => setState(() => _reportProblem = on ?? false),
                title: Text(l10n.feedbackReportProblem),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('feedback-skip'),
          onPressed: () => Navigator.of(
            context,
          ).pop(_manual ? null : FeedbackSubmission(trigger: widget.trigger)),
          child: Text(_manual ? l10n.feedbackCancel : l10n.feedbackSkip),
        ),
        FilledButton(
          key: const Key('feedback-send'),
          onPressed: _canSend
              ? () => Navigator.of(context).pop(_submission())
              : null,
          child: Text(l10n.feedbackSend),
        ),
      ],
    );
  }
}
