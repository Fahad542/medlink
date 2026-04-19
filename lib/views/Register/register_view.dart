import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Register/register_viewmodel.dart';
import 'package:medlink/widgets/email_verfication_bottom_sheet.dart';
import 'package:medlink/widgets/registration.dart';
import 'package:medlink/widgets/verfiy_opt.dart';
import 'package:medlink/widgets/complete_profile.dart';

// Patient steps
import 'package:medlink/views/Patient%20App/auth/patient_info.dart';
import 'package:medlink/widgets/emergency_contact.dart';
import 'package:medlink/widgets/Setting_up_account.dart';
import 'package:medlink/views/main/main_screen.dart';

// Doctor steps
import 'package:medlink/views/doctor/auth/steps/doctor_step4_professional.dart';
import 'package:medlink/views/doctor/auth/steps/doctor_step5_practice_details.dart';
import 'package:medlink/views/doctor/auth/steps/doctor_step7_setup.dart';
import 'package:medlink/views/doctor/doctor_main_screen.dart';

// Driver steps
import 'package:medlink/views/Ambulance/auth/steps/driver_step4_vehicle.dart';
import 'package:medlink/views/Ambulance/auth/steps/driver_step5_avatar.dart';
import 'package:medlink/views/Ambulance/auth/steps/driver_step6_setup.dart';
import 'package:medlink/views/Ambulance/Ambulance%20main/ambulance_main_view.dart';

class RegisterView extends StatefulWidget {
  final UserRole initialRole;

  const RegisterView({super.key, required this.initialRole});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<RegisterViewModel>(context, listen: false);
      authVM.initRole(widget.initialRole);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterViewModel>(
      builder: (context, authViewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: authViewModel.currentStep == authViewModel.totalSteps - 1
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () => authViewModel.previousStep(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: Colors.black87),
                      ),
                    ),
                  ),
                  title: Text(
                    _getAppBarTitle(authViewModel.role),
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                ),
          body: SafeArea(
            child: Column(
              children: [
                // Progress Bar
                if (authViewModel.currentStep < authViewModel.totalSteps - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 6,
                          width: MediaQuery.of(context).size.width *
                                  ((authViewModel.currentStep + 1) /
                                      (authViewModel.totalSteps - 1)) -
                              48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF26D0CE)],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: PageView(
                    controller: authViewModel.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _getStepsForRole(authViewModel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getAppBarTitle(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return "Patient Registration";
      case UserRole.doctor:
        return "Doctor Registration";
      case UserRole.driver:
        return "Driver Registration";
    }
  }

  List<Widget> _getStepsForRole(RegisterViewModel authViewModel) {
    final commonStep1 = Step1Credentials(
      nameController: authViewModel.nameController,
      phoneController: authViewModel.phoneController,
      passwordController: authViewModel.passwordController,
      confirmPasswordController: authViewModel.confirmPasswordController,
      isLoading: authViewModel.loading,
      onNext: () => authViewModel.submitStep1(context),
    );

    final commonStep2 = Step3Otp(
      phoneNumber: authViewModel.phoneController.text,
      debugOtp: authViewModel.debugOtp, // Add this line
      isLoading: authViewModel.loading,
      isResendLoading: authViewModel.resendLoading,
      onNext: (otp) async {
        bool otpSuccess = await authViewModel.submitStep2Otp(otp, context);

        if (otpSuccess) {
          if (mounted) {
            bool? emailVerified = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return Consumer<RegisterViewModel>(
                    builder: (context, model, _) {
                  return EmailVerificationSheet(
                    emailController: model.emailController,
                    isLoading: model.emailLoading,
                    debugOtp: model.emailDebugOtp,
                    onRequestOtp: (email) =>
                        model.requestEmailOtp(email, context),
                    onVerifyOtp: (email, otp) =>
                        model.submitEmailOtp(email, otp, context),
                  );
                });
              },
            );

            // Navigate to next regardless of email verification status (following UI behavior)
            authViewModel.nextStep();
          }
        }
      },
      onResend: () => authViewModel.resendOtp(context),
    );

    switch (authViewModel.role) {
      case UserRole.patient:
        return [
          commonStep1,
          commonStep2,
          const Step4Info(),
          const Step5Emergency(),
          Step6Avatar(
            onNext: () async {
              if (authViewModel.profileImagePath != null) {
                File file = File(authViewModel.profileImagePath!);
                bool success =
                    await authViewModel.registerStep3({}, context, file);
                if (success) authViewModel.nextStep();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select an image")));
              }
            },
            onSkip: () async {
              bool success =
                  await authViewModel.registerStep3({}, context, null);
              if (success) authViewModel.nextStep();
            },
            onImageSelected: (path) => authViewModel.setProfileImage(path),
            isLoading: authViewModel.loading,
          ),
          Step7Setup(
            onComplete: () {
              authViewModel.finishPatientSetup(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
          ),
        ];

      case UserRole.doctor:
        return [
          commonStep1,
          commonStep2,
          DoctorStep4Professional(
            isLoading: authViewModel.loading,
            onNext: () => authViewModel.submitDoctorStep4(context),
            specializationController: authViewModel.specializationController,
            experienceController: authViewModel.experienceController,
            clinicNameController: authViewModel.clinicNameController,
            clinicAddressController: authViewModel.clinicAddressController,
            aboutController: authViewModel.aboutController,
            onLicenseSelected: (path) => authViewModel.setLicensePath(path),
          ),
          DoctorStep5PracticeDetails(
            isLoading: authViewModel.loading,
            onNext: () => authViewModel.submitDoctorStep5(context),
            consultationFeeController: authViewModel.consultationFeeController,
            minimumConsultationFee:
                authViewModel.minimumDoctorConsultationFee,
            onAvailabilitySelected: (days) =>
                authViewModel.setAvailability(days),
            onTimeSelected: (start, end) => authViewModel.setTimes(start, end),
          ),
          Step6Avatar(
            isLoading: authViewModel.loading,
            onNext: () async {
              if (authViewModel.profileImagePath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile image required")));
                return;
              }
              if (authViewModel.licensePath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("License document required")));
                return;
              }
              final success = await authViewModel.doctorRegisterStep3(context);
              if (success && context.mounted) authViewModel.nextStep();
            },
            onSkip: () => authViewModel.nextStep(),
            onImageSelected: (path) => authViewModel.setProfileImage(path),
          ),
          DoctorStep7Setup(
            onFinished: () {
              authViewModel.finishDoctorSetup(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DoctorMainScreen()),
                (route) => false,
              );
            },
          ),
        ];

      case UserRole.driver:
        return [
          commonStep1,
          commonStep2,
          DriverStep4Vehicle(
            isLoading: authViewModel.loading,
            onNext: () async {
              if (authViewModel.driverLicensePath != null) {
                authViewModel.nextStep();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Driver License file required")));
              }
            },
            carNumberController: authViewModel.carNumberController,
            carNameController: authViewModel.carNameController,
            onLicenseSelected: (path) =>
                authViewModel.setDriverLicensePath(path),
          ),
          DriverStep5Avatar(
            isLoading: authViewModel.loading,
            onNext: () async {
              if (authViewModel.profileImagePath != null) {
                authViewModel.nextStep();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile image required")));
              }
            },
            onSkip: () => authViewModel.nextStep(),
            onImageSelected: (path) => authViewModel.setProfileImage(path),
          ),
          DriverStep6Setup(
            onFinished: () async {
              await authViewModel.finishDriverSetup(context);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AmbulanceMainView()),
                  (route) => false,
                );
              }
            },
          ),
        ];
    }
  }
}
