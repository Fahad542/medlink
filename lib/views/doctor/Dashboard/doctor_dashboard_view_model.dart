import 'package:flutter/material.dart';
import 'dart:async';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/services/chat_socket_service.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/utils/jwt_user_id.dart';

class DoctorDashboardViewModel extends ChangeNotifier {
  final UserViewModel _userViewModel;
  final ApiServices _apiServices = ApiServices();
  final ChatSocketService _chatSocket = ChatSocketService.instance;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<Map<String, dynamic>>? _chatReadSub;
  final Set<String> _seenSocketKeys = {};
  Timer? _sessionRefreshDebounce;
  Timer? _socketUnreadDebounce;

  bool _isOnline = true;
  String _earnings = "0";
  String _currency = "CFA";
  bool _isLoadingEarnings = false;
  bool _isLoadingAppointments = false;

  int _patientsCount = 0;
  int _appointmentsCount = 0;
  int _unreadMessagesCount = 0;
  List<AppointmentModel> _upcomingAppointments = [];
  int? _currentUserId;
  String? _chatToken;

  DoctorDashboardViewModel(this._userViewModel) {
    _userViewModel.addListener(_onUserSessionChanged);
    fetchData();
  }

  void _onUserSessionChanged() {
    _sessionRefreshDebounce?.cancel();
    _sessionRefreshDebounce = Timer(const Duration(milliseconds: 400), () {
      _sessionRefreshDebounce = null;
      ensureChatRealtime();
    });
  }

  int? get _myUserId =>
      _userViewModel.loginSession?.data?.user?.id ??
      int.tryParse(_userViewModel.doctor?.id ?? '') ??
      readAuthUserIdFromJwt(_userViewModel.accessToken);

  void _scheduleUnreadSyncFromSocket() {
    _socketUnreadDebounce?.cancel();
    _socketUnreadDebounce = Timer(const Duration(milliseconds: 450), () {
      _socketUnreadDebounce = null;
      unawaited(fetchUnreadMessagesCount());
    });
  }

  static int? _participantId(Map<String, dynamic> msg, String camel, String snake) {
    final a = msg[camel];
    final b = msg[snake];
    if (a is int) return a;
    if (b is int) return b;
    final s = a?.toString() ?? b?.toString() ?? '';
    return int.tryParse(s);
  }

  bool get isOnline => _isOnline;
  String get earnings => _earnings;
  String get currency => _currency;
  bool get isLoadingEarnings => _isLoadingEarnings;
  bool get isLoadingAppointments => _isLoadingAppointments;

  int get patientsCount => _patientsCount;
  int get appointmentsCount => _appointmentsCount;
  int get unreadMessagesCount => _unreadMessagesCount;
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
    ]);
  }

  /// Keeps socket + unread badge in sync on any tab (call when session/token changes).
  void ensureChatRealtime() {
    final token = _userViewModel.accessToken ?? '';
    if (token.isEmpty) return;

    _currentUserId = _myUserId;
    _chatSocket.connect(url: '${AppUrl.baseUrl}/chat', token: token);

    final tokenChanged = _chatToken != token;
    _chatToken = token;
    if (tokenChanged || _chatSub == null) {
      _chatSub?.cancel();
      _chatReadSub?.cancel();
      _chatSub = _chatSocket.newMessageStream.listen(_onChatSocketMessage);
      _chatReadSub = _chatSocket.conversationReadStream.listen((_) {
        unawaited(fetchUnreadMessagesCount());
      });
    }
    unawaited(fetchUnreadMessagesCount());
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
      final sid = _participantId(msg, 'senderId', 'sender_id')?.toString() ?? '';
      final rid =
          _participantId(msg, 'recipientId', 'recipient_id')?.toString() ?? '';
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
      final myId = _currentUserId ?? _myUserId;

      var msg = _unwrapSocketMessage(payload);
      if (msg['id'] == null && payload['id'] != null) {
        msg = Map<String, dynamic>.from(msg)..['id'] = payload['id'];
      }
      if (msg['sosId'] != null || msg['tripId'] != null) return;
      if (!_consumeSocketDedupe(msg)) return;

      final senderId = _participantId(msg, 'senderId', 'sender_id');
      final recipientId = _participantId(msg, 'recipientId', 'recipient_id');
      if (senderId == null || recipientId == null) {
        _scheduleUnreadSyncFromSocket();
        return;
      }

      if (myId != null &&
          recipientId == myId &&
          senderId != myId) {
        _unreadMessagesCount += 1;
        notifyListeners();
      }
      _scheduleUnreadSyncFromSocket();
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
      final response =
          await _apiServices.getDoctorMonthlyEarnings(now.year, now.month);

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
        _upcomingAppointments =
            data.map((json) => AppointmentModel.fromJson(json)).toList();
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
    _userViewModel.removeListener(_onUserSessionChanged);
    _sessionRefreshDebounce?.cancel();
    _socketUnreadDebounce?.cancel();
    _chatSub?.cancel();
    _chatReadSub?.cancel();
    super.dispose();
  }
}
