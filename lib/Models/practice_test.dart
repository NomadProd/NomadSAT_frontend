import 'package:flutter_web/Models/exam_question.dart';

String? _optionalText(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

class PracticeTestModuleInfo {
  final int id;
  final String name;
  final String section;
  final int orderIndex;
  final int timeLimitSeconds;
  final int requiredQuestionCount;
  final int questionCount;

  const PracticeTestModuleInfo({
    required this.id,
    required this.name,
    required this.section,
    required this.orderIndex,
    required this.timeLimitSeconds,
    required this.requiredQuestionCount,
    required this.questionCount,
  });

  bool get isMath => section == 'math';
  String get sectionLabel => isMath ? 'Math' : 'Reading & Writing';
  String get label => name.isEmpty ? sectionLabel : name;
  int get minutes => timeLimitSeconds ~/ 60;
  bool get isComplete => questionCount == requiredQuestionCount;

  factory PracticeTestModuleInfo.fromJson(Map<String, dynamic> json) {
    return PracticeTestModuleInfo(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      orderIndex: json['order_index'] ?? 0,
      timeLimitSeconds: json['time_limit_seconds'] ?? 0,
      requiredQuestionCount: json['required_question_count'] ?? 0,
      questionCount: json['question_count'] ?? 0,
    );
  }
}

class PracticeTestInfo {
  final int id;
  final String title;
  final String? description;
  final bool visible;
  final bool isPublishable;
  final List<int> classIds;
  final List<PracticeTestModuleInfo> modules;

  const PracticeTestInfo({
    required this.id,
    required this.title,
    required this.visible,
    required this.isPublishable,
    this.description,
    this.classIds = const [],
    this.modules = const [],
  });

  int get questionCount =>
      modules.fold(0, (total, module) => total + module.questionCount);

  int get requiredQuestionCount =>
      modules.fold(0, (total, module) => total + module.requiredQuestionCount);

  /// The module blocking publication, or null when the test is complete.
  PracticeTestModuleInfo? get firstIncompleteModule {
    for (final module in modules) {
      if (!module.isComplete) return module;
    }
    return null;
  }

  factory PracticeTestInfo.fromJson(Map<String, dynamic> json) {
    return PracticeTestInfo(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: _optionalText(json['description']),
      visible: json['visible'] == true,
      isPublishable: json['is_publishable'] == true,
      classIds: (json['class_ids'] as List<dynamic>? ?? [])
          .whereType<num>()
          .map((item) => item.toInt())
          .toList(),
      modules: (json['modules'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) =>
              PracticeTestModuleInfo.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

/// A question as its author sees it -- answer key included.
class PracticeTestQuestionAdmin {
  final int id;
  final int moduleId;
  final int orderIndex;
  final String domain;
  final String difficulty;
  final String? passageText;
  final String questionText;
  final String? explanation;
  final String? questionImage;
  final String? questionImagePublicId;
  final double imageScale;
  final String answerType;
  final List<ExamChoice> choices;
  final String? correctChoice;
  final List<String> correctAnswers;

  const PracticeTestQuestionAdmin({
    required this.id,
    required this.moduleId,
    required this.orderIndex,
    required this.domain,
    required this.difficulty,
    required this.questionText,
    required this.answerType,
    this.passageText,
    this.explanation,
    this.questionImage,
    this.questionImagePublicId,
    this.imageScale = kExamImageScaleDefault,
    this.choices = const [],
    this.correctChoice,
    this.correctAnswers = const [],
  });

  bool get isGridIn => answerType == 'spr';

  factory PracticeTestQuestionAdmin.fromJson(Map<String, dynamic> json) {
    return PracticeTestQuestionAdmin(
      id: json['id'] ?? 0,
      moduleId: json['module_id'] ?? 0,
      orderIndex: json['order_index'] ?? 0,
      domain: json['domain']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'easy',
      passageText: _optionalText(json['passage_text']),
      questionText: json['question_text']?.toString() ?? '',
      explanation: _optionalText(json['explanation']),
      questionImage: _optionalText(json['question_image']),
      questionImagePublicId: _optionalText(json['question_image_public_id']),
      imageScale: clampExamImageScale(
        json['image_scale'] is num ? (json['image_scale'] as num).toDouble() : null,
      ),
      answerType: json['answer_type']?.toString() ?? 'mcq',
      choices: (json['choices'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => ExamChoice.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      correctChoice: _optionalText(json['correct_choice']),
      correctAnswers: (json['correct_answers'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'order_index': orderIndex,
      'domain': domain,
      'difficulty': difficulty,
      'passage_text': passageText,
      'question_text': questionText,
      'explanation': explanation,
      'question_image': questionImage,
      'question_image_public_id': questionImagePublicId,
      'image_scale': clampExamImageScale(imageScale),
      'answer_type': answerType,
      'choices': isGridIn
          ? null
          : choices
              .map((choice) => {'key': choice.key, 'text': choice.text})
              .toList(),
      'correct_choice': isGridIn ? null : correctChoice,
      'correct_answers': isGridIn ? correctAnswers : null,
    };
  }

  ExamQuestion toExamQuestion({required bool isMath}) {
    return ExamQuestion(
      id: id,
      moduleId: moduleId,
      orderIndex: orderIndex,
      isMath: isMath,
      domain: domain,
      passageText: passageText,
      questionText: questionText,
      questionImage: questionImage,
      imageScale: imageScale,
      answerType:
          isGridIn ? ExamAnswerType.gridIn : ExamAnswerType.multipleChoice,
      choices: choices,
      correctChoice: correctChoice,
      correctAnswers: correctAnswers,
      explanation: explanation,
    );
  }
}

DateTime? _optionalDate(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

class PracticeTestAttempt {
  final int id;
  final int testId;
  final String? testTitle;
  final int studentId;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? currentModuleId;
  final int? currentQuestionId;
  final DateTime? moduleStartedAt;
  final DateTime? timerPausedAt;
  final int timerPauseSeconds;
  final int? rwRaw;
  final int? mathRaw;
  final int? rwScaled;
  final int? mathScaled;
  final int? totalScaled;

  const PracticeTestAttempt({
    required this.id,
    required this.testId,
    required this.studentId,
    required this.status,
    this.testTitle,
    this.startedAt,
    this.completedAt,
    this.currentModuleId,
    this.currentQuestionId,
    this.moduleStartedAt,
    this.timerPausedAt,
    this.timerPauseSeconds = 0,
    this.rwRaw,
    this.mathRaw,
    this.rwScaled,
    this.mathScaled,
    this.totalScaled,
  });

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';

  factory PracticeTestAttempt.fromJson(Map<String, dynamic> json) {
    return PracticeTestAttempt(
      id: json['id'] ?? json['attempt_id'] ?? 0,
      testId: json['test_id'] ?? 0,
      testTitle: _optionalText(json['test_title']),
      studentId: json['student_id'] ?? 0,
      status: json['status']?.toString() ?? 'in_progress',
      startedAt: _optionalDate(json['started_at']),
      completedAt: _optionalDate(json['completed_at']),
      currentModuleId: json['current_module_id'],
      currentQuestionId: json['current_question_id'],
      moduleStartedAt: _optionalDate(json['module_started_at']),
      timerPausedAt: _optionalDate(json['timer_paused_at']),
      timerPauseSeconds: json['timer_pause_seconds'] ?? 0,
      rwRaw: json['rw_raw'],
      mathRaw: json['math_raw'],
      rwScaled: json['rw_scaled'],
      mathScaled: json['math_scaled'],
      totalScaled: json['total_scaled'],
    );
  }
}

class PracticeTestAttemptDetail {
  final PracticeTestAttempt attempt;
  final String studentName;
  final List<ExamReviewAnswer> items;

  const PracticeTestAttemptDetail({
    required this.attempt,
    required this.studentName,
    required this.items,
  });

  ExamAttemptReview toExamReview() {
    return ExamAttemptReview(
      scoreRangeLabel: '${attempt.totalScaled ?? '—'}',
      student: ExamStudentSummary(fullName: studentName),
      answers: items,
      completedAt: attempt.completedAt,
      rwScaled: attempt.rwScaled,
      mathScaled: attempt.mathScaled,
    );
  }

  factory PracticeTestAttemptDetail.fromJson(Map<String, dynamic> json) {
    final attempt = PracticeTestAttempt.fromJson(
      Map<String, dynamic>.from(json['attempt'] as Map? ?? {}),
    );
    final student = Map<String, dynamic>.from(json['student'] as Map? ?? {});
    final items = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final question = PracticeTestQuestionAdmin.fromJson(
        Map<String, dynamic>.from(item['question'] as Map? ?? {}),
      );
      return ExamReviewAnswer(
        orderIndex: question.orderIndex,
        isMath: item['section']?.toString() == 'math',
        domain: question.domain,
        difficulty: question.difficulty,
        questionText: question.questionText,
        passageText: question.passageText,
        questionImage: question.questionImage,
        imageScale: question.imageScale,
        choices: question.choices,
        selectedChoice: _optionalText(item['selected_choice']),
        responseText: _optionalText(item['response_text']),
        correctChoice: question.correctChoice,
        correctAnswers: question.correctAnswers,
        isCorrect: item['is_correct'] == true,
        explanation: question.explanation,
      );
    }).toList();

    return PracticeTestAttemptDetail(
      attempt: attempt,
      studentName: [
        student['name']?.toString() ?? '',
        student['surname']?.toString() ?? '',
      ].where((part) => part.isNotEmpty).join(' '),
      items: items,
    );
  }
}
