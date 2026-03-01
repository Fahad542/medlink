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
      List<AppointmentModel> fetched = [];
      if (status == 'upcoming') {
        final response = await _apiService.getUpcomingAppointments();
        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'];
          fetched = data.map((json) => AppointmentModel.fromJson(json)).toList();
        }
        _upcomingAppointments = fetched;
      } else if (status == 'cancelled') {
        final response = await _apiService.getCancelledAppointments();
        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'];
          fetched = data.map((json) => AppointmentModel.fromJson(json)).toList();
        }
        _cancelledAppointments = fetched;
      } else if (status == 'past') {
        final response = await _apiService.getPastAppointments();
        if (response != null && response['success'] == true) {
          final List<dynamic> data = response['data'];
          fetched = data.map((json) => AppointmentModel.fromJson(json)).toList();
        }
        _pastAppointments = fetched;
      } else {
        // Fallback for other status
        final data = await _apiService.getPatientAppointments(patientId, status: status);
        fetched = data.map((json) => AppointmentModel.fromJson(json)).toList();
      }

    } catch (e) {
      print("ViewModel Error fetching $status appointments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      final response = await _apiService.cancelAppointment(appointmentId, reason);
      if (response != null && response['success'] == true) {
        // Find it in upcoming list and move it to cancelled, or just refetch
        _upcomingAppointments.removeWhere((a) => a.id == appointmentId);
        
        // Since we removed it, ideally we'd re-fetch cancelled or add it if we had the full model
        // To be safe, just notify listeners so UI updates. The user might switch to cancelled tab which will refetch.
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print("Error cancelling appointment: $e");
      return false;
    }
  }



  Future<void> loadUpcomingAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getUpcomingAppointments();
      if (response != null && response['success'] == true) {
         final List<dynamic> data = response['data'];
         _upcomingAppointments = data.map((json) => AppointmentModel.fromJson(json)).toList();
      } else {
         _upcomingAppointments = [];
      }
    } catch (e) {
      print("Error loading upcoming appointments: $e");
      _upcomingAppointments = [];
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
    String description = "General Consultation",
  }) async {
    // Parse start time and calculate end time
    DateTime? parsedStartTime;
    try {
       parsedStartTime = DateFormat("h:mm a").parse(time); 
    } catch (e) {
       parsedStartTime = DateFormat("HH:mm").parse(time);
    }

    String formattedStartTime = DateFormat("HH:mm").format(parsedStartTime);
    DateTime parsedEndTime = parsedStartTime.add(const Duration(minutes: 30));
    String formattedEndTime = DateFormat("HH:mm").format(parsedEndTime);

    int doctorIdInt = int.tryParse(doctor.id) ?? 0;

    final appointmentData = {
      "doctorId": doctorIdInt,
      "date": DateFormat('yyyy-MM-dd').format(date),
      "startTime": formattedStartTime,
      "endTime": formattedEndTime,
      "description": description.isEmpty ? "General Consultation" : description,
    };

    print("Sending Appointment Data: $appointmentData");

    try {
      final result = await _apiService.bookAppointment(appointmentData);
      
      if (result != null && (result['success'] == true || result['appointment'] != null || result['data'] != null)) {
         return {'success': true, 'message': 'Booking confirmed.'};
      } else {
         return {'success': false, 'message': result?['message'] ?? 'Failed to book appointment'};
      }
    } catch (e) {
      print("Booking error: $e");
      return {'success': false, 'message': 'An error occurred during booking: $e'};
    }
  }
}
