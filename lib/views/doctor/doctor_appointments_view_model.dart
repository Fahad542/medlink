import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/appointment_model.dart';

class DoctorAppointmentsViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  List<AppointmentModel> _cancelledAppointments = [];

  bool _hasFetched = false;

  DoctorAppointmentsViewModel() {
    // Removed automatic fetch to support lazy loading
  }

  Future<void> loadAppointmentsIfNotLoaded() async {
    if (_hasFetched) return;
    _hasFetched = true;
    await fetchAllAppointments();
  }

  bool get isLoading => _isLoading;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  List<AppointmentModel> get pastAppointments => _pastAppointments;
  List<AppointmentModel> get cancelledAppointments => _cancelledAppointments;

  Future<void> fetchAllAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchUpcomingAppointments(),
        fetchPastAppointments(),
        fetchCancelledAppointments(),
      ]);
    } catch (e) {
      debugPrint("Error fetching all doctor appointments: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingAppointments() async {
    try {
      final response = await _apiServices.getDoctorUpcomingAppointments();
      if (response != null && response['success'] == true) {
        final data = response['data'] as List?;
        if (data != null) {
          _upcomingAppointments = data
              .map((item) => AppointmentModel.fromJson(item))
              .where((a) => a.isDoctorUpcomingSlot)
              .toList();
          AppointmentModel.sortByCreatedAtDescending(_upcomingAppointments);
        } else {
          _upcomingAppointments = [];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching upcoming doctor appointments: $e");
    }
  }

  Future<void> fetchPastAppointments() async {
    try {
      final response = await _apiServices.getDoctorPastAppointments();
      if (response != null && response['success'] == true) {
        final data = response['data'] as List?;
        if (data != null) {
          _pastAppointments =
              data.map((item) => AppointmentModel.fromJson(item)).toList();
          AppointmentModel.sortByCreatedAtDescending(_pastAppointments);
        } else {
          _pastAppointments = [];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching past doctor appointments: $e");
    }
  }

  Future<void> fetchCancelledAppointments() async {
    try {
      final response = await _apiServices.getDoctorCancelledAppointments();
      if (response != null && response['success'] == true) {
        final data = response['data'] as List?;
        if (data != null) {
          _cancelledAppointments =
              data.map((item) => AppointmentModel.fromJson(item)).toList();
          AppointmentModel.sortByCreatedAtDescending(_cancelledAppointments);
        } else {
          _cancelledAppointments = [];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching cancelled doctor appointments: $e");
    }
  }

  Future<bool> approveAppointment(String id) async {
    try {
      final response = await _apiServices.approveAppointment(id);
      if (response != null && response['success'] == true) {
        await fetchAllAppointments();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error approving appointment: $e");
      return false;
    }
  }

  Future<bool> cancelAppointment(String id, String reason) async {
    try {
      final response = await _apiServices.doctorCancelAppointment(id, reason);
      if (response != null && response['success'] == true) {
        _upcomingAppointments.removeWhere((a) => a.id == id);
        notifyListeners();
        await fetchAllAppointments();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error cancelling appointment: $e");
      return false;
    }
  }

  void removeUpcomingAppointmentById(String id) {
    _upcomingAppointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}
