import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/Register/register_viewmodel.dart';
import 'package:provider/provider.dart';

class Step4Info extends StatelessWidget {
  const Step4Info({super.key});

  Future<void> _selectDate(BuildContext context, RegisterViewModel authVM) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      authVM.setDob(picked);
      authVM.dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      final age = DateTime.now().year - picked.year;
      authVM.ageController.text = age.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: We use Consumer or Provider.of in build. Consumer is fine here.
    return Consumer<RegisterViewModel>(
      builder: (context, authVM, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                "About You",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tell us a bit more about yourself.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "Gender",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildGenderCard("Male", authVM),
                  const SizedBox(width: 16),
                  _buildGenderCard("Female", authVM),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                "Date of Birth",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context, authVM),
                child: Container(
                  padding: const EdgeInsets.all(10),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        authVM.selectedDob != null
                            ? "${authVM.selectedDob!.day} / ${authVM.selectedDob!.month} / ${authVM.selectedDob!.year}"
                            : "Select Date",
                        style: GoogleFonts.inter(
                          fontSize: authVM.selectedDob != null ? 15 : 13,
                          fontWeight: authVM.selectedDob != null ? FontWeight.w600 : FontWeight.w400,
                          color: authVM.selectedDob != null ? Colors.black87 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _buildAnimatedTextField(
                label: "Age",
                hint: "Age",
                icon: Icons.cake_rounded,
                controller: authVM.ageController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedTextField(
                      label: "Weight (kg)",
                      hint: "Weight",
                      icon: Icons.monitor_weight_rounded,
                      controller: authVM.weightController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAnimatedTextField(
                      label: "Height (ft)",
                      hint: "Height",
                      icon: Icons.height_rounded,
                      controller: authVM.heightController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildAnimatedTextField(
                label: "Blood Group",
                hint: "Blood Group (Optional)",
                icon: Icons.bloodtype_rounded,
                controller: authVM.bloodGroupController,
              ),

              const SizedBox(height: 40),
              CustomButton(
                text: "Next Step",
                isLoading: authVM.loading,
                onPressed: () => authVM.submitStep4(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenderCard(String label, RegisterViewModel authVM) {
    bool isSelected = authVM.selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          authVM.setGender(label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.06),
                blurRadius: isSelected ? 16 : 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: isSelected
                ? null
                : Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            border: null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
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
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }
}
