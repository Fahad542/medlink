import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class AmbulanceEditProfileView extends StatefulWidget {
  const AmbulanceEditProfileView({super.key});

  @override
  State<AmbulanceEditProfileView> createState() => _AmbulanceEditProfileViewState();
}

class _AmbulanceEditProfileViewState extends State<AmbulanceEditProfileView> {
  // Controllers
  final _nameController = TextEditingController(text: "John Doe");
  final _phoneController = TextEditingController(text: "+1 234 567 8900");
  final _emailController = TextEditingController(text: "john.driver@medlink.com");
  final _vehicleNumberController = TextEditingController(text: "KYC 1234");
  final _vehicleModelController = TextEditingController(text: "Toyota HiAce Ambulance");
  final _licenseNumberController = TextEditingController(text: "DL-987654321");

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: "Edit Profile"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Image Edit
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/300?u=driver'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields

            _buildTextField("Full Name", _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField("Phone Number", _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
             const SizedBox(height: 16),
            _buildTextField("Email", _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),

            const SizedBox(height: 32),
            _buildTextField("Vehicle Number", _vehicleNumberController, Icons.directions_car_outlined),
             const SizedBox(height: 16),
            _buildTextField("Vehicle Model", _vehicleModelController, Icons.local_shipping_outlined),
             const SizedBox(height: 16),
            _buildTextField("License Number", _licenseNumberController, Icons.badge_outlined),


            const SizedBox(height: 40),
            CustomButton(
              text: "Save Changes",
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated successfully!")),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Enter $label",
              hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontWeight: FontWeight.w500, fontSize: 14),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
