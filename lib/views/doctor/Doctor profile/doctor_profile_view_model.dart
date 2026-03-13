import 'package:flutter/material.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';

class DoctorProfileViewModel extends ChangeNotifier {
  final AppointmentViewModel _appointmentVM;
  
  DoctorProfileViewModel(this._appointmentVM);

  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  
  final List<String> timeSlots = [
    "09:00 AM", "09:30 AM", "10:00 AM", "11:30 AM",
    "02:00 PM", "03:30 PM", "04:00 PM", "05:00 PM",
  ];

  DateTime get selectedDate => _selectedDate;
  String? get selectedTime => _selectedTime;

  void selectDate(DateTime date) {
    _selectedDate = date;
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
