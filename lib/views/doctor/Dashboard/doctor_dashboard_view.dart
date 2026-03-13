import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/doctor/Doctor%20earnings/doctor_earnings_view.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';
import 'package:medlink/views/doctor/doctor_chat_list_view.dart';
import 'package:medlink/views/doctor/doctor_chat_history_view_model.dart';
import 'package:medlink/views/doctor/doctor_appointment_view.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/doctor/appointment_details_edit_view.dart';

import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view_model.dart';
import 'package:medlink/views/doctor/Doctor%20patients/doctor_patients_view.dart';
import 'package:medlink/views/doctor/Patient%20history/patient_history_view.dart';
import 'package:medlink/views/Patient%20App/health/health_hub_view.dart';
import 'package:medlink/views/Patient%20App/consultation/chat_list_view.dart';
import 'package:medlink/widgets/custom_network_image.dart';
import 'package:medlink/widgets/appointment_list_shimmer.dart';
import 'package:medlink/views/doctor/past_appointments_view.dart';
import 'package:medlink/views/doctor/past_appointments_view_model.dart';
// ... other imports ...

class DoctorDashboardView extends StatelessWidget {
  const DoctorDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DoctorDashboardViewModel>(
      builder: (context, viewModel, child) {
          final userVM = Provider.of<UserViewModel>(context);
          final doctor = userVM.doctor;

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FB),
            body: RefreshIndicator(
              onRefresh: () => viewModel.fetchData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Stack(
                  children: [
                    // ... Header Background ...
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      child: Container(
                        height: 280,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Decorative Circles
                            Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 50,
                              left: -50,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Content
                    SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom App Bar Content (Greeting + Icons)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.5),
                                            width: 2),
                                      ),
                                      child: CustomNetworkImage(
                                        imageUrl: doctor?.imageUrl,
                                        placeholderName: doctor?.name,
                                        shape: BoxShape.circle,
                                        width: 42,
                                        height: 42,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Welcome back,",
                                          style: GoogleFonts.inter(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          doctor?.name ?? "Dr. Alex Smith",
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  ChangeNotifierProvider(
                                                    create: (_) =>
                                                        DoctorChatHistoryViewModel(),
                                                    child:
                                                        const DoctorChatListView(),
                                                  )),
                                        );
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.notifications_outlined,
                                                color: Colors.white,
                                                size: 20),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                "3",
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Total Earnings Section (Embedded in Header)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const DoctorEarningsView(
                                          showBackButton: true)),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                                color: Colors.white,
                                                size: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Total Earnings",
                                            style: GoogleFonts.inter(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Text("This Month",
                                                style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(width: 4),
                                            const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Colors.white,
                                                size: 14)
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  viewModel.isLoadingEarnings
                                      ? Shimmer.fromColors(
                                          baseColor:
                                              Colors.white.withOpacity(0.5),
                                          highlightColor: Colors.white,
                                          child: Container(
                                            height: 34,
                                            width: 120,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          "${viewModel.currency} ${viewModel.earnings}",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 28, // Large Hero Text
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                              height:
                                  20), // Reduced spacing slightly to ensure overlap

                          // 2. Stats Grid (Overlapping)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Patients",
                                    "${viewModel.patientsCount}",
                                    Icons.people_alt_outlined,
                                    Colors.blue,
                                    () {},
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    "Appointments",
                                    "${viewModel.appointmentsCount}",
                                    Icons.calendar_today_outlined,
                                    Colors.orange,
                                    () {},
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 3. Availability Toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.03), // Softer shadow
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: viewModel.isOnline
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.power_settings_new_rounded,
                                      color: viewModel.isOnline
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        viewModel.isOnline
                                            ? "Available for Booking"
                                            : "Currently Unavailable",
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        viewModel.isOnline
                                            ? "You are visible to patients"
                                            : "You are hidden from search",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: viewModel.isOnline,
                                      activeColor: Colors.white,
                                      activeTrackColor: Colors.green,
                                      inactiveThumbColor: Colors.white,
                                      inactiveTrackColor: Colors.grey[300],
                                      trackOutlineColor:
                                          WidgetStateProperty.all(
                                              Colors.transparent),
                                      onChanged: (val) =>
                                          viewModel.updateAvailability(val),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 4. Upcoming Appointments Section (Header + List)
                          Builder(
                            builder: (context) {
                              if (viewModel.isLoadingAppointments) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Upcoming Appointments",
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: null,
                                            child: const Text("See All",
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const AppointmentListShimmer(itemCount: 1),
                                  ],
                                );
                              }

                              final items = viewModel.upcomingAppointments;
                              if (items.isEmpty) {
                                return const SizedBox
                                    .shrink(); // Hide entire section if no appointments
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Upcoming Appointments",
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const DoctorAppointmentView(
                                                          showBackButton:
                                                              true)),
                                            );
                                          },
                                          child: const Text("See All"),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount:
                                        items.take(1).length, // Limit to 1
                                    itemBuilder: (context, index) {
                                      return _buildAppointmentCard(
                                          context, items[index]);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // 5. Quick Actions Grid
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                _buildSectionHeader("Quick Actions"),
                                const SizedBox(height: 16),
                                _buildQuickActionsGrid(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // Cleaner shadow
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                // Tiny trend indicator could go here
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "+2.5%",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context, AppointmentModel appointment) {
    return DoctorAppointmentCard(appointment: appointment);
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        "title": "Patients",
        "subtitle": "Manage records",
        "image": "assets/doctors.png",
        "color": const Color(0xFFCEE9F1),
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DoctorPatientsView(showBackButton: true))),
      },
      {
        "title": "History",
        "subtitle": "Patient records",
        "image": "assets/pres.png",
        "color": const Color(0xFFDCE8C0),
        "onTap": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                      create: (_) => PastAppointmentsViewModel(),
                      child: const PastAppointmentsView(title: "History"),
                    ))),
      },
      {
        "title": "Articles",
        "subtitle": "Health Hub",
        "image": "assets/tip.png",
        "color": const Color(0xFFFFEBD2),
        "onTap": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const HealthHubView(
                    showBackButton: true, isDoctor: true))),
      },
      {
        "title": "Appointments",
        "subtitle": "Schedule",
        "image": "assets/consult.png",
        "color": const Color(0xFFE3DBF2),
        "onTap": () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const DoctorAppointmentView(showBackButton: true))),
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];

        return InkWell(
          onTap: action['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: action['color'] as Color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        action['image'] as String,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action['title'] as String,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.2,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action['subtitle'] as String,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_outward_rounded,
                        size: 16, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
