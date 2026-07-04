import 'package:appwrite/appwrite.dart';
import 'package:bloom9/screens/authchoice.dart';
import 'package:bloom9/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:bloom9/screens/home.dart';
import 'package:bloom9/services/appwrite_service.dart';
import 'package:flutter/material.dart';

void main() async{
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> getStartScreen() async {
  try {
    final user = await AppwriteService.account.get();

    print("Logged in as ${user.email}");

    return Home();
  } on AppwriteException catch (e) {
    print(e.message);
    return const AuthChoiceScreen();
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
  ),
home: FutureBuilder(
  future: AppwriteService.account.get(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      print("account.get() failed: ${snapshot.error}");

      // 👇 Check if a session actually exists
      AppwriteService.account
          .getSession(sessionId: 'current')
          .then((session) {
            print("Session exists: ${session.$id}");
          })
          .catchError((e) {
            print("No session: $e");
          });

      return const AuthChoiceScreen();
    }

    final user = snapshot.data!;
    print("Logged in: ${user.email}");

    return Home();
  },
),
);
  }
}

