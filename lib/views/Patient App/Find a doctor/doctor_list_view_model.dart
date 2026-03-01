import 'package:flutter/material.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/data/network/api_services.dart';

class DoctorListViewModel extends ChangeNotifier {
  // Logic for DoctorListView
  // Managing filters and search locally for the view

  String _searchQuery = '';
  String? _selectedSpecialty;
  String? _selectedLocation;
  
  List<DoctorModel> _localDoctors = [];
  bool _isLoadingDoctors = false;

  List<DoctorModel> get localDoctors => _localDoctors;
  bool get isLoadingDoctors => _isLoadingDoctors;

  // Options for filters
  List<String> _specialtyOptions = [];

  Future<void> loadDoctorsBySpecialty(int specialtyId) async {
    _isLoadingDoctors = true;
    notifyListeners();
    try {
      final response = await ApiServices().getAvailableDoctorsBySpecialty(specialtyId);
      if (response != null && response['success'] == true) {
         final List<dynamic> data = response['data'];
         _localDoctors = data.map((json) => DoctorModel.fromJson(json)).toList();
      } else {
         _localDoctors = [];
      }
    } catch (e) {
      print("Error fetching by specialty: $e");
      _localDoctors = [];
    }
    _isLoadingDoctors = false;
    notifyListeners();
  }

  Future<void> loadAllDoctors() async {
    _isLoadingDoctors = true;
    notifyListeners();
    try {
      final response = await ApiServices().getDoctors();
      if (response != null && response['success'] == true) {
         final List<dynamic> data = response['data'];
         _localDoctors = data.map((json) => DoctorModel.fromJson(json)).toList();
      } else {
         _localDoctors = [];
      }
    } catch (e) {
      print("Error fetching all doctors: $e");
      _localDoctors = [];
    }
    _isLoadingDoctors = false;
    notifyListeners();
  }

  // Setters for dynamic loading
  void setSpecialtyOptions(List<String> options) {
    if (options.isNotEmpty) {
      _specialtyOptions = options;
      notifyListeners();
    }
  }

  List<String> get specialtyOptions => _specialtyOptions.isNotEmpty
      ? _specialtyOptions
      : ["Cardiologist", "Dentist", "Dermatologist", "General Practitioner", "Neurologist", "Pediatrician"]; // Fallback

  final List<String> locationOptions = [
    "Nairobi", "Mombasa", "Kisumu", "Nakuru", "Eldoret"
  ];

  String get searchQuery => _searchQuery;
  String? get selectedSpecialty => _selectedSpecialty;
  String? get selectedLocation => _selectedLocation;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedSpecialty(String? specialty) {
    _selectedSpecialty = specialty;
    notifyListeners();
  }

  void setSelectedLocation(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  // Search logic for the filter modal
  List<String> filterOptions(List<String> options, String query) {
    if (query.isEmpty) return options;
    return options.where((element) => element.toLowerCase().contains(query.toLowerCase())).toList();
  }
}
