import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';

class Step1Credentials extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final VoidCallback onNext;
  final bool isLoading;
  final Future<void> Function()? onGoogleSignIn;
  final Future<void> Function()? onAppleSignIn;

  const Step1Credentials({
    super.key,
    required this.nameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.onNext,
    this.isLoading = false,
    this.onGoogleSignIn,
    this.onAppleSignIn,
  });

  @override
  State<Step1Credentials> createState() => _Step1CredentialsState();
}

class _Step1CredentialsState extends State<Step1Credentials> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _showOptionalHint = false;

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
              "Let's get started!",
              style: GoogleFonts.inter(
                fontSize: 24, // Reduced from 28
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6), // Reduced from 8
            Text(
              "Enter your details to create an account",
              style: GoogleFonts.inter(
                fontSize: 14, // Reduced from 16
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24), // Reduced from 32
            _buildAnimatedTextField(
              label: "Full Name",
              hint: "Enter your full name",
              icon: Icons.person_rounded,
              controller: widget.nameController,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 16),
            _buildAnimatedTextField(
              label: "Phone Number",
              hint: "Enter your phone number",
              icon: Icons.phone_android_rounded,
              controller: widget.phoneController,
              validator: (v) => v!.isEmpty ? "Required" : (v.length < 10 ? "Invalid phone number" : null),
            ),
            const SizedBox(height: 16),
            _buildAnimatedTextField(
              label: "Password",
              hint: "Create a password",
              icon: Icons.lock_rounded,
              controller: widget.passwordController,
              isPassword: true,
              isObscure: _obscurePassword,
              onVisibilityToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              validator: (v) => v!.length < 6 ? "Min 6 characters" : null,
            ),
            const SizedBox(height: 16), // Reduced from 20
            _buildAnimatedTextField(
              label: "Confirm Password",
              hint: "Repeat password",
              icon: Icons.lock_outline_rounded,
              controller: widget.confirmPasswordController,
              isPassword: true,
              isObscure: _obscureConfirm,
              onVisibilityToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) => v != widget.passwordController.text ? "Passwords do not match" : null,
            ),
            const SizedBox(height: 32), // Reduced from 40
            CustomButton(
              text: "Send OTP",
              isLoading: widget.isLoading,
              onPressed: () {
                setState(() => _showOptionalHint = true);
                if (_formKey.currentState!.validate()) {
                  widget.onNext();
                }
              },
            ),

            const SizedBox(height: 32),

            if (widget.onGoogleSignIn != null ||
                widget.onAppleSignIn != null) ...[
              Row(
                children: [
                  Expanded(
                      child: Divider(color: Colors.grey[200], thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Or continue with",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(color: Colors.grey[200], thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (widget.onGoogleSignIn != null)
                    Expanded(
                      child: _buildSocialButton(
                        icon: "assets/Icons/google.png",
                        label: "Google",
                        onTap: () async {
                          await widget.onGoogleSignIn!();
                        },
                      ),
                    ),
                  if (widget.onGoogleSignIn != null &&
                      widget.onAppleSignIn != null)
                    const SizedBox(width: 16),
                  if (widget.onAppleSignIn != null)
                    Expanded(
                      child: _buildSocialButton(
                        icon: "assets/Icons/apple.png",
                        label: "Apple",
                        onTap: () async {
                          await widget.onAppleSignIn!();
                        },
                        isApple: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "Login",
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isApple = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56, // Golden Rule: 56px
        decoration: BoxDecoration(
          color: isApple ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isApple
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: isApple ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05), // Standard shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isApple
                ? const Icon(Icons.apple, size: 24, color: Colors.white)
                : Image.asset("assets/google.png", height: 22, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.red)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15, // Golden Rule: 15/16px
                color: isApple ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
    bool isOptional = false,
    bool showOptionalHint = false,
  }) {
    return FormField<String>(
      validator: validator != null ? (v) => validator(controller.text) : null,
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // Golden Rule: 16
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04), // Golden Rule: Cleaner shadow
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: null, // Removed error border
              ),
              child: TextField(
                controller: controller,
                obscureText: isObscure,
                onChanged: (text) => state.didChange(text),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.w400, fontSize: 13),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12), // Adjusted padding
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 18),
                    ),
                  ),
                  suffixIcon: isPassword
                      ? IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: onVisibilityToggle,
                  )
                      : null,
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
                    borderSide: BorderSide.none, // Removed focus border color
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20), // Golden Rule: v18
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
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
              )
            else if (isOptional && showOptionalHint)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 6),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      "Optional",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
