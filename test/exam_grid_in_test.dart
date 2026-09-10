import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Widgets/exam_question_taking_view.dart';

ExamQuestion _gridIn() => const ExamQuestion(
      id: 11,
      orderIndex: 1,
      isMath: true,
      domain: 'Algebra',
      questionText: 'What is two thirds?',
      answerType: ExamAnswerType.gridIn,
    );

Widget _taking(ExamQuestion question, ValueChanged<String> onSelect) {
  return MaterialApp(
    home: Scaffold(
      body: ExamQuestionTakingView(
        remaining: const Duration(minutes: 35),
        isMath: question.isMath,
        sectionNumber: 1,
        sectionQuestionCount: 1,
        sectionQuestions: [question],
        answeredQuestionIds: const <int>{},
        question: question,
        selectedChoice: null,
        completing: false,
        calculatorOpen: false,
        showMathToolsHint: false,
        canGoBack: false,
        onSelect: onSelect,
        onBack: null,
        onNext: () {},
        onJumpToQuestion: (_) {},
        onLeave: () {},
        onToggleCalculator: () {},
        onOpenReference: () {},
        onDismissHint: () {},
      ),
    ),
  );
}

void main() {
  group('sanitizeGridInInput', () {
    test('keeps digits, a decimal point and a fraction slash', () {
      expect(sanitizeGridInInput('3/4'), '3/4');
      expect(sanitizeGridInInput('.666'), '.666');
      expect(sanitizeGridInInput('12'), '12');
    });

    test('drops the symbols College Board does not accept', () {
      expect(sanitizeGridInInput('50%'), '50');
      expect(sanitizeGridInInput(r'$5'), '5');
      expect(sanitizeGridInInput('1,000'), '1000');
      expect(sanitizeGridInInput('3 1/2'), '31/2');
    });

    test('allows a minus only in the leading position', () {
      expect(sanitizeGridInInput('-1/2'), '-1/2');
      expect(sanitizeGridInInput('1-2'), '12');
    });

    test('caps at five characters, or six with a minus sign', () {
      expect(sanitizeGridInInput('0.66667'), '0.666');
      expect(sanitizeGridInInput('-0.66667'), '-0.666');
      expect(sanitizeGridInInput('123456789'), '12345');
    });

    test('handles empty and junk input', () {
      expect(sanitizeGridInInput(''), '');
      expect(sanitizeGridInInput('abc'), '');
    });
  });

  testWidgets('a grid-in question shows a typed field, not choices',
      (tester) async {
    await tester.pumpWidget(_taking(_gridIn(), (_) {}));

    expect(find.byKey(const Key('exam-grid-in-field')), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('typing into the grid-in field reports the sanitized answer',
      (tester) async {
    final reported = <String>[];
    await tester.pumpWidget(_taking(_gridIn(), reported.add));

    await tester.enterText(
      find.byKey(const Key('exam-grid-in-field')),
      r'$0.66667',
    );
    await tester.pump();

    expect(reported.last, '0.666');
    expect(
      tester.widget<TextField>(find.byKey(const Key('exam-grid-in-field')))
          .controller!
          .text,
      '0.666',
    );
  });

  testWidgets('a multiple-choice question still shows its choices',
      (tester) async {
    const mcq = ExamQuestion(
      id: 1,
      orderIndex: 1,
      isMath: false,
      domain: 'Craft and Structure',
      questionText: 'Reading stem',
      choices: [
        ExamChoice(key: 'A', text: 'One'),
        ExamChoice(key: 'B', text: 'Two'),
      ],
    );
    await tester.pumpWidget(_taking(mcq, (_) {}));

    expect(find.byKey(const Key('exam-grid-in-field')), findsNothing);
    expect(find.text('One'), findsOneWidget);
  });
}
