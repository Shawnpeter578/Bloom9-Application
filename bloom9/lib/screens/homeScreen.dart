import 'package:bloom9/screens/logs.dart';
import 'package:bloom9/screens/reminders_screen.dart';
import 'package:bloom9/screens/vitals_trends.dart';
import 'package:flutter/material.dart';
import 'package:bloom9/getters and storages/get.dart';

// Bloom9 palette — sampled from the app logo
class Bloom9Colors {
  static const pink = Color(0xFFE28ABE);
  static const pinkLight = Color(0xFFFBEAF0);
  static const pinkBorder = Color(0xFFF4C0D1);
  static const pinkText = Color(0xFF72243E);
  static const pinkTextMuted = Color(0xFFB0648A);
  static const pinkGradientEnd = Color(0xFFD474AB);

  static const blue = Color(0xFF0191F7);
  static const blueLight = Color(0xFFF2F8FE);
  static const blueBorder = Color(0xFFDCEBFB);
  static const blueText = Color(0xFF0C447C);
  static const blueTextMuted = Color(0xFF5B7C9A);

  // Added a soft coral color for the "Check Now" card so it stands out aesthetically
  static const coral = Color(0xFFFF8A8A);
  static const coralLight = Color(0xFFFFF0F0);

  static const surface = Color(0xFFF7F9FB);
  static const border = Color(0xFFE7E7E5);
  static const textPrimary = Color(0xFF2C2C2A);
  static const textSecondary = Color(0xFF777777);
}

class HomeScreen extends StatelessWidget {
  final String userName;
  final int weekNumber;
  final String trimester;
  final String babySizeComparison;
  final String babySizeDescription;
  final int daysToGo;
  final String dueDateLabel;
  final int? heartRate;
  final double? weightKg;
  final double weightDeltaKg;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.weekNumber,
    required this.trimester,
    required this.babySizeComparison,
    required this.babySizeDescription,
    required this.daysToGo,
    required this.dueDateLabel,
    this.heartRate,
    this.weightKg,
    this.weightDeltaKg = 0,
  });

  String getGreeting() {
  final hour = DateTime.now().hour;

  if (hour >= 5 && hour < 12) {
    return "Good Morning ☀️";
  } else if (hour >= 12 && hour < 17) {
    return "Good Afternoon 🌤";
  } else if (hour >= 17 && hour < 21) {
    return "Good Evening 🌅";
  } else {
    return "Good Night 🌙";
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Bloom9Colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          // This forces the screen to scroll and gives it a nice bounce
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildHeroCard(),
              const SizedBox(height: 24),
              _buildMetricsRow(),
              const SizedBox(height: 24),
              _buildCheckNowCard(context), // New Card added here
              const SizedBox(height: 32),
              _buildQuickActionsRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
             "${getGreeting()}, ${userName.split(' ').first}!",
              style: const TextStyle(
                fontSize: 14,
                color: Bloom9Colors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Bloom9Colors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
       
      ],
    );
  }

  Widget _buildHeroCard() {
    final progress = (weekNumber / 40).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Bloom9Colors.pink, Bloom9Colors.pinkGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Bloom9Colors.pink.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trimester.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}% there',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Week $weekNumber',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'of 40',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _heroStat('Days to go', '$daysToGo')),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(child: _heroStat('Due date', dueDateLabel)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            icon: Icons.favorite_rounded,
            iconColor: Bloom9Colors.blue,
            iconBg: Bloom9Colors.blueLight,
            label: 'Heart Rate',
            value: heartRate != null ? '$heartRate' : '--',
            unit: 'bpm',
            footer: heartRate != null ? 'Synced' : 'Connect watch',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _metricCard(
            icon: Icons.monitor_weight_rounded,
            iconColor: Bloom9Colors.pink,
            iconBg: Bloom9Colors.pinkLight,
            label: 'Weight',
            value: weightKg != null ? weightKg!.toStringAsFixed(1) : '--',
            unit: 'kg',
            footer: weightKg != null
                ? '${weightDeltaKg >= 0 ? '+' : ''}${weightDeltaKg.toStringAsFixed(1)} this week'
                : 'No entries yet',
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String unit,
    required String footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Bloom9Colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Bloom9Colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Bloom9Colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            footer,
            style: TextStyle(
              fontSize: 11,
              color: Bloom9Colors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Check Now Card
  Widget _buildCheckNowCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Bloom9Colors.coralLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Bloom9Colors.coral.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Material & InkWell give it a beautiful ripple effect when tapped
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigates to your separate screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CheckNowScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_information_rounded,
                    color: Bloom9Colors.coral,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Symptom Checker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Bloom9Colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Feeling unwell? Log it now.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Bloom9Colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Bloom9Colors.coral,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
Widget _buildQuickActionsRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Bloom9Colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          child: Row( // <-- Fixed: Changed 'children: [' to 'child: Row('
            children: [
              // Logs
              _quickAction(
                icon: Icons.assignment_rounded,
                color: Bloom9Colors.blue,
                label: 'Logs',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx)=> HealthLogScreen() ))
              ),
              const SizedBox(width: 20),
              
              // Reminders
              _quickAction(
                icon: Icons.trending_up_sharp,
                color: const Color(0xFF9E84D7), 
                label: 'Vitals Trends',
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (ctx)=> VitalsTrendsScreen()))
                // onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (ctx)=> RemindersScreen())),
              ),
              const SizedBox(width: 20),
              
              // Water 
              _quickAction(
                icon: Icons.water_drop_rounded,
                color: const Color(0xFF4CA5E2),
                label: 'Water',
                onTap: () => print("Water tapped"),
              ),
              const SizedBox(width: 20),
              
              // SOS
              _quickAction(
                icon: Icons.emergency_rounded, 
                color: Bloom9Colors.coral,
                label: 'SOS',
                onTap: () => print("SOS tapped"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Updated to include an onTap callback and InkWell for interaction
  Widget _quickAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Icon(icon, size: 26, color: color),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Bloom9Colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// --- Placeholder Screen ---
// I added this so your code will compile without errors when you paste it.
// You can replace this with your actual screen later.
class CheckNowScreen extends StatelessWidget {
  const CheckNowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Symptoms'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Text('This is the screen you will build separately!'),
      ),
    );
  }
}