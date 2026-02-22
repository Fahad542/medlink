import 'package:flutter/material.dart';

class AmbulanceDashboardViewModel extends ChangeNotifier {
  bool _isOnline = true;
  List<Map<String, dynamic>> _activeRequests = [];

  // Stats
  final int _completedTrips = 5;
  final String _earnings = "150.00";
  final double _rating = 4.8;

  AmbulanceDashboardViewModel() {
    _loadActiveRequests();
  }

  bool get isOnline => _isOnline;
  List<Map<String, dynamic>> get activeRequests => _activeRequests;
  int get completedTrips => _completedTrips;
  String get earnings => _earnings;
  double get rating => _rating;

  void toggleOnlineStatus(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  void _loadActiveRequests() {
    // Initial mock data load - No auto-recurring popup
    if (_isOnline) {
      _activeRequests = [
        {
          'id': 'REQ_123',
          'patientName': 'Michael Brown',
          'severity': 'Critical',
          'distance': '2.5 km',
          'location': '123 Main St, Central Park',
          'incident': 'Cardiac Arrest',
          'time': '2 mins ago',
        },
        {
          'id': 'REQ_124',
          'patientName': 'Sarah Jones',
          'severity': 'Moderate',
          'distance': '4.1 km',
          'location': '456 Elm St, Downtown',
          'incident': 'Road Accident',
          'time': '5 mins ago',
        },
        {
           'id': 'REQ_125',
           'patientName': 'David Wilson',
           'severity': 'High',
           'distance': '1.2 km',
           'location': '789 Oak Ave, Westside',
           'incident': 'Respiratory Failure',
           'time': '8 mins ago',
         },
      ];
      notifyListeners();
    }
  }

  void acceptRequest(String requestId) {
    // Remove request from list after acceptance and navigate
    _activeRequests.removeWhere((req) => req['id'] == requestId);
    notifyListeners();
  }

  void declineRequest(String requestId) {
    _activeRequests.removeWhere((req) => req['id'] == requestId);
    notifyListeners();
  }
}
