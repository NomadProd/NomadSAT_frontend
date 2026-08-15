import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/diagnostic_service.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/Widgets/confirm_dialog.dart';
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
    var index = 0;
    for (var i = 0; i < questions.length; i++) {
      if (!saved.containsKey(questions[i].id)) {
        index = i;
        break;
      }
      if (i == questions.length - 1) index = i;
    }
    final current = questions[index];
    final sectionStartedAt = current.isMath
        ? startedAt.add(const Duration(seconds: kDiagnosticRwSeconds))
        : startedAt;
    setState(() {
      _attemptId = attemptId;
      _sectionStartedAt = sectionStartedAt;
      _questions = questions;
      _index = index;
      _savedChoices
        ..clear()
        ..addAll(saved);
      _selectedChoice = saved[current.id];
      _taking = true;
      _starting = false;
      _loading = false;
      _expiryHandled = false;
      _calculatorOpen = false;
      _showMathToolsHint = current.isMath;
    });
    _syncRemaining();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _syncRemaining();
    });
  }

  bool get _isMath =>
      _questions.isNotEmpty && _questions[_index].isMath;

  int get _sectionNumber {
    if (_questions.isEmpty) return 1;
    final order = _questions[_index].orderIndex;
    return _isMath ? order - 10 : order;
  }

  void _syncRemaining() {
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
    final mathIndex = _questions.indexWhere((question) => question.isMath);
    if (mathIndex < 0) {
      await _completeTest();
      return;
    }
    setState(() {
      _index = mathIndex;
      _selectedChoice = _savedChoices[_questions[mathIndex].id];
      _sectionStartedAt = DateTime.now();
      _expiryHandled = false;
      _calculatorOpen = false;
      _showMathToolsHint = true;
    });
    _syncRemaining();
  }

  Future<void> _saveCurrentSelection({String? choiceOverride}) async {
    final attemptId = _attemptId;
    if (attemptId == null || _questions.isEmpty) return;
    final question = _questions[_index];
    final choice = choiceOverride ?? _selectedChoice;
    if (choice == null || choice.isEmpty) return;
    _savedChoices[question.id] = choice;
    try {
      await _service.submitAnswer(
        attemptId: attemptId,
        questionId: question.id,
        selectedChoice: choice,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingError(error))),
      );
    }
  }

  Future<void> _goNext() async {
    await _saveCurrentSelection();
    if (!mounted) return;
    final isLastInSection = _isMath
        ? _index >= _questions.length - 1
        : _index >= 9 || (_index + 1 < _questions.length && _questions[_index + 1].isMath);
    if (_isMath && isLastInSection) {
      await _completeTest();
      return;
    }
    if (!_isMath && isLastInSection) {
      final mathIndex = _questions.indexWhere((question) => question.isMath);
      if (mathIndex < 0) {
        await _completeTest();
        return;
      }
      setState(() {
        _index = mathIndex;
        _selectedChoice = _savedChoices[_questions[mathIndex].id];
        _sectionStartedAt = DateTime.now();
        _expiryHandled = false;
        _calculatorOpen = false;
        _showMathToolsHint = true;
      });
      _syncRemaining();
      return;
    }
    setState(() {
      _index += 1;
      _selectedChoice = _savedChoices[_questions[_index].id];
    });
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
    if (leave && mounted) Navigator.of(context).pop();
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
      return DiagnosticQuestionTakingView(
        remaining: _remaining,
        isMath: _isMath,
        sectionNumber: _sectionNumber,
        question: _questions[_index],
        selectedChoice: _selectedChoice,
        completing: _completing,
        calculatorOpen: _calculatorOpen,
        showMathToolsHint: _showMathToolsHint,
        onSelect: (choice) {
          setState(() => _selectedChoice = choice);
          unawaited(_saveCurrentSelection(choiceOverride: choice));
        },
        onNext: _completing ? null : () => unawaited(_goNext()),
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
                    icon: Icons.block_rounded,
                    text: 'You cannot go back to a previous question',
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
