import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:provider/provider.dart';

class DeleteAccountSheet extends StatefulWidget {
  const DeleteAccountSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const DeleteAccountSheet(),
    );
  }

  @override
  _DeleteAccountSheetState createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<DeleteAccountSheet> {
  final ApiServices _apiServices = ApiServices();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  int _step = 1; // 1: Initial Warning, 2: OTP Entry
  String? _debugOtp;

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiServices.sendDeleteAccountOtp();
      setState(() => _isLoading = false);
      if (response != null && response['success'] == true) {
        setState(() => _step = 2);
        final data = response['data'];
        if (data is Map && data.containsKey('otp')) {
          setState(() => _debugOtp = data['otp'].toString());
        }
        Utils.toastMessage(context, 'OTP sent to your registered email/phone');
      } else {
        Utils.toastMessage(context, response['message'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Utils.toastMessage(context, e.toString(), isError: true);
    }
  }

  Future<void> _verifyOtpAndDelete() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      Utils.toastMessage(context, 'Please enter valid OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiServices.verifyDeleteAccountOtp(otp);
      setState(() => _isLoading = false);
      
      if (response != null && response['success'] == true) {
        Utils.toastMessage(context, 'Account successfully deleted');
        Navigator.pop(context);
        Provider.of<UserViewModel>(context, listen: false).logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      } else {
        Utils.toastMessage(context, response['message'] ?? 'Invalid OTP', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Utils.toastMessage(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _step == 1 ? "Delete Account" : "Verify Deletion",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _step == 1
                    ? "This action is irreversible. All your data will be permanently removed."
                    : "Enter the OTP sent to you to confirm account deletion.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (_step == 2) ...[
               if (kDebugMode && _debugOtp != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bug_report_outlined, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Text(
                          "Debug OTP: $_debugOtp",
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
               Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 15, color: Colors.black87),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Enter 6-digit OTP",
                      hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.w400, fontSize: 13),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.security_rounded, color: AppColors.primary, size: 18),
                        ),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                ),
              ],

            const SizedBox(height: 32),

            CustomButton(
              text: _step == 1 ? "Send OTP to Delete" : "Confirm Deletion",
              height: 56,
              fontSize: 16,
              backgroundColor: AppColors.error,
              isLoading: _isLoading,
              onPressed: () {
                if (_step == 1) {
                  _sendOtp();
                } else {
                  _verifyOtpAndDelete();
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
