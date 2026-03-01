import 'package:flutter/material.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/data/network/api_services.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isOnline = true;
  String _earnings = "0";
  String _currency = "PKR";
  bool _isLoadingEarnings = false;
  
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

  DoctorDashboardViewModel() {
    fetchEarnings();
  }

  bool get isOnline => _isOnline;
  String get earnings => _earnings;
  String get currency => _currency;
  bool get isLoadingEarnings => _isLoadingEarnings;
  
  int get patientsCount => _patientsCount;
  int get appointmentsCount => _appointmentsCount;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;

  void toggleOnlineStatus(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  Future<void> fetchEarnings() async {
    _isLoadingEarnings = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final response = await _apiServices.getDoctorMonthlyEarnings(now.year, now.month);
      
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          _earnings = data['totalAmount']?.toString() ?? "0";
          _currency = data['currency'] ?? "PKR";
        }
      }
    } catch (e) {
      debugPrint("Error fetching earnings: $e");
    } finally {
      _isLoadingEarnings = false;
      notifyListeners();
    }
  }
}
