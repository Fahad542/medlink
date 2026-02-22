import 'package:flutter/material.dart';
import 'package:medlink/models/ambulance_model.dart';

class EmergencyViewModel extends ChangeNotifier {
  bool _isSosActive = false;
  AmbulanceModel? _assignedAmbulance;

  bool get isSosActive => _isSosActive;
  AmbulanceModel? get assignedAmbulance => _assignedAmbulance;

  void triggerSos() async {
    _isSosActive = true;
    notifyListeners();
    // Simulate finding ambulance
    await Future.delayed(const Duration(seconds: 3));
    _assignedAmbulance = AmbulanceModel(
      id: "AMB-001",
      driverName: "Samuel K.",
      plateNumber: "KBA 123A",
      currentLat: -1.2921,
      currentLng: 36.8219,
      vehicleType: "ICU Ambulance",
      status: "Enroute",
      estimatedArrival: "5 mins",
    );
    notifyListeners();
  }

  void cancelSos() {
    _isSosActive = false;
    _assignedAmbulance = null;
    notifyListeners();
  }
}
