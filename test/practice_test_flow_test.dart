import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/student/practice_test_list_screen.dart';

/// Four modules, two questions each, so a full run fits in a widget test. The
/// shape of the flow is what matters here, not the official 27/27/22/22 counts.
PracticeTestInfo _test() => const PracticeTestInfo(
      id: 1,
      title: 'Practice Test 1',
      visible: true,
      isPublishable: true,
      classIds: [1],
      modules: [
        PracticeTestModuleInfo(
          id: 10,
          name: 'Reading & Writing 1',
          section: 'reading_writing',
          orderIndex: 1,
          timeLimitSeconds: 1920,
          requiredQuestionCount: 2,
          questionCount: 2,
        ),
        PracticeTestModuleInfo(
          id: 11,
          name: 'Reading & Writing 2',
          section: 'reading_writing',
          orderIndex: 2,
          timeLimitSeconds: 1920,
          requiredQuestionCount: 2,
          questionCount: 2,
        ),
        PracticeTestModuleInfo(
          id: 20,
          name: 'Math 1',
          section: 'math',
          orderIndex: 3,
          timeLimitSeconds: 2100,
          requiredQuestionCount: 2,
          questionCount: 2,
        ),
        PracticeTestModuleInfo(
          id: 21,
          name: 'Math 2',
          section: 'math',
          orderIndex: 4,
          timeLimitSeconds: 2100,
          requiredQuestionCount: 2,
          questionCount: 2,
        ),
      ],
    );

ExamQuestion _mcq(int id, int moduleId, bool isMath, String stem) => ExamQuestion(
      id: id,
      moduleId: moduleId,
      orderIndex: id.isOdd ? 1 : 2,
      isMath: isMath,
      domain: isMath ? 'Algebra' : 'Craft and Structure',
      questionText: stem,
      choices: [
        ExamChoice(key: 'A', text: '$stem A'),
        ExamChoice(key: 'B', text: '$stem B'),
      ],
    );

List<ExamQuestion> _questions() => [
      _mcq(1, 10, false, 'RW1 one'),
      _mcq(2, 10, false, 'RW1 two'),
      _mcq(3, 11, false, 'RW2 one'),
      _mcq(4, 11, false, 'RW2 two'),
      _mcq(5, 20, true, 'Math1 one'),
      _mcq(6, 20, true, 'Math1 two'),
      _mcq(7, 21, true, 'Math2 one'),
      const ExamQuestion(
        id: 8,
        moduleId: 21,
        orderIndex: 2,
        isMath: true,
        domain: 'Advanced Math',
        questionText: 'Math2 grid-in',
        answerType: ExamAnswerType.gridIn,
      ),
    ];

class _FakeService implements PracticeTestService {
  final List<PracticeTestAttempt> attempts;
  final List<({int questionId, String? choice, String? response})> submitted =
      [];
  final List<int> moduleAdvances = [];
  bool completed = false;

  _FakeService({this.attempts = const []});

  @override
  Future<List<PracticeTestInfo>> fetchTests() async => [_test()];

  @override
  Future<PracticeTestInfo> fetchTest(int testId) async => _test();

  @override
  Future<List<PracticeTestAttempt>> fetchMyAttempts() async => attempts;

  @override
  Future<PracticeTestAttempt> startAttempt(int testId) async =>
      const PracticeTestAttempt(
        id: 99,
        testId: 1,
        studentId: 42,
        status: 'in_progress',
        currentModuleId: 10,
      );

  @override
  Future<List<ExamQuestion>> fetchAttemptQuestions(int attemptId) async =>
      _questions();

  @override
  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    String? selectedChoice,
    String? responseText,
  }) async {
    submitted.add((
      questionId: questionId,
      choice: selectedChoice,
      response: responseText,
    ));
  }

  @override
  Future<PracticeTestAttempt> saveProgress({
    required int attemptId,
    int? currentQuestionId,
    int? currentModuleId,
    bool? pauseTimer,
  }) async {
    if (currentModuleId != null) moduleAdvances.add(currentModuleId);
    return const PracticeTestAttempt(
      id: 99,
      testId: 1,
      studentId: 42,
      status: 'in_progress',
    );
  }

  @override
  Future<PracticeTestAttempt> completeAttempt(int attemptId) async {
    completed = true;
    return const PracticeTestAttempt(
      id: 99,
      testId: 1,
      studentId: 42,
      status: 'completed',
      rwRaw: 1,
      mathRaw: 2,
      rwScaled: 500,
      mathScaled: 800,
      totalScaled: 1300,
    );
  }

  @override
  Future<PracticeTestAttemptDetail> fetchAttemptDetail(int attemptId) async {
    return PracticeTestAttemptDetail(
      attempt: await completeAttempt(attemptId),
      studentName: 'Ada Lovelace',
      items: [
        const ExamReviewAnswer(
          orderIndex: 1,
          isMath: false,
          domain: 'Craft and Structure',
          difficulty: 'easy',
          questionText: 'Reading stem one',
          choices: [
            ExamChoice(key: 'A', text: 'RW one A'),
            ExamChoice(key: 'B', text: 'RW one B'),
          ],
          selectedChoice: 'A',
          correctChoice: 'B',
          isCorrect: false,
          explanation: 'B restates the claim.',
        ),
        const ExamReviewAnswer(
          orderIndex: 2,
          isMath: true,
          domain: 'Advanced Math',
          difficulty: 'easy',
          questionText: 'Math stem two',
          responseText: '2/3',
          correctAnswers: ['2/3'],
          isCorrect: true,
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Widget _app(_FakeService service) => MaterialApp(
      home: StudentPracticeTestListScreen(service: service),
    );

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a student runs all four modules, submits, and sees the review',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = _FakeService();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('Practice Test 1'), findsOneWidget);
    expect(
      find.byKey(const Key('student-practice-state-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('student-practice-card-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice-confirm-start')));
    await tester.pumpAndSettle();

    // Reading & Writing module 1.
    expect(find.text('RW1 one'), findsOneWidget);
    await _tapText(tester, 'RW1 one B');
    await _tapText(tester, 'Next');
    expect(find.text('RW1 two'), findsOneWidget);
    await _tapText(tester, 'RW1 two A');
    await _tapText(tester, 'Next');

    // Its review offers the next module by name, never "End test".
    expect(find.text('Module Complete!'), findsOneWidget);
    expect(find.text('End test'), findsNothing);
    await _tapText(tester, 'Continue to Reading & Writing 2');
    expect(find.text('Reading & Writing 1 complete'), findsOneWidget);
    await _tapText(tester, 'Start Reading & Writing 2');
    expect(service.moduleAdvances, [11]);

    // Reading & Writing module 2 — a different question list, not a repeat.
    expect(find.text('RW2 one'), findsOneWidget);
    await _tapText(tester, 'RW2 one B');
    await _tapText(tester, 'Next');
    await _tapText(tester, 'RW2 two B');
    await _tapText(tester, 'Next');
    await _tapText(tester, 'Continue to Math 1');
    expect(find.text('Math 1: 2 questions, 35 minutes'), findsOneWidget);
    await _tapText(tester, 'Start Math 1');

    // Math module 1.
    await _tapText(tester, 'Math1 one B');
    await _tapText(tester, 'Next');
    await _tapText(tester, 'Math1 two B');
    await _tapText(tester, 'Next');
    await _tapText(tester, 'Continue to Math 2');
    await _tapText(tester, 'Start Math 2');

    // Math module 2, including the grid-in question.
    await _tapText(tester, 'Math2 one B');
    await _tapText(tester, 'Next');
    await tester.enterText(find.byKey(const Key('exam-grid-in-field')), '2/3');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Next');

    // Only the last module offers to submit.
    expect(find.text('Submit test'), findsOneWidget);
    await _tapText(tester, 'Submit test');

    expect(service.completed, isTrue);
    expect(find.text('Practice test review'), findsOneWidget);
    expect(find.text('1300'), findsWidgets);
    expect(find.text('B restates the claim.'), findsOneWidget);
  });

  testWidgets('the grid-in answer is sent as typed text, not a choice',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = _FakeService();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student-practice-card-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice-confirm-start')));
    await tester.pumpAndSettle();

    await _tapText(tester, 'RW1 one B');

    final mcq = service.submitted.single;
    expect(mcq.choice, 'B');
    expect(mcq.response, isNull);
  });

  testWidgets('a test already taken opens the review, never a retake',
      (tester) async {
    final service = _FakeService(
      attempts: const [
        PracticeTestAttempt(
          id: 99,
          testId: 1,
          studentId: 42,
          status: 'completed',
          totalScaled: 1300,
        ),
      ],
    );
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('student-practice-score-1')), findsOneWidget);
    expect(find.text('View your result'), findsOneWidget);

    await tester.tap(find.byKey(const Key('student-practice-card-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('practice-confirm-start')), findsNothing);
    expect(find.text('Practice test review'), findsOneWidget);
  });

  testWidgets('an empty list explains why', (tester) async {
    final service = _EmptyService();
    await tester.pumpWidget(
      MaterialApp(home: StudentPracticeTestListScreen(service: service)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('student-practice-empty')), findsOneWidget);
  });
}

class _EmptyService extends _FakeService {
  @override
  Future<List<PracticeTestInfo>> fetchTests() async => [];
}
