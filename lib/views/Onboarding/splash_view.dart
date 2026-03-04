import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Onboarding/onboarding_view.dart';
import 'package:medlink/views/Login/login_view.dart';

import 'package:medlink/views/services/session_view_model.dart'; // Session
import 'package:provider/provider.dart';
import 'package:medlink/views/main/main_screen.dart'; // Patient Home
import 'package:medlink/views/doctor/doctor_main_screen.dart'; // Doctor Home
import 'package:medlink/views/Ambulance/Ambulance%20main/ambulance_main_view.dart'; // Driver Home

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward().then((_) async {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      await userVM.loadUser();

      if (mounted) {
        // Standardize role to lowercase for comparison
        final String? userRole = userVM.role?.toLowerCase();
        
        if (userRole != null) {
          // Logged In - Navigate to respective Home Screen
          if (userRole == 'patient') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
          } else if (userRole == 'doctor') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorMainScreen()));
          } else if (userRole == 'driver') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AmbulanceMainView()));
          } else {
             // Unknown role but logged in, fallback to onboarding or login
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingView()));
          }
        } else {
          // Not logged in - Show onboarding for first-time or unauthenticated users
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingView()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "MedLink Africa",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Emergency & Healthcare",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
