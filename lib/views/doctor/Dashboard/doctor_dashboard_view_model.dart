import 'package:flutter/material.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/models/user_model.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  bool _isOnline = true;
  final String _earnings = "24,450.00";
  final int _patientsCount = 124;
  final int _appointmentsCount = 8;
  
  final List<AppointmentModel> _upcomingAppointments = List.generate(2, (index) {
     bool isVideo = index % 2 == 0;
     return AppointmentModel(
        id: "mock_$index",
        doctorId: "doc_1",
        userId: "user_1",
        dateTime: DateTime.now().add(Duration(days: index)),
        status: AppointmentStatus.upcoming,
        type: isVideo ? AppointmentType.online : AppointmentType.inPerson,
        user: UserModel(
            id: "user_1",
            name: index == 0 ? "John Smith" : "Sarah Connor",
            email: "john@example.com",
            phoneNumber: "555-0123",
            profileImage: null 
        )
    );
  });

  bool get isOnline => _isOnline;
  String get earnings => _earnings;
  int get patientsCount => _patientsCount;
  int get appointmentsCount => _appointmentsCount;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;

  void toggleOnlineStatus(bool value) {
    _isOnline = value;
    notifyListeners();
  }
}
