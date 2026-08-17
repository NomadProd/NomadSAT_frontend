import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Utils/desmos_config.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/Utils/math_reference.dart';
import 'package:flutter_web/Widgets/diagnostic_module_break_view.dart';
import 'package:flutter_web/Widgets/diagnostic_question_taking_view.dart';
import 'package:flutter_web/Widgets/diagnostic_timer_bar.dart';
import 'package:flutter_web/Widgets/math_reference_sheet_panel.dart';
import 'package:flutter_web/screens/student/diagnostic_results_screen.dart';

DiagnosticAttempt _completedAttempt() {
  return DiagnosticAttempt(
    id: 11,
    studentId: 7,
    startedAt: DateTime.utc(2026, 8, 15, 10),
    completedAt: DateTime.utc(2026, 8, 15, 10, 25),
    status: 'completed',
    rwScaledEstimate: 620,
    mathScaledEstimate: 680,
    totalPointEstimate: 1300,
    totalRangeLow: 1220,
    totalRangeHigh: 1380,
  );
}

void main() {
  test('layout has 20 slots and 50 points per section', () {
    expect(kDiagnosticLayout, hasLength(20));
    final rw = kDiagnosticLayout.where((slot) => !slot.isMath);
    final math = kDiagnosticLayout.where((slot) => slot.isMath);
    expect(rw, hasLength(10));
    expect(math, hasLength(10));
    expect(rw.fold<int>(0, (sum, slot) => sum + slot.points), 50);
    expect(math.fold<int>(0, (sum, slot) => sum + slot.points), 50);
  });

  test('rejects mismatched difficulty and points', () {
    expect(
      diagnosticLayoutMismatch(
        orderIndex: 3,
        section: 'reading_writing',
        domain: 'Craft and Structure',
        difficulty: 'hard',
        points: 3,
      ),
      isNotNull,
    );
  });

  test('section timer counts down and hits zero', () {
    final started = DateTime.utc(2026, 8, 15, 12);
    expect(
      diagnosticSectionRemaining(
        now: started,
        sectionStartedAt: started,
        isMath: false,
      ),
      const Duration(minutes: 12),
    );
    expect(
      diagnosticSectionRemaining(
        now: started.add(const Duration(minutes: 12)),
        sectionStartedAt: started,
        isMath: false,
      ),
      Duration.zero,
    );
    expect(
      diagnosticSectionRemaining(
        now: started.add(const Duration(minutes: 5)),
        sectionStartedAt: started,
        isMath: true,
      ),
      const Duration(minutes: 10),
    );
    expect(formatDiagnosticCountdown(const Duration(minutes: 12)), '12:00');
    expect(formatDiagnosticCountdown(const Duration(seconds: 9)), '00:09');
  });

  test('question bank access is role-gated', () {
    expect(canManageDiagnosticBank('admin'), isTrue);
    expect(canManageDiagnosticBank('mentor'), isTrue);
    expect(canManageDiagnosticBank('teacher'), isFalse);
    expect(canManageDiagnosticBank('student'), isFalse);
    expect(canViewDiagnosticBank('teacher'), isTrue);
    expect(canViewDiagnosticBank('student'), isFalse);
  });

  testWidgets('results screen shows score range and disclaimer', (tester) async {
    var retakeCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiagnosticResultsView(
            attempt: _completedAttempt(),
            onRetake: () => retakeCount += 1,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('diagnostic-score-range')), findsOneWidget);
    expect(find.text('1220–1380'), findsOneWidget);
    expect(find.byKey(const Key('diagnostic-disclaimer')), findsOneWidget);
    expect(find.text(kDiagnosticScoreDisclaimer), findsOneWidget);
    expect(find.text('620'), findsOneWidget);
    expect(find.text('680'), findsOneWidget);

    await tester.tap(find.text('Retake test'));
    expect(retakeCount, 1);
  });

  testWidgets('results and timer fit mobile and desktop', (tester) async {
    Future<void> pumpAt(Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DiagnosticTimerBar(
                  remaining: const Duration(minutes: 11, seconds: 40),
                  isMath: false,
                ),
                Expanded(
                  child: DiagnosticResultsView(
                    attempt: _completedAttempt(),
                    onRetake: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpAt(const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('11:40'), findsOneWidget);
    expect(find.text('Reading & Writing'), findsWidgets);

    await pumpAt(const Size(1280, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('1220–1380'), findsOneWidget);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  test('retaking keeps previous completed attempts in history', () {
    final previous = _completedAttempt();
    final next = DiagnosticAttempt(
      id: 12,
      studentId: previous.studentId,
      startedAt: previous.startedAt.add(const Duration(days: 1)),
      status: 'in_progress',
    );
    expect(previous.id, isNot(next.id));
    expect(previous.isCompleted, isTrue);
    expect(next.isInProgress, isTrue);
  });

  testWidgets('teacher bank view is read-only and students are blocked', (tester) async {
    Widget bankFor(String role) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              if (!canViewDiagnosticBank(role)) {
                return const Text('You do not have access to the diagnostic question bank.');
              }
              return Column(
                children: [
                  if (canManageDiagnosticBank(role)) const Text('Edit'),
                  if (canManageDiagnosticBank(role)) const Text('Add'),
                  if (!canManageDiagnosticBank(role))
                    const Text('Reading & Writing'),
                ],
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(bankFor('student'));
    expect(find.text('You do not have access to the diagnostic question bank.'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    await tester.pumpWidget(bankFor('teacher'));
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Reading & Writing'), findsOneWidget);

    await tester.pumpWidget(bankFor('admin'));
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);

    await tester.pumpWidget(bankFor('mentor'));
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('calculator and reference are math-only', (tester) async {
    await tester.pumpWidget(
      _TakingHarness(
        question: _question(math: false, order: 10),
        remaining: const Duration(minutes: 4),
      ),
    );
    expect(find.byKey(const Key('diagnostic-calculator-button')), findsNothing);
    expect(find.byKey(const Key('diagnostic-reference-button')), findsNothing);
    expect(find.text('Reading stem'), findsOneWidget);

    await tester.pumpWidget(
      _TakingHarness(
        question: _question(math: true, order: 11),
        remaining: const Duration(minutes: 15),
        showHint: true,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('diagnostic-calculator-button')), findsOneWidget);
    expect(find.byKey(const Key('diagnostic-reference-button')), findsOneWidget);
    expect(find.byKey(const Key('diagnostic-math-tools-hint')), findsOneWidget);
    expect(find.text(kDesmosCalculatorHint), findsOneWidget);
    expect(find.text('Math stem'), findsOneWidget);
  });

  testWidgets('toggling calculator does not change the timer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _TakingHarness(
        question: _question(math: true, order: 11),
        remaining: const Duration(minutes: 12, seconds: 5),
      ),
    );
    expect(find.text('12:05'), findsOneWidget);
    await tester.tap(find.byKey(const Key('diagnostic-calculator-button')));
    await tester.pump();
    expect(find.text('12:05'), findsOneWidget);
    expect(find.text('Graphing Calculator'), findsOneWidget);
    expect(find.text('Math stem'), findsOneWidget);
    await tester.tap(find.byKey(const Key('desmos-calculator-close')));
    await tester.pump();
    expect(find.text('12:05'), findsOneWidget);
    expect(find.text('Graphing Calculator'), findsNothing);
    expect(find.text('Math stem'), findsOneWidget);
  });

  testWidgets('toggling reference does not change the timer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _TakingHarness(
        question: _question(math: true, order: 12),
        remaining: const Duration(minutes: 9, seconds: 40),
      ),
    );
    expect(find.text('09:40'), findsOneWidget);
    await tester.tap(find.byKey(const Key('diagnostic-reference-button')));
    await tester.pumpAndSettle();
    expect(find.text('09:40'), findsOneWidget);
    expect(find.byKey(const Key('math-reference-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('math-reference-close')));
    await tester.pumpAndSettle();
    expect(find.text('09:40'), findsOneWidget);
    expect(find.byKey(const Key('math-reference-sheet')), findsNothing);
  });

  testWidgets('reference sheet lists the official formulas only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MathReferenceSheetPanel())),
    );
    expect(kMathReferenceItems, hasLength(15));
    expect(find.byKey(const Key('math-reference-sheet')), findsOneWidget);
    expect(find.image(const AssetImage(kMathReferenceAsset)), findsOneWidget);
    expect(find.text('Math Reference'), findsOneWidget);
    expect(find.textContaining('quadratic'), findsNothing);
    expect(find.textContaining('logarithm'), findsNothing);
    expect(find.textContaining('sin'), findsNothing);
  });

  testWidgets('math tools layout works on mobile and desktop', (tester) async {
    Future<void> pumpAt(Size size, {required bool calculatorOpen}) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _TakingHarness(
          question: _question(math: true, order: 11),
          remaining: const Duration(minutes: 10),
          calculatorOpen: calculatorOpen,
        ),
      );
      await tester.pump();
    }

    await pumpAt(const Size(390, 844), calculatorOpen: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Graphing Calculator'), findsOneWidget);

    await pumpAt(const Size(1280, 800), calculatorOpen: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Math stem'), findsOneWidget);
    expect(find.text('Graphing Calculator'), findsOneWidget);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('calculator window can be dragged and resized', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _TakingHarness(
        question: _question(math: true, order: 11),
        remaining: const Duration(minutes: 10),
        calculatorOpen: true,
      ),
    );
    await tester.pump();

    final window = find.byKey(const Key('desmos-calculator-window'));
    final start = tester.getTopLeft(window);
    final startSize = tester.getSize(window);

    await tester.drag(
      find.byKey(const Key('desmos-calculator-drag-handle')),
      const Offset(80, 50),
    );
    await tester.pump();
    expect(tester.getTopLeft(window), start + const Offset(80, 50));

    await tester.drag(
      find.byKey(const Key('desmos-calculator-resize-handle')),
      const Offset(60, 40),
    );
    await tester.pump();
    final resized = tester.getSize(window);
    expect(resized.width, closeTo(startSize.width + 60, 0.5));
    expect(resized.height, closeTo(startSize.height + 40, 0.5));
    expect(find.text('Math stem'), findsOneWidget);
  });

  testWidgets('back button and question list stay in the current module', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final questions = [
      _question(math: false, order: 1),
      _question(math: false, order: 2),
      _question(math: false, order: 3),
    ];
    await tester.pumpWidget(
      _TakingHarness(
        question: questions[1],
        remaining: const Duration(minutes: 8),
        sectionQuestions: questions,
        answeredQuestionIds: {questions[0].id},
        canGoBack: true,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('diagnostic-back-button')), findsOneWidget);
    expect(find.text('Question 2 of 3'), findsOneWidget);
    expect(find.byKey(const Key('diagnostic-question-list')), findsNothing);

    await tester.tap(find.byKey(const Key('diagnostic-question-index-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('diagnostic-question-list')), findsOneWidget);
    expect(find.text('Reading & Writing Questions'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Unanswered'), findsOneWidget);
    expect(find.byKey(const Key('diagnostic-question-nav-item-1')), findsOneWidget);
    expect(find.byKey(const Key('diagnostic-question-nav-item-3')), findsOneWidget);
    expect(find.text('Math'), findsNothing);
  });

  testWidgets('module break starts math separately', (tester) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiagnosticModuleBreakView(onStartMath: () => started = true),
        ),
      ),
    );
    expect(find.byKey(const Key('diagnostic-module-break')), findsOneWidget);
    expect(find.text('Reading & Writing complete'), findsOneWidget);
    expect(find.textContaining('15-minute timer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('diagnostic-start-math-button')));
    expect(started, isTrue);
  });

  test('resume with math start skips break and restores that question', () {
    final questions = [
      _question(math: false, order: 1),
      _question(math: false, order: 2),
      _question(math: true, order: 11),
      _question(math: true, order: 12),
    ];
    final mathStarted = DateTime.utc(2026, 8, 17, 9, 10);
    final resume = resolveDiagnosticResume(
      questions: questions,
      savedQuestionIds: {1, 2},
      startedAt: DateTime.utc(2026, 8, 17, 9),
      now: DateTime.utc(2026, 8, 17, 9, 12),
      mathStartedAt: mathStarted,
      currentQuestionId: 12,
    );
    expect(resume.showBreak, isFalse);
    expect(resume.inMath, isTrue);
    expect(resume.sectionStartedAt, mathStarted);
    expect(resume.questionIndex, 3);
  });

  test('resume mid reading restores the saved question not the first blank', () {
    final questions = [
      _question(math: false, order: 1),
      _question(math: false, order: 2),
      _question(math: false, order: 3),
      _question(math: true, order: 11),
    ];
    final started = DateTime.utc(2026, 8, 17, 9);
    final resume = resolveDiagnosticResume(
      questions: questions,
      savedQuestionIds: {1},
      startedAt: started,
      now: started.add(const Duration(minutes: 3)),
      currentQuestionId: 3,
    );
    expect(resume.showBreak, isFalse);
    expect(resume.inMath, isFalse);
    expect(resume.sectionStartedAt, started);
    expect(resume.questionIndex, 2);
  });

  test('resume without math start shows break after reading is done', () {
    final questions = [
      _question(math: false, order: 1),
      _question(math: true, order: 11),
    ];
    final resume = resolveDiagnosticResume(
      questions: questions,
      savedQuestionIds: {1},
      startedAt: DateTime.utc(2026, 8, 17, 9),
      now: DateTime.utc(2026, 8, 17, 9, 5),
    );
    expect(resume.showBreak, isTrue);
    expect(resume.inMath, isFalse);
    expect(resume.questionIndex, 1);
  });
}

DiagnosticQuestion _question({required bool math, int order = 1}) {
  return DiagnosticQuestion(
    id: order,
    section: math ? 'math' : 'reading_writing',
    domain: math ? 'Algebra' : 'Craft and Structure',
    difficulty: 'easy',
    orderIndex: order,
    questionText: math ? 'Math stem' : 'Reading stem',
    choices: const [
      DiagnosticChoice(key: 'A', text: 'One'),
      DiagnosticChoice(key: 'B', text: 'Two'),
    ],
  );
}

class _TakingHarness extends StatefulWidget {
  final DiagnosticQuestion question;
  final Duration remaining;
  final bool showHint;
  final bool calculatorOpen;
  final List<DiagnosticQuestion>? sectionQuestions;
  final Set<int> answeredQuestionIds;
  final bool canGoBack;

  const _TakingHarness({
    required this.question,
    required this.remaining,
    this.showHint = false,
    this.calculatorOpen = false,
    this.sectionQuestions,
    this.answeredQuestionIds = const {},
    this.canGoBack = false,
  });

  @override
  State<_TakingHarness> createState() => _TakingHarnessState();
}

class _TakingHarnessState extends State<_TakingHarness> {
  late bool calculatorOpen = widget.calculatorOpen;
  late bool showHint = widget.showHint;

  @override
  void didUpdateWidget(_TakingHarness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calculatorOpen != widget.calculatorOpen) {
      calculatorOpen = widget.calculatorOpen;
    }
    if (oldWidget.showHint != widget.showHint) {
      showHint = widget.showHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final isMath = question.isMath;
    final sectionQuestions = widget.sectionQuestions ?? [question];
    final sectionNumber = sectionQuestions.indexWhere((item) => item.id == question.id);
    return MaterialApp(
      home: Builder(
        builder: (dialogContext) {
          return Scaffold(
            body: DiagnosticQuestionTakingView(
              remaining: widget.remaining,
              isMath: isMath,
              sectionNumber: sectionNumber < 0 ? 1 : sectionNumber + 1,
              sectionQuestionCount: sectionQuestions.length,
              sectionQuestions: sectionQuestions,
              answeredQuestionIds: widget.answeredQuestionIds,
              question: question,
              selectedChoice: null,
              completing: false,
              calculatorOpen: calculatorOpen,
              showMathToolsHint: showHint,
              canGoBack: widget.canGoBack,
              onSelect: (_) {},
              onBack: () {},
              onNext: () {},
              onJumpToQuestion: (_) {},
              onLeave: () {},
              onToggleCalculator: () {
                setState(() => calculatorOpen = !calculatorOpen);
              },
              onOpenReference: () {
                showMathReferenceSheet(dialogContext);
              },
              onDismissHint: () {
                setState(() => showHint = false);
              },
            ),
          );
        },
      ),
    );
  }
}
