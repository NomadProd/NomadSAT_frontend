import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/diagnostic_service.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/Widgets/confirm_dialog.dart';
import 'package:flutter_web/Widgets/diagnostic_module_break_view.dart';
import 'package:flutter_web/Widgets/diagnostic_question_taking_view.dart';
import 'package:flutter_web/Widgets/math_reference_sheet_panel.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/screens/student/diagnostic_results_screen.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticTestScreen extends StatefulWidget {
  const DiagnosticTestScreen({super.key});

  @override
  State<DiagnosticTestScreen> createState() => _DiagnosticTestScreenState();
}

class _DiagnosticTestScreenState extends State<DiagnosticTestScreen> {
  final _service = DiagnosticService();

  bool _loading = true;
  bool _starting = false;
  bool _taking = false;
  bool _completing = false;
  String? _error;
  List<DiagnosticAttempt> _attempts = [];
  DiagnosticAttempt? _inProgress;
  DiagnosticAttempt? _latestCompleted;

  int? _attemptId;
  DateTime? _sectionStartedAt;
  List<DiagnosticQuestion> _questions = [];
  int _index = 0;
  String? _selectedChoice;
  final Map<int, String> _savedChoices = {};
  Timer? _timer;
  Duration _remaining = const Duration(seconds: kDiagnosticRwSeconds);
  bool _expiryHandled = false;
  bool _calculatorOpen = false;
  bool _showMathToolsHint = false;
  bool _showingModuleBreak = false;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadEntry() async {
    setState(() {
      _loading = true;
      _error = null;
      _taking = false;
    });
    try {
      final attempts = await _service.fetchAttempts();
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _inProgress = attempts.where((item) => item.isInProgress).firstOrNull;
        _latestCompleted = attempts.where((item) => item.isCompleted).firstOrNull;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFacingError(error);
      });
    }
  }

  Future<void> _startNewAttempt() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final created = await _service.startAttempt();
      await _enterAttempt(
        attemptId: created.attemptId,
        startedAt: created.startedAt,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = userFacingError(error);
      });
    }
  }

  Future<void> _continueAttempt() async {
    final attempt = _inProgress;
    if (attempt == null) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await _enterAttempt(
        attemptId: attempt.id,
        startedAt: attempt.startedAt,
        existingAnswers: attempt.answers,
        mathStartedAt: attempt.mathStartedAt,
        currentQuestionId: attempt.currentQuestionId,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = userFacingError(error);
      });
    }
  }

  Future<void> _enterAttempt({
    required int attemptId,
    required DateTime startedAt,
    List<DiagnosticAnswer> existingAnswers = const [],
    DateTime? mathStartedAt,
    int? currentQuestionId,
  }) async {
    final questions = await _service.fetchAttemptQuestions(attemptId);
    if (!mounted) return;
    questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final saved = <int, String>{};
    for (final answer in existingAnswers) {
      final choice = answer.selectedChoice;
      if (choice != null && choice.isNotEmpty) {
        saved[answer.questionId] = choice;
      }
    }
    final resume = resolveDiagnosticResume(
      questions: questions,
      savedQuestionIds: saved.keys.toSet(),
      startedAt: startedAt,
      now: DateTime.now(),
      mathStartedAt: mathStartedAt,
      currentQuestionId: currentQuestionId,
    );
    setState(() {
      _attemptId = attemptId;
      _sectionStartedAt = resume.sectionStartedAt;
      _questions = questions;
      _index = resume.questionIndex;
      _savedChoices
        ..clear()
        ..addAll(saved);
      _selectedChoice = saved[questions[resume.questionIndex].id];
      _taking = true;
      _starting = false;
      _loading = false;
      _expiryHandled = false;
      _calculatorOpen = false;
      _showMathToolsHint = resume.inMath && !resume.showBreak;
      _showingModuleBreak = resume.showBreak;
    });
    _syncRemaining();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _syncRemaining();
    });
    if (!resume.showBreak) {
      _queueSaveProgress();
    }
  }

  bool get _isMath =>
      _questions.isNotEmpty && _questions[_index].isMath;

  List<DiagnosticQuestion> get _sectionQuestions {
    return _questions.where((question) => question.isMath == _isMath).toList();
  }

  int get _sectionNumber {
    final currentId = _questions.isEmpty ? null : _questions[_index].id;
    final index = _sectionQuestions.indexWhere((question) => question.id == currentId);
    return index < 0 ? 1 : index + 1;
  }

  bool get _canGoBack => _sectionNumber > 1;

  Set<int> get _answeredQuestionIds => _savedChoices.keys.toSet();

  void _syncRemaining() {
    if (_showingModuleBreak) return;
    final started = _sectionStartedAt;
    if (started == null || !_taking) return;
    final remaining = diagnosticSectionRemaining(
      now: DateTime.now(),
      sectionStartedAt: started,
      isMath: _isMath,
    );
    if (!mounted) return;
    setState(() => _remaining = remaining);
    if (remaining.inSeconds <= 0 && !_expiryHandled) {
      _expiryHandled = true;
      unawaited(_onSectionExpired());
    }
  }

  Future<void> _onSectionExpired() async {
    await _saveCurrentSelection();
    if (!mounted) return;
    if (_isMath) {
      await _completeTest();
      return;
    }
    setState(() {
      _showingModuleBreak = true;
      _calculatorOpen = false;
      _expiryHandled = true;
    });
  }

  void _queueSaveCurrentSelection({String? choiceOverride}) {
    if (_questions.isEmpty) return;
    unawaited(
      _saveSelection(
        questionId: _questions[_index].id,
        choice: choiceOverride ?? _selectedChoice,
      ),
    );
  }

  Future<void> _saveCurrentSelection({String? choiceOverride}) async {
    if (_questions.isEmpty) return;
    await _saveSelection(
      questionId: _questions[_index].id,
      choice: choiceOverride ?? _selectedChoice,
    );
  }

  Future<void> _saveSelection({
    required int questionId,
    String? choice,
  }) async {
    final attemptId = _attemptId;
    if (attemptId == null || choice == null || choice.isEmpty) return;
    _savedChoices[questionId] = choice;
    try {
      await _service.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        selectedChoice: choice,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(error))),
      );
    }
  }

  void _queueSaveProgress({DateTime? mathStartedAt}) {
    unawaited(_saveProgress(mathStartedAt: mathStartedAt));
  }

  Future<void> _saveProgress({DateTime? mathStartedAt}) async {
    final attemptId = _attemptId;
    if (attemptId == null || _questions.isEmpty) return;
    try {
      await _service.saveProgress(
        attemptId: attemptId,
        currentQuestionId: _questions[_index].id,
        mathStartedAt: mathStartedAt,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(error))),
      );
    }
  }

  void _showQuestionAt(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= _questions.length) return;
    setState(() {
      _index = nextIndex;
      _selectedChoice = _savedChoices[_questions[nextIndex].id];
    });
    _queueSaveProgress();
  }

  Future<void> _goBack() async {
    if (!_canGoBack) return;
    _queueSaveCurrentSelection();
    final section = _sectionQuestions;
    final currentPos = _sectionNumber - 1;
    final previous = section[currentPos - 1];
    _showQuestionAt(
      _questions.indexWhere((question) => question.id == previous.id),
    );
  }

  Future<void> _jumpToQuestion(DiagnosticQuestion target) async {
    if (target.isMath != _isMath) return;
    _queueSaveCurrentSelection();
    _showQuestionAt(
      _questions.indexWhere((question) => question.id == target.id),
    );
  }

  Future<void> _goNext() async {
    final isLastInSection = _sectionNumber >= _sectionQuestions.length;
    if (_isMath && isLastInSection) {
      await _saveCurrentSelection();
      if (!mounted) return;
      await _completeTest();
      return;
    }
    _queueSaveCurrentSelection();
    if (!_isMath && isLastInSection) {
      _queueSaveProgress();
      setState(() {
        _showingModuleBreak = true;
        _calculatorOpen = false;
      });
      return;
    }
    final nextQuestion = _sectionQuestions[_sectionNumber];
    _showQuestionAt(
      _questions.indexWhere((question) => question.id == nextQuestion.id),
    );
  }

  void _startMathModule() {
    final mathIndex = _questions.indexWhere((question) => question.isMath);
    if (mathIndex < 0) {
      unawaited(_completeTest());
      return;
    }
    final started = DateTime.now();
    setState(() {
      _showingModuleBreak = false;
      _index = mathIndex;
      _selectedChoice = _savedChoices[_questions[mathIndex].id];
      _sectionStartedAt = started;
      _expiryHandled = false;
      _calculatorOpen = false;
      _showMathToolsHint = true;
    });
    _syncRemaining();
    _queueSaveProgress(mathStartedAt: started);
  }

  Future<void> _completeTest() async {
    final attemptId = _attemptId;
    if (attemptId == null || _completing) return;
    setState(() => _completing = true);
    try {
      final result = await _service.completeAttempt(attemptId);
      if (!mounted) return;
      _timer?.cancel();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DiagnosticResultsScreen(
            attempt: result,
            onRetake: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DiagnosticTestScreen()),
              );
            },
            onBackToDashboard: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(error))),
      );
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showConfirmDialog(
      context,
      title: 'Leave diagnostic test?',
      body: 'Your answers so far are saved. You can continue this attempt later.',
      confirmLabel: 'Leave',
      confirmColor: TuranColors.warning,
    );
    if (!leave || !mounted) return;
    await _saveCurrentSelection();
    await _saveProgress();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_taking,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_taking) return;
        unawaited(_confirmLeave());
      },
      child: Scaffold(
        backgroundColor: TuranColors.bg,
        body: Column(
          children: [
            if (!_taking)
              TuranHeader(
                title: 'Digital SAT diagnostic',
                subtitle: '20 questions · about 27 minutes',
                pageLabel: 'Diagnostic',
                onBack: () => Navigator.of(context).pop(),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: TuranColors.primary),
      );
    }
    if (_taking) {
      if (_showingModuleBreak) {
        return DiagnosticModuleBreakView(onStartMath: _startMathModule);
      }
      return DiagnosticQuestionTakingView(
        remaining: _remaining,
        isMath: _isMath,
        sectionNumber: _sectionNumber,
        sectionQuestionCount: _sectionQuestions.length,
        sectionQuestions: _sectionQuestions,
        answeredQuestionIds: _answeredQuestionIds,
        question: _questions[_index],
        selectedChoice: _selectedChoice,
        completing: _completing,
        calculatorOpen: _calculatorOpen,
        showMathToolsHint: _showMathToolsHint,
        canGoBack: _canGoBack,
        onSelect: (choice) {
          setState(() => _selectedChoice = choice);
          unawaited(_saveCurrentSelection(choiceOverride: choice));
        },
        onBack: _completing ? null : () => unawaited(_goBack()),
        onNext: _completing ? null : () => unawaited(_goNext()),
        onJumpToQuestion: (target) => unawaited(_jumpToQuestion(target)),
        onLeave: _confirmLeave,
        onToggleCalculator: () {
          setState(() => _calculatorOpen = !_calculatorOpen);
        },
        onOpenReference: () {
          unawaited(showMathReferenceSheet(context));
        },
        onDismissHint: () {
          setState(() => _showMathToolsHint = false);
        },
      );
    }
    return DiagnosticEntryView(
      starting: _starting,
      error: _error,
      inProgress: _inProgress,
      latestCompleted: _latestCompleted,
      attemptCount: _attempts.where((item) => item.isCompleted).length,
      onStart: _startNewAttempt,
      onContinue: _continueAttempt,
    );
  }
}

class DiagnosticEntryView extends StatelessWidget {
  final bool starting;
  final String? error;
  final DiagnosticAttempt? inProgress;
  final DiagnosticAttempt? latestCompleted;
  final int attemptCount;
  final VoidCallback onStart;
  final VoidCallback onContinue;

  const DiagnosticEntryView({
    super.key,
    required this.starting,
    required this.error,
    required this.inProgress,
    required this.latestCompleted,
    required this.attemptCount,
    required this.onStart,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 20, compact ? 16 : 24, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              decoration: BoxDecoration(
                color: TuranColors.surface,
                borderRadius: BorderRadius.circular(TuranRadius.lg),
                border: Border.all(color: TuranColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Diagnostic Test', style: TuranTextStyles.title),
                  const SizedBox(height: 10),
                  const Text(
                    'This short diagnostic has 20 questions and takes about 27 minutes. It gives an approximate Digital SAT score range (400–1600), not an official SAT score.',
                    style: TextStyle(
                      color: TuranColors.textMid,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _InfoRow(
                    icon: Icons.menu_book_rounded,
                    text: 'Reading & Writing: 10 questions, 12 minutes',
                  ),
                  const SizedBox(height: 8),
                  const _InfoRow(
                    icon: Icons.calculate_rounded,
                    text: 'Math: 10 questions, 15 minutes',
                  ),
                  const SizedBox(height: 8),
                  const _InfoRow(
                    icon: Icons.replay_rounded,
                    text: 'You can go back to any question in the current module',
                  ),
                  if (latestCompleted != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Latest estimate: ${latestCompleted!.totalRangeLow}–${latestCompleted!.totalRangeHigh}'
                      '${attemptCount > 1 ? ' · $attemptCount completed attempts saved' : ''}',
                      style: const TextStyle(
                        color: TuranColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 14),
                    Text(error!, style: const TextStyle(color: TuranColors.error)),
                  ],
                  const SizedBox(height: 20),
                  if (inProgress != null) ...[
                    ElevatedButton(
                      onPressed: starting ? null : onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TuranColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        elevation: 0,
                      ),
                      child: starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Continue test'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: starting ? null : onStart,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Start a new test'),
                    ),
                  ] else
                    ElevatedButton(
                      onPressed: starting ? null : onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TuranColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        elevation: 0,
                      ),
                      child: starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Start Test'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: TuranColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: TuranColors.textDark, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
