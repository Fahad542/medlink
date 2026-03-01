import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/services/session_view_model.dart';

class DoctorPersonalInfoView extends StatefulWidget {
  const DoctorPersonalInfoView({super.key});

  @override
  State<DoctorPersonalInfoView> createState() => _DoctorPersonalInfoViewState();
}

class _DoctorPersonalInfoViewState extends State<DoctorPersonalInfoView> {

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _bioController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicAddressController;

  @override
  void initState() {
    super.initState();
    // Use UserViewModel to get the doctor data
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final doctor = userVM.doctor;

    _nameController = TextEditingController(text: doctor?.name ?? "");
    _emailController = TextEditingController(text: "doctor@medlink.com"); // Email not yet in DoctorModel, fallback or keep hardcoded if needed
    _phoneController = TextEditingController(text: "+1 555 000 0000"); // Phone not yet in DoctorModel

    // Real data from DoctorModel
    _specializationController = TextEditingController(text: doctor?.specialty ?? "");
    _experienceController = TextEditingController(text: doctor?.experience ?? "");
    _bioController = TextEditingController(text: doctor?.about ?? "");
    _clinicNameController = TextEditingController(text: doctor?.hospital ?? "");
    _clinicAddressController = TextEditingController(text: doctor?.location ?? "");
  }

  @override
  void dispose() {
    // ... existing dispose ...
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get doctor data for image
     final userVM = Provider.of<UserViewModel>(context);
     final doctor = userVM.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), 
      appBar: const CustomAppBar(title: "Personal Information"),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20), 
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90, 
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      image: DecorationImage(
                        image: (doctor?.imageUrl != null && doctor!.imageUrl.isNotEmpty)
                          ? (doctor!.imageUrl.startsWith('http') 
                              ? NetworkImage(doctor.imageUrl) 
                              : FileImage(File(doctor.imageUrl)) as ImageProvider)
                          : const NetworkImage("https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&auto=format&fit=crop&q=60"),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildModernTextField("Full Name", _nameController, Icons.person_rounded),
            const SizedBox(height: 12),
            _buildModernTextField("Email Address", _emailController, Icons.email_rounded, readOnly: true),
            const SizedBox(height: 12),
            _buildModernTextField("Phone Number", _phoneController, Icons.phone_rounded),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildModernTextField("Specialization", _specializationController, Icons.medical_services_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildModernTextField("Experience", _experienceController, Icons.work_history_rounded)),
              ],
            ),
            const SizedBox(height: 12),

            _buildModernTextField("Clinic Name", _clinicNameController, Icons.business_rounded),
            const SizedBox(height: 12),
            _buildModernTextField("Clinic Address", _clinicAddressController, Icons.location_on_rounded, maxLines: 2),
            const SizedBox(height: 12),
            
            _buildModernTextField("About Me", _bioController, Icons.info_outline_rounded, maxLines: 4),

            const SizedBox(height: 40), // Reduced spacing as button is in bottom nav
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: CustomButton(
            text: "Save Changes", 
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(String label, TextEditingController controller, IconData icon, {bool readOnly = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 12, // Reduced from 13
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14), // Reduced from 16
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10), // Reduced from 12
          child: Row(
            crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                width: 30, // Reduced from 34
                height: 30, // Reduced from 34
                padding: const EdgeInsets.all(6), // Reduced from 8
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10), // Reduced from 12
                ),
                child: Icon(icon, color: AppColors.primary, size: 16), // Reduced from 18
              ),
              const SizedBox(width: 10), // Reduced from 12
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  maxLines: maxLines,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14), // Reduced from 15 and w600 -> w500
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6), // Reduced from 8
                    filled: true,
                    fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
                    hintText: "Enter $label",
                    hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.w500, fontSize: 13), // Reduced from 14
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
