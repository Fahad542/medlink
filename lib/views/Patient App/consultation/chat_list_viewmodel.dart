import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/views/services/session_view_model.dart';

class ChatListViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final UserViewModel _userViewModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> get appointments => _appointments;

  ChatListViewModel(this._userViewModel) {
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch upcoming and past appointments to show in chat list
      final upcoming = await _apiServices.getUpcomingAppointments();
      final past = await _apiServices.getPastAppointments();
      
      List<AppointmentModel> all = [];
      if (upcoming != null && upcoming['success'] == true) {
        final List<dynamic> data = upcoming['data'];
        all.addAll(data.map((json) => AppointmentModel.fromJson(json)));
      }
      if (past != null && past['success'] == true) {
        final List<dynamic> data = past['data'];
        all.addAll(data.map((json) => AppointmentModel.fromJson(json)));
      }
      
      // Filter for appointments that are suitable for chat (e.g. not cancelled)
      _appointments = all.where((a) => a.status != AppointmentStatus.cancelled).toList();
      
      // Sort by date descending
      _appointments.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
    } catch (e) {
      debugPrint("Error fetching appointments for chat: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
