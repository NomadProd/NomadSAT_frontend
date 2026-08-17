import 'package:flutter_web/Models/diagnostic_question.dart';

class DiagnosticSlot {
  final int orderIndex;
  final String section;
  final String domain;
  final String difficulty;
  final int points;

  const DiagnosticSlot({
    required this.orderIndex,
    required this.section,
    required this.domain,
    required this.difficulty,
    required this.points,
  });

  bool get isMath => section == 'math';

  String get sectionLabel =>
      isMath ? 'Math' : 'Reading & Writing';
}

const kDiagnosticScoreDisclaimer =
    'This score is an approximate estimate based on a short 20-question diagnostic test. It does not replace an official SAT score and should not be used as the sole basis for academic or admissions decisions.';

const kDiagnosticQuestionCount = 20;
const kDiagnosticRwQuestionCount = 10;
const kDiagnosticMathQuestionCount = 10;
const kDiagnosticRwSeconds = 12 * 60;
const kDiagnosticMathSeconds = 15 * 60;

const kDiagnosticLayout = <DiagnosticSlot>[
  DiagnosticSlot(
    orderIndex: 1,
    section: 'reading_writing',
    domain: 'Craft and Structure',
    difficulty: 'easy',
    points: 3,
  ),
  DiagnosticSlot(
    orderIndex: 2,
    section: 'reading_writing',
    domain: 'Craft and Structure',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 3,
    section: 'reading_writing',
    domain: 'Craft and Structure',
    difficulty: 'hard',
    points: 7,
  ),
  DiagnosticSlot(
    orderIndex: 4,
    section: 'reading_writing',
    domain: 'Information and Ideas',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 5,
    section: 'reading_writing',
    domain: 'Information and Ideas',
    difficulty: 'hard',
    points: 7,
  ),
  DiagnosticSlot(
    orderIndex: 6,
    section: 'reading_writing',
    domain: 'Standard English Conventions',
    difficulty: 'easy',
    points: 3,
  ),
  DiagnosticSlot(
    orderIndex: 7,
    section: 'reading_writing',
    domain: 'Standard English Conventions',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 8,
    section: 'reading_writing',
    domain: 'Expression of Ideas',
    difficulty: 'easy',
    points: 3,
  ),
  DiagnosticSlot(
    orderIndex: 9,
    section: 'reading_writing',
    domain: 'Expression of Ideas',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 10,
    section: 'reading_writing',
    domain: 'Expression of Ideas',
    difficulty: 'hard',
    points: 7,
  ),
  DiagnosticSlot(
    orderIndex: 11,
    section: 'math',
    domain: 'Algebra',
    difficulty: 'easy',
    points: 3,
  ),
  DiagnosticSlot(
    orderIndex: 12,
    section: 'math',
    domain: 'Advanced Math',
    difficulty: 'easy',
    points: 3,
  ),
  DiagnosticSlot(
    orderIndex: 13,
    section: 'math',
    domain: 'Geometry and Trigonometry',
    difficulty: 'easy',
    points: 3,
  ),
  DiagnosticSlot(
    orderIndex: 14,
    section: 'math',
    domain: 'Algebra',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 15,
    section: 'math',
    domain: 'Advanced Math',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 16,
    section: 'math',
    domain: 'Problem-Solving and Data Analysis',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 17,
    section: 'math',
    domain: 'Problem-Solving and Data Analysis',
    difficulty: 'medium',
    points: 5,
  ),
  DiagnosticSlot(
    orderIndex: 18,
    section: 'math',
    domain: 'Advanced Math',
    difficulty: 'hard',
    points: 7,
  ),
  DiagnosticSlot(
    orderIndex: 19,
    section: 'math',
    domain: 'Problem-Solving and Data Analysis',
    difficulty: 'hard',
    points: 7,
  ),
  DiagnosticSlot(
    orderIndex: 20,
    section: 'math',
    domain: 'Geometry and Trigonometry',
    difficulty: 'hard',
    points: 7,
  ),
];

bool canManageDiagnosticBank(String role) {
  final normalized = role.toLowerCase();
  return normalized == 'admin' || normalized == 'mentor';
}

bool canViewDiagnosticBank(String role) {
  final normalized = role.toLowerCase();
  return canManageDiagnosticBank(normalized) || normalized == 'teacher';
}

DiagnosticSlot? diagnosticSlotFor(int orderIndex) {
  for (final slot in kDiagnosticLayout) {
    if (slot.orderIndex == orderIndex) return slot;
  }
  return null;
}

String? diagnosticLayoutMismatch({
  required int orderIndex,
  required String section,
  required String domain,
  required String difficulty,
  required int points,
}) {
  final slot = diagnosticSlotFor(orderIndex);
  if (slot == null) return 'order_index must be between 1 and 20';
  if (section != slot.section) {
    return 'order_index $orderIndex must use section ${slot.section}';
  }
  if (domain != slot.domain) {
    return 'order_index $orderIndex must use domain ${slot.domain}';
  }
  if (difficulty != slot.difficulty || points != slot.points) {
    return 'order_index $orderIndex must be ${slot.difficulty} with ${slot.points} points';
  }
  return null;
}

Duration diagnosticSectionRemaining({
  required DateTime now,
  required DateTime sectionStartedAt,
  required bool isMath,
}) {
  final limitSeconds = isMath ? kDiagnosticMathSeconds : kDiagnosticRwSeconds;
  final elapsed = now.difference(sectionStartedAt).inSeconds;
  final remaining = limitSeconds - elapsed;
  return Duration(seconds: remaining < 0 ? 0 : remaining);
}

String formatDiagnosticCountdown(Duration remaining) {
  final totalSeconds = remaining.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final minuteText = minutes.toString().padLeft(2, '0');
  final secondText = seconds.toString().padLeft(2, '0');
  return '$minuteText:$secondText';
}

class DiagnosticResumeState {
  final bool showBreak;
  final bool inMath;
  final DateTime sectionStartedAt;
  final int questionIndex;

  const DiagnosticResumeState({
    required this.showBreak,
    required this.inMath,
    required this.sectionStartedAt,
    required this.questionIndex,
  });
}

DiagnosticResumeState resolveDiagnosticResume({
  required List<DiagnosticQuestion> questions,
  required Set<int> savedQuestionIds,
  required DateTime startedAt,
  required DateTime now,
  DateTime? mathStartedAt,
  int? currentQuestionId,
}) {
  if (questions.isEmpty) {
    return DiagnosticResumeState(
      showBreak: false,
      inMath: false,
      sectionStartedAt: startedAt,
      questionIndex: 0,
    );
  }

  final rwQuestions = questions.where((question) => !question.isMath).toList();
  final allRwAnswered = rwQuestions.isNotEmpty &&
      rwQuestions.every((question) => savedQuestionIds.contains(question.id));
  final rwExpired = now.difference(startedAt).inSeconds >= kDiagnosticRwSeconds;
  final inMath = mathStartedAt != null;
  final showBreak = !inMath && (allRwAnswered || rwExpired);

  if (showBreak) {
    final mathIndex = questions.indexWhere((question) => question.isMath);
    return DiagnosticResumeState(
      showBreak: true,
      inMath: false,
      sectionStartedAt: startedAt,
      questionIndex: mathIndex >= 0 ? mathIndex : 0,
    );
  }

  return DiagnosticResumeState(
    showBreak: false,
    inMath: inMath,
    sectionStartedAt: mathStartedAt ?? startedAt,
    questionIndex: diagnosticResumeQuestionIndex(
      questions: questions,
      savedQuestionIds: savedQuestionIds,
      inMath: inMath,
      currentQuestionId: currentQuestionId,
    ),
  );
}

int diagnosticResumeQuestionIndex({
  required List<DiagnosticQuestion> questions,
  required Set<int> savedQuestionIds,
  required bool inMath,
  int? currentQuestionId,
}) {
  if (currentQuestionId != null) {
    final savedIndex = questions.indexWhere(
      (question) => question.id == currentQuestionId && question.isMath == inMath,
    );
    if (savedIndex >= 0) return savedIndex;
  }

  final module = questions.where((question) => question.isMath == inMath).toList();
  for (final question in module) {
    if (!savedQuestionIds.contains(question.id)) {
      return questions.indexWhere((item) => item.id == question.id);
    }
  }
  if (module.isNotEmpty) {
    return questions.indexWhere((item) => item.id == module.last.id);
  }
  return 0;
}
