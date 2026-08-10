class UserInfo {
  final int userId;
  final String name;
  final String surname;
  final String? email;
  final String role;

  UserInfo({
    required this.userId,
    required this.name,
    required this.surname,
    this.email,
    required this.role,
  });

  String get fullName => '$name $surname'.trim();

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
    );
  }
}

class ClassInfo {
  final int classId;
  final String className;

  final int? verbalTeacherId;
  final int? mathTeacherId;

  final String? verbalTeacherName;
  final String? verbalTeacherSurname;
  final String? mathTeacherName;
  final String? mathTeacherSurname;
  final bool archived;

  ClassInfo({
    required this.classId,
    required this.className,
    this.verbalTeacherId,
    this.mathTeacherId,
    this.verbalTeacherName,
    this.verbalTeacherSurname,
    this.mathTeacherName,
    this.mathTeacherSurname,
    this.archived = false,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      classId: json['class_id'] ?? 0,
      className: json['class_name'] ?? '',
      verbalTeacherId: json['verbal_teacher_id'],
      mathTeacherId: json['math_teacher_id'],
      verbalTeacherName: json['verbal_teacher_name'],
      verbalTeacherSurname: json['verbal_teacher_surname'],
      mathTeacherName: json['math_teacher_name'],
      mathTeacherSurname: json['math_teacher_surname'],
      archived: json['archived'] == true,
    );
  }
}

class SessionInfo {
  final int sessionId;
  final int classId;
  final int? teacherId;
  final String date;
  final String? startTime;
  final String? endTime;
  final String sessionType;
  final String? topic;
  final int? academicPlanItemId;
  final List<int> academicPlanItemIds;
  final String? lessonNotes;

  SessionInfo({
    required this.sessionId,
    required this.classId,
    required this.teacherId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.sessionType,
    required this.topic,
    required this.academicPlanItemId,
    required this.academicPlanItemIds,
    required this.lessonNotes,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sessionId: json['session_id'] ?? 0,
      classId: json['class_id'] ?? 0,
      teacherId: json['teacher_id'],
      date: json['date']?.toString() ?? '',
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      sessionType: json['session_type'] ?? '',
      topic: json['topic']?.toString(),
      academicPlanItemId: json['academic_plan_item_id'],
      academicPlanItemIds:
          (json['academic_plan_item_ids'] as List<dynamic>? ?? [])
              .map((e) => e as int)
              .toList(),
      lessonNotes: json['lesson_notes']?.toString(),
    );
  }
}

class HomeworkDocument {
  final String url;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final String? uploadedAt;

  const HomeworkDocument({
    required this.url,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    this.uploadedAt,
  });

  factory HomeworkDocument.fromJson(Map<String, dynamic> json) {
    final secureUrl = json['secure_url']?.toString();
    final url = (secureUrl != null && secureUrl.isNotEmpty)
        ? secureUrl
        : (json['url']?.toString() ?? '');
    return HomeworkDocument(
      url: url,
      filename: json['filename']?.toString() ?? 'homework.pdf',
      contentType: json['content_type']?.toString() ?? 'application/pdf',
      sizeBytes: json['size_bytes'] is num
          ? (json['size_bytes'] as num).toInt()
          : int.tryParse('${json['size_bytes']}') ?? 0,
      uploadedAt: json['uploaded_at']?.toString(),
    );
  }

  double get sizeMb => sizeBytes / (1024 * 1024);
}

HomeworkDocument? parseHomeworkDocument(dynamic value) {
  if (value is Map<String, dynamic>) {
    return HomeworkDocument.fromJson(value);
  }
  if (value is Map) {
    return HomeworkDocument.fromJson(Map<String, dynamic>.from(value));
  }
  return null;
}

class AssignmentInfo {
  final int assignmentId;
  final int sessionId;
  final int studentId;
  final int? slotIndex;
  final String? title;
  final String? instruction;
  final String? taskLink;
  final String? dueDate;
  final String? dueTime;
  final bool photoRequired;
  final HomeworkDocument? homeworkDocument;

  AssignmentInfo({
    required this.assignmentId,
    required this.sessionId,
    required this.studentId,
    required this.slotIndex,
    required this.title,
    required this.instruction,
    required this.taskLink,
    required this.dueDate,
    required this.dueTime,
    required this.photoRequired,
    this.homeworkDocument,
  });

  factory AssignmentInfo.fromJson(Map<String, dynamic> json) {
    return AssignmentInfo(
      assignmentId: json['assignment_id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      slotIndex: json['slot_index'],
      title: json['title']?.toString(),
      instruction: json['instruction']?.toString(),
      taskLink: json['task_link']?.toString(),
      dueDate: json['due_date']?.toString(),
      dueTime: json['due_time']?.toString(),
      photoRequired: json['photo_required'] ?? false,
      homeworkDocument: parseHomeworkDocument(json['homework_document']),
    );
  }

  AssignmentInfo copyWith({
    int? assignmentId,
    int? sessionId,
    int? studentId,
    int? slotIndex,
    String? title,
    String? instruction,
    String? taskLink,
    String? dueDate,
    String? dueTime,
    bool? photoRequired,
    HomeworkDocument? homeworkDocument,
    bool clearHomeworkDocument = false,
  }) {
    return AssignmentInfo(
      assignmentId: assignmentId ?? this.assignmentId,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      slotIndex: slotIndex ?? this.slotIndex,
      title: title ?? this.title,
      instruction: instruction ?? this.instruction,
      taskLink: taskLink ?? this.taskLink,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      photoRequired: photoRequired ?? this.photoRequired,
      homeworkDocument: clearHomeworkDocument
          ? null
          : (homeworkDocument ?? this.homeworkDocument),
    );
  }
}

class AttendanceInfo {
  static const String present = 'present';
  static const String absent = 'absent';
  static const String excused = 'excused';

  final int attendanceId;
  final int sessionId;
  final int studentId;
  final String status;

  AttendanceInfo({
    required this.attendanceId,
    required this.sessionId,
    required this.studentId,
    required this.status,
  });

  bool get isPresent => status == present;
  bool get isAbsent => status == absent;
  bool get isExcused => status == excused;

  String get statusLabel {
    switch (status) {
      case present:
        return 'Present';
      case excused:
        return 'Excused';
      case absent:
      default:
        return 'Absent';
    }
  }

  /// Cycle: present → absent → excused → present
  String get nextStatus {
    switch (status) {
      case present:
        return absent;
      case absent:
        return excused;
      case excused:
        return present;
      default:
        return present;
    }
  }

  factory AttendanceInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceInfo(
      attendanceId: json['attendance_id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      status: _parseAttendanceStatus(json['status']),
    );
  }
}

String _parseAttendanceStatus(dynamic raw) {
  if (raw is bool) {
    return raw ? AttendanceInfo.present : AttendanceInfo.absent;
  }
  final value = (raw ?? '').toString().trim().toLowerCase();
  if (value == AttendanceInfo.present ||
      value == AttendanceInfo.absent ||
      value == AttendanceInfo.excused) {
    return value;
  }
  return AttendanceInfo.absent;
}

class HomeworkResultInfo {
  final int resultId;
  final int? historyId;
  final bool isHistorical;
  final int assignmentId;
  final int studentId;
  final bool submitted;
  final String? submittedAt;
  final String? photoLink;
  final int? correctTotal;
  final int? incorrectTotal;
  final String? analysis;
  final double? accuracy;

  HomeworkResultInfo({
    required this.resultId,
    this.historyId,
    this.isHistorical = false,
    required this.assignmentId,
    required this.studentId,
    required this.submitted,
    required this.submittedAt,
    required this.photoLink,
    required this.correctTotal,
    required this.incorrectTotal,
    required this.analysis,
    required this.accuracy,
  });

  factory HomeworkResultInfo.fromJson(Map<String, dynamic> json) {
    return HomeworkResultInfo(
      resultId: json['result_id'] ?? json['id'] ?? 0,
      historyId: json['history_id'] as int?,
      isHistorical: json['is_historical'] == true,
      assignmentId: json['assignment_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      submitted: json['submitted'] ?? false,
      submittedAt: json['submitted_at']?.toString(),
      photoLink: json['photo_link']?.toString(),
      correctTotal: json['correct_total'],
      incorrectTotal: json['incorrect_total'],
      analysis: json['analysis']?.toString(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }
}

class HomeworkFileInfo {
  final int id;
  final String? publicId;
  final String url;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final String? uploadedAt;

  const HomeworkFileInfo({
    required this.id,
    this.publicId,
    required this.url,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  factory HomeworkFileInfo.fromJson(Map<String, dynamic> json) {
    return HomeworkFileInfo(
      id: json['id'] ?? 0,
      publicId: json['public_id']?.toString(),
      url: json['url']?.toString() ?? '',
      filename: json['filename']?.toString() ?? 'file',
      contentType: json['content_type']?.toString() ?? '',
      sizeBytes: json['size_bytes'] ?? 0,
      uploadedAt: json['uploaded_at']?.toString(),
    );
  }

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';
}

class HomeworkResultDetailInfo {
  final int id;
  final int? historyId;
  final bool isHistorical;
  final int assignmentId;
  final bool submitted;
  final String? submittedAt;
  final String? photoLink;
  final int? correctTotal;
  final int? incorrectTotal;
  final String? analysis;
  final String? returnedAt;
  final String? returnReason;
  final List<HomeworkFileInfo> attachments;
  final List<HomeworkFileInfo> originalAttachments;
  final bool legacyPhoto;

  const HomeworkResultDetailInfo({
    required this.id,
    this.historyId,
    this.isHistorical = false,
    required this.assignmentId,
    required this.submitted,
    required this.submittedAt,
    required this.photoLink,
    required this.correctTotal,
    required this.incorrectTotal,
    required this.analysis,
    required this.returnedAt,
    required this.returnReason,
    required this.attachments,
    required this.originalAttachments,
    required this.legacyPhoto,
  });

  bool get isReturnedForRevision =>
      !isHistorical && !submitted && (returnedAt ?? '').isNotEmpty;

  factory HomeworkResultDetailInfo.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw = json['attachments'];
    final attachments = attachmentsRaw is List
        ? attachmentsRaw
              .map(
                (item) => HomeworkFileInfo.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : <HomeworkFileInfo>[];
    final originalRaw = json['original_attachments'];
    final originalAttachments = originalRaw is List
        ? originalRaw
              .map(
                (item) => HomeworkFileInfo.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : <HomeworkFileInfo>[];

    return HomeworkResultDetailInfo(
      id: json['id'] ?? json['result_id'] ?? 0,
      historyId: json['history_id'] as int?,
      isHistorical: json['is_historical'] == true,
      assignmentId: json['assignment_id'] ?? 0,
      submitted: json['submitted'] ?? false,
      submittedAt: json['submitted_at']?.toString(),
      photoLink: json['photo_link']?.toString(),
      correctTotal: json['correct_total'],
      incorrectTotal: json['incorrect_total'],
      analysis: json['analysis']?.toString(),
      returnedAt: json['returned_at']?.toString(),
      returnReason: json['return_reason']?.toString(),
      attachments: attachments,
      originalAttachments: originalAttachments,
      legacyPhoto: json['legacy_photo'] == true,
    );
  }
}

class MockResultInfo {
  final int resultId;
  final int assignmentId;
  final int studentId;
  final bool submitted;
  final String? submittedAt;
  final int? totalPoints;
  final int? verbalPoints;
  final int? mathPoints;
  final int? verbalIncorrect;
  final int? mathIncorrect;
  final String? weakAreas;
  final String? photoLink;
  final List<HomeworkFileInfo> attachments;
  final bool legacyPhoto;

  MockResultInfo({
    required this.resultId,
    required this.assignmentId,
    required this.studentId,
    required this.submitted,
    required this.submittedAt,
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

  factory MockResultInfo.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw = json['attachments'];
    final attachments = attachmentsRaw is List
        ? attachmentsRaw
              .map(
                (item) => HomeworkFileInfo.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
        : <HomeworkFileInfo>[];

    return MockResultInfo(
      resultId: json['result_id'] ?? 0,
      assignmentId: json['assignment_id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      submitted: json['submitted'] ?? false,
      submittedAt: json['submitted_at']?.toString(),
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

class StudentHomeworkHistoryInfo {
  final HomeworkResultInfo result;
  final AssignmentInfo assignment;
  final SessionInfo session;
  final ClassInfo classInfo;

  StudentHomeworkHistoryInfo({
    required this.result,
    required this.assignment,
    required this.session,
    required this.classInfo,
  });

  factory StudentHomeworkHistoryInfo.fromJson(Map<String, dynamic> json) {
    return StudentHomeworkHistoryInfo(
      result: HomeworkResultInfo.fromJson(json),
      assignment: AssignmentInfo.fromJson(json['assignment'] ?? {}),
      session: SessionInfo.fromJson(json['session'] ?? {}),
      classInfo: ClassInfo.fromJson(json['class'] ?? {}),
    );
  }
}

class StudentMockHistoryInfo {
  final MockResultInfo result;
  final AssignmentInfo assignment;
  final SessionInfo session;
  final ClassInfo classInfo;

  StudentMockHistoryInfo({
    required this.result,
    required this.assignment,
    required this.session,
    required this.classInfo,
  });

  factory StudentMockHistoryInfo.fromJson(Map<String, dynamic> json) {
    return StudentMockHistoryInfo(
      result: MockResultInfo.fromJson(json),
      assignment: AssignmentInfo.fromJson(json['assignment'] ?? {}),
      session: SessionInfo.fromJson(json['session'] ?? {}),
      classInfo: ClassInfo.fromJson(json['class'] ?? {}),
    );
  }
}

class ClassDetailInfo {
  final int classId;
  final String className;
  final bool archived;
  final UserInfo? verbalTeacher;
  final UserInfo? mathTeacher;
  final List<UserInfo> students;
  final List<SessionInfo> sessions;

  ClassDetailInfo({
    required this.classId,
    required this.className,
    this.archived = false,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.students,
    required this.sessions,
  });

  UserInfo? get teacher => verbalTeacher;

  factory ClassDetailInfo.fromJson(Map<String, dynamic> json) {
    return ClassDetailInfo(
      classId: json['class_id'] ?? json['class']?['class_id'] ?? 0,
      className: json['class_name'] ?? json['class']?['name'] ?? '',
      archived: json['archived'] == true,
      verbalTeacher: json['verbal_teacher'] != null
          ? UserInfo.fromJson({...json['verbal_teacher'], 'role': 'teacher'})
          : null,
      mathTeacher: json['math_teacher'] != null
          ? UserInfo.fromJson({...json['math_teacher'], 'role': 'teacher'})
          : null,
      students: (json['students'] as List<dynamic>? ?? [])
          .map((e) => UserInfo.fromJson({...e, 'role': e['role'] ?? 'student'}))
          .toList(),
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((e) => SessionInfo.fromJson(e))
          .toList(),
    );
  }
}

class ClassFullDetailInfo {
  final int classId;
  final String className;
  final UserInfo? verbalTeacher;
  final UserInfo? mathTeacher;
  final List<UserInfo> students;
  final List<SessionInfo> sessions;
  final List<AssignmentInfo> assignments;
  final List<AttendanceInfo> attendance;
  final int homeworkResultCount;
  final int mockResultCount;

  ClassFullDetailInfo({
    required this.classId,
    required this.className,
    required this.verbalTeacher,
    required this.mathTeacher,
    required this.students,
    required this.sessions,
    required this.assignments,
    required this.attendance,
    required this.homeworkResultCount,
    required this.mockResultCount,
  });

  factory ClassFullDetailInfo.fromJson(Map<String, dynamic> json) {
    return ClassFullDetailInfo(
      classId: json['class_id'] ?? json['class']?['class_id'] ?? 0,
      className: json['class_name'] ?? json['class']?['name'] ?? '',
      verbalTeacher: json['verbal_teacher'] != null
          ? UserInfo.fromJson({...json['verbal_teacher'], 'role': 'teacher'})
          : null,
      mathTeacher: json['math_teacher'] != null
          ? UserInfo.fromJson({...json['math_teacher'], 'role': 'teacher'})
          : null,
      students: (json['students'] as List? ?? [])
          .map((e) => UserInfo.fromJson({...e, 'role': e['role'] ?? 'student'}))
          .toList(),
      sessions: (json['sessions'] as List? ?? [])
          .map((e) => SessionInfo.fromJson(e))
          .toList(),
      assignments: (json['assignments'] as List? ?? [])
          .map((e) => AssignmentInfo.fromJson(e))
          .toList(),
      attendance: (json['attendance'] as List? ?? [])
          .map((e) => AttendanceInfo.fromJson(e))
          .toList(),
      homeworkResultCount: json['homework_result_count'] ?? 0,
      mockResultCount: json['mock_result_count'] ?? 0,
    );
  }

  ClassFullDetailInfo copyWith({
    int? classId,
    String? className,
    UserInfo? verbalTeacher,
    UserInfo? mathTeacher,
    List<UserInfo>? students,
    List<SessionInfo>? sessions,
    List<AssignmentInfo>? assignments,
    List<AttendanceInfo>? attendance,
    int? homeworkResultCount,
    int? mockResultCount,
  }) {
    return ClassFullDetailInfo(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      verbalTeacher: verbalTeacher ?? this.verbalTeacher,
      mathTeacher: mathTeacher ?? this.mathTeacher,
      students: students ?? this.students,
      sessions: sessions ?? this.sessions,
      assignments: assignments ?? this.assignments,
      attendance: attendance ?? this.attendance,
      homeworkResultCount: homeworkResultCount ?? this.homeworkResultCount,
      mockResultCount: mockResultCount ?? this.mockResultCount,
    );
  }
}
