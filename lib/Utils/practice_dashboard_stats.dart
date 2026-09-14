import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';

/// Accuracy in one domain. Pooled across every attempt the student has
/// finished: a single test gives six or seven questions per domain, which on
/// its own is noise, so the raw counts travel with the fraction and get shown.
class DomainMastery {
  final String domain;
  final int correct;
  final int total;

  const DomainMastery({
    required this.domain,
    required this.correct,
    required this.total,
  });

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// The numbers the practice dashboard draws, and nothing else. Pure, so the
/// panels can be checked without a server or a widget tree.
class PracticeDashboardStats {
  /// The most recently completed attempt, and the one before it -- the delta
  /// is the whole reason the previous one is carried.
  final int? latestTotal;
  final int? previousTotal;
  final int? latestRwScaled;
  final int? latestMathScaled;
  final String? latestTestTitle;
  final DateTime? latestCompletedAt;
  final List<DomainMastery> rwMastery;
  final List<DomainMastery> mathMastery;

  const PracticeDashboardStats({
    this.latestTotal,
    this.previousTotal,
    this.latestRwScaled,
    this.latestMathScaled,
    this.latestTestTitle,
    this.latestCompletedAt,
    this.rwMastery = const [],
    this.mathMastery = const [],
  });

  /// No finished attempt means there is nothing to draw: the dashboard falls
  /// back to the test list alone.
  bool get isEmpty => latestTotal == null;

  int? get delta => latestTotal != null && previousTotal != null
      ? latestTotal! - previousTotal!
      : null;
}

/// The latest finished attempt at each test. Mastery reads only these: pooling
/// every retake of one test counts the same question three times over and
/// measures repetition, not what the student knows now.
List<PracticeTestAttempt> latestCompletedPerTest(
  List<PracticeTestAttempt> attempts,
) {
  final byTest = <int, PracticeTestAttempt>{};
  for (final attempt in attempts.where((a) => a.isCompleted)) {
    final seen = byTest[attempt.testId];
    if (seen == null || _byCompletion(seen, attempt) < 0) {
      byTest[attempt.testId] = attempt;
    }
  }
  return byTest.values.toList();
}

PracticeDashboardStats buildPracticeDashboardStats({
  required List<PracticeTestAttempt> attempts,
  required List<ExamReviewAnswer> answers,
}) {
  final completed = attempts.where((a) => a.isCompleted).toList()
    ..sort(_byCompletion);
  final latest = completed.isEmpty ? null : completed.last;
  final previous =
      completed.length < 2 ? null : completed[completed.length - 2];

  return PracticeDashboardStats(
    latestTotal: latest?.totalScaled,
    previousTotal: previous?.totalScaled,
    latestRwScaled: latest?.rwScaled,
    latestMathScaled: latest?.mathScaled,
    latestTestTitle: latest?.testTitle,
    latestCompletedAt: latest?.completedAt,
    rwMastery: _mastery(answers, isMath: false, order: kRwDomains),
    mathMastery: _mastery(answers, isMath: true, order: kMathDomains),
  );
}

/// Oldest first. An attempt can be complete without a timestamp, so id breaks
/// the tie -- ids climb with time, and a missing date must not jump to the top
/// and be read as the student's latest score.
int _byCompletion(PracticeTestAttempt a, PracticeTestAttempt b) {
  final left = a.completedAt;
  final right = b.completedAt;
  if (left != null && right != null) {
    final byDate = left.compareTo(right);
    if (byDate != 0) return byDate;
  } else if (left == null && right != null) {
    return -1;
  } else if (left != null && right == null) {
    return 1;
  }
  return a.id.compareTo(b.id);
}

List<DomainMastery> _mastery(
  List<ExamReviewAnswer> answers, {
  required bool isMath,
  required List<String> order,
}) {
  final counts = <String, DomainMastery>{};
  for (final answer in answers) {
    if (answer.isMath != isMath) continue;
    final seen = counts[answer.domain];
    counts[answer.domain] = DomainMastery(
      domain: answer.domain,
      correct: (seen?.correct ?? 0) + (answer.isCorrect == true ? 1 : 0),
      total: (seen?.total ?? 0) + 1,
    );
  }
  // Report order first, then anything tagged with a domain the list does not
  // know about -- a question with a drifted domain string still has to count.
  final known = [for (final domain in order) if (counts[domain] != null) counts.remove(domain)!];
  return [...known, ...counts.values];
}
