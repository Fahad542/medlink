import 'package:flutter/material.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';

class DriverStep1Credentials extends StatefulWidget {
  final VoidCallback onNext;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final bool isLoading;

  const DriverStep1Credentials({
    super.key,
    required this.onNext,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    this.isLoading = false,
  });

  @override
  State<DriverStep1Credentials> createState() => _DriverStep1CredentialsState();
}

class _DriverStep1CredentialsState extends State<DriverStep1Credentials> {
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
              "Let's get started",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Join our emergency response team.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildAnimatedTextField(
              label: "Full Name",
              hint: "Enter your full name",
              icon: Icons.person_rounded,
              controller: widget.nameController,
              validator: (value) {
                if (value == null || value.isEmpty) return "Name is required";
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildAnimatedTextField(
              label: "Phone Number",
              hint: "Enter your phone number",
              icon: Icons.phone_android_rounded,
              controller: widget.phoneController,
              validator: (v) => v!.isEmpty ? "Required" : (v.length < 10 ? "Invalid phone number" : null),
            ),
            const SizedBox(height: 24),

            _buildAnimatedTextField(
              label: "Password",
              hint: "Minimum 8 characters",
              icon: Icons.lock_rounded,
              controller: widget.passwordController,
              isPassword: true,
              isObscure: _obscurePassword,
              onVisibilityToggle: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              validator: (value) {
                if (value == null || value.length < 8) return "Min 8 chars required";
                return null;
              },
            ),

            const SizedBox(height: 24),

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
            
            const SizedBox(height: 40),

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
            
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Or continue with",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[200], thickness: 1.5)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    icon: "assets/Icons/google.png", 
                    label: "Google",
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSocialButton(
                    icon: "assets/Icons/apple.png", 
                    label: "Apple",
                    onTap: () {},
                    isApple: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            
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
        height: 52, // Slightly taller
        decoration: BoxDecoration(
          color: isApple ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isApple 
              ? null 
              : Border.all(color: Colors.grey[200]!),
          boxShadow: [
             BoxShadow(
              color: isApple ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05),
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
                fontSize: 15,
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
      validator: (value) {
        if (validator != null) {
          return validator(controller.text);
        }
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
                border: null,
              ),
              child: TextField(
                controller: controller,
                obscureText: isObscure,
                onChanged: (text) {
                  state.didChange(text);
                  state.validate();
                },
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400, // Reduced from w500
                  color: Colors.black87,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.w400, fontSize: 13),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
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
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                ),
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
