class DiagnosticAnswer {
  final int questionId;
  final String? selectedChoice;
  final DateTime? answeredAt;
  final bool? isCorrect;

  const DiagnosticAnswer({
    required this.questionId,
    this.selectedChoice,
    this.answeredAt,
    this.isCorrect,
  });

  factory DiagnosticAnswer.fromJson(Map<String, dynamic> json) {
    return DiagnosticAnswer(
      questionId: json['question_id'] ?? 0,
      selectedChoice: json['selected_choice']?.toString(),
      answeredAt: _parseDateTime(json['answered_at']),
      isCorrect: json['is_correct'] as bool?,
    );
  }
}

class DiagnosticAttempt {
  final int id;
  final int studentId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status;
  final int? rwPoints;
  final int? mathPoints;
  final int? rwScaledEstimate;
  final int? mathScaledEstimate;
  final int? totalPointEstimate;
  final int? totalRangeLow;
  final int? totalRangeHigh;
  final List<DiagnosticAnswer> answers;

  const DiagnosticAttempt({
    required this.id,
    required this.studentId,
    required this.startedAt,
    required this.status,
    this.completedAt,
    this.rwPoints,
    this.mathPoints,
    this.rwScaledEstimate,
    this.mathScaledEstimate,
    this.totalPointEstimate,
    this.totalRangeLow,
    this.totalRangeHigh,
    this.answers = const [],
  });

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  factory DiagnosticAttempt.fromJson(Map<String, dynamic> json) {
    final answers = (json['answers'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => DiagnosticAnswer.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return DiagnosticAttempt(
      id: json['id'] ?? json['attempt_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      startedAt: _parseDateTime(json['started_at']) ?? DateTime.now(),
      completedAt: _parseDateTime(json['completed_at']),
      status: json['status']?.toString() ?? 'in_progress',
      rwPoints: json['rw_points'] as int?,
      mathPoints: json['math_points'] as int?,
      rwScaledEstimate: json['rw_scaled_estimate'] as int?,
      mathScaledEstimate: json['math_scaled_estimate'] as int?,
      totalPointEstimate: json['total_point_estimate'] as int?,
      totalRangeLow: json['total_range_low'] as int?,
      totalRangeHigh: json['total_range_high'] as int?,
      answers: answers,
    );
  }
}

class DiagnosticAttemptCreated {
  final int attemptId;
  final String status;
  final DateTime startedAt;

  const DiagnosticAttemptCreated({
    required this.attemptId,
    required this.status,
    required this.startedAt,
  });

  factory DiagnosticAttemptCreated.fromJson(Map<String, dynamic> json) {
    return DiagnosticAttemptCreated(
      attemptId: json['attempt_id'] ?? json['id'] ?? 0,
      status: json['status']?.toString() ?? 'in_progress',
      startedAt: _parseDateTime(json['started_at']) ?? DateTime.now(),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
