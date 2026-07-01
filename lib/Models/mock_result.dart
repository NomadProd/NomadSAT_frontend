import 'package:flutter_web/Models/homework_result.dart';

class MockResultDetail {
  final int id;
  final int assignmentId;
  final int studentId;
  final bool submitted;
  final int? totalPoints;
  final int? verbalPoints;
  final int? mathPoints;
  final int? verbalIncorrect;
  final int? mathIncorrect;
  final String? weakAreas;
  final String? photoLink;
  final List<HomeworkAttachment> attachments;
  final bool legacyPhoto;

  const MockResultDetail({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.submitted,
    required this.totalPoints,
    required this.verbalPoints,
    required this.mathPoints,
    required this.verbalIncorrect,
    required this.mathIncorrect,
    required this.weakAreas,
    required this.photoLink,
    this.attachments = const [],
    this.legacyPhoto = false,
  });

  bool get isSubmittedLocked => submitted;

  factory MockResultDetail.fromJson(Map<String, dynamic> json) {
    final attachments = (json['attachments'] as List<dynamic>? ?? [])
        .map(
          (e) => HomeworkAttachment.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();

    return MockResultDetail(
      id: json['id'] ?? json['result_id'] ?? 0,
      assignmentId: json['assignment_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      submitted: json['submitted'] ?? false,
      totalPoints: json['total_points'],
      verbalPoints: json['verbal_points'],
      mathPoints: json['math_points'],
      verbalIncorrect: json['verbal_incorrect'],
      mathIncorrect: json['math_incorrect'],
      weakAreas: json['weak_areas']?.toString(),
      photoLink: json['photo_link']?.toString(),
      attachments: attachments,
      legacyPhoto: json['legacy_photo'] == true,
    );
  }
}
