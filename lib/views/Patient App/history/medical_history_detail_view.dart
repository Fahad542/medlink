import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class MedicalHistoryDetailView extends StatelessWidget {
  final Map<String, String> historyItem;

  const MedicalHistoryDetailView({super.key, required this.historyItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(title: "Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(historyItem['type']!),
                      color: AppColors.primary,
                      size: 32,
                    ),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     historyItem['title']!,
                     style: GoogleFonts.inter(
                       fontSize: 22,
                       fontWeight: FontWeight.bold,
                       color: AppColors.textPrimary,
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: _getStatusColor(historyItem['status']!).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Text(
                       historyItem['status']!,
                       style: GoogleFonts.inter(
                         color: _getStatusColor(historyItem['status']!),
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Details Section
            Text(
              "Information",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.grey[100]!),
               ),
               child: Column(
                 children: [
                   _buildDetailRow(Icons.calendar_today_rounded, "Date", historyItem['date']!),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                   _buildDetailRow(Icons.access_time_rounded, "Time", historyItem['time']!),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                   _buildDetailRow(Icons.person_outline_rounded, "Provider", historyItem['subtitle']!),
                   const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                   _buildDetailRow(Icons.category_outlined, "Type", historyItem['type']!),
                 ],
               ),
             ),
             
             const SizedBox(height: 24),
             if (historyItem['type'] == 'Prescription') ...[
                Text(
                  "Medications",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(20),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: Colors.grey[100]!),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       _buildMedicineItem("Amoxicillin", "500mg • 2x Daily"),
                       const SizedBox(height: 16),
                       _buildMedicineItem("Paracetamol", "500mg • As needed"),
                     ],
                   ),
                 ),
             ],

             if (historyItem['type'] == 'Appointment') ...[
               Text(
                  "Diagnosis Notes",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(20),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: Colors.grey[100]!),
                   ),
                   child: Text(
                     "Patient presented with mild fever and sore throat. Recommended rest and hydration along with prescribed antibiotics.",
                     style: GoogleFonts.inter(color: Colors.grey[600], height: 1.5, fontSize: 14),
                   ),
                 ),
                 const SizedBox(height: 24),
                 // Dummy Report Attachment
                  Text(
                  "Attachments",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                 Container(
                   height: 150,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(16),
                     image: const DecorationImage(
                       image: NetworkImage("https://img.freepik.com/free-vector/medical-checkup-report-concept-illustration_114360-15340.jpg?w=1480"),
                       fit: BoxFit.cover
                     )
                   ),
                 )
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicineItem(String name, String dose) {
    return Row(
      children: [
        const Icon(Icons.medication_liquid_sharp, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(dose, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          ],
        )
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Appointment': return Icons.calendar_today_rounded;
      case 'Prescription': return Icons.medication_outlined;
      case 'Lab Test': return Icons.biotech_rounded;
      default: return Icons.local_hospital_outlined;
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'Completed' || status == 'Delivered') return Colors.green;
    return Colors.blue;
  }
}
