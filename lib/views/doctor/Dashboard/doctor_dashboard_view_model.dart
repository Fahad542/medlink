import 'package:flutter/material.dart';
import 'dart:async';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/utils/notification_payload_utils.dart';
import 'package:medlink/services/chat_socket_service.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final ChatSocketService _chatSocket = ChatSocketService.instance;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<Map<String, dynamic>>? _chatReadSub;
  final Set<String> _seenSocketKeys = {};

  bool _isOnline = true;
  String _earnings = "0";
  String _currency = "CFA";
  bool _isLoadingEarnings = false;
  bool _isLoadingAppointments = false;
  
  int _patientsCount = 0;
  int _appointmentsCount = 0;
  int _unreadMessagesCount = 0;
  int _unreadNotificationsCount = 0;
  List<AppointmentModel> _upcomingAppointments = [];
  int? _currentUserId;
  String? _chatToken;

  DoctorDashboardViewModel() {
    fetchData();
  }

  bool get isOnline => _isOnline;
  String get earnings => _earnings;
  String get currency => _currency;
  bool get isLoadingEarnings => _isLoadingEarnings;
  bool get isLoadingAppointments => _isLoadingAppointments;
  
  int get patientsCount => _patientsCount;
  int get appointmentsCount => _appointmentsCount;
  int get unreadMessagesCount => _unreadMessagesCount;
  int get unreadNotificationsCount => _unreadNotificationsCount;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;

  Future<void> updateAvailability(bool value) async {
    // Optimistically update UI
    final previousStatus = _isOnline;
    _isOnline = value;
    notifyListeners();

    try {
      final response = await _apiServices.updateDoctorAvailability(value);
      if (response == null || response['success'] != true) {
        // Rollback on failure
        _isOnline = previousStatus;
        notifyListeners();
        debugPrint("Failed to update availability on server");
      }
    } catch (e) {
      // Rollback on error
      _isOnline = previousStatus;
      notifyListeners();
      debugPrint("Error updating availability: $e");
    }
  }

  Future<void> fetchData() async {
    await Future.wait([
      fetchEarnings(),
      fetchUpcomingAppointments(),
      fetchAvailability(),
      fetchPatientsCount(),
      fetchUnreadNotificationsCount(),
    ]);
  }

  void ensureChatRealtime({required String token, required int? currentUserId}) {
    if (token.isEmpty) return;
    _currentUserId = currentUserId;
    if (_chatSub != null && _chatToken == token) return;
    _chatToken = token;
    _chatSocket.connect(url: '${AppUrl.baseUrl}/chat', token: token);
    _chatSub?.cancel();
    _chatReadSub?.cancel();
    _chatSub = _chatSocket.newMessageStream.listen(_onChatSocketMessage);
    _chatReadSub = _chatSocket.conversationReadStream.listen((_) {
      unawaited(fetchUnreadMessagesCount());
    });
    fetchUnreadMessagesCount();
    fetchUnreadNotificationsCount();
  }

  Future<void> fetchUnreadNotificationsCount() async {
    try {
      final response = await _apiServices.getDoctorNotifications(limit: 80);
      if (response is! Map || response['success'] != true) return;
      final data = response['data'];
      if (data is! Map) return;
      final n = unreadCountFromNotificationsPayload(
        Map<String, dynamic>.from(data),
      );
      if (n != _unreadNotificationsCount) {
        _unreadNotificationsCount = n;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Doctor dashboard notifications badge error: $e');
    }
  }

  Future<void> fetchUnreadMessagesCount() async {
    try {
      final response = await _apiServices.getConversations();
      List<dynamic>? list;
      if (response is Map && response['data'] is List) {
        list = response['data'] as List;
      } else if (response is List) {
        list = response;
      }
      if (list == null) return;

      int total = 0;
      for (final raw in list) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final other = item['other'];
        if (other is Map) {
          final role = other['role']?.toString().toUpperCase() ?? '';
          if (role.isNotEmpty && role != 'PATIENT') continue;
        }
        final u = item['unreadCount'] ?? item['unread'] ?? 0;
        final count = u is int ? u : int.tryParse(u.toString()) ?? 0;
        if (count > 0) total += count;
      }

      if (total != _unreadMessagesCount) {
        _unreadMessagesCount = total;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Doctor dashboard unread count error: $e');
    }
  }

  static Map<String, dynamic> _unwrapSocketMessage(Map<String, dynamic> payload) {
    if (payload['message'] is Map) {
      return Map<String, dynamic>.from(payload['message'] as Map);
    }
    if (payload['data'] is Map) {
      return Map<String, dynamic>.from(payload['data'] as Map);
    }
    return payload;
  }

  bool _consumeSocketDedupe(Map<String, dynamic> msg) {
    final rawId = msg['id'];
    final mid = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    late final String key;
    if (mid != null && mid > 0) {
      key = 'id:$mid';
    } else {
      final sid = msg['senderId']?.toString() ?? '';
      final rid = msg['recipientId']?.toString() ?? '';
      final sa = msg['sentAt']?.toString() ?? '';
      final body = msg['body']?.toString() ?? '';
      if (sid.isEmpty || sa.isEmpty) return true;
      key = 'fb:$sid|$rid|$sa|$body';
    }
    if (_seenSocketKeys.contains(key)) return false;
    _seenSocketKeys.add(key);
    if (_seenSocketKeys.length > 400) _seenSocketKeys.clear();
    return true;
  }

  void _onChatSocketMessage(Map<String, dynamic> payload) {
    try {
      final myId = _currentUserId;
      if (myId == null) return;

      var msg = _unwrapSocketMessage(payload);
      if (msg['id'] == null && payload['id'] != null) {
        msg = Map<String, dynamic>.from(msg)..['id'] = payload['id'];
      }
      if (msg['sosId'] != null || msg['tripId'] != null) return;
      if (!_consumeSocketDedupe(msg)) return;

      final senderId = int.tryParse(msg['senderId']?.toString() ?? '');
      final recipientId = int.tryParse(msg['recipientId']?.toString() ?? '');
      if (senderId == null || recipientId == null) return;

      // Only increment when a patient sends message to current doctor.
      if (recipientId == myId && senderId != myId) {
        _unreadMessagesCount += 1;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Doctor dashboard chat socket error: $e');
    }
  }

  Future<void> fetchAvailability() async {
    try {
      final response = await _apiServices.getDoctorProfile();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          _isOnline = data['isAvailable'] ?? data['isActive'] ?? true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctor availability: $e");
    }
  }

  Future<void> fetchEarnings() async {
    _isLoadingEarnings = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final response = await _apiServices.getDoctorMonthlyEarnings(now.year, now.month);
      
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          _earnings = data['totalAmount']?.toString() ?? "0";
          _currency = data['currency'] ?? "CFA";
        }
      }
    } catch (e) {
      debugPrint("Error fetching earnings: $e");
    } finally {
      _isLoadingEarnings = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingAppointments() async {
    _isLoadingAppointments = true;
    notifyListeners();

    try {
      final response = await _apiServices.getDoctorUpcomingAppointments();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _upcomingAppointments = data
            .map((json) => AppointmentModel.fromJson(json))
            .where((a) => a.isDoctorUpcomingSlot)
            .toList();
        AppointmentModel.sortByCreatedAtDescending(_upcomingAppointments);
        _appointmentsCount = _upcomingAppointments.length;
      }
    } catch (e) {
      debugPrint("Error fetching upcoming appointments: $e");
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  /// Immediate UI update after cancel (before refetch completes).
  void removeUpcomingAppointmentById(String id) {
    final before = _upcomingAppointments.length;
    _upcomingAppointments.removeWhere((a) => a.id == id);
    if (_upcomingAppointments.length != before) {
      _appointmentsCount = _upcomingAppointments.length;
      notifyListeners();
    }
  }

  Future<void> fetchPatientsCount() async {
    try {
      final response = await _apiServices.getDoctorPatients();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        _patientsCount = data.length;
      }
    } catch (e) {
      debugPrint("Error fetching patients count: $e");
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _chatReadSub?.cancel();
    super.dispose();
  }
}
