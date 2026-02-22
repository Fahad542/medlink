import 'package:flutter/material.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';

class DriverStep3Otp extends StatefulWidget {
  final Function(String) onNext;
  final bool isLoading;
  final VoidCallback? onResend;
  final bool isResendLoading;

  const DriverStep3Otp({
    super.key,
    required this.onNext,
    this.isLoading = false,
    this.onResend,
    this.isResendLoading = false,
  });

  @override
  State<DriverStep3Otp> createState() => _DriverStep3OtpState();
}

class _DriverStep3OtpState extends State<DriverStep3Otp> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Add listeners to rebuild on focus change for the UI state
    for (var node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-verify if 4 digits entered
        String otp = _controllers.map((c) => c.text).join();
        if (otp.length == 4) {
           widget.onNext(otp);
        }
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We've sent a 4-digit code to your number.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 4; i++) ...[
                 _buildOtpDigitField(i),
                 if (i != 3) const SizedBox(width: 16),
              ],
            ],
          ),
          
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: Colors.red),
                  const SizedBox(width: 8),
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
          
          const SizedBox(height: 32),

            CustomButton(
              text: "Verify Code",
              isLoading: widget.isLoading,
              onPressed: () {
                String otp = _controllers.map((c) => c.text).join();
                if (otp.length == 4) {
                   widget.onNext(otp);
                } else {
                  setState(() {
                    _errorText = "Please enter full 4-digit code";
                  });
                }
              },
            ),
           const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: widget.onResend,
              child: Text(
                "Resend Code",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w400, // Reduced to w400
                  color: AppColors.primary, 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpDigitField(int index) {
    bool isFocused = _focusNodes[index].hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 56, 
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
              color: Colors.black.withOpacity(0.04), // Golden Rule: Cleaner
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          onChanged: (value) => _onChanged(value, index),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
             LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.inter(
            fontSize: 22, 
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          cursorColor: AppColors.primary,
          showCursor: false,
          decoration: const InputDecoration(
            counterText: "",
            filled: false,
            fillColor: Colors.transparent, 
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
