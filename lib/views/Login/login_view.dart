import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Register/register_view.dart';
import 'package:medlink/views/Register/register_viewmodel.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'login_view_model.dart';
import 'forgot_password_viewmodel.dart';

class LoginView extends StatelessWidget {
  final String? initialRole;
  const LoginView({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Text(
                      "Let's get started",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue to MedLink",
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Toggle
                    _buildLoginToggle(viewModel, context),

                    const SizedBox(height: 24),

                    // Login Form
                    Form(
                      key: viewModel.formKey,
                      child: Column(
                        children: [
                          if (viewModel.isEmailLogin)
                            _buildModernTextField(
                              context,
                              controller: viewModel.emailController,
                              hint: "Email Address",
                              icon: Icons.email_rounded,
                              validator: (v) => v!.isEmpty
                                  ? "Required"
                                  : (!v.contains("@") ? "Invalid email" : null),
                            )
                          else
                            _buildModernTextField(
                              context,
                              controller: viewModel.phoneController,
                              hint: "Phone Number",
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v!.isEmpty
                                  ? "Required"
                                  : (v.length < 10
                                      ? "Invalid phone number"
                                      : null),
                            ),
                          const SizedBox(height: 16),

                          // Password Field
                          _buildModernTextField(
                            context,
                            controller: viewModel.passwordController,
                            hint: "Password",
                            icon: Icons.lock_rounded,
                            isPassword: true,
                            isObscured: viewModel.obscurePassword,
                            onVisibilityToggle: () {
                              viewModel.toggleObscurePassword();
                            },
                            validator: (v) => v!.isEmpty
                                ? "Required"
                                : (v.length < 6 ? "Min 6 characters" : null),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _showForgotPasswordSheet(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text("Forgot Password?",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w400, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    CustomButton(
                      text: "Login",
                      height: 56,
                      fontSize: 14,
                      isLoading: viewModel.loading,
                      onPressed: () {
                        viewModel.loginApi(context);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Social Login Divider
                    Row(
                      children: [
                        Expanded(
                            child:
                                Divider(color: Colors.grey[200], thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("",
                              style: GoogleFonts.inter(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400)),
                        ),
                        Expanded(
                            child:
                                Divider(color: Colors.grey[200], thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Social Icons
                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            icon: "assets/google.png",
                            label: "Google",
                            onTap: () {
                              // In real app, call GoogleSignIn() then:
                              // viewModel.socialLoginApi(context, 'google', googleToken);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Google Sign-In integration required")),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSocialButton(
                            icon: "assets/Icons/apple.png",
                            label: "Apple",
                            onTap: () {
                              // In real app, call SignWithApple() then:
                              // viewModel.socialLoginApi(context, 'apple', appleToken);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Apple Sign-In integration required")),
                              );
                            },
                            isApple: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: GoogleFonts.inter(
                                color: Colors.grey[600], fontSize: 14)),
                        GestureDetector(
                          onTap: () {
                            _showRegistrationPopup(context);
                          },
                          child: Text(
                            "Sign Up",
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginToggle(LoginViewModel viewModel, BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Very light grey background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: !viewModel.isEmailLogin
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.44,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => viewModel.toggleLoginType(false),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        "Phone",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: !viewModel.isEmailLogin
                              ? Colors.white
                              : Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => viewModel.toggleLoginType(true),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        "Email",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: viewModel.isEmailLogin
                              ? Colors.white
                              : Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.04), // Golden Rule: Cleaner shadow
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: isObscured,
                keyboardType: keyboardType,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: Colors.black87),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                      fontSize: 13),
                  prefixIcon: Padding(
                    padding:
                        const EdgeInsets.all(12), // Adjusted for larger height
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
                            isObscured
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: onVisibilityToggle,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18), // Golden Rule: v18
                ),
                onChanged: (text) => state.didChange(text),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 14, color: AppColors.error),
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
      },
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ChangeNotifierProvider(
          create: (_) => ForgotPasswordViewModel(),
          child: Consumer<ForgotPasswordViewModel>(
            builder: (context, viewModel, child) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
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
                          viewModel.currentStep == 1
                              ? "Forgot Password"
                              : viewModel.currentStep == 2
                                  ? "Verify OTP"
                                  : "Reset Password",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          viewModel.currentStep == 1
                              ? "Enter your email or phone to reset your password"
                              : viewModel.currentStep == 2
                                  ? "Enter the 6-digit code sent to you"
                                  : "Enter your new password below",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (viewModel.currentStep == 1) ...[
                        _buildModernTextField(
                          context,
                          controller: viewModel.emailController,
                          hint: "Email Address or Phone",
                          icon: Icons.contact_mail_rounded,
                        ),
                      ] else if (viewModel.currentStep == 2) ...[
                        if (kDebugMode && viewModel.debugOtp != null)
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
                                    "Debug OTP: ${viewModel.debugOtp}",
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
                        _buildModernTextField(
                          context,
                          controller: viewModel.otpController,
                          hint: "Enter OTP code",
                          icon: Icons.lock_clock_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ] else if (viewModel.currentStep == 3) ...[
                        _buildModernTextField(
                          context,
                          controller: viewModel.passwordController,
                          hint: "New Password",
                          icon: Icons.lock_reset_rounded,
                          isPassword: true,
                          isObscured: true,
                        ),
                      ],
                      const SizedBox(height: 32),
                      CustomButton(
                        text: viewModel.currentStep == 1
                            ? "Send OTP"
                            : viewModel.currentStep == 2
                                ? "Verify Code"
                                : "Reset Password",
                        height: 56,
                        fontSize: 16,
                        isLoading: viewModel.isLoading,
                        onPressed: () {
                          if (viewModel.currentStep == 1) {
                            viewModel.sendResetLink(context);
                          } else if (viewModel.currentStep == 2) {
                            viewModel.verifyOtp(context);
                          } else {
                            viewModel.resetPassword(context);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showRegistrationPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Create Account",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select your role to join MedLink",
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildRegistrationOption(
                context,
                title: "Register as Patient",
                subtitle: "Find doctors & book appointments",
                icon: Icons.person_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterView(
                              initialRole: UserRole.patient)));
                },
              ),
              const SizedBox(height: 16),
              _buildRegistrationOption(
                context,
                title: "Register as Doctor",
                subtitle: "Manage patients & schedule",
                icon: Icons.medical_services_rounded,
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterView(
                              initialRole: UserRole.doctor)));
                },
              ),
              const SizedBox(height: 16),
/*              _buildRegistrationOption(
                context,
                title: "Register as Driver",
                subtitle: "Join emergency response team",
                icon: Icons.emergency_rounded,
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterView(
                              initialRole: UserRole.driver)));
                },
              ),*/
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegistrationOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey[300]),
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
          borderRadius: BorderRadius.circular(20),
          border:
              isApple ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: isApple
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.05),
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
                : Image.asset(icon,
                    height: 22,
                    errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata,
                        size: 24, color: Colors.red)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isApple ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
