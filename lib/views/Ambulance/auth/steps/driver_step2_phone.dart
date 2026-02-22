import 'package:flutter/material.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';

class DriverStep2Phone extends StatefulWidget {
  final VoidCallback onNext;
  final TextEditingController phoneController;
  final bool isLoading;

  const DriverStep2Phone({
    super.key,
    required this.onNext,
    required this.phoneController,
    this.isLoading = false,
  });

  @override
  State<DriverStep2Phone> createState() => _DriverStep2PhoneState();
}

class _DriverStep2PhoneState extends State<DriverStep2Phone> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "Verification",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Enter your mobile number for verification.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),

            FormField<String>(
              validator: (v) {
                if (widget.phoneController.text.isEmpty) return "Required";
                if (widget.phoneController.text.length < 10) return "Please enter valid number";
                return null;
              },
              builder: (FormFieldState<String> state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04), // Golden Rule: Cleaner shadow
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "+1", 
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: widget.phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (text) {
                                state.didChange(text);
                                state.validate();
                              },
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w400, // Reduced from w500
                                letterSpacing: 0.8
                              ),
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: "Enter phone number",
                                hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.w400, fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text(
                              state.errorText ?? "",
                              style: GoogleFonts.inter(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }
            ),
            
            const SizedBox(height: 48),

            CustomButton(
              text: "Send OTP",
              isLoading: widget.isLoading,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onNext();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
