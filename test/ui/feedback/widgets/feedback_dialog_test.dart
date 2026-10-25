import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/feedback/feedback_submission.dart';
import 'package:swayriderapp/ui/core/localization/applocalization.dart';
import 'package:swayriderapp/ui/feedback/widgets/feedback_dialog.dart';

void main() {
  FeedbackSubmission? result;
  var closed = false;

  Future<void> open(WidgetTester tester, FeedbackTrigger trigger) async {
    result = null;
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('nl')],
        localizationsDelegates: [
          ...GlobalMaterialLocalizations.delegates,
          AppLocalizationDelegate(),
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<FeedbackSubmission>(
                  context: context,
                  builder: (_) => FeedbackDialog(trigger: trigger),
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool reportTicked(WidgetTester tester) => tester
      .widget<CheckboxListTile>(
        find.byKey(const Key('feedback-report-problem')),
      )
      .value!;

  group('after a navigation', () {
    testWidgets('a low rating ticks "report this as a problem"', (
      tester,
    ) async {
      await open(tester, FeedbackTrigger.navigationEnd);
      expect(reportTicked(tester), isFalse);

      await tester.tap(find.byKey(const Key('feedback-star-3')));
      await tester.pump();

      expect(reportTicked(tester), isTrue);
    });

    testWidgets('a high rating leaves it unticked', (tester) async {
      await open(tester, FeedbackTrigger.navigationEnd);

      await tester.tap(find.byKey(const Key('feedback-star-5')));
      await tester.pump();

      expect(reportTicked(tester), isFalse);
    });

    testWidgets('the rider can untick it after a low rating', (tester) async {
      await open(tester, FeedbackTrigger.navigationEnd);
      await tester.tap(find.byKey(const Key('feedback-star-1')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('feedback-report-problem')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(result!.stars, 1);
      expect(result!.reportProblem, isFalse);
    });

    testWidgets('sends stars, tags and comment', (tester) async {
      await open(tester, FeedbackTrigger.navigationEnd);
      await tester.tap(find.byKey(const Key('feedback-star-2')));
      await tester.tap(find.byKey(const Key('feedback-tag-late-voice')));
      await tester.enterText(
        find.byKey(const Key('feedback-comment')),
        '  voice came after the turn  ',
      );
      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(result!.trigger, FeedbackTrigger.navigationEnd);
      expect(result!.stars, 2);
      expect(result!.tags, {FeedbackTag.lateVoice});
      expect(result!.comment, 'voice came after the turn');
      expect(result!.reportProblem, isTrue);
    });

    testWidgets('skipping still returns a submission, without rating', (
      tester,
    ) async {
      await open(tester, FeedbackTrigger.navigationEnd);
      await tester.tap(find.byKey(const Key('feedback-skip')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.stars, isNull);
      expect(result!.reportProblem, isFalse);
    });

    testWidgets('tapping the same star again clears the rating', (
      tester,
    ) async {
      await open(tester, FeedbackTrigger.navigationEnd);
      await tester.tap(find.byKey(const Key('feedback-star-4')));
      await tester.tap(find.byKey(const Key('feedback-star-4')));
      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(result!.stars, isNull);
    });
  });

  group('manual report', () {
    testWidgets('cannot be sent empty', (tester) async {
      await open(tester, FeedbackTrigger.manual);

      final send = tester.widget<FilledButton>(
        find.byKey(const Key('feedback-send')),
      );
      expect(send.onPressed, isNull);
      expect(find.byKey(const Key('feedback-report-problem')), findsNothing);
    });

    testWidgets('a tag is enough, and it always reports a problem', (
      tester,
    ) async {
      await open(tester, FeedbackTrigger.manual);
      await tester.tap(find.byKey(const Key('feedback-tag-bad-search')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('feedback-send')));
      await tester.pumpAndSettle();

      expect(result!.trigger, FeedbackTrigger.manual);
      expect(result!.tags, {FeedbackTag.badSearch});
      expect(result!.reportProblem, isTrue);
    });

    testWidgets('cancel returns nothing', (tester) async {
      await open(tester, FeedbackTrigger.manual);
      await tester.tap(find.byKey(const Key('feedback-skip')));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });
  });
}
