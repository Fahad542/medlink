import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/patient_appointment_history_model.dart';

class PastAppointmentsViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<PatientAppointmentHistoryData> _history = [];
  List<PatientAppointmentHistoryData> get history => _history;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHistory([String? patientId]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiServices.getDoctorAppointmentsHistory(patientId);
      final model = PatientAppointmentHistoryModel.fromJson(response);
      
      if (model.success == true) {
        _history = model.data ?? [];
      } else {
        _errorMessage = "Failed to load history";
      }
    } catch (e) {
      _errorMessage = "Something went wrong. Please try again.";
      debugPrint("Error fetching history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
