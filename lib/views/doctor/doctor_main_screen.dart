import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view.dart';
import 'package:medlink/views/doctor/doctor_appointment_view.dart';
import 'package:medlink/views/doctor/doctor_settings_profile_view.dart';
import 'package:medlink/views/doctor/Doctor%20patients/doctor_patients_view.dart';
import 'package:medlink/views/doctor/Doctor%20patients/doctor_patients_view_model.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';
import 'package:medlink/views/doctor/Dashboard/doctor_dashboard_view_model.dart';
import 'package:provider/provider.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;
  
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

          // 2. Floating Custom Navigation Bar
          Positioned(
            left: 20, // Slightly more padding for a cleaner look with 3 items
            right: 20,
            bottom: 30,
            child: Container(
              height: 70,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Reduced padding
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              )
            : BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
