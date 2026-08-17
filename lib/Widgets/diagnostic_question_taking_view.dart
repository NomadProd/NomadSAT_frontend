import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Widgets/desmos_calculator_panel.dart';
import 'package:flutter_web/Widgets/diagnostic_math_tools.dart';
import 'package:flutter_web/Widgets/diagnostic_question_figure.dart';
import 'package:flutter_web/Widgets/diagnostic_question_navigator.dart';
import 'package:flutter_web/Widgets/diagnostic_timer_bar.dart';
import 'package:flutter_web/theme/turan_theme.dart';

class DiagnosticQuestionTakingView extends StatelessWidget {
  final Duration remaining;
  final bool isMath;
  final int sectionNumber;
  final int sectionQuestionCount;
  final List<DiagnosticQuestion> sectionQuestions;
  final Set<int> answeredQuestionIds;
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final bool completing;
  final bool calculatorOpen;
  final bool showMathToolsHint;
  final bool canGoBack;
  final ValueChanged<String> onSelect;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<DiagnosticQuestion> onJumpToQuestion;
  final VoidCallback onLeave;
  final VoidCallback onToggleCalculator;
  final VoidCallback onOpenReference;
  final VoidCallback onDismissHint;
  final bool isPreview;

  const DiagnosticQuestionTakingView({
    super.key,
    required this.remaining,
    required this.isMath,
    required this.sectionNumber,
    required this.sectionQuestionCount,
    required this.sectionQuestions,
    required this.answeredQuestionIds,
    required this.question,
    required this.selectedChoice,
    required this.completing,
    required this.calculatorOpen,
    required this.showMathToolsHint,
    required this.canGoBack,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
    required this.onJumpToQuestion,
    required this.onLeave,
    required this.onToggleCalculator,
    required this.onOpenReference,
    required this.onDismissHint,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TuranBreakpoints.tablet;
        return Column(
          children: [
            DiagnosticTimerBar(
              remaining: remaining,
              isMath: isMath,
              onLeave: onLeave,
              leaveTooltip: isPreview ? 'Close preview' : 'Leave test',
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
            if (isPreview)
              Material(
                color: const Color(0xFFE8EEFF),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    isMath
                        ? 'Preview — this is how students will see this Math question. Close with X. Nothing is saved until you tap Save question.'
                        : 'Preview — this is how students will see this Reading & Writing question. Close with X. Nothing is saved until you tap Save question.',
                    key: const Key('diagnostic-question-preview-banner'),
                    style: const TextStyle(
                      color: TuranColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  _QuestionBody(
                    compact: compact,
                    isMath: isMath,
                    sectionNumber: sectionNumber,
                    sectionQuestionCount: sectionQuestionCount,
                    sectionQuestions: sectionQuestions,
                    answeredQuestionIds: answeredQuestionIds,
                    question: question,
                    selectedChoice: selectedChoice,
                    completing: completing,
                    canGoBack: canGoBack,
                    onSelect: onSelect,
                    onBack: onBack,
                    onNext: onNext,
                    onJumpToQuestion: onJumpToQuestion,
                  ),
                  if (isMath && calculatorOpen)
                    Positioned.fill(
                      child: DesmosCalculatorPanel(
                        onClose: onToggleCalculator,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuestionBody extends StatelessWidget {
  final bool compact;
  final bool isMath;
  final int sectionNumber;
  final int sectionQuestionCount;
  final List<DiagnosticQuestion> sectionQuestions;
  final Set<int> answeredQuestionIds;
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final bool completing;
  final bool canGoBack;
  final ValueChanged<String> onSelect;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<DiagnosticQuestion> onJumpToQuestion;

  const _QuestionBody({
    required this.compact,
    required this.isMath,
    required this.sectionNumber,
    required this.sectionQuestionCount,
    required this.sectionQuestions,
    required this.answeredQuestionIds,
    required this.question,
    required this.selectedChoice,
    required this.completing,
    required this.canGoBack,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
    required this.onJumpToQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final splitReading = !isMath && (question.hasPassage || question.hasQuestionImage);
    return Column(
      children: [
        Expanded(
          child: splitReading
              ? (compact
                  ? _StackedReadingBody(
                      question: question,
                      selectedChoice: selectedChoice,
                      onSelect: onSelect,
                    )
                  : _SplitReadingBody(
                      question: question,
                      selectedChoice: selectedChoice,
                      onSelect: onSelect,
                    ))
              : _SingleColumnBody(
                  compact: compact,
                  question: question,
                  selectedChoice: selectedChoice,
                  onSelect: onSelect,
                ),
        ),
        Material(
          color: const Color(0xFF111827),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 16,
                10,
                compact ? 10 : 16,
                12,
              ),
              child: compact
                  ? Column(
                      children: [
                        Center(
                          child: _QuestionIndexButton(
                            sectionNumber: sectionNumber,
                            sectionQuestionCount: sectionQuestionCount,
                            onPressed: () => _openQuestionNavigator(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _FooterNavButton(
                                key: const Key('diagnostic-back-button'),
                                label: 'Back',
                                emphasized: false,
                                onPressed: canGoBack ? onBack : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _FooterNavButton(
                                key: const Key('diagnostic-next-button'),
                                label: 'Next',
                                emphasized: true,
                                busy: completing,
                                onPressed: onNext,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Expanded(child: SizedBox.shrink()),
                        _QuestionIndexButton(
                          sectionNumber: sectionNumber,
                          sectionQuestionCount: sectionQuestionCount,
                          onPressed: () => _openQuestionNavigator(context),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _FooterNavButton(
                                  key: const Key('diagnostic-back-button'),
                                  label: 'Back',
                                  emphasized: false,
                                  onPressed: canGoBack ? onBack : null,
                                ),
                                const SizedBox(width: 8),
                                _FooterNavButton(
                                  key: const Key('diagnostic-next-button'),
                                  label: 'Next',
                                  emphasized: true,
                                  busy: completing,
                                  onPressed: onNext,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _openQuestionNavigator(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) {
        return DiagnosticQuestionNavigator(
          isMath: isMath,
          questions: sectionQuestions,
          currentQuestionId: question.id,
          answeredQuestionIds: answeredQuestionIds,
          onSelect: (item) {
            Navigator.of(dialogContext).pop();
            onJumpToQuestion(item);
          },
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }
}

class _SplitReadingBody extends StatelessWidget {
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final ValueChanged<String> onSelect;

  const _SplitReadingBody({
    required this.question,
    required this.selectedChoice,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _PassagePane(question: question),
        ),
        Container(width: 1, color: TuranColors.border),
        Expanded(
          flex: 4,
          child: _TaskPane(
            question: question,
            selectedChoice: selectedChoice,
            onSelect: onSelect,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          ),
        ),
      ],
    );
  }
}

class _StackedReadingBody extends StatelessWidget {
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final ValueChanged<String> onSelect;

  const _StackedReadingBody({
    required this.question,
    required this.selectedChoice,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(
          height: 280,
          child: _PassagePane(question: question),
        ),
        Container(height: 1, color: TuranColors.border),
        _TaskPane(
          question: question,
          selectedChoice: selectedChoice,
          onSelect: onSelect,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          scrollable: false,
        ),
      ],
    );
  }
}

class _SingleColumnBody extends StatelessWidget {
  final bool compact;
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final ValueChanged<String> onSelect;

  const _SingleColumnBody({
    required this.compact,
    required this.question,
    required this.selectedChoice,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                if (question.hasQuestionImage) ...[
                  DiagnosticQuestionFigure(
                    key: const Key('diagnostic-question-image'),
                    url: question.questionImage!,
                    scale: question.imageScale,
                  ),
                  const SizedBox(height: 14),
                ],
                _QuestionPrompt(text: question.questionText),
                const SizedBox(height: 16),
                _ChoiceList(
                  question: question,
                  selectedChoice: selectedChoice,
                  onSelect: onSelect,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PassagePane extends StatelessWidget {
  final DiagnosticQuestion question;

  const _PassagePane({required this.question});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('diagnostic-passage-pane'),
      color: TuranColors.panelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'PASSAGE',
              style: TextStyle(
                color: TuranColors.textMid,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                if (question.hasQuestionImage) ...[
                  DiagnosticQuestionFigure(
                    key: const Key('diagnostic-question-image'),
                    url: question.questionImage!,
                    scale: question.imageScale,
                  ),
                  const SizedBox(height: 14),
                ],
                if (question.hasPassage)
                  Text(
                    question.passageText!,
                    key: const Key('diagnostic-passage-text'),
                    style: const TextStyle(
                      color: TuranColors.textDark,
                      fontSize: 16,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPane extends StatelessWidget {
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final ValueChanged<String> onSelect;
  final EdgeInsets padding;
  final bool scrollable;

  const _TaskPane({
    required this.question,
    required this.selectedChoice,
    required this.onSelect,
    required this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Text(
        question.domain,
        style: const TextStyle(
          color: TuranColors.textMid,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'QUESTION',
        style: TextStyle(
          color: TuranColors.textMid,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      _QuestionPrompt(text: question.questionText),
      const SizedBox(height: 16),
      _ChoiceList(
        question: question,
        selectedChoice: selectedChoice,
        onSelect: onSelect,
      ),
    ];
    return ColoredBox(
      key: const Key('diagnostic-task-pane'),
      color: TuranColors.surface,
      child: scrollable
          ? ListView(padding: padding, children: content)
          : Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            ),
    );
  }
}

class _QuestionPrompt extends StatelessWidget {
  final String text;

  const _QuestionPrompt({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: const Key('diagnostic-question-text'),
      style: const TextStyle(
        color: TuranColors.textDark,
        fontSize: 17,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ChoiceList extends StatelessWidget {
  final DiagnosticQuestion question;
  final String? selectedChoice;
  final ValueChanged<String> onSelect;

  const _ChoiceList({
    required this.question,
    required this.selectedChoice,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final choice in question.choices) ...[
          _ChoiceTile(
            choice: choice,
            selected: selectedChoice == choice.key,
            onTap: () => onSelect(choice.key),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _QuestionIndexButton extends StatelessWidget {
  final int sectionNumber;
  final int sectionQuestionCount;
  final VoidCallback onPressed;

  const _QuestionIndexButton({
    required this.sectionNumber,
    required this.sectionQuestionCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(TuranRadius.pill),
      child: InkWell(
        key: const Key('diagnostic-question-index-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TuranRadius.pill),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Question $sectionNumber of $sectionQuestionCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterNavButton extends StatelessWidget {
  final String label;
  final bool emphasized;
  final bool busy;
  final VoidCallback? onPressed;

  const _FooterNavButton({
    super.key,
    required this.label,
    required this.emphasized,
    this.busy = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: emphasized ? TuranColors.primary : const Color(0xFF9BB0D1),
        disabledBackgroundColor: emphasized
            ? TuranColors.primary.withValues(alpha: 0.45)
            : const Color(0xFF6B7C99),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(72, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        shape: const StadiumBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
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
