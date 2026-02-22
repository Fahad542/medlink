import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class PatientVisitDetailView extends StatelessWidget {
  final String visitDate;
  final String visitType;
  final String doctorName;

  const PatientVisitDetailView({
    super.key,
    required this.visitDate,
    required this.visitType,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const CustomAppBar(title: "Visit Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visitType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$visitDate • $doctorName",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 1. Consultation Details
            _buildSectionHeader("Consultation Details", Icons.medical_services_rounded, AppColors.primary),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Chief Complaint", "Severe headache and mild fever"),
                  const Divider(height: 24),
                  _buildDetailRow("Diagnosis", "Viral Fever"),
                  const Divider(height: 24),
                  _buildDetailRow("Doctor's Notes", "Patient advised to take rest and stay hydrated. Follow up if fever persists for more than 3 days."),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Vitals Snapshot
            _buildSectionHeader("Vitals Snapshot", Icons.monitor_heart_rounded, Colors.redAccent),
            const SizedBox(height: 12),
             Row(
              children: [
                Expanded(child: _buildVitalItem("BP", "120/80", "mmHg")),
                const SizedBox(width: 12),
                Expanded(child: _buildVitalItem("HR", "76", "bpm")),
                const SizedBox(width: 12),
                Expanded(child: _buildVitalItem("Temp", "99.1", "°F")),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Prescriptions
            _buildSectionHeader("Prescriptions", Icons.medication_rounded, Colors.orange),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildRxItem("Paracetamol 500mg", "1 tablet • 3x Daily • 5 Days"),
                  const Divider(height: 24),
                  _buildRxItem("Vitamin C", "1 tablet • 1x Daily • 10 Days"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Lab Tests
            _buildSectionHeader("Lab Tests", Icons.science_rounded, Colors.blue),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildLabItem("Complete Blood Count (CBC)", "Completed", true),
                  const Divider(height: 24),
                  _buildLabItem("Liver Function Test", "Pending", false),
                ],
              ),
            ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title, 
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: AppColors.textPrimary
          )
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4)),
      ],
    );
  }

  Widget _buildVitalItem(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold, height: 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRxItem(String name, String dosage) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 8, color: Colors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(dosage, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabItem(String name, String status, bool isCompleted) {
    return Row(
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status, 
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.bold, 
              color: isCompleted ? Colors.green : Colors.orange
            )
          ),
        ),
      ],
    );
  }
}
