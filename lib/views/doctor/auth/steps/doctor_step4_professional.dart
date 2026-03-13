import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:provider/provider.dart';
import 'package:medlink/widgets/shimmer_widgets.dart';
import 'package:medlink/views/Register/register_viewmodel.dart';

class DoctorStep4Professional extends StatefulWidget {
  final VoidCallback onNext;
  final TextEditingController specializationController;
  final TextEditingController experienceController;
  final TextEditingController clinicNameController;
  final TextEditingController clinicAddressController;
  final TextEditingController aboutController;
  final Function(String) onLicenseSelected;
  final bool isLoading;

  const DoctorStep4Professional({
    super.key,
    required this.onNext,
    required this.specializationController,
    required this.experienceController,
    required this.clinicNameController,
    required this.clinicAddressController,
    required this.aboutController,
    required this.onLicenseSelected,
    this.isLoading = false,
  });

  @override
  State<DoctorStep4Professional> createState() => _DoctorStep4ProfessionalState();
}

class _DoctorStep4ProfessionalState extends State<DoctorStep4Professional> {
  final _formKey = GlobalKey<FormState>();
  String? _licenseFileName;
  String? _licenseError;
  File? _licenseFile;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiServices().getDoctorCategories();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _categories = data.whereType<Map<String, dynamic>>().toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      // Allow picking image from gallery for license
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
              "Professional Info",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tell us about your medical expertise.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildAnimatedTextField(
              label: "About Me",
              hint: "Write a brief bio about your professional background",
              icon: Icons.info_outline_rounded,
              controller: widget.aboutController,
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            _isLoadingCategories
                ? const DropdownShimmer()
                : Consumer<RegisterViewModel>(
                    builder: (context, authVM, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _categories.any((c) => c['id']?.toString() == authVM.selectedSpecialtyId) 
                              ? authVM.selectedSpecialtyId 
                              : null,
                          items: _categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat['id']?.toString(),
                              child: Text(
                                cat['name']?.toString() ?? "General",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              final selectedCat = _categories.firstWhere((c) => c['id']?.toString() == newValue);
                              widget.specializationController.text = selectedCat['name']?.toString() ?? "";
                              authVM.setSelectedSpecialtyId(newValue);
                            }
                          },
                          validator: (v) => v == null || v.isEmpty ? "Required" : null,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Select your specialization",
                            hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.w400, fontSize: 13),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 18),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 24),

            _buildAnimatedTextField(
              label: "Experience (Years)",
              hint: "Enter years of experience",
              icon: Icons.history_edu_rounded,
              controller: widget.experienceController,
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 24),

            _buildAnimatedTextField(
              label: "Clinic Name",
              hint: "Enter your clinic or hospital name",
              icon: Icons.business_rounded,
              controller: widget.clinicNameController,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 24),

            _buildAnimatedTextField(
              label: "Clinic Address",
              hint: "Enter full clinic address",
              icon: Icons.location_on_rounded,
              controller: widget.clinicAddressController,
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 24),



            _buildFileUploadField(
              label: "Medical License",
              fileName: _licenseFileName,
              onTap: () => _pickFile(),
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
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: null,
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                    fileName ?? "Tap to upload",
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
    int maxLines = 1,
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
                controller: controller, // Use TextField instead of wrapping in Container Row
                keyboardType: keyboardType,
                maxLines: maxLines,
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
                    padding: maxLines > 1 ? const EdgeInsets.only(bottom: 80, left: 12, right: 12, top: 12) : const EdgeInsets.all(12),
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
              ),
          ],
        );
      },
    );
  }
}
