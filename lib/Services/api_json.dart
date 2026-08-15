import 'dart:convert';

import 'package:http/http.dart' as http;

void Function()? onUnauthorized;

class UnauthenticatedException implements Exception {
  const UnauthenticatedException();

  @override
  String toString() => 'Please sign in again.';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

String apiDetailMessage(dynamic data, [String fallback = 'Request failed']) {
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }
    if (detail is List && detail.isNotEmpty) {
      final parts = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final msg = item['msg']?.toString().trim();
          if (msg != null && msg.isNotEmpty) {
            parts.add(msg);
            continue;
          }
        }
        final text = item.toString().trim();
        if (text.isNotEmpty) parts.add(text);
      }
      if (parts.isNotEmpty) return parts.join(' ');
    }
  }
  return fallback;
}

String userFacingError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is UnauthenticatedException || error is ApiException) {
    return error.toString();
  }
  final text = error.toString();
  final lower = text.toLowerCase();
  if (lower.contains('not authenticated') ||
      lower.contains('unauthenticated')) {
    return 'Please sign in again.';
  }
  if (lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('xmlhttprequest') ||
      lower.contains('connection refused') ||
      lower.contains('network is unreachable')) {
    return 'Could not connect to the server. Check your internet connection.';
  }
  if (lower.contains('formatexception')) {
    return 'The server returned an unexpected response. Please try again.';
  }
  final stripped = text.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  return stripped.isEmpty ? fallback : stripped;
}

dynamic decodeJsonResponse(
  http.Response response, {
  bool handleUnauthorized = true,
}) {
  if (handleUnauthorized && response.statusCode == 401) {
    onUnauthorized?.call();
    throw const UnauthenticatedException();
  }

  final body = utf8.decode(response.bodyBytes);
  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    throw const ApiException(
      'The server returned an empty response. Please try again.',
    );
  }

  try {
    return jsonDecode(trimmed);
  } on FormatException {
    throw ApiException(
      'The server returned an unexpected response. Please try again.',
      statusCode: response.statusCode,
    );
  }
}

String decodeResponseBody(http.Response response) {
  return utf8.decode(response.bodyBytes);
}
