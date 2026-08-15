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
