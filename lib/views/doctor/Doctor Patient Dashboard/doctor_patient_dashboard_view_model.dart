import 'package:flutter/material.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/patient_profile_model.dart';
import 'package:medlink/models/patient_appointment_history_model.dart';

class DoctorPatientDashboardViewModel extends ChangeNotifier {
  final _apiService = ApiServices();
  final UserModel patient;

  DoctorPatientDashboardViewModel(this.patient);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  PatientProfileData? _patientProfile;
  PatientProfileData? get patientProfile => _patientProfile;

  List<PatientAppointmentHistoryData> _appointmentHistory = [];
  List<PatientAppointmentHistoryData> get appointmentHistory => _appointmentHistory;

  Future<void> fetchPatientProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Profile
      final profileResponse = await _apiService.getPatientProfileForDoctor(patient.id);
      final profileModel = PatientProfileModel.fromJson(profileResponse);
      if (profileModel.success == true) {
        _patientProfile = profileModel.data;
      }

      // 2. Fetch Appointment History
      final historyResponse = await _apiService.getDoctorAppointmentsHistory(patient.id);
      final historyModel = PatientAppointmentHistoryModel.fromJson(historyResponse);
      if (historyModel.success == true) {
        _appointmentHistory = historyModel.data ?? [];
      }
    } catch (e) {
      print("Error fetching patient dashboard data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initials
  String get patientInitials => patient.name.isNotEmpty 
      ? patient.name.substring(0, 1).toUpperCase() 
      : "PT";
}
