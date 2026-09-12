// Regression tests for the three reported practice-test bugs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/Widgets/exam_question_taking_view.dart';
import 'package:flutter_web/screens/shared/practice_test_review_screen.dart';
import 'package:flutter_web/screens/student/practice_test_screen.dart';

/// Real SAT Standard-English questions all share one stem; only the passage
/// differs. Mirrors module 3 of test 1, whose questions 16-22 are like this.
ExamQuestion _sharedStem(int id, int order, String passage) => ExamQuestion(
      id: id,
      moduleId: 10,
      orderIndex: order,
      isMath: false,
      domain: 'Standard English Conventions',
      passageText: passage,
      questionText:
          'Which choice completes the text so that it conforms to the '
          'conventions of Standard English?',
      choices: const [
        ExamChoice(key: 'A', text: 'has been'),
        ExamChoice(key: 'B', text: 'have been'),
      ],
    );

final _stemTwins = [
  _sharedStem(60, 1, 'The archaeologist unearthed a bronze cauldron.'),
  _sharedStem(61, 2, 'Migrating cranes navigate by the Earth magnetic field.'),
  _sharedStem(62, 3, 'The printing press reshaped how knowledge travelled.'),
];

PracticeTestInfo _oneModuleTest() => const PracticeTestInfo(
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
          requiredQuestionCount: 3,
          questionCount: 3,
        ),
      ],
    );

class _Service implements PracticeTestService {
  _Service({this.completeError, this.detailError});

  final Object? completeError;
  final Object? detailError;
  int completeCalls = 0;

  @override
  Future<PracticeTestInfo> fetchTest(int testId) async => _oneModuleTest();

  @override
  Future<PracticeTestAttempt> startAttempt(int testId) async =>
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress',
          currentModuleId: 10);

  @override
  Future<List<ExamQuestion>> fetchAttemptQuestions(int attemptId) async =>
      _stemTwins;

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
      const PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'in_progress');

  @override
  Future<PracticeTestAttempt> completeAttempt(int attemptId) async {
    completeCalls += 1;
    if (completeError != null) throw completeError!;
    return const PracticeTestAttempt(
        id: 99, testId: 1, studentId: 42, status: 'completed',
        totalScaled: 1300);
  }

  @override
  Future<PracticeTestAttemptDetail> fetchAttemptDetail(int attemptId) async {
    if (detailError != null) throw detailError!;
    return const PracticeTestAttemptDetail(
      attempt: PracticeTestAttempt(
          id: 99, testId: 1, studentId: 42, status: 'completed'),
      studentName: 'Ada Lovelace',
      items: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Future<void> _startTest(WidgetTester tester, _Service service) async {
  await tester.pumpWidget(MaterialApp(
    home: PracticeTestScreen(testId: 1, service: service),
  ));
  await tester.pumpAndSettle();
}

Future<void> _answerAndNext(WidgetTester tester) async {
  await tester.tap(find.text('has been').first);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('diagnostic-next-button')));
  await tester.pumpAndSettle();
}

void main() {
  // --- Bug 1: questions that look repeated -------------------------------

  for (final size in [const Size(1280, 900), const Size(420, 850)])
    testWidgets(
        'questions sharing one stem still show their own passage (${size.width.toInt()}px)',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _startTest(tester, _Service());

      for (final question in _stemTwins) {
        expect(
          find.textContaining(question.passageText!),
          findsOneWidget,
          reason: 'question ${question.orderIndex} did not show its passage, '
              'so it is indistinguishable from its neighbours',
        );
        if (question != _stemTwins.last) await _answerAndNext(tester);
      }
    });

  // --- Bug 2: the student cannot finish ----------------------------------

  testWidgets('a failed submit tells the student something went wrong',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _Service(
      completeError: ApiException('Server error', statusCode: 500),
    );
    await _startTest(tester, service);

    for (var i = 0; i < _stemTwins.length - 1; i++) {
      await _answerAndNext(tester);
    }
    await tester.tap(find.text('has been').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diagnostic-next-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit test'));
    await tester.pumpAndSettle();

    expect(service.completeCalls, 1);
    expect(
      find.textContaining(RegExp('error|failed|try again', caseSensitive: false)),
      findsWidgets,
      reason: 'submit failed but the screen said nothing, so the student is '
          'left tapping a button that appears to do nothing',
    );
  });

  testWidgets('the submit button stays usable after a failed submit',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _Service(
      completeError: ApiException('Server error', statusCode: 500),
    );
    await _startTest(tester, service);
    for (var i = 0; i < _stemTwins.length - 1; i++) {
      await _answerAndNext(tester);
    }
    await tester.tap(find.text('has been').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('diagnostic-next-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit test'));
    await tester.pumpAndSettle();

    expect(service.completeCalls, 2,
        reason: 'the student must be able to retry a failed submit');
  });

  // --- Bug 3: review access ----------------------------------------------

  testWidgets('an unfinished attempt explains itself instead of "Access denied"',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: PracticeTestReviewScreen(
        attemptId: 99,
        service: _Service(
          detailError: ApiException(
            'Review is only available for completed attempts',
            statusCode: 409,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Access denied'), findsNothing);
    expect(find.textContaining('completed'), findsWidgets);
  });
}
