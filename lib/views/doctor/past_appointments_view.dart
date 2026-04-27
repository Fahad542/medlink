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
                    patientName: item.patientName,
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
    String? patientName,
    required String time,
    required bool highlight,
    required Color color,
    String? iconAsset,
    VoidCallback? onTap,
  }) {
    final displayName =
        (patientName != null && patientName.trim().isNotEmpty)
            ? patientName.trim()
            : title;
    final consultationLabel = title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.12),
                child: iconAsset != null
                    ? Image.asset(iconAsset, width: 22, height: 22, color: color)
                    : Icon(
                        highlight
                            ? Icons.check_circle_rounded
                            : Icons.history_edu_rounded,
                        color: color,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      consultationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
