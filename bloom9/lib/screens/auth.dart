import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:appwrite/appwrite.dart';
import 'package:bloom9/screens/health_profile_creation.dart';
import 'package:bloom9/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:bloom9/services/appwrite_service.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _hidePassword = true;
  bool _isLoading = false;

  String _username = "";
  String _email = "";
  String _password = "";

Future<void> setupPushNotification() async {
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    return; // user said no, handle gracefully
  }

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) return;

  await AppwriteService.account.createPushTarget(
    targetId: ID.unique(),
    identifier: fcmToken,
  );
}

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  _formKey.currentState!.save();
   setState(() {
    _isLoading = true;
  });

  try {
    
    if (_isLogin) {
      // LOGIN
      await AppwriteService.account.createEmailPasswordSession(
        email: _email,
        password: _password,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>  Home(),
        ),
      );
    } else {
       await AppwriteService.account.create(
    userId: ID.unique(),
    email: _email,
    password: _password,
    name: _username,
  );

  // Login
  try {
  await AppwriteService.account.deleteSession(
    sessionId: 'current',
  );
} catch (_) {}
  await AppwriteService.account.createEmailPasswordSession(
    email: _email,
    password: _password,
  );

  // Get current user
  final user = await AppwriteService.account.get();
await AppwriteService.tablesDB.createRow(
  databaseId: "6a410fff001e52dbe195",
  tableId: "users",
  rowId: ID.unique(),
  data: {
    "userId": user.$id,
    "userName": _username,
    "email": _email,
  },
);


  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ct) => HealthProfileScreen(name: _username,) ));

  
    }
  }  on AppwriteException catch (e) {
     print(e.code);
  print(e.type);
  print(e.message);

  setState(() {
    _isLoading = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.message ?? "Something went wrong"),
    ),
  );
  }
}
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFEDEFF3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1D29).withOpacity(.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: Image.asset('assets/images/logo.png'),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _isLogin ? "Welcome back" : "Create your account",
                      style: const TextStyle(
                        color: Color(0xFF1A1D29),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _isLogin
                          ? "Log in to continue your journey"
                          : "Let's set things up for you",
                      style: TextStyle(
                        color: const Color(0xFF1A1D29).withOpacity(.5),
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 28),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: !_isLogin
                          ? Column(
                              key: const ValueKey("username"),
                              children: [
                                TextFormField(
                                  decoration: _inputDecoration(
                                    hint: "Username",
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (_isLogin) return null;
                                    if (value == null ||
                                        value.trim().length < 3) {
                                      return "Minimum 3 characters";
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _username = value!;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                            )
                          : const SizedBox(),
                    ),

                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: "Email",
                        icon: Icons.mail_outline,
                      ),
                      validator: (value) {
                        if (value == null || !value.contains("@")) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _email = value!;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      obscureText: _hidePassword,
                      decoration: _inputDecoration(
                        hint: "Password",
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePassword = !_hidePassword;
                            });
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF1A1D29).withOpacity(.4),
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return "Minimum 6 characters";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _password = value!;
                      },
                    ),

                    if (_isLogin) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0191F7),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {},
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                          color: Color(0xFF0191F7),
                          strokeWidth: 2.5,
                        ),
                      ),

                    if (!_isLoading)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0191F7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(
                            _isLogin ? "Login" : "Create Account",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? "Don't have an account?"
                              : "Already have an account?",
                          style: TextStyle(
                            color: const Color(0xFF1A1D29).withOpacity(.55),
                            fontSize: 14,
                          ),
                        ),
                        if (!_isLoading)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0191F7),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin ? "Sign Up" : "Login",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF1A1D29).withOpacity(.35)),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF1A1D29).withOpacity(.4),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEDEFF3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEDEFF3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0191F7), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF8A8A)),
      ),
    );
  }
}