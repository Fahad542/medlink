import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class AppointmentDetailView extends StatelessWidget {
  final String title;
  final String date;
  final String reason;

  const AppointmentDetailView({
    super.key,
    required this.title,
    required this.date,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Softer background color
      appBar: CustomAppBar(title: title),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. More Compact Row Header


            // 2. Main Content (Compressed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Consultation Info", Icons.medical_services_outlined),
                  const SizedBox(height: 10),
                  _buildContainerCard([
                    _buildInformativeRow(Icons.short_text_rounded, "Chief Complaint", reason),
                    _buildInformativeRow(Icons.troubleshoot_rounded, "Diagnosis", "Acute Viral Infection", isLast: true),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionHeader("Vitals Captured", Icons.speed_rounded),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildGlassVitalBox("BP", "120/80", "mmHg", const Color(0xFFCEE9F1))), // Light blue
                      const SizedBox(width: 10),
                      Expanded(child: _buildGlassVitalBox("Pulse", "72", "bpm", const Color(0xFFE3DBF2))), // Light purple
                      const SizedBox(width: 10),
                      Expanded(child: _buildGlassVitalBox("Temp", "98.6", "°F", const Color(0xFFFFEBD2))), // Light orange
                    ],
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader("Medications", Icons.medication_liquid_rounded),
                  const SizedBox(height: 10),
                  _buildContainerCard([
                    _buildMedicationItem("Paracetamol", "500mg • 3x Daily", "5 Days"),
                    _buildMedicationItem("Vitamin C", "1 tablet • 1x Daily", "10 Days", isLast: true),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionHeader("Doctor's Remarks", Icons.comment_bank_outlined),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      "Patient advised to take rest. Increase fluid intake. Follow up if symptoms persist beyond 48 hours.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary.withOpacity(0.8),
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionHeader("Prescribed Tests", Icons.science_outlined),
                  const SizedBox(height: 10),
                  _buildContainerCard([
                    _buildTestItem("Complete Blood Count (CBC)", "Ordered Today", "Pending"),
                    _buildTestItem("Liver Function Test", "Ordered Today", "Completed", isLast: true),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildContainerCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInformativeRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.withOpacity(0.05), indent: 46, endIndent: 16),
      ],
    );
  }

  Widget _buildMedicationItem(String name, String dosage, String duration, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.circle, color: Colors.teal, size: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    Text(dosage, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Text(
                duration,
                style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.withOpacity(0.05), indent: 36, endIndent: 16),
      ],
    );
  }

  Widget _buildGlassVitalBox(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(14), // Adjusted padding to prevent overflow
      decoration: BoxDecoration(
        color: color, // Use the passed color as background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildTestItem(String name, String date, String status, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.science_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
              status == "Completed"
              ? GestureDetector(
                  onTap: () {
                    // Handle view result
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "See Result",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Pending",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.withOpacity(0.05), indent: 44, endIndent: 16),
      ],
    );
  }
}

