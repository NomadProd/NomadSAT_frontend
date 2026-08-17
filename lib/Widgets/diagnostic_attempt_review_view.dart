import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Widgets/diagnostic_question_figure.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticAttemptReviewDenied extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const DiagnosticAttemptReviewDenied({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              key: Key('diagnostic-access-denied'),
              size: 48,
              color: TuranColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Access denied',
              style: TuranTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TuranTextStyles.subtitle,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DiagnosticAttemptReviewView extends StatelessWidget {
  final DiagnosticAttemptDetail detail;
  final bool showStudentName;

  const DiagnosticAttemptReviewView({
    super.key,
    required this.detail,
    this.showStudentName = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReviewHeader(
                  detail: detail,
                  showStudentName: showStudentName,
                ),
                const SizedBox(height: 14),
                _ReviewSummary(answers: detail.answers),
                const SizedBox(height: 16),
                for (final answer in detail.answers) ...[
                  _ReviewQuestionCard(answer: answer),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final DiagnosticAttemptDetail detail;
  final bool showStudentName;

  const _ReviewHeader({
    required this.detail,
    required this.showStudentName,
  });

  @override
  Widget build(BuildContext context) {
    final completed = detail.completedAt?.toLocal();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStudentName)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                detail.student.fullName,
                key: const Key('diagnostic-review-student-name'),
                style: TuranTextStyles.title.copyWith(fontSize: 18),
              ),
            ),
          Text(
            completed == null
                ? 'Completed date unavailable'
                : 'Completed ${_formatDate(completed)}',
            style: TuranTextStyles.subtitle,
          ),
          const SizedBox(height: 10),
          Text(
            detail.scoreRangeLabel,
            style: const TextStyle(
              color: TuranColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _ScoreChip(
                label: 'Reading & Writing',
                value: '${detail.rwScaledEstimate ?? '—'}',
                color: TuranColors.verbal,
              ),
              _ScoreChip(
                label: 'Math',
                value: '${detail.mathScaledEstimate ?? '—'}',
                color: TuranColors.math,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label  $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SectionCounts {
  int correct = 0;
  int incorrect = 0;
  int unanswered = 0;
}

class _DomainCounts {
  int correct = 0;
  int total = 0;
}

class _ReviewSummary extends StatelessWidget {
  final List<DiagnosticAnswerReview> answers;

  const _ReviewSummary({required this.answers});

  @override
  Widget build(BuildContext context) {
    final rw = _SectionCounts();
    final math = _SectionCounts();
    final domains = <String, _DomainCounts>{};

    for (final answer in answers) {
      final bucket = answer.isMath ? math : rw;
      if (answer.isUnanswered) {
        bucket.unanswered += 1;
      } else if (answer.isCorrect == true) {
        bucket.correct += 1;
      } else {
        bucket.incorrect += 1;
      }
      final domain = domains.putIfAbsent(answer.domain, _DomainCounts.new);
      domain.total += 1;
      if (answer.isCorrect == true) domain.correct += 1;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary', style: TuranTextStyles.title.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Reading & Writing: ${_sectionLine(rw)}',
            style: TuranTextStyles.subtitle,
          ),
          const SizedBox(height: 4),
          Text(
            'Math: ${_sectionLine(math)}',
            style: TuranTextStyles.subtitle,
          ),
          const SizedBox(height: 10),
          Text(
            'Domain snapshot (informational only)',
            style: TuranTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final entry in domains.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '${entry.key}: ${entry.value.correct}/${entry.value.total} correct',
                style: TuranTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }

  String _sectionLine(_SectionCounts counts) {
    return '${counts.correct} correct, ${counts.incorrect} incorrect, ${counts.unanswered} unanswered';
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  final DiagnosticAnswerReview answer;

  const _ReviewQuestionCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('diagnostic-review-question-${answer.orderIndex}'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                label: 'Q${answer.orderIndex}',
                color: TuranColors.primary,
              ),
              _Badge(
                label: answer.isMath ? 'Math' : 'Reading & Writing',
                color: answer.isMath ? TuranColors.math : TuranColors.verbal,
              ),
              _Badge(label: answer.domain, color: TuranColors.neutral),
              _Badge(
                label: answer.difficulty,
                color: _difficultyColor(answer.difficulty),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if ((answer.passageText ?? '').trim().isNotEmpty) ...[
            Text(
              answer.passageText!.trim(),
              style: const TextStyle(
                color: TuranColors.textMid,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            answer.questionText,
            style: const TextStyle(
              color: TuranColors.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (answer.hasQuestionImage) ...[
            const SizedBox(height: 12),
            DiagnosticQuestionFigure(
              url: answer.questionImage!,
              scale: answer.imageScale,
            ),
          ],
          if (answer.isUnanswered) ...[
            const SizedBox(height: 12),
            Container(
              key: Key('diagnostic-review-unanswered-${answer.orderIndex}'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: TuranColors.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Not answered',
                style: TextStyle(
                  color: TuranColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final choice in answer.choices) ...[
            _ReviewChoiceTile(answer: answer, choice: choice),
            const SizedBox(height: 8),
          ],
          if (answer.hasExplanation) ...[
            const SizedBox(height: 4),
            _ExplanationBlock(text: answer.explanation!.trim()),
          ],
        ],
      ),
    );
  }
}

class _ReviewChoiceTile extends StatelessWidget {
  final DiagnosticAnswerReview answer;
  final DiagnosticChoice choice;

  const _ReviewChoiceTile({
    required this.answer,
    required this.choice,
  });

  @override
  Widget build(BuildContext context) {
    final selected = (answer.selectedChoice ?? '').toUpperCase();
    final correct = answer.correctChoice.toUpperCase();
    final key = choice.key.toUpperCase();
    final isSelected = selected.isNotEmpty && key == selected;
    final isCorrect = key == correct;
    Color border = TuranColors.border;
    Color background = TuranColors.surface;
    IconData? icon;
    Color? iconColor;
    if (isCorrect) {
      border = TuranColors.success;
      background = TuranColors.successBg;
      icon = Icons.check_circle_rounded;
      iconColor = TuranColors.success;
    }
    if (isSelected && !isCorrect) {
      border = TuranColors.error;
      background = TuranColors.errorBg;
      icon = Icons.cancel_rounded;
      iconColor = TuranColors.error;
    }

    return Container(
      key: Key(
        'diagnostic-review-choice-${answer.orderIndex}-${choice.key}',
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
          width: isSelected || isCorrect ? 1.8 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${choice.key}.',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: TuranColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              choice.text,
              style: const TextStyle(
                color: TuranColors.textDark,
                height: 1.35,
              ),
            ),
          ),
          if (icon != null) Icon(icon, color: iconColor, size: 20),
        ],
      ),
    );
  }
}

class _ExplanationBlock extends StatelessWidget {
  final String text;

  const _ExplanationBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.length < 220) {
      return Text(
        text,
        style: const TextStyle(
          color: TuranColors.textMid,
          height: 1.45,
          fontSize: 13,
        ),
      );
    }
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        title: const Text(
          'Explanation',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: TuranColors.textDark,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                color: TuranColors.textMid,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

Color _difficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return TuranColors.success;
    case 'hard':
      return TuranColors.error;
    default:
      return TuranColors.warning;
  }
}

String _formatDate(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
