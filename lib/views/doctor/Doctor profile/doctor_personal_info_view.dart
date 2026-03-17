import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_personal_info_viewmodel.dart';
import 'package:medlink/widgets/shimmer_widgets.dart';

class DoctorPersonalInfoView extends StatelessWidget {
  const DoctorPersonalInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DoctorPersonalInfoViewModel(
        Provider.of<UserViewModel>(context, listen: false),
      ),
      child: Consumer<DoctorPersonalInfoViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: const CustomAppBar(title: "Personal Information"),
            body: viewModel.isLoading
                ? const PersonalInfoShimmer()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: () => viewModel.pickImage(),
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    image: (viewModel.imageFile != null ||
                                            (viewModel.profileImage != null &&
                                                viewModel
                                                    .profileImage!.isNotEmpty))
                                        ? DecorationImage(
                                            image: viewModel.imageFile != null
                                                ? FileImage(
                                                        viewModel.imageFile!)
                                                    as ImageProvider
                                                : (viewModel.profileImage!
                                                        .startsWith('http')
                                                    ? NetworkImage(
                                                        viewModel.profileImage!)
                                                    : FileImage(File(viewModel
                                                            .profileImage!))
                                                        as ImageProvider),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: (viewModel.imageFile == null &&
                                          (viewModel.profileImage == null ||
                                              viewModel.profileImage!.isEmpty))
                                      ? const Icon(Icons.person,
                                          size: 50, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => viewModel.pickImage(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildModernTextField("Full Name",
                            viewModel.nameController, Icons.person_rounded),
                        const SizedBox(height: 16),
                        _buildModernTextField("Email Address",
                            viewModel.emailController, Icons.email_rounded,
                            readOnly: true),
                        const SizedBox(height: 16),
                        _buildModernTextField("Phone Number",
                            viewModel.phoneController, Icons.phone_rounded),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                            "Specialization",
                            viewModel.specializationController,
                            Icons.medical_services_rounded),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                            "Experience (Years)",
                            viewModel.experienceController,
                            Icons.timeline_rounded,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                            "Clinic Name",
                            viewModel.clinicNameController,
                            Icons.business_rounded),
                        const SizedBox(height: 16),
                        _buildModernTextField(
                            "Clinic Address",
                            viewModel.clinicAddressController,
                            Icons.location_on_rounded),
                        const SizedBox(height: 16),
                        _buildModernTextField("About Me",
                            viewModel.bioController, Icons.info_rounded,
                            maxLines: 3),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ]),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "Save Changes",
                    fontWeight: FontWeight.w500,
                    onPressed: () => viewModel.saveChanges(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTextField(
      String label, TextEditingController controller, IconData icon,
      {bool readOnly = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
              hintText: "Enter $label",
              hintStyle: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
              ),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
