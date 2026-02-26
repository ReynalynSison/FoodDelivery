import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final box = Hive.box("database");
  bool hidePassword = true;
  String? _passwordError;
  String? _usernameError;
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _username.addListener(() {
      if (_usernameError != null) setState(() => _usernameError = null);
    });
    _password.addListener(() {
      if (_passwordError != null) setState(() => _passwordError = null);
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSignUp() {
    final username = _username.text.trim();
    final password = _password.text.trim();

    setState(() {
      _usernameError = username.isEmpty ? 'Username is required.' : null;
      _passwordError = password.length < 6
          ? 'Password must be at least 6 characters.'
          : null;
    });

    if (_usernameError != null || _passwordError != null) return;

    box.put("username", username);
    box.put("password", password);
    box.put("biometrics", false);
    _password.text = "";
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      child: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Column(
            children: [
              // ── Top hero section ────────────────────────────────────────
              Container(
                width: double.infinity,
                height: size.height * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFE84E0F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CupertinoColors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text('🐯', style: TextStyle(fontSize: 50)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Food Tiger',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fast. Fresh. Fierce.',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Form card ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sign up to start ordering',

                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),

                      _FTField(
                        controller: _username,
                        placeholder: 'Username',
                        icon: CupertinoIcons.person_fill,
                        error: _usernameError,
                      ),
                      const SizedBox(height: 14),

                      _FTField(
                        controller: _password,
                        placeholder: 'Password',
                        icon: CupertinoIcons.lock_fill,
                        error: _passwordError,
                        obscureText: hidePassword,
                        suffix: GestureDetector(
                          onTap: () =>
                              setState(() => hidePassword = !hidePassword),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Icon(
                              hidePassword
                                  ? CupertinoIcons.eye
                                  : CupertinoIcons.eye_slash,
                              size: 18,
                              color: const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      GestureDetector(
                        onTap: _onSignUp,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFE84E0F)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x59FF6B35),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared styled text field
// ─────────────────────────────────────────────────────────────────────────────
class _FTField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final String? error;
  final bool obscureText;
  final Widget? suffix;

  const _FTField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.error,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? CupertinoColors.destructiveRed
                  : const Color(0xFFE5E5EA),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscureText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            placeholderStyle: const TextStyle(
              color: Color(0xFFAEAEB2),
              fontSize: 15,
            ),
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 15,
            ),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(icon, size: 18, color: const Color(0xFFFF6B35)),
            ),
            suffix: suffix,
            decoration: const BoxDecoration(),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_circle,
                    size: 13, color: CupertinoColors.destructiveRed),
                const SizedBox(width: 5),
                Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
