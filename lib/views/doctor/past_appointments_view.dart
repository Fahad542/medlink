import 'package:flutter/material.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/patient_appointment_history_model.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/appointment_detail_view.dart';
import 'package:medlink/views/doctor/Doctor%20Patient%20Dashboard/prescription_detail_view_model.dart';
import 'package:medlink/views/doctor/past_appointments_view_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/shimmer_widgets.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PastAppointmentsView extends StatefulWidget {
  final UserModel? patient;
  final String title;
  final List<PatientAppointmentHistoryData>? history;

  const PastAppointmentsView({
    super.key,
    this.patient,
    this.title = "Past Appointments",
    this.history,
  });

  @override
  State<PastAppointmentsView> createState() => _PastAppointmentsViewState();
}

class _PastAppointmentsViewState extends State<PastAppointmentsView> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid fetching during build if possible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<PastAppointmentsViewModel>(context, listen: false);
      if (widget.history == null || widget.history!.isEmpty) {
        viewModel.fetchHistory(widget.patient?.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: CustomAppBar(title: widget.title),
      body: Consumer<PastAppointmentsViewModel>(
        builder: (context, viewModel, child) {
          // If we have history passed via constructor, use it. Otherwise use ViewModel data.
          final displayHistory = (widget.history != null && widget.history!.isNotEmpty)
              ? widget.history!
              : viewModel.history;

          if (viewModel.isLoading && displayHistory.isEmpty) {
            return _buildLoadingState();
          }

          if (displayHistory.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.fetchHistory(widget.patient?.id),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: displayHistory.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildVisitCard(
                    title: item.appointmentName ?? "Consultation",
                    subtitle: item.chiefComplaint ?? "No complaint provided",
                    patientName: item.patientName ?? "Patient",
                    time: _formatAppointmentDate(item.date),
                    highlight: true,
                    color: AppColors.primary,
                    iconAsset: "assets/Icons/appointment.png",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => PrescriptionDetailViewModel(),
                          child: AppointmentDetailView(
                            title: item.appointmentName ?? "Consultation",
                            date: _formatAppointmentDate(item.date),
                            reason: item.chiefComplaint ?? "No complaint",
                            appointmentId: item.appointmentId?.toString() ?? "0",
                          ),
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: 8,
      itemBuilder: (context, index) => const VisitCardShimmer(),
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

  Widget _buildEmptyState() {
    return const NoDataWidget(
      subTitle: "No past appointments found",
    );
  }

  Widget _buildVisitCard({
    required String title,
    required String subtitle,
    required String patientName,
    required String time,
    required bool highlight,
    required Color color,
    String? iconAsset,
    VoidCallback? onTap,
  }) {
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
                  const SizedBox(height: 2),
                  Text(
                    "Patient: $patientName",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary.withOpacity(0.8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
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
