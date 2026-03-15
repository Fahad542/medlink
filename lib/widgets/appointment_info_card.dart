import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_profile_view.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient App/appointment/appointment_viewmodel.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/widgets/custom_network_image.dart';

import 'package:medlink/views/services/session_view_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AppointmentInfoCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showConfirmationActions;

  const AppointmentInfoCard({
    super.key,
    required this.appointment,
    this.showConfirmationActions = false,
  });

  void _showAppointmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    "Appointment Options",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Choose an action for this appointment",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // View Prescription — only if prescription exists
            if (appointment.prescription != null)
              _buildOptionItem(
                context,
                icon: Icons.description_outlined,
                title: "View Prescription",
                subtitle: "See diagnosis, medicines & tests",
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _showPrescriptionSheet(context);
                },
              ),

            _buildOptionItem(
              context,
              icon: Icons.chat_bubble_outline_rounded,
              assetPath: "assets/Icons/chat.png",
              iconSize: 18,
              title: "Message Doctor",
              subtitle: "Start a chat related to this visit",
              color: AppColors.primary,
              onTap: () {
                final userVM =
                    Provider.of<UserViewModel>(context, listen: false);
                final currentUserId = userVM.loginSession?.data?.user?.id ?? 0;
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatView(
                              recipientName:
                                  appointment.doctor?.name ?? "Doctor",
                              appointmentId: appointment.id,
                              doctorId: appointment.doctorId,
                              patientId: currentUserId.toString(),
                            )));
              },
            ),
            if (appointment.status != AppointmentStatus.completed)
              _buildOptionItem(
                context,
                icon: Icons.videocam_outlined,
                assetPath: "assets/Icons/video.png",
                iconSize: 24,
                title: "Video Call",
                subtitle: "Join the virtual waiting room",
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet first
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WaitingRoomView(
                                callTargetName: appointment.doctor?.name,
                                isDoctor: false,
                                appointmentId: appointment.id,
                              )));
                },
              ),
            if (appointment.status != AppointmentStatus.completed)
              _buildOptionItem(
                context,
                icon: Icons.edit_calendar_outlined,
                title: "Reschedule",
                subtitle: "Change appointment date or time",
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _showRescheduleDialog(context);
                },
              ),
            // Confirm Session — for all appointments that are not already completed or cancelled
            if (appointment.status != AppointmentStatus.completed &&
                appointment.status != AppointmentStatus.cancelled)
              _buildOptionItem(
                context,
                icon: Icons.verified_rounded,
                title: "Confirm Session",
                subtitle: "Mark this visit as completed",
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _showConfirmSessionDialog(context);
                },
              ),

            if (appointment.status != AppointmentStatus.completed)
              _buildOptionItem(
                context,
                icon: Icons.cancel_outlined,
                title: "Cancel Appointment",
                subtitle: "Cancel this scheduled visit",
                color: Colors.red,
                showBorder: false,
                onTap: () {
                  Navigator.pop(context);
                  _showCancelDialog(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        bool isCancelling = false;
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Cancel Appointment?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Are you sure you want to cancel this appointment? This action cannot be undone.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCancelling
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text("Back"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCancelling
                              ? null
                              : () async {
                                  setState(() => isCancelling = true);

                                  final vm = Provider.of<AppointmentViewModel>(
                                      context,
                                      listen: false);
                                  bool success = await vm.cancelAppointment(
                                      appointment.id.toString(),
                                      "Patient requested cancellation");

                                  if (context.mounted) {
                                    setState(() => isCancelling = false);
                                    Navigator.pop(context); // Close dialog

                                    Utils.toastMessage(
                                        context,
                                        success
                                            ? "Appointment cancelled successfully"
                                            : "Failed to cancel appointment",
                                        isError: !success);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: isCancelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text("Yes, Cancel"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showRescheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Reschedule Appointment",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Select a new date and time for your appointment.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              // Placeholder for Date Picker
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text("Select Date",
                        style: TextStyle(color: Colors.grey.shade700)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Reschedule Request Sent")));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text("Confirm"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        bool isCompleting = false;
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Confirm Session",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Has this session been completed successfully?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCompleting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text("No"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCompleting
                              ? null
                              : () async {
                                  setState(() => isCompleting = true);

                                  final vm = Provider.of<AppointmentViewModel>(
                                      context,
                                      listen: false);
                                  bool success = await vm.completeAppointment(
                                      appointment.id.toString());

                                  if (context.mounted) {
                                    setState(() => isCompleting = false);
                                    Navigator.pop(context); // Close dialog

                                    Utils.toastMessage(
                                        context,
                                        success
                                            ? "Session confirmed successfully"
                                            : "Failed to confirm session",
                                        isError: !success);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: isCompleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text("Yes, Confirm"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showPrescriptionSheet(BuildContext context,
      {AppointmentModel? updatedAppointment}) {
    final ap = updatedAppointment ?? appointment;
    final rx = ap.prescription;
    final doctor = ap.doctor;
    final vitals = ap.vitals;
    final medications = rx?.items ?? [];
    final tests = rx?.tests ?? [];

    // Doctor avatar
    final photoUrl = doctor?.imageUrl ?? '';
    final doctorName = doctor?.name ?? 'Doctor';
    final specialty = doctor?.specialty ?? '';
    final initials = doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D';

    Widget avatar = CustomNetworkImage(
      imageUrl: photoUrl,
      width: 48,
      height: 48,
      shape: BoxShape.circle,
      placeholderName: doctorName,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(color: Colors.transparent)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Padding(
                padding: const EdgeInsets.only(right: 30, bottom: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black87),
                    ),
                  ),
                ),
              ),

              // Receipt card
              Container(
                width: MediaQuery.of(ctx).size.width * 0.92,
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.75),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.05)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10)
                                  ],
                                ),
                                child: avatar,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Dr. $doctorName",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B))),
                                    if (specialty.isNotEmpty)
                                      Text(specialty,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500)),
                                    Text(
                                      DateFormat('MMM dd, yyyy • hh:mm a')
                                          .format(ap.dateTime),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ap.type == AppointmentType.online
                                      ? 'Video'
                                      : 'In-Person',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Body ──
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reason
                              if (ap.reason != null &&
                                  ap.reason!.isNotEmpty) ...[
                                _buildRxSectionTitle("Reason for Visit"),
                                const SizedBox(height: 6),
                                Text(ap.reason!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Color(0xFF475569))),
                                const SizedBox(height: 16),
                                _buildRxDashedLine(),
                                const SizedBox(height: 16),
                              ],

                              // Diagnosis
                              if (rx?.diagnosis != null &&
                                  rx!.diagnosis!.isNotEmpty) ...[
                                _buildRxSectionTitle("Diagnosis"),
                                const SizedBox(height: 6),
                                Text(rx.diagnosis!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Color(0xFF475569))),
                                const SizedBox(height: 16),
                                _buildRxDashedLine(),
                                const SizedBox(height: 16),
                              ],

                              // Vitals
                              if (vitals != null) ...[
                                _buildRxSectionTitle("Vitals"),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      if (vitals['bpSystolic'] != null &&
                                          vitals['bpDiastolic'] != null)
                                        _buildRxVitalRow("Blood Pressure",
                                            "${vitals['bpSystolic']}/${vitals['bpDiastolic']} mmHg"),
                                      if (vitals['heartRate'] != null)
                                        _buildRxVitalRow("Heart Rate",
                                            "${vitals['heartRate']} bpm"),
                                      if (vitals['weightKg'] != null)
                                        _buildRxVitalRow("Weight",
                                            "${vitals['weightKg']} kg"),
                                      if (vitals['temperature'] != null)
                                        _buildRxVitalRow("Temperature",
                                            "${vitals['temperature']} °C",
                                            isLast: true),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildRxDashedLine(),
                                const SizedBox(height: 16),
                              ],

                              // Medications
                              if (medications.isNotEmpty) ...[
                                _buildRxSectionTitle("Medications"),
                                const SizedBox(height: 12),
                                ...medications.map((med) {
                                  final name =
                                      med['medicineName'] ?? med['name'] ?? '';
                                  final dosage =
                                      med['dosage']?.toString() ?? '';
                                  final frequency =
                                      med['frequency']?.toString() ?? '';
                                  final duration =
                                      med['duration']?.toString() ?? '';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FFFE),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withOpacity(0.1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                              Icons.medication_outlined,
                                              size: 16,
                                              color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(name,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF1E293B))),
                                              if (dosage.isNotEmpty ||
                                                  frequency.isNotEmpty)
                                                Text(
                                                  [
                                                    if (dosage.isNotEmpty)
                                                      dosage,
                                                    if (frequency.isNotEmpty)
                                                      frequency
                                                  ].join(' • '),
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF00897B),
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              if (duration.isNotEmpty)
                                                Text("Duration: $duration",
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Colors.grey[500])),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                                _buildRxDashedLine(),
                                const SizedBox(height: 16),
                              ],

                              // Tests
                              if (tests.isNotEmpty) ...[
                                _buildRxSectionTitle("Tests Required"),
                                const SizedBox(height: 12),
                                ...tests.map((test) {
                                  final testName =
                                      test['testName'] ?? test['name'] ?? '';
                                  final hasReport = test['reportUrl'] != null;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(testName,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF1E293B),
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                        const SizedBox(width: 12),
                                        hasReport
                                            ? const Icon(Icons.check_circle,
                                                size: 20,
                                                color: Color(0xFF00897B))
                                            : const Icon(
                                                Icons.radio_button_unchecked,
                                                size: 20,
                                                color: Colors.grey),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                                _buildRxDashedLine(),
                                const SizedBox(height: 16),
                              ],

                              // Doctor's Notes
                              if (rx?.notes != null &&
                                  rx!.notes!.isNotEmpty) ...[
                                _buildRxSectionTitle("Doctor's Notes"),
                                const SizedBox(height: 6),
                                Text(rx.notes!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Color(0xFF475569))),
                              ],

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Download + Share buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRxActionButton(Icons.download_rounded, () {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text("Downloading prescription...")),
                      );
                    }),
                    const SizedBox(width: 20),
                    _buildRxActionButton(Icons.share_rounded, () {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text("Sharing prescription...")),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRxSectionTitle(String title) {
    return Row(
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF00BFA5), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildRxActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildRxVitalRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildRxDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
              dashCount,
              (_) => Container(
                    width: dashWidth,
                    height: 1,
                    color: Colors.grey.shade200,
                  )),
        );
      },
    );
  }

  Widget _buildMedicineItem(
      String name, String qty, String instructions, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.4)),
                                const SizedBox(height: 4),
                                Text(instructions,
                                    style: TextStyle(
                                        color: const Color(0xFF64748B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(qty,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF334155))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.timer_rounded,
                                size: 14, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            duration,
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w900),
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
    );
  }

  Widget _buildTestItem(String name, String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.biotech_rounded,
                color: Color(0xFF475569), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(reason,
                    style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? assetPath,
    double iconSize = 20,
    bool showBorder = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(bottom: BorderSide(color: Colors.grey.shade100))
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: assetPath != null
                  ? Image.asset(assetPath,
                      color: color, width: iconSize, height: iconSize)
                  : Icon(icon, color: color, size: iconSize),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusBg = AppColors.secondary.withOpacity(0.1);
    Color statusColor = AppColors.primary;
    String statusText = "Upcoming";

    final bool isDone = appointment.status == AppointmentStatus.completed;
    final bool isCancelled = appointment.status == AppointmentStatus.cancelled;

    if (isDone) {
      statusBg = Colors.green.withOpacity(0.1);
      statusColor = Colors.green;
      statusText = "Completed";
    } else if (appointment.status == AppointmentStatus.cancelled) {
      statusBg = Colors.red.withOpacity(0.1);
      statusColor = Colors.red;
      statusText = "Cancelled";
    } else if (appointment.status == AppointmentStatus.unconfirmed) {
      statusBg = Colors.orange;
      statusColor = Colors.white;
      statusText = "Unconfirmed";
    }

    return GestureDetector(
      onTap: isCancelled ? null : () => _showAppointmentOptions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Doctor Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      appointment.doctor?.imageUrl ??
                          'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctor?.name ?? "Doctor",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.doctor?.specialty ?? "Specialist",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 14,
                              color: AppColors.primary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a')
                                .format(appointment.dateTime),
                            style: TextStyle(
                                color: AppColors.primary.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge or 3-dots
                if (isDone || isCancelled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          (isDone ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isDone ? "Completed" : "Cancelled",
                      style: GoogleFonts.inter(
                        color: isDone ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _showAppointmentOptions(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.more_vert_rounded,
                          size: 20, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),

            // Bottom Actions ONLY if enabled and upcoming
            if (showConfirmationActions &&
                !isDone &&
                appointment.status == AppointmentStatus.unconfirmed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showPrescriptionSheet(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: Colors.grey.shade300),
                        foregroundColor: Colors.grey.shade700,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text("See Prescription",
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showConfirmSessionDialog(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: AppColors.primary),
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text("Confirm Session",
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
