import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:medlink/widgets/custom_app_bar_widget.dart';

import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_profile_view.dart';
import 'package:medlink/widgets/appointment_info_card.dart';
import 'package:medlink/widgets/appointment_list_shimmer.dart';

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
      appBar: CustomAppBar(
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
              controller: _tabController,
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
              labelStyle:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Past"), // Renamed from Completed
                Tab(text: "Canceled"),
              ],
            ),
          ),
        ),
      ),
      body: appointmentVM.isLoading
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
                    child: _buildAppointmentList(appointmentVM.pastAppointments,
                        "No past appointments")),
                RefreshIndicator(
                    onRefresh: () => _fetchAppointmentsForTab(2),
                    child: _buildAppointmentList(
                        appointmentVM.cancelledAppointments,
                        "No canceled appointments")),
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
        return _buildAppointmentCard(context, appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context, AppointmentModel appointment) {
    return AppointmentInfoCard(
        appointment: appointment, showConfirmationActions: true);
  }
}
