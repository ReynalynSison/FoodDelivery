import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

// Ensure these filenames match your actual files!
import 'homepage.dart';
import 'signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("database");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _State();
}

class _State extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box("database");
    return CupertinoApp(
        theme: const CupertinoThemeData(
            primaryColor: CupertinoColors.label,
            brightness: Brightness.dark),
        debugShowCheckedModeBanner: false,
        home: (box.get("username") != null) ? const LoginPage() : const SignupPage());
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Login", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w200)),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: _username,
                placeholder: "Username",
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(CupertinoIcons.person),
                ),
                padding: const EdgeInsets.all(10),
              ),
              const SizedBox(height: 5),
              CupertinoTextField(
                controller: _password,
                placeholder: "Password",
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(CupertinoIcons.padlock),
                ),
                padding: const EdgeInsets.all(10),
                obscureText: hidePassword,
                suffix: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash),
                    onPressed: () => setState(() => hidePassword = !hidePassword)),
              ),
              Center(
                child: Column(
                  children: [
                    CupertinoButton(
                        child: const Text('Sign In'),
                        onPressed: () {
                          if (_username.text.trim() == box.get("username") &&
                              _password.text.trim() == box.get("password")) {
                            Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const Homepage()));
                          } else {
                            setState(() => msg = "Invalid Username or Password");
                          }
                        }),

                    if (box.get("biometrics", defaultValue: false))
                      CupertinoButton(
                        child: const Icon(Icons.fingerprint_rounded, size: 50),
                        onPressed: () async {
                          try {
                            // In v3.0.0, use 'biometricOnly' and 'persistAcrossBackgrounding' directly
                            final bool didAuthenticate = await auth.authenticate(
                              localizedReason: 'Login to your account',
                              // ignore: deprecated_member_use
                              biometricOnly: true,
                              // replaces stickyAuth in v3.0.0
                              persistAcrossBackgrounding: true,
                            );

                            if (didAuthenticate) {
                              Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const Homepage()));
                            }
                          } catch (e) {
                            setState(() => msg = "Auth Error: $e");
                          }
                        },
                      ),

                    CupertinoButton(
                        child: const Text('Reset Data', style: TextStyle(color: CupertinoColors.destructiveRed)),
                        onPressed: () {
                          showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text("Delete all local data?"),
                                actions: [
                                  CupertinoButton(
                                      child: const Text('Yes'),
                                      onPressed: () {
                                        box.clear();
                                        Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const SignupPage()));
                                      }),
                                  CupertinoButton(
                                      child: const Text('No'),
                                      onPressed: () => Navigator.pop(context)),
                                ],
                              ));
                        }),
                    const SizedBox(height: 10),
                    Text(msg, style: const TextStyle(color: CupertinoColors.destructiveRed), textAlign: TextAlign.center,)
                  ],
                ),
              )
            ],
          ),
        ));
  }
}