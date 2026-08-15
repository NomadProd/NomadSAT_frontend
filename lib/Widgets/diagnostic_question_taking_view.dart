import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Widgets/desmos_calculator_panel.dart';
import 'package:flutter_web/Widgets/diagnostic_math_tools.dart';
import 'package:flutter_web/Widgets/diagnostic_timer_bar.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticQuestionTakingView extends StatelessWidget {
  final Duration remaining;
  final bool isMath;
  final int sectionNumber;
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final bool completing;
  final bool calculatorOpen;
  final bool showMathToolsHint;
  final ValueChanged<String> onSelect;
  final VoidCallback? onNext;
  final VoidCallback onLeave;
  final VoidCallback onToggleCalculator;
  final VoidCallback onOpenReference;
  final VoidCallback onDismissHint;

  const DiagnosticQuestionTakingView({
    super.key,
    required this.remaining,
    required this.isMath,
    required this.sectionNumber,
    required this.question,
    required this.selectedChoice,
    required this.completing,
    required this.calculatorOpen,
    required this.showMathToolsHint,
    required this.onSelect,
    required this.onNext,
    required this.onLeave,
    required this.onToggleCalculator,
    required this.onOpenReference,
    required this.onDismissHint,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < TuranBreakpoints.desktop;
    return Column(
      children: [
        DiagnosticTimerBar(
          remaining: remaining,
          isMath: isMath,
          sectionNumber: sectionNumber,
          onLeave: onLeave,
          actions: [
            if (isMath)
              DiagnosticMathToolsBar(
                calculatorOpen: calculatorOpen,
                onToggleCalculator: onToggleCalculator,
                onOpenReference: onOpenReference,
              ),
          ],
        ),
        if (isMath && showMathToolsHint)
          DiagnosticMathToolsHint(onDismiss: onDismissHint),
        Expanded(
          child: compact
              ? Stack(
                  children: [
                    _QuestionBody(
                      compact: compact,
                      isMath: isMath,
                      question: question,
                      selectedChoice: selectedChoice,
                      completing: completing,
                      onSelect: onSelect,
                      onNext: onNext,
                    ),
                    if (isMath && calculatorOpen)
                      Positioned.fill(
                        child: DesmosCalculatorPanel(
                          onClose: onToggleCalculator,
                          expanded: true,
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _QuestionBody(
                        compact: compact,
                        isMath: isMath,
                        question: question,
                        selectedChoice: selectedChoice,
                        completing: completing,
                        onSelect: onSelect,
                        onNext: onNext,
                      ),
                    ),
                    if (isMath && calculatorOpen) ...[
                      const VerticalDivider(width: 1, color: TuranColors.border),
                      SizedBox(
                        width: 420,
                        child: DesmosCalculatorPanel(
                          onClose: onToggleCalculator,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _QuestionBody extends StatelessWidget {
  final bool compact;
  final bool isMath;
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final bool completing;
  final ValueChanged<String> onSelect;
  final VoidCallback? onNext;

  const _QuestionBody({
    required this.compact,
    required this.isMath,
    required this.question,
    required this.selectedChoice,
    required this.completing,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = isMath && question.orderIndex == 20;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24,
              16,
              compact ? 16 : 24,
              16,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        question.domain,
                        style: const TextStyle(
                          color: TuranColors.textMid,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question.questionText,
                        style: const TextStyle(
                          color: TuranColors.textDark,
                          fontSize: 17,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (question.questionImage != null &&
                          question.questionImage!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            question.questionImage!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text(
                              'Image could not be loaded.',
                              style: TextStyle(color: TuranColors.error),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      for (final choice in question.choices) ...[
                        _ChoiceTile(
                          choice: choice,
                          selected: selectedChoice == choice.key,
                          onTap: () => onSelect(choice.key),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 16 : 24,
              8,
              compact ? 16 : 24,
              16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TuranColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                    ),
                    child: completing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isLast ? 'Submit test' : 'Next'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final DiagnosticChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8EEFF) : TuranColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? TuranColors.primary : TuranColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? TuranColors.primary : TuranColors.panelBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  choice.key,
                  style: TextStyle(
                    color: selected ? Colors.white : TuranColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  choice.text,
                  style: const TextStyle(
                    color: TuranColors.textDark,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
