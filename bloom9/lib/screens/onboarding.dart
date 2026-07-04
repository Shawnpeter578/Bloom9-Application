import 'package:bloom9/screens/home.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  int _currentPage = 0;

  final List<Map<String, dynamic>> pages = [
    {
      "icon": Icons.favorite_rounded,
      "title": "Welcome to Bloom",
      "subtitle":
          "Your personal companion for a healthier and happier pregnancy journey.",
      "color": Color(0xFFE8F1FF),
    },
    {
      "icon": Icons.monitor_heart_rounded,
      "title": "Track Your Health",
      "subtitle":
          "Monitor your heart rate, daily activities, and important health insights in one place.",
      "color": Color(0xFFE7F8FF),
    },
    {
      "icon": Icons.insights_rounded,
      "title": "Smart Insights",
      "subtitle":
          "Receive personalized predictions and recommendations based on your health data.",
      "color": Color(0xFFEAF4FF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == pages.length - 1;

   
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx)=> Home()));
                  },
                  child: const Text("Skip"),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemBuilder: (context, index) {
                  final page = pages[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: page["color"],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page["icon"],
                            size: 100,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 50),

                        Text(
                          page["title"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          page["subtitle"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 28 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.blue
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLastPage) {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx)=> Home()));
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    isLastPage ? "Get Started" : "Next",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}