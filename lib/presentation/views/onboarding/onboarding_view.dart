import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_layout.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Pick Your Words",
      "desc": "Enter vocabulary you want to learn. Support for multiple words at once!",
      "icon": "✍️"
    },
    {
      "title": "AI Generates Magic",
      "desc": "Our Gemini AI creates a custom story using your selected words instantly.",
      "icon": "🪄"
    },
    {
      "title": "Learn in Context",
      "desc": "See Hindi meanings, listen to pronunciation, and practice reading daily.",
      "icon": "📚"
    },
    {
      "title": "Go Premium",
      "desc": "Unlock 10 words, Advanced difficulty, and lifetime story history!",
      "icon": "💎"
    },
  ];

  // Logic to save status and move to the app
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    // Set this to true so main.dart knows to skip this screen next time
    await prefs.setBool('seen_onboarding', true);

    if (mounted) {
      // Use pushReplacement so the user can't "Back" into onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _buildPage(_pages[i], colorScheme),
              ),
            ),

            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      "Skip",
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 16
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary, // Using primary for a stronger "Next" button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? "Start Learning" : "Next",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, String> data, ColorScheme colorScheme) {
    bool isPremiumPage = data['title'] == "Go Premium";

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data['icon']!, style: const TextStyle(fontSize: 100)),
          const SizedBox(height: 40),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data['desc']!,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.5
            ),
          ),
          if (isPremiumPage) ...[
            const SizedBox(height: 30),
            _buildPremiumFeature(Icons.check_circle, "10 Words per story", colorScheme),
            _buildPremiumFeature(Icons.check_circle, "Advanced Difficulty", colorScheme),
            _buildPremiumFeature(Icons.check_circle, "Unlimited History", colorScheme),
          ]
        ],
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
        ],
      ),
    );
  }
}