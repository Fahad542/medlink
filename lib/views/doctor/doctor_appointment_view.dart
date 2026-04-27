import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';
// Reuse existing view
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';

import 'package:medlink/views/doctor/Consultation/submit_consultation_view.dart';
import '../../models/user_model.dart';
import 'package:medlink/views/doctor/past_appointments_view.dart';
import 'package:medlink/views/doctor/past_appointments_view_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:medlink/widgets/appointment_list_shimmer.dart';
import 'package:medlink/widgets/appointment_reschedule_sheet.dart';
import 'package:medlink/widgets/appointment_cancel_reason_dialog.dart';
import 'package:medlink/services/notification_services.dart';
import 'package:medlink/services/appointment_socket_service.dart';
import 'package:intl/intl.dart';

class DoctorAppointmentView extends StatelessWidget {
  final bool showBackButton;
  const DoctorAppointmentView({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final docApptVM = Provider.of<DoctorAppointmentsViewModel>(context);

    final upcoming = docApptVM.upcomingAppointments;
    final completed = docApptVM.pastAppointments;
    final cancelled = docApptVM.cancelledAppointments;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            _buildTopHeader(context),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(
                    onRefresh: () => docApptVM.fetchAllAppointments(),
                    child: docApptVM.isLoading
                        ? const AppointmentListShimmer(itemCount: 6)
                        : _buildAppointmentList(upcoming, "No upcoming visits"),
                  ),
                  RefreshIndicator(
                    onRefresh: () => docApptVM.fetchAllAppointments(),
                    child: docApptVM.isLoading
                        ? const AppointmentListShimmer(itemCount: 6)
                        : _buildAppointmentList(completed, "No past visits"),
                  ),
                  RefreshIndicator(
                    onRefresh: () => docApptVM.fetchAllAppointments(),
                    child: docApptVM.isLoading
                        ? const AppointmentListShimmer(itemCount: 6)
                        : _buildAppointmentList(cancelled, "No cancelled visits"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF01917C), Color(0xFF0C9F8B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              Expanded(
                child: Text(
                  "My Appointments",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (showBackButton) const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TabBar(
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: Color(0xD9FFFFFF),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: "Upcoming"),
                Tab(text: "Past"),
                Tab(text: "Canceled"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(
      List<AppointmentModel> appointments, String emptyMessage) {
    if (appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 420,
            child: NoDataWidget(
              title: emptyMessage,
              subTitle: "You have no appointments in this category.",
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return DoctorAppointmentCard(appointment: appointments[index]);
        //   GestureDetector(
        //   onTap: () {
        //      // Go to "See Details"
        //      Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => AppointmentDetailsEditView(appointment: appointments[index]),
        //       ),
        //     );
        //   },
        //   child: DoctorAppointmentCard(appointment: appointments[index]),
        // );
      },
    );
  }
}

class DoctorAppointmentCard extends StatefulWidget {
  final AppointmentModel appointment;

  const DoctorAppointmentCard({super.key, required this.appointment});

  @override
  State<DoctorAppointmentCard> createState() => _DoctorAppointmentCardState();
}

class _DoctorAppointmentCardState extends State<DoctorAppointmentCard> {
  bool _actionBusy = false;

  AppointmentModel get appointment => widget.appointment;

  Future<void> _approveBooking(BuildContext context) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final vm =
          Provider.of<DoctorAppointmentsViewModel>(context, listen: false);
      final ok = await vm.approveAppointment(appointment.id);
      if (!context.mounted) return;
      try {
        Provider.of<DoctorDashboardViewModel>(context, listen: false)
            .fetchData();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? 'Booking approved' : 'Could not approve. Try again.'),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _rejectBooking(BuildContext context) async {
    if (_actionBusy) return;
    final reason = await showAppointmentCancelReasonDialog(
      context,
      title: 'Reject this booking?',
      subtitle:
          'The patient will be notified. Please give a short reason (at least 3 characters).',
    );
    if (!context.mounted || reason == null) return;
    setState(() => _actionBusy = true);
    try {
      final vm =
          Provider.of<DoctorAppointmentsViewModel>(context, listen: false);
      final dashVM = Provider.of<DoctorDashboardViewModel>(context, listen: false);
      final ok = await vm.rejectPatientBooking(appointment.id, reason: reason);
      if (!context.mounted) return;
      if (ok) {
        try {
          AppointmentSocketService.instance
              .emitAfterCancellation(appointment.id);
          dashVM.removeUpcomingAppointmentById(appointment.id);
          await dashVM.fetchData();
        } catch (_) {}
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            ok ? 'Booking rejected' : 'Could not reject. Try again.'),
        backgroundColor: ok ? Colors.orange.shade800 : Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUpcoming = appointment.isDoctorUpcomingSlot &&
        (appointment.status == AppointmentStatus.upcoming ||
        appointment.status == AppointmentStatus.pending ||
        appointment.status == AppointmentStatus.confirmed ||
        appointment.status == AppointmentStatus.rescheduled);
    final String patientName = appointment.user?.name ?? "Unknown Patient";
    final String patientInitials = patientName.isNotEmpty
        ? patientName.trim().split(' ').map((l) => l[0]).take(2).join()
        : "??";
    final showCancelledBadge = appointment.status == AppointmentStatus.cancelled;
    final showCompletedBadge = appointment.status == AppointmentStatus.completed;
    final showInlineActions = appointment.status == AppointmentStatus.pending;
    final dateLabel =
        DateFormat('MMM d, h:mm a').format(appointment.displayScheduledStart);
    final dur = appointment.scheduledDurationLabel;
    final dateLine = dur != null ? '$dateLabel · $dur' : dateLabel;
    final subtitle = (appointment.reason != null &&
            appointment.reason!.trim().isNotEmpty)
        ? appointment.reason!.trim()
        : 'Consultation';
    final feeAmount = appointment.feeAmount ??
        (appointment.doctor?.consultationFee != null &&
                appointment.doctor!.consultationFee > 0
            ? appointment.doctor!.consultationFee
            : null);
    final currency = (appointment.currency != null &&
            appointment.currency!.trim().isNotEmpty)
        ? appointment.currency!.trim()
        : 'KES';
    final formattedFee = feeAmount != null
        ? ((feeAmount % 1 == 0)
            ? feeAmount.toInt().toString()
            : feeAmount.toStringAsFixed(2))
        : null;
    final completedPrimaryTextColor =
        showCompletedBadge ? const Color(0xFF6B7280) : const Color(0xFF1F2937);
    final completedSecondaryTextColor =
        showCompletedBadge ? const Color(0xFF9CA3AF) : const Color(0xFF71717A);
    final completedAccentColor =
        showCompletedBadge ? const Color(0xFF9CA3AF) : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final bool isDone =
              appointment.status == AppointmentStatus.completed ||
                  appointment.prescription != null;

          if (isDone) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SubmitConsultationView(appointment: appointment)),
            );
          } else if (appointment.status == AppointmentStatus.cancelled) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                        create: (_) => PastAppointmentsViewModel(),
                        child: PastAppointmentsView(
                          patient: UserModel(
                            id: appointment.user?.id ?? "mock_id",
                            name: appointment.user?.name ?? patientName,
                            profileImage: appointment.user?.profileImage,
                            email:
                                appointment.user?.email ?? "patient@example.com",
                            phoneNumber: appointment.user?.phoneNumber ??
                                "+1 234 567 8900",
                            age: appointment.user?.age ?? 28,
                            role: appointment.user?.role ?? "patient",
                          ),
                        ),
                      )),
            );
          } else if (appointment.status == AppointmentStatus.pending) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Approve or reject this booking using the actions below.'),
            ));
          } else if (appointment.status == AppointmentStatus.confirmed ||
              appointment.status == AppointmentStatus.upcoming ||
              appointment.status == AppointmentStatus.rescheduled) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SubmitConsultationView(appointment: appointment)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Cannot start consultation for this visit")));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8EEF5),
                    backgroundImage: (appointment.user?.profileImage != null &&
                            appointment.user!.profileImage!.isNotEmpty)
                        ? NetworkImage(appointment.user!.profileImage!)
                        : null,
                    child: (appointment.user?.profileImage == null ||
                            appointment.user!.profileImage!.isEmpty)
                        ? Text(
                            patientInitials,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appointment.type.shortLabel} Consultation',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: completedAccentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: completedPrimaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: completedSecondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.watch_later_outlined,
                                size: 14, color: completedAccentColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: completedAccentColor,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showCancelledBadge)
                    _statusBadge(
                      label: 'Canceled',
                      foreground: AppColors.error,
                      background: AppColors.error.withValues(alpha: 0.12),
                    )
                  else if (showCompletedBadge)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/Icons/tick.png',
                          width: 30,
                          height: 30,
                          color: const Color(0xFF6B7280),
                        ),
                        if (formattedFee != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            '$formattedFee $currency',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ],
                    )
                  else if (isUpcoming)
                    IconButton(
                      onPressed: () => _showAppointmentActions(context, patientName),
                      icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                    )
                  else
                    _statusBadge(
                      label: appointment.status.name,
                      foreground: AppColors.primary,
                      background: AppColors.primary.withValues(alpha: 0.12),
                    ),
                ],
              ),

              if (showInlineActions) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed:
                              _actionBusy ? null : () => _approveBooking(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _actionBusy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Approve',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 30,
                        child: OutlinedButton(
                          onPressed:
                              _actionBusy ? null : () => _rejectBooking(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Reject',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (appointment.status == AppointmentStatus.unconfirmed) ...[
                const SizedBox(height: 12),
                Container(
                    width: double.infinity, height: 1, color: Colors.grey[100]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "Confirmation request sent to ${appointment.user?.name ?? 'patient'}")));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: AppColors.primary.withOpacity(0.05),
                    ),
                    child: Text("Request Confirmation",
                        style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: foreground,
            height: 1.15,
          ),
        ),
      ),
    );
  }

  void _showAppointmentActions(
      BuildContext cardContext, String patientName) {
    final userVM = Provider.of<UserViewModel>(cardContext, listen: false);
    final uId = userVM.loginSession?.data?.user?.id?.toString();
    final dId = userVM.doctor?.id;
    final currentUserId = (uId != null && uId.isNotEmpty) ? uId :
                          (dId != null && dId.isNotEmpty) ? dId : "0";
    showModalBottomSheet(
      context: cardContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
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
            if (appointment.status == AppointmentStatus.pending) ...[
              _appointmentBottomSheetActionItem(
                iconData: Icons.check_circle_outline_rounded,
                title: "Approve",
                subtitle:
                    "Confirm the visit on your schedule; payout when patient completes the visit",
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _approveBooking(cardContext);
                },
              ),
              _appointmentBottomSheetActionItem(
                iconData: Icons.cancel_outlined,
                title: "Reject",
                subtitle: "Decline this booking; patient is notified",
                color: Colors.red,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _rejectBooking(cardContext);
                },
              ),
            ],
            _appointmentBottomSheetActionItem(
              iconData: Icons.chat_bubble_outline_rounded,
              assetPath: "assets/Icons/chat-icon.png",
              iconSize: 18,
              title: "Message Patient",
              subtitle: "Start a chat related to this visit",
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                    cardContext,
                    MaterialPageRoute(
                        builder: (_) => ChatView(
                              recipientName: patientName,
                              profileImage: appointment.user?.profileImage ?? "",
                              appointmentId: appointment.id,
                              doctorId: currentUserId.toString(),
                              patientId: appointment.userId.toString(),
                            )));
              },
            ),
            _appointmentBottomSheetActionItem(
              iconData: Icons.videocam_outlined,
              assetPath: "assets/Icons/video.png",
              iconSize: 24,
              title: "Video Call",
              subtitle: "Start video consultation",
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                    cardContext,
                    MaterialPageRoute(
                        builder: (_) => WaitingRoomView(
                              callTargetName: patientName,
                              isDoctor: true,
                              appointmentId: appointment.id,
                            )));
              },
            ),
            if (AppointmentModel.doctorCanCancel(appointment.status))
              _appointmentBottomSheetActionItem(
              iconData: Icons.edit_calendar_outlined,
              title: "Reschedule",
              subtitle: "Change appointment date or time",
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(sheetContext);
                showAppointmentRescheduleSheet(
                  context: cardContext,
                  appointment: appointment,
                  isDoctorContext: true,
                  submit: (body) => ApiServices()
                      .doctorRescheduleAppointment(appointment.id, body),
                  onSuccess: () {
                    try {
                      Provider.of<DoctorAppointmentsViewModel>(cardContext,
                              listen: false)
                          .fetchUpcomingAppointments();
                      Provider.of<DoctorDashboardViewModel>(cardContext,
                              listen: false)
                          .fetchData();
                    } catch (_) {}
                  },
                );
              },
            ),
            if (AppointmentModel.doctorCanCancel(appointment.status) &&
                appointment.status != AppointmentStatus.pending)
              _appointmentBottomSheetActionItem(
              iconData: Icons.cancel_outlined,
              title: "Cancel Appointment",
              subtitle: "Cancel this scheduled visit",
              color: Colors.red,
              showBorder: false,
              isLoading: _actionBusy,
              onTap: () async {
                if (_actionBusy) return;
                Navigator.pop(sheetContext);

                final reason = await showAppointmentCancelReasonDialog(
                  cardContext,
                  title: 'Cancel appointment?',
                  subtitle:
                      'The patient will be notified. Please give a short reason for cancellation.',
                );
                if (!cardContext.mounted || reason == null) return;

                final apptVm = Provider.of<DoctorAppointmentsViewModel>(
                    cardContext,
                    listen: false);
                final dashVM = Provider.of<DoctorDashboardViewModel>(
                    cardContext,
                    listen: false);

                setState(() => _actionBusy = true);

                var success = false;
                try {
                  success =
                      await apptVm.cancelAppointment(appointment.id, reason);
                } catch (e) {
                  debugPrint("Error during cancellation: $e");
                } finally {
                  if (mounted) setState(() => _actionBusy = false);
                }

                if (!cardContext.mounted) return;

                if (success) {
                  AppointmentSocketService.instance
                      .emitAfterCancellation(appointment.id);
                  dashVM.removeUpcomingAppointmentById(appointment.id);
                  try {
                    await dashVM.fetchData();
                    final bannerBody = reason.length > 160
                        ? '${reason.substring(0, 157)}...'
                        : reason;
                    await NotificationServices.app?.showLocalBanner(
                      title: 'Appointment cancelled',
                      body: bannerBody,
                    );
                  } catch (e) {
                    debugPrint('Post-cancel refresh: $e');
                  }
                }

                if (!cardContext.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(cardContext).showSnackBar(const SnackBar(
                      content: Text("Appointment cancelled successfully")));
                } else {
                  ScaffoldMessenger.of(cardContext).showSnackBar(const SnackBar(
                      content: Text("Failed to cancel appointment")));
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

Widget _appointmentBottomSheetActionItem({
  required IconData iconData,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
  String? assetPath,
  double iconSize = 20,
  bool showBorder = true,
  bool isLoading = false,
}) {
  return InkWell(
    onTap: isLoading ? null : onTap,
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
                : Icon(iconData, color: color, size: iconSize),
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
          isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey.shade300),
        ],
      ),
    ),
  );
}
