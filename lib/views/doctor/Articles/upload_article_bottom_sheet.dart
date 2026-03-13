import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/views/Patient%20App/health/health_hub_viewmodel.dart';
import 'package:provider/provider.dart';

class UploadArticleBottomSheet extends StatefulWidget {
  const UploadArticleBottomSheet({super.key});

  @override
  State<UploadArticleBottomSheet> createState() => _UploadArticleBottomSheetState();
}

class _UploadArticleBottomSheetState extends State<UploadArticleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _contentController = TextEditingController();
  File? _image;
  final _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      Utils.toastMessage(context, "Please select a cover image", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = Provider.of<HealthHubViewModel>(context, listen: false);
    final success = await viewModel.uploadArticle(
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      contentHtml: _contentController.text.trim(),
      isPublished: true,
      imagePath: _image?.path,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.pop(context);
        Utils.toastMessage(context, "Article uploaded successfully!");
      }
    } else {
      if (mounted) {
        Utils.toastMessage(context, "Failed to upload article", isError: true);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 20),
              Text(
                "Upload New Article",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: Colors.grey[400], size: 40),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to select cover image",
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Title Field
              _buildTextField(
                controller: _titleController,
                label: "Title",
                hint: "Enter article title",
                icon: Icons.title_rounded,
                validator: (v) => v!.isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 16),

              // Category Field
              _buildTextField(
                controller: _categoryController,
                label: "Category",
                hint: "e.g. Health, Nutrition, Fitness",
                icon: Icons.category_rounded,
                validator: (v) => v!.isEmpty ? "Category is required" : null,
              ),
              const SizedBox(height: 16),

              // Content Field
              _buildTextField(
                controller: _contentController,
                label: "Content",
                hint: "Write your article content here...",
                icon: Icons.description_rounded,
                maxLines: 6,
                validator: (v) => v!.isEmpty ? "Content is required" : null,
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Text(
                          "Publish Article",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
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
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: AppColors.primary, size: 18),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLines: maxLines,
                          keyboardType: keyboardType,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                              color: Colors.black87),
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.transparent,
                            hintText: hint,
                            hintStyle: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                                fontSize: 13),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                          ),
                          onChanged: (text) => state.didChange(text),
                        ),
                      ),
                    ],
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
        ),
      ],
    );
  }
}
