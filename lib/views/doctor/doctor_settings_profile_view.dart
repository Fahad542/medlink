import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/localization/app_localizations.dart';
import 'package:medlink/data/network/api_services.dart';

import 'package:medlink/views/doctor/Doctor%20profile/doctor_personal_info_view.dart';
import 'package:medlink/views/doctor/Doctor%20earnings/doctor_earnings_view.dart';
import 'package:medlink/views/Login/login_view.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/delete_account_sheet.dart';
import 'package:medlink/widgets/logout_confirmation_dialog.dart';
import 'package:medlink/main.dart';
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

  void _showLocalizationSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final currentLocale = Localizations.localeOf(sheetContext).languageCode;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetContext.tr('profile.localization.sheet.title'),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sheetContext.tr('profile.localization.sheet.subtitle'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sheetContext.tr('profile.localization.french')),
                  trailing: currentLocale == 'fr'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    MedLinkApp.setLocale(context, const Locale('fr'));
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(sheetContext.tr('profile.localization.english')),
                  trailing: currentLocale == 'en'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    MedLinkApp.setLocale(context, const Locale('en'));
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(doctor),
            Transform.translate(
              offset: const Offset(0, -52),
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
                                    int.tryParse(doctor?.experience ?? '0') ??
                                        0,
                                patientsCount: doctor?.totalPatients ?? 0,
                              );
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                label:
                                    l10n.tr('doctor.settings.stats.experience'),
                                value: stats.experienceYears.toString(),
                                unit: l10n
                                    .tr('doctor.settings.stats.years_short'),
                              ),
                              _VerticalDivider(),
                              _StatItem(
                                label:
                                    l10n.tr('doctor.settings.stats.patients'),
                                value: _formatCount(stats.patientsCount),
                                unit: l10n.tr('doctor.settings.stats.lives'),
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
                            l10n.tr('doctor.settings.section.account_settings'),
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
                                title: l10n.tr(
                                    'doctor.settings.tile.personal_info.title'),
                                subtitle: l10n.tr(
                                    'doctor.settings.tile.personal_info.subtitle'),
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
                                title: l10n.tr(
                                    'doctor.settings.tile.availability.title'),
                                subtitle: l10n.tr(
                                    'doctor.settings.tile.availability.subtitle'),
                                onTap: () {
                                  _showAvailabilityBottomSheet(context);
                                },
                              ),
                              _buildDivider(),
                              _buildPremiumTile(
                                context,
                                icon: Icons.language,
                                color: AppColors.primary,
                                title: l10n.tr(
                                    'doctor.settings.tile.localization.title'),
                                subtitle: l10n.tr(
                                    'doctor.settings.tile.localization.subtitle'),
                                onTap: _showLocalizationSheet,
                              ),
                              _buildDivider(),
                              _buildPremiumTile(
                                context,
                                icon: Icons.account_balance_wallet_outlined,
                                color: AppColors.primary,
                                title: l10n
                                    .tr('doctor.settings.tile.earnings.title'),
                                subtitle: l10n.tr(
                                    'doctor.settings.tile.earnings.subtitle'),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.tr('doctor.settings.section.account_actions'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            icon: Icons.logout_rounded,
                            color: AppColors.primary,
                            title: l10n.tr('doctor.settings.tile.logout.title'),
                            subtitle:
                                l10n.tr('doctor.settings.tile.logout.subtitle'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => LogoutConfirmationDialog(
                                  onConfirm: () {
                                    userVM.logout();
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginView()),
                                      (route) => false,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildPremiumTile(
                            context,
                            icon: Icons.person_remove_rounded,
                            color: AppColors.primary,
                            title: l10n.tr('doctor.settings.tile.delete.title'),
                            subtitle:
                                l10n.tr('doctor.settings.tile.delete.subtitle'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => LogoutConfirmationDialog(
                                  title: l10n
                                      .tr('doctor.settings.tile.delete.title'),
                                  message: l10n.tr(
                                      'doctor.settings.dialog.delete.message'),
                                  confirmText: l10n.tr('common.delete'),
                                  confirmColor: AppColors.primary,
                                  onConfirm: () {
                                    Navigator.pop(context);
                                    DeleteAccountSheet.show(context);
                                  },
                                ),
                              );
                            },
                          ),
                        ],
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

  Future<void> _showAvailabilityBottomSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final personalInfoVMPre =
        Provider.of<DoctorPersonalInfoViewModel>(context, listen: false);
    await personalInfoVMPre.refreshConsultationFeeRulesFromBackend();

    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final doctor = userVM.doctor;

    double duration = (doctor?.sessionDuration ?? 30).toDouble();
    Set<String> selectedDays =
        doctor?.availabilityDays.toSet() ?? {"Mon", "Tue", "Wed", "Thu", "Fri"};
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
                _buildSheetHeader(
                  context,
                  l10n.tr('doctor.settings.sheet.title'),
                  l10n.tr('doctor.settings.sheet.subtitle'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildFeeCard(context, feeController),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                          context, l10n.tr('doctor.settings.active_days')),
                      const SizedBox(height: 12),
                      _buildDaysRow(allDays, selectedDays, setState),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                          context, l10n.tr('doctor.settings.practice_hours')),
                      const SizedBox(height: 12),
                      _buildHoursCard(context, startTime, endTime, setState,
                          (BuildContext ctx, bool isStart,
                              StateSetter st) async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: ctx,
                          initialTime: isStart ? startTime : endTime,
                        );
                        if (picked != null) {
                          st(() {
                            if (isStart)
                              startTime = picked;
                            else
                              endTime = picked;
                          });
                        }
                      }),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                          context, l10n.tr('doctor.settings.session_duration')),
                      const SizedBox(height: 12),
                      _buildDurationCard(duration,
                          (val) => setState(() => duration = val), context),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: l10n.tr('doctor.settings.save_changes'),
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
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
                      style:
                          GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
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

  Widget _buildFeeCard(BuildContext context, TextEditingController controller) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tr('doctor.settings.consultation_fee'),
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey)),
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
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 22),
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
                border:
                    isSelected ? null : Border.all(color: Colors.grey[200]!),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
              child: _buildTimeItem(
                  context,
                  l10n.tr('doctor.settings.start_time'),
                  start,
                  () => selectTime(context, true, setState))),
          const SizedBox(width: 12),
          Expanded(
              child: _buildTimeItem(
                  context,
                  l10n.tr('doctor.settings.end_time'),
                  end,
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.tr('doctor.settings.slot_duration'),
                  style: GoogleFonts.inter(fontSize: 13)),
              Text(
                  l10n.tr('doctor.settings.minutes_short',
                      params: {'minutes': duration.toInt().toString()}),
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
                label: Text("${mins}m",
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                onSelected: (selected) {
                  if (selected) onChanged(mins.toDouble());
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color:
                          isSelected ? Colors.transparent : Colors.grey[200]!),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800]));
  }

  Widget _buildHeader(DoctorModel? doctor) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 300,
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
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
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
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
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
                        radius: 42,
                        backgroundColor: Colors.white,
                        backgroundImage: (doctor?.imageUrl.isNotEmpty ?? false)
                            ? NetworkImage(doctor!.imageUrl)
                            : null,
                        child: (doctor?.imageUrl.isEmpty ?? true)
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      doctor?.name ?? l10n.tr('doctor.settings.name_fallback'),
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
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
                        doctor?.specialty ??
                            l10n.tr('doctor.settings.specialty_fallback'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTile(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
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

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, indent: 60, color: Colors.grey[100]);

  Widget _StatItem(
      {required String label, required String value, required String unit}) {
    final hasUnit = unit.trim().isNotEmpty;
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1)),
            if (hasUnit) const SizedBox(width: 2),
            if (hasUnit)
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(unit,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B))),
              ),
          ],
        ),
      ],
    );
  }

  Widget _VerticalDivider() =>
      Container(height: 46, width: 1, color: Colors.grey[200]);

  Future<_DoctorStats> _loadDoctorStats() async {
    final api = ApiServices();
    int patients = 0;
    int experienceYears = 0;

    try {
      final patientsRes = await api.getDoctorPatients();
      final patientData = patientsRes is Map ? patientsRes['data'] : null;
      if (patientData is List) {
        patients = patientData.length;
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
    return _DoctorStats(
      experienceYears: experienceYears,
      patientsCount: patients,
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final value = count / 1000.0;
      return value >= 10
          ? "${value.toStringAsFixed(0)}k"
          : "${value.toStringAsFixed(1)}k";
    }
    return count.toString();
  }
}

class _DoctorStats {
  final int experienceYears;
  final int patientsCount;

  const _DoctorStats({
    required this.experienceYears,
    required this.patientsCount,
  });
}
