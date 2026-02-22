import 'package:flutter/material.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class DriverStep5Avatar extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Function(String) onImageSelected;
  final bool isLoading;

  const DriverStep5Avatar({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.onImageSelected,
    this.isLoading = false,
  });

  @override
  State<DriverStep5Avatar> createState() => _DriverStep5AvatarState();
}

class _DriverStep5AvatarState extends State<DriverStep5Avatar> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        widget.onImageSelected(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Profile Photo",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Add a professional photo.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),

          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 130, // Regular Size
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _imageFile != null
                      ? ClipOval(child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : Icon(Icons.person_rounded, size: 64, color: Colors.grey[300]),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 56),

            CustomButton(
              text: "Complete Setup",
              isLoading: widget.isLoading,
              onPressed: () {
                // Allow skipping or require it
                widget.onNext();
              },
            ),
          const SizedBox(height: 16),
           TextButton(
              onPressed: widget.onSkip,
               style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: Text(
                "Skip for now",
                style: GoogleFonts.inter(fontWeight: FontWeight.w400),
              ),
            ),
        ],
      ),
    );
  }
}
