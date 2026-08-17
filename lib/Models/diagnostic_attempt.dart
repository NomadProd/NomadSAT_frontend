import 'package:flutter_web/Models/diagnostic_question.dart';

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
  final DateTime? mathStartedAt;
  final int? currentQuestionId;
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
    this.mathStartedAt,
    this.currentQuestionId,
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
      mathStartedAt: _parseDateTime(json['math_started_at']),
      currentQuestionId: json['current_question_id'] as int?,
      answers: answers,
    );
  }
}

class DiagnosticStudentSummary {
  final int id;
  final String name;
  final String surname;

  const DiagnosticStudentSummary({
    required this.id,
    required this.name,
    required this.surname,
  });

  String get fullName => '$name $surname'.trim();

  factory DiagnosticStudentSummary.fromJson(Map<String, dynamic> json) {
    return DiagnosticStudentSummary(
      id: json['id'] ?? json['user_id'] ?? 0,
      name: json['name']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
    );
  }
}

class DiagnosticAttemptListItem {
  final int attemptId;
  final int studentId;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? rwPoints;
  final int? mathPoints;
  final int? rwScaledEstimate;
  final int? mathScaledEstimate;
  final int? totalPointEstimate;
  final int? totalRangeLow;
  final int? totalRangeHigh;
  final DiagnosticStudentSummary? student;

  const DiagnosticAttemptListItem({
    required this.attemptId,
    required this.studentId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.rwPoints,
    this.mathPoints,
    this.rwScaledEstimate,
    this.mathScaledEstimate,
    this.totalPointEstimate,
    this.totalRangeLow,
    this.totalRangeHigh,
    this.student,
  });

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  String get scoreRangeLabel {
    final low = totalRangeLow;
    final high = totalRangeHigh;
    if (low == null || high == null) return 'Score pending';
    return '$low–$high';
  }

  factory DiagnosticAttemptListItem.fromJson(Map<String, dynamic> json) {
    final studentJson = json['student'];
    return DiagnosticAttemptListItem(
      attemptId: json['attempt_id'] ?? json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      status: json['status']?.toString() ?? 'in_progress',
      startedAt: _parseDateTime(json['started_at']) ?? DateTime.now(),
      completedAt: _parseDateTime(json['completed_at']),
      rwPoints: json['rw_points'] as int?,
      mathPoints: json['math_points'] as int?,
      rwScaledEstimate: json['rw_scaled_estimate'] as int?,
      mathScaledEstimate: json['math_scaled_estimate'] as int?,
      totalPointEstimate: json['total_point_estimate'] as int?,
      totalRangeLow: json['total_range_low'] as int?,
      totalRangeHigh: json['total_range_high'] as int?,
      student: studentJson is Map
          ? DiagnosticStudentSummary.fromJson(
              Map<String, dynamic>.from(studentJson),
            )
          : null,
    );
  }
}

class DiagnosticAnswerReview {
  final int orderIndex;
  final String section;
  final String domain;
  final String difficulty;
  final int points;
  final String questionText;
  final String? passageText;
  final String? questionImage;
  final double imageScale;
  final List<DiagnosticChoice> choices;
  final String? selectedChoice;
  final String correctChoice;
  final bool? isCorrect;
  final String? explanation;

  const DiagnosticAnswerReview({
    required this.orderIndex,
    required this.section,
    required this.domain,
    required this.difficulty,
    required this.points,
    required this.questionText,
    required this.choices,
    required this.correctChoice,
    this.passageText,
    this.questionImage,
    this.imageScale = kDiagnosticImageScaleDefault,
    this.selectedChoice,
    this.isCorrect,
    this.explanation,
  });

  bool get isMath => section == 'math';
  bool get isUnanswered =>
      selectedChoice == null || selectedChoice!.trim().isEmpty;
  bool get hasExplanation {
    final value = explanation?.trim() ?? '';
    return value.isNotEmpty;
  }

  bool get hasQuestionImage {
    final value = questionImage?.trim() ?? '';
    return value.isNotEmpty;
  }

  factory DiagnosticAnswerReview.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => DiagnosticChoice.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return DiagnosticAnswerReview(
      orderIndex: json['order_index'] ?? 0,
      section: json['section']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      points: json['points'] ?? 0,
      questionText: json['question_text']?.toString() ?? '',
      passageText: json['passage_text']?.toString(),
      questionImage: json['question_image']?.toString(),
      imageScale: _parseReviewImageScale(json['image_scale']),
      choices: choices,
      selectedChoice: json['selected_choice']?.toString(),
      correctChoice: json['correct_choice']?.toString() ?? '',
      isCorrect: json['is_correct'] as bool?,
      explanation: json['explanation']?.toString(),
    );
  }
}

double _parseReviewImageScale(dynamic value) {
  if (value is num) return clampDiagnosticImageScale(value.toDouble());
  return clampDiagnosticImageScale(double.tryParse(value?.toString() ?? ''));
}

class DiagnosticAttemptDetail {
  final int attemptId;
  final DiagnosticStudentSummary student;
  final DateTime? completedAt;
  final String status;
  final int? rwPoints;
  final int? mathPoints;
  final int? rwScaledEstimate;
  final int? mathScaledEstimate;
  final int? totalPointEstimate;
  final int? totalRangeLow;
  final int? totalRangeHigh;
  final List<DiagnosticAnswerReview> answers;

  const DiagnosticAttemptDetail({
    required this.attemptId,
    required this.student,
    required this.status,
    required this.answers,
    this.completedAt,
    this.rwPoints,
    this.mathPoints,
    this.rwScaledEstimate,
    this.mathScaledEstimate,
    this.totalPointEstimate,
    this.totalRangeLow,
    this.totalRangeHigh,
  });

  String get scoreRangeLabel {
    final low = totalRangeLow;
    final high = totalRangeHigh;
    if (low == null || high == null) return 'Score pending';
    return '$low–$high';
  }

  factory DiagnosticAttemptDetail.fromJson(Map<String, dynamic> json) {
    final answers = (json['answers'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map(
          (item) => DiagnosticAnswerReview.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final studentJson = json['student'];
    return DiagnosticAttemptDetail(
      attemptId: json['attempt_id'] ?? json['id'] ?? 0,
      student: DiagnosticStudentSummary.fromJson(
        studentJson is Map
            ? Map<String, dynamic>.from(studentJson)
            : const <String, dynamic>{},
      ),
      completedAt: _parseDateTime(json['completed_at']),
      status: json['status']?.toString() ?? 'completed',
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
