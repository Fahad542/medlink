import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/sos_socket_service.dart';

enum MissionStatus { dispatched, onRoute, arrived, transporting, completed }

class AmbulanceMissionViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final SosSocketService _socket = SosSocketService.instance;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<Map<String, dynamic>>? _tripSub;
  StreamSubscription<Map<String, dynamic>>? _locSub;

  MissionStatus _status = MissionStatus.dispatched;
  String? _tripId;
  bool _isLoading = false;
  double? _driverLat;
  double? _driverLng;
  double? _driverHeading;
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;

  Map<String, dynamic> _missionData = {
    'patientName': 'Loading...',
    'location': '...',
    'destination': 'Hospital',
    'eta': 'Calculating...',
  };

  MissionStatus get status => _status;
  Map<String, dynamic> get missionData => _missionData;
  bool get isLoading => _isLoading;
  double? get driverLat => _driverLat;
  double? get driverLng => _driverLng;
  double? get driverHeading => _driverHeading;
  double? get pickupLat => _pickupLat;
  double? get pickupLng => _pickupLng;
  double? get dropoffLat => _dropoffLat;
  double? get dropoffLng => _dropoffLng;

  AmbulanceMissionViewModel() {
    _loadCurrentTrip();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _tripSub?.cancel();
    _locSub?.cancel();
    super.dispose();
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
          final tripIdNum = int.tryParse(_tripId ?? '');
          if (tripIdNum != null) {
            _socket.joinTrip(tripIdNum);
            _startTripRealtime(tripIdNum);
            await _startLocationSharing(tripIdNum);
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading current trip: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTripRealtime(int tripId) {
    _tripSub ??= _socket.tripUpdatedStream.listen((payload) {
      if (payload['id']?.toString() != tripId.toString()) return;
      _updateStateFromData(payload);
    });

    _locSub ??= _socket.tripLocationUpdatedStream.listen((payload) {
      if (payload['tripId']?.toString() != tripId.toString()) return;
      final etaMinutes = payload['etaMinutes'];
      final distanceKm = payload['distanceKm'];
      final etaText = etaMinutes != null
          ? '${int.tryParse(etaMinutes.toString()) ?? etaMinutes} mins'
          : (distanceKm != null
              ? '${double.tryParse(distanceKm.toString())?.toStringAsFixed(1) ?? distanceKm} km'
              : null);
      if (etaText != null) {
        _missionData = {..._missionData, 'eta': etaText};
        notifyListeners();
      }
    });
  }

  Future<void> _startLocationSharing(int tripId) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _driverLat = current.latitude;
      _driverLng = current.longitude;
      _driverHeading = current.heading;
      notifyListeners();
      final speedKmh = current.speed.isFinite ? (current.speed * 3.6) : null;
      _socket.updateTripLocation(
        tripId: tripId,
        lat: current.latitude,
        lng: current.longitude,
        speed: speedKmh,
        heading: current.heading.isFinite ? current.heading : null,
      );
    } catch (_) {}

    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      _driverLat = pos.latitude;
      _driverLng = pos.longitude;
      _driverHeading = pos.heading;
      notifyListeners();
      final speedKmh = pos.speed.isFinite ? (pos.speed * 3.6) : null;
      _socket.updateTripLocation(
        tripId: tripId,
        lat: pos.latitude,
        lng: pos.longitude,
        speed: speedKmh,
        heading: pos.heading.isFinite ? pos.heading : null,
      );
    });
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

    _pickupLat = data['pickupLat'] != null
        ? double.tryParse(data['pickupLat'].toString())
        : _pickupLat;
    _pickupLng = data['pickupLng'] != null
        ? double.tryParse(data['pickupLng'].toString())
        : _pickupLng;
    _dropoffLat = data['dropoffLat'] != null
        ? double.tryParse(data['dropoffLat'].toString())
        : _dropoffLat;
    _dropoffLng = data['dropoffLng'] != null
        ? double.tryParse(data['dropoffLng'].toString())
        : _dropoffLng;

    final sosId = data['sosId']?.toString();
    final tripId = data['id']?.toString();

    _missionData = {
      'sosId': sosId,
      'tripId': tripId,
      'patientId': data['patient']?['id'], // Added patientId
      'patientName': data['patient']?['fullName'] ?? 'Unknown Patient',
      'patientPhotoUrl': data['patient']?['profilePhotoUrl'],
      'location': data['pickupAddress'] ??
          ((data['pickupLat'] != null && data['pickupLng'] != null)
              ? 'Lat: ${data['pickupLat']}, Lng: ${data['pickupLng']}'
              : 'Unknown Location'),
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
