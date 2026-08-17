import 'package:flutter/material.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Utils/diagnostic_layout.dart';
import 'package:flutter_web/Widgets/diagnostic_question_taking_view.dart';
import 'package:flutter_web/Widgets/math_reference_sheet_panel.dart';

class DiagnosticQuestionPreviewScreen extends StatefulWidget {
  final DiagnosticQuestion question;

  const DiagnosticQuestionPreviewScreen({
    super.key,
    required this.question,
  });

  @override
  State<DiagnosticQuestionPreviewScreen> createState() =>
      _DiagnosticQuestionPreviewScreenState();
}

class _DiagnosticQuestionPreviewScreenState
    extends State<DiagnosticQuestionPreviewScreen> {
  String? _selectedChoice;
  bool _calculatorOpen = false;
  bool _showMathToolsHint = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final isMath = question.isMath;
    return Scaffold(
      body: DiagnosticQuestionTakingView(
        remaining: Duration(
          seconds: isMath ? kDiagnosticMathSeconds : kDiagnosticRwSeconds,
        ),
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
