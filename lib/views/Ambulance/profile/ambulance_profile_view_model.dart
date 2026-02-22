import 'package:flutter/material.dart';
import 'package:medlink/views/Login/login_view.dart';

class AmbulanceProfileViewModel extends ChangeNotifier {
  // Mock User Data
  final String driverName = "Alex Driver";
  final String driverId = "AMB-2024-05";
  final String licensePlate = "NY-123-456";
  final String phone = "+1 (555) 123-4567";

  void logout(BuildContext context) {
    // Clear session logic here
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }
}
