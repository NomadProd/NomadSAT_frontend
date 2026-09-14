import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/Utils/practice_dashboard_stats.dart';
import 'package:flutter_web/screens/student/practice_test_list_screen.dart';

PracticeTestAttempt _attempt({
  required int id,
  int? test,
  String status = 'completed',
  DateTime? completedAt,
  int? total,
  int? rw,
  int? math,
  String? title,
}) =>
    PracticeTestAttempt(
      id: id,
      testId: test ?? id,
      studentId: 1,
      status: status,
      testTitle: title,
      completedAt: completedAt,
      rwScaled: rw,
      mathScaled: math,
      totalScaled: total,
    );

ExamReviewAnswer _answer({
  required bool isMath,
  required String domain,
  required bool correct,
}) =>
    ExamReviewAnswer(
      orderIndex: 1,
      isMath: isMath,
      domain: domain,
      difficulty: 'medium',
      questionText: 'stem',
      isCorrect: correct,
    );

String? _textAt(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data;

void main() {
  group('buildPracticeDashboardStats', () {
    test('is empty until an attempt is completed', () {
      final stats = buildPracticeDashboardStats(
        attempts: [_attempt(id: 1, status: 'in_progress', total: 1200)],
        answers: const [],
      );
      expect(stats.isEmpty, isTrue);
      expect(stats.delta, isNull);
    });

    test('takes the latest completed attempt by date, not by list order', () {
      final stats = buildPracticeDashboardStats(
        attempts: [
          _attempt(
            id: 2,
            completedAt: DateTime(2026, 3, 1),
            total: 1400,
            rw: 700,
            math: 700,
            title: 'Test B',
          ),
          _attempt(id: 1, completedAt: DateTime(2026, 1, 1), total: 1200),
        ],
        answers: const [],
      );
      expect(stats.latestTotal, 1400);
      expect(stats.previousTotal, 1200);
      expect(stats.delta, 200);
      expect(stats.latestRwScaled, 700);
      expect(stats.latestTestTitle, 'Test B');
    });

    test('an unfinished attempt never becomes the previous score', () {
      final stats = buildPracticeDashboardStats(
        attempts: [
          _attempt(id: 1, completedAt: DateTime(2026, 1, 1), total: 1200),
          _attempt(id: 2, status: 'in_progress', total: 1500),
        ],
        answers: const [],
      );
      expect(stats.latestTotal, 1200);
      expect(stats.previousTotal, isNull);
      expect(stats.delta, isNull);
    });

    test('pools domain accuracy across every attempt, in report order', () {
      final stats = buildPracticeDashboardStats(
        attempts: [_attempt(id: 1, total: 1200)],
        answers: [
          // Two attempts' worth of the same domain must add up, not replace.
          _answer(isMath: false, domain: 'Information and Ideas', correct: true),
          _answer(isMath: false, domain: 'Information and Ideas', correct: false),
          _answer(isMath: false, domain: 'Craft and Structure', correct: true),
          _answer(isMath: true, domain: 'Algebra', correct: false),
        ],
      );
      expect(
        stats.rwMastery.map((m) => m.domain),
        // kRwDomains order, not first-seen order.
        ['Craft and Structure', 'Information and Ideas'],
      );
      final ideas = stats.rwMastery.last;
      expect(ideas.correct, 1);
      expect(ideas.total, 2);
      expect(ideas.accuracy, 0.5);
      expect(stats.mathMastery.single.domain, 'Algebra');
      expect(stats.mathMastery.single.correct, 0);
    });

    test('keeps a domain the report order does not know about', () {
      final stats = buildPracticeDashboardStats(
        attempts: [_attempt(id: 1, total: 1200)],
        answers: [_answer(isMath: true, domain: 'Trigonometry', correct: true)],
      );
      expect(stats.mathMastery.single.domain, 'Trigonometry');
    });
  });

  group('which attempt counts', () {
    test('mastery reads one attempt per test, the latest', () {
      final latest = latestCompletedPerTest([
        _attempt(id: 53, test: 2, completedAt: DateTime(2026, 3, 3)),
        _attempt(id: 41, test: 2, completedAt: DateTime(2026, 3, 1)),
        _attempt(id: 30, test: 1, completedAt: DateTime(2026, 2, 1)),
        _attempt(id: 60, test: 2, status: 'in_progress'),
      ]);
      expect(latest.map((a) => a.id).toSet(), {53, 30});
    });
  });

  group('dashboard rendering', () {
    testWidgets('shows scores and mastery once a test is finished',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudentPracticeTestListScreen(service: _FakeService()),
        ),
      );
      await tester.pumpAndSettle();

      // By key, not by text: the card's score pill says 1300 as well.
      expect(_textAt(tester, 'practice-dashboard-total'), '1300');
      expect(find.byKey(const Key('practice-dashboard-rw')), findsOneWidget);
      expect(
        find.byKey(const Key('practice-mastery-Algebra')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('practice-dashboard-empty')), findsNothing);
    });

    testWidgets('falls back to the list alone with no finished attempt',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudentPracticeTestListScreen(
            service: _FakeService(attempts: const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('practice-dashboard-empty')), findsOneWidget);
      expect(find.byKey(const Key('practice-dashboard-total')), findsNothing);
      expect(find.byKey(const Key('student-practice-card-1')), findsOneWidget);
    });

    testWidgets('a domain with nothing right still draws its track',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: StudentPracticeTestListScreen(service: _FakeService())),
      );
      await tester.pumpAndSettle();

      // The track used to shrink-wrap to its fill, so a zero score rendered
      // nothing at all and read as a layout failure.
      final track = tester.getSize(
        find.byKey(const Key('practice-track-Geometry and Trigonometry')),
      );
      expect(track.width, greaterThan(100));
      expect(track.height, 8);
    });

    testWidgets('a finished test offers a retake', (tester) async {
      final service = _FakeService();
      await tester.pumpWidget(
        MaterialApp(home: StudentPracticeTestListScreen(service: service)),
      );
      await tester.pumpAndSettle();

      // The panels push the card below the fold in a test-sized viewport.
      await tester.scrollUntilVisible(
        find.byKey(const Key('student-practice-retake-1')),
        200,
      );
      await tester.pumpAndSettle();

      // The server keeps every attempt, so a finished test is not a dead end.
      await tester.tap(find.byKey(const Key('student-practice-retake-1')));
      await tester.pumpAndSettle();
      expect(find.text('Retake "Practice Test 1"?'), findsOneWidget);
    });

    testWidgets('one unreadable attempt does not blank the dashboard',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StudentPracticeTestListScreen(
            service: _FakeService(detailThrows: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scores come from the attempt list, so they survive; only the mastery
      // panel goes quiet.
      expect(_textAt(tester, 'practice-dashboard-total'), '1300');
      expect(find.byKey(const Key('practice-mastery-Algebra')), findsNothing);
    });
  });
}

class _FakeService implements PracticeTestService {
  final List<PracticeTestAttempt>? attempts;
  final bool detailThrows;

  _FakeService({this.attempts, this.detailThrows = false});

  @override
  Future<List<PracticeTestInfo>> fetchTests() async => const [
        PracticeTestInfo(
          id: 1,
          title: 'Practice Test 1',
          visible: true,
          isPublishable: true,
          classIds: [1],
          modules: [
            PracticeTestModuleInfo(
              id: 10,
              name: 'Math 1',
              section: 'math',
              orderIndex: 1,
              timeLimitSeconds: 2100,
              requiredQuestionCount: 2,
              questionCount: 2,
            ),
          ],
        ),
      ];

  @override
  Future<List<PracticeTestAttempt>> fetchMyAttempts() async =>
      attempts ??
      [_attempt(id: 1, completedAt: DateTime(2026, 2, 2), total: 1300, rw: 650, math: 650)];

  @override
  Future<PracticeTestAttemptDetail> fetchAttemptDetail(int attemptId) async {
    if (detailThrows) throw Exception('nope');
    return PracticeTestAttemptDetail(
      attempt: await fetchMyAttempts().then((list) => list.first),
      studentName: 'Ada Lovelace',
      items: [
        _answer(isMath: true, domain: 'Algebra', correct: true),
        // Nothing right in this domain: the bar must still be drawn.
        _answer(isMath: true, domain: 'Geometry and Trigonometry', correct: false),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
