class AuthResult {
  final bool isAuthenticated;
  final String role;
  final int userId;

  AuthResult({
    required this.isAuthenticated,
    required this.role,
    required this.userId,
  });
}