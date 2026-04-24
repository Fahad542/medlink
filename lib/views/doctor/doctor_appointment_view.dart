import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';
// Reuse existing view
import 'package:provider/provider.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
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
import 'package:medlink/widgets/consultation_type_badge.dart';
import 'package:medlink/widgets/appointment_schedule_rows.dart';
import 'package:medlink/widgets/appointment_reschedule_sheet.dart';
import 'package:medlink/widgets/appointment_cancel_reason_dialog.dart';
import 'package:medlink/services/notification_services.dart';
import 'package:medlink/services/appointment_socket_service.dart';

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
        backgroundColor: Colors.grey.shade50,
        appBar: CustomAppBar(
          automaticallyImplyLeading: showBackButton,
          title: "My Appointments",
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white.withOpacity(0.9),
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: "Upcoming"),
                  Tab(text: "Past"),
                  Tab(text: "Canceled"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
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
    );
  }

  Widget _buildAppointmentList(
      List<AppointmentModel> appointments, String emptyMessage) {
    if (appointments.isEmpty) {
      return NoDataWidget(
        title: emptyMessage,
        subTitle: "You have no appointments in this category.",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Reduced vertical padding
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
    Color statusBg = AppColors.secondary.withOpacity(0.1);
    Color statusColor = AppColors.secondary;
    String statusText = "Upcoming";

    final bool isUpcoming = appointment.isDoctorUpcomingSlot &&
        (appointment.status == AppointmentStatus.upcoming ||
        appointment.status == AppointmentStatus.pending ||
        appointment.status == AppointmentStatus.confirmed ||
        appointment.status == AppointmentStatus.rescheduled);
    final String patientName = appointment.user?.name ?? "Unknown Patient";
    final String patientInitials = patientName.isNotEmpty
        ? patientName.trim().split(' ').map((l) => l[0]).take(2).join()
        : "??";

    if (appointment.status == AppointmentStatus.completed) {
      statusBg = Colors.green.withOpacity(0.1);
      statusColor = Colors.green;
      statusText = "Completed";
    } else if (appointment.status == AppointmentStatus.cancelled) {
      statusBg = Colors.red.withOpacity(0.1);
      statusColor = Colors.red;
      statusText = "Cancelled";
    } else if (appointment.status == AppointmentStatus.pending) {
      statusBg = Colors.orange.withOpacity(0.1);
      statusColor = Colors.orange;
      statusText = "Pending";
    } else if (appointment.status == AppointmentStatus.confirmed) {
      statusBg = Colors.green.withOpacity(0.1);
      statusColor = Colors.green;
      statusText = "Confirmed";
    } else if (appointment.status == AppointmentStatus.rescheduled) {
      statusBg = Colors.blue.withOpacity(0.1);
      statusColor = Colors.blue;
      statusText = "Rescheduled";
    } else if (appointment.status == AppointmentStatus.unconfirmed) {
      statusBg = Colors.grey.withOpacity(0.1);
      statusColor = Colors.black;
      statusText = "Unconfirmed";
    } else {
      // Upcoming
      statusBg = AppColors.primary.withOpacity(0.1);
      statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Matches AppointmentInfoCard
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
          // Patient Info Row with Click Action
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final bool isDone =
                    appointment.status == AppointmentStatus.completed ||
                        appointment.prescription != null;

                if (isDone) {
                  // Show prescription detail for completed appointments or those with data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            SubmitConsultationView(appointment: appointment)),
                  );
                } else if (appointment.status == AppointmentStatus.cancelled) {
                  // Show patient history for cancelled appointments
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
                                  email: appointment.user?.email ??
                                      "patient@example.com",
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
                    content: Text(
                        'Approve or reject this booking using the actions below.',
                    ),
                  ));
                } else if (appointment.status == AppointmentStatus.confirmed ||
                    appointment.status == AppointmentStatus.upcoming ||
                    appointment.status == AppointmentStatus.rescheduled) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SubmitConsultationView(
                              appointment: appointment)),
                    );
                } else {
                  // For other statuses (cancelled, etc.)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text("Cannot start consultation for this visit")));
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Patient Image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[100],
                        backgroundImage:
                            (appointment.user?.profileImage != null &&
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
                                    fontSize: 16),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (appointment.reason != null &&
                                    appointment.reason!.trim().isNotEmpty)
                                ? appointment.reason!.trim()
                                : 'Consultation',
                            style: GoogleFonts.inter(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          AppointmentScheduleRows(
                              appointment: appointment, dense: true),
                          const SizedBox(height: 6),
                          ConsultationTypeBadge(
                              type: appointment.type, compact: true),
                        ],
                      ),
                    ),
                    if (isUpcoming)
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () =>
                            _showAppointmentActions(context, patientName),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          statusText,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (appointment.status == AppointmentStatus.pending) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _actionBusy
                        ? null
                        : () => _approveBooking(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _actionBusy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Approve',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _actionBusy
                        ? null
                        : () => _rejectBooking(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade800,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Approving only confirms the visit on your schedule. Your fee is credited when the patient marks the visit complete.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ),
          ],

          // Bottom Actions for Unconfirmed (Request Confirmation)

          if (appointment.status == AppointmentStatus.unconfirmed) ...[
            const SizedBox(height: 12),
            Container(
                width: double.infinity, height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "Confirmation request sent to ${appointment.user?.name ?? 'patient'}")));
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: AppColors.primary.withOpacity(0.05),
                      ),
                      child: Text("Request Confirmation",
                          style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
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
              assetPath: "assets/Icons/chat.png",
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
              onTap: () async {
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

                showDialog<void>(
                  context: cardContext,
                  barrierDismissible: false,
                  useRootNavigator: true,
                  builder: (_) => Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          SizedBox(width: 16),
                          Text('Cancelling appointment…'),
                        ],
                      ),
                    ),
                  ),
                );

                var success = false;
                try {
                  success =
                      await apptVm.cancelAppointment(appointment.id, reason);
                } catch (e) {
                  debugPrint("Error during cancellation: $e");
                } finally {
                  if (cardContext.mounted) {
                    Navigator.of(cardContext, rootNavigator: true).pop();
                  }
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
          Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Colors.grey.shade300),
        ],
      ),
    ),
  );
}
