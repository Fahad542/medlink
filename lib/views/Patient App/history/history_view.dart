import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'medical_history_detail_view.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock History Data
    final historyItems = [
      {
        "title": "General Checkup",
        "subtitle": "Dr. Sarah Johnson • Cardiologist",
        "date": "12 Oct 2025",
        "time": "10:00 AM",
        "type": "Appointment",
        "status": "Completed"
      },
      {
        "title": "Prescription Refill",
        "subtitle": "Amoxicillin, Paracetamol",
        "date": "05 Sept 2025",
        "time": "4:30 PM",
        "type": "Prescription",
        "status": "Delivered"
      },
      {
        "title": "Video Consultation",
        "subtitle": "Dr. Emily Davis • Dermatologist",
        "date": "20 Aug 2025",
        "time": "2:15 PM",
        "type": "Consultation",
        "status": "Completed"
      },
      {
        "title": "Blood Test",
        "subtitle": "City Lab Center",
        "date": "10 Aug 2025",
        "time": "9:00 AM",
        "type": "Lab Test",
        "status": "Report Ready"
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(title: "Medical History"),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          final item = historyItems[index];
          final isAppointment = item['type'] == 'Appointment';
          final isPrescription = item['type'] == 'Prescription';

          IconData icon;
          Color iconColor;
          Color iconBg;

          if (isAppointment) {
            icon = Icons.calendar_today_rounded;
            iconColor = Colors.orange;
            iconBg = Colors.orange.withOpacity(0.1);
          } else if (isPrescription) {
            icon = Icons.medication_outlined;
            iconColor = Colors.green;
            iconBg = Colors.green.withOpacity(0.1);
          } else if (item['type'] == 'Lab Test') {
            icon = Icons.biotech_rounded;
            iconColor = Colors.purple;
            iconBg = Colors.purple.withOpacity(0.1);
          } else {
            icon = Icons.video_camera_front_outlined;
            iconColor = Colors.blue;
            iconBg = Colors.blue.withOpacity(0.1);
          }

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MedicalHistoryDetailView(historyItem: item),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // Clean styling similar to other screens
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle']!,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Date/Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['date']!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['status']!,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
