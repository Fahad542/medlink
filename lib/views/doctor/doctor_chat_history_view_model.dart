import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/doctor_chat_history_model.dart';
import 'package:medlink/services/chat_socket_service.dart';
import 'package:medlink/views/services/session_view_model.dart';

class DoctorChatHistoryViewModel extends ChangeNotifier {
  final UserViewModel _userViewModel;
  final _apiService = ApiServices();
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DoctorChatHistoryModel? _chatHistory;
  DoctorChatHistoryModel? get chatHistory => _chatHistory;

  final Set<String> _seenSocketKeys = {};

  int? get _myUserId =>
      _userViewModel.loginSession?.data?.user?.id ??
      int.tryParse(_userViewModel.doctor?.id ?? '');

  /// Same id used for GET conversations / fallback history (JWT user id).
  String get _doctorIdForApi =>
      _userViewModel.loginSession?.data?.user?.id?.toString() ??
      _userViewModel.doctor?.id ??
      '';

  DoctorChatHistoryViewModel(this._userViewModel) {
    _subscribeSocket();
  }

  void _subscribeSocket() {
    final token = _userViewModel.accessToken;
    if (token == null || token.isEmpty) return;
    ChatSocketService.instance
        .connect(url: '${AppUrl.baseUrl}/chat', token: token);
    _socketSub?.cancel();
    _socketSub =
        ChatSocketService.instance.newMessageStream.listen(_onSocketMessage);
  }

  static Map<String, dynamic> _unwrapSocketMessage(
      Map<String, dynamic> payload) {
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
    if (_seenSocketKeys.length > 400) {
      _seenSocketKeys.clear();
    }
    return true;
  }

  void _onSocketMessage(Map<String, dynamic> payload) {
    final myId = _myUserId;
    if (myId == null) return;
    final rows = _chatHistory?.data;

    try {
      var msg = _unwrapSocketMessage(payload);
      if (msg['id'] == null && payload['id'] != null) {
        msg = Map<String, dynamic>.from(msg)..['id'] = payload['id'];
      }
      if (msg['sosId'] != null || msg['tripId'] != null) return;
      if (!_consumeSocketDedupe(msg)) return;

      final senderId = int.tryParse(msg['senderId']?.toString() ?? '');
      final recipientId = int.tryParse(msg['recipientId']?.toString() ?? '');
      if (senderId == null) return;

      final int? peerPatientId = senderId == myId ? recipientId : senderId;
      if (peerPatientId == null) {
        fetchChatHistory(_doctorIdForApi);
        return;
      }

      // List may still be loading (fetch runs post-frame) or new patient thread.
      if (rows == null || rows.isEmpty) {
        fetchChatHistory(_doctorIdForApi);
        return;
      }

      final type = msg['messageType']?.toString() ?? 'TEXT';
      final preview =
          type == 'IMAGE' ? '📷 Photo' : (msg['body']?.toString() ?? '');
      DateTime sentAt;
      try {
        sentAt = DateTime.parse(msg['sentAt'].toString());
      } catch (_) {
        sentAt = DateTime.now().toUtc();
      }
      final dateStr = sentAt.toUtc().toIso8601String();

      final idx = rows.indexWhere(
        (c) => int.tryParse(c.patient?.id ?? '') == peerPatientId,
      );
      if (idx < 0) {
        fetchChatHistory(_doctorIdForApi);
        return;
      }

      final row = rows[idx];
      final fromPeer = senderId != myId;
      final prior = row.unreadCount ?? 0;
      final nextUnread = fromPeer ? prior + 1 : 0;
      final updated = DoctorChatHistoryData(
        patient: row.patient,
        lastMessage: preview.isEmpty ? row.lastMessage : preview,
        lastMessageDate: dateStr,
        unreadCount: nextUnread,
      );
      final list = List<DoctorChatHistoryData>.from(rows);
      list[idx] = updated;
      list.sort((a, b) {
        final da = DateTime.tryParse(a.lastMessageDate ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b.lastMessageDate ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      _chatHistory = DoctorChatHistoryModel(success: true, data: list);
      notifyListeners();
    } catch (e, st) {
      debugPrint('DoctorChatHistoryViewModel socket: $e $st');
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> fetchChatHistory(String doctorId) async {
    _isLoading = true;
    notifyListeners();

    if (_socketSub == null &&
        (_userViewModel.accessToken?.isNotEmpty ?? false)) {
      _subscribeSocket();
    }

    DoctorChatHistoryModel? model;
    try {
      try {
        final conv = await _apiService.getConversations();
        model = DoctorChatHistoryModel.fromConversationsApi(conv);
      } catch (e) {
        debugPrint('Doctor chat list: getConversations failed: $e');
      }

      final rows = model?.data ?? [];
      if (rows.isEmpty && doctorId.isNotEmpty) {
        try {
          final response = await _apiService.getDoctorChatHistory(doctorId);
          model = DoctorChatHistoryModel.fromResponse(response);
        } catch (e) {
          debugPrint('Doctor chat list: getDoctorChatHistory failed: $e');
        }
      }

      _chatHistory = model ?? DoctorChatHistoryModel(success: false, data: []);
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
      _chatHistory = DoctorChatHistoryModel(success: false, data: []);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistic UI: clear unread badge immediately when opening patient thread.
  void clearUnreadForPatient(int patientUserId) {
    final rows = _chatHistory?.data;
    if (rows == null || rows.isEmpty) return;
    final idx =
        rows.indexWhere((c) => int.tryParse(c.patient?.id ?? '') == patientUserId);
    if (idx < 0) return;
    final row = rows[idx];
    if ((row.unreadCount ?? 0) == 0) return;

    final list = List<DoctorChatHistoryData>.from(rows);
    list[idx] = DoctorChatHistoryData(
      patient: row.patient,
      lastMessage: row.lastMessage,
      lastMessageDate: row.lastMessageDate,
      unreadCount: 0,
    );
    _chatHistory = DoctorChatHistoryModel(success: true, data: list);
    notifyListeners();
  }

  Future<void> markThreadReadForPatient(int patientUserId) async {
    await _apiService.markChatConversationRead(patientUserId);
  }
}
