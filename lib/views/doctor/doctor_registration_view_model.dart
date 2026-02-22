import 'package:flutter/material.dart';

class DoctorRegistrationViewModel extends ChangeNotifier {
  // Form Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // State
  // File placeholders (In real app, use File or XFile)
  String? _selectedLicenseFile;
  String? _selectedIdFile;

  bool _isLoading = false;

  // Getters
  String? get selectedLicenseFile => _selectedLicenseFile;
  String? get selectedIdFile => _selectedIdFile;
  bool get isLoading => _isLoading;


  // Actions
  Future<void> pickLicenseFile() async {
    // Implement license file picker logic
    // For now, simulate picking a file
    _selectedLicenseFile = "license_doc.pdf";
    notifyListeners();
  }

  Future<void> pickIdFile() async {
     // Implement ID file picker logic
    // For now, simulate picking a file
    _selectedIdFile = "id_card.jpg";
    notifyListeners();
  }

  Future<void> submitRegistration({
    required String specialty,
    required String experience,
    required String licenseNumber,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    
    if (nameController.text.isEmpty || 
        emailController.text.isEmpty || 
        phoneController.text.isEmpty || 
        passwordController.text.isEmpty || 
        confirmPasswordController.text.isEmpty) {
      onError("Please fill in all fields.");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      onError("Passwords do not match.");
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    // Simulate API call and validation
    await Future.delayed(const Duration(seconds: 2));

    bool success = true; // Simulate success
    
    _isLoading = false;
    notifyListeners();

    if (success) {
      onSuccess();
    } else {
      onError("Registration failed. Please try again.");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    bioController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
