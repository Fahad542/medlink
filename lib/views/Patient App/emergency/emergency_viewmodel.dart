import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/ambulance_model.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/services/sos_socket_service.dart';
import 'package:medlink/utils/gps_coord.dart';
import 'package:medlink/utils/trip_driver_location.dart';

/// Real-time SOS feedback for the patient UI (SnackBars / toasts).
class EmergencyToast {
  final String message;
  final Color backgroundColor;

  EmergencyToast(this.message, this.backgroundColor);
}

class EmergencyViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final SosSocketService _socket = SosSocketService.instance;
  bool _isSosActive = false;
  AmbulanceModel? _assignedAmbulance;
  String? _sosStatus;
  String? _sosId;
  String? get sosId => _sosId;
  Map<String, dynamic>? _activeTrip;
  String? _lastCompletedTripId;
  Timer? _pollingTimer;
  bool _realtimeEnabled = false;
  StreamSubscription<Map<String, dynamic>>? _sosSub;
  StreamSubscription<Map<String, dynamic>>? _tripSub;
  StreamSubscription<Map<String, dynamic>>? _locSub;

  /// Logged-in patient user id (string — numeric or UUID from API).
  String? _currentPatientId;

  /// Trip id (string) for `trip:locationUpdated` / `joinTrip` — supports int ids and UUIDs.
  String? _trackedTripIdKey;

  final StreamController<EmergencyToast> _toastController =
      StreamController<EmergencyToast>.broadcast();
  Stream<EmergencyToast> get toastStream => _toastController.stream;

  /// Last known status per SOS id (for transition toasts).
  final Map<String, String> _lastSosStatusById = {};

  /// Last known trip status per trip id (driver milestones → patient toasts).
  final Map<String, String> _lastTripStatusById = {};

  bool get isSosActive => _isSosActive;
  AmbulanceModel? get assignedAmbulance => _assignedAmbulance;
  String? get sosStatus => _sosStatus;
  Map<String, dynamic>? get activeTrip => _activeTrip;
  String? get tripStatus => _activeTrip?['status']?.toString();
  String? get lastCompletedTripId => _lastCompletedTripId;

  void _syncTrackedTripIdFromActiveTrip() {
    final id = _activeTrip?['id'];
    if (id == null) return;
    final s = id.toString();
    if (s.isEmpty) return;
    _trackedTripIdKey = s;
  }

  /// Seed patient map from REST/socket `trip` (flat driverLat, nested driver, latestLocation, …).
  void _mergeDriverLocationFromTripMap(Map<String, dynamic>? trip) {
    if (trip == null) return;
    final merged = TripDriverLocation.latestFromTrip(trip);
    if (merged == null) return;
    final lat = GpsCoord.tryParse(merged['lat']);
    final lng = GpsCoord.tryParse(merged['lng']);
    if (!GpsCoord.isValidPair(lat, lng)) return;
    _activeTrip = {...trip, 'latestLocation': merged};
    final amb = _assignedAmbulance;
    if (amb != null) {
      _assignedAmbulance = amb.withDriverLocation(lat!, lng!);
    }
  }

  /// Call when opening the live map so the patient (re)joins SOS + trip rooms for driver GPS.
  void ensurePatientTripTracking() {
    if (!_realtimeEnabled) return;
    final sid = _sosId;
    if (sid != null && sid.isNotEmpty) _socket.joinSos(sid);
    _syncTrackedTripIdFromActiveTrip();
    final tid = _trackedTripIdKey ?? _activeTrip?['id'];
    if (tid != null) _socket.joinTrip(tid);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _sosSub?.cancel();
    _tripSub?.cancel();
    _locSub?.cancel();
    _toastController.close();
    super.dispose();
  }

  bool _payloadIsForCurrentPatient(Map<String, dynamic> payload) {
    if (_currentPatientId == null || _currentPatientId!.isEmpty) {
      return false;
    }
    final direct = payload['patientId'];
    if (direct != null) {
      return GpsCoord.sameId(direct, _currentPatientId);
    }
    final pat = payload['patient'];
    if (pat is Map && pat['id'] != null) {
      return GpsCoord.sameId(pat['id'], _currentPatientId);
    }
    // Many backends only put the patient in their user room and omit patientId on trip payloads.
    return true;
  }

  void _maybeEmitSosToast(Map<String, dynamic> payload) {
    if (_toastController.isClosed) return;
    final sid = payload['id']?.toString() ?? '';
    if (sid.isEmpty) return;
    final status = payload['status']?.toString() ?? '';
    final prev = _lastSosStatusById[sid];
    final assignedId = payload['assignedDriverId'];

    if (status == 'ASSIGNED' &&
        assignedId != null &&
        prev != 'ASSIGNED') {
      final d = payload['assignedDriver'];
      final name = d is Map
          ? (d['fullName']?.toString().trim().isNotEmpty == true
              ? d['fullName'].toString()
              : 'A driver')
          : 'A driver';
      _toastController.add(EmergencyToast(
        '$name accepted your request. Ambulance is on the way.',
        const Color(0xFF2E7D32),
      ));
    } else if (status == 'OPEN' && prev == 'ASSIGNED') {
      _toastController.add(EmergencyToast(
        'Driver released your request. Still searching for an ambulance…',
        const Color(0xFFE65100),
      ));
    } else if (status == 'CANCELLED') {
      _toastController.add(EmergencyToast(
        'Your emergency request was cancelled.',
        Colors.red.shade800,
      ));
    }

    _lastSosStatusById[sid] = status;
  }

  /// Avoid re-firing trip milestone toasts after REST restore or duplicate socket payloads.
  void _seedTripStatusFromMap(Map<String, dynamic>? trip) {
    if (trip == null) return;
    final tid = trip['id']?.toString();
    final st = trip['status']?.toString();
    if (tid != null && tid.isNotEmpty && st != null && st.isNotEmpty) {
      _lastTripStatusById[tid] = st;
    }
  }

  void _maybeEmitTripStatusToast(Map<String, dynamic> payload) {
    if (_toastController.isClosed) return;
    final tid = payload['id']?.toString() ?? '';
    if (tid.isEmpty) return;
    final status = payload['status']?.toString() ?? '';
    final prev = _lastTripStatusById[tid];
    if (status.isEmpty || status == prev) return;

    final driver = payload['driver'];
    final driverName = driver is Map &&
            driver['fullName']?.toString().trim().isNotEmpty == true
        ? driver['fullName'].toString()
        : 'Ambulance';

    switch (status) {
      case 'REQUESTED':
        _toastController.add(EmergencyToast(
          'Trip requested. Waiting for confirmation…',
          const Color(0xFF1565C0),
        ));
        break;
      case 'ACCEPTED':
        final linkedSos = payload['sosId']?.toString();
        if (linkedSos != null &&
            linkedSos.isNotEmpty &&
            _lastSosStatusById[linkedSos] == 'ASSIGNED') {
          _lastTripStatusById[tid] = status;
          return;
        }
        _toastController.add(EmergencyToast(
          '$driverName is on the way to your location.',
          const Color(0xFF1565C0),
        ));
        break;
      case 'ARRIVED':
        _toastController.add(EmergencyToast(
          '$driverName has arrived at the pickup point.',
          const Color(0xFF2E7D32),
        ));
        break;
      case 'IN_PROGRESS':
        _toastController.add(EmergencyToast(
          'Heading to the hospital.',
          const Color(0xFF1565C0),
        ));
        break;
      case 'COMPLETED':
        _toastController.add(EmergencyToast(
          'Trip completed. Thank you for using Medlink.',
          const Color(0xFF2E7D32),
        ));
        break;
      case 'CANCELLED':
        _toastController.add(EmergencyToast(
          'Ambulance trip was cancelled.',
          Colors.red.shade800,
        ));
        break;
      default:
        break;
    }

    _lastTripStatusById[tid] = status;
  }

  void startRealtime({required String patientUserId, required String token}) {
    final pid = patientUserId.trim();
    if (pid.isEmpty) return;
    _currentPatientId = pid;
    _realtimeEnabled = true;
    _pollingTimer?.cancel();
    _seedTripStatusFromMap(_activeTrip);
    _syncTrackedTripIdFromActiveTrip();
    _socket.connect(url: '${AppUrl.baseUrl}/sos', token: token);

    _sosSub ??= _socket.sosUpdatedStream.listen((payload) {
      final m = Map<String, dynamic>.from(payload);
      if (!_payloadIsForCurrentPatient(m)) return;

      _maybeEmitSosToast(m);

      _sosStatus = m['status']?.toString();
      _sosId = m['id']?.toString();
      final assigned = m['assignedDriver'];
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
      final m = Map<String, dynamic>.from(payload);
      if (!_payloadIsForCurrentPatient(m)) return;

      _maybeEmitTripStatusToast(m);

      _activeTrip = m;
      _syncTrackedTripIdFromActiveTrip();
      _mergeDriverLocationFromTripMap(_activeTrip);
      final tripId = _activeTrip?['id'];
      final status = _activeTrip?['status']?.toString();

      if (status == 'COMPLETED' || status == 'CANCELLED') {
        if (status == 'COMPLETED') {
          _lastCompletedTripId = _activeTrip?['id']?.toString();
        }
        cancelSos();
        return;
      }

      if (tripId != null) {
        _socket.joinTrip(tripId);
      }
      notifyListeners();
    });

    _locSub ??= _socket.tripLocationUpdatedStream.listen((payload) {
      final incomingRaw =
          payload['tripId'] ?? payload['trip_id'] ?? payload['tripID'];
      final incomingStr = incomingRaw?.toString();
      if (incomingStr == null || incomingStr.isEmpty) return;

      _syncTrackedTripIdFromActiveTrip();
      final knownStr = _trackedTripIdKey ?? _activeTrip?['id']?.toString();
      if (knownStr != null &&
          knownStr.isNotEmpty &&
          !GpsCoord.sameId(knownStr, incomingStr)) {
        return;
      }
      if ((knownStr == null || knownStr.isEmpty) && !_isSosActive) return;

      _trackedTripIdKey = incomingStr;

      final lat = GpsCoord.tryParse(payload['lat'] ?? payload['latitude']);
      final lng = GpsCoord.tryParse(payload['lng'] ?? payload['longitude']);
      final heading = GpsCoord.tryParse(payload['heading']);
      final speed = GpsCoord.tryParse(payload['speed']);

      Map<String, dynamic>? nextLatest;
      if (GpsCoord.isValidPair(lat, lng)) {
        nextLatest = {
          'lat': lat,
          'lng': lng,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
          if (payload['createdAt'] != null) 'createdAt': payload['createdAt'],
        };
        final amb = _assignedAmbulance;
        if (amb != null) {
          _assignedAmbulance = amb.withDriverLocation(lat!, lng!);
        }
      }

      _activeTrip = {
        ...(_activeTrip ?? {}),
        if (payload['distanceKm'] != null) 'distanceKm': payload['distanceKm'],
        if (payload['etaMinutes'] != null) 'timeMinutes': payload['etaMinutes'],
        if (nextLatest != null) 'latestLocation': nextLatest,
      };
      notifyListeners();
    });

    if (_sosId != null && _sosId!.isNotEmpty) {
      _socket.joinSos(_sosId!);
    }
    final tripRaw = _activeTrip?['id'];
    if (tripRaw != null) {
      _socket.joinTrip(tripRaw);
    }
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
            _seedTripStatusFromMap(_activeTrip);
            _syncTrackedTripIdFromActiveTrip();
            final tripId = _activeTrip?['id'];
            if (tripId != null) {
              _socket.joinTrip(tripId);
            }
            if (_realtimeEnabled &&
                _sosId != null &&
                _sosId!.isNotEmpty) {
              _socket.joinSos(_sosId!);
            }
            if (sos['status'] == 'ASSIGNED' && sos['assignedDriver'] != null) {
              _assignedAmbulance =
                  AmbulanceModel.fromJson(sos['assignedDriver']);
            }
            _mergeDriverLocationFromTripMap(_activeTrip);
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

  /// Explicit pickup + destination from the map flow (no GPS override for pickup).
  Future<void> triggerSosWithPickupAndDestination(
    BuildContext context, {
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    String? addressSummary,
  }) async {
    await _triggerSosInternal(
      context,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destLat: destinationLat,
      destLng: destinationLng,
      addressText: addressSummary,
    );
  }

  Future<List<double>?> _getCurrentPickupLatLng() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return [pos.latitude, pos.longitude];
    } catch (e) {
      debugPrint('EmergencyViewModel: pickup location error: $e');
      return null;
    }
  }

  Future<void> _triggerSosInternal(
    BuildContext context, {
    double? pickupLat,
    double? pickupLng,
    double? destLat,
    double? destLng,
    String? addressText,
  }) async {
    _isSosActive = true;
    notifyListeners();

    try {
      double latitude;
      double longitude;

      if (pickupLat != null && pickupLng != null) {
        latitude = pickupLat;
        longitude = pickupLng;
      } else {
        final pickup = await _getCurrentPickupLatLng();
        if (pickup == null) {
          _isSosActive = false;
          notifyListeners();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Turn on location and allow access so we can send your position with SOS.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        latitude = pickup[0];
        longitude = pickup[1];
      }

      final response = await _apiServices.createSos(
        latitude,
        longitude,
        destinationLat: destLat,
        destinationLng: destLng,
        addressText: addressText,
      );

      if (response != null) {
        if (response['data'] != null) {
          _sosId = response['data']['id']?.toString();
        }
        if (!_realtimeEnabled) {
          _startPollingForDriver();
        } else {
          await checkActiveSos();
          if (_sosId != null && _sosId!.isNotEmpty) {
            _socket.joinSos(_sosId!);
          }
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
            _syncTrackedTripIdFromActiveTrip();
            if (sos['status'] == 'ASSIGNED' && sos['assignedDriver'] != null) {
              _assignedAmbulance =
                  AmbulanceModel.fromJson(sos['assignedDriver']);
            }
            _mergeDriverLocationFromTripMap(_activeTrip);
            if (sos['status'] == 'RESOLVED' ||
                sos['status'] == 'CANCELLED') {
              final trip = _activeTrip;
              final tripStatus = trip?['status']?.toString();
              if (tripStatus == 'COMPLETED') {
                _lastCompletedTripId = trip?['id']?.toString();
              }
              cancelSos();
            } else {
              notifyListeners();
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
    _trackedTripIdKey = null;
    _lastSosStatusById.clear();
    _lastTripStatusById.clear();
    _socket.clearJoinedRooms();
    _pollingTimer?.cancel();
    notifyListeners();
  }

  void clearCompletedTripReviewPrompt() {
    _lastCompletedTripId = null;
    notifyListeners();
  }
}
