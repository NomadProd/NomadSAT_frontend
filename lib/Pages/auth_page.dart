import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web/Services/auth_service.dart';
import 'package:flutter_web/theme/turan_theme.dart';

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
      backgroundColor: TuranColors.surface,
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
            child: Container(height: 4, color: TuranColors.primary),
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
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: TuranColors.textDark,
                              letterSpacing: -0.4,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: TuranSpacing.xs),
                          const Text(
                            'Log in to continue your TuranSAT prep',
                            textAlign: TextAlign.center,
                            style: TuranTextStyles.subtitle,
                          ),
                          const SizedBox(height: TuranSpacing.xxl),

                          // ── Email field ────────────────────────────
                          AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _InputField(
                                  controller: _emailController,
                                  label: 'Email address',
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),

                                // ── Password field ─────────────────────────
                                _InputField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  obscureText: _obscurePassword,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (!loading) _login();
                                  },
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                              ],
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
                                color: TuranColors.errorBg,
                                borderRadius: BorderRadius.circular(TuranRadius.sm),
                                border: Border.all(
                                  color: TuranColors.error.withValues(alpha: 0.25),
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
      TextInput.finishAutofillContext();
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
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: TuranColors.textLight, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: TuranSpacing.sm),
                child: suffixIcon,
              )
            : null,
      ).applyDefaults(theme.inputDecorationTheme),
    );
  }
}
