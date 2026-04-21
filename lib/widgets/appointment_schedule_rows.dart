import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/appointment_model.dart';

/// Shows scheduledStart, scheduledEnd, and createdAt for My Appointments lists.
class AppointmentScheduleRows extends StatelessWidget {
  final AppointmentModel appointment;
  final bool dense;

  const AppointmentScheduleRows({
    super.key,
    required this.appointment,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy • h:mm a');
    String fmtDt(DateTime? d) => d == null ? '—' : fmt.format(d);

    Widget line(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: dense ? 13 : 15,
                color: AppColors.primary.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: dense ? 11.5 : 13,
                      color: dense ? const Color(0xFF64748B) : const Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: value),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(
          Icons.schedule_rounded,
          'Scheduled start',
          fmtDt(appointment.displayScheduledStart),
        ),
        line(
          Icons.event_available_outlined,
          'Scheduled end',
          fmtDt(appointment.scheduledEnd),
        ),
        if (appointment.scheduledDurationLabel != null)
          line(
            Icons.timelapse_outlined,
            'Duration',
            appointment.scheduledDurationLabel!,
          ),
        line(
          Icons.add_circle_outline_rounded,
          'Created at',
          fmtDt(appointment.createdAt),
        ),
      ],
    );
  }
}
