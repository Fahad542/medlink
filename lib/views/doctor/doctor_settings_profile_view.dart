import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';

import 'package:medlink/views/doctor/Doctor%20profile/doctor_personal_info_view.dart';
import 'package:medlink/views/doctor/Doctor%20earnings/doctor_earnings_view.dart';
import 'package:medlink/views/doctor/doctor_reviews_view.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/delete_account_sheet.dart';
import 'package:medlink/widgets/logout_confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_personal_info_viewmodel.dart';

class DoctorSettingsProfileView extends StatefulWidget {
  const DoctorSettingsProfileView({super.key});

  @override
  State<DoctorSettingsProfileView> createState() =>
      _DoctorSettingsProfileViewState();
}

class _DoctorSettingsProfileViewState extends State<DoctorSettingsProfileView> {
  late Future<_DoctorStats> _statsFuture;
  String _statsSeed = '';

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadDoctorStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userVM = Provider.of<UserViewModel>(context);
    final nextSeed =
        '${userVM.loginSession?.data?.user?.id ?? ''}|${userVM.accessToken ?? ''}|${userVM.doctor?.id ?? ''}';
    if (nextSeed != _statsSeed) {
      _statsSeed = nextSeed;
      _statsFuture = _loadDoctorStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = Provider.of<UserViewModel>(context);
    final doctor = userVM.doctor;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(doctor),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
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
                      child: FutureBuilder<_DoctorStats>(
                        future: _statsFuture,
                        builder: (context, snapshot) {
                          final stats = snapshot.data ??
                              _DoctorStats(
                                experienceYears:
                                    int.tryParse(doctor?.experience ?? '0') ?? 0,
                                patientsCount: doctor?.totalPatients ?? 0,
                                reviewsCount: doctor?.totalReviews ?? 0,
                              );
                          return Row(
                            children: [
                              Expanded(
                                child: _StatItem(
                                  label: "Experience",
                                  value: stats.experienceYears.toString(),
                                  unit: "Yrs",
                                ),
                              ),
                              _VerticalDivider(),
                              Expanded(
                                child: _StatItem(
                                  label: "Patients",
                                  value: _formatCount(stats.patientsCount),
                                  unit: "Lives",
                                ),
                              ),
                              _VerticalDivider(),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    if (doctor == null) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorReviewsView(
                                          doctor: doctor,
                                          isDoctorMode: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _StatItem(
                                    label: "Reviews",
                                    value: stats.reviewsCount.toString(),
                                    unit: "",
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
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
                                onTap: () {},
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
                    _buildActionButton(
                      text: "Log Out",
                      icon: Icons.logout_rounded,
                      color: Colors.red,
                      onTap: () {
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
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      text: "Delete Account",
                      icon: Icons.person_remove_rounded,
                      color: AppColors.error,
                      onTap: () {
                        DeleteAccountSheet.show(context);
                      },
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

  Future<void> _showAvailabilityBottomSheet(BuildContext context) async {
    final personalInfoVMPre =
        Provider.of<DoctorPersonalInfoViewModel>(context, listen: false);
    await personalInfoVMPre.refreshConsultationFeeRulesFromBackend();

    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final doctor = userVM.doctor;

    double duration = (doctor?.sessionDuration ?? 30).toDouble();
    Set<String> selectedDays = doctor?.availabilityDays.toSet() ??
        {"Mon", "Tue", "Wed", "Thu", "Fri"};
    List<String> allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

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
      } catch (e) {}
      return const TimeOfDay(hour: 9, minute: 0);
    }

    TimeOfDay startTime = _parseTime(doctor?.startTime ?? "09:00 AM");
    TimeOfDay endTime = _parseTime(doctor?.endTime ?? "05:00 PM");

    final personalInfoVM =
        Provider.of<DoctorPersonalInfoViewModel>(context, listen: false);
    final feeController = TextEditingController(
        text: doctor?.consultationFee.toStringAsFixed(2) ?? "50.00");

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
            ),
            child: Column(
              children: [
                _buildSheetHeader(context, "Availability & Rates",
                    "Configure your practice details"),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildFeeCard(feeController),
                      const SizedBox(height: 24),
                      _buildSectionHeader("Active Days"),
                      const SizedBox(height: 12),
                      _buildDaysRow(allDays, selectedDays, setState),
                      const SizedBox(height: 24),
                      _buildSectionHeader("Practice Hours"),
                      const SizedBox(height: 12),
                      _buildHoursCard(context, startTime, endTime, setState,
                          (BuildContext ctx, bool isStart, StateSetter st) async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: ctx,
                          initialTime: isStart ? startTime : endTime,
                        );
                        if (picked != null) {
                          st(() {
                            if (isStart) startTime = picked;
                            else endTime = picked;
                          });
                        }
                      }),
                      const SizedBox(height: 24),
                      _buildSectionHeader("Session Duration"),
                      const SizedBox(height: 12),
                      _buildDurationCard(duration,
                          (val) => setState(() => duration = val), context),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: "Save Changes",
                        onPressed: () async {
                          final feeRaw =
                              feeController.text.trim().replaceAll(',', '');
                          final feeVal = double.tryParse(feeRaw);
                          await personalInfoVM.updateAvailability(
                            selectedDays: selectedDays,
                            consultationFee: feeVal ?? 0,
                            sessionDuration: duration,
                            morningStart: startTime,
                            morningEnd: endTime,
                            eveningStart: null,
                            eveningEnd: null,
                            context: context,
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context, String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(sub,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ],
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Consultation Fee",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text("\$",
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 22),
                  decoration: const InputDecoration(
                      border: InputBorder.none, hintText: "0.00"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysRow(
      List<String> allDays, Set<String> selectedDays, StateSetter setState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allDays.map((day) {
          final isSelected = selectedDays.contains(day);
          return GestureDetector(
            onTap: () => setState(() =>
                isSelected ? selectedDays.remove(day) : selectedDays.add(day)),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: isSelected ? null : Border.all(color: Colors.grey[200]!),
              ),
              child: Center(
                child: Text(day.substring(0, 1),
                    style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHoursCard(BuildContext context, TimeOfDay start, TimeOfDay end,
      StateSetter setState, Function selectTime) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
              child: _buildTimeItem(context, "Start Time", start,
                  () => selectTime(context, true, setState))),
          const SizedBox(width: 12),
          Expanded(
              child: _buildTimeItem(context, "End Time", end,
                  () => selectTime(context, false, setState))),
        ],
      ),
    );
  }

  Widget _buildTimeItem(
      BuildContext context, String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time.format(context),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const Icon(Icons.access_time_rounded,
                    size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(
      double duration, Function(double) onChanged, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Slot Duration", style: GoogleFonts.inter(fontSize: 13)),
              Text("${duration.toInt()} mins",
                  style: GoogleFonts.inter(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [15, 30, 45, 60].map((mins) {
              final isSelected = duration.toInt() == mins;
              return ChoiceChip(
                label: Text("${mins}m", style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87
                )),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  if (selected) onChanged(mins.toDouble());
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[200]!),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800]));
  }

  Widget _buildActionButton(
      {required String text,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(text,
                style: GoogleFonts.inter(
                    color: color, fontWeight: FontWeight.w500, fontSize: 15)),
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
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: CircleAvatar(
                radius: 130, backgroundColor: Colors.white.withOpacity(0.08)),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  backgroundImage: (doctor?.imageUrl.isNotEmpty ?? false)
                      ? NetworkImage(doctor!.imageUrl)
                      : null,
                  child: (doctor?.imageUrl.isEmpty ?? true)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(doctor?.name ?? "Doctor Name",
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16)),
                  child: Text(doctor?.specialty ?? "Specialist",
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTile(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B))),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
      trailing:
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, indent: 60, color: Colors.grey[100]);

  Widget _StatItem(
      {required String label, required String value, required String unit}) {
    final hasUnit = unit.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500])),
            if (hasUnit) const SizedBox(width: 2),
            if (hasUnit)
              Text(unit,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _VerticalDivider() =>
      Container(height: 42, width: 1, color: Colors.grey[200]);

  Future<_DoctorStats> _loadDoctorStats() async {
    final api = ApiServices();
    int patients = 0;
    int reviews = 0;
    int experienceYears = 0;

    try {
      final patientsRes = await api.getDoctorPatients();
      final patientData = patientsRes is Map ? patientsRes['data'] : null;
      if (patientData is List) {
        patients = patientData.length;
      }
    } catch (_) {}

    try {
      final reviewsRes = await api.getDoctorReviews();
      final data = reviewsRes is Map ? reviewsRes['data'] : null;
      if (data is Map) {
        final total = int.tryParse((data['totalReviews'] ?? '').toString());
        if (total != null) {
          reviews = total;
        } else if (data['reviews'] is List) {
          reviews = (data['reviews'] as List).length;
        }
      }
    } catch (_) {}

    try {
      final profileRes = await api.getDoctorProfile();
      final data = profileRes is Map ? profileRes['data'] : null;
      if (data is Map) {
        final yearsRaw = data['yearsExperience'] ??
            data['experienceInYears'] ??
            data['experience'] ??
            (data['doctorProfile'] is Map
                ? (data['doctorProfile']['yearsExperience'] ??
                    data['doctorProfile']['experienceInYears'])
                : null);
        experienceYears = int.tryParse((yearsRaw ?? '').toString()) ?? 0;
      }
    } catch (_) {}

    if (experienceYears == 0) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      experienceYears = int.tryParse(userVM.doctor?.experience ?? '0') ?? 0;
    }
    if (patients == 0) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      patients = userVM.doctor?.totalPatients ?? 0;
    }
    if (reviews == 0) {
      final userVM = Provider.of<UserViewModel>(context, listen: false);
      reviews = userVM.doctor?.totalReviews ?? 0;
    }

    return _DoctorStats(
      experienceYears: experienceYears,
      patientsCount: patients,
      reviewsCount: reviews,
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final value = count / 1000.0;
      return value >= 10 ? "${value.toStringAsFixed(0)}k" : "${value.toStringAsFixed(1)}k";
    }
    return count.toString();
  }
}

class _DoctorStats {
  final int experienceYears;
  final int patientsCount;
  final int reviewsCount;

  const _DoctorStats({
    required this.experienceYears,
    required this.patientsCount,
    required this.reviewsCount,
  });
}
