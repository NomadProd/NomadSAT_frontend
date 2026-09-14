// Bluebook-style module flow: automatic within a section, and a clock that
// stops when the student leaves.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/student/practice_test_screen.dart';

const _rw1 = 10, _rw2 = 11, _math1 = 20, _math2 = 21;

PracticeTestInfo _test() => const PracticeTestInfo(
      id: 1,
      title: 'Practice Test 1',
      visible: true,
      isPublishable: true,
      classIds: [1],
      modules: [
        PracticeTestModuleInfo(
          id: _rw1, name: 'Reading & Writing 1', section: 'reading_writing',
          orderIndex: 1, timeLimitSeconds: 1920,
          requiredQuestionCount: 2, questionCount: 2,
        ),
        PracticeTestModuleInfo(
          id: _rw2, name: 'Reading & Writing 2', section: 'reading_writing',
          orderIndex: 2, timeLimitSeconds: 1920,
          requiredQuestionCount: 2, questionCount: 2,
        ),
        PracticeTestModuleInfo(
          id: _math1, name: 'Math 1', section: 'math',
          orderIndex: 3, timeLimitSeconds: 2100,
          requiredQuestionCount: 2, questionCount: 2,
        ),
        PracticeTestModuleInfo(
          id: _math2, name: 'Math 2', section: 'math',
          orderIndex: 4, timeLimitSeconds: 2100,
          requiredQuestionCount: 2, questionCount: 2,
        ),
      ],
    );

ExamQuestion _q(int id, int moduleId, int order, bool isMath, String stem) =>
    ExamQuestion(
      id: id, moduleId: moduleId, orderIndex: order, isMath: isMath,
      domain: isMath ? 'Algebra' : 'Craft and Structure',
      questionText: stem,
      choices: const [
        ExamChoice(key: 'A', text: 'Choice A'),
        ExamChoice(key: 'B', text: 'Choice B'),
      ],
    );

List<ExamQuestion> _questions() => [
      _q(1, _rw1, 1, false, 'RW1 Q1'), _q(2, _rw1, 2, false, 'RW1 Q2'),
      _q(3, _rw2, 1, false, 'RW2 Q1'), _q(4, _rw2, 2, false, 'RW2 Q2'),
      _q(5, _math1, 1, true, 'Math1 Q1'), _q(6, _math1, 2, true, 'Math1 Q2'),
      _q(7, _math2, 1, true, 'Math2 Q1'), _q(8, _math2, 2, true, 'Math2 Q2'),
    ];

class _Service implements PracticeTestService {
  _Service({this.attempt});

  final PracticeTestAttempt? attempt;

  /// What the server says is left in the module, if anything.
  int? secondsRemainingToReport;

  /// Every (module, question) pair sent to saveProgress, in order.
  final List<({int? module, int? question})> progress = [];
  /// When set, saveProgress hangs until this completes -- a slow network.
  Completer<void>? gate;

  @override
  Future<PracticeTestInfo> fetchTest(int testId) async => _test();

  @override
  Future<PracticeTestAttempt> startAttempt(int testId) async =>
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: _rw1);

  @override
  Future<PracticeTestAttempt> fetchAttempt(int attemptId) async => attempt!;

  @override
  Future<List<ExamQuestion>> fetchAttemptQuestions(int attemptId) async =>
      _questions();

  @override
  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    String? selectedChoice,
    String? responseText,
  }) async {}

  @override
  Future<PracticeTestAttempt> saveProgress({
    required int attemptId,
    int? currentQuestionId,
    int? currentModuleId,
  }) async {
    progress.add((module: currentModuleId, question: currentQuestionId));
    if (gate != null) await gate!.future;
    return PracticeTestAttempt(
      id: 99, testId: 1, studentId: 42, status: 'in_progress',
      currentModuleId: currentModuleId,
      secondsRemaining: secondsRemainingToReport,
    );
  }

  @override
  Future<PracticeTestAttempt> completeAttempt(int attemptId) async =>
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'completed');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Future<_Service> _start(WidgetTester tester, {PracticeTestAttempt? attempt}) async {
  final service = _Service(attempt: attempt);
  await tester.pumpWidget(MaterialApp(
    home: PracticeTestScreen(testId: 1, attempt: attempt, service: service),
  ));
  await tester.pumpAndSettle();
  return service;
}

/// Answer both questions of the current module and press Continue on its review.
Future<void> _finishModule(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.tap(find.text('Choice A').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diagnostic-next-button')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('diagnostic-review-continue')));
  await tester.pumpAndSettle();
}

String _timer(WidgetTester tester) => tester
    .widget<Text>(find.descendant(
      of: find.byKey(const Key('diagnostic-timer')),
      matching: find.byType(Text),
    ))
    .data!;

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('module transitions', () {
    testWidgets('R&W 1 goes straight into R&W 2', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _start(tester);

      await _finishModule(tester);

      expect(find.byKey(const Key('diagnostic-module-break')), findsNothing,
          reason: 'modules inside a section must not stop at an interstitial');
      expect(find.text('RW2 Q1'), findsOneWidget);
    });

    testWidgets('moving on tells the server which question it landed on',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _start(tester);

      await _finishModule(tester);

      expect(find.text('RW2 Q1'), findsOneWidget);
      final move = service.progress.last;
      expect((move.module, move.question), (_rw2, 3),
          reason: 'a module id without its question leaves the server pointing '
              'at a question the student has already finished');
    });

    testWidgets('the R&W section still ends with a break', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _start(tester);

      await _finishModule(tester); // R&W 1 -> R&W 2
      await _finishModule(tester); // R&W 2 -> break before Math

      expect(find.byKey(const Key('diagnostic-module-break')), findsOneWidget,
          reason: 'Bluebook breaks between sections, not between modules');
      expect(find.text('Math1 Q1'), findsNothing);
    });

    testWidgets('Math 1 goes straight into Math 2', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _start(tester);

      await _finishModule(tester);
      await _finishModule(tester);
      await tester.tap(find.byKey(const Key('diagnostic-start-math-button')));
      await tester.pumpAndSettle();
      await _finishModule(tester); // Math 1 -> Math 2

      expect(find.byKey(const Key('diagnostic-module-break')), findsNothing);
      expect(find.text('Math2 Q1'), findsOneWidget);
    });
  });

  group('the clock belongs to the server', () {
    testWidgets('switching tab does not stop it', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _start(tester);
      final before = _timer(tester);

      // Away and back again. Nothing about this is leaving the test, and the
      // clock must not care.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 3));

      expect(_timer(tester), isNot(before),
          reason: 'a switched tab is still sitting the test');
    });

    testWidgets('it reports in while the test is open', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _start(tester);
      final before = service.progress.length;

      await tester.pump(const Duration(seconds: 25));

      expect(service.progress.length, greaterThan(before),
          reason: 'silence is how the server learns the student has gone, so '
              'an open test must keep saying it is here');
    });

    testWidgets('the server can correct the clock', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _start(tester);
      expect(_timer(tester), '32:00');

      // The next heartbeat comes back saying there is far less left.
      service.secondsRemainingToReport = 90;
      await tester.pump(const Duration(seconds: 25));
      await tester.pumpAndSettle();

      // 90s from the sync, less the few ticks since: the point is that half
      // an hour of client-side certainty gave way to the server's answer.
      expect(_timer(tester), startsWith('01:'),
          reason: 'whatever the server says is the time, even mid-module');
    });

    testWidgets('a resumed module opens on the server\'s clock',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _start(
        tester,
        attempt: const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: _rw1, currentQuestionId: 1,
          secondsRemaining: 1320,
        ),
      );

      expect(_timer(tester), '22:00');
    });

    testWidgets('the leave dialog tells the student the clock runs on',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _start(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('clock keeps running'), findsOneWidget);
    });
  });
}
