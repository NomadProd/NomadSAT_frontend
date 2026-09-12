// Bluebook-style module flow: automatic within a section, and a clock that
// stops when the student leaves.
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

  /// Every pauseTimer value sent to saveProgress, in order.
  final List<bool> pauseCalls = [];
  int pauseSecondsToReport = 0;

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
    bool? pauseTimer,
  }) async {
    if (pauseTimer != null) pauseCalls.add(pauseTimer);
    return PracticeTestAttempt(
      id: 99, testId: 1, studentId: 42, status: 'in_progress',
      currentModuleId: currentModuleId,
      timerPauseSeconds: pauseSecondsToReport,
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

  group('the clock stops when the student leaves', () {
    testWidgets('leaving through the dialog pauses it', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _start(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(service.pauseCalls, contains(true),
          reason: 'leaving must stop the module clock');
    });

    testWidgets('the leave dialog no longer claims the timer keeps running',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _start(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('timer keeps running'), findsNothing);
    });

    testWidgets('hiding the tab pauses, and showing it resumes',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _start(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pumpAndSettle();
      expect(service.pauseCalls, contains(true),
          reason: 'closing or hiding the tab is how students actually leave');

      // A browser returning from hidden walks back up through inactive.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(service.pauseCalls.last, isFalse,
          reason: 'coming back must restart the clock');
    });

    testWidgets('resuming a paused attempt banks the paused seconds',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _start(
        tester,
        attempt: PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: _rw1,
          moduleStartedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          timerPausedAt: DateTime.now().subtract(const Duration(minutes: 9)),
        ),
      );

      expect(service.pauseCalls, contains(false),
          reason: 'a paused attempt must be un-paused when the student returns');
    });
  });
}
