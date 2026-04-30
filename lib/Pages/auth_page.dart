import 'package:flutter/material.dart';
import 'package:flutter_web/Services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool loading = false;
  bool _obscurePassword = true;
  String error = "";

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  static const Color kBlue = Color(0xFF1A4AF0);
  static const Color kBlueDark = Color(0xFF1A4AF0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final patternBase = size.shortestSide.clamp(360.0, 720.0);
    final topPatternSize = patternBase * 1.24;
    final bottomPatternSize = patternBase * 1.16;
    const headerHeight = 4.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Top-right decorative pattern ──────────────────────────────
          Positioned(
            top: headerHeight - topPatternSize / 2,
            right: -topPatternSize / 2,
            child: Opacity(
              opacity: 0.16,
              child: Transform.scale(
                scaleY: -1,
                child: Image.asset(
                  'assets/brand/turan_pattern.png',
                  width: topPatternSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── Bottom-left decorative pattern ────────────────────────────
          Positioned(
            bottom: -bottomPatternSize / 2,
            left: -bottomPatternSize / 2,
            child: Opacity(
              opacity: 0.13,
              child: Transform.scale(
                scaleX: -1,
                child: Image.asset(
                  'assets/brand/turan_pattern.png',
                  width: bottomPatternSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // ── Subtle top blue bar ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 4, color: kBlue),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 48),

                          // ── Logo ───────────────────────────────────
                          Center(
                            child: Image.asset(
                              'assets/brand/turan_symbol.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Headline ───────────────────────────────
                          const Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D1A3A),
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Log in to continue your TuranSAT prep journey',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: Color(0xFF7B8AA0),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ── Email field ────────────────────────────
                          _InputField(
                            controller: _emailController,
                            label: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                          ),
                          const SizedBox(height: 16),

                          // ── Password field ─────────────────────────
                          _InputField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF7B8AA0),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Error ──────────────────────────────────
                          if (error.isNotEmpty)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade400,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ── Login button ───────────────────────────
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loading ? null : _login,
                              style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor: kBlue,
                                    disabledBackgroundColor: kBlue.withValues(
                                      alpha: 0.6,
                                    ),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ).copyWith(
                                    overlayColor:
                                        WidgetStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            WidgetState.pressed,
                                          )) {
                                            return kBlueDark.withValues(
                                              alpha: 0.3,
                                            );
                                          }
                                          return null;
                                        }),
                                  ),
                              child: loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _login() async {
    setState(() {
      loading = true;
      error = "";
    });

    try {
      final user = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() => loading = false);
      Navigator.pushReplacementNamed(context, _homeRouteForRole(user.role));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  String _homeRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case "admin":
      case "mentor":
      case "teacher":
        return "/classes";
      default:
        return "/home";
    }
  }
}

// ── Reusable styled input field ────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  static const Color kBlue = Color(0xFF1A4AF0);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF0D1A3A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF7B8AA0)),
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          color: kBlue,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFFADB8CC), size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF7F9FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3EE), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE3EE), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.8),
        ),
      ),
    );
  }
}
