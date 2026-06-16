import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/chat_history_model.dart';
import 'package:medlink/services/chat_socket_service.dart';
import 'package:medlink/views/services/session_view_model.dart';

class ChatListViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final UserViewModel _userViewModel;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ChatHistoryModel> _chatHistory = [];
  List<ChatHistoryModel> get chatHistory => _chatHistory;

  /// Ignores duplicate `chat:newMessage` deliveries (same id or same payload fingerprint).
  final Set<String> _seenSocketKeys = {};

  ChatListViewModel(this._userViewModel) {
    fetchChatHistory();
    _subscribeSocket();
  }

  int? get _myUserId =>
      _userViewModel.loginSession?.data?.user?.id ??
      int.tryParse(_userViewModel.patient?.id ?? '');

  void _subscribeSocket() {
    final token = _userViewModel.accessToken;
    if (token == null || token.isEmpty) return;
    ChatSocketService.instance
        .connect(url: '${AppUrl.baseUrl}/chat', token: token);
    _socketSub?.cancel();
    _socketSub =
        ChatSocketService.instance.newMessageStream.listen(_onSocketMessage);
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

  /// Returns false if this socket event was already applied (duplicate emit).
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

      final int? peerDoctorId =
          senderId == myId ? recipientId : senderId;
      if (peerDoctorId == null) {
        fetchChatHistory();
        return;
      }

      final type = msg['messageType']?.toString() ?? 'TEXT';
      final preview =
          type == 'IMAGE' ? '📷 Photo' : (msg['body']?.toString() ?? '');
      DateTime sentAt;
      try {
        sentAt = DateTime.parse(msg['sentAt'].toString()).toLocal();
      } catch (_) {
        sentAt = DateTime.now();
      }

      final idx = _chatHistory.indexWhere((c) => c.doctor.id == peerDoctorId);
      if (idx < 0) {
        fetchChatHistory();
        return;
      }

      final row = _chatHistory[idx];
      final fromPeer = senderId != myId;
      final nextUnread = fromPeer
          ? (row.unreadCount) + 1
          : 0;
      final updated = row.copyWith(
        lastMessage: preview.isEmpty ? row.lastMessage : preview,
        lastMessageDate: sentAt,
        unreadCount: nextUnread,
      );
      final list = List<ChatHistoryModel>.from(_chatHistory);
      list[idx] = updated;
      list.sort((a, b) => b.lastMessageDate.compareTo(a.lastMessageDate));
      _chatHistory = list;
      notifyListeners();
    } catch (e, st) {
      debugPrint('ChatListViewModel socket: $e $st');
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  Future<void> fetchChatHistory() async {
    _isLoading = true;
    notifyListeners();

    if (_socketSub == null &&
        (_userViewModel.accessToken?.isNotEmpty ?? false)) {
      _subscribeSocket();
    }

    try {
      final response = await _apiServices.getConversations();
      _chatHistory = ChatHistoryModel.fromConversationsApi(response);
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Support for RefreshIndicator
  Future<void> onRefresh() => fetchChatHistory();

  /// Optimistic UI: clear unread badge immediately when user opens the thread.
  void clearUnreadForDoctor(int doctorUserId) {
    final idx = _chatHistory.indexWhere((c) => c.doctor.id == doctorUserId);
    if (idx < 0) return;
    final row = _chatHistory[idx];
    if (row.unreadCount == 0) return;
    final list = List<ChatHistoryModel>.from(_chatHistory);
    list[idx] = row.copyWith(unreadCount: 0);
    _chatHistory = list;
    notifyListeners();
  }

  /// Mark thread read on server as soon as user opens chat.
  Future<void> markThreadReadForDoctor(int doctorUserId) async {
    await _apiServices.markChatConversationRead(doctorUserId);
  }
}
