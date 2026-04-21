import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/utils/utils.dart';

class AmbulanceEditProfileView extends StatefulWidget {
  /// Initial values from driver profile (passed from profile screen).
  final String? initialFullName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialProfilePhoto;
  final String? initialVehiclePlate;
  final String? initialVehicleType;
  final String? initialLicenseNo;

  const AmbulanceEditProfileView({
    super.key,
    this.initialFullName,
    this.initialEmail,
    this.initialPhone,
    this.initialProfilePhoto,
    this.initialVehiclePlate,
    this.initialVehicleType,
    this.initialLicenseNo,
  });

  @override
  State<AmbulanceEditProfileView> createState() =>
      _AmbulanceEditProfileViewState();
}

class _AmbulanceEditProfileViewState extends State<AmbulanceEditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _vehicleModelController;
  late final TextEditingController _licenseNumberController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFullName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _vehicleNumberController =
        TextEditingController(text: widget.initialVehiclePlate ?? '');
    _vehicleModelController =
        TextEditingController(text: widget.initialVehicleType ?? '');
    _licenseNumberController =
        TextEditingController(text: widget.initialLicenseNo ?? '');
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

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

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: "Edit Profile"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Image Edit
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
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
                              color: Colors.grey[200],
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover)
                                  : (widget.initialProfilePhoto != null &&
                                          widget.initialProfilePhoto!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(AppUrl.getFullUrl(
                                              widget.initialProfilePhoto)),
                                          fit: BoxFit.cover,
                                        )
                                      : null),
                            ),
                            child: _selectedImage == null &&
                                    (widget.initialProfilePhoto == null ||
                                        widget.initialProfilePhoto!.isEmpty)
                                ? const Icon(Icons.person,
                                    color: Colors.grey, size: 50)
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields

                  _buildTextField(
                      "Full Name", _nameController, Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(
                      "Phone Number", _phoneController, Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(
                      "Email", _emailController, Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),

                  const SizedBox(height: 32),
                  _buildTextField("Vehicle Number", _vehicleNumberController,
                      Icons.directions_car_outlined),
                  const SizedBox(height: 16),
                  _buildTextField("Vehicle Model", _vehicleModelController,
                      Icons.local_shipping_outlined),
                  const SizedBox(height: 16),
                  _buildTextField("License Number", _licenseNumberController,
                      Icons.badge_outlined),

                  const SizedBox(height: 40),
                  CustomButton(
                    text: "Save Changes",
                    onPressed: _updateProfile,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiServices = ApiServices();
      await apiServices.updateDriverProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        vehiclePlate: _vehicleNumberController.text.trim(),
        vehicleType: _vehicleModelController.text.trim(),
        licenseNo: _licenseNumberController.text.trim(),
        profilePhoto: _selectedImage,
      );

      if (mounted) {
        Utils.toastMessage(context, "Profile updated successfully!");
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        Utils.toastError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType}) {
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
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Enter $label",
              hintStyle: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w400,
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
