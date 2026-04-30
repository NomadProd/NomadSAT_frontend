import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:flutter_web/Models/auth_models.dart';
import 'package:flutter_web/Models/class_models.dart';
import 'package:flutter_web/Services/api_config.dart';
import 'package:flutter_web/Services/api_json.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  final http.Client _client = BrowserClient()..withCredentials = true;

  static UserInfo? _cachedUser;
  static Future<UserInfo>? _inFlightUser;

  Future<UserInfo> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = decodeJsonResponse(response);

    if (response.statusCode == 200) {
      final user = UserInfo.fromJson(data);
      _cachedUser = user;
      _inFlightUser = null;
      return user;
    }

    throw Exception(data["detail"] ?? "Login failed");
  }

  Future<AuthResult> checkAuth() async {
    try {
      final user = await fetchMe();
      return AuthResult(
        isAuthenticated: true,
        role: user.role,
        userId: user.userId,
      );
    } catch (e) {
      return AuthResult(isAuthenticated: false, role: "", userId: 0);
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
    String surname,
    String role,
  ) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": name,
          "surname": surname,
          "role": role,
        }),
      );

      final data = decodeJsonResponse(response);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "Registered successfully",
          "role": data["role"],
          "user_id": data["user_id"],
        };
      }

      return {
        "success": false,
        "message": data["detail"] ?? "Registration failed",
      };
    } catch (e) {
      return {"success": false, "message": "Connection failed: $e"};
    }
  }

  Future<UserInfo> fetchMe() async {
    final cachedUser = _cachedUser;
    if (cachedUser != null) return cachedUser;

    final inFlightUser = _inFlightUser;
    if (inFlightUser != null) return inFlightUser;

    _inFlightUser = _fetchMeFromServer();
    try {
      final user = await _inFlightUser!;
      _cachedUser = user;
      return user;
    } finally {
      _inFlightUser = null;
    }
  }

  Future<UserInfo> _fetchMeFromServer() async {
    final response = await _client.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return UserInfo.fromJson(decodeJsonResponse(response));
    }

    final data = decodeJsonResponse(response);
    throw Exception(data["detail"] ?? "Failed to load user");
  }

  Future<void> logout() async {
    final response = await _client.post(
      Uri.parse("$baseUrl/auth/logout"),
      headers: {"Content-Type": "application/json"},
    );

    _cachedUser = null;
    _inFlightUser = null;

    if (response.statusCode != 200) {
      final data = decodeJsonResponse(response);
      throw Exception(data["detail"] ?? "Logout failed");
    }
  }
}
