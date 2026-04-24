import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/sos_socket_service.dart';

class AmbulanceDashboardViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final SosSocketService _socket = SosSocketService.instance;
  StreamSubscription<Map<String, dynamic>>? _sosSub;
  Timer? _countdownTickTimer;

  /// Dedupe reverse-geocode lookups by rounded coordinates.
  final Map<String, String> _reverseGeocodeCache = {};

  bool _isOnline = true;
  List<Map<String, dynamic>> _activeRequests = [];

  /// From public system settings; per-request overrides may exist on each SOS.
  int _sosDriverSearchWindowMinutes = 2;

  // Stats from API
  int _totalTrips = 0;
  num _totalEarnings = 0;
  String _profilePhotoUrl = '';
  String _currency = 'CFA';

  bool _isLoadingDashboard = true;
  bool get isLoadingDashboard => _isLoadingDashboard;

  AmbulanceDashboardViewModel() {
    _loadDashboard();
    _loadSystemSosWindow();
    _loadActiveRequests();
    _loadProfile();
    _sosSub = _socket.sosUpdatedStream.listen(_handleSosUpdated);
    _countdownTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isOnline) return;
      final before = _activeRequests.length;
      _activeRequests.removeWhere(
          (r) => remainingAcceptTimeForRequest(r) <= Duration.zero);
      if (before != _activeRequests.length || _activeRequests.isNotEmpty) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _countdownTickTimer?.cancel();
    _sosSub?.cancel();
    super.dispose();
  }

  int _windowMinutesFor(Map<String, dynamic> r) {
    final raw = r['searchWindowMinutes'];
    if (raw != null) {
      return (int.tryParse(raw.toString()) ?? _sosDriverSearchWindowMinutes)
          .clamp(1, 1440);
    }
    return _sosDriverSearchWindowMinutes.clamp(1, 1440);
  }

  /// Time left to accept (from `searchWindowStartedAt`, else `createdAt`). Zero if expired.
  Duration remainingAcceptTimeForRequest(Map<String, dynamic> r) {
    final window = Duration(minutes: _windowMinutesFor(r));
    final startRaw = r['searchWindowStartedAt'] ?? r['createdAt'];
    if (startRaw == null) return Duration.zero;
    try {
      final t = DateTime.parse(startRaw.toString()).toUtc();
      final end = t.add(window);
      final left = end.difference(DateTime.now().toUtc());
      return left.isNegative ? Duration.zero : left;
    } catch (_) {
      return Duration.zero;
    }
  }

  /// 1.0 = window just started, 0.0 = window ended.
  double acceptProgressFractionFor(Map<String, dynamic> r) {
    final window = Duration(minutes: _windowMinutesFor(r));
    final startRaw = r['searchWindowStartedAt'] ?? r['createdAt'];
    if (startRaw == null) return 0.0;
    try {
      final t = DateTime.parse(startRaw.toString()).toUtc();
      final now = DateTime.now().toUtc();
      final elapsed = now.difference(t);
      if (elapsed <= Duration.zero) return 1.0;
      if (elapsed >= window) return 0.0;
      return 1.0 - (elapsed.inMilliseconds / window.inMilliseconds);
    } catch (_) {
      return 0.0;
    }
  }

  static String formatCountdownMmSs(Duration d) {
    if (d <= Duration.zero) return '0:00';
    final totalSec = d.inSeconds;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _formatDistanceMeters(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  static String _placemarkLine(Placemark p) {
    final parts = <String>[
      if (p.street != null && p.street!.trim().isNotEmpty) p.street!.trim(),
      if (p.subLocality != null && p.subLocality!.trim().isNotEmpty)
        p.subLocality!.trim(),
      if (p.locality != null && p.locality!.trim().isNotEmpty) p.locality!.trim(),
      if (p.administrativeArea != null &&
          p.administrativeArea!.trim().isNotEmpty)
        p.administrativeArea!.trim(),
    ];
    if (parts.isEmpty) {
      final n = p.name?.trim();
      if (n != null && n.isNotEmpty) return n;
      return '';
    }
    return parts.join(', ');
  }

  Future<Position?> _tryDriverPosition() async {
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
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('AmbulanceDashboardViewModel _tryDriverPosition: $e');
      return null;
    }
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    final key =
        '${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';
    final cached = _reverseGeocodeCache[key];
    if (cached != null) return cached;
    try {
      final list = await placemarkFromCoordinates(lat, lng);
      if (list.isEmpty) return null;
      final line = _placemarkLine(list.first).trim();
      if (line.isEmpty) return null;
      _reverseGeocodeCache[key] = line;
      return line;
    } catch (e) {
      debugPrint('AmbulanceDashboardViewModel _reverseGeocode: $e');
      return null;
    }
  }

  Future<void> _enrichRequestsLocationAndDistance() async {
    if (_activeRequests.isEmpty) return;

    final driver = await _tryDriverPosition();
    bool anyChange = false;

    for (final r in _activeRequests) {
      final lat = _toDouble(r['lat']);
      final lng = _toDouble(r['lng']);

      if (lat != null && lng != null && driver != null) {
        final meters = Geolocator.distanceBetween(
          driver.latitude,
          driver.longitude,
          lat,
          lng,
        );
        final label = _formatDistanceMeters(meters);
        if (r['distance'] != label) {
          r['distance'] = label;
          anyChange = true;
        }
      } else if (lat != null && lng != null) {
        const fallback = 'Turn on location for distance';
        if (r['distance'] != fallback) {
          r['distance'] = fallback;
          anyChange = true;
        }
      }

      final hasAddr = r['hasAddressFromApi'] == true;
      final loc = r['location']?.toString() ?? '';
      final needsGeocode =
          !hasAddr && lat != null && lng != null && loc == 'Loading address...';
      if (needsGeocode) {
        final resolved = await _reverseGeocode(lat, lng);
        final next = resolved ?? 'Address unavailable';
        if (r['location'] != next) {
          r['location'] = next;
          anyChange = true;
        }
      }
    }

    if (anyChange) notifyListeners();
  }

  Map<String, dynamic> _mapEmergencyRequest(Map<String, dynamic> m) {
    final addrRaw = m['addressText']?.toString().trim();
    final hasAddr = addrRaw != null && addrRaw.isNotEmpty;
    final address = hasAddr ? addrRaw : null;
    final lat = _toDouble(m['lat']);
    final lng = _toDouble(m['lng']);
    final destinationLat = _toDouble(m['destinationLat'] ?? m['dropoffLat']);
    final destinationLng = _toDouble(m['destinationLng'] ?? m['dropoffLng']);
    return {
      'id': m['id'].toString(),
      'createdAt': m['createdAt'],
      'searchWindowStartedAt': m['searchWindowStartedAt'],
      'searchWindowMinutes': m['searchWindowMinutes'],
      'patientName': m['patient']?['fullName'] ?? 'Unknown',
      'lat': lat,
      'lng': lng,
      'hasAddressFromApi': hasAddr,
      'distance': '—',
      'location': hasAddr
          ? address
          : (lat != null && lng != null ? 'Loading address...' : 'Location unavailable'),
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'incident': m['emergencyType'] ?? 'Emergency',
      'time': _formatTime(
        (m['searchWindowStartedAt'] ?? m['createdAt'])?.toString(),
      ),
    };
  }

  Map<String, dynamic> _mapSosPayload(Map<String, dynamic> payload) {
    final addrRaw = payload['addressText']?.toString().trim();
    final hasAddr = addrRaw != null && addrRaw.isNotEmpty;
    final address = hasAddr ? addrRaw : null;
    final lat = _toDouble(payload['lat']);
    final lng = _toDouble(payload['lng']);
    final destinationLat =
        _toDouble(payload['destinationLat'] ?? payload['dropoffLat']);
    final destinationLng =
        _toDouble(payload['destinationLng'] ?? payload['dropoffLng']);
    final patient = payload['patient'] is Map
        ? Map<String, dynamic>.from(payload['patient'] as Map)
        : <String, dynamic>{};

    return {
      'id': payload['id'].toString(),
      'createdAt': payload['createdAt'],
      'searchWindowStartedAt': payload['searchWindowStartedAt'],
      'searchWindowMinutes': payload['searchWindowMinutes'],
      'patientName': patient['fullName'] ?? 'Unknown',
      'lat': lat,
      'lng': lng,
      'hasAddressFromApi': hasAddr,
      'distance': '—',
      'location': hasAddr
          ? address
          : (lat != null && lng != null ? 'Loading address...' : 'Location unavailable'),
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'incident': payload['emergencyType'] ?? 'Emergency',
      'time': _formatTime(
        (payload['searchWindowStartedAt'] ?? payload['createdAt'])
            ?.toString(),
      ),
    };
  }

  bool get isOnline => _isOnline;
  List<Map<String, dynamic>> get activeRequests => _activeRequests;
  int get completedTrips => _totalTrips;
  String get earnings => _totalEarnings
      .toStringAsFixed(_totalEarnings == _totalEarnings.round() ? 0 : 2);
  double get rating => 4.8;
  String get profilePhotoUrl => _profilePhotoUrl;
  String get currency => _currency;

  Future<void> _loadProfile() async {
    try {
      final response = await _apiServices.getDriverProfile();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['user'] is Map) {
          _profilePhotoUrl = data['user']['profilePhotoUrl']?.toString() ?? '';
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading profile photo: $e');
    }
  }

  Future<void> _loadDashboard() async {
    _isLoadingDashboard = true;
    notifyListeners();
    try {
      final response = await _apiServices.getDriverDashboard();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          _totalTrips = (data['totalTrips'] is int)
              ? data['totalTrips'] as int
              : int.tryParse(data['totalTrips']?.toString() ?? '0') ?? 0;
          final earningsRaw = data['totalEarnings'];
          if (earningsRaw is num) {
            _totalEarnings = earningsRaw;
          } else {
            _totalEarnings = num.tryParse(earningsRaw?.toString() ?? '0') ?? 0;
          }
          _currency = data['currency'] ?? 'CFA';
        }
      }
    } catch (e) {
      debugPrint('AmbulanceDashboardViewModel _loadDashboard error: $e');
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    await Future.wait([
      _loadDashboard(),
      _loadSystemSosWindow(),
      _loadActiveRequests(),
      _loadProfile(), // Reload profile on pull-to-refresh
    ]);
  }

  Future<void> _loadSystemSosWindow() async {
    try {
      final response = await _apiServices.getSystemSettings();
      if (response != null && response['success'] == true && response['data'] is Map) {
        final raw =
            (response['data'] as Map)['sosDriverSearchWindowMinutes'];
        if (raw != null) {
          _sosDriverSearchWindowMinutes =
              (int.tryParse(raw.toString()) ?? _sosDriverSearchWindowMinutes)
                  .clamp(1, 1440);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AmbulanceDashboardViewModel _loadSystemSosWindow: $e');
    }
  }

  Future<void> toggleOnlineStatus(bool value) async {
    final previousStatus = _isOnline;
    _isOnline = value;
    notifyListeners();

    try {
      final response = await _apiServices.updateDriverStatus(value);
      if (response == null || response['success'] != true) {
        _isOnline = previousStatus;
        notifyListeners();
        debugPrint(
            'AmbulanceDashboardViewModel: failed to update driver status on server');
      }
    } catch (e) {
      _isOnline = previousStatus;
      notifyListeners();
      debugPrint('AmbulanceDashboardViewModel toggleOnlineStatus error: $e');
    }
  }

  Future<void> _loadActiveRequests() async {
    if (!_isOnline) return;

    try {
      final response = await _apiServices.getDriverEmergencyRequests();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _activeRequests = List<Map<String, dynamic>>.from(
            data.where((item) => item is Map).map((item) {
              final m = Map<String, dynamic>.from(item as Map);
              return _mapEmergencyRequest(m);
            }),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading active requests: $e');
    }
    notifyListeners();
    unawaited(_enrichRequestsLocationAndDistance());
  }

  void _handleSosUpdated(Map<String, dynamic> payload) {
    if (!_isOnline) return;

    final id = payload['id']?.toString();
    if (id == null || id.isEmpty) return;

    final status = payload['status']?.toString();
    final assigned = payload['assignedDriverId'];

    final bool inPool =
        status == 'OPEN' && (assigned == null || assigned.toString().isEmpty);

    if (!inPool) {
      _activeRequests.removeWhere((r) => r['id']?.toString() == id);
      notifyListeners();
      return;
    }

    _activeRequests.removeWhere((r) => r['id']?.toString() == id);
    _activeRequests.insert(
      0,
      _mapSosPayload(Map<String, dynamic>.from(payload)),
    );
    notifyListeners();
    unawaited(_enrichRequestsLocationAndDistance());
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return 'Just now';
    try {
      final date = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return 'Just now';
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    try {
      final response = await _apiServices.acceptEmergencyRequest(requestId);
      if (response != null && response['success'] == true) {
        _activeRequests.removeWhere((req) => req['id'] == requestId);
        notifyListeners();
        return true;
      } else {
        debugPrint("Failed to accept request");
        return false;
      }
    } catch (e) {
      debugPrint("Error accepting request: $e");
      return false;
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      final response = await _apiServices.declineEmergencyRequest(requestId);
      if (response != null && response['success'] == true) {
        _activeRequests.removeWhere((req) => req['id'] == requestId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error declining request: $e");
    }
  }
}
