import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Ambulance/Dashboard/ambulance_dashboard_view.dart';
import 'package:medlink/views/Ambulance/history/ambulance_history_view.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_profile_view.dart';
import 'package:medlink/views/Ambulance/profile/ambulance_earnings_view.dart';
import 'package:medlink/views/Ambulance/Ambulance%20main/ambulance_main_view_model.dart';
import 'package:medlink/views/call/call_view_model.dart';
import 'package:medlink/views/Ambulance/Mission/ambulance_mission_view.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/services/call_socket_service.dart';
import 'package:medlink/views/call/call_screen.dart';
import 'package:medlink/views/call/incoming_call_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class AmbulanceMainView extends StatefulWidget {
  const AmbulanceMainView({super.key});

  @override
  State<AmbulanceMainView> createState() => _AmbulanceMainViewState();
}

class _AmbulanceMainViewState extends State<AmbulanceMainView>
    with SingleTickerProviderStateMixin {
  late final AmbulanceMainViewModel _viewModel;
  late AnimationController _pulseController;
  StreamSubscription? _incomingCallSub;

  @override
  void initState() {
    super.initState();
    _viewModel = AmbulanceMainViewModel();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Provider.of<CallViewModel>(context, listen: false).startPolling(context);
      _viewModel.checkActiveTrip();
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      final token = userVM.accessToken;
      final driverId = int.tryParse(userVM.driver?.id ?? '');
      if (token != null && token.isNotEmpty && driverId != null) {
        _viewModel.startRealtime(userId: driverId, token: token);

        // Connect to dedicated Call Socket
        final callSocket =
            Provider.of<CallSocketService>(context, listen: false);
        callSocket.connect(token: token, userId: driverId);

        // Listen for real-time incoming calls via Socket
        _incomingCallSub = callSocket.incomingCallStream.listen((data) {
          _handleSocketIncomingCall(data);
        });
      }
    });
  }

  void _handleSocketIncomingCall(Map<String, dynamic> data) {
    if (!mounted) return;
    // Prevent duplicate incoming call screen if polling already showed one
    if (CallViewModel.isIncomingCallActive) {
      debugPrint('[AmbulanceMainView] Incoming call skipped — already active');
      return;
    }

    final callerId = data['callerId'] is int
        ? data['callerId'] as int
        : int.tryParse(data['callerId']?.toString() ?? '');

    CallViewModel.isIncomingCallActive = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callerName: data['callerName'] ?? 'Unknown Caller',
          callerPhoto: data['callerPhoto'],
          channelName: data['channelName'],
          token: data['token'],
          appId: data['appId'],
          callerId: callerId,
          onDecline: () {},
        ),
      ),
    ).then((result) {
      CallViewModel.isIncomingCallActive = false;
      if (result == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              channelName: data['channelName'],
              token: data['token'],
              appId: data['appId'],
              recipientName: data['callerName'] ?? 'Caller',
              recipientPhoto: data['callerPhoto'],
              isCaller: false,
              recipientId: callerId,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<AmbulanceMainViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9), // Match Patient App
            body: Stack(
              children: [
                // 1. Main Content
                IndexedStack(
                  index: viewModel.currentIndex,
                  children: const [
                    AmbulanceDashboardView(),
                    AmbulanceEarningsView(),
                    AmbulanceHistoryView(),
                    AmbulanceProfileView(),
                  ],
                ),

                if (viewModel.hasActiveTrip)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 115,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AmbulanceMissionView(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    viewModel.activeTripEtaText,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      color: const Color(0xFF1E293B),
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    viewModel.activeTripTitle,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to open mission',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFEF2F2),
                                    ),
                                  ),
                                  Transform.rotate(
                                    angle: -1.5,
                                    child: const SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                        value: 0.75,
                                        strokeWidth: 6,
                                        backgroundColor: Colors.transparent,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFFEF4444),
                                        ),
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: 0.9 +
                                            (_pulseController.value * 0.1),
                                        child: const Icon(
                                          Icons.local_hospital_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 26,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        _buildNavItem(
                            context,
                            viewModel,
                            0,
                            Icons.grid_view_rounded,
                            Icons.grid_view_outlined,
                            "Home"),
                        _buildNavItem(
                            context,
                            viewModel,
                            1,
                            Icons.account_balance_wallet_rounded,
                            Icons.account_balance_wallet_outlined,
                            "Earnings"),
                        _buildNavItem(
                            context,
                            viewModel,
                            2,
                            Icons.history_rounded,
                            Icons.history_outlined,
                            "History"),
                        _buildNavItem(
                            context,
                            viewModel,
                            3,
                            Icons.person_rounded,
                            Icons.person_outline,
                            "Profile"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _incomingCallSub?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildNavItem(BuildContext context, AmbulanceMainViewModel viewModel,
      int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = viewModel.currentIndex == index;
    return GestureDetector(
      onTap: () {
        viewModel.setIndex(index);
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
