import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';

class DriverStep4Vehicle extends StatefulWidget {
  final VoidCallback onNext;
  final TextEditingController carNumberController;
  final TextEditingController carNameController; // Added
  final Function(String) onLicenseSelected;
  final bool isLoading;

  const DriverStep4Vehicle({
    super.key,
    required this.onNext,
    required this.carNumberController,
    required this.carNameController, // Added
    required this.onLicenseSelected,
    this.isLoading = false,
  });

  @override
  State<DriverStep4Vehicle> createState() => _DriverStep4VehicleState();
}

class _DriverStep4VehicleState extends State<DriverStep4Vehicle> {
  final _formKey = GlobalKey<FormState>();
  String? _licenseFileName;
  String? _licenseError;
  File? _licenseFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile() async {
     try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _licenseFile = File(pickedFile.path);
          _licenseFileName = pickedFile.name;
          _licenseError = null;
          widget.onLicenseSelected(pickedFile.path);
        });
      }
    } catch (e) {
       setState(() {
         _licenseError = "Failed to pick file";
      });
    }
  }

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
              "Vehicle Info",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Provide details about your vehicle and license.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildAnimatedTextField(
              label: "Car Name",
              hint: "Enter car model",
              icon: Icons.directions_car_filled_rounded,
              controller: widget.carNameController,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            
            const SizedBox(height: 16),

            _buildAnimatedTextField(
              label: "Car Number",
              hint: "Enter car number",
              icon: Icons.confirmation_number_rounded, 
              controller: widget.carNumberController,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 24),

            _buildFileUploadField(
              label: "Driver License",
              fileName: _licenseFileName,
              onTap: _pickFile,
              errorText: _licenseError,
            ),

            const SizedBox(height: 40),
            CustomButton(
              text: "Next Step",
              isLoading: widget.isLoading,
              onPressed: () {
                 bool formValid = _formKey.currentState!.validate();
                bool fileValid = true;

                setState(() {
                  if (_licenseFileName == null) {
                    _licenseError = "License Required";
                    fileValid = false;
                  } else {
                    _licenseError = null;
                  }
                });

                if (formValid && fileValid) {
                  widget.onNext();
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadField({
    required String label,
    required String? fileName,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), // Golden Rule
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fileName ?? "Tap to upload license",
                    style: GoogleFonts.inter(
                      fontSize: fileName != null ? 15 : 13,
                      fontWeight: FontWeight.w400, // Reduced from w500
                      color: fileName != null ? Colors.black87 : Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (fileName != null)
                   const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              ],
            ),
          ),
        ),
        if (errorText != null)
           Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  errorText,
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

  Widget _buildAnimatedTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
                    color: Colors.black.withOpacity(0.04), // Golden Rule
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: null,
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
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
              ),
          ],
        );
      },
    );
  }
}
