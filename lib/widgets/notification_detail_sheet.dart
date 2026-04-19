import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/in_app_notification_model.dart';

/// Fancy bottom sheet for a single notification (timeline, chips, contextual cards).
///
/// When [onMarkRead] is set and [n.isRead] is false, calls it with [n.id] so the app
/// can PATCH the backend (`isRead` in DB). Fire-and-forget.
void showNotificationDetailSheet(
  BuildContext context,
  InAppNotificationModel n, {
  Future<void> Function(String notificationId)? onMarkRead,
}) {
  if (onMarkRead != null && n.id.isNotEmpty && !n.isRead) {
    unawaited(onMarkRead(n.id));
  }
  final fullWhen =
      DateFormat('EEEE, d MMMM yyyy • h:mm:ss a').format(n.createdAt.toLocal());

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      final maxH = MediaQuery.of(ctx).size.height * 0.92;

      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  color: Color(0x40000000),
                  offset: Offset(0, -6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHeader(n, fullWhen),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: _sheetBody(context, n),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

String _relativeSnippet(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 &&
      local.day == now.day &&
      local.month == now.month &&
      local.year == now.year) {
    return '${diff.inHours} hr ago';
  }
  if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  return DateFormat('EEE, d MMM yyyy • h:mm a').format(local);
}

IconData _iconForType(String? type) {
  switch (type) {
    case 'APPOINTMENT_RESCHEDULED':
      return Icons.event_repeat_rounded;
    case 'APPOINTMENT_CANCELLED':
      return Icons.event_busy_rounded;
    case 'APPOINTMENT_CONFIRMED':
    case 'APPOINTMENT_BOOKED':
      return Icons.event_available_rounded;
    default:
      return Icons.notifications_active_rounded;
  }
}

Color _accentForType(String? type) {
  switch (type) {
    case 'APPOINTMENT_RESCHEDULED':
      return const Color(0xFF0288D1);
    case 'APPOINTMENT_CANCELLED':
      return AppColors.error;
    case 'APPOINTMENT_CONFIRMED':
    case 'APPOINTMENT_BOOKED':
      return AppColors.success;
    default:
      return AppColors.primary;
  }
}

Widget _sheetHeader(InAppNotificationModel n, String fullWhen) {
  final accent = _accentForType(n.type);
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      _iconForType(n.type),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _glassChip(
                              icon: Icons.schedule_rounded,
                              label: fullWhen,
                              compact: false,
                            ),
                            _glassChip(
                              icon: Icons.timelapse_rounded,
                              label: _relativeSnippet(n.createdAt),
                              compact: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (n.type != null && n.type!.isNotEmpty)
                    _tagChip(
                      label: n.type!.replaceAll('_', ' '),
                      color: accent,
                    ),
                  _tagChip(
                    label: n.isRead ? 'Read' : 'New',
                    color: n.isRead ? AppColors.textSecondary : Colors.white,
                    filled: !n.isRead,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _glassChip({
  required IconData icon,
  required String label,
  required bool compact,
}) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 10 : 12,
      vertical: compact ? 6 : 8,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 14 : 16, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _tagChip({
  required String label,
  required Color color,
  bool filled = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withValues(alpha: filled ? 0.9 : 0.35),
      ),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: filled ? AppColors.primary : Colors.white,
      ),
    ),
  );
}

Widget _sheetBody(BuildContext context, InAppNotificationModel n) {
  final data = n.data;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Message',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          n.body,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (data != null && data.isNotEmpty)
        _contextualBlock(n.type, data),
      if (_shouldShowTechnicalFallback(n.type, data))
        _technicalFooter(data),
      const SizedBox(height: 16),
      Center(
        child: Text(
          'Notification #${n.id}',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    ],
  );
}

bool _shouldShowTechnicalFallback(String? type, Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) return false;
  if (type == 'APPOINTMENT_RESCHEDULED') return false;
  return true;
}

Widget _contextualBlock(String? type, Map<String, dynamic> data) {
  if (type == 'APPOINTMENT_RESCHEDULED') {
    return _rescheduleCard(data);
  }

  return _genericDataCards(data);
}

DateTime? _parseIso(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

Widget _rescheduleCard(Map<String, dynamic> data) {
  final appointmentId = data['appointmentId'];
  final by = data['rescheduledBy']?.toString().toUpperCase();
  final prev = _parseIso(
    data['previousScheduledStart'] ??
        data['oldScheduledStart'] ??
        data['scheduledStartBefore'],
  );
  final next = _parseIso(
    data['newScheduledStart'] ??
        data['scheduledStart'] ??
        data['scheduledStartAfter'],
  );

  final isDoctor = by == 'DOCTOR';
  final byLabel = by == null
      ? 'Someone'
      : isDoctor
          ? 'Doctor'
          : 'Patient';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Appointment',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.secondary.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appointmentId != null
                        ? 'Visit reference #${appointmentId.toString()}'
                        : 'Visit update',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      isDoctor ? AppColors.primary.withValues(alpha: 0.15) : AppColors.secondary.withValues(alpha: 0.35),
                  child: Icon(
                    isDoctor ? Icons.medical_services_outlined : Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rescheduled by',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        byLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (prev != null || next != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              if (prev != null) _timeRow('Previous time', prev, Icons.history_rounded),
              if (prev != null && next != null) const SizedBox(height: 12),
              if (next != null) _timeRow('New time', next, Icons.event_available_rounded),
            ] else ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.primary.withValues(alpha: 0.85), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Open Appointments in the app to see the full updated date and time for this visit.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

Widget _timeRow(String label, DateTime dt, IconData icon) {
  final dateStr = DateFormat('EEE, d MMM yyyy').format(dt);
  final timeStr = DateFormat('h:mm a').format(dt);

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              timeStr,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _genericDataCards(Map<String, dynamic> data) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Details',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 10),
      ...data.entries.map((e) {
        final v = e.value;
        final display = v is Map || v is List
            ? jsonEncode(v)
            : v.toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    _friendlyKey(e.key),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    display,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}

String _friendlyKey(String k) {
  return k.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (m) => ' ${m.group(1)}',
  ).trim().split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

Widget _technicalFooter(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) return const SizedBox.shrink();
  final raw = const JsonEncoder.withIndent('  ').convert(data);
  return Material(
    color: Colors.transparent,
    child: Theme(
    data: ThemeData.light().copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(Icons.code_rounded, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'Technical payload',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            raw,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              height: 1.45,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    ),
    ),
  );
}
