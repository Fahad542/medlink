import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/utils/doctor_schedule_slot_labels.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/Patient%20App/consultation/appointment_details_view.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_profile_view_model.dart'; // Import local VM
import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';
import 'package:medlink/core/localization/app_localizations.dart';

class DoctorProfileView extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorProfileView({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    print("DEBUG: BUILDING REDESIGNED DOCTOR PROFILE VIEW");
    return ChangeNotifierProvider(
      create: (context) => DoctorProfileViewModel(
          Provider.of<AppointmentViewModel>(context, listen: false)),
      child: _DoctorProfileContent(doctor: doctor),
    );
  }
}

class _DoctorProfileContent extends StatefulWidget {
  final DoctorModel doctor;

  const _DoctorProfileContent({required this.doctor});

  @override
  State<_DoctorProfileContent> createState() => _DoctorProfileContentState();
}

class _DoctorProfileContentState extends State<_DoctorProfileContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedMonth = DateTime.now();
  AppointmentType _consultationType = AppointmentType.inPerson;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = Provider.of<DoctorProfileViewModel>(context, listen: false);
      viewModel.selectDate(viewModel.selectedDate, widget.doctor);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DoctorProfileViewModel>(context);
    final hasBooking = viewModel.hasBooking(widget.doctor.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed header
          SizedBox(
            height: 320,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                  // Background & Decorations
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 320,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: Stack(
                          children: [
                            // Gradient
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Circle 1
                            Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            // Circle 2
                            Positioned(
                              bottom: -30,
                              left: -30,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Profile Image & Name
                  Positioned(
                    top: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(widget.doctor.imageUrl),
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.doctor.name,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.doctor.specialty,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 12,
                    child: _buildTabs(),
                  ),

                  // AppBar Actions (Back, Chat, Video)
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const Spacer(),
                        if (hasBooking) ...[
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset("assets/Icons/chat-icon.png",
                                  width: 16, height: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => WaitingRoomView(
                                          callTargetName: widget.doctor.name,
                                          isDoctor: false,
                                          appointmentId: viewModel
                                              .getAppointmentId(widget.doctor.id),
                                        )),
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset("assets/Icons/video.png",
                                  width: 20, height: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(context.tr('doctor.profile.about'), style: _sectionTitleStyle),
                        const SizedBox(height: 8),
                        Text(
                          widget.doctor.about,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                Icons.local_hospital_rounded,
                                context.tr('doctor.profile.hospital'),
                                widget.doctor.hospital,
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                Icons.attach_money_rounded,
                                context.tr('doctor.profile.consultation'),
                                context.tr(
                                  'doctor.profile.consultation_fee',
                                  params: {'fee': widget.doctor.consultationFee},
                                ),
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                Icons.calendar_today_outlined,
                                context.tr('doctor.profile.available'),
                                widget.doctor.availabilityDays.isEmpty
                                    ? context.tr('doctor.profile.not_set')
                                    : widget.doctor.availabilityDays.join(", "),
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                Icons.timer_outlined,
                                context.tr('doctor.profile.time'),
                                "${widget.doctor.startTime} - ${widget.doctor.endTime}",
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildAppointmentTab(viewModel),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5))
            ]),
        child: SafeArea(
          // Ensure button is safe from bottom gestures
          child: SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: context.tr('doctor.profile.confirm_appointment'),
              onPressed: () => _openConfirmAppointment(viewModel),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.white.withOpacity(0.85),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: context.tr('doctor.profile.tab.details')),
          Tab(text: context.tr('doctor.profile.tab.appointment')),
        ],
      ),
    );
  }

  void _openConfirmAppointment(DoctorProfileViewModel viewModel) {
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
      Utils.toastMessage(
        context,
        context.tr('doctor.profile.choose_date_time'),
        isError: true,
      );
      return;
    }

    if (viewModel.selectedTime == null) {
      Utils.toastMessage(
        context,
        context.tr('patient.booking.select_time_error'),
        isError: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsView(
          doctor: widget.doctor,
          selectedDate: viewModel.selectedDate,
          selectedTime: viewModel.selectedTime!,
          consultationType: _consultationType,
        ),
      ),
    );
  }

  Widget _buildAppointmentTab(DoctorProfileViewModel viewModel) {
    final availableDates = _availableDatesForFocusedMonth(widget.doctor);
    _ensureSelectedDateInAvailableRange(viewModel, availableDates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Availability Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('doctor.profile.create_schedule'),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('doctor.profile.plan_appointment'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(viewModel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Color(0xFF1E293B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d').format(viewModel.selectedDate),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 14),

        // Consultation Type Pills (above date strip)
        Row(
          children: [
            Expanded(
              child: _buildConsultationPill(
                AppointmentType.inPerson,
                Icons.location_on_outlined,
                context.tr('doctor.profile.in_clinic'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildConsultationPill(
                AppointmentType.online,
                Icons.videocam_outlined,
                context.tr('doctor.profile.virtual'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Horizontal Calendar Strip
        if (availableDates.isEmpty)
          Container(
            height: 72,
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr('doctor.profile.no_availability_month'),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                final date = availableDates[index];
                final isSelected =
                    DateUtils.isSameDay(viewModel.selectedDate, date);

                return GestureDetector(
                  onTap: () => viewModel.selectDate(date, widget.doctor),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.75)
                          : const Color(0xFFF3F8FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : const Color(0xFFE6EEF3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            DateFormat('d').format(date),
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 14),

        // Time Slots Grid
        _buildTimeSlots(viewModel),
      ],
    );
  }

  void _changeFocusedMonth(int delta, DoctorProfileViewModel viewModel) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
    final monthDates = _availableDatesForFocusedMonth(widget.doctor);
    if (monthDates.isNotEmpty) {
      viewModel.selectDate(monthDates.first, widget.doctor);
    }
  }

  Future<void> _showMonthPicker(DoctorProfileViewModel viewModel) async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month, 1);
        final months = List.generate(
          12,
          (i) => DateTime(currentMonth.year, currentMonth.month + i, 1),
        );

        return FractionallySizedBox(
          heightFactor: 0.65,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.tr('doctor.profile.select_month'),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('doctor.profile.past_months_unavailable'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: months.length,
                      itemBuilder: (_, index) {
                        final month = months[index];
                        final isCurrent = month.year == _focusedMonth.year &&
                            month.month == _focusedMonth.month;
                        return ListTile(
                          dense: true,
                          title: Text(
                            DateFormat('MMMM yyyy').format(month),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight:
                                  isCurrent ? FontWeight.w600 : FontWeight.w500,
                              color: isCurrent
                                  ? AppColors.primary
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 18,
                                )
                              : null,
                          onTap: () => Navigator.pop(ctx, month),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _focusedMonth = DateTime(selected.year, selected.month, 1);
    });
    final monthDates = _availableDatesForFocusedMonth(widget.doctor);
    if (monthDates.isNotEmpty) {
      viewModel.selectDate(monthDates.first, widget.doctor);
    } else {
      Utils.toastMessage(context, context.tr('doctor.profile.no_availability_selected_month'), isError: true);
    }
  }

  List<DateTime> _availableDatesForFocusedMonth(DoctorModel doctor) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    final totalDays = nextMonth.difference(firstDay).inDays;
    final availableDates = <DateTime>[];

    for (var i = 0; i < totalDays; i++) {
      final date = firstDay.add(Duration(days: i));
      if (date.isBefore(today)) continue;
      final slots = buildDoctorSlotLabelsForDay(doctor, date);
      if (slots.isNotEmpty) {
        availableDates.add(date);
      }
    }
    return availableDates;
  }

  void _ensureSelectedDateInAvailableRange(
    DoctorProfileViewModel viewModel,
    List<DateTime> availableDates,
  ) {
    if (availableDates.isEmpty) return;
    final isSelectedInRange = availableDates.any(
      (d) => DateUtils.isSameDay(d, viewModel.selectedDate),
    );
    if (!isSelectedInRange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        viewModel.selectDate(availableDates.first, widget.doctor);
      });
    }
  }

  Widget _buildConsultationPill(AppointmentType type, IconData icon, String label) {
    final isSelected = _consultationType == type;
    return GestureDetector(
      onTap: () => setState(() => _consultationType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots(DoctorProfileViewModel viewModel) {
    final normalizedSlots = viewModel.timeSlots
        .map(_normalizeSlotLabel)
        .where((slot) => slot.isNotEmpty)
        .toSet()
        .toList();
    final normalizedPastSlots = viewModel.pastSlots
        .map(_normalizeSlotLabel)
        .where((slot) => slot.isNotEmpty)
        .toSet();
    final selectedTime = _normalizeSlotLabel(viewModel.selectedTime ?? '');

    final availableSlots = normalizedSlots.where((time) {
      if (normalizedPastSlots.contains(time)) return false;
      try {
        final slotParsed = DateFormat('hh:mm a').parse(time);
        final day = viewModel.selectedDate;
        final slotStart = DateTime(
          day.year,
          day.month,
          day.day,
          slotParsed.hour,
          slotParsed.minute,
        );
        final slotEnd =
            slotStart.add(Duration(minutes: widget.doctor.sessionDuration));
        final isBooked = viewModel.bookedRanges.any(
          (range) => slotStart.isBefore(range.end) && slotEnd.isAfter(range.start),
        );
        if (isBooked) return false;
      } catch (_) {
        final isBooked = viewModel.bookedSlots.any(
          (slot) => slot.trim().toUpperCase() == time.trim().toUpperCase(),
        );
        if (isBooked) return false;
      }
      return true;
    }).toList();

    if (availableSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            context.tr('doctor.profile.no_available_slots'),
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.35,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final time = availableSlots[index];
        final isSelected = selectedTime == time;

        return InkWell(
          onTap: () {
            viewModel.selectTime(time);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        );
      },
    );
  }

  String _normalizeSlotLabel(String raw) {
    final input = raw.trim().toUpperCase();
    if (input.isEmpty) return '';

    for (final pattern in ['hh:mm a', 'h:mm a', 'HH:mm', 'H:mm']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(input);
        return DateFormat('hh:mm a').format(parsed);
      } catch (_) {}
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AP]M))?$')
        .firstMatch(input);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '');
      final minute = int.tryParse(match.group(2) ?? '');
      final meridiem = match.group(3);
      if (hour != null && minute != null && minute >= 0 && minute < 60) {
        int resolvedHour = hour;
        if (meridiem != null && hour >= 1 && hour <= 12) {
          resolvedHour = meridiem == 'PM'
              ? (hour % 12) + 12
              : (hour % 12);
        } else if (hour >= 0 && hour <= 23) {
          resolvedHour = hour;
        } else {
          return raw;
        }
        final dt = DateTime(2000, 1, 1, resolvedHour, minute);
        return DateFormat('hh:mm a').format(dt);
      }
    }

    return raw;
  }


  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1E293B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  TextStyle get _sectionTitleStyle => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

}
