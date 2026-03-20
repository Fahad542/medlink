import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentStep = 1; // 1: Email/Phone, 2: OTP, 3: New Password
  int get currentStep => _currentStep;

  String _identifier = "";
  String _resetToken = "";
  String? _debugOtp;
  String? get debugOtp => _debugOtp;

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> sendResetLink(BuildContext context) async {
    final identifier = emailController.text.trim();
    if (identifier.isEmpty) {
      Utils.toastMessage(context, 'Please enter email or phone', isError: true);
      return;
    }

    setLoading(true);
    _identifier = identifier;

    try {
      final response = await _apiServices.forgotPassword(identifier);
      setLoading(false);
      if (response != null && response['success'] == true) {
        _currentStep = 2; // Move to OTP step
        final data = response['data'];
        if (data is Map && data.containsKey('otp')) {
          _debugOtp = data['otp'].toString();
        }
        notifyListeners();
        Utils.toastMessage(context, 'OTP sent to $identifier');
      } else {
        Utils.toastMessage(context, response['message'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      setLoading(false);
      Utils.toastMessage(context, e.toString(), isError: true);
    }
  }

  Future<void> verifyOtp(BuildContext context) async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      Utils.toastMessage(context, 'Please enter OTP', isError: true);
      return;
    }

    setLoading(true);
    try {
      final response =
          await _apiServices.verifyResetOtp(_identifier, otp);
      setLoading(false);
      if (response != null && response['success'] == true) {
        _resetToken = response['data']?['resetToken'] ?? '';
        _currentStep = 3; // Move to Reset Password step
        notifyListeners();
      } else {
        Utils.toastMessage(context, response['message'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      setLoading(false);
      Utils.toastMessage(context, e.toString(), isError: true);
    }
  }

  Future<void> resetPassword(BuildContext context) async {
    final newPassword = passwordController.text.trim();
    if (newPassword.isEmpty || newPassword.length < 6) {
      Utils.toastMessage(context, 'Password must be at least 6 characters', isError: true);
      return;
    }

    setLoading(true);
    try {
      final response = await _apiServices.resetPassword(
          _resetToken, newPassword);
      setLoading(false);
      if (response != null && response['success'] == true) {
        Utils.toastMessage(context, 'Password reset successfully');
        Navigator.pop(context); // Close bottom sheet
      } else {
        Utils.toastMessage(context, response['message'] ?? 'Failed to reset password', isError: true);
      }
    } catch (e) {
      setLoading(false);
      Utils.toastMessage(context, e.toString(), isError: true);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
