// A finished practice test can be sat again, and the earlier score stays.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/student/practice_test_list_screen.dart';

PracticeTestInfo _test() => const PracticeTestInfo(
      id: 1,
      title: 'Practice Test 1',
      visible: true,
      isPublishable: true,
      classIds: [1],
      modules: [
        PracticeTestModuleInfo(
          id: 10, name: 'Reading & Writing 1', section: 'reading_writing',
          orderIndex: 1, timeLimitSeconds: 1920,
          requiredQuestionCount: 1, questionCount: 1,
        ),
      ],
    );

PracticeTestAttempt _attempt({
  required int id,
  required String status,
  int? score,
  DateTime? completedAt,
}) =>
    PracticeTestAttempt(
      id: id,
      testId: 1,
      studentId: 42,
      status: status,
      totalScaled: score,
      completedAt: completedAt,
      currentModuleId: 10,
    );

class _Service implements PracticeTestService {
  _Service(this.attempts);

  final List<PracticeTestAttempt> attempts;
  int startCalls = 0;

  @override
  Future<List<PracticeTestInfo>> fetchTests() async => [_test()];

  @override
  Future<PracticeTestInfo> fetchTest(int testId) async => _test();

  @override
  Future<List<PracticeTestAttempt>> fetchMyAttempts() async => attempts;

  @override
  Future<PracticeTestAttempt> startAttempt(int testId) async {
    startCalls += 1;
    return _attempt(id: 500, status: 'in_progress');
  }

  @override
  Future<PracticeTestAttempt> fetchAttempt(int attemptId) async =>
      attempts.firstWhere((a) => a.id == attemptId);

  @override
  Future<List<ExamQuestion>> fetchAttemptQuestions(int attemptId) async => const [
        ExamQuestion(
          id: 1, moduleId: 10, orderIndex: 1, isMath: false,
          domain: 'Craft and Structure', questionText: 'RW1 Q1',
          choices: [ExamChoice(key: 'A', text: 'Choice A')],
        ),
      ];

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
  }) async =>
      _attempt(id: attemptId, status: 'in_progress');

  @override
  Future<PracticeTestAttempt> completeAttempt(int attemptId) async =>
      _attempt(id: attemptId, status: 'completed', score: 1300);

  @override
  Future<PracticeTestAttemptDetail> fetchAttemptDetail(int attemptId) async =>
      PracticeTestAttemptDetail(
        attempt: attempts.firstWhere((a) => a.id == attemptId),
        studentName: 'Alizhan Turegeldiev',
        items: const [],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Future<_Service> _pump(
  WidgetTester tester,
  List<PracticeTestAttempt> attempts,
) async {
  final service = _Service(attempts);
  await tester.pumpWidget(
    MaterialApp(home: StudentPracticeTestListScreen(service: service)),
  );
  await tester.pumpAndSettle();
  return service;
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('a completed test still shows its score', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, [
      _attempt(id: 6, status: 'completed', score: 1231,
          completedAt: DateTime.utc(2026, 9, 12, 15, 9)),
    ]);

    expect(find.text('1231'), findsWidgets,
        reason: 'the earlier result must stay visible after a retake exists');
  });

  testWidgets('a completed test offers a retake', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = await _pump(tester, [
      _attempt(id: 6, status: 'completed', score: 1231,
          completedAt: DateTime.utc(2026, 9, 12, 15, 9)),
    ]);

    await tester.tap(find.byKey(const Key('student-practice-retake-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice-confirm-start')));
    await tester.pumpAndSettle();

    expect(service.startCalls, 1, reason: 'the retake must start a new attempt');
  });

  testWidgets('the best score is the headline when there are several',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, [
      _attempt(id: 6, status: 'completed', score: 1231,
          completedAt: DateTime.utc(2026, 9, 12, 15, 9)),
      _attempt(id: 7, status: 'completed', score: 1380,
          completedAt: DateTime.utc(2026, 9, 13, 10)),
    ]);

    expect(find.text('1380'), findsWidgets);
    expect(find.textContaining('2 attempts'), findsOneWidget,
        reason: 'the student should see that the earlier attempt is kept');
  });

  testWidgets('an attempt in progress is resumed, not retaken', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = await _pump(tester, [
      _attempt(id: 6, status: 'completed', score: 1231,
          completedAt: DateTime.utc(2026, 9, 12, 15, 9)),
      _attempt(id: 7, status: 'in_progress'),
    ]);

    expect(find.byKey(const Key('student-practice-retake-1')), findsNothing,
        reason: 'no retake while an attempt is still running');

    await tester.tap(find.byKey(const Key('student-practice-card-1')));
    await tester.pumpAndSettle();

    expect(service.startCalls, 0);
    expect(find.text('RW1 Q1'), findsOneWidget);
  });
}
