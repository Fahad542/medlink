import 'package:flutter/material.dart';

class PatientHistoryViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> _visits = [];

  PatientHistoryViewModel() {
    _loadVisits();
  }

  List<Map<String, dynamic>> get visits => _visits;

  void _loadVisits() {
    // Mock data
    _visits = [
      {
        "title": "General Checkup",
        "doctor": "Dr. Alex Smith",
        "symptoms": "Fever, Headache",
        "date": "Today, 10:00 AM",
        "status": "Completed"
      },
      {
        "title": "Follow-up",
        "doctor": "Dr. Sarah Johnson",
        "symptoms": "Post-surgery check",
        "date": "12 Dec, 4:15 PM",
        "status": "Completed"
      },
      {
        "title": "Urgent Care",
        "doctor": "Dr. Michael Chen",
        "symptoms": "Stomach pain",
        "date": "05 Dec, 11:00 AM",
        "status": "Completed"
      },
      {
        "title": "Routine Lab Visit",
        "doctor": "Dr. Emily Davis",
        "symptoms": "Blood work",
        "date": "01 Dec, 3:00 PM",
        "status": "Completed"
      },
    ];
    notifyListeners();
  }
}
