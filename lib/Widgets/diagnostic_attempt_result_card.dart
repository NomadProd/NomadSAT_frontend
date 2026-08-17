import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/theme/turan_theme.dart';

String formatDiagnosticDate(DateTime? value) {
  if (value == null) return 'In progress';
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String? diagnosticTrendLabel(List<DiagnosticAttemptListItem> attempts) {
  final completed = attempts
      .where((item) => item.isCompleted && item.totalPointEstimate != null)
      .toList();
  if (completed.length < 2) return null;
  final delta =
      completed[0].totalPointEstimate! - completed[1].totalPointEstimate!;
  if (delta == 0) return 'No change since last attempt';
  if (delta > 0) return '+$delta points since last attempt';
  return '$delta points since last attempt';
}

class DiagnosticAttemptResultCard extends StatelessWidget {
  final DiagnosticAttemptListItem attempt;
  final VoidCallback onTap;
  final bool showStudentName;

  const DiagnosticAttemptResultCard({
    super.key,
    required this.attempt,
    required this.onTap,
    this.showStudentName = false,
  });

  @override
  Widget build(BuildContext context) {
    final inProgress = attempt.isInProgress;
    return Material(
      color: TuranColors.surface,
      borderRadius: BorderRadius.circular(TuranRadius.lg),
      child: InkWell(
        key: Key('diagnostic-attempt-card-${attempt.attemptId}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TuranRadius.lg),
            border: Border.all(color: TuranColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: inProgress
                      ? TuranColors.warningBg
                      : const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  inProgress
                      ? Icons.timelapse_rounded
                      : Icons.quiz_rounded,
                  color: inProgress ? TuranColors.warning : TuranColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showStudentName && attempt.student != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          attempt.student!.fullName,
                          style: const TextStyle(
                            color: TuranColors.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    Text(
                      inProgress
                          ? 'In progress'
                          : formatDiagnosticDate(attempt.completedAt),
                      style: TextStyle(
                        color: TuranColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: showStudentName ? 13 : 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inProgress
                          ? 'Continue this attempt'
                          : attempt.scoreRangeLabel,
                      style: TextStyle(
                        color: inProgress
                            ? TuranColors.warning
                            : TuranColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (!inProgress) ...[
                      const SizedBox(height: 4),
                      Text(
                        'RW ${attempt.rwScaledEstimate ?? '—'}  ·  Math ${attempt.mathScaledEstimate ?? '—'}',
                        style: const TextStyle(
                          color: TuranColors.textMid,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TuranColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiagnosticAttemptListView extends StatelessWidget {
  final List<DiagnosticAttemptListItem> attempts;
  final ValueChanged<DiagnosticAttemptListItem> onOpen;
  final VoidCallback? onTakeTest;
  final VoidCallback? onRetake;
  final bool showStudentName;
  final String emptyTitle;
  final String emptyBody;

  const DiagnosticAttemptListView({
    super.key,
    required this.attempts,
    required this.onOpen,
    this.onTakeTest,
    this.onRetake,
    this.showStudentName = false,
    this.emptyTitle = 'No diagnostic results yet',
    this.emptyBody =
        'Take the 20-question diagnostic to see an approximate SAT score range.',
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
    final trend = diagnosticTrendLabel(attempts);

    if (attempts.isEmpty) {
      return _EmptyDiagnosticState(
        title: emptyTitle,
        body: emptyBody,
        onTakeTest: onTakeTest,
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        18,
        compact ? 16 : 24,
        32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (trend != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      trend,
                      key: const Key('diagnostic-trend'),
                      style: const TextStyle(
                        color: TuranColors.textMid,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (onRetake != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      key: const Key('diagnostic-retake'),
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retake test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TuranColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                for (var i = 0; i < attempts.length; i++) ...[
                  DiagnosticAttemptResultCard(
                    attempt: attempts[i],
                    showStudentName: showStudentName,
                    onTap: () => onOpen(attempts[i]),
                  ),
                  if (i != attempts.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDiagnosticState extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onTakeTest;

  const _EmptyDiagnosticState({
    required this.title,
    required this.body,
    this.onTakeTest,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.quiz_outlined,
                size: 48,
                color: TuranColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TuranTextStyles.title,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TuranTextStyles.subtitle,
              ),
              if (onTakeTest != null) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  key: const Key('diagnostic-take-test'),
                  onPressed: onTakeTest,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Take the Diagnostic Test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TuranColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
