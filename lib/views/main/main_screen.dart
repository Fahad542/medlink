import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient App/home/home_view.dart';
import 'package:medlink/views/Patient%20App/Find%20a%20doctor/doctor_list_view.dart';
import 'package:medlink/views/Patient App/appointment/appointment_list_view.dart';
import 'package:medlink/views/Patient App/profile/profile_view.dart';
import 'package:medlink/views/Patient App/health/health_hub_view.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/Patient App/emergency/ambulance_tracking_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;
  List<Widget> _pages = [
    const HomeView(),
    const AppointmentListView(), // Swapped to index 1
    const HealthHubView(),       // Swapped to index 2
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Check if provider exists above, if not, consuming might fail if MainScreen is root. 
    // Assuming MultiProvider is at app root.
    final emergencyVM = Provider.of<EmergencyViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Main Content
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
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
                      if (emergencyVM.assignedAmbulance != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AmbulanceTrackingView(
                                ambulance: emergencyVM.assignedAmbulance!),
                          ),
                        );
                      }
                    },
                    child: Container(
                      // height: 100, // Removed fixed height
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                          // LEFT: Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Time Headline
                                Text(
                                  emergencyVM.assignedAmbulance != null
                                      ? emergencyVM.assignedAmbulance!.estimatedArrival
                                      : "Calculating...",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22, // Big & Bold
                                    color: const Color(0xFF1E293B),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Status Title
                                Text(
                                  "Ambulance Dispatched",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Subtitle / Hint
                                Text(
                                  "Tap to track live location",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // RIGHT: Circular Graphic (Progress Ring + Icon)
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                 // Background Circle
                                Container(
                                  width: 60, height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFEF2F2), // Very Light Red
                                  ),
                                ),
                                // Spinning/Static Partial Ring
                                Transform.rotate(
                                  angle: -1.5, // Rotate to start from top/right roughly
                                  child: SizedBox(
                                    width: 50, height: 50,
                                    child: CircularProgressIndicator(
                                      value: 0.75, // 75% circle like image
                                      strokeWidth: 6,
                                      backgroundColor: Colors.transparent,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)), // Red
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                ),
                                // Center Icon
                                 AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 0.9 + (_pulseController.value * 0.1),
                                      child: Image.asset("assets/ambulance_marker.png", width: 28, height: 28, errorBuilder: (c,e,s) => const Icon(Icons.medical_services_rounded, color: Color(0xFFEF4444), size: 24)), 
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
                          border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
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
                  _buildNavItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined, "Home"),
                  _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_today_outlined, "Appointments"), // Index 1
                  _buildNavItem(2, Icons.health_and_safety_rounded, Icons.health_and_safety_outlined, "Health"), // Index 2
                  _buildNavItem(3, Icons.person_rounded, Icons.person_outline, "Profile"),
                ],
              ),
            ),
          ),
        ],
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
