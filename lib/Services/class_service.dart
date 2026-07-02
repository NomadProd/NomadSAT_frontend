import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/api_config.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/Models/homework_result.dart';
import 'package:flutter_web/Models/mock_result.dart';

class ClassService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = BrowserClient()..withCredentials = true;

  Future<Map<String, dynamic>> createClass({
    required String name,
    int? teacherId,
    int? verbalTeacherId,
    int? mathTeacherId,
    String? scheduleTemplate,
    String? startDate,
    int? scheduleWeeks,
    List<Map<String, dynamic>>? verbalSchedule,
    List<Map<String, dynamic>>? mathSchedule,
    List<Map<String, dynamic>>? mockSchedule,
  }) async {
    final resolvedVerbalTeacherId = verbalTeacherId ?? teacherId;
    final resolvedMathTeacherId = mathTeacherId ?? teacherId;

    if (resolvedVerbalTeacherId == null || resolvedMathTeacherId == null) {
      return {
        'success': false,
        'message': 'Both verbalTeacherId and mathTeacherId are required',
      };
    }

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/classes/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'verbal_teacher_id': resolvedVerbalTeacherId,
          'math_teacher_id': resolvedMathTeacherId,
          if (scheduleTemplate != null) 'schedule_template': scheduleTemplate,
          if (startDate != null) 'start_date': startDate,
          if (scheduleWeeks != null) 'schedule_weeks': scheduleWeeks,
          if (verbalSchedule != null) 'verbal_schedule': verbalSchedule,
          if (mathSchedule != null) 'math_schedule': mathSchedule,
          if (mockSchedule != null) 'mock_schedule': mockSchedule,
        }),
      );

      final data = decodeJsonResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Class created successfully',
          'class_id': data['class_id'],
          'sessions_created': data['sessions_created'],
        };
      }

      return {
        'success': false,
        'message': data['detail'] ?? 'Failed to create class',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<List<ClassInfo>> fetchClasses({bool? archived}) async {
    final uri = archived == null
        ? Uri.parse('$baseUrl/classes')
        : Uri.parse('$baseUrl/classes').replace(
            queryParameters: {'archived': archived.toString()},
          );
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load classes');
    }

    final List<dynamic> data = decodeJsonResponse(response);
    return data.map((e) => ClassInfo.fromJson(e)).toList();
  }

  Future<ClassDetailInfo> fetchClassDetail(int classId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/classes/$classId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load class detail');
    }

    return ClassDetailInfo.fromJson(decodeJsonResponse(response));
  }

  Future<ClassFullDetailInfo> fetchClassFullDetail(int classId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/classes/$classId/detail'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load full class detail');
    }

    return ClassFullDetailInfo.fromJson(decodeJsonResponse(response));
  }

  Future<List<ClassFullDetailInfo>> fetchStudentHomeClassDetails() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/classes/student-home/details'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load student classes');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => ClassFullDetailInfo.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> updateClass({
    required int classId,
    String? name,
    int? verbalTeacherId,
    int? mathTeacherId,
    bool? archived,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['name'] = name;
      if (verbalTeacherId != null) {
        payload['verbal_teacher_id'] = verbalTeacherId;
      }
      if (mathTeacherId != null) payload['math_teacher_id'] = mathTeacherId;
      if (archived != null) payload['archived'] = archived;

      final response = await _client.patch(
        Uri.parse('$baseUrl/classes/$classId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? data['detail'] ?? 'Failed to update class',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<List<SessionInfo>> fetchClassSessions(int classId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/classes/$classId/sessions'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load sessions');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => SessionInfo.fromJson(e)).toList();
  }

  Future<List<UserInfo>> fetchStudents() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/users/students'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load students');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => UserInfo.fromJson(e)).toList();
  }

  Future<List<UserInfo>> fetchUsers() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/users/all'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(
        data['detail']?.toString() ?? 'Failed to load users (${response.statusCode})',
      );
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => UserInfo.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String role,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'surname': surname,
          'role': role,
        }),
      );

      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['detail'] ?? 'Failed to create user',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserRole({
    required int userId,
    required String role,
  }) async {
    return updateUser(userId: userId, role: role);
  }

  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? email,
    String? password,
    String? name,
    String? surname,
    String? role,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (email != null) body['email'] = email;
      if (password != null && password.isNotEmpty) body['password'] = password;
      if (name != null) body['name'] = name;
      if (surname != null) body['surname'] = surname;
      if (role != null) body['role'] = role;

      final response = await _client.patch(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['detail'] ?? 'Failed to update user',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteUser({required int userId}) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return {'success': true};
      }

      final data = decodeJsonResponse(response);
      if (response.statusCode == 403 && data['error'] == 'SELF_DELETE_FORBIDDEN') {
        return {
          'success': false,
          'error': 'SELF_DELETE_FORBIDDEN',
          'message': data['detail'] ?? 'You cannot delete your own account',
        };
      }

      return {
        'success': false,
        'message': data['detail']?.toString() ?? 'Failed to delete user. Try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete user. Try again.',
      };
    }
  }

  Future<Map<String, dynamic>> deleteClass({required int classId}) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/classes/$classId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return {'success': true};
      }

      final data = decodeJsonResponse(response);
      return {
        'success': false,
        'message': data['detail']?.toString() ?? 'Failed to delete class. Try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete class. Try again.',
      };
    }
  }

  Future<Map<String, dynamic>> createSession({
    required int classId,
    required String date,
    String? startTime,
    String? endTime,
    required String sessionType,
    int? teacherId,
    String? topic,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/classes/$classId/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': date,
          'start_time': startTime != null && startTime.length == 5
              ? '$startTime:00'
              : startTime,
          'end_time': endTime != null && endTime.length == 5
              ? '$endTime:00'
              : endTime,
          'session_type': sessionType,
          'teacher_id': teacherId,
          'topic': topic,
        }),
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to create session',
        'session_id': data['session_id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSession({required int sessionId}) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to delete session',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<List<AssignmentInfo>> fetchAssignmentsBySession(int sessionId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/assignments/sessions/$sessionId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load assignments');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => AssignmentInfo.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createAssignmentForStudent({
    required int sessionId,
    required int studentId,
    int? slotIndex,
    String? title,
    String? instruction,
    String? taskLink,
    String? dueDate,
    String? dueTime,
    bool photoRequired = true,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/assignments/sessions/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'slot_index': slotIndex,
          'title': title,
          'instruction': instruction,
          'task_link': taskLink,
          'due_date': dueDate,
          'due_time': dueTime,
          'photo_required': photoRequired,
        }),
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to create assignment',
        'assignment_id': data['assignment_id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAssignment({
    required int assignmentId,
    int? studentId,
    int? slotIndex,
    String? title,
    String? instruction,
    String? taskLink,
    String? dueDate,
    String? dueTime,
    bool? photoRequired,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/assignments/$assignmentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'slot_index': slotIndex,
          'title': title,
          'instruction': instruction,
          'task_link': taskLink,
          'due_date': dueDate,
          'due_time': dueTime,
          'photo_required': photoRequired,
        }),
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to update assignment',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> copyAssignment({
    required int sourceAssignmentId,
    List<int>? targetStudentIds,
    bool allStudents = false,
    int? targetSlotIndex,
    int? sessionId,
  }) async {
    try {
      final body = <String, dynamic>{
        'all_students': allStudents,
        if (sessionId != null) 'session_id': sessionId,
        if (targetSlotIndex != null) 'target_slot_index': targetSlotIndex,
        if (!allStudents && targetStudentIds != null)
          'target_student_ids': targetStudentIds,
      };

      final response = await _client.post(
        Uri.parse('$baseUrl/assignments/$sourceAssignmentId/copy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      if (response.statusCode == 200) {
        final created = data['created'];
        final skipped = data['skipped'];
        return {
          'success': true,
          'message': data['message']?.toString() ?? 'Homework copied',
          'created': created is List ? created : <dynamic>[],
          'skipped': skipped is List ? skipped : <dynamic>[],
        };
      }

      return {
        'success': false,
        'message': detailMessage ?? 'Failed to copy assignment',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteAssignment({
    required int assignmentId,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/assignments/$assignmentId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to delete assignment',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<List<HomeworkResultInfo>> fetchHomeworkResultsByAssignment(
    int assignmentId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/assignments/$assignmentId/homework-results'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load homework results');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => HomeworkResultInfo.fromJson(e)).toList();
  }

  Future<List<HomeworkResultInfo>> fetchHomeworkResultsByClass(
    int classId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/classes/$classId/homework-results'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load homework results');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => HomeworkResultInfo.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createHomeworkResult({
    required int assignmentId,
    required bool submitted,
    html.File? photoFile,
    String? photoLink,
    int? correctTotal,
    int? incorrectTotal,
    String? analysis,
  }) async {
    try {
      final response = await _sendHomeworkResultRequest(
        'POST',
        Uri.parse('$baseUrl/assignments/$assignmentId/homework-results'),
        submitted: submitted,
        photoFile: photoFile,
        photoLink: photoLink,
        correctTotal: correctTotal,
        incorrectTotal: incorrectTotal,
        analysis: analysis,
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to submit homework',
        'result_id': data['result_id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> updateHomeworkResult({
    required int resultId,
    bool? submitted,
    html.File? photoFile,
    String? photoLink,
    int? correctTotal,
    int? incorrectTotal,
    String? analysis,
  }) async {
    try {
      final response = await _sendHomeworkResultRequest(
        'PATCH',
        Uri.parse('$baseUrl/homework-results/$resultId'),
        submitted: submitted,
        photoFile: photoFile,
        photoLink: photoLink,
        correctTotal: correctTotal,
        incorrectTotal: incorrectTotal,
        analysis: analysis,
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to update homework',
        'result_id': data['result_id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<HomeworkResultDetailInfo> fetchHomeworkResultDetail(
    int resultId, {
    int? historyId,
  }) async {
    final uri = historyId == null
        ? Uri.parse('$baseUrl/homework-results/$resultId')
        : Uri.parse(
            '$baseUrl/homework-results/$resultId',
          ).replace(queryParameters: {'history_id': historyId.toString()});
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load homework result');
    }

    return HomeworkResultDetailInfo.fromJson(decodeJsonResponse(response));
  }

  Future<Map<String, dynamic>> returnHomeworkForRevision({
    required int resultId,
    String? reason,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/homework-results/$resultId/return'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      final data = decodeJsonResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'result': HomeworkResultDetailInfo.fromJson(data),
        };
      }

      if (response.statusCode == 409) {
        final error = data['error']?.toString();
        if (error == 'ALREADY_RETURNED') {
          return {
            'success': false,
            'error': 'ALREADY_RETURNED',
            'message':
                data['detail']?.toString() ??
                'This homework is already pending revision',
          };
        }
        if (error == 'NOT_SUBMITTED') {
          return {
            'success': false,
            'error': 'NOT_SUBMITTED',
            'message':
                data['detail']?.toString() ??
                'Homework has not been submitted yet',
          };
        }
      }

      final detail = data['detail'];
      return {
        'success': false,
        'message': detail is String
            ? detail
            : detail?.toString() ?? 'Failed to return homework. Try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to return homework. Try again.',
      };
    }
  }

  Future<bool> deleteHomeworkAttachment({
    required int resultId,
    required String publicId,
  }) async {
    final encodedPublicId = Uri.encodeComponent(publicId);
    final response = await _client.delete(
      Uri.parse(
        '$baseUrl/homework-results/$resultId/attachments/$encodedPublicId',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 204;
  }

  Future<bool> deleteHomeworkHistoryAttachment({
    required int resultId,
    required int historyId,
    required String publicId,
  }) async {
    final encodedPublicId = Uri.encodeComponent(publicId);
    final response = await _client.delete(
      Uri.parse(
        '$baseUrl/homework-results/$resultId/history/$historyId/attachments/$encodedPublicId',
      ),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 204;
  }

  Future<HomeworkResult> fetchHomeworkResult(int resultId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/homework-results/$resultId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load homework result');
    }

    return HomeworkResult.fromJson(decodeJsonResponse(response));
  }

  MediaType _mimeTypeForFilename(String filename) {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<Map<String, dynamic>> uploadHomeworkResultFiles({
    required int resultId,
    required List<PlatformFile> files,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/homework-results/$resultId/upload'),
      );

      for (final file in files) {
        final bytes = file.bytes;
        if (bytes == null) {
          return {
            'success': false,
            'message': 'Could not read ${file.name}. Try selecting the file again.',
          };
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: file.name,
            contentType: _mimeTypeForFilename(file.name),
          ),
        );
      }

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final data = decodeJsonResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'result': HomeworkResult.fromJson(data),
        };
      }

      if (response.statusCode == 422) {
        return {
          'success': false,
          'message': _formatHomeworkUploadValidationError(data),
          'status_code': 422,
        };
      }

      if (response.statusCode == 500) {
        return {
          'success': false,
          'message': 'Upload failed. Please try again.',
          'status_code': 500,
        };
      }

      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': false,
        'message': detailMessage ?? 'Upload failed. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  String _formatHomeworkUploadValidationError(Map<String, dynamic> data) {
    final error = data['error']?.toString();
    final filename = data['filename']?.toString();

    switch (error) {
      case 'INVALID_FILE_TYPE':
        if (filename != null && filename.isNotEmpty) {
          return '«$filename» is not a supported file type';
        }
        return 'One or more files have an unsupported type';
      case 'FILE_TOO_LARGE':
        if (filename != null && filename.isNotEmpty) {
          return '«$filename» exceeds the 50 MB limit';
        }
        return 'One or more files exceed the 50 MB limit';
      case 'TOO_MANY_FILES':
        return 'Maximum 10 files per submission';
      default:
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        return 'Validation failed';
    }
  }

  Future<http.Response> _sendHomeworkResultRequest(
    String method,
    Uri uri, {
    bool? submitted,
    html.File? photoFile,
    String? photoLink,
    int? correctTotal,
    int? incorrectTotal,
    String? analysis,
  }) async {
    if (photoFile == null) {
      return method == 'POST'
          ? _client.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'submitted': submitted,
                'photo_link': photoLink,
                'correct_total': correctTotal,
                'incorrect_total': incorrectTotal,
                'analysis': analysis,
              }),
            )
          : _client.patch(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'submitted': submitted,
                'photo_link': photoLink,
                'correct_total': correctTotal,
                'incorrect_total': incorrectTotal,
                'analysis': analysis,
              }),
            );
    }

    final request = http.MultipartRequest(method, uri);
    if (submitted != null) request.fields['submitted'] = submitted.toString();
    if ((photoLink ?? '').isNotEmpty) request.fields['photo_link'] = photoLink!;
    if (correctTotal != null) {
      request.fields['correct_total'] = correctTotal.toString();
    }
    if (incorrectTotal != null) {
      request.fields['incorrect_total'] = incorrectTotal.toString();
    }
    if ((analysis ?? '').isNotEmpty) request.fields['analysis'] = analysis!;
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        await _readFileBytes(photoFile),
        filename: photoFile.name,
      ),
    );

    final streamed = await _client.send(request);
    return http.Response.fromStream(streamed);
  }

  Future<Uint8List> _readFileBytes(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final result = reader.result;
    if (result is ByteBuffer) return result.asUint8List();
    return result as Uint8List;
  }

  Future<List<MockResultInfo>> fetchMockResultsByAssignment(
    int assignmentId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/assignments/$assignmentId/mock-results'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load mock results');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => MockResultInfo.fromJson(e)).toList();
  }

  Future<MockResultDetail> fetchMockResult(int resultId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/mock-results/$resultId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load mock result');
    }

    return MockResultDetail.fromJson(decodeJsonResponse(response));
  }

  Future<bool> deleteMockFile(int fileId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/mock-files/$fileId'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 204;
  }

  Future<Map<String, dynamic>> uploadMockResultFiles({
    required int resultId,
    required List<PlatformFile> files,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/mock-results/$resultId/upload'),
      );

      for (final file in files) {
        final bytes = file.bytes;
        if (bytes == null) {
          return {
            'success': false,
            'message': 'Could not read ${file.name}. Try selecting the file again.',
          };
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: file.name,
            contentType: _mimeTypeForFilename(file.name),
          ),
        );
      }

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final data = decodeJsonResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'result': MockResultDetail.fromJson(data),
        };
      }

      if (response.statusCode == 422) {
        final detail = data['detail'];
        return {
          'success': false,
          'message': detail is String
              ? detail
              : detail?.toString() ?? 'Validation failed',
          'status_code': 422,
        };
      }

      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': false,
        'message': detailMessage ?? 'Upload failed. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<List<MockResultInfo>> fetchMockResultsByClass(int classId) async {
    final url = '$baseUrl/classes/$classId/mock-results';
    final response = await _client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load mock results');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => MockResultInfo.fromJson(e)).toList();
  }

  Future<List<StudentHomeworkHistoryInfo>> fetchStudentHomeworkHistory(
    int studentId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/students/$studentId/homework-results'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load homework history');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => StudentHomeworkHistoryInfo.fromJson(e)).toList();
  }

  Future<List<StudentMockHistoryInfo>> fetchStudentMockHistory(
    int studentId,
  ) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/students/$studentId/mock-results'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load mock history');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => StudentMockHistoryInfo.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createMockResult({
    required int assignmentId,
    required int studentId,
    required bool submitted,
    String? photoLink,
    int? verbalPoints,
    int? mathPoints,
    int? verbalIncorrect,
    int? mathIncorrect,
    String? weakAreas,
  }) async {
    try {
      final response = await _sendMockResultRequest(
        'POST',
        Uri.parse('$baseUrl/assignments/$assignmentId/mock-results'),
        studentId: studentId,
        submitted: submitted,
        photoLink: photoLink,
        verbalPoints: verbalPoints,
        mathPoints: mathPoints,
        verbalIncorrect: verbalIncorrect,
        mathIncorrect: mathIncorrect,
        weakAreas: weakAreas,
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to submit mock result',
        'result_id': data['result_id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMockResult({
    required int resultId,
    bool? submitted,
    String? photoLink,
    int? verbalPoints,
    int? mathPoints,
    int? verbalIncorrect,
    int? mathIncorrect,
    String? weakAreas,
  }) async {
    try {
      final response = await _sendMockResultRequest(
        'PATCH',
        Uri.parse('$baseUrl/mock-results/$resultId'),
        submitted: submitted,
        photoLink: photoLink,
        verbalPoints: verbalPoints,
        mathPoints: mathPoints,
        verbalIncorrect: verbalIncorrect,
        mathIncorrect: mathIncorrect,
        weakAreas: weakAreas,
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to update mock result',
        'result_id': data['result_id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<http.Response> _sendMockResultRequest(
    String method,
    Uri uri, {
    int? studentId,
    bool? submitted,
    String? photoLink,
    int? verbalPoints,
    int? mathPoints,
    int? verbalIncorrect,
    int? mathIncorrect,
    String? weakAreas,
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'submitted': submitted,
      'photo_link': photoLink,
      'verbal_points': verbalPoints,
      'math_points': mathPoints,
      'verbal_incorrect': verbalIncorrect,
      'math_incorrect': mathIncorrect,
      'weak_areas': weakAreas,
    };
    return method == 'POST'
        ? _client.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
        : _client.patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          );
  }

  Future<List<UserInfo>> fetchTeachers() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/users/teachers'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data['detail'] ?? 'Failed to load teachers');
    }

    final List data = decodeJsonResponse(response);
    return data.map((e) => UserInfo.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> upsertAttendance({
    required int sessionId,
    required int studentId,
    required bool status,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/attendance/sessions/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'records': [
            {'student_id': studentId, 'status': status},
          ],
        }),
      );
      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? data['detail'] ?? 'Failed to update attendance',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSession({
    required int sessionId,
    required String date,
    String? startTime,
    String? endTime,
    required String sessionType,
    int? teacherId,
    String? topic,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/sessions/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': date,
          'start_time': startTime != null && startTime.length == 5
              ? '$startTime:00'
              : startTime,
          'end_time': endTime != null && endTime.length == 5
              ? '$endTime:00'
              : endTime,
          'session_type': sessionType,
          'teacher_id': teacherId,
          'topic': topic,
        }),
      );

      final data = decodeJsonResponse(response);
      final detailMessage = data['detail'] == null
          ? null
          : data['detail'] is String
          ? data['detail']
          : jsonEncode(data['detail']);

      return {
        'success': response.statusCode == 200,
        'message':
            data['message'] ?? detailMessage ?? 'Failed to update session',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> assignStudentToClass({
    required int classId,
    required int studentId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/classes/$classId/students'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'student_id': studentId}),
      );

      final data = decodeJsonResponse(response);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? data['detail'] ?? 'Failed to add student',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  Future<Map<String, dynamic>> removeStudentFromClass({
    required int classId,
    required int studentId,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/classes/$classId/students/$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return {'success': true};
      }

      final data = decodeJsonResponse(response);
      return {
        'success': false,
        'message':
            data['detail']?.toString() ?? 'Failed to remove student. Try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to remove student. Try again.',
      };
    }
  }
}
