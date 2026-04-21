import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view.dart';
import 'package:medlink/views/doctor/doctor_appointment_view.dart';
import 'package:medlink/views/doctor/doctor_settings_profile_view.dart';
import 'package:medlink/views/doctor/Doctor%20patients/doctor_patients_view.dart';
import 'package:medlink/views/doctor/Doctor%20patients/doctor_patients_view_model.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view_model.dart';
import 'package:medlink/services/call_socket_service.dart';
import 'package:medlink/views/call/call_screen.dart';
import 'package:medlink/views/call/call_view_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/services/appointment_socket_service.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;
  StreamSubscription? _incomingCallSub;
  StreamSubscription? _callEndedSub;
  StreamSubscription? _appointmentSub;
  Map<String, dynamic>? _pendingIncomingCall;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      final token = userVM.accessToken;
      final doctorIdNum = int.tryParse(userVM.doctor?.id ?? '');
      

      if (token != null && token.isNotEmpty && doctorIdNum != null) {
        // Connect to Appointment Socket
        final appointmentSocket = Provider.of<AppointmentSocketService>(context, listen: false);
        appointmentSocket.connect(url: AppUrl.baseUrl, token: token);
        _appointmentSub = appointmentSocket.appointmentUpdateStream.listen((_) {
          debugPrint('[DoctorMainScreen] Appointment update received! Refreshing dashboard...');
          Provider.of<DoctorDashboardViewModel>(context, listen: false).fetchData();
          Provider.of<DoctorAppointmentsViewModel>(context, listen: false).fetchAllAppointments();
        });

        final callSocket = Provider.of<CallSocketService>(context, listen: false);
        callSocket.connect(token: token, userId: doctorIdNum);

        _incomingCallSub = callSocket.incomingCallStream.listen((data) {
          _handleSocketIncomingCall(data);
        });
        _callEndedSub = callSocket.callEndedStream.listen((channel) {
          final pending = _pendingIncomingCall;
          if (pending == null) return;
          if (pending['channelName']?.toString() == channel) {
            setState(() => _pendingIncomingCall = null);
          }
        });
      }
    });
  }

  void _handleSocketIncomingCall(Map<String, dynamic> data) {
    if (!mounted) return;
    if (CallViewModel.isIncomingCallActive) {
      debugPrint('[DoctorMainScreen] Incoming call skipped — already active');
      return;
    }
    setState(() => _pendingIncomingCall = Map<String, dynamic>.from(data));
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    _callEndedSub?.cancel();
    _appointmentSub?.cancel();
    super.dispose();
  }
  
  // Reuse existing views or placeholders where appropriate
  final List<Widget> _pages = [
    const DoctorDashboardView(),
    const DoctorAppointmentView(showBackButton: false), // Hide back button for Navbar Tab
    const DoctorPatientsView(),
    const DoctorSettingsProfileView(), // Updated to Doctor Specific Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Main Content
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          if (_pendingIncomingCall != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _buildIncomingCallBanner(_pendingIncomingCall!),
            ),

          // 2. Floating Custom Navigation Bar
          Positioned(
            left: 20, // Slightly more padding for a cleaner look with 3 items
            right: 20,
            bottom: 30,
            child: Container(
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Softer shadow
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined, "Home"),
                  _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_today_outlined, "Appointments"),
                  _buildNavItem(2, Icons.people_alt_rounded, Icons.people_alt_outlined, "Patients"),
                  _buildNavItem(3, Icons.person_rounded, Icons.person_outline, "Profile"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingCallBanner(Map<String, dynamic> data) {
    final callerId = data['callerId'] is int
        ? data['callerId'] as int
        : int.tryParse(data['callerId']?.toString() ?? '');
    final callerName = data['callerName']?.toString() ?? 'Incoming call';
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$callerName is calling — Join video call',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () async {
                final payload = _pendingIncomingCall;
                if (payload == null) return;
                setState(() => _pendingIncomingCall = null);
                CallViewModel.isIncomingCallActive = true;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(
                      channelName: payload['channelName'],
                      token: payload['token'],
                      appId: payload['appId'],
                      recipientName: payload['callerName'] ?? 'Patient',
                      recipientPhoto: payload['callerPhoto'],
                      isCaller: false,
                      recipientId: callerId,
                    ),
                  ),
                );
                CallViewModel.isIncomingCallActive = false;
              },
              child: const Text('Join'),
            ),
            IconButton(
              onPressed: () => setState(() => _pendingIncomingCall = null),
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        
        // Refresh dashboard data if the home tab is tapped
        if (index == 0) {
          Provider.of<DoctorDashboardViewModel>(context, listen: false).fetchData();
        }
        
        // Always fetch fresh appointments if the appointments tab is tapped
        if (index == 1) {
          Provider.of<DoctorAppointmentsViewModel>(context, listen: false).fetchAllAppointments();
        }
        
        // Lazy load patients if the patients tab is tapped
        if (index == 2) {
          Provider.of<DoctorPatientsViewModel>(context, listen: false).loadPatientsIfNotLoaded();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
