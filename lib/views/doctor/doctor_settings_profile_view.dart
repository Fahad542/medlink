import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';

import 'package:medlink/views/doctor/Doctor%20profile/doctor_personal_info_view.dart';
import 'package:medlink/views/doctor/Doctor%20earnings/doctor_earnings_view.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/delete_account_sheet.dart';
import 'package:medlink/widgets/logout_confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/models/doctor_model.dart';

class DoctorSettingsProfileView extends StatelessWidget {
  const DoctorSettingsProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    // For now mocking user data or getting from AuthVM if available
    // For now mocking user data or getting from AuthVM if available
    final userVM = Provider.of<UserViewModel>(context);
    final doctor = userVM.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7), // Light Gray background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Premium Header (Standard Widget)
            _buildHeader(doctor),

            // 2. Overlapping Content & Settings
            Transform.translate(
              offset: const Offset(0, -40), // Pull up to overlap header
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Vital Stats Row (Doctor Specific)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatItem(
                              label: "Experience",
                              value: doctor?.experience ?? "0",
                              unit: "Yrs"),
                          const _VerticalDivider(),
                          const _StatItem(
                              label: "Patients", value: "1.5k", unit: "Lives"),
                          const _VerticalDivider(),
                          _StatItem(
                              label: "Rating",
                              value: doctor?.rating.toString() ?? "0.0",
                              unit: "Star"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Grouped Settings
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            "DOCTOR SETTINGS",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildPremiumTile(
                                context,
                                icon: Icons.person_outline_rounded,
                                color: AppColors.primary,
                                title: "Personal Info",
                                subtitle: "Bio, Specialization & Fee",
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DoctorPersonalInfoView())),
                              ),
                              _buildDivider(),
                              _buildPremiumTile(
                                context,
                                icon: Icons.schedule_rounded,
                                color: AppColors.primary,
                                title: "Availability",
                                subtitle: "Working Hours & Days",
                                onTap: () {
                                  _showAvailabilityBottomSheet(context);
                                },
                              ),
                              _buildDivider(),
                              _buildPremiumTile(
                                context,
                                icon: Icons.language,
                                color: AppColors.primary,
                                title: "Localization",
                                subtitle: "Language & Region",
                                onTap: () {
                                  // TODO: Navigate to Localization Settings
                                },
                              ),
                              _buildDivider(),
                              _buildPremiumTile(
                                context,
                                icon: Icons.account_balance_wallet_outlined,
                                color: AppColors.primary,
                                title: "Consultation Earnings",
                                subtitle: "Check Balance & Transactions",
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DoctorEarningsView(
                                                showBackButton: true))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Logout Action
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => LogoutConfirmationDialog(
                              onLogout: () {
                                userVM.logout();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginView()),
                                  (route) => false,
                                );
                              },
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          // Border removed
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Log Out",
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Delete Account Action
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton(
                        onPressed: () {
                          DeleteAccountSheet.show(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_remove_rounded,
                                color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Delete Account",
                              style: GoogleFonts.inter(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DoctorModel? doctor) {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Decorative Patterns
            Positioned(
              top: -100,
              right: -50,
              child: CircleAvatar(
                radius: 130,
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),

            // Profile Content
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Image
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        backgroundImage: (doctor?.imageUrl != null &&
                                doctor!.imageUrl.isNotEmpty)
                            ? NetworkImage(doctor.imageUrl)
                            : null,
                        child: (doctor?.imageUrl == null ||
                                doctor!.imageUrl.isEmpty)
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctor?.name ?? "Dr. Alex Smith",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        (doctor?.specialty != null &&
                                doctor!.specialty.isNotEmpty)
                            ? doctor.specialty
                            : "Cardiologist",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 0,
      color: Colors.grey[100],
    );
  }

  void _showAvailabilityBottomSheet(BuildContext context) {
    // Get latest doctor data
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final doctor = userVM.doctor;

    double duration = 30; // Parsing from model if added later

    // Parse Availability Days
    Set<String> selectedDays =
        doctor?.availabilityDays.toSet() ?? {"Mon", "Tue", "Wed", "Thu", "Fri"};
    List<String> allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    // Parse Times (Simple string parsing "09:00 AM")
    TimeOfDay _parseTime(String timeStr) {
      try {
        final format = RegExp(r"(\d+):(\d+)\s+(AM|PM)");
        final match = format.firstMatch(timeStr);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          int minute = int.parse(match.group(2)!);
          String period = match.group(3)!;
          if (period == "PM" && hour != 12) hour += 12;
          if (period == "AM" && hour == 12) hour = 0;
          return TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        print("Error parsing time: $e");
      }
      return const TimeOfDay(hour: 9, minute: 0); // Default
    }

    TimeOfDay morningStart = _parseTime(doctor?.startTime ?? "09:00 AM");
    TimeOfDay morningEnd = const TimeOfDay(
        hour: 13, minute: 0); // Not currently in model, keeping default
    TimeOfDay eveningStart =
        const TimeOfDay(hour: 16, minute: 0); // Not in model
    TimeOfDay eveningEnd = _parseTime(doctor?.endTime ?? "05:00 PM");

    Future<void> selectTime(BuildContext context, bool isStart, bool isMorning,
        StateSetter setState) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: isStart
            ? (isMorning ? morningStart : eveningStart)
            : (isMorning ? morningEnd : eveningEnd),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          if (isMorning) {
            if (isStart) {
              morningStart = picked;
            } else {
              morningEnd = picked;
            }
          } else {
            if (isStart) {
              eveningStart = picked;
            } else {
              eveningEnd = picked;
            }
          }
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  )
                ]),
            child: Column(
              children: [
                // Handle Bar with Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.withOpacity(0.05))),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Availability & Rates",
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Configure your practice details",
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded,
                                  color: Colors.grey[600], size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Consultation Rate Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Consultation Fee",
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "\$",
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(
                                        text: doctor?.consultationFee
                                                .toStringAsFixed(2) ??
                                            "50.00"),
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: "0.00",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[300]),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    "Per Session",
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSectionHeader("Active Days"),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: allDays.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedDays.remove(day);
                                  } else {
                                    selectedDays.add(day);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                width: 38, // Reduced size
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            Color(0xFF008985)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4))
                                        ]
                                      : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2))
                                        ],
                                  border: isSelected
                                      ? null
                                      : Border.all(color: Colors.grey[200]!),
                                ),
                                child: Center(
                                  child: Text(
                                    day.substring(0, 1),
                                    style: GoogleFonts.inter(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader("Shift Schedule"),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactTimeCard(
                              context,
                              "Morning",
                              Icons.wb_sunny_rounded,
                              Colors.orange[400]!,
                              morningStart,
                              morningEnd,
                              () async => await selectTime(
                                  context, true, true, setState),
                              () async => await selectTime(
                                  context, false, true, setState),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactTimeCard(
                              context,
                              "Evening",
                              Icons.nights_stay_rounded,
                              Colors.indigo[400]!,
                              eveningStart,
                              eveningEnd,
                              () async => await selectTime(
                                  context, true, false, setState),
                              () async => await selectTime(
                                  context, false, false, setState),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader("Session Duration"),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("${duration.round()} mins",
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor:
                              AppColors.primary.withOpacity(0.1),
                          thumbColor: Colors.white,
                          overlayColor: AppColors.primary.withOpacity(0.1),
                        ),
                        child: Slider(
                          value: duration,
                          min: 15,
                          max: 60,
                          divisions: 3,
                          onChanged: (val) {
                            setState(() {
                              duration = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Save Button (Fixed at bottom)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: CustomButton(
                    text: "Save Changes",
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactTimeCard(
      BuildContext context,
      String label,
      IconData icon,
      Color color,
      TimeOfDay start,
      TimeOfDay end,
      VoidCallback onStartTap,
      VoidCallback onEndTap) {
    String formatTime(TimeOfDay time) {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Start Time
          InkWell(
            onTap: onStartTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Text("Start",
                      style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(
                    formatTime(start),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // End Time
          InkWell(
            onTap: onEndTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Text("End",
                      style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(
                    formatTime(end),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClinicDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle Bar with Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Clinic Details",
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.close_rounded,
                              color: Colors.grey[400], size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSectionHeader("Overview"),
                  const SizedBox(height: 16),
                  _buildTextField(
                      "Clinic Name", Icons.business, "City Heart Center"),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Location"),
                  const SizedBox(height: 16),
                  _buildTextField("Address", Icons.location_on_outlined,
                      "123 Medical Plaza, Downtown",
                      maxLines: 2),
                  const SizedBox(height: 16),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                      image: const DecorationImage(
                        image: NetworkImage(
                            "https://via.placeholder.com/600x300"), // Better Aspect Ratio
                        fit: BoxFit.cover,
                        opacity: 0.8, // More visible
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.map_rounded,
                              color: AppColors.primary),
                          label: const Text(
                            "Locate on Map",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader("Contact & Services"),
                  const SizedBox(height: 16),
                  _buildTextField(
                      "Contact Number", Icons.phone_rounded, "+1 234 567 890"),
                  const SizedBox(height: 16),
                  _buildTextField("Services", Icons.medical_services_outlined,
                      "ECG, Echo, Consultation",
                      maxLines: 2),
                ],
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Update Clinic Info",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, String initialValue,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }
}
