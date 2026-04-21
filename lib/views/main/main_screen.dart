import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient App/home/home_view.dart';
import 'package:medlink/views/Patient App/appointment/appointment_list_view.dart';
import 'package:medlink/views/Patient App/profile/profile_view.dart';
import 'package:medlink/views/Patient App/health/health_hub_view.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/Patient App/emergency/ambulance_tracking_view.dart';
import 'package:medlink/views/call/call_view_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/services/call_socket_service.dart';
import 'package:medlink/views/call/call_screen.dart';
import 'package:medlink/services/appointment_socket_service.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/core/constants/sos_constants.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  StreamSubscription? _incomingCallSub;
  StreamSubscription? _callEndedSub;
  StreamSubscription? _appointmentSub;
  StreamSubscription? _emergencyToastSub;
  Map<String, dynamic>? _pendingIncomingCall;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Check for active SOS session on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emergencyVM =
          Provider.of<EmergencyViewModel>(context, listen: false);
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      final appointmentVM =
          Provider.of<AppointmentViewModel>(context, listen: false);

      emergencyVM.checkActiveSos();
      final token = userVM.accessToken;
      final patientIdStr = (userVM.patient?.id ?? '').trim();
      final patientIdNum = int.tryParse(patientIdStr);

      if (token != null &&
          token.isNotEmpty &&
          patientIdStr.isNotEmpty) {
        emergencyVM.startRealtime(
            patientUserId: patientIdStr, token: token);

        _emergencyToastSub?.cancel();
        _emergencyToastSub = emergencyVM.toastStream.listen((t) {
          if (!mounted) return;
          Utils.toastMessage(context, t.message, isError: t.isError);
        });

        // Initial load
        appointmentVM.loadUpcomingAppointments();

        // Connect to Appointment Socket
        final appointmentSocket =
            Provider.of<AppointmentSocketService>(context, listen: false);
        appointmentSocket.connect(url: AppUrl.baseUrl, token: token);
        _appointmentSub = appointmentSocket.appointmentUpdateStream.listen((_) {
          debugPrint('[MainScreen] Appointment update received! Refreshing...');
          appointmentVM.loadUpcomingAppointments();
        });

        // Connect to dedicated Call Socket
        final callSocket =
            Provider.of<CallSocketService>(context, listen: false);
        if (patientIdNum != null) {
          callSocket.connect(token: token, userId: patientIdNum);
        }

        // Listen for real-time incoming calls via Socket
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
      debugPrint('[MainScreen] Incoming call skipped — already active');
      return;
    }
    setState(() => _pendingIncomingCall = Map<String, dynamic>.from(data));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _incomingCallSub?.cancel();
    _callEndedSub?.cancel();
    _appointmentSub?.cancel();
    _emergencyToastSub?.cancel();
    super.dispose();
  }

  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomeView(),
    const AppointmentListView(), // Swapped to index 1
    const HealthHubView(), // Swapped to index 2
    const ProfileView(),
  ];
  final List<Widget?> _loadedPages = List.filled(4, null);

  @override
  Widget build(BuildContext context) {
    // Check if provider exists above, if not, consuming might fail if MainScreen is root.
    // Assuming MultiProvider is at app root.
    final emergencyVM = Provider.of<EmergencyViewModel>(context);

    // Lazy load the current page
    if (_loadedPages[_selectedIndex] == null) {
      _loadedPages[_selectedIndex] = _pages[_selectedIndex];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Main Content (Lazy loaded IndexedStack)
          IndexedStack(
            index: _selectedIndex,
            children: _loadedPages
                .map((page) => page ?? const SizedBox.shrink())
                .toList(),
          ),

          if (_pendingIncomingCall != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _buildIncomingCallBanner(_pendingIncomingCall!),
            ),

          // 3. Floating SOS Status (Fixed Position above Navbar)
          if (emergencyVM.isSosActive)
            Positioned(
              left: 16,
              right: 16,
              bottom: 115,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (emergencyVM.sosStatus == 'EXPIRED') {
                        Utils.toastMessage(
                          context,
                          emergencyVM.canRetrySearch
                              ? 'Tap Try again to search for a driver.'
                              : (emergencyVM.noDriverFoundMessage ??
                                  SosConstants.noAmbulanceDriverMessage),
                        );
                        return;
                      }
                      if (emergencyVM.assignedAmbulance != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AmbulanceTrackingView(
                                ambulance: emergencyVM.assignedAmbulance!),
                          ),
                        );
                      } else {
                        Utils.toastMessage(
                          context,
                          "Finding Driver... Please wait.",
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          topRight: Radius.circular(60),
                          bottomRight: Radius.circular(60),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      emergencyVM.sosEtaText,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        color: const Color(0xFF1E293B),
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      emergencyVM.sosTitle,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      emergencyVM.sosStatus == 'EXPIRED'
                                          ? (emergencyVM.canRetrySearch
                                              ? 'Tap Try again below to search again.'
                                              : 'This search window has ended.')
                                          : (emergencyVM.assignedAmbulance !=
                                                  null
                                              ? 'Tap to track live location'
                                              : 'Finding a nearby ambulance…'),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Builder(builder: (context) {
                                final expired =
                                    emergencyVM.sosStatus == 'EXPIRED';
                                final frac =
                                    emergencyVM.searchWindowProgressFraction;
                                final ringValue = expired
                                    ? 0.0
                                    : (frac != null
                                        ? (1.0 - frac).clamp(0.0, 1.0)
                                        : null);
                                final ringColor = expired
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFFEF4444);
                                return SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: expired
                                              ? const Color(0xFFF1F5F9)
                                              : const Color(0xFFFEF2F2),
                                        ),
                                      ),
                                      Transform.rotate(
                                        angle: -1.5,
                                        child: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: CircularProgressIndicator(
                                            value: ringValue,
                                            strokeWidth: 6,
                                            backgroundColor: Colors.transparent,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    ringColor),
                                            strokeCap: StrokeCap.round,
                                          ),
                                        ),
                                      ),
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: 0.9 +
                                                (_pulseController.value *
                                                    0.1),
                                            child: Image.asset(
                                              "assets/ambulance_marker.png",
                                              width: 28,
                                              height: 28,
                                              errorBuilder: (c, e, s) =>
                                                  Icon(
                                                Icons.medical_services_rounded,
                                                color: ringColor,
                                                size: 24,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                          if (emergencyVM.sosStatus == 'EXPIRED' &&
                              emergencyVM.canRetrySearch) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () =>
                                    emergencyVM.retrySosSearch(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Try again',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Close Button
                  Positioned(
                    top: -16,
                    right: -8,
                    child: GestureDetector(
                      onTap: () {
                        emergencyVM.cancelSos();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Floating Custom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30, // Floats above bottom
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35), // Pill shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.grid_view_rounded,
                      Icons.grid_view_outlined, "Home"),
                  _buildNavItem(1, Icons.calendar_month_rounded,
                      Icons.calendar_today_outlined, "Appointments"), // Index 1
                  _buildNavItem(2, Icons.health_and_safety_rounded,
                      Icons.health_and_safety_outlined, "Health"), // Index 2
                  _buildNavItem(
                      3, Icons.person_rounded, Icons.person_outline, "Profile"),
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
                      recipientName: payload['callerName'] ?? 'Caller',
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

  Widget _buildNavItem(
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
        child: Row(
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
                  fontWeight: FontWeight.w500,
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
