import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/appointment_model.dart';

/// Online (video) vs in-clinic booking; stored on the appointment as API `consultKind`.
class ConsultationTypeSelector extends StatelessWidget {
  final AppointmentType value;
  final ValueChanged<AppointmentType> onChanged;
  final TextStyle? titleStyle;

  const ConsultationTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consultation type',
          style: titleStyle ??
              GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<AppointmentType>(
          segments: const [
            ButtonSegment<AppointmentType>(
              value: AppointmentType.inPerson,
              label: Text('At clinic'),
              icon: Icon(Icons.local_hospital_outlined, size: 18),
            ),
            ButtonSegment<AppointmentType>(
              value: AppointmentType.online,
              label: Text('Online'),
              icon: Icon(Icons.videocam_outlined, size: 18),
            ),
          ],
          selected: {value},
          onSelectionChanged: (Set<AppointmentType> next) {
            if (next.isNotEmpty) onChanged(next.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.comfortable,
            side: WidgetStatePropertyAll(
              BorderSide(color: Colors.grey.withValues(alpha: 0.35)),
            ),
          ),
        ),
      ],
    );
  }
}
