import 'package:flutter/material.dart';

class AmbulanceHistoryViewModel extends ChangeNotifier {
  final List<Map<String, dynamic>> _trips = [
    {
      "patientName": "John Doe",
      "date": "Oct 24, 2024",
      "time": "10:30 AM",
      "status": "Completed",
      "location": "123 Main St, New York",
      "earnings": "\$45.00"
    },
    {
      "patientName": "Jane Smith",
      "date": "Oct 23, 2024",
      "time": "02:15 PM",
      "status": "Completed",
      "location": "456 Park Ave, New York",
      "earnings": "\$32.50"
    },
    {
      "patientName": "Emergency Run",
      "date": "Oct 22, 2024",
      "time": "09:00 PM",
      "status": "Completed",
      "location": "789 Broadway, New York",
      "earnings": "\$60.00"
    },
  ];

  List<Map<String, dynamic>> get trips => _trips;
}
