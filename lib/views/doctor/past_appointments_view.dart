import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/appointment_detail_view.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class PastAppointmentsView extends StatelessWidget {
  final UserModel patient;

  const PastAppointmentsView({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const CustomAppBar(title: "Past Appointments"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _buildVisitCard(
              "General Checkup",
              "Mild Fever & Cough",
              "Today, 10:00 AM",
              true,
              AppColors.primary,
              iconAsset: "assets/Icons/appointment.png",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentDetailView(title: "General Checkup", date: "Today, 10:00 AM", reason: "Mild Fever & Cough"))),
            ),
            const SizedBox(height: 12),
            _buildVisitCard(
              "Blood Test",
              "Typhoid",
              "Yesterday, 02:00 PM",
              false,
              AppColors.primary,
              iconAsset: "assets/Icons/appointment.png",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentDetailView(title: "Blood Test", date: "Yesterday, 02:00 PM", reason: "Typhoid"))),
            ),
            const SizedBox(height: 12),
            _buildVisitCard(
              "Follow up",
              "Viral Infection",
              "12 Dec, 04:30 PM",
              false,
              AppColors.primary,
              iconAsset: "assets/Icons/appointment.png",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentDetailView(title: "Follow up", date: "12 Dec, 04:30 PM", reason: "Viral Infection"))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(String title, String subtitle, String time, bool highlight, Color color, {String? iconAsset, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: iconAsset != null
                  ? Image.asset(iconAsset, width: 20, height: 20, color: color)
                  : Icon(highlight ? Icons.check_circle_rounded : Icons.history_edu_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Row(
                        children: [
                          Text("See Details", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
