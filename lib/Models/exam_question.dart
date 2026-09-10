/// The question shape the exam-taking widgets render.
///
/// Both the diagnostic and practice tests convert their own API models into
/// this, so the timer, navigator, taking view and review views are written once.
/// It carries exactly the fields those widgets read -- nothing more.

const kExamImageScaleMin = 0.4;
const kExamImageScaleMax = 1.0;
const kExamImageScaleDefault = 0.85;

double clampExamImageScale(double? value) {
  final scale = value ?? kExamImageScaleDefault;
  if (scale.isNaN) return kExamImageScaleDefault;
  return scale.clamp(kExamImageScaleMin, kExamImageScaleMax);
}

/// How a student answers: pick a choice, or type a value into the grid-in field.
enum ExamAnswerType { multipleChoice, gridIn }

ExamAnswerType examAnswerTypeFrom(dynamic value) {
  return value?.toString() == 'spr'
      ? ExamAnswerType.gridIn
      : ExamAnswerType.multipleChoice;
}

class ExamChoice {
  final String key;
  final String text;

  const ExamChoice({required this.key, required this.text});

  factory ExamChoice.fromJson(Map<String, dynamic> json) {
    return ExamChoice(
      key: (json['key'] ?? '').toString().toUpperCase(),
      text: json['text']?.toString() ?? '',
    );
  }
}

class ExamQuestion {
  final int id;

  /// Which module this question sits in. A section has more than one module,
  /// so the section alone cannot say which questions belong together.
  final int moduleId;

  final int orderIndex;
  final bool isMath;
  final String domain;
  final String? passageText;
  final String questionText;
  final String? questionImage;
  final double imageScale;
  final ExamAnswerType answerType;
  final List<ExamChoice> choices;

  /// Review-only. Never populated while an attempt is in progress.
  final String? correctChoice;
  final List<String>? correctAnswers;
  final String? explanation;

  const ExamQuestion({
    required this.id,
    required this.orderIndex,
    required this.isMath,
    required this.domain,
    required this.questionText,
    this.moduleId = 0,
    this.passageText,
    this.questionImage,
    this.imageScale = kExamImageScaleDefault,
    this.answerType = ExamAnswerType.multipleChoice,
    this.choices = const [],
    this.correctChoice,
    this.correctAnswers,
    this.explanation,
  });

  bool get isGridIn => answerType == ExamAnswerType.gridIn;

  bool get hasPassage => (passageText?.trim() ?? '').isNotEmpty;

  bool get hasQuestionImage {
    final value = questionImage?.trim() ?? '';
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// The answer key as a student-readable string, for the review views.
  String? get correctAnswerLabel {
    if (isGridIn) {
      final answers = correctAnswers ?? const [];
      return answers.isEmpty ? null : answers.join(' or ');
    }
    return correctChoice;
  }
}

/// Grid-in field limits, per College Board: five characters, or six with a
/// leading minus sign. `%`, `$` and commas are not accepted.
const kGridInMaxLength = 5;
const kGridInMaxLengthNegative = 6;

String sanitizeGridInInput(String raw) {
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final ch = raw[i];
    if (ch == '-' && buffer.isEmpty) {
      buffer.write(ch);
      continue;
    }
    if ('0123456789./'.contains(ch)) buffer.write(ch);
  }
  final text = buffer.toString();
  final limit =
      text.startsWith('-') ? kGridInMaxLengthNegative : kGridInMaxLength;
  return text.length <= limit ? text : text.substring(0, limit);
}


/// One graded question in a completed attempt's review.
class ExamReviewAnswer {
  final int orderIndex;
  final bool isMath;
  final String domain;
  final String difficulty;
  final String questionText;
  final String? passageText;
  final String? questionImage;
  final double imageScale;
  final List<ExamChoice> choices;
  final String? selectedChoice;
  final String? responseText;
  final String? correctChoice;
  final List<String>? correctAnswers;
  final bool? isCorrect;
  final String? explanation;

  const ExamReviewAnswer({
    required this.orderIndex,
    required this.isMath,
    required this.domain,
    required this.difficulty,
    required this.questionText,
    this.choices = const [],
    this.passageText,
    this.questionImage,
    this.imageScale = kExamImageScaleDefault,
    this.selectedChoice,
    this.responseText,
    this.correctChoice,
    this.correctAnswers,
    this.isCorrect,
    this.explanation,
  });

  bool get isGridIn => choices.isEmpty;

  bool get isUnanswered {
    final given = isGridIn ? responseText : selectedChoice;
    return given == null || given.trim().isEmpty;
  }

  String get correctAnswerLabel {
    if (isGridIn) return (correctAnswers ?? const []).join(' or ');
    return correctChoice ?? '';
  }

  bool get hasExplanation => (explanation?.trim() ?? '').isNotEmpty;

  bool get hasQuestionImage => (questionImage?.trim() ?? '').isNotEmpty;
}

class ExamStudentSummary {
  final String fullName;

  const ExamStudentSummary({required this.fullName});
}

/// A completed attempt, as the review screen renders it.
class ExamAttemptReview {
  final String scoreRangeLabel;
  final ExamStudentSummary student;
  final List<ExamReviewAnswer> answers;
  final DateTime? completedAt;
  final int? rwScaled;
  final int? mathScaled;

  const ExamAttemptReview({
    required this.scoreRangeLabel,
    required this.student,
    required this.answers,
    this.completedAt,
    this.rwScaled,
    this.mathScaled,
  });
}

/// Builds a question from the taking endpoint's public payload -- the shape
/// that deliberately carries no answer key.
ExamQuestion examQuestionFromPublicJson(Map<String, dynamic> json) {
  final scale = json['image_scale'];
  return ExamQuestion(
    id: json['id'] ?? 0,
    moduleId: json['module_id'] ?? 0,
    orderIndex: json['order_index'] ?? 0,
    isMath: json['section']?.toString() == 'math',
    domain: json['domain']?.toString() ?? '',
    passageText: (json['passage_text']?.toString().trim().isEmpty ?? true)
        ? null
        : json['passage_text'].toString().trim(),
    questionText: json['question_text']?.toString() ?? '',
    questionImage: (json['question_image']?.toString().trim().isEmpty ?? true)
        ? null
        : json['question_image'].toString().trim(),
    imageScale: clampExamImageScale(scale is num ? scale.toDouble() : null),
    answerType: examAnswerTypeFrom(json['answer_type']),
    choices: (json['choices'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => ExamChoice.fromJson(Map<String, dynamic>.from(item)))
        .toList(),
  );
}
