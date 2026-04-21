import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/utils/doctor_schedule_slot_labels.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/views/doctor/doctor_appointments_view_model.dart';

int rescheduleSlotMinutes(AppointmentModel a) {
  final ss = a.scheduledStart;
  final se = a.scheduledEnd;
  if (ss != null && se != null) {
    final m = se.difference(ss).inMinutes;
    if (m > 0) return m;
  }
  return a.doctor?.sessionDuration ?? 30;
}

/// Pick new date & start time within the doctor's weekly availability and free slots.
Future<void> showAppointmentRescheduleSheet({
  required BuildContext context,
  required AppointmentModel appointment,
  required Future<dynamic> Function(Map<String, dynamic> body) submit,
  VoidCallback? onSuccess,
  bool isDoctorContext = false,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _RescheduleSheetBody(
      appointment: appointment,
      submit: submit,
      onSuccess: onSuccess,
      isDoctorContext: isDoctorContext,
    ),
  );
}

class _RescheduleSheetBody extends StatefulWidget {
  final AppointmentModel appointment;
  final Future<dynamic> Function(Map<String, dynamic> body) submit;
  final VoidCallback? onSuccess;
  final bool isDoctorContext;

  const _RescheduleSheetBody({
    required this.appointment,
    required this.submit,
    this.onSuccess,
    required this.isDoctorContext,
  });

  @override
  State<_RescheduleSheetBody> createState() => _RescheduleSheetBodyState();
}

class _RescheduleSheetBodyState extends State<_RescheduleSheetBody> {
  final ApiServices _api = ApiServices();

  DoctorModel? _doctorForSlots;
  bool _loadingAvailability = true;
  String? _availabilityError;

  late DateTime _pickedDate;
  String? _pickedSlotLabel;

  List<String> _slotLabels = [];
  List<String> _pastLabels = [];
  List<DateTimeRange> _bookedRanges = [];
  bool _loadingBooked = false;

  bool _submitting = false;

  /// Length of this visit when placed (PATCH body and overlap checks).
  int get _visitLengthMinutes => rescheduleSlotMinutes(widget.appointment);

  @override
  void initState() {
    super.initState();
    final initial = widget.appointment.displayScheduledStart;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    var d = DateTime(initial.year, initial.month, initial.day);
    if (d.isBefore(today)) d = today;
    _pickedDate = d;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailability());
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loadingAvailability = true;
      _availabilityError = null;
    });

    try {
      if (widget.isDoctorContext) {
        final res = await _api.getPracticeSettings();
        if (res is! Map || res['success'] != true) {
          setState(() {
            _availabilityError =
                res is Map ? (res['message']?.toString() ?? 'Could not load schedule') : 'Could not load schedule';
            _loadingAvailability = false;
          });
          return;
        }
        final data = res['data'];
        if (data is! Map) {
          setState(() {
            _availabilityError = 'Invalid schedule response';
            _loadingAvailability = false;
          });
          return;
        }
        final sessionMin =
            int.tryParse(data['sessionDurationMin']?.toString() ?? '') ??
                _visitLengthMinutes;
        final days = data['days'];
        final rawList =
            days is List ? List<dynamic>.from(days) : <dynamic>[];

        _doctorForSlots = DoctorModel(
          id: widget.appointment.doctorId,
          name: '',
          specialty: '',
          hospital: '',
          rating: 0,
          imageUrl: '',
          isAvailable: true,
          consultationFee: 0,
          about: '',
          sessionDuration: sessionMin,
          rawAvailability: rawList,
        );
      } else {
        // Patient: load weekly hours from API (same source as doctor list / server truth).
        final embedded = widget.appointment.doctor;
        DoctorModel? resolved;

        try {
          final res = await _api
              .getPatientDoctorWeeklySchedule(widget.appointment.doctorId);
          if (res is Map && res['success'] == true && res['data'] is Map) {
            final data = res['data'] as Map;
            final rawList = data['availability'];
            final list =
                rawList is List ? List<dynamic>.from(rawList) : <dynamic>[];
            if (list.isNotEmpty) {
              final sessionMin = int.tryParse(
                      data['sessionDurationMin']?.toString() ?? '') ??
                  embedded?.sessionDuration ??
                  _visitLengthMinutes;
              resolved = DoctorModel(
                id: widget.appointment.doctorId,
                name: embedded?.name ?? 'Doctor',
                specialty: embedded?.specialty ?? '',
                hospital: embedded?.hospital ?? '',
                rating: embedded?.rating ?? 0,
                imageUrl: embedded?.imageUrl ?? '',
                isAvailable: embedded?.isAvailable ?? true,
                consultationFee: embedded?.consultationFee ?? 0,
                about: embedded?.about ?? '',
                experience: embedded?.experience ?? '',
                location: embedded?.location ?? '',
                availabilityDays: embedded?.availabilityDays ?? [],
                sessionDuration: sessionMin,
                rawAvailability: list,
                totalReviews: embedded?.totalReviews ?? 0,
                totalPatients: embedded?.totalPatients ?? 0,
                recentReviews: embedded?.recentReviews ?? [],
              );
            }
          }
        } catch (_) {}

        if (resolved == null &&
            embedded != null &&
            embedded.rawAvailability.isNotEmpty) {
          resolved = DoctorModel(
            id: embedded.id,
            name: embedded.name,
            specialty: embedded.specialty,
            hospital: embedded.hospital,
            rating: embedded.rating,
            imageUrl: embedded.imageUrl,
            isAvailable: embedded.isAvailable,
            consultationFee: embedded.consultationFee,
            about: embedded.about,
            experience: embedded.experience,
            location: embedded.location,
            availabilityDays: embedded.availabilityDays,
            startTime: embedded.startTime,
            endTime: embedded.endTime,
            sessionDuration: embedded.sessionDuration,
            rawAvailability: embedded.rawAvailability,
            totalReviews: embedded.totalReviews,
            totalPatients: embedded.totalPatients,
            recentReviews: embedded.recentReviews,
          );
        }

        if (resolved == null) {
          setState(() {
            _availabilityError =
                'Could not load this doctor\'s weekly hours. Pull to refresh or try again.';
            _doctorForSlots = null;
            _loadingAvailability = false;
          });
          return;
        }

        _doctorForSlots = resolved;
      }

      _clampPickedDateToSelectable();

      setState(() => _loadingAvailability = false);
      await _reloadBookedAndSlots();
    } catch (e) {
      if (mounted) {
        setState(() {
          _availabilityError = e.toString();
          _loadingAvailability = false;
        });
      }
    }
  }

  DateTime _firstCalendarDayWithSlotsOnOrAfter(DateTime from) {
    final doctor = _doctorForSlots!;
    final last =
        DateTime(from.year, from.month, from.day).add(const Duration(days: 365));
    var d = DateTime(from.year, from.month, from.day);
    while (!d.isAfter(last)) {
      if (buildDoctorSlotLabelsForDay(doctor, d).isNotEmpty) return d;
      d = d.add(const Duration(days: 1));
    }
    return DateTime(from.year, from.month, from.day);
  }

  void _clampPickedDateToSelectable() {
    final doctor = _doctorForSlots;
    if (doctor == null) return;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (_pickedDate.isBefore(today)) _pickedDate = today;
    if (buildDoctorSlotLabelsForDay(doctor, _pickedDate).isEmpty) {
      _pickedDate = _firstCalendarDayWithSlotsOnOrAfter(_pickedDate);
    }
  }

  bool _calendarSelectable(DateTime day) {
    final doctor = _doctorForSlots;
    if (doctor == null) return false;
    final norm = DateTime(day.year, day.month, day.day);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (norm.isBefore(today)) return false;
    return buildDoctorSlotLabelsForDay(doctor, norm).isNotEmpty;
  }

  Future<void> _reloadBookedAndSlots() async {
    final doctor = _doctorForSlots;
    if (doctor == null) return;

    setState(() => _loadingBooked = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_pickedDate);

    try {
      if (widget.isDoctorContext) {
        if (!mounted) return;
        final docApptVm =
            Provider.of<DoctorAppointmentsViewModel>(context, listen: false);
        try {
          await docApptVm.fetchUpcomingAppointments();
        } catch (_) {}
        if (!mounted) return;
        _bookedRanges = bookedRangesFromUpcomingOnDay(
          docApptVm.upcomingAppointments,
          _pickedDate,
          widget.appointment.id,
          _visitLengthMinutes,
        );
      } else {
        final response = await _api.getBookedSlots(
          widget.appointment.doctorId,
          dateStr,
          excludeAppointmentId: widget.appointment.id,
        );
        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'] ?? [];
          _bookedRanges = data.map((json) {
            final start =
                DateTime.parse(json['scheduledStart'].toString()).toLocal();
            final end = json['scheduledEnd'] != null
                ? DateTime.parse(json['scheduledEnd'].toString()).toLocal()
                : start;
            return DateTimeRange(start: start, end: end);
          }).toList();
        } else {
          _bookedRanges = [];
        }

        _dropRangeMatchingCurrentAppointment();
      }

      _slotLabels = buildDoctorSlotLabelsForDay(doctor, _pickedDate);
      final now = DateTime.now();
      _pastLabels = pastSlotLabelsForDay(_slotLabels, _pickedDate, now);

      _syncPickedSlot();
    } catch (e) {
      _bookedRanges = [];
      _slotLabels = buildDoctorSlotLabelsForDay(doctor, _pickedDate);
      _pastLabels =
          pastSlotLabelsForDay(_slotLabels, _pickedDate, DateTime.now());
    }

    _syncPickedSlot();
    if (mounted) {
      setState(() => _loadingBooked = false);
    }
  }

  /// If the backend ignores [excludeAppointmentId], remove overlap with this visit.
  void _dropRangeMatchingCurrentAppointment() {
    final mine = widget.appointment.scheduledStart ?? widget.appointment.dateTime;
    final local = mine.toLocal();
    _bookedRanges.removeWhere((r) {
      if (!DateUtils.isSameDay(r.start, local)) return false;
      return r.start.hour == local.hour && r.start.minute == local.minute;
    });
  }

  void _syncPickedSlot() {
    if (_slotLabels.isEmpty) {
      _pickedSlotLabel = null;
      return;
    }
    final initialStart = widget.appointment.displayScheduledStart;
    if (_pickedSlotLabel == null ||
        !_slotLabels.contains(_pickedSlotLabel) ||
        _isSlotDisabled(_pickedSlotLabel!)) {
      final fromAppt = DateFormat('hh:mm a').format(initialStart);
      if (_slotLabels.contains(fromAppt) && !_isSlotDisabled(fromAppt)) {
        _pickedSlotLabel = fromAppt;
        return;
      }
      String? firstOk;
      for (final s in _slotLabels) {
        if (!_isSlotDisabled(s)) {
          firstOk = s;
          break;
        }
      }
      _pickedSlotLabel = firstOk;
    }
  }

  bool _isSlotDisabled(String label) {
    if (_pastLabels.contains(label)) return true;
    try {
      final slotParsed = DateFormat('hh:mm a').parse(label);
      final day = _pickedDate;
      final slotStart =
          DateTime(day.year, day.month, day.day, slotParsed.hour, slotParsed.minute);
      return slotOverlapsBookedRanges(
        slotStart,
        _visitLengthMinutes,
        _bookedRanges,
      );
    } catch (_) {
      return true;
    }
  }

  Future<void> _pickDate() async {
    final doctor = _doctorForSlots;
    if (doctor == null) return;

    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = first.add(const Duration(days: 365));

    final d = await showDatePicker(
      context: context,
      initialDate:
          _pickedDate.isBefore(first) ? _firstCalendarDayWithSlotsOnOrAfter(first) : _pickedDate,
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: _calendarSelectable,
    );
    if (d != null) {
      setState(() {
        _pickedDate = DateTime(d.year, d.month, d.day);
        _pickedSlotLabel = null;
      });
      await _reloadBookedAndSlots();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final doctor = _doctorForSlots;
    final canSubmit = !_loadingAvailability &&
        !_loadingBooked &&
        doctor != null &&
        _pickedSlotLabel != null &&
        !_isSlotDisabled(_pickedSlotLabel!);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reschedule appointment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                doctor != null
                    ? 'Only times inside weekly hours (about ${doctor.sessionDuration} min steps; this visit is $_visitLengthMinutes min).'
                    : 'Loading schedule…',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              if (_availabilityError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _availabilityError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              if (_loadingAvailability) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (!_loadingAvailability && doctor != null) ...[
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_pickedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 8),
                Text(
                  'Available times',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                if (_loadingBooked)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ))
                else if (_slotLabels.isEmpty)
                  Text(
                    'No openings on this day.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _slotLabels.length,
                    itemBuilder: (context, index) {
                      final time = _slotLabels[index];
                      final isSelected = _pickedSlotLabel == time;
                      final isDisabled = _isSlotDisabled(time);

                      return InkWell(
                        onTap: () {
                          if (isDisabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _pastLabels.contains(time)
                                      ? 'That time has already passed'
                                      : 'That time overlaps another booking',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _pickedSlotLabel = time);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDisabled
                                    ? Colors.grey[100]
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDisabled
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !canSubmit || _submitting
                        ? null
                        : () async {
                            final slotLabel = _pickedSlotLabel!;
                            DateTime parsedStart;
                            try {
                              parsedStart = DateFormat('hh:mm a').parse(slotLabel);
                            } catch (_) {
                              parsedStart = DateFormat('HH:mm').parse(slotLabel);
                            }
                            final localStart = DateTime(
                              _pickedDate.year,
                              _pickedDate.month,
                              _pickedDate.day,
                              parsedStart.hour,
                              parsedStart.minute,
                            );
                            final localEnd = localStart
                                .add(Duration(minutes: _visitLengthMinutes));
                            final utcStart = localStart.toUtc();
                            final utcEnd = localEnd.toUtc();

                            if (localStart.isBefore(DateTime.now())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please pick a future date and time.')),
                              );
                              return;
                            }

                            final body = {
                              'date': DateFormat('yyyy-MM-dd').format(utcStart),
                              'startTime':
                                  DateFormat('HH:mm').format(utcStart),
                              'endTime': DateFormat('HH:mm').format(utcEnd),
                            };

                            setState(() => _submitting = true);
                            try {
                              final res = await widget.submit(body);
                              if (!context.mounted) return;

                              final ok = res != null &&
                                  (res['success'] == true ||
                                      res['success'] == 'true');
                              if (ok) {
                                Navigator.pop(context);
                                widget.onSuccess?.call();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Appointment rescheduled')),
                                );
                              } else {
                                setState(() => _submitting = false);
                                final msg = res is Map
                                    ? (res['message']?.toString() ??
                                        'Could not reschedule')
                                    : 'Could not reschedule';
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(msg)));
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _submitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm new time'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
