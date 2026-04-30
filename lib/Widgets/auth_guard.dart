import 'package:flutter/material.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/Models/auth_models.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  final List<String>? requiredRoles;

  const AuthGuard({super.key, required this.child, this.requiredRoles});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late Future<AuthResult?> _check;

  @override
  void initState() {
    super.initState();
    _check = AuthService().checkAuth();
  }

  void _redirect(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthResult?>(
      future: _check,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          _redirect('/login');
          return const SizedBox.shrink();
        }

        final result = snapshot.data;

        if (result == null || !result.isAuthenticated) {
          _redirect('/login');
          return const SizedBox.shrink();
        }

        if (widget.requiredRoles != null &&
            !widget.requiredRoles!.contains(result.role)) {
          _redirect(result.role == 'student' ? '/home' : '/classes');
          return const SizedBox.shrink();
        }

        return widget.child;
      },
    );
  }
}
