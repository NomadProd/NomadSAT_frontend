import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_web/Models/diagnostic_attempt.dart';
import 'package:flutter_web/Models/diagnostic_question.dart';
import 'package:flutter_web/Services/api_config.dart';
import 'package:flutter_web/Services/api_json.dart';

class DiagnosticService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = BrowserClient()..withCredentials = true;

  Future<List<DiagnosticQuestion>> fetchQuestionBank() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/diagnostic/questions'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to load diagnostic questions'),
        statusCode: response.statusCode,
      );
    }
    return (data as List<dynamic>)
        .whereType<Map>()
        .map((item) => DiagnosticQuestion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<DiagnosticQuestion> createQuestion(Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/diagnostic/questions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to create diagnostic question'),
        statusCode: response.statusCode,
      );
    }
    return DiagnosticQuestion.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<DiagnosticQuestion> updateQuestion(
    int questionId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/diagnostic/questions/$questionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to update diagnostic question'),
        statusCode: response.statusCode,
      );
    }
    return DiagnosticQuestion.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<({String url, String publicId})> uploadQuestionImage(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const ApiException('Could not read the image. Try selecting it again.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const ApiException('File size cannot exceed 10mb');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/diagnostic/questions/image'),
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

  MediaType _imageMimeType(String filename) {
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
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<void> deleteQuestion(int questionId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/diagnostic/questions/$questionId'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to delete diagnostic question'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<DiagnosticAttemptCreated> startAttempt() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/diagnostic/attempts'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to start diagnostic test'),
        statusCode: response.statusCode,
      );
    }
    return DiagnosticAttemptCreated.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<DiagnosticAttempt>> fetchAttempts() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/diagnostic/attempts'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to load diagnostic attempts'),
        statusCode: response.statusCode,
      );
    }
    return (data as List<dynamic>)
        .whereType<Map>()
        .map((item) => DiagnosticAttempt.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<DiagnosticAttempt> fetchAttempt(int attemptId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/diagnostic/attempts/$attemptId'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to load diagnostic attempt'),
        statusCode: response.statusCode,
      );
    }
    return DiagnosticAttempt.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<DiagnosticQuestion>> fetchAttemptQuestions(int attemptId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/diagnostic/attempts/$attemptId/questions'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to load diagnostic questions'),
        statusCode: response.statusCode,
      );
    }
    return (data as List<dynamic>)
        .whereType<Map>()
        .map((item) => DiagnosticQuestion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveProgress({
    required int attemptId,
    required int currentQuestionId,
    DateTime? mathStartedAt,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/diagnostic/attempts/$attemptId/progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'current_question_id': currentQuestionId,
        if (mathStartedAt != null)
          'math_started_at': mathStartedAt.toUtc().toIso8601String(),
      }),
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to save diagnostic progress'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    required String selectedChoice,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/diagnostic/attempts/$attemptId/answers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question_id': questionId,
        'selected_choice': selectedChoice,
      }),
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to save answer'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<DiagnosticAttempt> completeAttempt(int attemptId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/diagnostic/attempts/$attemptId/complete'),
      headers: {'Content-Type': 'application/json'},
    );
    final data = decodeJsonResponse(response);
    if (response.statusCode != 200) {
      throw ApiException(
        apiDetailMessage(data, 'Failed to complete diagnostic test'),
        statusCode: response.statusCode,
      );
    }
    return DiagnosticAttempt.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
