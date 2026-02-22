import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medlink/core/theme/app_theme.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/models/appointment_model.dart';
// import 'package:medlink/viewmodels/auth_viewmodel.dart'; // To get userId
import 'package:intl/intl.dart';

class MyAppointmentsView extends StatefulWidget {
  final String patientId; // Pass patientId when navigating to this view

  const MyAppointmentsView({Key? key, required this.patientId}) : super(key: key);

  @override
  State<MyAppointmentsView> createState() => _MyAppointmentsViewState();
}

class _MyAppointmentsViewState extends State<MyAppointmentsView> with SingleTickerProviderStateMixin {
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
        title: const Text('My Appointments', style: TextStyle(color: Colors.black)),
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
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(viewModel.upcomingAppointments, 'upcoming'),
              _buildAppointmentList(viewModel.pastAppointments, 'past'),
              _buildAppointmentList(viewModel.cancelledAppointments, 'cancelled'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentModel> appointments, String type) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No $type appointments',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(appointment.doctor?.imageUrl ?? 'https://i.pravatar.cc/150'), 
                    fit: BoxFit.cover,
                  ),
                  color: Colors.grey[200],
                ),
                child: appointment.doctor?.imageUrl == null || appointment.doctor!.imageUrl.isEmpty 
                    ? const Icon(Icons.person, color: Colors.grey) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctor?.name ?? 'Doctor Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                       "${appointment.doctor?.specialty ?? 'Specialty'} - ${appointment.doctor?.hospital ?? 'Hospital'}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                     const SizedBox(height: 4),
                     // Display Status if needed, but handled by tab usually
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: _getStatusColor(appointment.status).withOpacity(0.1),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(
                         appointment.status.toString().split('.').last.capitalize(),
                         style: TextStyle(
                           color: _getStatusColor(appointment.status),
                           fontSize: 10,
                           fontWeight: FontWeight.bold
                         ),
                       ),
                     )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(appointment.dateTime),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('hh:mm a').format(appointment.dateTime),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                   const Icon(Icons.circle, size: 8, color: Colors.green), // Online/Offline indicator?
                   const SizedBox(width: 4),
                   Text("Confirmed", style: TextStyle(color: Colors.grey[700], fontSize: 12)) 
                ]
              )
            ],
          ),
          // Add Buttons (Cancel / Reschedule) if it's Upcoming
          if (appointment.status == AppointmentStatus.upcoming) ...[
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton(
                     onPressed: () {},
                     child: const Text("Cancel"),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () {},
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       foregroundColor: Colors.white
                     ),
                     child: const Text("Reschedule"),
                   ),
                 ),
               ],
             )
          ]
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming: return Colors.blue;
      case AppointmentStatus.completed: return Colors.green;
      case AppointmentStatus.cancelled: return Colors.red;
      case AppointmentStatus.unconfirmed: return Colors.orange;
      default: return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
