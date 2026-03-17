import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';

enum MissionStatus { dispatched, onRoute, arrived, transporting, completed }

class AmbulanceMissionViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  MissionStatus _status = MissionStatus.dispatched;
  String? _tripId;
  bool _isLoading = false;

  Map<String, dynamic> _missionData = {
    'patientName': 'Loading...',
    'location': '...',
    'destination': 'Hospital',
    'eta': 'Calculating...',
  };

  MissionStatus get status => _status;
  Map<String, dynamic> get missionData => _missionData;
  bool get isLoading => _isLoading;

  AmbulanceMissionViewModel() {
    _loadCurrentTrip();
  }

  Future<void> _loadCurrentTrip() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiServices.getCurrentTrip();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          _updateStateFromData(data);
        }
      }
    } catch (e) {
      debugPrint("Error loading current trip: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateStateFromData(Map<String, dynamic> data) {
    _tripId = data['id']?.toString();
    final statusStr = data['status'];

    // Map backend status to UI status
    if (statusStr == 'ACCEPTED') {
      _status = MissionStatus.dispatched; // Or onRoute depending on flow
    } else if (statusStr == 'ARRIVED') {
      _status = MissionStatus.arrived;
    } else if (statusStr == 'IN_PROGRESS') {
      _status = MissionStatus.transporting;
    } else if (statusStr == 'COMPLETED') {
      _status = MissionStatus.completed;
    }

    _missionData = {
      'patientId': data['patient']?['id'], // Added patientId
      'patientName': data['patient']?['fullName'] ?? 'Unknown Patient',
      'location': data['pickupAddress'] ?? 'Unknown Location',
      'destination': data['dropoffAddress'] ??
          'Hospital', // Assuming backend sends this or we default
      'eta': data['timeMinutes'] != null
          ? '${data['timeMinutes']} mins'
          : '${data['distanceKm'] ?? '--'} km',
    };
    notifyListeners();
  }

  Future<void> updateStatus() async {
    if (_tripId == null) return;

    try {
      if (_status == MissionStatus.dispatched) {
        // UI Action: "Start Route" -> Move to "On Route" (Local state only, or trigger navigation)
        // No backend call needed for "Starting Navigation" unless we want to track it.
        // Backend stays ACCEPTED.
        _status = MissionStatus.onRoute;
        notifyListeners();
        // Here you would launch Google Maps
      } else if (_status == MissionStatus.onRoute) {
        // UI Action: "Arrived at Location" -> Backend: ARRIVED
        final response = await _apiServices.arriveAtPickup(_tripId!);
        if (response != null && response['success'] == true) {
          _status = MissionStatus.arrived;
          notifyListeners();
        }
      } else if (_status == MissionStatus.arrived) {
        // UI Action: "Start Transport" -> Backend: IN_PROGRESS
        final response = await _apiServices
            .startRoute(_tripId!); // reusing startRoute for 'transporting'
        if (response != null && response['success'] == true) {
          _status = MissionStatus.transporting;
          notifyListeners();
        }
      } else if (_status == MissionStatus.transporting) {
        // UI Action: "Complete Mission" -> Backend: COMPLETED
        final response = await _apiServices.completeTrip(_tripId!);
        if (response != null && response['success'] == true) {
          _status = MissionStatus.completed;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }
}
