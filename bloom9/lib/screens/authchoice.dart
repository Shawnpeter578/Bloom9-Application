import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:bloom9/screens/auth.dart';
import 'package:bloom9/screens/health_profile_creation.dart';
import 'package:bloom9/screens/home.dart';
import 'package:bloom9/services/appwrite_service.dart';
import 'package:flutter/material.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  static const Color _ink = Color(0xFF1A1D29);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _surface = Color(0xFFF7F9FC);
  static const Color _border = Color(0xFFEDEFF3);


  Future<void> signInWithGoogle(BuildContext Context) async {

    try{
      await AppwriteService.account.createOAuth2Session(
    provider: OAuthProvider.google,
    success:
      'appwrite-callback-${AppwriteService.projectId}://success',
  failure:
      'appwrite-callback-${AppwriteService.projectId}://failure',
  );

  final user = await AppwriteService.account.get();
  final userId = user.$id;

  final rows = await AppwriteService.tablesDB.listRows(
  databaseId: AppwriteService.databaseId,
  tableId: AppwriteService.healthTableId,
  queries: [
    Query.equal("userId", [userId]),
    Query.limit(1),
  ],
);
  if (rows.rows.isEmpty) {
  // First time user
  Navigator.pushReplacement(
    Context,
    MaterialPageRoute(
      builder: (_) => const HealthProfileScreen(name: 'jamees'),
    ),
  );
} else {
  // Returning user
  Navigator.pushReplacement(
    Context,
    MaterialPageRoute(
      builder: (_) => const Home(),
    ),
  );
}
    } on  AppwriteException catch (e) {
    print(e.message);
  }
   

} 


//   Future<void> (BuildContext context) async {
//   try {
//     await AppwriteService.account.createOAuth2Session(
//       provider: OAuthProvider.google,
//       success: 'appwrite-callback-${AppwriteService.projectId}://success',
//       failure: 'appwrite-callback-${AppwriteService.projectId}://failure',
//     );

//     // This runs after the user successfully signs in and returns to the app
//     final user = await AppwriteService.account.get();
//     print(user.name);
//     print(user.email);

//     await AppwriteService.tablesDB.createRow(databaseId: AppwriteService.databaseId, tableId: AppwriteService.healthTableId, rowId: ID.unique(), data: {
//       "userId": user.$id,
//       "userName": user.name,
//       "email": user.email
//     });

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => Home()),
//     );
//   } on AppwriteException catch(e)  {
//     ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text(e.message ?? "Login failed"),
//     ),
//   );
//   } catch (e){
//     ScaffoldMessenger.of(context).showSnackBar(
//     const SnackBar(
//       content: Text("Something went wrong. Please try again."),
//     ),
//   );
//   }
// }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              SizedBox(
                height: 350,
                child: Image.asset('assets/images/logo.png'),
              ),

              const SizedBox(height: 0),

              const Text(
                "Your journey,\ntracked with care",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Sign in to continue to Bloom9",
                style: TextStyle(
                  color: _ink.withOpacity(.5),
                  fontSize: 15,
                ),
              ),

              const Spacer(flex: 3),

              // Google button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: ()=> signInWithGoogle(context),
                  child:Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "G",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: _primary,
      ),
    ),
    const SizedBox(width: 12),
    const Text(
      "Continue with Google",
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  ],
),
                ),
              ),

              const SizedBox(height: 12),

              // Email button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => AuthScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Continue with Email",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  
                ),
              ),

              const Spacer(flex: 2),

              Text(
                "By continuing, you agree to our Terms\nand Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink.withOpacity(.35),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}