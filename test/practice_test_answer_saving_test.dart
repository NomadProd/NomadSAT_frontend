// Answers must reach the server exactly once, in order, and never be lost
// silently -- and a failed save must not stop the clock.
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/student/practice_test_screen.dart';

const _math = 20;

PracticeTestInfo _test() => const PracticeTestInfo(
      id: 1,
      title: 'Practice Test 1',
      visible: true,
      isPublishable: true,
      classIds: [1],
      modules: [
        PracticeTestModuleInfo(
          id: _math, name: 'Math 1', section: 'math',
          orderIndex: 1, timeLimitSeconds: 2100,
          requiredQuestionCount: 2, questionCount: 2,
        ),
      ],
    );

List<ExamQuestion> _questions() => const [
      ExamQuestion(
        id: 1, moduleId: _math, orderIndex: 1, isMath: true,
        domain: 'Algebra', questionText: 'Math Q1',
        answerType: ExamAnswerType.gridIn,
      ),
      ExamQuestion(
        id: 2, moduleId: _math, orderIndex: 2, isMath: true,
        domain: 'Algebra', questionText: 'Math Q2',
        choices: [
          ExamChoice(key: 'A', text: 'Choice A'),
          ExamChoice(key: 'B', text: 'Choice B'),
        ],
      ),
    ];

typedef Submitted = ({int questionId, String? choice, String? response});

class _Service implements PracticeTestService {
  _Service({this.failSubmitsBefore = 0, this.failPause = false});

  /// Throw from submitAnswer until this many calls have been made.
  final int failSubmitsBefore;
  final bool failPause;

  final List<Submitted> submitted = [];
  final List<bool> pauseCalls = [];
  final List<int> moduleAdvances = [];
  int submitAttempts = 0;
  int completeCalls = 0;
  bool completedAfterAllSubmits = false;

  @override
  Future<PracticeTestInfo> fetchTest(int testId) async => _test();

  @override
  Future<PracticeTestAttempt> startAttempt(int testId) async =>
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: _math);

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
    submitAttempts += 1;
    if (submitAttempts <= failSubmitsBefore) {
      throw Exception('network down');
    }
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
    if (pauseTimer != null) {
      pauseCalls.add(pauseTimer);
      if (failPause) throw Exception('pause failed');
    }
    if (currentModuleId != null) moduleAdvances.add(currentModuleId);
    return const PracticeTestAttempt(
        id: 99, testId: 1, studentId: 42, status: 'in_progress');
  }

  @override
  Future<PracticeTestAttempt> completeAttempt(int attemptId) async {
    completeCalls += 1;
    completedAfterAllSubmits = true;
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

Future<_Service> _open(WidgetTester tester, _Service service) async {
  await tester.pumpWidget(MaterialApp(
    home: PracticeTestScreen(testId: 1, service: service),
  ));
  await tester.pumpAndSettle();
  return service;
}

/// Let any debounce elapse and the queued saves drain.
Future<void> _settleSaves(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('typing a grid-in sends one request, not one per character',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _open(tester, _Service());

    await tester.enterText(find.byKey(const Key('exam-grid-in-field')), '2');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byKey(const Key('exam-grid-in-field')), '2/');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byKey(const Key('exam-grid-in-field')), '2/3');
    await _settleSaves(tester);

    expect(service.submitted.length, 1,
        reason: 'a request per keystroke is what races and loses answers');
    expect(service.submitted.single.response, '2/3',
        reason: 'the whole answer must be sent, never a truncated prefix');
  });

  testWidgets('answers are sent in the order they were given', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _open(tester, _Service());

    await tester.enterText(find.byKey(const Key('exam-grid-in-field')), '1/2');
    await _settleSaves(tester);
    await tester.tap(find.byKey(const Key('diagnostic-next-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choice B'));
    await _settleSaves(tester);

    expect(service.submitted.map((s) => s.questionId).toList(), [1, 2]);
  });

  testWidgets('an answer that failed to save is retried before submit',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _open(tester, _Service(failSubmitsBefore: 1));

    await tester.enterText(find.byKey(const Key('exam-grid-in-field')), '2/3');
    await _settleSaves(tester);
    expect(service.submitted, isEmpty, reason: 'the first save failed');

    await tester.tap(find.byKey(const Key('diagnostic-next-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choice B'));
    await _settleSaves(tester);
    await tester.tap(find.byKey(const Key('diagnostic-next-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit test'));
    await _settleSaves(tester);
    await tester.pumpAndSettle();

    expect(
      service.submitted.any((s) => s.response == '2/3'),
      isTrue,
      reason: 'submitting must re-send anything the server never took',
    );
    expect(service.completeCalls, 1);
  });

  testWidgets('an unsaved answer is shown to the student', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _open(tester, _Service(failSubmitsBefore: 99));

    await tester.enterText(find.byKey(const Key('exam-grid-in-field')), '2/3');
    await _settleSaves(tester);

    expect(find.byKey(const Key('practice-test-unsaved')), findsOneWidget,
        reason: 'silence is what let two exams lose answers unnoticed');
  });

  testWidgets('a failed pause does not freeze the clock', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = await _open(tester, _Service(failPause: true));

    final before = clock.now();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await _settleSaves(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settleSaves(tester);

    await tester.pump(const Duration(seconds: 5));
    expect(clock.now().isAfter(before), isTrue);
    expect(find.textContaining('34:'), findsWidgets,
        reason: 'the module clock must keep running when a pause call fails');
  });
}
