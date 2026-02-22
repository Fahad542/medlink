import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/views/Patient%20App/prescription/doctor_viewmodel.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_profile_view.dart';

class PrescriptionView extends StatelessWidget {
  const PrescriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorVM = Provider.of<DoctorViewModel>(context);
    // Ensure we have doctors loaded or use placeholders if empty
    final doctors = doctorVM.doctors; 
    
    // Mock Data using real doctor models if available
    final prescriptions = [
      if (doctors.isNotEmpty)
      {
        "doctor": doctors[0],
        "date": "12 Oct 2025",
        "medicines": [
          {"name": "Amoxicillin 500mg", "dose": "1 Tablet", "timing": "Morning • Night (After Meal)"},
          {"name": "Paracetamol 650mg", "dose": "1 Tablet", "timing": "SOS (When needed)"}
        ],
        "instructions": "Take 2 tablets daily after meals for 5 days.",
        "diagnosis": "Viral Fever",
        "tests": [
          {"name": "CBC (Complete Blood Count)", "status": "pending"},
          {"name": "Dengue NS1 Antigen", "status": "submitted"}
        ],
        "status": "Active"
      },
      if (doctors.length > 1)
      {
        "doctor": doctors[1],
        "date": "05 Sept 2025",
        "medicines": [
          {"name": "Doxycycline (100mg)", "dose": "1 Capsule", "timing": "Whyte • Night (After Meal)"},
          {"name": "Cetaphil Cleanser", "dose": "Apply", "timing": "Morning • Night"}
        ],
        "instructions": "Apply cream twice daily. Take pill after dinner.",
        "diagnosis": "Acne Vulgaris",
        "status": "Completed"
      },
       if (doctors.length > 2)
      {
        "doctor": doctors[2],
        "date": "20 Aug 2025",
        "medicines": [
           {"name": "Ibuprofen (400mg)", "dose": "1 Tablet", "timing": "SOS (For Pain)"}
        ],
        "instructions": "Take 1 tablet when needed for pain. Max 3 per day.",
        "diagnosis": "Migraine",
        "status": "Completed"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(title: "E-Prescriptions"),
      body: prescriptions.isEmpty 
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Icon(Icons.medication_outlined, size: 80, color: Colors.grey[300]),
               const SizedBox(height: 16),
               Text("No Prescriptions Found", style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ],
          ),
        )
      : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          final doctor = prescription["doctor"] as DoctorModel;
          final status = prescription["status"] as String? ?? "Active";
          final isActive = status == "Active";
       //   final isActive = status == "Active";
          final hasPendingTests = prescription.containsKey("tests") &&
              (prescription["tests"] as List).any((t) => t["status"] == "pending");
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => _showPrescriptionDetail(context, prescription, doctor),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar, Name/Specialty, View Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(14),
                              image: DecorationImage(
                                 image: NetworkImage(doctor.imageUrl), 
                                 fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  doctor.specialty,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6), // Spacer for visual separation if needed
                                
                                // Diagnosis Moved Here (Already here, just ensuring context)
                                Row(
                                  children: [
                                    Icon(Icons.medication_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        prescription["diagnosis"] as String,
                                         style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                         maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasPendingTests) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 14, color: Colors.orange[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Action: Submit Report",
                                        style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Date at Top Right
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    prescription["date"] as String,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // View Button
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "View",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPrescriptionDetail(BuildContext context, Map<String, dynamic> prescription, DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Dismissible Background
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          
          // Main Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close Button (Top Right, floating above card)
              Padding(
                padding: const EdgeInsets.only(right: 30, bottom: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.black87),
                    ),
                  ),
                ),
              ),

              // Receipt Card
              Container(
                width: MediaQuery.of(context).size.width * 0.85, // COMPACT: Narrower card
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Gradient Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // COMPACT Padding
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)], 
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: CircleAvatar(
                                  radius: 24, // COMPACT: Smaller Avatar
                                  backgroundImage: NetworkImage(doctor.imageUrl),
                                ),
                              ),
                              const SizedBox(width: 12), // COMPACT Spacing
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doctor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), // COMPACT Font
                                    const SizedBox(height: 2),
                                    Text(doctor.specialty, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)), // COMPACT Font
                                    const SizedBox(height: 1),
                                    Text("15 min • Standard Check", style: TextStyle(fontSize: 10, color: Colors.grey[500])), // COMPACT Font
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Body Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // COMPACT Padding
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Diagnosis Section
                              _buildReceiptSectionTitle("Diagnosis", const Color(0xFF00BFA5)),
                              const SizedBox(height: 6),
                              Text(
                                "The patient has ${prescription["diagnosis"].toString().toLowerCase()}. Suspected viral AURI, treated symptomatically.",
                                style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475569)), // COMPACT Font
                              ),
                              
                              const SizedBox(height: 16),
                              _buildDashedLine(),
                              const SizedBox(height: 16),

                              // Tests Section (Conditional)
                              if (prescription.containsKey("tests")) ...[
                                _buildReceiptSectionTitle("Tests Required", const Color(0xFF00BFA5)),
                                const SizedBox(height: 12),
                                Column(
                                  children: (prescription["tests"] as List<Map<String, String>>).map((test) {
                                    final isSubmitted = test["status"] == "submitted";
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              test["name"]!, 
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (isSubmitted)
                                            // Submitted: Icon Only
                                             const Icon(Icons.check_circle, size: 20, color: Color(0xFF00897B))
                                          else
                                            // Upload: Small, Icon + Text, Not Bold
                                            SizedBox(
                                              height: 32,
                                              child: OutlinedButton.icon(
                                                onPressed: () {},
                                                icon: const Icon(Icons.upload_rounded, size: 14),
                                                label: const Text("Upload Report"),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.primary,
                                                  side: const BorderSide(color: AppColors.primary),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal), // Not Bold
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                _buildDashedLine(),
                                const SizedBox(height: 16),
                              ],

                              // Prescriptions Section
                              _buildReceiptSectionTitle("Prescriptions", const Color(0xFF00BFA5)),
                              const SizedBox(height: 12),
                              
                              // Medicines Grid/List
                              // Medicines Grid/List
                              Wrap(
                                spacing: 16, // COMPACT Spacing
                                runSpacing: 16,
                                children: (prescription["medicines"] as List<Map<String, String>>).map((med) {
                                  return SizedBox(
                                    width: (MediaQuery.of(context).size.width * 0.85 - 32 - 16) / 2, // 2 columns based on compact width
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(med["name"]!, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)), // COMPACT: Smaller Label
                                        const SizedBox(height: 2),
                                        Text(med["dose"]!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))), // COMPACT: Smaller Value
                                        const SizedBox(height: 2),
                                        Text(med["timing"]!, style: const TextStyle(fontSize: 10, color: Color(0xFF00897B), fontWeight: FontWeight.w500)), // Timing Info
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 16),
                              _buildDashedLine(),
                              const SizedBox(height: 16),

                              // Doctor's Notes
                              _buildReceiptSectionTitle("Doctor's Notes", const Color(0xFF00BFA5)),
                              const SizedBox(height: 6),
                               Text(
                                prescription["instructions"] ?? "No notes provided.",
                                style: const TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFF475569)),
                              ),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),



              const SizedBox(height: 20), // COMPACT Bottom Spacing

              // 3. Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionCircleButton(
                      icon: Icons.download_rounded, 
                      label: "Download", 
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading PDF..."), backgroundColor: Colors.teal));
                      }
                    ),
                    const SizedBox(width: 32),
                    _ActionCircleButton(icon: Icons.share_outlined, label: "Share", onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
        ],

    ));

  }

  Widget _buildReceiptSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 6, height: 6, // COMPACT Dot
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))), // COMPACT Font
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey[300]),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCircleButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 48, height: 48, // COMPACT Button Size
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[600])), // COMPACT Font
      ],
    );
  }
}



class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DetailLabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
