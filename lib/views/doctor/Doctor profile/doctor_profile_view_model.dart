import 'package:flutter/material.dart';
import 'package:medlink/core/utils/doctor_schedule_slot_labels.dart';
import 'package:medlink/models/appointment_model.dart';
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
    _pastSlots.clear();
    final now = DateTime.now();

    _timeSlots = buildDoctorSlotLabelsForDay(doctor, _selectedDate);
    _pastSlots = pastSlotLabelsForDay(_timeSlots, _selectedDate, now);

    notifyListeners();
  }

  void selectDate(DateTime date, DoctorModel doctor) {
    _selectedDate = date;
    _selectedTime = null; // Reset time on date change
    generateTimeSlots(doctor);
    _appointmentVM.fetchBookedSlots(
      doctor.id,
      DateFormat('yyyy-MM-dd').format(date),
    );
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

  Future<void> bookAppointment(DoctorModel doctor, String patientId,
      {AppointmentType consultationType = AppointmentType.inPerson,
      required VoidCallback onSuccess,
      required Function(String) onError}) async {
    if (_selectedTime == null) {
      onError("Please select a time slot");
      return;
    }
    
    final result = await _appointmentVM.bookAppointment(
      doctor: doctor,
      date: _selectedDate,
      time: _selectedTime!,
      patientId: patientId,
      consultationType: consultationType,
    );

    if (result['success']) {
      onSuccess();
    } else {
      onError(result['message'] ?? "Failed to book appointment");
    }
  }
}
