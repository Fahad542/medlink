import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/utils/trip_fare_format.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/sos_history/patient_sos_history_map.dart';

class PatientSosHistoryDetailView extends StatelessWidget {
  final Map<String, dynamic> sos;

  const PatientSosHistoryDetailView({super.key, required this.sos});

  static String statusLabelFor(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'OPEN':
        return 'Searching for driver';
      case 'ASSIGNED':
        return 'Driver assigned';
      case 'RESOLVED':
        return 'Resolved';
      case 'CANCELLED':
        return 'Cancelled';
      case 'EXPIRED':
        return 'No driver found';
      default:
        return raw?.replaceAll('_', ' ') ?? '—';
    }
  }

  static Color statusColorFor(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'OPEN':
        return const Color(0xFFF59E0B);
      case 'ASSIGNED':
        return AppColors.primary;
      case 'RESOLVED':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      case 'EXPIRED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _fmt(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy, HH:mm').format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final id = sos['id']?.toString() ?? '—';
    final status = sos['status']?.toString();
    final trip = sos['trip'];
    final driver = sos['assignedDriver'];
    final noDriverMsg = sos['noDriverFoundMessage']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CustomAppBar(title: 'SOS #$id'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Locations (Google Maps)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                PatientSosHistoryMap(sos: sos),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Emergency request',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColorFor(status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabelFor(status),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColorFor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _row('Requested', _fmt(sos['createdAt'])),
                if (sos['resolvedAt'] != null)
                  _row('Resolved / closed', _fmt(sos['resolvedAt'])),
                _row('Type', sos['emergencyType']?.toString() ?? '—'),
                _row('Severity', sos['severity']?.toString() ?? '—'),
                _row(
                  'Pickup / location',
                  sos['addressText']?.toString().trim().isNotEmpty == true
                      ? sos['addressText'].toString()
                      : '—',
                ),
              ],
            ),
          ),
          if (noDriverMsg != null && noDriverMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                noDriverMsg,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.35,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
          if (driver is Map) ...[
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned driver',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Builder(
                        builder: (context) {
                          final photoUrl =
                              driver['profilePhotoUrl']?.toString().trim() ?? '';
                          final name =
                              driver['fullName']?.toString().trim() ?? '';
                          final initial = name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?';
                          return CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(AppUrl.getFullUrl(photoUrl))
                                : null,
                            child: photoUrl.isEmpty
                                ? Text(
                                    initial,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver['fullName']?.toString() ?? 'Driver',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (driver['phone'] != null &&
                                driver['phone'].toString().isNotEmpty)
                              Text(
                                driver['phone'].toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            if (driver['vehicleType'] != null ||
                                driver['vehiclePlate'] != null)
                              Text(
                                [
                                  driver['vehicleType']?.toString(),
                                  driver['vehiclePlate']?.toString(),
                                ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (trip is Map) ...[
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ambulance trip',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row('Trip', trip['tripNumber']?.toString() ?? '#${trip['id']}'),
                  _row('Trip status', trip['status']?.toString() ?? '—'),
                  _row('Pickup', trip['pickupAddress']?.toString() ?? '—'),
                  _row('Drop-off', trip['dropoffAddress']?.toString() ?? '—'),
                  _row('Fare', TripFareFormat.display(Map<String, dynamic>.from(trip))),
                  _row('Payment', trip['paymentStatus']?.toString() ?? '—'),
                  _row('Payment method', trip['paymentMethod']?.toString() ?? '—'),
                  if (trip['distanceKm'] != null)
                    _row('Distance (km)', trip['distanceKm'].toString()),
                  if (trip['timeMinutes'] != null)
                    _row('Time (min)', trip['timeMinutes'].toString()),
                  _row('Requested', _fmt(trip['requestedAt'])),
                  if (trip['startedAt'] != null)
                    _row('Started', _fmt(trip['startedAt'])),
                  if (trip['completedAt'] != null)
                    _row('Completed', _fmt(trip['completedAt'])),
                  if (trip['cancelledAt'] != null)
                    _row('Cancelled', _fmt(trip['cancelledAt'])),
                  if (trip['paidAt'] != null) _row('Paid at', _fmt(trip['paidAt'])),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'No trip was created for this request (for example, no driver accepted in time).',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              k,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
