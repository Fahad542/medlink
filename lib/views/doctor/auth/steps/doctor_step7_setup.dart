import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:medlink/core/constants/app_colors.dart';

class DoctorStep7Setup extends StatefulWidget {
  final VoidCallback onFinished;

  const DoctorStep7Setup({super.key, required this.onFinished});

  @override
  State<DoctorStep7Setup> createState() => _DoctorStep7SetupState();
}

class _DoctorStep7SetupState extends State<DoctorStep7Setup> {
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showCheck = true);
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/success.json',
            width: 180,
            height: 180,
            repeat: false,
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _showCheck ? "You're all set!" : "Setting up account...",
              key: ValueKey<bool>(_showCheck),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Redirecting to dashboard...",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
