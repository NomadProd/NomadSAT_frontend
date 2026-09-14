import 'dart:async';

import 'package:clock/clock.dart';

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
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

  /// What the server has actually acknowledged. An answer only lands here once
  /// the write came back clean, so anything missing is still owed.
  final Map<int, String> _persistedAnswers = {};

  /// Saves run one at a time: a grid-in types faster than the network, and
  /// concurrent writes to one question race and can store a truncated answer.
  Future<void> _saveChain = Future.value();
  Timer? _saveDebounce;
  int? _pendingQuestionId;

  int _moduleIndex = 0;
  int _index = 0;
  _Phase _phase = _Phase.taking;
  Duration _remaining = Duration.zero;
  Timer? _ticker;

  /// When this module runs out, in this device's own terms.
  ///
  /// The server says how many seconds are left and this is that answer plus
  /// the moment we heard it, so a device clock that disagrees with the server
  /// cannot change the result: only the passage of time here matters, never
  /// what time this machine thinks it is.
  DateTime? _deadline;

  /// Ticks since we last told the server we are here. The heartbeat rides the
  /// countdown rather than owning a timer: a backgrounded tab throttles both
  /// together, which is exactly what the server's away-detection assumes.
  int _ticksSinceSync = 0;
  static const _syncEveryTicks = 20;

  bool _loading = true;
  bool _completing = false;
  bool _calculatorOpen = false;
  bool _showMathToolsHint = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Nothing listens for the tab being hidden any more. Switching away is not
    // leaving, and the clock is the server's to stop: while this screen keeps
    // reporting in, the student is here. Silence is what stops it.
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
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
        secondsRemaining: attempt.secondsRemaining,
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

  /// Open a module, with the server's word on how long is left in it.
  ///
  /// [secondsRemaining] falling back to the module's full limit only happens
  /// when the server said nothing; it can then only under-report how generous
  /// the server is being, and late answers are refused there regardless.
  void _beginModule({int? secondsRemaining, int? resumeQuestionId}) {
    _syncDeadline(secondsRemaining ?? _module.timeLimitSeconds);
    // The saved question only counts if it belongs to the module being opened:
    // an older attempt can carry a question from the module before this one.
    _index = resumeQuestionId == null
        ? -1
        : _questions.indexWhere(
            (q) => q.id == resumeQuestionId && q.moduleId == _module.id);
    if (_index < 0) {
      _index = _questions.indexWhere((q) => q.moduleId == _module.id);
    }
    if (_index < 0) _index = 0;
    final left = _left();
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

  /// Take the server's answer as the new truth about this module's clock.
  void _syncDeadline(int secondsRemaining) {
    _deadline = clock.now().add(Duration(seconds: secondsRemaining));
    _ticksSinceSync = 0;
  }

  Duration _left() {
    final deadline = _deadline;
    if (deadline == null) return Duration.zero;
    final left = deadline.difference(clock.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    if (!mounted) return;
    final left = _left();
    setState(() => _remaining = left);
    if (++_ticksSinceSync >= _syncEveryTicks) {
      _ticksSinceSync = 0;
      unawaited(_syncPosition(_questions.isEmpty ? null : _questions[_index].id));
    }
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

  void _recordAnswer(ExamQuestion question, String value) {
    setState(() => _answers[question.id] = value);
    // A grid-in fires on every keystroke, so wait for the typing to stop and
    // send the finished answer once. A choice has nothing to wait for.
    _saveDebounce?.cancel();
    if (!question.isGridIn) {
      _queueSave(question.id);
      return;
    }
    _pendingQuestionId = question.id;
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      _pendingQuestionId = null;
      _queueSave(question.id);
    });
  }

  /// Flush a debounced grid-in immediately -- on navigation or submit, the
  /// student is done typing whether or not the timer has fired.
  void _flushPendingAnswer() {
    final pending = _pendingQuestionId;
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _pendingQuestionId = null;
    if (pending != null) _queueSave(pending);
  }

  void _queueSave(int questionId) {
    final previous = _saveChain;
    _saveChain = previous.then((_) => _saveAnswer(questionId));
  }

  Future<void> _saveAnswer(int questionId) async {
    final attemptId = _attemptId;
    final value = _answers[questionId];
    if (attemptId == null || value == null) return;
    if (_persistedAnswers[questionId] == value) return;
    final question = _questions.firstWhere((q) => q.id == questionId);
    try {
      await _service.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        selectedChoice: question.isGridIn ? null : value,
        responseText: question.isGridIn ? value : null,
      );
      _persistedAnswers[questionId] = value;
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        // The module is over, or was left behind. The server will never take
        // this answer, so stop offering it -- retrying at submit would only
        // fail again for no reason.
        _answers.remove(questionId);
        _persistedAnswers.remove(questionId);
      }
      // Anything else is worth another try: left out of _persistedAnswers on
      // purpose, so _resendUnsavedAnswers picks it up before submit.
    } catch (_) {
      // Left out of _persistedAnswers on purpose: _resendUnsavedAnswers picks
      // it up before submit, and until then the student can see it is unsaved.
    }
  }

  /// Re-send everything the server never acknowledged. This is what makes
  /// "the submit call re-sends the state that matters" actually true.
  Future<void> _resendUnsavedAnswers() async {
    _flushPendingAnswer();
    for (final entry in _answers.entries) {
      if (_persistedAnswers[entry.key] != entry.value) {
        _queueSave(entry.key);
      }
    }
    await _saveChain;
  }

  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    _flushPendingAnswer();
    setState(() => _index = index);
    unawaited(_syncPosition(_questions[index].id));
  }

  /// Report in, and take back whatever the server now says about the clock.
  ///
  /// This carries the heartbeat as well as the position: while it keeps
  /// arriving the student counts as present, and the silence when it stops is
  /// what tells the server they have gone.
  Future<void> _syncPosition(int? questionId) async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    try {
      final attempt = await _service.saveProgress(
        attemptId: attemptId,
        currentQuestionId: questionId,
      );
      if (!mounted) return;
      // The server finished the attempt because its last module ran out. That
      // can arrive either as the answer to the beat that triggered it, or as a
      // 409 on the one after.
      if (attempt.isCompleted) {
        unawaited(_openReview());
        return;
      }
      final remaining = attempt.secondsRemaining;
      if (remaining != null) _syncDeadline(remaining);
    } on ApiException catch (error) {
      if (error.statusCode == 409) unawaited(_openReview());
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
    // The module and the question it opens on move together, in one call: a
    // module id saved without its question leaves the server pointing at a
    // question of the module the student has just finished.
    final nextQuestions = _questions.where((q) => q.moduleId == next.id);
    final firstQuestion =
        nextQuestions.isEmpty ? null : nextQuestions.first.id;
    setState(() => _completing = true);
    int? remaining;
    try {
      remaining = (await _service.saveProgress(
        attemptId: attemptId,
        currentModuleId: next.id,
        currentQuestionId: firstQuestion,
      ))
          .secondsRemaining;
    } catch (_) {
      // Retry once: if the server keeps the old module, a later resume drops
      // the student back into a module they have already finished.
      try {
        remaining = (await _service.saveProgress(
          attemptId: attemptId,
          currentModuleId: next.id,
          currentQuestionId: firstQuestion,
        ))
            .secondsRemaining;
      } catch (_) {
        // Out of options; the client still advances so the test can continue,
        // and the module's own limit stands in until the next sync corrects it.
      }
    }
    if (!mounted) return;
    setState(() {
      _moduleIndex += 1;
      _completing = false;
    });
    // The new module's clock is whatever the server just started, not a fresh
    // one invented here.
    _beginModule(secondsRemaining: remaining);
  }

  /// Hand the student their score. The test is over by the time this runs.
  Future<void> _openReview() async {
    final attemptId = _attemptId;
    if (attemptId == null || !mounted) return;
    _ticker?.cancel();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PracticeTestReviewScreen(
          attemptId: attemptId,
          service: widget.service,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    setState(() {
      _completing = true;
      _error = null;
    });
    try {
      // Nothing is submitted until every answer the student gave is stored.
      await _resendUnsavedAnswers();
      await _service.completeAttempt(attemptId);
      await _openReview();
      return;
    } on ApiException catch (error) {
      // Already completed -- the server finished it when the clock ran out
      // while this submit was on its way. That is their score, not an error.
      if (error.statusCode == 409) {
        await _openReview();
        return;
      }
      if (!mounted) return;
      setState(() {
        _completing = false;
        _error = userFacingError(error);
      });
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
          'Your answers are saved. The module clock keeps running for a short '
          'while after you go, so come back soon or you will lose the rest of '
          'this module.',
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
    Navigator.of(context).pop();
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
        final taking = ExamQuestionTakingView(
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
          onSelect: (value) => _recordAnswer(question, value),
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
        return taking;
    }
  }

  Set<int> get _answeredIds => {
        for (final entry in _answers.entries)
          if (entry.value.trim().isNotEmpty) entry.key,
      };
}
