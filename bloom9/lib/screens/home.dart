import 'package:appwrite/appwrite.dart';
import 'package:bloom9/getters and storages/get.dart';
import 'package:bloom9/screens/auth.dart';
import 'package:bloom9/screens/authchoice.dart';
import 'package:bloom9/screens/homeScreen.dart';
import 'package:bloom9/screens/profile.dart';
import 'package:bloom9/services/appwrite_service.dart';
import 'package:bloom9/services/profile_service.dart';
import 'package:bloom9/services/watch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:bloom9/theme/colors.dart';
import 'dart:async';


  

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;
  Map<String, dynamic>? healthData;
  bool isLoading = true;
  bool hasError = false; // Added error state
  int? heartRate;
  double? weight;
  @override
  void initState() {
    super.initState();
    setupPushNotification();
    loadHealthData();
    loadLatestHealthLog();

  }



 Future<void> loadHeartRate() async {
  try {
    final bpm = await WatchService().getHeartRate();

    if (!mounted) return;

    setState(() {
      heartRate = bpm;
    });

    print("Heart Rate: $bpm");
  } catch (e) {
    print("Heart Rate Error: $e");
  }
}

  Future<void> loadHealthData() async {
    try {
      healthData = await HealthService.getHealthData();
      await loadHeartRate();
      setState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true; // Properly catch the error
      });
    }
  }

  Future<void> logout(BuildContext context) async {

    final bool ? shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (context){
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(onPressed: ()=> Navigator.pop(context,false ), child: const Text('Cancel')),
            ElevatedButton(onPressed: ()=> Navigator.pop(context, true), child: const Text('Log Out'), style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  ),)
          ],
        );
      }
    );
    if(shouldLogOut != true) return;
    try {
      await AppwriteService.account.deleteSession(sessionId: "current");

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }
Future<void> loadLatestHealthLog() async{
  final user = await AppwriteService.account.get();
  final userId = user.$id;
  final rows = await AppwriteService.tablesDB.listRows(
  databaseId: AppwriteService.databaseId,
  tableId: AppwriteService.daily_health_logs,
  queries: [
    Query.equal("userId", [userId]),
    Query.orderDesc("logDate"),
    Query.limit(1),
  ],

);


final latest = rows.rows.first;

setState(() {
  weight = (latest.data["weight"] as num?)?.toDouble();
});


  }




  
Future<void> setupPushNotification() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    print("FCM Tokenssssssssssssssssssssssssssssssssssssssss: $token");
    if (token == null) return;

    await AppwriteService.account.createPushTarget(
      targetId: ID.unique(),
      identifier: token,
    );

    print("Push target created.");
  } on AppwriteException catch (e) {
    if (e.code == 409) {
      print("Push target already registered.");
    } else {
      print(e);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    // 1. Handle Loading State
    if (isLoading) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Handle Error State (Prevents the infinite loading spinner bug)
    if (hasError || healthData == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Oops! We couldn't load your data."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => isLoading = true);
                  loadHealthData();
                },
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Main Pages
    final pages = [
      HomeScreen(
        userName: healthData!['username'],
        weekNumber: healthData!['pregnancyWeek'],
        trimester: getTrimester(healthData!['pregnancyWeek']),
        babySizeComparison: getBabySize(healthData!['pregnancyWeek']),
        babySizeDescription: getBabyDescription(healthData!['pregnancyWeek']),
        daysToGo: getDaysToGo(healthData!['pregnancyWeek']),
        dueDateLabel: getDueDate(healthData!['pregnancyWeek']),
        heartRate: heartRate,
        weightKg:weight ,
        
      ),
     ProfileScreen(), // Made this const for performance
    ];

    return Scaffold(
      backgroundColor: bg,
      // FIX: This allows your home screen to scroll BEHIND the floating navigation bar
      extendBody: true, 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: SizedBox(height: 150,
          child: Image.asset('assets/images/logo.png', fit:BoxFit.contain )),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(
              Icons.logout_rounded,
              color: subtleInk,
            ),
          ),
        ],
      ),
      body: pages[currentIndex],
      
      // Floating Bottom Navigation Bar
      bottomNavigationBar: SafeArea(
        // Use SafeArea so the floating bar isn't blocked by iOS home indicators
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36), // More rounded looks better on floating bars
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NavButton(
                  icon: Icons.home_rounded,
                  label: "Home",
                  selected: currentIndex == 0,
                  onTap: () =>  setState(() => currentIndex = 0),
                            ),
                NavButton(
                  icon: Icons.person_rounded,
                  label: "Profile",
                  selected: currentIndex == 1,
                  onTap: () => setState(() => currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Standardizing the inactive color
    final subtleInkColor = Colors.grey.shade400;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? const Color(0xFF2563EB) : subtleInkColor,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1.0 : 0.0,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}