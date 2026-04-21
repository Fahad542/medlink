import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medlink/widgets/appointment_list_shimmer.dart';
import 'package:medlink/widgets/appointment_info_card.dart';

class AppointmentListView extends StatefulWidget {
  const AppointmentListView({super.key});

  @override
  State<AppointmentListView> createState() => _AppointmentListViewState();
}

class _AppointmentListViewState extends State<AppointmentListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initial fetch for the first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppointmentsForTab(0);
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchAppointmentsForTab(_tabController.index);
      }
    });
  }

  Future<void> _fetchAppointmentsForTab(int index) async {
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final viewModel = Provider.of<AppointmentViewModel>(context, listen: false);

    if (userVM.patient?.id == null) return;

    String status = 'upcoming';
    if (index == 1) status = 'past';
    if (index == 2) status = 'cancelled';

    return viewModel.fetchAppointments(userVM.patient!.id, status: status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentVM = Provider.of<AppointmentViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: appointmentVM.isLoading
                ? const AppointmentListShimmer(itemCount: 6)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                          onRefresh: () => _fetchAppointmentsForTab(0),
                          child: _buildAppointmentList(
                              appointmentVM.upcomingAppointments,
                              "No upcoming appointments")),
                      RefreshIndicator(
                          onRefresh: () => _fetchAppointmentsForTab(1),
                          child: _buildAppointmentList(
                              appointmentVM.pastAppointments,
                              "No past appointments",
                              isPastTab: true)),
                      RefreshIndicator(
                          onRefresh: () => _fetchAppointmentsForTab(2),
                          child: _buildAppointmentList(
                              appointmentVM.cancelledAppointments,
                              "No canceled appointments",
                              isCancelledTab: true)),
                    ],
                  ),
          ),
        ],
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
          Text(
            "My Appointments",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
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
    List<AppointmentModel> appointments,
    String emptyMessage, {
    bool isPastTab = false,
    bool isCancelledTab = false,
  }) {
    if (appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
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
        return _buildAppointmentCard(
          context,
          appointments[index],
          isPastTab: isPastTab,
          showCancelBadge: isCancelledTab,
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    AppointmentModel appointment, {
    bool isPastTab = false,
    bool showCancelBadge = false,
  }) {
    final showCompletedBadge = !showCancelBadge &&
        (appointment.status == AppointmentStatus.completed ||
            (isPastTab &&
                appointment.status == AppointmentStatus.unconfirmed));
    final doctor = appointment.doctor;
    final doctorName = doctor?.name.isNotEmpty == true
        ? doctor!.name
        : "Unknown Doctor";
    final specialty = doctor?.specialty.isNotEmpty == true
        ? doctor!.specialty
        : "General";
    final profileImage = doctor?.imageUrl ?? '';
    final dateLabel =
        DateFormat('MMM d, h:mm a').format(appointment.displayScheduledStart);
    final dur = appointment.scheduledDurationLabel;
    final dateLine =
        dur != null ? '$dateLabel · $dur' : dateLabel;

    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE8EEF5),
            backgroundImage:
                profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
            child: profileImage.isEmpty
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF71717A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.watch_later_outlined,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showCancelBadge)
            _appointmentListStatusBadge(
              label: 'Canceled',
              foreground: AppColors.error,
              background: AppColors.error.withValues(alpha: 0.12),
            )
          else if (showCompletedBadge)
            _appointmentListStatusBadge(
              label: 'Completed',
              foreground: AppColors.success,
              background: AppColors.success.withValues(alpha: 0.14),
            )
          else
            IconButton(
              onPressed: () => AppointmentInfoCard(
                appointment: appointment,
                showConfirmationActions: true,
              ).showAppointmentOptions(context),
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _appointmentListStatusBadge({
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
}
