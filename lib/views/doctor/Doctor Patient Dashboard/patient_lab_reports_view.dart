import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class PatientLabReportsView extends StatelessWidget {
  final UserModel patient;

  const PatientLabReportsView({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const CustomAppBar(title: "Lab Reports"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
             _buildLabReportCard("Lipid Profile", "Results Pending", "Today, 11:30 AM", false),
            const SizedBox(height: 12),
            _buildLabReportCard("Complete Blood Count (CBC)", "Completed", "Yesterday, 09:00 AM", true),
            const SizedBox(height: 12),
            _buildLabReportCard("Thyroid Panel", "Reviewed", "10 Dec, 02:00 PM", true),
            const SizedBox(height: 12),
            _buildLabReportCard("Hemoglobin A1c", "Completed", "05 Dec, 10:30 AM", true),
             const SizedBox(height: 12),
            _buildLabReportCard("Liver Function Test", "Results Pending", "04 Dec, 09:15 AM", false),
             const SizedBox(height: 12),
            _buildLabReportCard("Urinalysis", "Completed", "01 Dec, 01:45 PM", true),
          ],
        ),
      ),
    );
  }

  Widget _buildLabReportCard(String title, String status, String date, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          isCompleted
              ? GestureDetector(
                  onTap: () {
                    // Handle View Result
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Text(
                          "Result",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
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
    );
  }
}
