// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:medlink/core/constants/app_colors.dart';
// import 'package:medlink/views/Login/login_view.dart';
// import 'package:medlink/views/doctor/auth/verification_pending_view.dart';
// import 'package:medlink/widgets/custom_button.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:medlink/viewmodels/Doctor/doctor_registration_view_model.dart';
//
// // class DoctorRegistrationView extends StatefulWidget {
// //   const DoctorRegistrationView({super.key});
// //
// //   @override
// //   State<DoctorRegistrationView> createState() => _DoctorRegistrationViewState();
// // }
//
//
// // ... other imports ...
//
// class DoctorRegistrationView extends StatefulWidget {
//   const DoctorRegistrationView({super.key});
//
//   @override
//   State<DoctorRegistrationView> createState() => _DoctorRegistrationViewState();
// }
//
// class _DoctorRegistrationViewState extends State<DoctorRegistrationView> {
//   final _formKey = GlobalKey<FormState>();
//   final _licenseController = TextEditingController();
//   final _specialtyController = TextEditingController();
//   final _experienceController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     // Set status bar to dark icons
//     SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
//
//     return ChangeNotifierProvider(
//       create: (_) => DoctorRegistrationViewModel(),
//       child: Consumer<DoctorRegistrationViewModel>(
//         builder: (context, viewModel, child) {
//           return Scaffold(
//             backgroundColor: Colors.white,
//             appBar: AppBar(
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               leading: IconButton(
//                 icon: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             body: SafeArea(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 24),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Center(
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary.withOpacity(0.1),
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(Icons.medical_services_rounded, size: 40, color: AppColors.primary),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//
//                       Center(
//                         child: Text(
//                           "Doctor Registration",
//                           textAlign: TextAlign.center,
//                           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Center(
//                         child: Text(
//                           "Complete your profile to start practicing",
//                           textAlign: TextAlign.center,
//                           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                                 color: Colors.grey[500],
//                               ),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//
//                       const SizedBox(height: 24),
//
//                       _buildTextField(
//                         controller: viewModel.nameController,
//                         label: "Full Name",
//                         hint: "Dr. John Doe",
//                         icon: Icons.person_outline,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildTextField(
//                         controller: viewModel.emailController,
//                         label: "Email Address",
//                         hint: "doctor@example.com",
//                         icon: Icons.email_outlined,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildTextField(
//                         controller: viewModel.phoneController,
//                         label: "Phone Number",
//                         hint: "Enter phone number",
//                         icon: Icons.phone_outlined,
//                         keyboardType: TextInputType.phone,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildTextField(
//                         controller: _specialtyController,
//                         label: "Specialization",
//                         hint: "e.g. Cardiologist, Dermatologist",
//                         icon: Icons.medical_services_outlined,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildTextField(
//                         controller: _experienceController,
//                         label: "Years of Experience",
//                         hint: "e.g. 5",
//                         icon: Icons.work_history_outlined,
//                         keyboardType: TextInputType.number,
//                       ),
//
//                       const SizedBox(height: 16),
//                       _buildTextField(
//                         controller: _licenseController,
//                         label: "Medical License Number",
//                         hint: "Enter your license number",
//                         icon: Icons.badge_outlined,
//                       ),
//                       const SizedBox(height: 16),
//                        _buildTextField(
//                         controller: viewModel.passwordController,
//                         label: "Password",
//                         hint: "Enter your password",
//                         icon: Icons.lock_outline,
//                         isPassword: true,
//                         isObscure: true, // Simplified for now
//                       ),
//                       const SizedBox(height: 16),
//                        _buildTextField(
//                         controller: viewModel.confirmPasswordController,
//                         label: "Confirm Password",
//                         hint: "Re-enter your password",
//                         icon: Icons.lock_outline,
//                         isPassword: true,
//                         isObscure: true,
//                       ),
//
//                       const SizedBox(height: 24),
//
//                       _buildFileUpload(
//                         label: "Upload Medical License",
//                         fileName: viewModel.selectedLicenseFile,
//                         onTap: viewModel.pickLicenseFile,
//                       ),
//                       const SizedBox(height: 16),
//                       _buildFileUpload(
//                         label: "Upload Government ID",
//                         fileName: viewModel.selectedIdFile,
//                         onTap: viewModel.pickIdFile,
//                       ),
//
//                       const SizedBox(height: 16),
//
//
//                       const SizedBox(height: 48),
//                       CustomButton(
//                         text: "Submit for Verification",
//                         onPressed: () {
//                           if (_formKey.currentState!.validate()) {
//                             viewModel.submitRegistration(
//                               specialty: _specialtyController.text,
//                               experience: _experienceController.text,
//                               licenseNumber: _licenseController.text,
//                               onSuccess: () {
//                                 Navigator.pushReplacement(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => const VerificationPendingView(),
//                                   ),
//                                 );
//                               },
//                               onError: (message) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(content: Text(message)),
//                                 );
//                               },
//                             );
//                           }
//
//                         },
//                       ),
//                       const SizedBox(height: 24),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text("Already have an account? ", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w400)),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => const LoginView(initialRole: 'doctor'),
//                                 ),
//                               );
//                             },
//                             child:  Text(
//                               "Login",
//                               style: GoogleFonts.inter(
//                                 color: AppColors.primary,
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     TextInputType? keyboardType,
//     bool isPassword = false,
//     bool isObscure = false,
//     VoidCallback? onVisibilityToggle,
//   }) {
//     return FormField<String>(
//       initialValue: controller.text,
//       validator: (value) {
//         if (controller.text.isEmpty) return "Required"; // Use controller directly to be safe
//         return null;
//       },
//       builder: (FormFieldState<String> state) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.08),
//                     blurRadius: 24,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//                 border: state.hasError
//                     ? Border.all(color: Colors.red.shade100, width: 1)
//                     : null,
//               ),
//               child: TextField(
//                 controller: controller,
//                 keyboardType: keyboardType,
//                 obscureText: isObscure,
//                 style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
//                 cursorColor: AppColors.primary,
//                 onChanged: (text) {
//                   state.didChange(text);
//                 },
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: Colors.white,
//                   hintText: hint.isNotEmpty ? hint : label,
//                   hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.w400, fontSize: 13),
//                   prefixIcon: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 22),
//                   ),
//                   prefixIconConstraints: const BoxConstraints(minWidth: 48),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//                 ),
//               ),
//             ),
//             if (state.hasError)
//               Padding(
//                 padding: const EdgeInsets.only(left: 16, top: 6),
//                 child: Text(
//                   state.errorText ?? "",
//                   style: TextStyle(
//                     color: Colors.red[400],
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildFileUpload({
//     required String label,
//     required String? fileName,
//     required VoidCallback onTap,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[700],
//           ),
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//             decoration: BoxDecoration(
//               color: fileName != null ? AppColors.primary.withOpacity(0.05) : const Color(0xFFF5F7FA),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: fileName != null ? AppColors.primary : Colors.grey[300]!,
//                 style: BorderStyle.solid,
//                 width: 1,
//               ),
//             ),
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: fileName != null ? AppColors.primary.withOpacity(0.1) : Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     fileName != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
//                     size: 28,
//                     color: fileName != null ? AppColors.primary : Colors.grey[400],
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Text(
//                   fileName ?? "Tap to upload document",
//                   style: TextStyle(
//                     color: fileName != null ? AppColors.primary : Colors.grey[600],
//                     fontWeight: fileName != null ? FontWeight.w600 : FontWeight.w500,
//                     fontSize: 14,
//                   ),
//                 ),
//                 if (fileName == null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4.0),
//                     child: Text(
//                       "PDF, JPG, or PNG (Max 5MB)",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[400],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
