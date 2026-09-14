import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Utils/exam_marks_store.dart';
import 'package:flutter_web/Widgets/exam_timer_bar.dart';

const _chip = Key('diagnostic-timer');
const _toggle = Key('exam-timer-toggle');

Widget _bar({required bool timerVisible, VoidCallback? onToggleTimer}) =>
    MaterialApp(
      home: Scaffold(
        body: ExamTimerBar(
          remaining: const Duration(minutes: 12),
          isMath: false,
          timerVisible: timerVisible,
          onToggleTimer: onToggleTimer,
        ),
      ),
    );

void main() {
  testWidgets('the countdown cannot be hidden unless the caller allows it',
      (tester) async {
    await tester.pumpWidget(_bar(timerVisible: true));

    // The diagnostic renders the same bar and must keep the one it has.
    expect(find.byKey(_toggle), findsNothing);
    expect(find.byKey(_chip), findsOneWidget);
  });

  testWidgets('the countdown follows the visibility the caller owns',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _bar(timerVisible: true, onToggleTimer: () => taps++),
    );
    expect(find.byKey(_chip), findsOneWidget);
    await tester.tap(find.byKey(_toggle));
    expect(taps, 1);

    // The bar does not hold the flag -- it is rebuilt at every module boundary
    // and would forget it, so the screen above owns it.
    await tester.pumpWidget(
      _bar(timerVisible: false, onToggleTimer: () => taps++),
    );
    expect(find.byKey(_chip), findsNothing);
    expect(find.byKey(_toggle), findsOneWidget);
  });

  testWidgets('the fullscreen button hides where fullscreen is not real',
      (tester) async {
    // Tests run against the stub, the same branch a non-web build takes.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExamFullscreenButton())),
    );

    expect(find.byKey(const Key('exam-fullscreen-toggle')), findsNothing);
  });

  group('ExamMarksStore', () {
    test('marks come back for the attempt that stored them', () {
      ExamMarksStore.save('practice-1', {3, 7});
      ExamMarksStore.save('practice-2', {9});

      // Keyed per attempt, so resuming one test never shows another's flags.
      expect(ExamMarksStore.load('practice-1'), {3, 7});
      expect(ExamMarksStore.load('practice-2'), {9});
      expect(ExamMarksStore.load('practice-3'), isEmpty);

      ExamMarksStore.clear('practice-1');
      expect(ExamMarksStore.load('practice-1'), isEmpty);
      expect(ExamMarksStore.load('practice-2'), {9});
      ExamMarksStore.clear('practice-2');
    });

    test('the set handed back is a copy, not the stored one', () {
      ExamMarksStore.save('practice-4', {1});
      ExamMarksStore.load('practice-4').add(2);

      expect(ExamMarksStore.load('practice-4'), {1});
      ExamMarksStore.clear('practice-4');
    });
  });
}
