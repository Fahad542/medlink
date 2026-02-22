import 'package:flutter/material.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/models/appointment_model.dart';

class DoctorPatientsViewModel extends ChangeNotifier {
  String _searchQuery = "";
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Current"];
  
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  DoctorPatientsViewModel() {
    _loadPatients();
  }

  List<Map<String, dynamic>> get patients => _filteredPatients;
  List<String> get filters => _filters;
  int get selectedFilterIndex => _selectedFilterIndex;

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setFilterIndex(int index) {
    _selectedFilterIndex = index;
    _applyFilters();
  }

  void _loadPatients() {
    // Mock data with realistic names and profile images
    final patientNames = [
      {'name': 'Sarah Johnson', 'image': 'https://i.pravatar.cc/150?u=sarah_johnson'},
      {'name': 'Michael Chen', 'image': 'https://i.pravatar.cc/150?u=michael_chen'},
      {'name': 'Emily Rodriguez', 'image': 'https://i.pravatar.cc/150?u=emily_rodriguez'},
      {'name': 'James Williams', 'image': 'https://i.pravatar.cc/150?u=james_williams'},
      {'name': 'Olivia Brown', 'image': 'https://i.pravatar.cc/150?u=olivia_brown'},
      {'name': 'David Martinez', 'image': 'https://i.pravatar.cc/150?u=david_martinez'},
      {'name': 'Sophia Anderson', 'image': 'https://i.pravatar.cc/150?u=sophia_anderson'},
      {'name': 'Daniel Taylor', 'image': 'https://i.pravatar.cc/150?u=daniel_taylor'},
      {'name': 'Emma Thomas', 'image': 'https://i.pravatar.cc/150?u=emma_thomas'},
      {'name': 'Christopher Lee', 'image': 'https://i.pravatar.cc/150?u=christopher_lee'},
    ];
    
    _allPatients = List.generate(10, (index) => {
      'user': UserModel(
        id: 'p_$index',
        name: patientNames[index]['name']!,
        age: 25 + index,
        gender: index % 2 == 0 ? 'Male' : 'Female',
        profileImage: patientNames[index]['image'], 
        email: '', 
        phoneNumber: '', 
      ),
      'sessions': (index + 1) * 2,
      'nextSession': index % 2 == 0 ? 'Tomorrow, 10:00 AM' : null,
      'isCurrent': index < 5,
    });
    _applyFilters();
  }

  void _applyFilters() {
    _filteredPatients = _allPatients.where((data) {
      final user = data['user'] as UserModel;
      final nameMatches = user.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      
      bool filterMatches = true;
      if (_selectedFilterIndex == 1) { // Current
         filterMatches = data['isCurrent'] == true;
      }

      return nameMatches && filterMatches;
    }).toList();
    notifyListeners();
  }
}
