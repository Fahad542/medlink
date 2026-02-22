import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Your family's well-being, our top priority",
      "desc": "We understand that nothing matters more than the health and comfort of your loved ones.",
      "image": "assets/trusted.jpg"
    },
    {
      "title": "Emergency Help,\nJust a Tap Away",
      "desc": "Instant ambulance dispatch and live tracking to ensure safety when it counts the most.",
      "image": "assets/emergency_onboard.jpg"
    },
    {
      "title": "Expert Consultation,\nAnytime, Anywhere",
      "desc": "Connect with top specialists via video or chat from the comfort of your home.",
      "image": "assets/online_consult.png"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) => _buildOnboardingPage(
              _onboardingData[index]["title"]!,
              _onboardingData[index]["desc"]!,
              _onboardingData[index]["image"]!,
            ),
          ),

          // Bottom Controls (Dots & Button)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _onboardingData.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: _currentPage == index ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Main Button
                CustomButton(
                  text: _currentPage == _onboardingData.length - 1 ? "Get Started" : "Next",
                  fontSize: 14, // Matched Login
                  height: 56,
                  // Default borderRadius and fontWeight will be used
                  onPressed: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginView()),
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuart,
                      );
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(String title, String desc, String imagePath) {
    return Stack(
      children: [
        // Background Image
        Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.grey[100], // Fallback
                ),
                child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: imagePath.contains("online_consult") ? const Alignment(0.7, 0) : Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                        // Fallback placeholder pattern
                        return Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[300]));
                    },
                ),
            ),
        ),
        
        // Gradient Fade (Optional, for smoother transition to white if needed)
        Positioned(
            top: MediaQuery.of(context).size.height * 0.65 - 100,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                            Colors.white.withOpacity(0),
                            Colors.white,
                        ]
                    )
                ),
            ),
        ),

        // Bottom White Card
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      )
                    ]
                ),
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
                child: Column(
                    children: [
                        Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                                height: 1.3,
                            ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                            desc,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                                height: 1.6,
                            ),
                        ),
                        const SizedBox(height: 32), // Added space
                    ],
                ),
            ),
        ),
      ],
    );
  }
}
