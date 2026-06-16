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
import 'package:medlink/utils/jwt_user_id.dart';
import 'package:medlink/core/constants/sos_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? _normEnum(dynamic v) {
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return s.toUpperCase();
}

/// Real-time SOS feedback for the patient UI (custom toasts via [Utils.toastMessage]).
class EmergencyToast {
  final String message;
  final Color backgroundColor;
  final bool isError;

  EmergencyToast(this.message, this.backgroundColor, {this.isError = false});
}

/// Global payment prompt when driver completes drop-off (`trip:paymentRequired` / `trip:updated`).
class TripPaymentPromptEvent {
  final String tripId;
  final double fareAmount;
  final String currency;
  final String? driverName;

  TripPaymentPromptEvent({
    required this.tripId,
    required this.fareAmount,
    required this.currency,
    this.driverName,
  });
}

class EmergencyViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final SosSocketService _socket = SosSocketService.instance;
  bool _isSosActive = false;
  AmbulanceModel? _assignedAmbulance;
  String? _sosStatus;
  String? _sosId;
  String? _emergencyType;
  String? _severity;
  String? get sosId => _sosId;
  Map<String, dynamic>? _activeTrip;
  String? _lastCompletedTripId;
  Timer? _pollingTimer;
  /// While realtime is on we normally skip polling; this backs up REST if sockets drop events.
  Timer? _sosBackupSyncTimer;
  bool _realtimeEnabled = false;
  StreamSubscription<Map<String, dynamic>>? _sosSub;
  StreamSubscription<Map<String, dynamic>>? _tripSub;
  StreamSubscription<Map<String, dynamic>>? _locSub;
  StreamSubscription<Map<String, dynamic>>? _tripPaySub;
  Timer? _searchUiTicker;

  /// JWT `sub` (User id) — matches `sos.patientId` / `trip.patientId` on the server.
  String? _jwtPatientIdStr;
  /// Session `UserModel.id` (may differ from JWT if API nests profile ids).
  String? _sessionPatientIdStr;

  /// Server-driven driver search window (minutes). Default until API responds.
  int _searchWindowMinutes = 2;
  DateTime? _searchWindowStartedAt;
  DateTime? _searchWindowEndsAt;
  String? _noDriverFoundMessage;
  bool _canRetrySearch = false;
  int _driversViewingCount = 0;
  List<Map<String, dynamic>> _driversViewingProfiles = [];
  String? _dismissedRetrySosId;

  /// Trip id (string) for `trip:locationUpdated` / `joinTrip` — supports int ids and UUIDs.
  String? _trackedTripIdKey;

  final StreamController<EmergencyToast> _toastController =
      StreamController<EmergencyToast>.broadcast();
  Stream<EmergencyToast> get toastStream => _toastController.stream;

  final StreamController<TripPaymentPromptEvent> _tripPaymentPromptController =
      StreamController<TripPaymentPromptEvent>.broadcast();
  Stream<TripPaymentPromptEvent> get tripPaymentPromptStream =>
      _tripPaymentPromptController.stream;

  static const String _kPendingTripPaymentIdsKey = 'pending_trip_payment_ids_v1';

  final Set<String> _tripPaymentPromptedIds = {};
  final Set<String> _pendingTripPaymentIds = {};
  final Map<String, TripPaymentPromptEvent> _pendingTripPaymentMeta = {};
  bool _pendingTripPaymentsLoaded = false;

  /// Last known status per SOS id (for transition toasts).
  final Map<String, String> _lastSosStatusById = {};

  /// Last known trip status per trip id (driver milestones → patient toasts).
  final Map<String, String> _lastTripStatusById = {};

  bool get isSosActive => _isSosActive;
  AmbulanceModel? get assignedAmbulance => _assignedAmbulance;
  String? get sosStatus => _sosStatus;
  String? get emergencyType => _emergencyType;
  String? get severity => _severity;
  Map<String, dynamic>? get activeTrip => _activeTrip;
  String? get tripStatus => _normEnum(_activeTrip?['status']);

  /// Show "EMERGENCY" badge only for true emergency SOS/trips (not "normal"/routine).
  bool get isEmergencySos {
    final sev = _severity?.trim().toUpperCase();
    if (sev == 'HIGH' || sev == 'CRITICAL') return true;
    final t = (_emergencyType ?? '').trim().toLowerCase();
    if (t.isEmpty) return false;
    if (t == 'normal' || t == 'routine') return false;
    return true;
  }

  bool get hasPendingTripPayment => _pendingTripPaymentIds.isNotEmpty;
  int get pendingTripPaymentCount => _pendingTripPaymentIds.length;
  String get pendingTripPaymentWarningText =>
      pendingTripPaymentCount <= 1
          ? 'Payment is pending for your completed trip'
          : 'Payment is pending for $pendingTripPaymentCount completed trips';

  TripPaymentPromptEvent? get nextPendingTripPaymentPrompt {
    if (_pendingTripPaymentIds.isEmpty) return null;
    for (final id in _pendingTripPaymentIds) {
      final known = _pendingTripPaymentMeta[id];
      if (known != null) return known;
    }
    final fallback = _pendingTripPaymentIds.first;
    return TripPaymentPromptEvent(
      tripId: fallback,
      fareAmount: 0,
      currency: 'CFA',
    );
  }

  /// Prefer [assignedAmbulance]; if missing, build from `trip.driver` (socket / richer payloads).
  AmbulanceModel? get trackingAmbulance {
    if (_assignedAmbulance != null) return _assignedAmbulance;
    final t = _activeTrip;
    if (t == null) return null;
    final ts = _normEnum(t['status']);
    if (ts != 'ACCEPTED' && ts != 'ARRIVED' && ts != 'IN_PROGRESS') {
      return null;
    }
    final d = t['driver'];
    if (d is! Map) return null;
    return AmbulanceModel.fromJson({
      'driver': Map<String, dynamic>.from(d),
      if (t['latestLocation'] is Map) 'latestLocation': t['latestLocation'],
    });
  }
  String? get lastCompletedTripId => _lastCompletedTripId;

  int get searchWindowMinutes => _searchWindowMinutes;
  DateTime? get searchWindowStartedAt => _searchWindowStartedAt;
  DateTime? get searchWindowEndsAt => _searchWindowEndsAt;
  String? get noDriverFoundMessage => _noDriverFoundMessage;
  bool get canRetrySearch => _canRetrySearch;
  int get driversViewingCount => _driversViewingCount;
  List<Map<String, dynamic>> get driversViewingProfiles => _driversViewingProfiles;
  bool get isRetrySosDismissed {
    final currentSosId = _sosId?.trim();
    if (currentSosId == null || currentSosId.isEmpty) return false;
    return _canRetrySearch && currentSosId == _dismissedRetrySosId;
  }
  bool get shouldShowSosStatusCard => _isSosActive && !isRetrySosDismissed;
  bool get shouldShowSosCreateSection => !_isSosActive || isRetrySosDismissed;

  void dismissRetrySosCard() {
    final currentSosId = _sosId?.trim();
    if (!_canRetrySearch ||
        currentSosId == null ||
        currentSosId.isEmpty) {
      return;
    }
    _dismissedRetrySosId = currentSosId;
    notifyListeners();
  }

  void _resetDismissedRetryIfNewSos(String? nextSosId) {
    final normalized = nextSosId?.trim();
    if (normalized == null || normalized.isEmpty) return;
    if (_dismissedRetrySosId != null && _dismissedRetrySosId != normalized) {
      _dismissedRetrySosId = null;
    }
  }

  /// Patient can cancel only for the first 2 minutes after SOS search starts.
  /// We hide the UI afterwards (server enforces it too).
  bool get canCancelActiveSos {
    if (!_isSosActive) return false;
    if (_sosId == null || _sosId!.isEmpty) return false;
    if (_sosStatus != 'OPEN') return false;
    if (_assignedAmbulance != null) return false;
    final start = _searchWindowStartedAt;
    if (start == null) return false;
    const window = Duration(minutes: 2);
    final endsAt = start.add(window);
    return DateTime.now().isBefore(endsAt);
  }

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

    final st = _normEnum(m['status']) ?? _sosStatus;
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

    final dvc = m['driversViewingCount'];
    if (dvc is int) {
      _driversViewingCount = dvc < 0 ? 0 : dvc;
    } else if (dvc != null) {
      final parsed = int.tryParse(dvc.toString());
      _driversViewingCount = (parsed ?? 0).clamp(0, 1000000);
    } else if (st == 'EXPIRED') {
      _driversViewingCount = 0;
    }

    final listRaw = m['driversViewingProfiles'];
    if (listRaw is List) {
      _driversViewingProfiles = listRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (st == 'EXPIRED') {
      _driversViewingProfiles = [];
    }
  }

  void _applyAssignedDriverFromSosMap(Map<String, dynamic> sos) {
    final st = _normEnum(sos['status']);
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
    _resetDismissedRetryIfNewSos(_sosId);
    _sosStatus = _normEnum(sos['status']) ?? _sosStatus;
    _emergencyType = sos['emergencyType']?.toString() ?? _emergencyType;
    _severity = sos['severity']?.toString() ?? _severity;
    _mergeSosTimingFromMap(sos);
    _activeTrip = sos['trip'] is Map
        ? Map<String, dynamic>.from(sos['trip'])
        : _activeTrip;
    _applyAssignedDriverFromSosMap(sos);
    if (_activeTrip != null) {
      _hydrateAmbulanceFromTripPayload(_activeTrip!);
    }
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

  /// `trip:updated` carries `driver` even when `sos:updated` was filtered or missed — align UI + tap-to-track.
  void _hydrateAmbulanceFromTripPayload(Map<String, dynamic> trip) {
    final ts = _normEnum(trip['status']);
    if (ts != 'ACCEPTED' && ts != 'ARRIVED' && ts != 'IN_PROGRESS') {
      return;
    }
    final d = trip['driver'];
    if (d is! Map) return;
    _emergencyType = trip['emergencyType']?.toString() ?? _emergencyType;
    _severity = trip['severity']?.toString() ?? _severity;
    _assignedAmbulance = AmbulanceModel.fromJson({
      'driver': Map<String, dynamic>.from(d),
      if (trip['latestLocation'] is Map)
        'latestLocation': trip['latestLocation'],
    });
    if (_sosStatus == 'OPEN') {
      _sosStatus = 'ASSIGNED';
    }
  }

  /// NestJS returns either a raw `[...]` or `{ "data": [...] }` from `GET /patient/sos`.
  List<Map<String, dynamic>>? _parseMySosList(dynamic response) {
    if (response == null) return null;
    if (response is List) {
      return response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (response is Map) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return null;
  }

  bool _matchesPatientIdentity(Object? raw) {
    if (raw == null) return false;
    if (_jwtPatientIdStr != null &&
        _jwtPatientIdStr!.isNotEmpty &&
        GpsCoord.sameId(raw, _jwtPatientIdStr!)) {
      return true;
    }
    if (_sessionPatientIdStr != null &&
        _sessionPatientIdStr!.isNotEmpty &&
        GpsCoord.sameId(raw, _sessionPatientIdStr!)) {
      return true;
    }
    return false;
  }

  Future<void> _savePendingTripPayments() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
      _kPendingTripPaymentIdsKey,
      _pendingTripPaymentIds.toList(),
    );
  }

  Future<void> _loadPendingTripPayments() async {
    if (_pendingTripPaymentsLoaded) return;
    _pendingTripPaymentsLoaded = true;
    try {
      final sp = await SharedPreferences.getInstance();
      final ids = sp.getStringList(_kPendingTripPaymentIdsKey) ?? const <String>[];
      _pendingTripPaymentIds
        ..clear()
        ..addAll(ids.where((e) => e.trim().isNotEmpty));
      if (_pendingTripPaymentIds.isNotEmpty) notifyListeners();
    } catch (_) {}
  }

  Future<void> _markTripPaymentPending(TripPaymentPromptEvent event) async {
    _pendingTripPaymentMeta[event.tripId] = event;
    if (_pendingTripPaymentIds.add(event.tripId)) {
      await _savePendingTripPayments();
      notifyListeners();
    }
  }

  Future<void> markTripPaymentSettled(String tripId) async {
    final tid = tripId.trim();
    if (tid.isEmpty) return;
    _pendingTripPaymentMeta.remove(tid);
    _tripPaymentPromptedIds.remove(tid);
    if (_pendingTripPaymentIds.remove(tid)) {
      await _savePendingTripPayments();
      notifyListeners();
    }
  }

  void _offerTripPaymentPrompt(Map<String, dynamic> raw) {
    if (_tripPaymentPromptController.isClosed) return;
    final tid =
        raw['tripId']?.toString() ?? raw['id']?.toString() ?? '';
    if (tid.isEmpty) return;
    if (_tripPaymentPromptedIds.contains(tid)) return;
    _tripPaymentPromptedIds.add(tid);

    final fare =
        double.tryParse(raw['fareAmount']?.toString() ?? '') ?? 0;
    final currency =
        raw['currency']?.toString().trim().isNotEmpty == true
            ? raw['currency'].toString()
            : 'CFA';
    String? driverName;
    final dn = raw['driverName'];
    if (dn != null && dn.toString().trim().isNotEmpty) {
      driverName = dn.toString();
    } else if (raw['driver'] is Map) {
      driverName =
          (raw['driver'] as Map)['fullName']?.toString();
    }

    final event = TripPaymentPromptEvent(
      tripId: tid,
      fareAmount: fare,
      currency: currency,
      driverName: driverName,
    );
    unawaited(_markTripPaymentPending(event));
    _tripPaymentPromptController.add(event);
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
    _sosBackupSyncTimer?.cancel();
    _searchUiTicker?.cancel();
    _sosSub?.cancel();
    _tripSub?.cancel();
    _locSub?.cancel();
    _tripPaySub?.cancel();
    _toastController.close();
    super.dispose();
  }

  bool _payloadIsForCurrentPatient(Map<String, dynamic> payload) {
    final hasId = (_jwtPatientIdStr != null && _jwtPatientIdStr!.isNotEmpty) ||
        (_sessionPatientIdStr != null && _sessionPatientIdStr!.isNotEmpty);
    if (!hasId) return false;
    final direct = payload['patientId'];
    if (direct != null) {
      return _matchesPatientIdentity(direct);
    }
    final pat = payload['patient'];
    if (pat is Map && pat['id'] != null) {
      return _matchesPatientIdentity(pat['id']);
    }
    // Many backends only put the patient in their user room and omit patientId on trip payloads.
    return true;
  }

  void _maybeEmitSosToast(Map<String, dynamic> payload) {
    if (_toastController.isClosed) return;
    final sid = payload['id']?.toString() ?? '';
    if (sid.isEmpty) return;
    final status = _normEnum(payload['status']) ?? '';
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
    final st = _normEnum(trip['status']);
    if (tid != null && tid.isNotEmpty && st != null && st.isNotEmpty) {
      _lastTripStatusById[tid] = st;
    }
  }

  void _maybeEmitTripStatusToast(Map<String, dynamic> payload) {
    if (_toastController.isClosed) return;
    final tid = payload['id']?.toString() ?? '';
    if (tid.isEmpty) return;
    final status = _normEnum(payload['status']) ?? '';
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
    final jwtUid = readAuthUserIdFromJwt(token);
    _jwtPatientIdStr = jwtUid?.toString();
    _sessionPatientIdStr = pid;
    _realtimeEnabled = true;
    unawaited(_loadPendingTripPayments());
    _pollingTimer?.cancel();
    _sosBackupSyncTimer?.cancel();
    _sosBackupSyncTimer =
        Timer.periodic(const Duration(seconds: 12), (_) {
      if (!_realtimeEnabled || !_isSosActive) return;
      if (_sosStatus != 'OPEN' || _assignedAmbulance != null) return;
      final tripSt = _normEnum(_activeTrip?['status']);
      if (tripSt == 'ACCEPTED' ||
          tripSt == 'ARRIVED' ||
          tripSt == 'IN_PROGRESS') {
        return;
      }
      checkActiveSos();
    });
    _seedTripStatusFromMap(_activeTrip);
    _syncTrackedTripIdFromActiveTrip();
    _socket.connect(url: '${AppUrl.baseUrl}/sos', token: token);
    scheduleMicrotask(() => checkActiveSos());

    _tripPaySub ??=
        _socket.tripPaymentRequiredStream.listen((payload) {
      final m = Map<String, dynamic>.from(payload);
      final pid = m['patientId'];
      if (pid != null && !_matchesPatientIdentity(pid)) return;
      _offerTripPaymentPrompt(m);
    });

    _sosSub ??= _socket.sosUpdatedStream.listen((payload) {
      final m = Map<String, dynamic>.from(payload);
      if (!_payloadIsForCurrentPatient(m)) return;

      _maybeEmitSosToast(m);

      _sosId = m['id']?.toString() ?? _sosId;
      _sosStatus = _normEnum(m['status']) ?? _sosStatus;
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
      _hydrateAmbulanceFromTripPayload(m);
      _mergeDriverLocationFromTripMap(_activeTrip);
      final tripId = _activeTrip?['id'];
      final status = _normEnum(_activeTrip?['status']);

      if (status == 'COMPLETED' || status == 'CANCELLED') {
        if (status == 'COMPLETED') {
          _lastCompletedTripId = _activeTrip?['id']?.toString();
          final payMap = Map<String, dynamic>.from(m);
          payMap['tripId'] ??= m['id'];
          payMap['fareAmount'] ??= m['fareAmount'];
          payMap['currency'] ??= m['currency'];
          if (payMap['driverName'] == null && m['driver'] is Map) {
            payMap['driverName'] =
                (m['driver'] as Map)['fullName']?.toString();
          }
          _offerTripPaymentPrompt(payMap);
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
      final list = _parseMySosList(response);
      if (list != null && list.isNotEmpty) {
        final sos = list.first;
        final st = _normEnum(sos['status']);
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
    } catch (e) {
      debugPrint("Error checking active SOS: $e");
    }
  }

  Future<void> triggerSos(BuildContext context) async {
    // Basic SOS trigger
    _triggerSosInternal(
      context,
      incidentType: 'Medical Emergency',
      severity: 'High',
    );
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
    String? incidentType,
    String? severity,
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
        incidentType: incidentType,
        severity: severity,
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
        final list = _parseMySosList(response);
        if (list == null || list.isEmpty) return;
        final sos = list.first;
        final st = _normEnum(sos['status']);
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
          final tripStatus = _normEnum(trip?['status']);
          if (tripStatus == 'COMPLETED') {
            _lastCompletedTripId = trip?['id']?.toString();
          }
          cancelSos();
        } else {
          notifyListeners();
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
    if (trip == 'ACCEPTED') return 'Ambulance Dispatched';
    if (_sosStatus == 'OPEN') return 'Finding Driver';
    return 'Ambulance Dispatched';
  }

  String get sosEtaText {
    if (_sosStatus == 'EXPIRED') {
      return _noDriverFoundMessage ?? SosConstants.noAmbulanceDriverMessage;
    }
    final rem = searchWindowRemaining;
    final tripSt = tripStatus;
    if (tripSt == 'ACCEPTED' ||
        tripSt == 'ARRIVED' ||
        tripSt == 'IN_PROGRESS') {
      // fall through to trip-based ETA
    } else if (_sosStatus == 'OPEN' &&
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

  /// Cancels the active SOS on the server (within cancel window) then clears local state.
  Future<void> cancelActiveSosOnServer(BuildContext context) async {
    final id = _sosId;
    if (id == null || id.isEmpty) return;
    if (!canCancelActiveSos) return;
    try {
      final res = await _apiServices.cancelPatientSos(id);
      cancelSos();
      if (context.mounted) {
        final msg = res is Map ? res['message']?.toString() : null;
        Utils.toastMessage(
          context,
          (msg != null && msg.trim().isNotEmpty)
              ? msg.trim()
              : 'Emergency request cancelled',
        );
      }
    } catch (e) {
      if (context.mounted) {
        Utils.toastError(context, e);
      }
    }
  }

  void cancelSos() {
    _isSosActive = false;
    _assignedAmbulance = null;
    _sosStatus = null;
    _sosId = null;
    _activeTrip = null;
    _trackedTripIdKey = null;
    _emergencyType = null;
    _severity = null;
    _lastSosStatusById.clear();
    _lastTripStatusById.clear();
    _searchWindowStartedAt = null;
    _searchWindowEndsAt = null;
    _noDriverFoundMessage = null;
    _dismissedRetrySosId = null;
    _canRetrySearch = false;
    _driversViewingCount = 0;
    _driversViewingProfiles = [];
    _searchWindowMinutes = 2;
    _stopSearchUiTicker();
    _socket.clearJoinedRooms();
    _pollingTimer?.cancel();
    _sosBackupSyncTimer?.cancel();
    _sosBackupSyncTimer = null;
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
