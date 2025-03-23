import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sequential Navigation',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController =
      PageController(); // Controller untuk PageView
  int _currentPage = 0;

  final List<String> _titles = [
    "Welcome to MyApp!",
    "Track Your Progress",
    "Stay Connected"
  ];

  final List<String> _descriptions = [
    "This app will help you organize your tasks efficiently.",
    "Monitor your achievements and stay productive.",
    "Connect with friends and work together on your goals."
  ];

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300), 
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300), 
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _titles.length,
        itemBuilder: (context, index) {
          return _buildPage(
            _titles[index],
            _descriptions[index],
            index == _titles.length - 1,
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildPage(String title, String description, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          isLastPage
              ? ElevatedButton(
                  onPressed: () {
                    // Aksi ketika selesai
                    print("Onboarding Selesai!");
                  }, 
                  child: Text("Get Started"),
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? TextButton(
                  onPressed: _previousPage,
                  child: Text("Previous"),
              )
            : SizedBox.shrink(),
          Row(
            children: List.generate(
              _titles.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _nextPage,
            child: Text(_currentPage == _titles.length - 1 ? "Finish" : "Next"),
          ),
        ],
      ),
    );
  }
}