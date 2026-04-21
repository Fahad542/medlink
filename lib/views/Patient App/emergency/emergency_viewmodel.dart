import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/ambulance_model.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/services/sos_socket_service.dart';
import 'package:medlink/utils/gps_coord.dart';
import 'package:medlink/utils/trip_driver_location.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/core/constants/sos_constants.dart';

/// Real-time SOS feedback for the patient UI (custom toasts via [Utils.toastMessage]).
class EmergencyToast {
  final String message;
  final Color backgroundColor;
  final bool isError;

  EmergencyToast(this.message, this.backgroundColor, {this.isError = false});
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
  Timer? _searchUiTicker;

  /// Logged-in patient user id (string — numeric or UUID from API).
  String? _currentPatientId;

  /// Server-driven driver search window (minutes). Default until API responds.
  int _searchWindowMinutes = 2;
  DateTime? _searchWindowStartedAt;
  DateTime? _searchWindowEndsAt;
  String? _noDriverFoundMessage;
  bool _canRetrySearch = false;

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

  int get searchWindowMinutes => _searchWindowMinutes;
  DateTime? get searchWindowStartedAt => _searchWindowStartedAt;
  DateTime? get searchWindowEndsAt => _searchWindowEndsAt;
  String? get noDriverFoundMessage => _noDriverFoundMessage;
  bool get canRetrySearch => _canRetrySearch;

  /// Progress 0→1 while OPEN and unassigned; null when not applicable.
  double? get searchWindowProgressFraction {
    if (_sosStatus != 'OPEN' || _assignedAmbulance != null) return null;
    final ends = _searchWindowEndsAt;
    final started = _searchWindowStartedAt;
    if (ends == null || started == null) return null;
    final now = DateTime.now();
    if (!now.isBefore(ends)) return 1.0;
    final total = ends.difference(started).inMilliseconds;
    if (total <= 0) return 1.0;
    final elapsed = now.difference(started).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Remaining time in the driver search window (OPEN, unassigned only).
  Duration? get searchWindowRemaining {
    if (_sosStatus != 'OPEN' || _assignedAmbulance != null) return null;
    final ends = _searchWindowEndsAt;
    if (ends == null) return null;
    final d = ends.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  DateTime? _tryParseIso(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  void _recomputeSearchWindowEndsIfNeeded() {
    final started = _searchWindowStartedAt;
    if (started == null) return;
    if (_searchWindowEndsAt == null ||
        _sosStatus == 'OPEN' ||
        _sosStatus == 'EXPIRED') {
      _searchWindowEndsAt =
          started.add(Duration(minutes: _searchWindowMinutes));
    }
  }

  /// Merges timing / retry fields from REST or `sos:updated` payloads.
  void _mergeSosTimingFromMap(Map<String, dynamic> m) {
    final rawMin = m['searchWindowMinutes'];
    if (rawMin != null) {
      final v = int.tryParse(rawMin.toString()) ?? _searchWindowMinutes;
      _searchWindowMinutes = v.clamp(1, 1440);
    }
    final startedRaw = m['searchWindowStartedAt'];
    if (startedRaw != null) {
      _searchWindowStartedAt = _tryParseIso(startedRaw);
    }
    final endsRaw = m['searchWindowEndsAt'];
    if (endsRaw != null) {
      _searchWindowEndsAt = _tryParseIso(endsRaw);
    } else {
      _recomputeSearchWindowEndsIfNeeded();
    }

    final st = m['status']?.toString() ?? _sosStatus;
    final nd = m['noDriverFoundMessage'];
    if (nd != null && nd.toString().trim().isNotEmpty) {
      _noDriverFoundMessage = nd.toString();
    } else if (st == 'EXPIRED') {
      _noDriverFoundMessage = SosConstants.noAmbulanceDriverMessage;
    } else {
      _noDriverFoundMessage = null;
    }

    final cr = m['canRetrySearch'];
    if (cr is bool) {
      _canRetrySearch = cr;
    } else if (cr != null) {
      _canRetrySearch = cr.toString() == 'true';
    } else {
      _canRetrySearch = st == 'EXPIRED';
    }
  }

  void _applyAssignedDriverFromSosMap(Map<String, dynamic> sos) {
    final st = sos['status']?.toString();
    final assignedId = sos['assignedDriverId'];
    if (st == 'ASSIGNED' && sos['assignedDriver'] is Map) {
      _assignedAmbulance = AmbulanceModel.fromJson(
        Map<String, dynamic>.from(sos['assignedDriver']),
      );
    } else if (st == 'OPEN' &&
        (assignedId == null || assignedId.toString().isEmpty)) {
      _assignedAmbulance = null;
    } else if (st == 'EXPIRED') {
      _assignedAmbulance = null;
    }
  }

  void _ingestSosRecord(Map<String, dynamic> sos) {
    _sosId = sos['id']?.toString() ?? _sosId;
    _sosStatus = sos['status']?.toString();
    _mergeSosTimingFromMap(sos);
    _activeTrip = sos['trip'] is Map
        ? Map<String, dynamic>.from(sos['trip'])
        : _activeTrip;
    _applyAssignedDriverFromSosMap(sos);
    _mergeDriverLocationFromTripMap(_activeTrip);
  }

  void _startSearchUiTicker() {
    _searchUiTicker?.cancel();
    _searchUiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isSosActive) return;
      if (_sosStatus != 'OPEN' || _assignedAmbulance != null) return;
      if (_searchWindowEndsAt == null) return;
      notifyListeners();
    });
  }

  void _stopSearchUiTicker() {
    _searchUiTicker?.cancel();
    _searchUiTicker = null;
  }

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
    _searchUiTicker?.cancel();
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
        isError: false,
      ));
    } else if (status == 'OPEN' && prev == 'ASSIGNED') {
      _toastController.add(EmergencyToast(
        'Driver released your request. Still searching for an ambulance…',
        const Color(0xFFE65100),
        isError: false,
      ));
    } else if (status == 'CANCELLED') {
      _toastController.add(EmergencyToast(
        'Your emergency request was cancelled.',
        Colors.red.shade800,
        isError: true,
      ));
    } else if (status == 'EXPIRED' &&
        prev != 'EXPIRED' &&
        prev != null &&
        prev.isNotEmpty) {
      final msg = (payload['noDriverFoundMessage']?.toString().trim().isNotEmpty ==
              true)
          ? payload['noDriverFoundMessage'].toString()
          : SosConstants.noAmbulanceDriverMessage;
      _toastController.add(EmergencyToast(
        msg,
        Colors.red.shade800,
        isError: true,
      ));
    } else if (status == 'OPEN' && prev == 'EXPIRED') {
      _toastController.add(EmergencyToast(
        SosConstants.retrySearchingMessage,
        const Color(0xFF1565C0),
        isError: false,
      ));
    }

    _lastSosStatusById[sid] = status;
  }

  void _seedSosStatusTrackingForCurrent() {
    final sid = _sosId;
    final st = _sosStatus;
    if (sid != null && sid.isNotEmpty && st != null && st.isNotEmpty) {
      _lastSosStatusById[sid] = st;
    }
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
          isError: false,
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
          isError: false,
        ));
        break;
      case 'ARRIVED':
        _toastController.add(EmergencyToast(
          '$driverName has arrived at the pickup point.',
          const Color(0xFF2E7D32),
          isError: false,
        ));
        break;
      case 'IN_PROGRESS':
        _toastController.add(EmergencyToast(
          'Heading to the hospital.',
          const Color(0xFF1565C0),
          isError: false,
        ));
        break;
      case 'COMPLETED':
        _toastController.add(EmergencyToast(
          'Trip completed. Thank you for using Medlink.',
          const Color(0xFF2E7D32),
          isError: false,
        ));
        break;
      case 'CANCELLED':
        _toastController.add(EmergencyToast(
          'Ambulance trip was cancelled.',
          Colors.red.shade800,
          isError: true,
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

      _sosId = m['id']?.toString() ?? _sosId;
      _sosStatus = m['status']?.toString();
      _mergeSosTimingFromMap(m);

      final assigned = m['assignedDriver'];
      if (_sosStatus == 'ASSIGNED' && assigned is Map) {
        _assignedAmbulance = AmbulanceModel.fromJson(
          Map<String, dynamic>.from(assigned),
        );
      } else if (_sosStatus == 'OPEN') {
        final aid = m['assignedDriverId'];
        if (aid == null || aid.toString().isEmpty) {
          _assignedAmbulance = null;
        }
      } else if (_sosStatus == 'EXPIRED') {
        _assignedAmbulance = null;
      }

      if (_sosStatus == 'RESOLVED' || _sosStatus == 'CANCELLED') {
        cancelSos();
        return;
      }

      _isSosActive = true;
      if (_sosStatus == 'OPEN' && _assignedAmbulance == null) {
        _startSearchUiTicker();
      } else {
        _stopSearchUiTicker();
      }
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
          final sos = Map<String, dynamic>.from(list.first as Map);
          final st = sos['status']?.toString();
          if (st == 'OPEN' || st == 'ASSIGNED' || st == 'EXPIRED') {
            _isSosActive = true;
            _ingestSosRecord(sos);
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
            if (st == 'OPEN' && _assignedAmbulance == null) {
              _startSearchUiTicker();
            } else {
              _stopSearchUiTicker();
            }
            _seedSosStatusTrackingForCurrent();
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
            Utils.toastMessage(
              context,
              'Turn on location and allow access so we can send your position with SOS.',
              isError: true,
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
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          _ingestSosRecord(Map<String, dynamic>.from(data));
        } else if (data is Map) {
          _ingestSosRecord(Map<String, dynamic>.from(data));
        } else if (response is Map &&
            response['id'] != null &&
            response['status'] != null) {
          _ingestSosRecord(Map<String, dynamic>.from(response));
        } else if (data != null && data is Map && data['id'] != null) {
          _sosId = data['id']?.toString();
        }
        if (_sosStatus == 'OPEN' && _assignedAmbulance == null) {
          _startSearchUiTicker();
        }
        _seedSosStatusTrackingForCurrent();
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
          final friendly = response['message']?.toString();
          Utils.toastMessage(
            context,
            (friendly != null && friendly.isNotEmpty)
                ? friendly
                : 'SOS Alert Sent Successfully! Finding Driver...',
          );
        }
      } else {
        _isSosActive = false;
        notifyListeners();
        debugPrint("Failed to create SOS");
        if (context.mounted) {
          Utils.toastMessage(context, 'Failed to send SOS', isError: true);
        }
      }
    } catch (e) {
      _isSosActive = false;
      notifyListeners();
      debugPrint("Error creating SOS: $e");
      if (context.mounted) {
        Utils.toastError(context, e);
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
            final sos = Map<String, dynamic>.from(list.first as Map);
            final st = sos['status']?.toString();
            _ingestSosRecord(sos);
            _syncTrackedTripIdFromActiveTrip();
            if (st == 'OPEN' && _assignedAmbulance == null) {
              _startSearchUiTicker();
            } else {
              _stopSearchUiTicker();
            }
            _mergeDriverLocationFromTripMap(_activeTrip);
            if (st == 'RESOLVED' || st == 'CANCELLED') {
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
    if (_sosStatus == 'EXPIRED') return 'No driver found';
    final trip = tripStatus;
    if (trip == 'ARRIVED') return 'Ambulance Arrived';
    if (trip == 'IN_PROGRESS') return 'Trip In Progress';
    if (_sosStatus == 'OPEN') return 'Finding Driver';
    return 'Ambulance Dispatched';
  }

  String get sosEtaText {
    if (_sosStatus == 'EXPIRED') {
      return _noDriverFoundMessage ?? SosConstants.noAmbulanceDriverMessage;
    }
    final rem = searchWindowRemaining;
    if (_sosStatus == 'OPEN' &&
        _assignedAmbulance == null &&
        rem != null &&
        rem > Duration.zero) {
      final s = rem.inSeconds;
      final m = s ~/ 60;
      final sec = s % 60;
      if (m > 0) return '${m}m ${sec}s';
      return '${sec}s';
    }
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
    _searchWindowStartedAt = null;
    _searchWindowEndsAt = null;
    _noDriverFoundMessage = null;
    _canRetrySearch = false;
    _searchWindowMinutes = 2;
    _stopSearchUiTicker();
    _socket.clearJoinedRooms();
    _pollingTimer?.cancel();
    notifyListeners();
  }

  /// Re-open driver search for an EXPIRED SOS (`POST /patient/sos/:id/retry`).
  Future<void> retrySosSearch(BuildContext context) async {
    if (!_canRetrySearch && _sosStatus != 'EXPIRED') return;
    final id = _sosId;
    if (id == null || id.isEmpty) return;
    try {
      final response = await _apiServices.retryPatientSos(id);
      if (response == null) {
        if (context.mounted) {
          Utils.toastMessage(context, 'Could not retry search', isError: true);
        }
        return;
      }
      final data = response['data'];
      if (data is Map) {
        _ingestSosRecord(Map<String, dynamic>.from(data));
      }
      _isSosActive = true;
      if (_sosStatus == 'OPEN' && _assignedAmbulance == null) {
        _startSearchUiTicker();
      }
      if (!_realtimeEnabled) {
        _startPollingForDriver();
      } else if (_sosId != null && _sosId!.isNotEmpty) {
        _socket.joinSos(_sosId!);
      }
      _seedSosStatusTrackingForCurrent();
      notifyListeners();
      if (context.mounted) {
        final msg = response['message']?.toString();
        Utils.toastMessage(
          context,
          (msg != null && msg.isNotEmpty)
              ? msg
              : SosConstants.retrySearchingMessage,
        );
      }
    } catch (e) {
      debugPrint('retrySosSearch error: $e');
      if (context.mounted) Utils.toastError(context, e);
    }
  }

  void clearCompletedTripReviewPrompt() {
    _lastCompletedTripId = null;
    notifyListeners();
  }
}
