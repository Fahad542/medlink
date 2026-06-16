import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/utils/trip_fare_format.dart';
import 'package:medlink/widgets/custom_network_image.dart';

/// Bottom sheet with full details for a patient appointment.
void showPatientAppointmentDetail(
  BuildContext context,
  AppointmentModel appointment,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.38,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return _PatientAppointmentSheetContent(
            scrollController: scrollController,
            appointment: appointment,
          );
        },
      );
    },
  );
}

/// Backward-compatible wrapper for existing cancelled-only call sites.
void showPatientCancelledAppointmentDetail(
  BuildContext context,
  AppointmentModel appointment,
) {
  showPatientAppointmentDetail(context, appointment);
}

class _PatientAppointmentSheetContent extends StatelessWidget {
  const _PatientAppointmentSheetContent({
    required this.scrollController,
    required this.appointment,
  });

  final ScrollController scrollController;
  final AppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final doctor = a.doctor;
    final name = (doctor?.name.isNotEmpty == true) ? doctor!.name : 'Unknown Doctor';
    final spec = (doctor?.specialty.isNotEmpty == true) ? doctor!.specialty : '—';
    final imageUrl = doctor?.imageUrl;
    final start = a.displayScheduledStart;
    final end = a.scheduledEnd;
    final startFmt = DateFormat('EEE, MMM d, y').format(start);
    final startTime = DateFormat('h:mm a').format(start);
    final endTime = end != null ? DateFormat('h:mm a').format(end) : null;
    final dur = a.scheduledDurationLabel ?? '—';
    final typeLabel = a.type.shortLabel;
    final fee = a.feeAmount;
    final feeText = (fee != null)
        ? TripFareFormat.formatCfa(
            fee,
            currencyHint: a.currency,
          )
        : '—';

    String cancelBy;
    final cid = a.cancelledById;
    if (cid == null || cid.isEmpty) {
      cancelBy = 'Unknown';
    } else if (cid == a.userId) {
      cancelBy = 'You (patient)';
    } else if (cid == a.doctorId) {
      cancelBy = 'Doctor';
    } else {
      cancelBy = 'Other';
    }

    final byDoctor = cancelBy == 'Doctor';
    final byPatient = cancelBy == 'You (patient)';
    final showCancellationPanel = a.status == AppointmentStatus.cancelled;

    final reason = (a.cancelReason != null && a.cancelReason!.trim().isNotEmpty)
        ? a.cancelReason!.trim()
        : null;
    final bookReason = (a.reason != null && a.reason!.trim().isNotEmpty)
        ? a.reason!.trim()
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visit details',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                _DoctorHeaderCard(
                  name: name,
                  specialty: spec,
                  imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Schedule',
                  child: Column(
                    children: [
                      _IconRow(
                        icon: Icons.event_rounded,
                        label: 'Date',
                        value: startFmt,
                        iconBg: AppColors.primary.withValues(alpha: 0.12),
                        iconColor: AppColors.primary,
                      ),
                      const _SoftDivider(),
                      _IconRow(
                        icon: Icons.schedule_rounded,
                        label: 'Time slot',
                        value: endTime != null
                            ? '$startTime – $endTime'
                            : startTime,
                        iconBg: const Color(0xFFE0F2F1),
                        iconColor: AppColors.accent,
                      ),
                      const _SoftDivider(),
                      _IconRow(
                        icon: Icons.timelapse_rounded,
                        label: 'Duration',
                        value: dur,
                        iconBg: const Color(0xFFFFF3E0),
                        iconColor: const Color(0xFFE65100),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Visit type',
                  child: _IconRow(
                    icon: a.type == AppointmentType.online
                        ? Icons.videocam_rounded
                        : Icons.local_hospital_rounded,
                    label: 'Consultation',
                    value: typeLabel,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    dense: true,
                  ),
                ),
                const SizedBox(height: 12),
                _FeeCard(amountLabel: feeText),
                const SizedBox(height: 12),
                if (showCancellationPanel)
                  _CancellationPanel(
                    cancelledBy: cancelBy,
                    reason: reason,
                    byDoctor: byDoctor,
                    byPatient: byPatient,
                  ),
                if (bookReason != null) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Booking note',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.notes_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bookReason,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _statusChip() {
  return Container(
    margin: const EdgeInsets.only(top: 4, right: 4),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.error.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.do_not_disturb_on_rounded,
          size: 16,
          color: AppColors.error,
        ),
        const SizedBox(width: 5),
        Text(
          'Cancelled',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

class _DoctorHeaderCard extends StatelessWidget {
  const _DoctorHeaderCard({
    required this.name,
    required this.specialty,
    this.imageUrl,
  });

  final String name;
  final String specialty;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final u = imageUrl;
    final hasPhoto = u != null && u.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? CustomNetworkImage(
                      imageUrl: u,
                      width: 64,
                      height: 64,
                      shape: BoxShape.circle,
                      borderRadius: 0,
                    )
                  : ColoredBox(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.medical_services_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your doctor',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        specialty,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: dense ? 36 : 40,
          height: dense ? 36 : 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: dense ? 18 : 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: dense ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider.withValues(alpha: 0.5),
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({required this.amountLabel});

  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSULTATION FEE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amountLabel,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationPanel extends StatelessWidget {
  const _CancellationPanel({
    required this.cancelledBy,
    required this.reason,
    required this.byDoctor,
    required this.byPatient,
  });

  final String cancelledBy;
  final String? reason;
  final bool byDoctor;
  final bool byPatient;

  @override
  Widget build(BuildContext context) {
    final bg = byDoctor
        ? const Color(0xFFFFF5F5)
        : (byPatient ? const Color(0xFFFFF8E1) : const Color(0xFFF5F5F5));
    final border = byDoctor
        ? const Color(0xFFFFCDD2)
        : (byPatient ? const Color(0xFFFFE082) : AppColors.divider);
    final accent = byDoctor ? AppColors.error : const Color(0xFFF57C00);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  byDoctor ? Icons.person_off_rounded : Icons.info_outline,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cancellation',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.assignment_ind_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Cancelled by',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            cancelledBy,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: byDoctor
                  ? AppColors.error
                  : (byPatient ? const Color(0xFFE65100) : AppColors.textPrimary),
            ),
          ),
          if (reason != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 20,
                  color: accent.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Reason',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                reason!,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
