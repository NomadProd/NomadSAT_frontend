import 'dart:async';

import 'package:clock/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/Utils/exam_timer.dart';
import 'package:flutter_web/Widgets/exam_module_break_view.dart';
import 'package:flutter_web/Widgets/exam_module_review_view.dart';
import 'package:flutter_web/Widgets/exam_question_taking_view.dart';
import 'package:flutter_web/Widgets/math_reference_sheet_panel.dart';
import 'package:flutter_web/screens/shared/practice_test_review_screen.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

enum _Phase { taking, moduleReview, moduleBreak }

/// A thin wrapper over the shared exam widgets: one module at a time, its own
/// timer, a review list between modules, then submit.
class PracticeTestScreen extends StatefulWidget {
  final int testId;

  /// An attempt already underway, to resume instead of starting a new one.
  /// Starting a second attempt would 409: one attempt per test.
  final PracticeTestAttempt? attempt;

  /// Injectable so the flow can be driven in tests without a server.
  final PracticeTestService? service;

  const PracticeTestScreen({
    super.key,
    required this.testId,
    this.attempt,
    this.service,
  });

  @override
  State<PracticeTestScreen> createState() => _PracticeTestScreenState();
}

class _PracticeTestScreenState extends State<PracticeTestScreen> {
  late final _service = widget.service ?? PracticeTestService();

  PracticeTestInfo? _test;
  int? _attemptId;
  List<ExamQuestion> _questions = [];
  final Map<int, String> _answers = {};

  int _moduleIndex = 0;
  int _index = 0;
  _Phase _phase = _Phase.taking;
  DateTime? _moduleStartedAt;
  Duration _remaining = Duration.zero;
  Timer? _ticker;

  /// Seconds the student spent out of the test, mirrored from the server so the
  /// module clock does not run while they are away.
  int _pauseSeconds = 0;
  bool _paused = false;
  AppLifecycleListener? _lifecycle;

  bool _loading = true;
  bool _completing = false;
  bool _calculatorOpen = false;
  bool _showMathToolsHint = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Closing or hiding the tab is how students actually leave, not the button.
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(_setPaused(true)),
      onPause: () => unawaited(_setPaused(true)),
      onShow: () => unawaited(_setPaused(false)),
      onResume: () => unawaited(_setPaused(false)),
    );
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  /// Stop or restart the module clock, on the server and locally.
  Future<void> _setPaused(bool paused) async {
    final attemptId = _attemptId;
    if (attemptId == null || paused == _paused) return;
    _paused = paused;
    if (paused) {
      _ticker?.cancel();
    }
    try {
      final attempt = await _service.saveProgress(
        attemptId: attemptId,
        currentQuestionId: _questions.isEmpty ? null : _questions[_index].id,
        pauseTimer: paused,
      );
      if (!mounted) return;
      _pauseSeconds = attempt.timerPauseSeconds;
    } catch (_) {
      // A failed pause costs accurate time, never the test itself.
    }
    if (!paused && mounted) _resumeTicking();
  }

  void _resumeTicking() {
    _tick();
    _ticker?.cancel();
    if (_remaining > Duration.zero) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  PracticeTestModuleInfo get _module => _test!.modules[_moduleIndex];

  // By module, never by section: a section has two modules, and each one runs
  // on its own timer with its own question list.
  List<ExamQuestion> get _moduleQuestions =>
      _questions.where((q) => q.moduleId == _module.id).toList();

  bool get _isLastModule => _moduleIndex >= (_test?.modules.length ?? 1) - 1;

  Future<void> _start() async {
    try {
      final test = await _service.fetchTest(widget.testId);
      final resuming = widget.attempt;
      // Resume carries the saved answers; startAttempt would 409 here.
      var attempt = resuming == null
          ? await _service.startAttempt(widget.testId)
          : await _service.fetchAttempt(resuming.id);
      if (attempt.timerPausedAt != null) {
        // Coming back from a pause: bank the time away and restart the clock.
        final resumed = await _service.saveProgress(
          attemptId: attempt.id,
          currentQuestionId: attempt.currentQuestionId,
          pauseTimer: false,
        );
        _pauseSeconds = resumed.timerPauseSeconds;
      } else {
        _pauseSeconds = attempt.timerPauseSeconds;
      }
      final questions = await _service.fetchAttemptQuestions(attempt.id);
      if (!mounted) return;
      final moduleIndex = resuming == null
          ? 0
          : test.modules
              .indexWhere((module) => module.id == attempt.currentModuleId);
      setState(() {
        _test = test;
        _attemptId = attempt.id;
        _questions = questions;
        _moduleIndex = moduleIndex < 0 ? 0 : moduleIndex;
        _index = 0;
        _answers
          ..clear()
          ..addAll(attempt.answers);
        _loading = false;
        _showMathToolsHint = false;
      });
      _beginModule(
        resumeFrom: resuming == null ? null : attempt.moduleStartedAt,
        resumeQuestionId: resuming == null ? null : attempt.currentQuestionId,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(error);
        _loading = false;
      });
    }
  }

  void _beginModule({DateTime? resumeFrom, int? resumeQuestionId}) {
    // A resumed module counts from when the server says it started, minus the
    // seconds the student spent out of the test.
    _moduleStartedAt = resumeFrom ?? clock.now();
    _index = resumeQuestionId == null
        ? -1
        : _questions.indexWhere((q) => q.id == resumeQuestionId);
    if (_index < 0) {
      _index = _questions.indexWhere((q) => q.moduleId == _module.id);
    }
    if (_index < 0) _index = 0;
    final left = examModuleRemaining(
      moduleStartedAt: _moduleStartedAt!,
      now: clock.now(),
      timeLimitSeconds: _module.timeLimitSeconds,
      pauseSeconds: resumeFrom == null ? 0 : _pauseSeconds,
    );
    setState(() {
      // Time ran out while they were away: show this module's review so they
      // can move on or submit. Deliberately not auto-advanced -- a student
      // returning hours later must not be fast-forwarded through the rest.
      _phase = left == Duration.zero ? _Phase.moduleReview : _Phase.taking;
      _showMathToolsHint = _module.isMath && left > Duration.zero;
      _remaining = left;
    });
    _ticker?.cancel();
    if (left > Duration.zero) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final startedAt = _moduleStartedAt;
    if (startedAt == null || !mounted || _paused) return;
    final left = examModuleRemaining(
      moduleStartedAt: startedAt,
      now: clock.now(),
      timeLimitSeconds: _module.timeLimitSeconds,
      pauseSeconds: _pauseSeconds,
    );
    setState(() => _remaining = left);
    if (left > Duration.zero) return;
    // Out of time: show the review, then move on by itself a tick later, the
    // way Bluebook does. The ticker keeps running so that second step happens.
    if (_phase == _Phase.taking) {
      setState(() => _phase = _Phase.moduleReview);
    } else if (_phase == _Phase.moduleReview) {
      _ticker?.cancel();
      unawaited(_continueFromReview());
    } else {
      _ticker?.cancel();
    }
  }

  Future<void> _recordAnswer(ExamQuestion question, String value) async {
    setState(() => _answers[question.id] = value);
    final attemptId = _attemptId;
    if (attemptId == null) return;
    try {
      await _service.submitAnswer(
        attemptId: attemptId,
        questionId: question.id,
        selectedChoice: question.isGridIn ? null : value,
        responseText: question.isGridIn ? value : null,
      );
    } catch (_) {
      // A dropped keystroke must not interrupt the test; the next answer or
      // the submit call re-sends the state that matters.
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _index = index);
    unawaited(_syncPosition(_questions[index].id));
  }

  Future<void> _syncPosition(int questionId) async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    try {
      await _service.saveProgress(
        attemptId: attemptId,
        currentQuestionId: questionId,
      );
    } catch (_) {
      // Position is a convenience for resuming, never a blocker for answering.
    }
  }

  void _next() {
    final moduleQuestions = _moduleQuestions;
    final positionInModule =
        moduleQuestions.indexWhere((q) => q.id == _questions[_index].id);
    if (positionInModule >= moduleQuestions.length - 1) {
      setState(() => _phase = _Phase.moduleReview);
      return;
    }
    _goTo(_questions.indexWhere(
      (q) => q.id == moduleQuestions[positionInModule + 1].id,
    ));
  }

  void _back() {
    final moduleQuestions = _moduleQuestions;
    final positionInModule =
        moduleQuestions.indexWhere((q) => q.id == _questions[_index].id);
    if (positionInModule <= 0) return;
    _goTo(_questions.indexWhere(
      (q) => q.id == moduleQuestions[positionInModule - 1].id,
    ));
  }

  Future<void> _continueFromReview() async {
    if (_isLastModule) {
      await _submit();
      return;
    }
    // Bluebook runs the two modules of a section back to back and breaks only
    // between sections.
    final next = _test!.modules[_moduleIndex + 1];
    if (next.section == _module.section) {
      await _startNextModule();
      return;
    }
    setState(() => _phase = _Phase.moduleBreak);
  }

  Future<void> _startNextModule() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    final next = _test!.modules[_moduleIndex + 1];
    setState(() => _completing = true);
    try {
      await _service.saveProgress(
        attemptId: attemptId,
        currentModuleId: next.id,
      );
    } catch (_) {
      // The client already knows which module comes next; a failed sync here
      // only costs an accurate resume, not the test itself.
    }
    if (!mounted) return;
    setState(() {
      _moduleIndex += 1;
      _completing = false;
    });
    _pauseSeconds = 0;  // the server resets its pause total per module
    _beginModule();
  }

  Future<void> _submit() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      await _service.completeAttempt(attemptId);
      _ticker?.cancel();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PracticeTestReviewScreen(
            attemptId: attemptId,
            service: widget.service,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _completing = false;
        _error = userFacingError(error);
      });
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the test?'),
        content: const Text(
          'You only get one attempt at this test. Your answers are saved and '
          'the module timer stops until you come back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TuranColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    await _setPaused(true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: TuranColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _test == null) {
      return Scaffold(
        backgroundColor: TuranColors.bg,
        body: Column(
          children: [
            TuranHeader(
              title: 'Practice test',
              subtitle: 'This test could not be started',
              pageLabel: 'Practice',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    key: const Key('practice-test-start-error'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: TuranColors.textMid, height: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: SafeArea(top: false, child: _buildPhase()),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _Phase.moduleBreak:
        final next = _test!.modules[_moduleIndex + 1];
        return ExamModuleBreakView(
          completedModuleLabel: _module.label,
          nextModuleLabel: next.label,
          nextQuestionCount: next.requiredQuestionCount,
          nextMinutes: next.minutes,
          onStartNextModule: () => unawaited(_startNextModule()),
        );
      case _Phase.moduleReview:
        final review = ExamModuleReviewView(
          remaining: _remaining,
          isMath: _module.isMath,
          moduleLabel: _module.label,
          continueLabel: _isLastModule
              ? 'Submit test'
              : 'Continue to ${_test!.modules[_moduleIndex + 1].label}',
          questions: _moduleQuestions,
          answeredQuestionIds: _answeredIds,
          completing: _completing,
          onLeave: () => unawaited(_confirmLeave()),
          onReviewQuestion: (question) {
            setState(() {
              _phase = _Phase.taking;
              _index = _questions.indexWhere((q) => q.id == question.id);
            });
          },
          onContinue: () => unawaited(_continueFromReview()),
          onOpenReference: _module.isMath
              ? () => unawaited(showMathReferenceSheet(context))
              : null,
        );
        if (_error == null) return review;
        // A failed submit must say so: the student is looking at this screen, and
        // silence reads as a dead button.
        return Column(
          children: [
            Container(
              key: const Key('practice-test-submit-error'),
              width: double.infinity,
              color: TuranColors.error.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TuranColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: review),
          ],
        );
      case _Phase.taking:
        final question = _questions[_index];
        final moduleQuestions = _moduleQuestions;
        return ExamQuestionTakingView(
          remaining: _remaining,
          isMath: _module.isMath,
          sectionNumber:
              moduleQuestions.indexWhere((q) => q.id == question.id) + 1,
          sectionQuestionCount: moduleQuestions.length,
          sectionQuestions: moduleQuestions,
          answeredQuestionIds: _answeredIds,
          question: question,
          selectedChoice: _answers[question.id],
          completing: _completing,
          calculatorOpen: _calculatorOpen,
          showMathToolsHint: _showMathToolsHint,
          canGoBack:
              moduleQuestions.indexWhere((q) => q.id == question.id) > 0,
          onSelect: (value) => unawaited(_recordAnswer(question, value)),
          onBack: _completing ? null : _back,
          onNext: _completing ? null : _next,
          onJumpToQuestion: (target) =>
              _goTo(_questions.indexWhere((q) => q.id == target.id)),
          onLeave: () => unawaited(_confirmLeave()),
          onToggleCalculator: () =>
              setState(() => _calculatorOpen = !_calculatorOpen),
          onOpenReference: () => unawaited(showMathReferenceSheet(context)),
          onDismissHint: () => setState(() => _showMathToolsHint = false),
        );
    }
  }

  Set<int> get _answeredIds => {
        for (final entry in _answers.entries)
          if (entry.value.trim().isNotEmpty) entry.key,
      };
}
