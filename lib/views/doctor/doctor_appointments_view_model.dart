import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/appointment_model.dart';

class DoctorAppointmentsViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  List<AppointmentModel> _upcomingAppointments = [];

  DoctorAppointmentsViewModel() {
    fetchUpcomingAppointments();
  }

  bool get isLoading => _isLoading;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;

  Future<void> fetchUpcomingAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getDoctorUpcomingAppointments();
      if (response != null && response['success'] == true) {
        final data = response['data'] as List?;
        if (data != null) {
          _upcomingAppointments = data.map((item) => AppointmentModel.fromJson(item)).toList();
        } else {
             _upcomingAppointments = [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching upcoming doctor appointments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
