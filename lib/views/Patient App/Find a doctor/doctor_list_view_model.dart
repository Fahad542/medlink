import 'package:flutter/material.dart';

class DoctorListViewModel extends ChangeNotifier {
  // Logic for DoctorListView
  // Managing filters and search locally for the view

  String _searchQuery = '';
  String? _selectedSpecialty;
  String? _selectedLocation;

  // Options for filters
  List<String> _specialtyOptions = [];

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
