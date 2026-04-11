import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/services/sos_socket_service.dart';

class AmbulanceMainViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final SosSocketService _socket = SosSocketService.instance;

  int _currentIndex = 0;
  Map<String, dynamic>? _activeTrip;
  Timer? _tripPollingTimer;
  StreamSubscription<Map<String, dynamic>>? _tripSub;
  StreamSubscription<Map<String, dynamic>>? _locSub;
  StreamSubscription<Map<String, dynamic>>? _sosDriverSub;
  StreamSubscription<Position>? _posSub;
  /// Trip id as string (numeric or UUID) for location emit + dedupe.
  String? _sharingTripIdKey;
  int? _currentUserId;
  bool _realtimeEnabled = false;

  int get currentIndex => _currentIndex;
  Map<String, dynamic>? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;
  String get activeTripStatus => (_activeTrip?['status']?.toString() ?? '');

  /// Called when the current trip ends (completed/cancelled or API shows no trip).
  VoidCallback? onActiveTripEnded;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> checkActiveTrip({bool startPolling = true}) async {
    final hadActive = _activeTrip != null;
    try {
      final response = await _apiServices.getCurrentTrip();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          _activeTrip = Map<String, dynamic>.from(data);
          final tripId = _activeTrip?['id'];
          if (tripId != null) {
            _socket.joinTrip(tripId);
            if (_realtimeEnabled) {
              await _startLocationSharing(tripId);
            }
          }
          notifyListeners();
          if (startPolling && !_realtimeEnabled) _startTripPolling();
          return;
        }
      }
      _activeTrip = null;
      notifyListeners();
      _stopTripPolling();
      _stopLocationSharing();
      if (hadActive) onActiveTripEnded?.call();
    } catch (e) {
      debugPrint('Error checking active trip: $e');
    }
  }

  void startRealtime({required int userId, required String token}) {
    _currentUserId = userId;
    _realtimeEnabled = true;
    _stopTripPolling();
    _socket.connect(url: '${AppUrl.baseUrl}/sos', token: token);
    final existingTripId = _activeTrip?['id'];
    if (existingTripId != null) {
      _socket.joinTrip(existingTripId);
      _startLocationSharing(existingTripId);
    }

    _tripSub ??= _socket.tripUpdatedStream.listen((payload) {
      final driverId = payload['driverId'];
      if (driverId == null || driverId != _currentUserId) return;

      final status = payload['status']?.toString();
      if (status == 'COMPLETED' || status == 'CANCELLED') {
        final hadActive = _activeTrip != null;
        _activeTrip = null;
        _stopLocationSharing();
        notifyListeners();
        if (hadActive) onActiveTripEnded?.call();
        return;
      }

      _activeTrip = Map<String, dynamic>.from(payload);
      final tripId = _activeTrip?['id'];
      if (tripId != null) {
        _socket.joinTrip(tripId);
        _startLocationSharing(tripId);
      }
      notifyListeners();
    });

    _sosDriverSub ??= _socket.sosUpdatedStream.listen((payload) {
      final aid = payload['assignedDriverId'];
      final st = payload['status']?.toString();
      if (st == 'ASSIGNED' &&
          aid != null &&
          _currentUserId != null &&
          aid.toString() == _currentUserId.toString()) {
        checkActiveTrip(startPolling: false);
      }
    });

    _locSub ??= _socket.tripLocationUpdatedStream.listen((payload) {
      final tripId = payload['tripId'] ?? payload['trip_id'];
      final currentTripId = _activeTrip?['id'];
      if (tripId == null || currentTripId == null) return;
      if (tripId.toString() != currentTripId.toString()) return;

      _activeTrip = {
        ...(_activeTrip ?? {}),
        if (payload['distanceKm'] != null) 'distanceKm': payload['distanceKm'],
        if (payload['etaMinutes'] != null) 'timeMinutes': payload['etaMinutes'],
        'latestLocation': {
          'lat': payload['lat'],
          'lng': payload['lng'],
          'speed': payload['speed'],
          'heading': payload['heading'],
          'createdAt': payload['createdAt'],
        },
      };
      notifyListeners();
    });
  }

  Future<void> _startLocationSharing(Object tripId) async {
    final key = tripId.toString();
    if (key.isEmpty) return;
    if (_sharingTripIdKey != null && _sharingTripIdKey != key) {
      _stopLocationSharing();
    }
    if (_posSub != null && _sharingTripIdKey == key) return;
    _sharingTripIdKey = key;

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
      final speedKmh = current.speed.isFinite ? (current.speed * 3.6) : null;
      _socket.updateTripLocation(
        tripId: tripId,
        lat: current.latitude,
        lng: current.longitude,
        speed: speedKmh,
        heading: current.heading.isFinite ? current.heading : null,
      );
    } catch (_) {}

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
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

  void _stopLocationSharing() {
    _posSub?.cancel();
    _posSub = null;
    _sharingTripIdKey = null;
  }

  String get activeTripEtaText {
    final data = _activeTrip;
    if (data == null) return '';
    final timeMinutes = data['timeMinutes'] ?? data['etaMinutes'];
    final distanceKm = data['distanceKm'];
    if (timeMinutes != null) {
      final mins = int.tryParse(timeMinutes.toString());
      if (mins != null && mins > 0) return '$mins min';
    }
    if (distanceKm != null) {
      final km = double.tryParse(distanceKm.toString());
      if (km != null && km > 0) return '${km.toStringAsFixed(1)} km';
    }
    return 'Trip active';
  }

  String get activeTripTitle {
    switch (activeTripStatus) {
      case 'ACCEPTED':
        return 'Ambulance Dispatched';
      case 'ARRIVED':
        return 'Arrived at Pickup';
      case 'IN_PROGRESS':
        return 'Trip In Progress';
      default:
        return 'Trip Active';
    }
  }

  void _startTripPolling() {
    _tripPollingTimer?.cancel();
    _tripPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await checkActiveTrip(startPolling: false);
    });
  }

  void _stopTripPolling() {
    _tripPollingTimer?.cancel();
    _tripPollingTimer = null;
  }

  @override
  void dispose() {
    _stopTripPolling();
    _stopLocationSharing();
    _tripSub?.cancel();
    _locSub?.cancel();
    _sosDriverSub?.cancel();
    super.dispose();
  }
}
