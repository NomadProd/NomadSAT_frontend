import 'package:flutter/material.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Widgets/exam_question_taking_view.dart';
import 'package:flutter_web/Widgets/math_reference_sheet_panel.dart';

class ExamQuestionPreviewScreen extends StatefulWidget {
  final ExamQuestion question;
  final Duration remaining;

  const ExamQuestionPreviewScreen({
    super.key,
    required this.question,
    required this.remaining,
  });

  @override
  State<ExamQuestionPreviewScreen> createState() =>
      _ExamQuestionPreviewScreenState();
}

class _ExamQuestionPreviewScreenState
    extends State<ExamQuestionPreviewScreen> {
  String? _selectedChoice;
  bool _calculatorOpen = false;
  bool _showMathToolsHint = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final isMath = question.isMath;
    return Scaffold(
      body: ExamQuestionTakingView(
        remaining: widget.remaining,
        isMath: isMath,
        sectionNumber: 1,
        sectionQuestionCount: 1,
        sectionQuestions: [question],
        answeredQuestionIds:
            _selectedChoice == null ? const <int>{} : {question.id},
        question: question,
        selectedChoice: _selectedChoice,
        completing: false,
        calculatorOpen: _calculatorOpen,
        showMathToolsHint: _showMathToolsHint,
        canGoBack: false,
        isPreview: true,
        onSelect: (choice) => setState(() => _selectedChoice = choice),
        onBack: null,
        onNext: () {},
        onJumpToQuestion: (_) {},
        onLeave: () => Navigator.of(context).pop(),
        onToggleCalculator: () {
          setState(() => _calculatorOpen = !_calculatorOpen);
        },
        onOpenReference: () {
          showMathReferenceSheet(context);
        },
        onDismissHint: () {
          setState(() => _showMathToolsHint = false);
        },
      ),
    );
  }
}
