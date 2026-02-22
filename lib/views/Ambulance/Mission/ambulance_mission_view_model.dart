import 'package:flutter/material.dart';

enum MissionStatus {
  dispatched,
  onRoute,
  arrived,
  transporting,
  completed
}

class AmbulanceMissionViewModel extends ChangeNotifier {
  MissionStatus _status = MissionStatus.dispatched;
  
  // Mock Patient Data
  final Map<String, dynamic> _missionData = {
    'patientName': 'Michael Brown',
    'location': '123 Main St, Central Park',
    'destination': 'City General Hospital',
    'eta': '12 mins',
  };

  MissionStatus get status => _status;
  Map<String, dynamic> get missionData => _missionData;

  String get statusText {
    switch (_status) {
      case MissionStatus.dispatched: return "Dispatched";
      case MissionStatus.onRoute: return "On Route to Patient";
      case MissionStatus.arrived: return "Arrived at Scene";
      case MissionStatus.transporting: return "Transporting to Hospital";
      case MissionStatus.completed: return "Mission Completed";
    }
  }

  double get progress {
    // 0.0 to 1.0 based on status for a progress bar
    return (_status.index + 1) / MissionStatus.values.length;
  }

  void updateStatus() {
    if (_status.index < MissionStatus.values.length - 1) {
      _status = MissionStatus.values[_status.index + 1];
      notifyListeners();
    }
  }

  void cancelMission() {
    // Logic to cancel
  }
}
