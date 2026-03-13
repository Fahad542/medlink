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
  bool _isLoadingAppointments = false;
  
  int _patientsCount = 0;
  int _appointmentsCount = 0;
  List<AppointmentModel> _upcomingAppointments = [];

  DoctorDashboardViewModel() {
    fetchData();
  }

  bool get isOnline => _isOnline;
  String get earnings => _earnings;
  String get currency => _currency;
  bool get isLoadingEarnings => _isLoadingEarnings;
  bool get isLoadingAppointments => _isLoadingAppointments;
  
  int get patientsCount => _patientsCount;
  int get appointmentsCount => _appointmentsCount;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;

  Future<void> updateAvailability(bool value) async {
    // Optimistically update UI
    final previousStatus = _isOnline;
    _isOnline = value;
    notifyListeners();

    try {
      final response = await _apiServices.updateDoctorAvailability(value);
      if (response == null || response['success'] != true) {
        // Rollback on failure
        _isOnline = previousStatus;
        notifyListeners();
        debugPrint("Failed to update availability on server");
      }
    } catch (e) {
      // Rollback on error
      _isOnline = previousStatus;
      notifyListeners();
      debugPrint("Error updating availability: $e");
    }
  }

  Future<void> fetchData() async {
    await Future.wait([
      fetchEarnings(),
      fetchUpcomingAppointments(),
      fetchAvailability(),
    ]);
  }

  Future<void> fetchAvailability() async {
    try {
      final response = await _apiServices.getDoctorProfile();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          _isOnline = data['isAvailable'] ?? data['isActive'] ?? true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctor availability: $e");
    }
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

  Future<void> fetchUpcomingAppointments() async {
    _isLoadingAppointments = true;
    notifyListeners();

    try {
      final response = await _apiServices.getDoctorUpcomingAppointments();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _upcomingAppointments =
            data.map((json) => AppointmentModel.fromJson(json)).toList();
        _appointmentsCount = _upcomingAppointments.length;
      }
    } catch (e) {
      debugPrint("Error fetching upcoming appointments: $e");
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  Future<void> fetchPatientsCount() async {
    try {
      final response = await _apiServices.getDoctorPatients();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _patientsCount = data.length;
      }
    } catch (e) {
      debugPrint("Error fetching patients count: $e");
    } finally {
      notifyListeners();
    }
  }
}
