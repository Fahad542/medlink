import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/widgets/appointment_info_card.dart';
import 'package:medlink/widgets/no_data_widget.dart';
// import 'package:medlink/viewmodels/auth_viewmodel.dart'; // To get userId

class MyAppointmentsView extends StatefulWidget {
  final String patientId; // Pass patientId when navigating to this view

  const MyAppointmentsView({Key? key, required this.patientId})
      : super(key: key);

  @override
  State<MyAppointmentsView> createState() => _MyAppointmentsViewState();
}

class _MyAppointmentsViewState extends State<MyAppointmentsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchAppointmentsForTab(_tabController.index);
      }
    });

    // Initial fetch for the first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppointmentsForTab(0);
    });
  }

  void _fetchAppointmentsForTab(int index) {
    final viewModel = Provider.of<AppointmentViewModel>(context, listen: false);
    String status = 'upcoming';
    if (index == 1) status = 'past';
    if (index == 2) status = 'cancelled';

    viewModel.fetchAppointments(widget.patientId, status: status);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Appointments',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<AppointmentViewModel>(
        builder: (context, viewModel, child) {
          return TabBarView(
            controller: _tabController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildAppointmentList(viewModel.upcomingAppointments, 'upcoming',
                  viewModel.isLoading),
              _buildAppointmentList(
                  viewModel.pastAppointments, 'past', viewModel.isLoading),
              _buildAppointmentList(viewModel.cancelledAppointments,
                  'cancelled', viewModel.isLoading),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentList(
      List<AppointmentModel> appointments, String type, bool isLoading) {
    if (isLoading && appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointments.isEmpty) {
      return NoDataWidget(
        title: 'No ${type.capitalize()} Appointments',
        subTitle: "You have no ${type.toLowerCase()} appointments right now.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      key: ValueKey("${type}_${appointments.length}"),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentInfoCard(appointment: appointment);
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
