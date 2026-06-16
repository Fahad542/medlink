import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/appointment_model.dart';

/// Small chip: **Online** (video) vs **In clinic** (physical), from [AppointmentModel.type].
class ConsultationTypeBadge extends StatelessWidget {
  final AppointmentType type;
  final bool compact;

  const ConsultationTypeBadge({
    super.key,
    required this.type,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = type == AppointmentType.online
        ? Icons.videocam_outlined
        : Icons.local_hospital_outlined;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 14 : 16,
            color: AppColors.primary,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            type.shortLabel,
            style: GoogleFonts.inter(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
