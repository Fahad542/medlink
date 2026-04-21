import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';
import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/appointment_detail_view.dart';
import 'package:medlink/views/doctor/past_appointments_view.dart';
import 'package:medlink/views/doctor/past_appointments_view_model.dart';

import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/doctor_patient_dashboard_view_model.dart';
import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/prescription_detail_view_model.dart';
import 'package:intl/intl.dart';

class PatientDashboardView extends StatelessWidget {
  const PatientDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DoctorPatientDashboardViewModel>(
      builder: (context, viewModel, child) {
        final patient = viewModel.patient;
        final profile = viewModel.patientProfile;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: viewModel.isLoading
              ? _buildShimmerLoading(context)
              : SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Enhanced Header Background
                      Container(
                        height: 268,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF00897B), AppColors.primary],
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                        ),
                      ),
                      // Decorative Patterns (Circles)
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // 2. Main Content
                      Column(
                        children: [
                          // Header Content
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  // Custom Navigation Bar
                                  Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      // Centered Profile Section
                                      Padding(
                                        padding: const EdgeInsets.only(top: 70),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Profile Image
                                            Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.15),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: CircleAvatar(
                                                radius: 35,
                                                backgroundColor: Colors.white,
                                                backgroundImage: (patient.profileImage != null &&
                                                        patient.profileImage!.isNotEmpty)
                                                    ? NetworkImage(patient.profileImage!)
                                                    : null,
                                                child: (patient.profileImage == null ||
                                                        patient.profileImage!.isEmpty)
                                                    ? Text(
                                                        viewModel.patientInitials,
                                                        style: const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primary),
                                                      )
                                                    : null,
                                              ),
                                            ),

                                            const SizedBox(width: 12),

                                            // Name with Gender/Age
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                profile?.name ?? patient.name ?? "Unknown",
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 20,
                                                                  fontWeight: FontWeight.w700,
                                                                  letterSpacing: -0.5,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      _buildHeaderAction("assets/Icons/chat.png", () {
                                                        final userVM = Provider.of<UserViewModel>(context, listen: false);
                                                        final uId = userVM.loginSession?.data?.user?.id?.toString();
                                                        final dId = userVM.doctor?.id;
                                                        final currentUserId = (uId != null && uId.isNotEmpty) ? uId :
                                                                              (dId != null && dId.isNotEmpty) ? dId : "0";
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (_) => ChatView(
                                                                      recipientName: patient.name ?? "Patient",
                                                                      profileImage: patient.profileImage ?? "",
                                                                      appointmentId: patient.lastAppointmentId ?? "0",
                                                                      doctorId: currentUserId.toString(),
                                                                      patientId: patient.id.toString(),
                                                                                              )));
                                                      }, iconSize: 16, bgColor: Colors.white.withOpacity(0.15)),
                                                      const SizedBox(width: 8),
                                                      _buildHeaderAction("assets/Icons/video.png",
                                                          () => Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (_) => WaitingRoomView(
                                                                      callTargetName: patient.name,
                                                                      isDoctor: true,
                                                                      appointmentId: patient.lastAppointmentId))),
                                                          iconSize: 18,
                                                          bgColor: Colors.white.withOpacity(0.15)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          "${profile?.gender ?? patient.gender ?? 'Male'}, ${profile?.age ?? patient.age ?? 0}",
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),

                                      // Back Button (Positioned Top Left)
                                      Positioned(
                                        left: 0,
                                        top: 10,
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                                            onPressed: () => Navigator.pop(context),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ),
                                      ),

                                      // Centered Title
                                      const Positioned(
                                        top: 12,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: Text(
                                            "Patient Profile",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 3. Latest Vitals — overlap teal header (same pattern as doctor/patient profile KPIs)
                          Transform.translate(
                            offset: const Offset(0, -18),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: _buildCompactVitalItem(
                                            "BP", profile?.bps ?? "120/80", "mmHg", Icons.favorite_outline, Colors.pink)),
                                    Container(width: 1, height: 40, color: Colors.grey.shade200),
                                    Expanded(
                                        child: _buildCompactVitalItem("Heart", "${profile?.heartRate ?? 72}", "bpm",
                                            Icons.monitor_heart_outlined, Colors.blue)),
                                    Container(width: 1, height: 40, color: Colors.grey.shade200),
                                    Expanded(
                                        child: _buildCompactVitalItem("Weight", "${profile?.weight ?? 75}", "kg",
                                            Icons.monitor_weight_outlined, Colors.orange)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 4. Quick Actions
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Text("Quick Actions",
                                    style: TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    "Past Visits",
                                    "${profile?.pastVisitsCount ?? 0} History",
                                    Icons.history_rounded,
                                    Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoCard(
                                    "Lab Reports",
                                    "${profile?.unsubmittedReportsCount ?? 0} New",
                                    Icons.assignment_rounded,
                                    Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 5. Past Appointments
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Past Appointments",
                                        style: TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    TextButton(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ChangeNotifierProvider(
                                                    create: (_) =>
                                                        PastAppointmentsViewModel(),
                                                    child: PastAppointmentsView(
                                                        patient: patient,
                                                        history: viewModel
                                                            .appointmentHistory),
                                                  ))),
                                      child: const Text("View All",
                                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // This could be populated from real appointments if API provides them
                                // For now staying with the mock visits as in original build
                                  if (viewModel.appointmentHistory.isEmpty)
                                    _buildEmptyHistoryState()
                                  else
                                    ...viewModel.appointmentHistory
                                        .take(3)
                                        .map((history) => Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: _buildVisitCard(
                                                history.appointmentName ?? "Consultation",
                                                history.chiefComplaint ?? "No complaint provided",
                                                _formatAppointmentDate(history.date),
                                                true,
                                                AppColors.primary,
                                                iconAsset: "assets/Icons/appointment.png",
                                                onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ChangeNotifierProvider(
                                                      create: (_) => PrescriptionDetailViewModel(),
                                                      child: AppointmentDetailView(
                                                        title: history.appointmentName ?? "Consultation",
                                                        date: _formatAppointmentDate(history.date),
                                                        reason: history.chiefComplaint ?? "No complaint",
                                                        appointmentId: history.appointmentId?.toString() ?? "0",
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )),
                              ],
                            ),
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header Shimmer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 70),
                  Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.3),
                    highlightColor: Colors.white.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 20,
                                width: 150,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 16,
                                width: 100,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Vitals Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: Container(
                height: 80,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Quick Actions Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[50]!,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[200]!,
                    highlightColor: Colors.grey[50]!,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Appointments Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                  2,
                  (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[200]!,
                          highlightColor: Colors.grey[50]!,
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: " $unit",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVitalItem(
      String title, String value, String unit, IconData icon, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: " $unit",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(
      String title, String subtitle, String time, bool highlight, Color color,
      {String? iconAsset, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
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
                  : Icon(
                      highlight
                          ? Icons.check_circle_rounded
                          : Icons.history_edu_rounded,
                      color: color,
                      size: 20),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(time,
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Row(
                        children: [
                          Text("See Details",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 9, color: AppColors.primary),
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

  Widget _buildHeaderAction(String assetPath, VoidCallback onTap,
      {double iconSize = 16.0, Color? bgColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Image.asset(assetPath,
            width: iconSize, height: iconSize, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      height: 120, // Slightly shorter than actions
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabReportCard(
      String title, String status, String date, bool isCompleted) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        Icon(Icons.visibility_outlined,
                            size: 12, color: Colors.white),
                      ],
                    ),
                  ),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  String _formatAppointmentDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final difference = today.difference(appointmentDate).inDays;

      if (difference == 0) {
        return "Today, ${DateFormat.jm().format(dateTime)}";
      } else if (difference == 1) {
        return "Yesterday, ${DateFormat.jm().format(dateTime)}";
      } else {
        return DateFormat('MMM d, yyyy - hh:mm a').format(dateTime);
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmptyHistoryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, color: Colors.grey[300], size: 40),
          const SizedBox(height: 8),
          Text(
            "No appointment history found",
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
