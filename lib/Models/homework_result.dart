class HomeworkFile {
  final int id;
  final String url;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final DateTime uploadedAt;

  const HomeworkFile({
    required this.id,
    required this.url,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  factory HomeworkFile.fromJson(Map<String, dynamic> json) {
    return HomeworkFile(
      id: json['id'] ?? 0,
      url: json['url']?.toString() ?? '',
      filename: json['filename']?.toString() ?? 'file',
      contentType: json['content_type']?.toString() ?? '',
      sizeBytes: json['size_bytes'] ?? 0,
      uploadedAt:
          _parseDateTime(json['uploaded_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';

  double get sizeMb => sizeBytes / 1024 / 1024;
}

class HomeworkResult {
  final int id;
  final int assignmentId;
  final bool submitted;
  final DateTime? submittedAt;
  final String? photoLink;
  final int? correctTotal;
  final int? incorrectTotal;
  final String? analysis;
  final DateTime? returnedAt;
  final int? returnedById;
  final String? returnReason;
  final List<HomeworkFile> attachments;
  final bool legacyPhoto;

  const HomeworkResult({
    required this.id,
    required this.assignmentId,
    required this.submitted,
    required this.submittedAt,
    required this.photoLink,
    required this.correctTotal,
    required this.incorrectTotal,
    required this.analysis,
    required this.returnedAt,
    required this.returnedById,
    required this.returnReason,
    this.attachments = const [],
    this.legacyPhoto = false,
  });

  bool get isReturnedForRevision =>
      !submitted && returnedAt != null;

  bool get isSubmittedLocked => submitted && !isReturnedForRevision;

  factory HomeworkResult.fromJson(Map<String, dynamic> json) {
    final attachments = (json['attachments'] as List<dynamic>? ?? [])
        .map((e) => HomeworkFile.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return HomeworkResult(
      id: json['id'] ?? json['result_id'] ?? 0,
      assignmentId: json['assignment_id'] ?? 0,
      submitted: json['submitted'] ?? false,
      submittedAt: _parseDateTime(json['submitted_at']),
      photoLink: json['photo_link']?.toString(),
      correctTotal: json['correct_total'],
      incorrectTotal: json['incorrect_total'],
      analysis: json['analysis']?.toString(),
      returnedAt: _parseDateTime(json['returned_at']),
      returnedById: json['returned_by_id'],
      returnReason: json['return_reason']?.toString(),
      attachments: attachments,
      legacyPhoto: json['legacy_photo'] == true,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
