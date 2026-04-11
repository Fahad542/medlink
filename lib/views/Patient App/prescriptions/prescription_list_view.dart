import 'package:flutter/material.dart';
import 'package:medlink/widgets/custom_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/views/Patient App/prescriptions/prescription_view_model.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:medlink/widgets/prescription_list_shimmer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PrescriptionListView extends StatefulWidget {
  const PrescriptionListView({super.key});

  @override
  State<PrescriptionListView> createState() => _PrescriptionListViewState();
}

class _PrescriptionListViewState extends State<PrescriptionListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrescriptionViewModel>(context, listen: false)
          .fetchPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const CustomAppBar(title: "My Prescriptions"),
      body: Consumer<PrescriptionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.prescriptions.isEmpty) {
            return const PrescriptionListShimmer(itemCount: 4);
          }

          if (viewModel.prescriptions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => viewModel.fetchPrescriptions(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: viewModel.prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = viewModel.prescriptions[index];
                return _buildPrescriptionCard(prescription);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const NoDataWidget(
      title: "No Prescriptions Yet",
      subTitle: "Your prescriptions from doctors\nwill appear here.",
    );
  }

  Widget _buildPrescriptionCard(dynamic p) {
    final doctor = p['doctor'] as Map? ?? {};
    final appointment = p['appointment'] as Map? ?? {};
    final diagnosis = p['diagnosis'] ?? 'N/A';
    final testsPending = p['testsPending'] ?? 0;
    final testsCount = p['testsCount'] ?? 0;

    final createdAt = p['createdAt'] != null
        ? DateTime.tryParse(p['createdAt'])
        : null;

    final scheduledStart = appointment['scheduledStart'] != null
        ? DateTime.tryParse(appointment['scheduledStart'])
        : null;

    final doctorName = doctor['fullName'] ?? 'Doctor';
    final specialty = doctor['specialty'] ?? '';
    final profilePhotoUrl =
        AppUrl.getFullUrl(doctor['profilePhotoUrl']?.toString());
    final consultKind = appointment['consulKind'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildDoctorAvatar(profilePhotoUrl, doctorName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. $doctorName",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (specialty.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM dd, yyyy').format(createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildConsultKindBadge(consultKind),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[100]),

          // ── Diagnosis ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_information_outlined,
                    size: 18, color: AppColors.primary.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Diagnosis",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        diagnosis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1A1A2E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Appointment Date ──
          if (scheduledStart != null) ...[
            Divider(height: 1, color: Colors.grey[100]),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    "Appointment: ${DateFormat('MMM dd, yyyy • hh:mm a').format(scheduledStart.toLocal())}",
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],

          // ── Tests Summary Footer ──
          if (testsCount > 0) ...[
            Divider(height: 1, color: Colors.grey[100]),
            Container(
              decoration: BoxDecoration(
                color: testsPending > 0
                    ? const Color(0xFFFFF8E7)
                    : const Color(0xFFECFDF5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    testsPending > 0
                        ? Icons.science_outlined
                        : Icons.check_circle_outline,
                    size: 16,
                    color: testsPending > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    testsPending > 0
                        ? "$testsPending of $testsCount test(s) pending upload"
                        : "All $testsCount test report(s) uploaded",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: testsPending > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Just rounded bottom
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorAvatar(String photoUrl, String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    final fallback = CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: AppColors.primary,
        ),
      ),
    );

    if (photoUrl.isEmpty) return fallback;

    return CustomNetworkImage(
      imageUrl: photoUrl,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      shape: BoxShape.circle,
    );
  }

  Widget _buildConsultKindBadge(String kind) {
    final isVideo = kind.toUpperCase() == 'VIDEO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isVideo
            ? const Color(0xFFEDE9FE)
            : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_outlined : Icons.phone_outlined,
            size: 13,
            color: isVideo ? const Color(0xFF7C3AED) : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            kind.isEmpty ? 'Consult' : kind,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isVideo ? const Color(0xFF7C3AED) : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
