import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_web/Models/exam_question.dart';
import 'package:flutter_web/Models/practice_test.dart';
import 'package:flutter_web/Services/api_config.dart';
import 'package:flutter_web/Services/authed_client.dart';
import 'package:flutter_web/Services/api_json.dart';

class PracticeTestService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = createAuthedClient();

  /// Every endpoint here has the same shape: send JSON, expect 200, otherwise
  /// surface the server's `detail` message. One helper instead of one copy per
  /// endpoint.
  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    required String failure,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    const headers = {'Content-Type': 'application/json'};
    final encoded = body == null ? null : jsonEncode(body);

    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encoded),
      'PUT' => await _client.put(uri, headers: headers, body: encoded),
      'PATCH' => await _client.patch(uri, headers: headers, body: encoded),
      'DELETE' => await _client.delete(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('Unsupported method $method'),
    };

    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, failure),
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  List<Map<String, dynamic>> _asMaps(dynamic data) {
    return (data as List<dynamic>)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // --- tests ---------------------------------------------------------------

  Future<List<PracticeTestInfo>> fetchTests() async {
    final data = await _send('GET', '/practice-tests',
        failure: 'Failed to load practice tests');
    return _asMaps(data).map(PracticeTestInfo.fromJson).toList();
  }

  Future<PracticeTestInfo> fetchTest(int testId) async {
    final data = await _send('GET', '/practice-tests/$testId',
        failure: 'Failed to load this practice test');
    return PracticeTestInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PracticeTestInfo> createTest({
    required String title,
    String? description,
  }) async {
    final data = await _send(
      'POST',
      '/practice-tests',
      body: {'title': title, 'description': description},
      failure: 'Failed to create the practice test',
    );
    return PracticeTestInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PracticeTestInfo> updateTest(
    int testId, {
    String? title,
    String? description,
  }) async {
    final data = await _send(
      'PATCH',
      '/practice-tests/$testId',
      body: {'title': title, 'description': description},
      failure: 'Failed to update the practice test',
    );
    return PracticeTestInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteTest(int testId) async {
    await _send('DELETE', '/practice-tests/$testId',
        failure: 'Failed to delete the practice test');
  }

  Future<PracticeTestInfo> setClasses(int testId, List<int> classIds) async {
    final data = await _send(
      'PUT',
      '/practice-tests/$testId/classes',
      body: {'class_ids': classIds},
      failure: 'Failed to update the groups for this test',
    );
    return PracticeTestInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PracticeTestInfo> setVisible(int testId, bool visible) async {
    final data = await _send(
      'PATCH',
      '/practice-tests/$testId/visible',
      body: {'visible': visible},
      failure: visible
          ? 'Failed to publish this test'
          : 'Failed to hide this test',
    );
    return PracticeTestInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // --- questions -----------------------------------------------------------

  Future<List<PracticeTestQuestionAdmin>> fetchModuleQuestions(
    int moduleId,
  ) async {
    final data = await _send(
      'GET',
      '/practice-tests/modules/$moduleId/questions',
      failure: 'Failed to load the questions for this module',
    );
    return _asMaps(data).map(PracticeTestQuestionAdmin.fromJson).toList();
  }

  Future<PracticeTestQuestionAdmin> createQuestion(
    int moduleId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _send(
      'POST',
      '/practice-tests/modules/$moduleId/questions',
      body: payload,
      failure: 'Failed to create the question',
    );
    return PracticeTestQuestionAdmin.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<PracticeTestQuestionAdmin> updateQuestion(
    int questionId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _send(
      'PUT',
      '/practice-tests/questions/$questionId',
      body: payload,
      failure: 'Failed to update the question',
    );
    return PracticeTestQuestionAdmin.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  /// Returns true when removing the question dropped a published test back to
  /// draft, so no student can start a module that is now a question short.
  Future<bool> deleteQuestion(int questionId) async {
    final data = await _send('DELETE', '/practice-tests/questions/$questionId',
        failure: 'Failed to delete the question');
    return (data as Map?)?['test_unpublished'] == true;
  }

  Future<({String url, String publicId})> uploadQuestionImage(
    PlatformFile file,
  ) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const ApiException(
        'Could not read the image. Try selecting it again.',
      );
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const ApiException('File size cannot exceed 10mb');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/practice-tests/questions/image'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: _imageMimeType(file.name),
      ),
    );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to upload question image'),
        statusCode: response.statusCode,
      );
    }
    final map = Map<String, dynamic>.from(data as Map);
    final url = map['url']?.toString() ?? '';
    final publicId = map['public_id']?.toString() ?? '';
    if (url.isEmpty || publicId.isEmpty) {
      throw const ApiException('Failed to upload question image');
    }
    return (url: url, publicId: publicId);
  }

  // --- attempts ------------------------------------------------------------

  Future<PracticeTestAttempt> startAttempt(int testId) async {
    final data = await _send('POST', '/practice-tests/$testId/attempts',
        failure: 'Could not start this practice test');
    return PracticeTestAttempt.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<ExamQuestion>> fetchAttemptQuestions(int attemptId) async {
    final data = await _send(
      'GET',
      '/practice-tests/attempts/$attemptId/questions',
      failure: 'Failed to load the questions',
    );
    return _asMaps(data).map(examQuestionFromPublicJson).toList();
  }

  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    String? selectedChoice,
    String? responseText,
  }) async {
    await _send(
      'POST',
      '/practice-tests/attempts/$attemptId/answers',
      body: {
        'question_id': questionId,
        'selected_choice': selectedChoice,
        'response_text': responseText,
      },
      failure: 'Failed to save your answer',
    );
  }

  Future<PracticeTestAttempt> saveProgress({
    required int attemptId,
    int? currentQuestionId,
    int? currentModuleId,
    bool? pauseTimer,
  }) async {
    await _send(
      'PATCH',
      '/practice-tests/attempts/$attemptId/progress',
      body: {
        'current_question_id': currentQuestionId,
        'current_module_id': currentModuleId,
        'pause_timer': pauseTimer,
      },
      failure: 'Failed to save your progress',
    );
    return fetchMyAttempt(attemptId);
  }

  Future<PracticeTestAttempt> fetchMyAttempt(int attemptId) async {
    final attempts = await fetchMyAttempts();
    return attempts.firstWhere(
      (attempt) => attempt.id == attemptId,
      orElse: () => throw const ApiException('Attempt not found'),
    );
  }

  Future<PracticeTestAttempt> completeAttempt(int attemptId) async {
    final data = await _send(
      'POST',
      '/practice-tests/attempts/$attemptId/complete',
      failure: 'Failed to submit the test',
    );
    return PracticeTestAttempt.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<PracticeTestAttempt>> fetchMyAttempts() async {
    final data = await _send('GET', '/practice-tests/attempts/me',
        failure: 'Failed to load your practice tests');
    return _asMaps(data).map(PracticeTestAttempt.fromJson).toList();
  }

  Future<PracticeTestAttemptDetail> fetchAttemptDetail(int attemptId) async {
    final data = await _send(
      'GET',
      '/practice-tests/attempts/$attemptId/detail',
      failure: 'Failed to load the review',
    );
    return PracticeTestAttemptDetail.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<List<PracticeTestAttempt>> fetchAttemptsForTest(int testId) async {
    final data = await _send('GET', '/practice-tests/$testId/attempts',
        failure: 'Failed to load results for this test');
    return _asMaps(data).map(PracticeTestAttempt.fromJson).toList();
  }

  MediaType _imageMimeType(String filename) {
    final ext =
        filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'gif' => MediaType('image', 'gif'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
