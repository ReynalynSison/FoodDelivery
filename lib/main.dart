import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';
import 'signup.dart';
import 'cart/cart_provider.dart';
import 'models/order.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/wishlist_provider.dart';
import 'theme/app_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  Hive.registerAdapter(OrderStatusAdapter());
  Hive.registerAdapter(OrderAdapter());
  await Hive.openBox("database");
  await Hive.openBox<Order>('orders');

  // Load persisted brightness BEFORE first frame — prevents flicker
  final themeProvider = await ThemeProvider.load();

  // Load persisted wishlist
  final wishlistProvider = await WishlistProvider.load();

  // Restore any active (non-delivered) orders that were in-flight
  // when the app was last closed, resuming their timers correctly.
  final orderProvider = OrderProvider();
  await orderProvider.restoreActiveOrders();

  runApp(MyApp(
    themeProvider: themeProvider,
    orderProvider: orderProvider,
    wishlistProvider: wishlistProvider,
  ));
}

class MyApp extends StatefulWidget {
  final ThemeProvider themeProvider;
  final OrderProvider orderProvider;
  final WishlistProvider wishlistProvider;
  const MyApp({
    super.key,
    required this.themeProvider,
    required this.orderProvider,
    required this.wishlistProvider,
  });

  @override
  State<MyApp> createState() => _State();
}

class _State extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box("database");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: widget.themeProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider<OrderProvider>.value(value: widget.orderProvider),
        ChangeNotifierProvider<WishlistProvider>.value(value: widget.wishlistProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => CupertinoApp(
          theme: themeProvider.isDark
              ? AppThemes.darkTheme
              : AppThemes.lightTheme,
          debugShowCheckedModeBanner: false,
          home: (box.get("username") != null)
              ? const LoginPage()
              : const SignupPage(),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String msg = "";
  bool hidePassword = true;
  final box = Hive.box("database");
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

  void _clearMsg() {
    if (msg.isNotEmpty) setState(() => msg = '');
  }

  @override
  void initState() {
    super.initState();
    _username.addListener(_clearMsg);
    _password.addListener(_clearMsg);
  }

  @override
  void dispose() {
    _username.removeListener(_clearMsg);
    _password.removeListener(_clearMsg);
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (_username.text.trim() == box.get("username") &&
        _password.text.trim() == box.get("password")) {
      Navigator.pushAndRemoveUntil(
        context,
        CupertinoPageRoute(builder: (_) => const Homepage()),
        (route) => false, // remove ALL previous routes
      );
    } else {
      setState(() => msg = "Invalid username or password.");
    }
  }

  Future<void> _biometricLogin() async {
    try {
      final bool ok = await auth.authenticate(
        localizedReason: 'Login to Food Tiger',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (_) => const Homepage()),
          (route) => false, // remove ALL previous routes
        );
      }
    } catch (_) {
      setState(() => msg = 'Biometric auth not available.');
    }
  }

  Future<void> _resetData() async {
    final hasBiometrics = box.get("biometrics", defaultValue: false) as bool;
    if (hasBiometrics) {
      // Show warning dialog first
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Biometric Verification Required'),
          content: const Text(
            'You need to verify your identity using biometrics before you can reset all data.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      try {
        final bool ok = await auth.authenticate(
          localizedReason: 'Verify your identity to reset all data',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );
        if (!ok) return;
      } catch (_) {
        setState(() => msg = 'Biometric auth not available.');
        return;
      }
    }
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete all local data?'),
        content: const Text(
            'This will clear your account, order history and cart.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              // 1. Clear Hive boxes (account, location, orders)
              await box.clear();
              final ordersBox = Hive.box<Order>('orders');
              await ordersBox.clear();

              // 2. Clear SharedPreferences (wishlist, theme)
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              if (context.mounted) {
                // 3. Reset in-memory providers
                context.read<CartProvider>().clearCart();
                context.read<WishlistProvider>().clearAll();
                context.read<OrderProvider>().clearAll();

                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(builder: (_) => const SignupPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hasBiometrics = box.get("biometrics", defaultValue: false) as bool;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      child: SingleChildScrollView(
        child: SizedBox(
          height: size.height,
          child: Column(
            children: [
              // ── Top hero section ──────────────────────────────────────
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

              // ── Form card ─────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sign in to your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),

                      _LoginField(
                        controller: _username,
                        placeholder: 'Username',
                        icon: CupertinoIcons.person_fill,
                      ),
                      const SizedBox(height: 14),

                      _LoginField(
                        controller: _password,
                        placeholder: 'Password',
                        icon: CupertinoIcons.lock_fill,
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

                      if (msg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              const Icon(
                                  CupertinoIcons.exclamationmark_circle,
                                  size: 13,
                                  color: CupertinoColors.destructiveRed),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(msg,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.destructiveRed)),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 28),

                      GestureDetector(
                        onTap: _onSignIn,
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
                              'Sign In',
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

                      if (hasBiometrics) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: _biometricLogin,
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CustomPaint(
                                painter: _FaceIdPainter(
                                    color: const Color(0xFFFF6B35)),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),

                      Center(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _resetData,
                          child: const Text(
                            'Reset all data',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.destructiveRed,
                            ),
                          ),
                        ),
                      ),
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
// Styled text field for LoginPage
// ─────────────────────────────────────────────────────────────────────────────
class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;

  const _LoginField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1.5),
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
        placeholderStyle:
            const TextStyle(color: Color(0xFFAEAEB2), fontSize: 15),
        style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 15),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Icon(icon, size: 18, color: const Color(0xFFFF6B35)),
        ),
        suffix: suffix,
        decoration: const BoxDecoration(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Face ID icon — CustomPainter drawing the scan-frame + face features
// ─────────────────────────────────────────────────────────────────────────────

class _FaceIdPainter extends CustomPainter {
  final Color color;
  const _FaceIdPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = w * 0.18;
    final arm = w * 0.28;

    // ── Corner brackets ──────────────────────────────────────────────────
    // Top-left
    canvas.drawPath(Path()
      ..moveTo(0, arm)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(arm, 0), paint);
    // Top-right
    canvas.drawPath(Path()
      ..moveTo(w - arm, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, arm), paint);
    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(0, h - arm)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h),
          radius: Radius.circular(r), clockwise: false)
      ..lineTo(arm, h), paint);
    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(w - arm, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r),
          radius: Radius.circular(r), clockwise: false)
      ..lineTo(w, h - arm), paint);

    // ── Face features ─────────────────────────────────────────────────────
    final cx = w / 2;
    // Left eye
    canvas.drawLine(
      Offset(cx - w * 0.22, h * 0.33),
      Offset(cx - w * 0.22, h * 0.45),
      paint,
    );
    // Right eye
    canvas.drawLine(
      Offset(cx + w * 0.22, h * 0.33),
      Offset(cx + w * 0.22, h * 0.45),
      paint,
    );
    // Nose
    canvas.drawPath(
      Path()
        ..moveTo(cx, h * 0.40)
        ..lineTo(cx, h * 0.58)
        ..lineTo(cx - w * 0.08, h * 0.62),
      paint,
    );
    // Smile
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * 0.62),
        width: w * 0.44,
        height: h * 0.22,
      ),
      0.3,
      2.54,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_FaceIdPainter old) => old.color != color;
}




