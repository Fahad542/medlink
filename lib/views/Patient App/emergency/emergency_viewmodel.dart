import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/ambulance_model.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/services/sos_socket_service.dart';

class EmergencyViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final SosSocketService _socket = SosSocketService.instance;
  bool _isSosActive = false;
  AmbulanceModel? _assignedAmbulance;
  String? _sosStatus;
  String? _sosId;
  String? get sosId => _sosId;
  Map<String, dynamic>? _activeTrip;
  Timer? _pollingTimer;
  bool _realtimeEnabled = false;
  StreamSubscription<Map<String, dynamic>>? _sosSub;
  StreamSubscription<Map<String, dynamic>>? _tripSub;
  StreamSubscription<Map<String, dynamic>>? _locSub;

  int? _currentUserId;

  bool get isSosActive => _isSosActive;
  AmbulanceModel? get assignedAmbulance => _assignedAmbulance;
  String? get sosStatus => _sosStatus;
  Map<String, dynamic>? get activeTrip => _activeTrip;
  String? get tripStatus => _activeTrip?['status']?.toString();

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _sosSub?.cancel();
    _tripSub?.cancel();
    _locSub?.cancel();
    super.dispose();
  }

  void startRealtime({required int userId, required String token}) {
    _currentUserId = userId;
    _realtimeEnabled = true;
    _pollingTimer?.cancel();
    _socket.connect(url: '${AppUrl.baseUrl}/sos', token: token);
    _socket.joinUser();

    _sosSub ??= _socket.sosUpdatedStream.listen((payload) {
      final patientId = payload['patientId'];
      if (patientId == null || patientId != _currentUserId) return;

      _sosStatus = payload['status']?.toString();
      _sosId = payload['id']?.toString();
      final assigned = payload['assignedDriver'];
      if (assigned is Map) {
        _assignedAmbulance = AmbulanceModel.fromJson(
          Map<String, dynamic>.from(assigned),
        );
      }

      if (_sosStatus == 'RESOLVED' || _sosStatus == 'CANCELLED') {
        cancelSos();
        return;
      }

      _isSosActive = true;
      notifyListeners();
    });

    _tripSub ??= _socket.tripUpdatedStream.listen((payload) {
      final patientId = payload['patientId'];
      if (patientId == null || patientId != _currentUserId) return;

      _activeTrip = Map<String, dynamic>.from(payload);
      final tripId = _activeTrip?['id'];
      final status = _activeTrip?['status']?.toString();

      if (status == 'COMPLETED' || status == 'CANCELLED') {
        cancelSos();
        return;
      }

      if (tripId is int) {
        _socket.joinTrip(tripId);
      } else if (tripId is String) {
        final parsed = int.tryParse(tripId);
        if (parsed != null) _socket.joinTrip(parsed);
      }
      notifyListeners();
    });

    _locSub ??= _socket.tripLocationUpdatedStream.listen((payload) {
      final tripId = payload['tripId'];
      final currentTripId = _activeTrip?['id'];
      if (tripId == null || currentTripId == null) return;
      if (tripId.toString() != currentTripId.toString()) return;

      final latest = {
        'lat': payload['lat'],
        'lng': payload['lng'],
        'speed': payload['speed'],
        'heading': payload['heading'],
        'createdAt': payload['createdAt'],
      };
      _activeTrip = {
        ...(_activeTrip ?? {}),
        if (payload['distanceKm'] != null) 'distanceKm': payload['distanceKm'],
        if (payload['etaMinutes'] != null) 'timeMinutes': payload['etaMinutes'],
        'latestLocation': latest,
      };
      notifyListeners();
    });
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
            _sosId = sos['id']?.toString();
            _sosStatus = sos['status']?.toString();
            _activeTrip = sos['trip'] is Map
                ? Map<String, dynamic>.from(sos['trip'])
                : null;
            final tripId = _activeTrip?['id'];
            if (tripId is int) {
              _socket.joinTrip(tripId);
            } else if (tripId is String) {
              final parsed = int.tryParse(tripId);
              if (parsed != null) _socket.joinTrip(parsed);
            }
            if (sos['status'] == 'ASSIGNED' && sos['assignedDriver'] != null) {
              _assignedAmbulance =
                  AmbulanceModel.fromJson(sos['assignedDriver']);
            }
            notifyListeners();
            if (!_realtimeEnabled) {
              _startPollingForDriver();
            }
            debugPrint("Restored active SOS session: ${sos['id']}");
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking active SOS: $e");
    }
  }

  Future<void> triggerSos(BuildContext context) async {
    // Basic SOS trigger
    _triggerSosInternal(context);
  }

  Future<void> triggerSosWithDestination(BuildContext context, double destLat, double destLng) async {
    _triggerSosInternal(context, destLat: destLat, destLng: destLng);
  }

  Future<void> _triggerSosInternal(BuildContext context, {double? destLat, double? destLng}) async {
    _isSosActive = true;
    notifyListeners();

    try {
      // Hardcoded current location for demo (should ideally come from location service)
      const latitude = 37.7749;
      const longitude = -122.4194;

      final response = await _apiServices.createSos(
        latitude, 
        longitude,
        destinationLat: destLat,
        destinationLng: destLng,
      );

      if (response != null) {
        if (response['data'] != null) {
          _sosId = response['data']['id']?.toString();
        }
        if (!_realtimeEnabled) {
          _startPollingForDriver();
        } else {
          await checkActiveSos();
        }

        debugPrint("SOS Created: ${response['data']}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SOS Alert Sent Successfully! Finding Driver...'),
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startPollingForDriver() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await _apiServices.getMySos();
        if (response != null && response['data'] is List) {
          final list = response['data'] as List;
          if (list.isNotEmpty) {
            // Check the most recent SOS
            final sos = list.first;
            _sosStatus = sos['status']?.toString();
            _activeTrip = sos['trip'] is Map
                ? Map<String, dynamic>.from(sos['trip'])
                : null;
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

  String get sosTitle {
    if (!_isSosActive) return '';
    final trip = tripStatus;
    if (trip == 'ARRIVED') return 'Ambulance Arrived';
    if (trip == 'IN_PROGRESS') return 'Trip In Progress';
    if (_sosStatus == 'OPEN') return 'Finding Driver';
    return 'Ambulance Dispatched';
  }

  String get sosEtaText {
    final trip = _activeTrip;
    if (trip == null) return _assignedAmbulance?.estimatedArrival ?? '...';
    final timeMinutes = trip['timeMinutes'];
    final distanceKm = trip['distanceKm'];
    if (timeMinutes != null) {
      final mins = int.tryParse(timeMinutes.toString());
      if (mins != null && mins > 0) return '$mins min';
    }
    if (distanceKm != null) {
      final km = double.tryParse(distanceKm.toString());
      if (km != null && km > 0) return '${km.toStringAsFixed(1)} km';
    }
    return _assignedAmbulance?.estimatedArrival ?? '...';
  }

  void cancelSos() {
    _isSosActive = false;
    _assignedAmbulance = null;
    _sosStatus = null;
    _sosId = null;
    _activeTrip = null;
    _pollingTimer?.cancel();
    notifyListeners();
  }
}
