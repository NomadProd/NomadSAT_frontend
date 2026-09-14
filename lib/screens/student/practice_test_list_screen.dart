import 'package:flutter/material.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Services/practice_test_service.dart';
import 'package:flutter_web/Utils/exam_fullscreen.dart';
import 'package:flutter_web/Utils/practice_dashboard_stats.dart';
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
  PracticeDashboardStats _stats = const PracticeDashboardStats();
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
      final stats = await _statsFor(attempts);
      if (!mounted) return;
      setState(() {
        _tests = tests;
        _attemptsByTest = {};
        for (final attempt in attempts) {
          (_attemptsByTest[attempt.testId] ??= []).add(attempt);
        }
        _stats = stats;
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

  /// Domain accuracy lives on individual questions, and questions only come
  /// back with an attempt's detail -- so one request per test, for its latest
  /// attempt only. Pooling every retake of one test counts the same question
  /// several times over and measures repetition, not what the student knows.
  Future<PracticeDashboardStats> _statsFor(
    List<PracticeTestAttempt> attempts,
  ) async {
    final details = await Future.wait([
      for (final attempt in latestCompletedPerTest(attempts))
        _service
            .fetchAttemptDetail(attempt.id)
            .then<PracticeTestAttemptDetail?>(
              (detail) => detail,
              // One unreadable attempt must not blank the whole dashboard.
              onError: (_) => null,
            ),
    ]);
    return buildPracticeDashboardStats(
      attempts: attempts,
      answers: [for (final detail in details) ...?detail?.items],
    );
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
      // Still inside the tap that opened this, which is the only moment a
      // browser will grant fullscreen.
      ExamFullscreen.enter();
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
  Future<void> _startFresh(PracticeTestInfo test, {bool retake = false}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(retake ? 'Retake "${test.title}"?' : 'Start "${test.title}"?'),
        content: Text(
          'Each attempt is timed and kept in your history. '
          '${_testShape(test)}. '
          'Each module has its own timer and cannot be reopened once finished. '
          'The test opens fullscreen -- press Esc whenever you want to leave it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            key: const Key('practice-confirm-start'),
            onPressed: () {
              // Fullscreen is only granted inside a user gesture, so it is
              // asked for here rather than after the dialog has closed.
              ExamFullscreen.enter();
              Navigator.of(context).pop(true);
            },
            child: Text(retake ? 'Retake' : 'Start'),
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // One measure for the whole page. Full-bleed rows put a domain's name
          // and its score a thousand pixels apart on a laptop, and the eye
          // stops pairing them.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMeasure),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_stats.isEmpty)
                    const _NoResultsYet()
                  else ...[
                    _HeroScore(stats: _stats),
                    const SizedBox(height: 18),
                    _SectionScores(stats: _stats),
                    const SizedBox(height: 14),
                    _DomainMastery(stats: _stats),
                  ],
                  const SizedBox(height: 26),
                  for (final test in _tests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StudentTestCard(
                        test: test,
                        attempts: _attemptsByTest[test.id] ?? const [],
                        onRetake: () => _startFresh(test, retake: true),
                        onTap: () => _open(test),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The page's single column width.
const _kMeasure = 760.0;

/// Scores are read in columns, so their digits have to line up.
const _figures = [FontFeature.tabularFigures()];

/// A test is four modules, and naming each one repeats "Reading & Writing 27
/// questions in 32 minutes" twice over. Totals say the same thing once.
String _testShape(PracticeTestInfo test) {
  final modules = test.modules.length;
  final questions =
      test.modules.fold<int>(0, (sum, m) => sum + m.requiredQuestionCount);
  final minutes = test.modules.fold<int>(0, (sum, m) => sum + m.minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  final time = hours == 0 ? '${minutes}m' : (rest == 0 ? '${hours}h' : '${hours}h ${rest}m');
  return '$modules modules · $questions questions · $time';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
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
                          fontFeatures: _figures,
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
                _testShape(test),
                style: const TextStyle(
                  color: TuranColors.textMid,
                  fontSize: 12.5,
                  fontFeatures: _figures,
                ),
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

/// The card chrome. Only the mastery panel wears it now -- the score above it
/// sits on the page itself, so the page has one loud thing instead of three
/// identical boxes competing.
class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
      ),
      child: child,
    );
  }
}

/// Shown in place of every panel until the first test is finished: there is no
/// honest number to draw from zero attempts.
class _NoResultsYet extends StatelessWidget {
  const _NoResultsYet();

  @override
  Widget build(BuildContext context) {
    return const _Panel(
      child: Text(
        'Finish a practice test and your scores and domain breakdown appear here.',
        key: Key('practice-dashboard-empty'),
        style: TuranTextStyles.subtitle,
      ),
    );
  }
}

class _HeroScore extends StatelessWidget {
  final PracticeDashboardStats stats;

  const _HeroScore({required this.stats});

  @override
  Widget build(BuildContext context) {
    final delta = stats.delta;
    final title = stats.latestTestTitle;
    final at = stats.latestCompletedAt;
    final caption = [
      if (title != null && title.isNotEmpty) title,
      if (at != null) _shortDate(at),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest score',
          style: TuranTextStyles.label.copyWith(color: TuranColors.textMuted),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${stats.latestTotal}',
              key: const Key('practice-dashboard-total'),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -2,
                color: TuranColors.primary,
                fontFeatures: _figures,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                'of 1600',
                style: TuranTextStyles.caption.copyWith(
                  color: TuranColors.textLight,
                  fontFeatures: _figures,
                ),
              ),
            ),
            const Spacer(),
            // Nothing to compare against on a first attempt, and a delta of
            // zero is better said with silence than with a grey "0".
            if (delta != null && delta != 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DeltaChip(delta: delta),
              ),
          ],
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(caption, style: TuranTextStyles.subtitle),
        ],
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final int delta;

  const _DeltaChip({required this.delta});

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final color = up ? TuranColors.success : TuranColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: up ? TuranColors.successBg : TuranColors.errorBg,
        borderRadius: BorderRadius.circular(TuranRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            // Students retake the same test, so the comparison is against the
            // previous attempt -- which may well be the same paper.
            '${delta.abs()} from last attempt',
            key: const Key('practice-dashboard-delta'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: _figures,
            ),
          ),
        ],
      ),
    );
  }
}

/// Both sections in one panel rather than two cards: they are one fact read
/// together, and a divider says that more quietly than a gap does.
class _SectionScores extends StatelessWidget {
  final PracticeDashboardStats stats;

  const _SectionScores({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rw = _SectionScore(
      label: 'Reading & Writing',
      scaled: stats.latestRwScaled,
      color: TuranColors.verbal,
      valueKey: const Key('practice-dashboard-rw'),
    );
    final math = _SectionScore(
      label: 'Math',
      scaled: stats.latestMathScaled,
      color: TuranColors.math,
      valueKey: const Key('practice-dashboard-math'),
    );
    return _Panel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < TuranBreakpoints.mobile) {
            return Column(
              children: [
                rw,
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: TuranColors.border),
                ),
                math,
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: rw),
                const VerticalDivider(width: 33, color: TuranColors.border),
                Expanded(child: math),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionScore extends StatelessWidget {
  final String label;
  final int? scaled;
  final Color color;
  final Key valueKey;

  const _SectionScore({
    required this.label,
    required this.scaled,
    required this.color,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final score = scaled;
    // Each section is scored 200-800, so that is the track the bar fills.
    final fraction = score == null ? 0.0 : ((score - 200) / 600).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                label,
                style: TuranTextStyles.label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              score == null ? '—' : '$score',
              key: valueKey,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.1,
                color: color,
                fontFeatures: _figures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _Track(fraction: fraction, color: color),
      ],
    );
  }
}

class _DomainMastery extends StatelessWidget {
  final PracticeDashboardStats stats;

  const _DomainMastery({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Domain mastery',
            style: TuranTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            'Your latest attempt at each test.',
            key: const Key('practice-dashboard-mastery'),
            style: TuranTextStyles.caption,
          ),
          const SizedBox(height: 16),
          if (stats.rwMastery.isNotEmpty)
            _MasteryGroup(
              label: 'Reading & Writing',
              color: TuranColors.verbal,
              domains: stats.rwMastery,
            ),
          if (stats.rwMastery.isNotEmpty && stats.mathMastery.isNotEmpty)
            const SizedBox(height: 18),
          if (stats.mathMastery.isNotEmpty)
            _MasteryGroup(
              label: 'Math',
              color: TuranColors.math,
              domains: stats.mathMastery,
            ),
        ],
      ),
    );
  }
}

class _MasteryGroup extends StatelessWidget {
  final String label;
  final Color color;
  final List<DomainMastery> domains;

  const _MasteryGroup({
    required this.label,
    required this.color,
    required this.domains,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TuranTextStyles.label.copyWith(color: color)),
        const SizedBox(height: 10),
        for (final domain in domains)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        domain.domain,
                        style: TuranTextStyles.body.copyWith(fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // The raw count rides with the bar: six questions in a
                    // domain is not a verdict, and hiding the denominator
                    // would dress it up as one.
                    Text(
                      '${domain.correct}/${domain.total}',
                      key: Key('practice-mastery-${domain.domain}'),
                      style: TuranTextStyles.label.copyWith(
                        color: TuranColors.textMid,
                        fontFeatures: _figures,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _Track(
                  key: Key('practice-track-${domain.domain}'),
                  fraction: domain.accuracy,
                  color: color,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The empty part of the track is data too -- a domain answered nothing right
/// has to read as an empty bar, not as a bar that failed to render.
class _Track extends StatelessWidget {
  final double fraction;
  final Color color;

  const _Track({super.key, required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    // The width has to be forced: a FractionallySizedBox in a loose parent
    // shrink-wraps to its fill, so the track itself vanished at zero and every
    // other bar was really just the fill with no track behind it.
    return SizedBox(
      width: double.infinity,
      height: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TuranRadius.pill),
        child: ColoredBox(
          color: TuranColors.border,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );
  }
}
