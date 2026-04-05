import 'package:flutter/material.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:intl/intl.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';

class DoctorProfileViewModel extends ChangeNotifier {
  final AppointmentViewModel _appointmentVM;
  
  DoctorProfileViewModel(this._appointmentVM) {
    // Listen to changes in AppointmentViewModel (like booked slot updates)
    _appointmentVM.addListener(_onAppointmentUpdate);
  }

  void _onAppointmentUpdate() {
    debugPrint("[DoctorProfileViewModel] AppointmentViewModel updated, notifying listeners...");
    notifyListeners();
  }

  @override
  void dispose() {
    _appointmentVM.removeListener(_onAppointmentUpdate);
    super.dispose();
  }

  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<String> _timeSlots = [];
  List<String> _pastSlots = [];
  List<String> get timeSlots => _timeSlots;
  List<String> get pastSlots => _pastSlots;

  DateTime get selectedDate => _selectedDate;
  String? get selectedTime => _selectedTime;
  List<String> get bookedSlots => _appointmentVM.bookedSlots;
  List<DateTimeRange> get bookedRanges => _appointmentVM.bookedRanges;
  bool get isLoadingBookedSlots => _appointmentVM.isLoadingBookedSlots;

  void generateTimeSlots(DoctorModel doctor) {
    Set<String> uniqueSlots = {};
    _pastSlots.clear();
    _timeSlots.clear();
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_selectedDate, now);
    
    final dayOfWeek = _selectedDate.weekday % 7; // 0 for Sunday
    
    // Find slots for this day 
    final slots = doctor.rawAvailability.where((slot) => slot['dayOfWeek'] == dayOfWeek).toList();
    
    void _addSlots(String startStr, String endStr) {
       _generateSlotsInRange(startStr, endStr, doctor.sessionDuration, uniqueSlots);
    }

    for (var slot in slots) {
      if (slot['morningStart'] != null && slot['morningEnd'] != null) {
        _addSlots(slot['morningStart'], slot['morningEnd']);
      }
      
      if (slot['eveningStart'] != null && slot['eveningEnd'] != null) {
        _addSlots(slot['eveningStart'], slot['eveningEnd']);
      }

      if (slot['startTime'] != null && slot['endTime'] != null) {
        _addSlots(slot['startTime'], slot['endTime']);
      }
    }
    
    _timeSlots = uniqueSlots.toList();
    
    // Sort slots by time
    _timeSlots.sort((a, b) {
       final timeA = DateFormat("hh:mm a").parse(a);
       final timeB = DateFormat("hh:mm a").parse(b);
       return timeA.compareTo(timeB);
    });

    // Identify past slots if today
    if (isToday) {
      for (var slot in _timeSlots) {
        final slotTime = DateFormat("hh:mm a").parse(slot);
        final fullSlotDateTime = DateTime(
          now.year, now.month, now.day, slotTime.hour, slotTime.minute
        );
        if (fullSlotDateTime.isBefore(now)) {
          _pastSlots.add(slot);
        }
      }
    }
    
    notifyListeners();
  }

  void _generateSlotsInRange(String startStr, String endStr, int durationMin, Set<String> target) {
    try {
      DateTime start;
      DateTime end;
      
      // Handle "09:00" format vs "2026-04-05T09:00:00.000Z"
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
        target.add(DateFormat("hh:mm a").format(start));
        start = start.add(Duration(minutes: durationMin));
      }
    } catch (e) {
      debugPrint("Error generating slots: $e");
    }
  }

  void selectDate(DateTime date, DoctorModel doctor) {
    _selectedDate = date;
    _selectedTime = null; // Reset time on date change
    generateTimeSlots(doctor);
    _appointmentVM.fetchBookedSlots(
        doctor.id, DateFormat('yyyy-MM-dd').format(date));
    notifyListeners();
  }

  void selectTime(String time) {
    _selectedTime = time;
    notifyListeners();
  }
  
  bool hasBooking(String doctorId) {
    return _appointmentVM.appointments.any((appt) => appt.doctorId == doctorId);
  }

  String? getAppointmentId(String doctorId) {
    try {
      return _appointmentVM.appointments
          .firstWhere((appt) => appt.doctorId == doctorId)
          .id;
    } catch (e) {
      return null;
    }
  }

  Future<void> bookAppointment(DoctorModel doctor, String patientId, {required VoidCallback onSuccess, required Function(String) onError}) async {
    if (_selectedTime == null) {
      onError("Please select a time slot");
      return;
    }
    
    final result = await _appointmentVM.bookAppointment(
      doctor: doctor,
      date: _selectedDate,
      time: _selectedTime!,
      patientId: patientId,
    );

    if (result['success']) {
      onSuccess();
    } else {
      onError(result['message'] ?? "Failed to book appointment");
    }
  }
}
