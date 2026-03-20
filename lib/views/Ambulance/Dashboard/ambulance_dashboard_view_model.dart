import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/services/sos_socket_service.dart';

class AmbulanceDashboardViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final SosSocketService _socket = SosSocketService.instance;
  StreamSubscription<Map<String, dynamic>>? _sosSub;

  bool _isOnline = true;
  List<Map<String, dynamic>> _activeRequests = [];

  // Stats from API
  int _totalTrips = 0;
  num _totalEarnings = 0;
  String _profilePhotoUrl = '';

  bool _isLoadingDashboard = true;
  bool get isLoadingDashboard => _isLoadingDashboard;

  AmbulanceDashboardViewModel() {
    _loadDashboard();
    _loadActiveRequests();
    _loadProfile();
    _sosSub = _socket.sosUpdatedStream.listen(_handleSosUpdated);
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    super.dispose();
  }

  bool get isOnline => _isOnline;
  List<Map<String, dynamic>> get activeRequests => _activeRequests;
  int get completedTrips => _totalTrips;
  String get earnings => _totalEarnings
      .toStringAsFixed(_totalEarnings == _totalEarnings.round() ? 0 : 2);
  double get rating => 4.8;
  String get profilePhotoUrl => _profilePhotoUrl;

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
      _loadActiveRequests(),
      _loadProfile(), // Reload profile on pull-to-refresh
    ]);
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
          _activeRequests = List<Map<String, dynamic>>.from(data.map((item) {
            return {
              'id': item['id'].toString(),
              'patientName': item['patient']?['fullName'] ?? 'Unknown',
              'severity': item['severity'] ?? 'High',
              'distance':
                  'Calculating...', // You can calculate distance if user location is available
              'location': item['addressText'] ??
                  'Lat: ${item['lat']}, Lng: ${item['lng']}',
              'incident': item['emergencyType'] ?? 'Emergency',
              'time': _formatTime(item['createdAt']),
            };
          }));
        }
      }
    } catch (e) {
      debugPrint('Error loading active requests: $e');
    }
    notifyListeners();
  }

  void _handleSosUpdated(Map<String, dynamic> payload) {
    if (!_isOnline) return;
    if (payload['status']?.toString() != 'OPEN') return;
    if (payload['assignedDriverId'] != null) return;

    final id = payload['id']?.toString();
    if (id == null || id.isEmpty) return;
    final exists = _activeRequests.any((r) => r['id']?.toString() == id);
    if (exists) return;

    final patient = payload['patient'] is Map
        ? Map<String, dynamic>.from(payload['patient'])
        : <String, dynamic>{};

    _activeRequests.insert(0, {
      'id': id,
      'patientName': patient['fullName'] ?? 'Unknown',
      'severity': payload['severity'] ?? 'High',
      'distance': 'Calculating...',
      'location': payload['addressText'] ??
          'Lat: ${payload['lat']}, Lng: ${payload['lng']}',
      'incident': payload['emergencyType'] ?? 'Emergency',
      'time': _formatTime(payload['createdAt']?.toString()),
    });
    notifyListeners();
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return 'Just now';
    try {
      final date = DateTime.parse(createdAt);
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
