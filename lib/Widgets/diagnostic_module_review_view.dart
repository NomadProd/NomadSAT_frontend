import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/theme/turan_theme.dart';

const _answeredColor = Color(0xFF2E7D32);
const _answeredFill = Color(0xFFE8F5E9);
const _unansweredColor = Color(0xFF607D8B);
const _unansweredFill = Color(0xFFEEF1F4);

class DiagnosticModuleReviewView extends StatelessWidget {
  final Duration remaining;
  final bool isMath;
  final List<DiagnosticQuestion> questions;
  final Set<int> answeredQuestionIds;
  final bool completing;
  final VoidCallback onLeave;
  final ValueChanged<DiagnosticQuestion> onReviewQuestion;
  final VoidCallback onContinue;
  final VoidCallback? onOpenReference;

  const DiagnosticModuleReviewView({
    super.key,
    required this.remaining,
    required this.isMath,
    required this.questions,
    required this.answeredQuestionIds,
    required this.completing,
    required this.onLeave,
    required this.onReviewQuestion,
    required this.onContinue,
    this.onOpenReference,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
    final answeredCount = questions
        .where((question) => answeredQuestionIds.contains(question.id))
        .length;
    final unansweredCount = questions.length - answeredCount;
    final sectionLabel = isMath ? 'Math' : 'Reading & Writing';
    final continueLabel = isMath ? 'End test' : 'Continue to Math';

    return Column(
      children: [
        _ReviewHeader(
          remaining: remaining,
          isMath: isMath,
          sectionLabel: sectionLabel,
          answeredCount: answeredCount,
          questionCount: questions.length,
          compact: compact,
          onLeave: onLeave,
          onOpenReference: onOpenReference,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24,
              18,
              compact ? 16 : 24,
              28,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusCards(
                        compact: compact,
                        answeredCount: answeredCount,
                        unansweredCount: unansweredCount,
                      ),
                      const SizedBox(height: 16),
                      _NavigatorCard(
                        questions: questions,
                        answeredQuestionIds: answeredQuestionIds,
                        answeredCount: answeredCount,
                        unansweredCount: unansweredCount,
                        compact: compact,
                        continueLabel: continueLabel,
                        completing: completing,
                        onReviewQuestion: onReviewQuestion,
                        onContinue: onContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  final Duration remaining;
  final bool isMath;
  final String sectionLabel;
  final int answeredCount;
  final int questionCount;
  final bool compact;
  final VoidCallback onLeave;
  final VoidCallback? onOpenReference;

  const _ReviewHeader({
    required this.remaining,
    required this.isMath,
    required this.sectionLabel,
    required this.answeredCount,
    required this.questionCount,
    required this.compact,
    required this.onLeave,
    required this.onOpenReference,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = remaining.inSeconds <= 30;
    return Material(
      color: TuranColors.primary,
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 16,
            8,
            compact ? 12 : 18,
            16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onLeave,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Leave test',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Module Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sectionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review your answers before moving forward.',
                      style: TextStyle(
                        color: Color(0xFFD7E3FF),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    key: const Key('diagnostic-timer'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: urgent ? const Color(0xFFFFCDD2) : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      formatDiagnosticCountdown(remaining),
                      style: TextStyle(
                        color: urgent ? TuranColors.error : TuranColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2F9E),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$answeredCount/$questionCount answered',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isMath && onOpenReference != null) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      key: const Key('diagnostic-reference-button'),
                      onPressed: onOpenReference,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Reference',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
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

class _StatusCards extends StatelessWidget {
  final bool compact;
  final int answeredCount;
  final int unansweredCount;

  const _StatusCards({
    required this.compact,
    required this.answeredCount,
    required this.unansweredCount,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatusCard(
        label: 'Answered',
        count: answeredCount,
        color: _answeredColor,
        icon: Icons.check_rounded,
      ),
      _StatusCard(
        label: 'Unanswered',
        count: unansweredCount,
        color: _unansweredColor,
        icon: Icons.help_outline_rounded,
      ),
    ];
    if (compact) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 10),
          cards[1],
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
        boxShadow: [
          BoxShadow(
            color: TuranColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: TuranColors.textMid,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}

class _NavigatorCard extends StatelessWidget {
  final List<DiagnosticQuestion> questions;
  final Set<int> answeredQuestionIds;
  final int answeredCount;
  final int unansweredCount;
  final bool compact;
  final String continueLabel;
  final bool completing;
  final ValueChanged<DiagnosticQuestion> onReviewQuestion;
  final VoidCallback onContinue;

  const _NavigatorCard({
    required this.questions,
    required this.answeredQuestionIds,
    required this.answeredCount,
    required this.unansweredCount,
    required this.compact,
    required this.continueLabel,
    required this.completing,
    required this.onReviewQuestion,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('diagnostic-module-review'),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 22,
        18,
        compact ? 16 : 22,
        18,
      ),
      decoration: BoxDecoration(
        color: TuranColors.surface,
        borderRadius: BorderRadius.circular(TuranRadius.lg),
        border: Border.all(color: TuranColors.border),
        boxShadow: [
          BoxShadow(
            color: TuranColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: const [
              Text(
                'Question Navigator',
                style: TextStyle(
                  color: TuranColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                'Tap any question to review your answer',
                style: TextStyle(
                  color: TuranColors.textMid,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReviewGrid(
            questions: questions,
            answeredQuestionIds: answeredQuestionIds,
            onSelect: onReviewQuestion,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LegendSwatch(
                    color: _answeredColor,
                    fill: _answeredFill,
                    label: 'Answered ($answeredCount)',
                  ),
                  _LegendSwatch(
                    color: _unansweredColor,
                    fill: _unansweredFill,
                    label: 'Unanswered ($unansweredCount)',
                  ),
                ],
              ),
              SizedBox(
                width: compact ? double.infinity : null,
                child: ElevatedButton(
                  key: const Key('diagnostic-review-continue'),
                  onPressed: completing ? null : onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TuranColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        TuranColors.primary.withValues(alpha: 0.45),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: completing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          continueLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewGrid extends StatelessWidget {
  final List<DiagnosticQuestion> questions;
  final Set<int> answeredQuestionIds;
  final ValueChanged<DiagnosticQuestion> onSelect;

  const _ReviewGrid({
    required this.questions,
    required this.answeredQuestionIds,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 10 : 5;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = questions[index];
            final answered = answeredQuestionIds.contains(item.id);
            return _ReviewCell(
              number: index + 1,
              answered: answered,
              onTap: () => onSelect(item),
            );
          },
        );
      },
    );
  }
}

class _ReviewCell extends StatelessWidget {
  final int number;
  final bool answered;
  final VoidCallback onTap;

  const _ReviewCell({
    required this.number,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = answered ? _answeredColor : _unansweredColor;
    final fill = answered ? _answeredFill : _unansweredFill;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: Key('diagnostic-review-item-$number'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final Color fill;
  final String label;

  const _LegendSwatch({
    required this.color,
    required this.fill,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: TuranColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
