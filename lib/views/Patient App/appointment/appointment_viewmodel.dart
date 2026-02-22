import 'package:flutter/material.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/user_model.dart';
import 'package:intl/intl.dart';

import '../../../data/network/api_services.dart'; // Added for time formatting

class AppointmentViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  List<AppointmentModel> _cancelledAppointments = [];
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  List<AppointmentModel> get pastAppointments => _pastAppointments;
  List<AppointmentModel> get cancelledAppointments => _cancelledAppointments;
  List<AppointmentModel> get appointments => [..._upcomingAppointments, ..._pastAppointments, ..._cancelledAppointments];


  

  Future<void> fetchAppointments(String patientId, {String status = 'upcoming'}) async {
    _isLoading = true;
    notifyListeners();

    try {

      
      final data = await _apiService.getPatientAppointments(patientId, status: status);
      
      List<AppointmentModel> fetched = data.map((json) => AppointmentModel.fromJson(json)).toList();

      if (status == 'upcoming') {
        _upcomingAppointments = fetched;
      } else if (status == 'past') {
        _pastAppointments = fetched;
      } else if (status == 'cancelled') {
        _cancelledAppointments = fetched;
      }
      
      // Also update the main list if needed, or just rely on specific lists
      // _appointments = [..._upcomingAppointments, ..._pastAppointments, ..._cancelledAppointments];

    } catch (e) {
      print("ViewModel Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Keep the bookAppointment method
  final ApiServices _apiService = ApiServices();

  Future<Map<String, dynamic>> bookAppointment({
    required DoctorModel doctor,
    required DateTime date,
    required String time,
    required String patientId,
  }) async {
    // Convert Time to 24h format (HH:mm)
    String formattedTime = time; 
    try {
       if (time.contains("PM") || time.contains("AM")) {
          final dt = DateFormat("h:mm a").parse(time); // Needs intl package
          formattedTime = DateFormat("HH:mm").format(dt); 
       }
    } catch (e) {
      print("Time parsing error: $e, sending original");
    }

    final appointmentData = {
      "doctor_id": doctor.id,
      "patient_id": patientId,
      "date": date.toIso8601String().split('T')[0], // YYYY-MM-DD
      "time": formattedTime,
      "duration": 30, // Default duration
      "price": doctor.consultationFee > 0 ? doctor.consultationFee.toInt() : 500, 
      "note": "General Consultation"
    };

    print("Sending Appointment Data: $appointmentData");

    final result = await _apiService.bookAppointment(appointmentData);
    
    if (result != null && (result['success'] == true || result['appointment'] != null)) {
       // Refresh upcoming list or add locally
       // For now just return success
       return result;
    }
    return result;
  }
}
