import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticQuestionNavigator extends StatelessWidget {
  final bool isMath;
  final List<DiagnosticQuestion> questions;
  final int currentQuestionId;
  final Set<int> answeredQuestionIds;
  final ValueChanged<DiagnosticQuestion> onSelect;
  final VoidCallback onClose;

  const DiagnosticQuestionNavigator({
    super.key,
    required this.isMath,
    required this.questions,
    required this.currentQuestionId,
    required this.answeredQuestionIds,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.mobile;
    final section = isMath ? 'Math' : 'Reading & Writing';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 40,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Material(
            key: const Key('diagnostic-question-list'),
            color: TuranColors.surface,
            elevation: 16,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 16 : 22,
                16,
                compact ? 12 : 16,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$section Questions',
                          style: const TextStyle(
                            color: TuranColors.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('diagnostic-question-navigator-close'),
                        tooltip: 'Close',
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: const [
                      _LegendItem(
                        icon: Icons.location_on,
                        label: 'Current',
                      ),
                      _LegendItem(
                        dashed: true,
                        label: 'Unanswered',
                      ),
                      _LegendItem(
                        icon: Icons.flag_rounded,
                        iconColor: Color(0xFFD32F2F),
                        label: 'For Review',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _QuestionGrid(
                    questions: questions,
                    currentQuestionId: currentQuestionId,
                    answeredQuestionIds: answeredQuestionIds,
                    onSelect: onSelect,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final bool dashed;
  final String label;

  const _LegendItem({
    this.icon,
    this.iconColor,
    this.dashed = false,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 16, color: iconColor ?? TuranColors.textDark)
        else
          CustomPaint(
            size: const Size(16, 16),
            painter: _DashedRectPainter(
              color: const Color(0xFF90A4C8),
              dashed: dashed,
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

class _QuestionGrid extends StatelessWidget {
  final List<DiagnosticQuestion> questions;
  final int currentQuestionId;
  final Set<int> answeredQuestionIds;
  final ValueChanged<DiagnosticQuestion> onSelect;

  const _QuestionGrid({
    required this.questions,
    required this.currentQuestionId,
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
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final item = questions[index];
            return _QuestionCell(
              number: index + 1,
              current: item.id == currentQuestionId,
              answered: answeredQuestionIds.contains(item.id),
              onTap: () => onSelect(item),
            );
          },
        );
      },
    );
  }
}

class _QuestionCell extends StatelessWidget {
  final int number;
  final bool current;
  final bool answered;
  final VoidCallback onTap;

  const _QuestionCell({
    required this.number,
    required this.current,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = current
        ? TuranColors.textDark
        : answered
            ? TuranColors.primary
            : const Color(0xFF8FB3E8);
    return InkWell(
      key: Key('diagnostic-question-nav-item-$number'),
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 14,
            child: current
                ? const Icon(
                    Icons.location_on,
                    size: 14,
                    color: TuranColors.textDark,
                  )
                : null,
          ),
          Expanded(
            child: CustomPaint(
              painter: _DashedRectPainter(
                color: borderColor,
                dashed: current || !answered,
                strokeWidth: current ? 2 : 1.4,
              ),
              child: SizedBox.expand(
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: current ? TuranColors.textDark : TuranColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  final double strokeWidth;

  const _DashedRectPainter({
    required this.color,
    required this.dashed,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    if (!dashed) {
      canvas.drawRRect(rect, paint);
      return;
    }
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 4.0;
      const gap = 3.0;
      while (distance < metric.length) {
        final next = distance + dash > metric.length
            ? metric.length
            : distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashed != dashed ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
