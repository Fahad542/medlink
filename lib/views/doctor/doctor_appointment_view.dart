import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart'; // We can reuse this or create a doctor specific one if needed
// Reuse existing view
import 'package:provider/provider.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';


import '../../models/user_model.dart';
import 'package:medlink/views/doctor/past_appointments_view.dart';

import 'Doctor Patient Dashboard/appointment_detail_view.dart';

class DoctorAppointmentView extends StatelessWidget {
  final bool showBackButton;
  const DoctorAppointmentView({super.key, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final appointmentVM = Provider.of<AppointmentViewModel>(context);
    // In a real app, we would filter by doctor ID. For now, we assume the VM has the data.
    final upcoming = appointmentVM.appointments.where((a) => a.status == AppointmentStatus.upcoming).toList();
    final completed = appointmentVM.appointments.where((a) => a.status == AppointmentStatus.completed || a.status == AppointmentStatus.unconfirmed).toList();
    final cancelled = appointmentVM.appointments.where((a) => a.status == AppointmentStatus.cancelled).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: CustomAppBar(
          automaticallyImplyLeading: showBackButton,
          title: "My Appointments",
           bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50), // Reduced from 60
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), 
              height: 36, 
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Semi-transparent white container
                borderRadius: BorderRadius.circular(20), 
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white, // White indicator
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primary, // Selected text is Primary color
                unselectedLabelColor: Colors.white, // Unselected text is White

                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12), 
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
            _buildAppointmentList(upcoming, "No upcoming appointments"),
            _buildAppointmentList(completed, "No past appointments"),
            _buildAppointmentList(cancelled, "No canceled appointments"),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentModel> appointments, String emptyMessage) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today_rounded, size: 64, color: AppColors.primary.withOpacity(0.5)),
            ),
             const SizedBox(height: 16),
             Text(emptyMessage, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical padding
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return
          DoctorAppointmentCard(appointment: appointments[index]);
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

class DoctorAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const DoctorAppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    Color statusBg = AppColors.secondary.withOpacity(0.1);
    Color statusColor = AppColors.secondary; 
    String statusText = "Upcoming";


    final bool isUpcoming = appointment.status == AppointmentStatus.upcoming;
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
                if(appointment.status == AppointmentStatus.upcoming || appointment.status == AppointmentStatus.cancelled) {
                  Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PastAppointmentsView(patient: UserModel(
                              id: appointment.user?.id ?? "mock_id",
                              name: appointment.user?.name ?? patientName,
                              profileImage: appointment.user?.profileImage,
                              email: appointment.user?.email ?? "patient@example.com",
                              phoneNumber: appointment.user?.phoneNumber ?? "+1 234 567 8900",
                              age: appointment.user?.age ?? 28,
                              gender: appointment.user?.gender ?? "Female",
                              bloodGroup: appointment.user?.bloodGroup ?? "O+",
                            ),
                        )

                  ),
                );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AppointmentDetailView(title: "General Checkup", date: "12 Dec, 04:30 PM", reason: "Viral Infection"))
                            );



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
                        backgroundImage: appointment.user?.profileImage != null
                            ? NetworkImage(appointment.user!.profileImage!)
                            : const AssetImage("assets/images/user_placeholder.png") as ImageProvider, // Mock/Placeholder
                        child: appointment.user?.profileImage == null
                            ? Text(
                                patientInitials,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
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
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "General Checkup", // Placeholder for reason
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM d, h:mm a').format(appointment.dateTime), 
                                style: GoogleFonts.inter(color: AppColors.primary.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isUpcoming)
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () => _showAppointmentActions(context, appointment, patientName),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          
          // Bottom Actions for Upcoming (Cancel & Reschedule)

          if (appointment.status == AppointmentStatus.unconfirmed) ...[
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Confirmation request sent to ${appointment.user?.name ?? 'patient'}"))
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: AppColors.primary.withOpacity(0.05),
                      ),
                      child: Text("Request Confirmation", style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
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


  void _showAppointmentActions(BuildContext context, AppointmentModel appointment, String patientName) {
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
            _buildBSActionItem(
              context,
              iconData: Icons.chat_bubble_outline_rounded,
              assetPath: "assets/Icons/chat.png",
              iconSize: 18,
              title: "Message Patient",
              subtitle: "Start a chat related to this visit",
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatView(recipientName: patientName)));
              },
            ),
            _buildBSActionItem(
              context,
              iconData: Icons.videocam_outlined,
              assetPath: "assets/Icons/video.png",
              iconSize: 24,
              title: "Video Call",
              subtitle: "Start video consultation",
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingRoomView(callTargetName: patientName, isDoctor: true)));
              },
            ),
            _buildBSActionItem(
              context,
              iconData: Icons.edit_calendar_outlined,
              title: "Reschedule",
              subtitle: "Change appointment date or time",
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                // Reschedule logic
              },
            ),
            _buildBSActionItem(
              context,
              iconData: Icons.cancel_outlined,
              title: "Cancel Appointment",
              subtitle: "Cancel this scheduled visit",
              color: Colors.red,
              showBorder: false,
              onTap: () {
                Navigator.pop(context);
                // Cancel logic
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBSActionItem(
    BuildContext context, {
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
          border: showBorder ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
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
                  ? Image.asset(assetPath, color: color, width: iconSize, height: iconSize)
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
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

