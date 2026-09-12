// Leaving a practice test and coming back must resume it, not lock you out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/student/practice_test_list_screen.dart';

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
          requiredQuestionCount: 3, questionCount: 3,
        ),
        PracticeTestModuleInfo(
          id: _rw2, name: 'Reading & Writing 2', section: 'reading_writing',
          orderIndex: 2, timeLimitSeconds: 1920,
          requiredQuestionCount: 3, questionCount: 3,
        ),
        PracticeTestModuleInfo(
          id: _math1, name: 'Math 1', section: 'math',
          orderIndex: 3, timeLimitSeconds: 2100,
          requiredQuestionCount: 3, questionCount: 3,
        ),
        PracticeTestModuleInfo(
          id: _math2, name: 'Math 2', section: 'math',
          orderIndex: 4, timeLimitSeconds: 2100,
          requiredQuestionCount: 3, questionCount: 3,
        ),
      ],
    );

ExamQuestion _q(int id, int moduleId, int order, bool isMath, String stem) =>
    ExamQuestion(
      id: id,
      moduleId: moduleId,
      orderIndex: order,
      isMath: isMath,
      domain: isMath ? 'Algebra' : 'Craft and Structure',
      questionText: stem,
      choices: const [
        ExamChoice(key: 'A', text: 'Choice A'),
        ExamChoice(key: 'B', text: 'Choice B'),
      ],
    );

/// ids 1-3 in R&W 1, 4-6 in R&W 2, 7-9 in Math 1, 10-12 in Math 2.
List<ExamQuestion> _questions() => [
      for (var i = 0; i < 3; i++) _q(1 + i, _rw1, i + 1, false, 'RW1 Q${i + 1}'),
      for (var i = 0; i < 3; i++) _q(4 + i, _rw2, i + 1, false, 'RW2 Q${i + 1}'),
      for (var i = 0; i < 3; i++) _q(7 + i, _math1, i + 1, true, 'Math1 Q${i + 1}'),
      for (var i = 0; i < 3; i++) _q(10 + i, _math2, i + 1, true, 'Math2 Q${i + 1}'),
    ];

class _Service implements PracticeTestService {
  _Service({required this.attempt});

  final PracticeTestAttempt? attempt;
  int startCalls = 0;

  @override
  Future<List<PracticeTestInfo>> fetchTests() async => [_test()];

  @override
  Future<PracticeTestInfo> fetchTest(int testId) async => _test();

  @override
  Future<List<PracticeTestAttempt>> fetchMyAttempts() async =>
      attempt == null ? [] : [attempt!];

  @override
  Future<PracticeTestAttempt> fetchAttempt(int attemptId) async => attempt!;

  @override
  Future<PracticeTestAttempt> startAttempt(int testId) async {
    startCalls += 1;
    return const PracticeTestAttempt(
        id: 99, testId: 1, studentId: 42, status: 'in_progress',
        currentModuleId: _rw1);
  }

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
  }) async =>
      attempt ??
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress');

  @override
  Future<PracticeTestAttempt> completeAttempt(int attemptId) async =>
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'completed');

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

PracticeTestAttempt _inProgress({
  int? currentModuleId = _rw1,
  int? currentQuestionId,
  Map<int, String> answers = const {},
  DateTime? moduleStartedAt,
}) =>
    PracticeTestAttempt(
      id: 99,
      testId: 1,
      studentId: 42,
      status: 'in_progress',
      currentModuleId: currentModuleId,
      currentQuestionId: currentQuestionId,
      moduleStartedAt: moduleStartedAt ?? DateTime.now(),
      answers: answers,
    );

Future<_Service> _openTest(
  WidgetTester tester,
  PracticeTestAttempt? attempt,
) async {
  final service = _Service(attempt: attempt);
  await tester.pumpWidget(
    MaterialApp(home: StudentPracticeTestListScreen(service: service)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('student-practice-card-1')));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('an in-progress attempt reopens the test, not the review',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openTest(tester, _inProgress());

    expect(find.text('Not available yet'), findsNothing);
    expect(find.text('Access denied'), findsNothing);
    expect(find.text('RW1 Q1'), findsOneWidget,
        reason: 'the student must land back in their test');
  });

  testWidgets('a completed attempt still opens the review', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openTest(
      tester,
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'completed'),
    );

    expect(find.text('Practice test review'), findsOneWidget);
  });

  testWidgets('resuming does not start a second attempt', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = await _openTest(tester, _inProgress());

    expect(service.startCalls, 0,
        reason: 'starting again would 409: one attempt per test');
  });

  testWidgets('resuming restores the answers already given', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openTest(
      tester,
      _inProgress(answers: const {1: 'A', 2: 'B', 3: 'A'}),
    );

    // Walk to the module review without answering anything new.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('diagnostic-next-button')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('diagnostic-module-review')), findsOneWidget);
    expect(find.text('3/3 answered'), findsOneWidget,
        reason: 'answers already saved on the server must come back');
  });

  testWidgets('resuming lands on the saved module and question',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openTest(
      tester,
      _inProgress(currentModuleId: _math1, currentQuestionId: 8),
    );

    expect(find.text('Math1 Q2'), findsOneWidget);
    expect(find.text('Question 2 of 3'), findsOneWidget);
  });

  testWidgets('resuming a module whose time expired opens that module review',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _openTest(
      tester,
      _inProgress(
        currentModuleId: _math2,
        // Math 2 allows 35 minutes; this student left 40 minutes ago.
        moduleStartedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
    );

    expect(find.byKey(const Key('diagnostic-module-review')), findsOneWidget);
    expect(find.text('Submit test'), findsOneWidget,
        reason: 'a student whose clock ran out must still be able to submit');
  });
}
