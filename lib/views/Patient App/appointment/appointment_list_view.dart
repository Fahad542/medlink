import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
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

class AppointmentListView extends StatefulWidget {
  const AppointmentListView({super.key});

  @override
  State<AppointmentListView> createState() => _AppointmentListViewState();
}

class _AppointmentListViewState extends State<AppointmentListView> with SingleTickerProviderStateMixin {
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

  void _fetchAppointmentsForTab(int index) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      final viewModel = Provider.of<AppointmentViewModel>(context, listen: false);
      
      if (userVM.patient?.id == null) return;
      
      String status = 'upcoming';
      if (index == 1) status = 'past';
      if (index == 2) status = 'cancelled';
      
      viewModel.fetchAppointments(userVM.patient!.id, status: status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We'll filter real data for the tabs
    final appointmentVM = Provider.of<AppointmentViewModel>(context);
    final upcoming = appointmentVM.appointments.where((a) => a.status == AppointmentStatus.upcoming).toList();
    
    // Past appointments logic: dateTime < now AND NOT cancelled AND NOT upcoming
    final past = appointmentVM.appointments.where((a) => a.dateTime.isBefore(DateTime.now()) && a.status != AppointmentStatus.cancelled && a.status != AppointmentStatus.upcoming).toList();
    
    final cancelled = appointmentVM.appointments.where((a) => a.status == AppointmentStatus.cancelled).toList();

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
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
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
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList(upcoming, "No upcoming appointments"),
                _buildAppointmentList(past, "No past appointments"), // Using past list
                _buildAppointmentList(cancelled, "No canceled appointments"),
              ],
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
              child: Icon(Icons.event_note_rounded, size: 64, color: AppColors.primary.withOpacity(0.5)),
            ),
             const SizedBox(height: 16),
             Text(emptyMessage, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(context, appointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, AppointmentModel appointment) {
    return AppointmentInfoCard(appointment: appointment, showConfirmationActions: true);
  }
}
