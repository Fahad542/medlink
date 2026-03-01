import 'package:flutter/material.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/data/network/api_services.dart';

class DoctorPatientsViewModel extends ChangeNotifier {
  String _searchQuery = "";
  int _selectedFilterIndex = 0;
  final List<String> _filters = ["All", "Current"];
  
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  bool _hasFetched = false;

  DoctorPatientsViewModel();

  Future<void> loadPatientsIfNotLoaded() async {
    if (_hasFetched) return;
    _hasFetched = true;
    await _loadPatients();
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

  final _apiServices = ApiServices();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _loadPatients() async {
    _setLoading(true);
    try {
      final response = await _apiServices.getDoctorPatients();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _allPatients = data.map((json) {
          final profile = json['patientProfile'] ?? {};
          
          DateTime? dob;
          int age = 0;
          if (profile['dob'] != null) {
            try {
              dob = DateTime.parse(profile['dob'].toString());
              age = DateTime.now().year - dob.year;
            } catch (_) {}
          }

          String? avatarUrl = json['profilePhotoUrl'];
          if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
             avatarUrl = 'https://medlink-be-production.up.railway.app$avatarUrl';
          }

          return {
            'user': UserModel(
              id: json['id'].toString(),
              name: json['fullName'] ?? 'Unknown',
              age: age > 0 ? age : null,
              gender: profile['gender']?.toString() ?? 'Unknown',
              profileImage: avatarUrl, 
              email: json['email']?.toString() ?? '', 
              phoneNumber: json['phone']?.toString() ?? '', 
            ),
            'sessions': 1, // Defaulting as API doesn't provide this currently
            'nextSession': null, 
            'isCurrent': true, // Defaulting
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching doctor patients: $e");
    } finally {
      _applyFilters();
      _setLoading(false);
    }
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
