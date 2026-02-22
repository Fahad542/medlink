import 'package:flutter/material.dart';
import 'package:medlink/models/doctor_model.dart';

import '../../../data/network/api_services.dart';

class DoctorViewModel extends ChangeNotifier {
  List<DoctorModel> _doctors = [];
  bool _isLoading = false;
  final ApiServices _apiService = ApiServices();

  List<DoctorModel> get doctors => _doctors;
  bool get isLoading => _isLoading;

  // Dynamic Categories from Data
  List<String> get categories {
    final allSpecialties = _doctors.map((d) => d.specialty).toSet().toList();
    allSpecialties.sort(); // Alphabetical
    return allSpecialties;
  }

  DoctorViewModel() {
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getDoctors();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _doctors = data.map((json) => DoctorModel.fromJson(json)).toList();
      } else {
        _doctors = [];
      }
    } catch (e) {
      print("Error loading doctors: $e");
      _doctors = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
