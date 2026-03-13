import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/appointment_detail_view.dart';

import 'package:provider/provider.dart';
import 'package:medlink/views/doctor/Patient%20history/patient_history_view_model.dart';
import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/prescription_detail_view_model.dart';
// ... other imports ...

class PatientHistoryView extends StatelessWidget {
  final String patientName;
  final UserModel? patient;
  final bool showBackButton;

  const PatientHistoryView({
    super.key, 
    this.patientName = "John Doe",
    this.patient,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientHistoryViewModel(),
      child: Consumer<PatientHistoryViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FB),
            appBar: CustomAppBar(
              title: patientName,
              automaticallyImplyLeading: showBackButton,
              actions: [
                  _buildAppBarAction(assetPath: "assets/Icons/chat.png", onTap: () {}),
                  const SizedBox(width: 8),
                  _buildAppBarAction(assetPath: "assets/Icons/video.png", onTap: () {}),
                  const SizedBox(width: 8),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Recent Visits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 10),

                // Medical History List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: viewModel.visits.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final visit = viewModel.visits[index];
                      return _buildVisitCard(context, visit);
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: const Text("New Visit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildVisitCard(BuildContext context, Map<String, dynamic> visit) {
      final title = visit['title'];
      final doctor = visit['doctor'];
      final symptoms = visit['symptoms'];
      final date = visit['date'];
      
      return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(
            create: (_) => PrescriptionDetailViewModel(),
            child: AppointmentDetailView(
              date: date,
              title: title,
              reason: symptoms,
              appointmentId: visit['id']?.toString() ?? "0",
            ),
          )));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Colored Bar
                Container(
                  width: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  date, 
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("Completed", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(doctor, style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                        Text(symptoms, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
                        
                        const SizedBox(height: 12),
                        // Action / Divider
                        Divider(color: Colors.grey.withOpacity(0.1), height: 1),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Text("View Full Details", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildAppBarAction({IconData? icon, String? assetPath, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: assetPath != null 
            ? Image.asset(assetPath, width: 20, height: 20, color: Colors.white)
            : Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
