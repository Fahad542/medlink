import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:medlink/utils/utils.dart';

class Step6Avatar extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Function(String) onImageSelected;
  final bool isLoading;

  const Step6Avatar({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.onImageSelected,
    this.isLoading = false,
  });

  @override
  State<Step6Avatar> createState() => _Step6AvatarState();
}

class _Step6AvatarState extends State<Step6Avatar> {
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
      Utils.toastError(context, e);
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
                fontSize: 24, // Reduced from 28
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6), // Reduced from 8
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Add a photo so doctors can identify you.",
              style: GoogleFonts.inter(
                fontSize: 14, // Reduced from 16
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48), // Reduced from 60

          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 130, // Reduced from 160
                  height: 130, // Reduced from 160
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
                      : Icon(Icons.person_rounded, size: 64, color: Colors.grey[300]), // Reduced from 80
                ),
                Container(
                  padding: const EdgeInsets.all(10), // Reduced from 12
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18), // Reduced from 20
                ),
              ],
            ),
          ),

          const SizedBox(height: 56), // Reduced from 80

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
            child: const Text(
              "Skip for now",
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
