import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/ambulance_model.dart';

class EmergencyViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  bool _isSosActive = false;
  AmbulanceModel? _assignedAmbulance;
  Timer? _pollingTimer;

  bool get isSosActive => _isSosActive;
  AmbulanceModel? get assignedAmbulance => _assignedAmbulance;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> checkActiveSos() async {
    try {
      final response = await _apiServices.getMySos();
      if (response != null && response['data'] is List) {
        final list = response['data'] as List;
        if (list.isNotEmpty) {
          final sos = list.first;
          // Check if the latest SOS is still active
          if (sos['status'] == 'OPEN' || sos['status'] == 'ASSIGNED') {
            _isSosActive = true;
            if (sos['status'] == 'ASSIGNED' && sos['assignedDriver'] != null) {
              _assignedAmbulance =
                  AmbulanceModel.fromJson(sos['assignedDriver']);
            }
            notifyListeners();
            _startPollingForDriver();
            debugPrint("Restored active SOS session: ${sos['id']}");
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking active SOS: $e");
    }
  }

  Future<void> triggerSos(BuildContext context) async {
    _isSosActive = true;
    notifyListeners();

    try {
      // Hardcoded location for demo
      const latitude = 37.7749;
      const longitude = -122.4194;

      final response = await _apiServices.createSos(latitude, longitude);

      if (response != null) {
        // Start polling for driver assignment
        _startPollingForDriver();

        debugPrint("SOS Created: ${response['data']}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS Alert Sent Successfully! Help is on the way.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        _isSosActive = false;
        notifyListeners();
        debugPrint("Failed to create SOS");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send SOS')),
          );
        }
      }
    } catch (e) {
      _isSosActive = false;
      notifyListeners();
      debugPrint("Error creating SOS: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SOS: $e')),
        );
      }
    }
  }

  void _startPollingForDriver() {
    _pollingTimer?.cancel();
    // Poll every 10 seconds instead of 5 to reduce server load
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final response = await _apiServices.getMySos();
        if (response != null && response['data'] is List) {
          final list = response['data'] as List;
          if (list.isNotEmpty) {
            // Check the most recent SOS
            final sos = list.first;
            if (sos['status'] == 'ASSIGNED' && sos['assignedDriver'] != null) {
              _assignedAmbulance =
                  AmbulanceModel.fromJson(sos['assignedDriver']);
              notifyListeners();
              // Driver found, maybe slow down polling or stop if we only need one-time assignment
              // For tracking, we might want to keep polling if we implement live location later
            } else if (sos['status'] == 'RESOLVED' ||
                sos['status'] == 'CANCELLED') {
              cancelSos();
            }
          }
        }
      } catch (e) {
        debugPrint("Error polling SOS: $e");
      }
    });
  }

  void cancelSos() {
    _isSosActive = false;
    _assignedAmbulance = null;
    _pollingTimer?.cancel();
    notifyListeners();
  }
}
