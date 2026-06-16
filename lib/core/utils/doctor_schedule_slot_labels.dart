import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/models/doctor_model.dart';

/// Generates 'hh:mm a' labels for each session-sized step within weekly
/// availability rows on [selectedDate].
List<String> buildDoctorSlotLabelsForDay(
  DoctorModel doctor,
  DateTime selectedDate,
) {
  return buildRawAvailabilitySlotLabelsForDay(
    rawAvailability: doctor.rawAvailability,
    selectedDate: selectedDate,
    sessionDurationMinutes: doctor.sessionDuration,
  );
}

/// Same as [buildDoctorSlotLabelsForDay] but accepts raw weekly rows directly
/// (used when building from practice-settings `days` without a full [DoctorModel]).
List<String> buildRawAvailabilitySlotLabelsForDay({
  required List<dynamic> rawAvailability,
  required DateTime selectedDate,
  required int sessionDurationMinutes,
}) {
  final uniqueSlots = <String>{};
  final dayOfWeek = selectedDate.weekday % 7;

  final slots =
      rawAvailability.where((slot) => slot['dayOfWeek'] == dayOfWeek).toList();

  void addRange(String? startStr, String? endStr) {
    if (startStr == null || endStr == null) return;
    addSlotsInRange(startStr, endStr, sessionDurationMinutes, uniqueSlots);
  }

  for (final slot in slots) {
    addRange(slot['morningStart'], slot['morningEnd']);
    addRange(slot['eveningStart'], slot['eveningEnd']);
    addRange(slot['startTime'], slot['endTime']);
  }

  final list = uniqueSlots.toList()
    ..sort((a, b) =>
        DateFormat('hh:mm a').parse(a).compareTo(DateFormat('hh:mm a').parse(b)));
  return list;
}

void addSlotsInRange(
  String startStr,
  String endStr,
  int durationMin,
  Set<String> target,
) {
  try {
    DateTime start;
    DateTime end;

    if (startStr.contains('T')) {
      start = DateTime.parse(startStr).toLocal();
    } else {
      final parts = startStr.split(':');
      start = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    }

    if (endStr.contains('T')) {
      end = DateTime.parse(endStr).toLocal();
    } else {
      final parts = endStr.split(':');
      end = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    }

    while (start.isBefore(end)) {
      target.add(DateFormat('hh:mm a').format(start));
      start = start.add(Duration(minutes: durationMin));
    }
  } catch (_) {}
}

/// Marks slot labels that are strictly before [now] when [selectedDate] is today.
List<String> pastSlotLabelsForDay(
  List<String> slots,
  DateTime selectedDate,
  DateTime now,
) {
  if (!DateUtils.isSameDay(selectedDate, now)) return [];
  final past = <String>[];
  for (final slot in slots) {
    try {
      final slotTime = DateFormat('hh:mm a').parse(slot);
      final full = DateTime(
        now.year,
        now.month,
        now.day,
        slotTime.hour,
        slotTime.minute,
      );
      if (full.isBefore(now)) past.add(slot);
    } catch (_) {}
  }
  return past;
}

bool slotOverlapsBookedRanges(
  DateTime slotStartLocal,
  int slotDurationMinutes,
  List<DateTimeRange> bookedRanges,
) {
  final slotEnd =
      slotStartLocal.add(Duration(minutes: slotDurationMinutes));
  return bookedRanges.any(
    (r) => slotStartLocal.isBefore(r.end) && slotEnd.isAfter(r.start),
  );
}

/// Booked intervals on [day] from doctor upcoming list (excludes appointment being moved).
List<DateTimeRange> bookedRangesFromUpcomingOnDay(
  List<AppointmentModel> upcoming,
  DateTime day,
  String excludeAppointmentId,
  int fallbackDurationMinutes,
) {
  final out = <DateTimeRange>[];
  for (final a in upcoming) {
    if (a.id == excludeAppointmentId) continue;
    final startRaw = a.scheduledStart ?? a.dateTime;
    final start = startRaw.toLocal();
    if (!DateUtils.isSameDay(start, day)) continue;
    DateTime end;
    if (a.scheduledEnd != null) {
      end = a.scheduledEnd!.toLocal();
    } else {
      end = start.add(Duration(minutes: fallbackDurationMinutes));
    }
    out.add(DateTimeRange(start: start, end: end));
  }
  return out;
}
