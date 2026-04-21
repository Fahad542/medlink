import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/chat_message_model.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/services/chat_socket_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final ChatSocketService _socket = ChatSocketService.instance;
  final String doctorId;
  final String patientId;
  final String token;
  /// Logged-in user id (JWT); used to mark P2P thread read and resolve peer id.
  int? _currentUserId;
  String? appointmentId;
  String? sosId;
  String? tripId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => _messages;

  StreamSubscription<Map<String, dynamic>>? _newMsgSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  Timer? _typingDebounce;
  Timer? _typingHideTimer;
  bool _isPeerTyping = false;
  bool get isPeerTyping => _isPeerTyping;

  static String? _stringIdOrNull(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  ChatViewModel({
    required this.doctorId,
    required this.patientId,
    required this.token,
    this.appointmentId,
    Object? sosId,
    Object? tripId,
  })  : sosId = _stringIdOrNull(sosId),
        tripId = _stringIdOrNull(tripId) {
    _socket.connect(url: '${AppUrl.baseUrl}/chat', token: token);
    _newMsgSub = _socket.newMessageStream.listen(_handleNewMessage);
    _typingSub = _socket.typingStream.listen(_handleTypingEvent);
    _joinRoomIfPossible();
  }

  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
  }
  @override
  void dispose() {
    _newMsgSub?.cancel();
    _typingSub?.cancel();
    _typingDebounce?.cancel();
    _typingHideTimer?.cancel();
    if (appointmentId != null && appointmentId!.isNotEmpty) {
      _socket.leaveRoom(appointmentId!);
    }
    _socket.clearMissionChatContext();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      dynamic response;
      if (sosId != null && sosId!.isNotEmpty) {
        response = await _apiServices.getSosChatMessageHistory(sosId!);
      } else if (tripId != null && tripId!.isNotEmpty) {
        response = await _apiServices.getTripChatMessageHistory(tripId!);
      } else {
        response =
            await _apiServices.getUnifiedChatHistory(doctorId, patientId);
      }

      List<dynamic> messagesList = [];
      if (response is List) {
        messagesList = List<dynamic>.from(response);
      } else {
        final Map<String, dynamic>? payload =
            _normalizeApiDataEnvelope(response);
        if (payload != null) {
          final latest = payload['latestAppointmentId'];
          if (latest != null) {
            appointmentId = latest.toString();
          }
          if (payload['messages'] is List) {
            messagesList = List<dynamic>.from(payload['messages'] as List);
          }
        }
      }

      final bool shouldApplyMessages = response is List ||
          (response is Map && response['success'] == true);

      if (shouldApplyMessages) {
        final List<ChatMessageModel> fetchedMessages = [];
        for (final raw in messagesList) {
          if (raw is! Map) continue;
          try {
            fetchedMessages.add(
              ChatMessageModel.fromJson(Map<String, dynamic>.from(raw)),
            );
          } catch (e) {
            debugPrint('Skipping chat message parse error: $e');
          }
        }

        if ((appointmentId == null || appointmentId!.isEmpty) &&
            fetchedMessages.isNotEmpty &&
            fetchedMessages.any((m) => m.appointmentId != null)) {
          appointmentId = fetchedMessages
              .firstWhere((m) => m.appointmentId != null)
              .appointmentId
              .toString();
        }

        fetchedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        _messages = fetchedMessages;
        _joinRoomIfPossible();
      }
      if ((sosId == null || sosId!.isEmpty) &&
          (tripId == null || tripId!.isEmpty)) {
        unawaited(_markThreadRead());
      }
    } catch (e) {
      debugPrint("Error fetching unified chat history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _markThreadRead() async {
    if (_currentUserId == null) return;
    final d = int.tryParse(doctorId);
    final p = int.tryParse(patientId);
    if (d == null || p == null) return;
    final peerId = _currentUserId == d ? p : d;
    await _apiServices.markChatConversationRead(peerId);
  }

  Future<void> sendMessage(String body, String currentUserId,
      {File? file}) async {
    final Map<String, String> fields = {
      'messageType': file != null ? 'IMAGE' : 'TEXT',
      'body': body,
    };

    try {
      dynamic response;
      if (sosId != null && sosId!.isNotEmpty) {
        response = await _apiServices.sendSosChatMessage(sosId!, fields, file);
      } else if (tripId != null && tripId!.isNotEmpty) {
        response =
            await _apiServices.sendTripChatMessage(tripId!, fields, file);
      } else {
        final String recipientId =
            currentUserId == doctorId ? patientId : doctorId;
        response =
            await _apiServices.sendChatMessage(recipientId, fields, file);
      }

      final Map<String, dynamic>? msgMap = _parseSendMessageBody(response);
      if (msgMap != null) {
        final newMessage = ChatMessageModel.fromJson(msgMap);
        _insertIfNotExists(newMessage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  void onInputChanged(String text, String currentUserId) {
    final recipientId = _peerIdForCurrentUser(currentUserId);
    if (recipientId == null) return;

    if (text.trim().isEmpty) {
      _typingDebounce?.cancel();
      _socket.sendTyping(
        recipientId: recipientId,
        isTyping: false,
        appointmentId: appointmentId,
        sosId: sosId,
        tripId: tripId,
      );
      return;
    }

    _socket.sendTyping(
      recipientId: recipientId,
      isTyping: true,
      appointmentId: appointmentId,
      sosId: sosId,
      tripId: tripId,
    );

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 1200), () {
      _socket.sendTyping(
        recipientId: recipientId,
        isTyping: false,
        appointmentId: appointmentId,
        sosId: sosId,
        tripId: tripId,
      );
    });
  }

  String? _peerIdForCurrentUser(String currentUserId) {
    if (sosId != null && sosId!.isNotEmpty) return doctorId;
    if (tripId != null && tripId!.isNotEmpty) return doctorId;
    if (currentUserId == doctorId) return patientId;
    return doctorId;
  }

  void _joinRoomIfPossible() {
    if (sosId != null && sosId!.isNotEmpty) {
      _socket.joinSosRoom(sosId!);
    }
    if (tripId != null && tripId!.isNotEmpty) {
      _socket.joinTripRoom(tripId!);
    }
    if (appointmentId != null && appointmentId!.isNotEmpty) {
      _socket.joinRoom(appointmentId!);
    }
  }

  void _handleNewMessage(Map<String, dynamic> payload) {
    try {
      final Map<String, dynamic> msgJson = _unwrapSocketMessage(payload);

      final bool inSos = sosId != null && sosId!.isNotEmpty;
      final bool inTrip = tripId != null && tripId!.isNotEmpty;
      final bool inDm = !inSos && !inTrip;

      final String? incomingApptId = msgJson['appointmentId']?.toString();
      final String? incomingSosId = msgJson['sosId']?.toString();
      final String? incomingTripId = msgJson['tripId']?.toString();
      final dynamic senderId = msgJson['senderId'];

      bool isRelevant = false;

      if (inSos && incomingSosId == sosId) {
        isRelevant = true;
      }
      if (inTrip && incomingTripId == tripId) {
        isRelevant = true;
      }

      if (inDm) {
        final bool hasLocalAppt =
            appointmentId != null && appointmentId!.isNotEmpty;
        final bool hasPayloadAppt =
            incomingApptId != null && incomingApptId.isNotEmpty;

        if (hasPayloadAppt &&
            hasLocalAppt &&
            incomingApptId != appointmentId) {
          // Different appointment thread — ignore.
        } else if (hasLocalAppt && incomingApptId == appointmentId) {
          isRelevant = true;
        } else if (hasLocalAppt && !hasPayloadAppt) {
          if (_idMatchesUser(senderId, doctorId) ||
              _idMatchesUser(senderId, patientId)) {
            isRelevant = true;
          }
        } else if (!hasLocalAppt) {
          if (_idMatchesUser(senderId, doctorId) ||
              _idMatchesUser(senderId, patientId)) {
            isRelevant = true;
          }
        }
      }

      if (!isRelevant) return;

      final msg = ChatMessageModel.fromJson(msgJson);
      _insertIfNotExists(msg);
      notifyListeners();
      if (inDm && _currentUserId != null) {
        final d = int.tryParse(doctorId);
        final p = int.tryParse(patientId);
        final me = _currentUserId!;
        final peer = me == d ? p : d;
        if (peer != null && msg.senderId == peer) {
          // User is already inside thread, so any incoming peer message is read.
          unawaited(_markThreadRead());
        }
      }
    } catch (e) {
      debugPrint("Error handling real-time message: $e");
    }
  }

  void _handleTypingEvent(Map<String, dynamic> payload) {
    try {
      final data = _unwrapSocketMessage(payload);
      final sender = data['senderId']?.toString();
      final recipient = data['recipientId']?.toString();
      final me = _currentUserId?.toString();
      if (me == null || me.isEmpty) return;
      if (sender == null || sender == me) return;
      if (recipient != null && recipient != me) return;

      final d = int.tryParse(doctorId);
      final p = int.tryParse(patientId);
      if (d == null || p == null) return;
      final meInt = int.tryParse(me);
      if (meInt == null) return;
      final peerId = meInt == d ? p : d;
      if (sender != peerId.toString()) return;

      final inSos = sosId != null && sosId!.isNotEmpty;
      final inTrip = tripId != null && tripId!.isNotEmpty;
      final incomingSosId = data['sosId']?.toString();
      final incomingTripId = data['tripId']?.toString();
      final incomingApptId = data['appointmentId']?.toString();

      bool relevant = false;
      if (inSos) {
        relevant = incomingSosId == sosId;
      } else if (inTrip) {
        relevant = incomingTripId == tripId;
      } else if (appointmentId != null && appointmentId!.isNotEmpty) {
        // Accept both exact appointment match and fallback peer typing when
        // backend/client payload does not include appointment context.
        relevant = incomingApptId == appointmentId || incomingApptId == null;
      } else {
        relevant = sender == doctorId || sender == patientId;
      }
      if (!relevant) return;

      final typing = data['isTyping'] == true;
      if (_isPeerTyping != typing) {
        _isPeerTyping = typing;
        notifyListeners();
      }

      _typingHideTimer?.cancel();
      if (typing) {
        _typingHideTimer = Timer(const Duration(seconds: 2), () {
          if (_isPeerTyping) {
            _isPeerTyping = false;
            notifyListeners();
          }
        });
      }
    } catch (_) {}
  }

  /// Backend may emit `{ "message": { ... } }` or flat fields like the REST API.
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

  static bool _idMatchesUser(dynamic value, String userId) {
    if (userId.isEmpty) return false;
    final int? n = int.tryParse(userId);
    if (n != null && value == n) return true;
    return value?.toString() == userId;
  }

  /// Unwraps `{ success, data }`. If the controller also nested
  /// `{ success, data: { messages } }`, unwraps one more level.
  static Map<String, dynamic>? _normalizeApiDataEnvelope(dynamic response) {
    if (response is! Map) return null;
    final root = Map<String, dynamic>.from(response);
    if (root['success'] != true) return null;
    final raw = root['data'];
    if (raw is! Map) return null;
    final d = Map<String, dynamic>.from(raw);
    if (d['success'] == true && d['data'] is Map) {
      return Map<String, dynamic>.from(d['data'] as Map);
    }
    return d;
  }

  /// API may return `{ success, data }` or a raw message entity.
  static Map<String, dynamic>? _parseSendMessageBody(dynamic response) {
    if (response is! Map) return null;
    final map = Map<String, dynamic>.from(response);
    if (map['success'] == true && map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    if (map.containsKey('id') && map.containsKey('senderId')) {
      return map;
    }
    return null;
  }

  void _insertIfNotExists(ChatMessageModel msg) {
    final exists = _messages.any((m) => m.id == msg.id);
    if (exists) return;
    _messages.insert(0, msg);
  }
}
