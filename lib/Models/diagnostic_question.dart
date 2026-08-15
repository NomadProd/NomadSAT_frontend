class DiagnosticChoice {
  final String key;
  final String text;

  const DiagnosticChoice({required this.key, required this.text});

  factory DiagnosticChoice.fromJson(Map<String, dynamic> json) {
    return DiagnosticChoice(
      key: (json['key'] ?? '').toString().toUpperCase(),
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'text': text};
}

class DiagnosticQuestion {
  final int id;
  final String section;
  final String domain;
  final String difficulty;
  final int? points;
  final int orderIndex;
  final String questionText;
  final String? questionImage;
  final List<DiagnosticChoice> choices;
  final String? correctChoice;
  final String? explanation;

  const DiagnosticQuestion({
    required this.id,
    required this.section,
    required this.domain,
    required this.difficulty,
    required this.orderIndex,
    required this.questionText,
    required this.choices,
    this.points,
    this.questionImage,
    this.correctChoice,
    this.explanation,
  });

  bool get isMath => section == 'math';

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => DiagnosticChoice.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return DiagnosticQuestion(
      id: json['id'] ?? 0,
      section: json['section']?.toString() ?? '',
      domain: json['domain']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      points: json['points'] as int?,
      orderIndex: json['order_index'] ?? 0,
      questionText: json['question_text']?.toString() ?? '',
      questionImage: json['question_image']?.toString(),
      choices: choices,
      correctChoice: json['correct_choice']?.toString(),
      explanation: json['explanation']?.toString(),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'section': section,
      'domain': domain,
      'difficulty': difficulty,
      'points': points,
      'order_index': orderIndex,
      'question_text': questionText,
      if (questionImage != null && questionImage!.trim().isNotEmpty)
        'question_image': questionImage,
      'choices': choices.map((choice) => choice.toJson()).toList(),
      'correct_choice': correctChoice,
      if (explanation != null && explanation!.trim().isNotEmpty)
        'explanation': explanation,
    };
  }
}
