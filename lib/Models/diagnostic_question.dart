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

String? _optionalText(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

const kDiagnosticImageScaleMin = 0.4;
const kDiagnosticImageScaleMax = 1.0;
const kDiagnosticImageScaleDefault = 0.85;

double clampDiagnosticImageScale(double? value) {
  final scale = value ?? kDiagnosticImageScaleDefault;
  if (scale.isNaN) return kDiagnosticImageScaleDefault;
  return scale.clamp(kDiagnosticImageScaleMin, kDiagnosticImageScaleMax);
}

double _parseImageScale(dynamic value) {
  if (value is num) return clampDiagnosticImageScale(value.toDouble());
  return clampDiagnosticImageScale(double.tryParse(value?.toString() ?? ''));
}

class DiagnosticQuestion {
  final int id;
  final String section;
  final String domain;
  final String difficulty;
  final int? points;
  final int orderIndex;
  final String? passageText;
  final String questionText;
  final String? questionUrl;
  final String? questionImage;
  final String? questionImagePublicId;
  final double imageScale;
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
    this.passageText,
    this.questionUrl,
    this.questionImage,
    this.questionImagePublicId,
    this.imageScale = kDiagnosticImageScaleDefault,
    this.correctChoice,
    this.explanation,
  });

  bool get isMath => section == 'math';

  bool get hasPassage {
    final value = passageText?.trim() ?? '';
    return value.isNotEmpty;
  }

  bool get hasQuestionImage {
    final value = questionImage?.trim() ?? '';
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

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
      passageText: _optionalText(json['passage_text']),
      questionText: json['question_text']?.toString() ?? '',
      questionUrl: _optionalText(json['question_url']),
      questionImage: _optionalText(json['question_image']),
      questionImagePublicId: _optionalText(json['question_image_public_id']),
      imageScale: _parseImageScale(json['image_scale']),
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
      'passage_text': passageText,
      'question_text': questionText,
      'question_url': questionUrl,
      'question_image': questionImage,
      'question_image_public_id': questionImagePublicId,
      'image_scale': clampDiagnosticImageScale(imageScale),
      'choices': choices.map((choice) => choice.toJson()).toList(),
      'correct_choice': correctChoice,
      'explanation': explanation,
    };
  }
}
