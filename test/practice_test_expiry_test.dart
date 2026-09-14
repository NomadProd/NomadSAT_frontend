// What happens when a module's clock runs out, and what happens on a resume
// whose saved position no longer makes sense.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/student/practice_test_screen.dart';

const _rw1 = 10, _rw2 = 11, _math1 = 20, _math2 = 21;

/// Two-second modules, so a widget test can watch a clock run out.
PracticeTestInfo _test({int seconds = 2}) => PracticeTestInfo(
      id: 1,
      title: 'Practice Test 1',
      visible: true,
      isPublishable: true,
      classIds: const [1],
      modules: [
        PracticeTestModuleInfo(
          id: _rw1, name: 'Reading & Writing 1', section: 'reading_writing',
          orderIndex: 1, timeLimitSeconds: seconds,
          requiredQuestionCount: 1, questionCount: 1,
        ),
        PracticeTestModuleInfo(
          id: _rw2, name: 'Reading & Writing 2', section: 'reading_writing',
          orderIndex: 2, timeLimitSeconds: seconds,
          requiredQuestionCount: 1, questionCount: 1,
        ),
        PracticeTestModuleInfo(
          id: _math1, name: 'Math 1', section: 'math',
          orderIndex: 3, timeLimitSeconds: seconds,
          requiredQuestionCount: 1, questionCount: 1,
        ),
        PracticeTestModuleInfo(
          id: _math2, name: 'Math 2', section: 'math',
          orderIndex: 4, timeLimitSeconds: seconds,
          requiredQuestionCount: 1, questionCount: 1,
        ),
      ],
    );

ExamQuestion _q(int id, int moduleId, bool isMath, String stem) => ExamQuestion(
      id: id, moduleId: moduleId, orderIndex: 1, isMath: isMath,
      domain: isMath ? 'Algebra' : 'Craft and Structure',
      questionText: stem,
      choices: const [ExamChoice(key: 'A', text: 'Choice A')],
    );

List<ExamQuestion> _questions() => [
      _q(1, _rw1, false, 'RW1 Q1'),
      _q(2, _rw2, false, 'RW2 Q1'),
      _q(3, _math1, true, 'Math1 Q1'),
      _q(4, _math2, true, 'Math2 Q1'),
    ];

class _Service implements PracticeTestService {
  _Service({this.attempt, this.seconds = 2});

  final PracticeTestAttempt? attempt;
  final int seconds;
  int completeCalls = 0;
  final List<int> moduleAdvances = [];

  @override
  Future<PracticeTestInfo> fetchTest(int testId) async =>
      _test(seconds: seconds);

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
    if (currentModuleId != null) moduleAdvances.add(currentModuleId);
    return const PracticeTestAttempt(
        id: 99, testId: 1, studentId: 42, status: 'in_progress');
  }

  @override
  Future<PracticeTestAttempt> completeAttempt(int attemptId) async {
    completeCalls += 1;
    return const PracticeTestAttempt(
        id: 99, testId: 1, studentId: 42, status: 'completed');
  }

  @override
  Future<PracticeTestAttemptDetail> fetchAttemptDetail(int attemptId) async =>
      const PracticeTestAttemptDetail(
        attempt: PracticeTestAttempt(
            id: 99, testId: 1, studentId: 42, status: 'completed'),
        studentName: 'Ada Lovelace',
        items: [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Future<_Service> _open(
  WidgetTester tester, {
  PracticeTestAttempt? attempt,
  int seconds = 2,
}) async {
  final service = _Service(attempt: attempt, seconds: seconds);
  await tester.pumpWidget(MaterialApp(
    home: PracticeTestScreen(testId: 1, attempt: attempt, service: service),
  ));
  await tester.pumpAndSettle();
  return service;
}

/// Run a two-second module exactly past its limit: expiry on the second tick,
/// the automatic move on the third. Pumping further would burn the *next*
/// module's clock too.
Future<void> _runOutTheClock(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  // Flush the awaited saveProgress / completeAttempt chain.
  for (var i = 0; i < 3; i++) {
    await tester.pump();
  }
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('when a module clock runs out', () {
    testWidgets('R&W 1 moves on by itself', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _open(tester);
      expect(find.text('RW1 Q1'), findsOneWidget);

      await _runOutTheClock(tester);

      expect(service.moduleAdvances, contains(_rw2),
          reason: 'time is up: Bluebook moves the student on, it does not wait');
      expect(find.text('RW2 Q1'), findsOneWidget);
    });

    testWidgets('the section boundary still stops at the break',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _open(tester);

      await _runOutTheClock(tester); // R&W 1 -> R&W 2
      await _runOutTheClock(tester); // R&W 2 -> break

      expect(find.byKey(const Key('diagnostic-module-break')), findsOneWidget);
      expect(service.moduleAdvances, isNot(contains(_math1)),
          reason: 'an expired clock must not skip the between-section break');
    });

    testWidgets('the last module submits by itself', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _open(
        tester,
        attempt: PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: _math2,
          moduleStartedAt: clock.now(),
        ),
      );

      await _runOutTheClock(tester);

      expect(service.completeCalls, 1,
          reason: 'a test whose final clock expires must be submitted, not '
              'left unscored the way the stranded attempts were');
    });

    testWidgets('it submits once, not once per tick', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = await _open(
        tester,
        attempt: PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: _math2,
          moduleStartedAt: clock.now(),
        ),
      );

      await _runOutTheClock(tester);
      await _runOutTheClock(tester);

      expect(service.completeCalls, 1);
    });
  });

  group('resuming with a position that no longer fits', () {
    testWidgets('an unknown module falls back to the first one',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _open(
        tester,
        seconds: 3600,
        attempt: PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: 9999,
          moduleStartedAt: clock.now(),
        ),
      );

      expect(find.text('RW1 Q1'), findsOneWidget);
    });

    testWidgets('a null module falls back to the first one', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _open(
        tester,
        seconds: 3600,
        attempt: PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          moduleStartedAt: clock.now(),
        ),
      );

      expect(find.text('RW1 Q1'), findsOneWidget);
    });

    testWidgets('an unknown question falls back to the module start',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _open(
        tester,
        seconds: 3600,
        attempt: PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: _math1,
          currentQuestionId: 9999,
          moduleStartedAt: clock.now(),
        ),
      );

      expect(find.text('Math1 Q1'), findsOneWidget,
          reason: 'a deleted or foreign question id must not strand the student');
    });
  });
}
