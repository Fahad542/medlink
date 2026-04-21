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
import 'dart:async';
import 'package:medlink/services/google_maps_service.dart';

class DoctorStep4Professional extends StatefulWidget {
  final VoidCallback onNext;
  final TextEditingController phoneController;
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
    required this.phoneController,
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
  List<dynamic> _suggestions = [];
  Timer? _debounce;

  final FocusNode _categoryFocusNode = FocusNode();
  final GlobalKey<FormFieldState<String>> _specialtyFormFieldKey =
      GlobalKey<FormFieldState<String>>();
  List<Map<String, dynamic>> _filteredCategories = [];
  String? _appliedCategoryName;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _categoryFocusNode.addListener(_onCategoryFocusChange);
  }

  void _onCategoryFocusChange() {
    if (_categoryFocusNode.hasFocus) {
      _openCategoryList();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_categoryFocusNode.hasFocus) {
          setState(() => _filteredCategories = []);
        }
      });
    }
  }

  /// Always show the full API category list (no text filter).
  void _openCategoryList() {
    if (_categories.isEmpty) return;
    setState(() {
      _filteredCategories = List<Map<String, dynamic>>.from(_categories);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _categoryFocusNode.removeListener(_onCategoryFocusChange);
    _categoryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiServices().getDoctorCategories();
      if (response != null && response['success'] == true) {
        final raw = response['data'];
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          final inner = raw['categories'] ?? raw['items'] ?? raw['specialties'];
          if (inner is List) list = inner;
        }
        setState(() {
          _categories = list.whereType<Map<String, dynamic>>().toList();
          _isLoadingCategories = false;
          if (_categoryFocusNode.hasFocus) {
            _filteredCategories =
                List<Map<String, dynamic>>.from(_categories);
          }
        });
      } else {
        setState(() => _isLoadingCategories = false);
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() => _isLoadingCategories = false);
    }
  }

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length > 2) {
        final suggestions = await GoogleMapsService.searchPlaces(query);
        setState(() {
          _suggestions = suggestions;
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
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
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (context, setLocal) {
                final needPhone =
                    widget.phoneController.text.trim().length < 10;
                if (!needPhone) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Phone number",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
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
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: widget.phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setLocal(() {}),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter your phone number",
                          hintStyle: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.phone_android_rounded,
                                  color: AppColors.primary, size: 18),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
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
                : FormField<String>(
                    key: _specialtyFormFieldKey,
                    validator: (_) {
                      final auth = Provider.of<RegisterViewModel>(context,
                          listen: false);
                      final id = auth.selectedSpecialtyId;
                      if (id == null || id.isEmpty) return "Required";
                      return null;
                    },
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Specialization",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: widget.specializationController,
                              focusNode: _categoryFocusNode,
                              onTap: _openCategoryList,
                              onChanged: (v) {
                                final authVM =
                                    Provider.of<RegisterViewModel>(context,
                                        listen: false);
                                if (_appliedCategoryName != null &&
                                    v.trim() != _appliedCategoryName) {
                                  authVM.setSelectedSpecialtyId(null);
                                  _appliedCategoryName = null;
                                }
                                if (_categoryFocusNode.hasFocus) {
                                  _openCategoryList();
                                }
                                field.didChange(
                                    authVM.selectedSpecialtyId ?? '');
                              },
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: "Tap to see all specializations",
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.local_hospital_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                suffixIcon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey[600],
                                ),
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
                                    vertical: 18, horizontal: 20),
                              ),
                            ),
                          ),
                          if (_filteredCategories.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height *
                                        0.32,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: _filteredCategories.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey[100],
                                  ),
                                  itemBuilder: (context, index) {
                                    final cat = _filteredCategories[index];
                                    final name =
                                        cat['name']?.toString() ?? "General";
                                    final id = cat['id']?.toString() ?? "";
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.local_hospital_outlined,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      onTap: () {
                                        final authVM = Provider.of<
                                                RegisterViewModel>(
                                            context,
                                            listen: false);
                                        widget.specializationController
                                            .text = name;
                                        _appliedCategoryName = name;
                                        authVM.setSelectedSpecialtyId(id);
                                        field.didChange(id);
                                        setState(() =>
                                            _filteredCategories.clear());
                                        FocusScope.of(context).unfocus();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          if (field.hasError)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 14,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    field.errorText ?? "",
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
              onChanged: (text) {
                _onAddressChanged(text);
              },
            ),

            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                      title: Text(
                        suggestion['description'],
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                      ),
                      onTap: () {
                        setState(() {
                          widget.clinicAddressController.text = suggestion['description'];
                          _suggestions = [];
                        });
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                ),
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
    void Function(String)? onChanged,
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
                  if (onChanged != null) onChanged(text);
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
