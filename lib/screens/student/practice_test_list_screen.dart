import 'package:flutter/material.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/screens/shared/practice_test_review_screen.dart';
import 'package:flutter_web/screens/student/practice_test_screen.dart';
import 'package:flutter_web/Widgets/turan_header.dart';
import 'package:flutter_web/theme/turan_theme.dart';

/// The attempt still running, if any. Only one can be.
PracticeTestAttempt? inProgressAttempt(List<PracticeTestAttempt> attempts) {
  for (final attempt in attempts) {
    if (attempt.isInProgress) return attempt;
  }
  return null;
}

/// The student's best completed attempt -- what a retake is measured against.
PracticeTestAttempt? bestAttempt(List<PracticeTestAttempt> attempts) {
  PracticeTestAttempt? best;
  for (final attempt in attempts) {
    if (!attempt.isCompleted) continue;
    if (best == null || (attempt.totalScaled ?? 0) > (best.totalScaled ?? 0)) {
      best = attempt;
    }
  }
  return best;
}

class StudentPracticeTestListScreen extends StatefulWidget {
  /// Injectable so the flow can be driven in tests without a server.
  final PracticeTestService? service;

  const StudentPracticeTestListScreen({super.key, this.service});

  @override
  State<StudentPracticeTestListScreen> createState() =>
      _StudentPracticeTestListScreenState();
}

class _StudentPracticeTestListScreenState
    extends State<StudentPracticeTestListScreen> {
  late final _service = widget.service ?? PracticeTestService();

  List<PracticeTestInfo> _tests = [];
  Map<int, List<PracticeTestAttempt>> _attemptsByTest = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tests = await _service.fetchTests();
      final attempts = await _service.fetchMyAttempts();
      if (!mounted) return;
      setState(() {
        _tests = tests;
        _attemptsByTest = {};
        for (final attempt in attempts) {
          (_attemptsByTest[attempt.testId] ??= []).add(attempt);
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(error);
        _loading = false;
      });
    }
  }

  Future<void> _open(PracticeTestInfo test) async {
    final attempts = _attemptsByTest[test.id] ?? const <PracticeTestAttempt>[];
    final attempt = inProgressAttempt(attempts) ?? bestAttempt(attempts);
    if (attempt != null && attempt.isCompleted) {
      // Opens the best attempt's review; a retake is its own button.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PracticeTestReviewScreen(
            attemptId: attempt.id,
            service: widget.service,
          ),
        ),
      );
      await _load();
      return;
    }
    if (attempt != null && attempt.isInProgress) {
      // Resume: the review would refuse an unfinished attempt, leaving the
      // student locked out of a test they can never submit.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PracticeTestScreen(
            testId: test.id,
            attempt: attempt,
            service: widget.service,
          ),
        ),
      );
      await _load();
      return;
    }
    await _startFresh(test);
  }

  /// Start a new attempt -- the first, or a retake once the last one is done.
  Future<void> _startFresh(PracticeTestInfo test) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start "${test.title}"?'),
        content: Text(
          'Each attempt is timed and kept in your history. '
          '${test.modules.map((m) => '${m.sectionLabel} '
              '${m.requiredQuestionCount} questions in ${m.minutes} minutes').join('. ')}. '
          'Each module has its own timer and cannot be reopened once finished.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            key: const Key('practice-confirm-start'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) =>
          PracticeTestScreen(testId: test.id, service: widget.service)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TuranColors.bg,
      body: Column(
        children: [
          TuranHeader(
            title: 'Practice Tests',
            subtitle: 'Full-length tests shared with your group',
            pageLabel: 'Practice',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_tests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No practice tests have been shared with your group yet.',
            key: Key('student-practice-empty'),
            textAlign: TextAlign.center,
            style: TextStyle(color: TuranColors.textMid, height: 1.5),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final test = _tests[index];
          return _StudentTestCard(
            test: test,
            attempts: _attemptsByTest[test.id] ?? const [],
            onRetake: () => _startFresh(test),
            onTap: () => _open(test),
          );
        },
      ),
    );
  }
}

class _StudentTestCard extends StatelessWidget {
  final PracticeTestInfo test;
  final List<PracticeTestAttempt> attempts;
  final VoidCallback onTap;
  final VoidCallback onRetake;

  const _StudentTestCard({
    required this.test,
    required this.attempts,
    required this.onTap,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final running = inProgressAttempt(attempts);
    final best = bestAttempt(attempts);
    final attempt = running ?? best;
    final completedCount = attempts.where((a) => a.isCompleted).length;
    final taken = best != null && running == null;
    final inProgress = running != null;
    return Material(
      color: TuranColors.surface,
      borderRadius: BorderRadius.circular(TuranRadius.lg),
      child: InkWell(
        key: Key('student-practice-card-${test.id}'),
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TuranRadius.lg),
            border: Border.all(color: TuranColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(test.title, style: TuranTextStyles.title),
                  ),
                  if (taken)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: TuranColors.primary,
                        borderRadius: BorderRadius.circular(TuranRadius.pill),
                      ),
                      child: Text(
                        '${attempt!.totalScaled ?? '—'}',
                        key: Key('student-practice-score-${test.id}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
              if (test.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  test.description!,
                  style: const TextStyle(
                      color: TuranColors.textMid, fontSize: 13, height: 1.4),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                test.modules
                    .map((m) =>
                        '${m.sectionLabel} · ${m.requiredQuestionCount}q · ${m.minutes}m')
                    .join('    '),
                style: const TextStyle(
                    color: TuranColors.textMid, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    taken
                        ? Icons.fact_check_rounded
                        : inProgress
                            ? Icons.timelapse_rounded
                            : Icons.play_circle_fill_rounded,
                    size: 18,
                    color: TuranColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    taken
                        ? (completedCount > 1
                            ? 'Best of $completedCount attempts'
                            : 'View your result')
                        : inProgress
                            ? 'Continue test'
                            : 'Start test',
                    key: Key('student-practice-state-${test.id}'),
                    style: const TextStyle(
                      color: TuranColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // A retake only once nothing is still running.
                  if (taken) ...[
                    const Spacer(),
                    TextButton.icon(
                      key: Key('student-practice-retake-${test.id}'),
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retake'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
