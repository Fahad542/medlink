import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';

class Step3Otp extends StatefulWidget {
  final String phoneNumber;
  final String? debugOtp; // Add this
  final Function(String) onNext;
  final VoidCallback onResend;
  final bool isLoading;
  final bool isResendLoading;

  const Step3Otp({
    super.key,
    required this.phoneNumber,
    this.debugOtp, // Add this
    required this.onNext,
    required this.onResend,
    this.isLoading = false,
    this.isResendLoading = false,
  });

  @override
  State<Step3Otp> createState() => _Step3OtpState();
}

class _Step3OtpState extends State<Step3Otp> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());
  String? _errorText;

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-submit if last digit
        String otp = _controllers.map((c) => c.text).join();
        if (otp.length == _otpLength) {
          widget.onNext(otp);
        }
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {}); // Rebuild for button state if needed
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "Enter Code",
            style: GoogleFonts.inter(
              fontSize: 24, // Reduced from 28 to match others
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14, // Reduced from 16
                color: Colors.grey[500],
                height: 1.5,
              ),
              children: [
                TextSpan(text: "We sent a $_otpLength-digit code to "),
                TextSpan(
                  text: widget.phoneNumber.isEmpty
                      ? "+1 234 567 890"
                      : widget.phoneNumber,
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32), // Reduced from 48

          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bug_report_outlined,
                        size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text(
                      "Debug OTP: ${widget.debugOtp ?? 'Checking console...'}",
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centered for better focus
            children: [
              for (int i = 0; i < _otpLength; i++) ...[
                _buildOtpDigitField(i),
                if (i != _otpLength - 1)
                  const SizedBox(width: 12), // Spacing between digits
              ],
            ],
          ),

          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          CustomButton(
            text: "Verify Phone Number",
            isLoading: widget.isLoading,
            onPressed: () {
              String otp = _controllers.map((c) => c.text).join();
              if (otp.length == _otpLength) {
                setState(() => _errorText = null);
                widget.onNext(otp);
              } else {
                setState(() {
                  _errorText = "Please enter full $_otpLength-digit code";
                });
              }
            },
          ),
          const SizedBox(height: 20), // Reduced from 24
          Center(
            child: TextButton(
              onPressed: widget.isResendLoading ? null : widget.onResend,
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: Text(
                "Resend Code",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpDigitField(int index) {
    bool isActive =
        _focusNodes[index].hasFocus || _controllers[index].text.isNotEmpty;
    bool isFocused = _focusNodes[index].hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 45,
      height: 64, // Reduced height for more compact look
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Golden Rule: 16
        border: isFocused
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22, // Reduced font size
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          cursorColor: AppColors.primary,
          maxLength: 1,
          showCursor: false, // Hide cursor for cleaner look
          onChanged: (value) => _onDigitEntered(index, value),
          decoration: const InputDecoration(
            counterText: "",
            filled: false, // Ensure transparency
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
      ),
    );
  }
}
