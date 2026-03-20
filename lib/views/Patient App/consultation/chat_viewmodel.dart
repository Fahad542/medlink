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
  String? appointmentId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => _messages;

  StreamSubscription<Map<String, dynamic>>? _newMsgSub;

  ChatViewModel({
    required this.doctorId,
    required this.patientId,
    required this.token,
    this.appointmentId,
  }) {
    _socket.connect(url: '${AppUrl.baseUrl}/chat', token: token);
    _newMsgSub = _socket.newMessageStream.listen(_handleNewMessage);
    _joinRoomIfPossible();
  }

  @override
  void dispose() {
    _newMsgSub?.cancel();
    if (appointmentId != null && appointmentId!.isNotEmpty) {
      _socket.leaveRoom(appointmentId!);
    }
    super.dispose();
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response =
          await _apiServices.getUnifiedChatHistory(doctorId, patientId);
      if (response != null && response['success'] == true) {
        final data = response['data'];

        // The data has a 'messages' list according to the screenshot
        final List<dynamic> messagesList =
            (data is Map && data.containsKey('messages'))
                ? data['messages']
                : (data is List ? data : []);

        final List<ChatMessageModel> fetchedMessages = messagesList
            .map((json) => ChatMessageModel.fromJson(json))
            .toList();

        // If appointmentId is missing, try to get it from the latest message
        if ((appointmentId == null || appointmentId!.isEmpty) &&
            fetchedMessages.isNotEmpty) {
          appointmentId = fetchedMessages.first.appointmentId.toString();
        }

        fetchedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        _messages = fetchedMessages;
        _joinRoomIfPossible();
      }
    } catch (e) {
      debugPrint("Error fetching unified chat history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String body, String currentUserId,
      {File? file}) async {
    final String recipientId = currentUserId == doctorId ? patientId : doctorId;

    final Map<String, String> fields = {
      'messageType': file != null ? 'IMAGE' : 'TEXT',
      'body': body,
    };

    try {
      final response =
          await _apiServices.sendChatMessage(recipientId, fields, file);
      if (response != null && response['success'] == true) {
        final newMessage = ChatMessageModel.fromJson(response['data']);
        _insertIfNotExists(newMessage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  void _joinRoomIfPossible() {
    if (appointmentId == null || appointmentId!.isEmpty) return;
    _socket.joinRoom(appointmentId!);
  }

  void _handleNewMessage(Map<String, dynamic> payload) {
    try {
      if (appointmentId == null || appointmentId!.isEmpty) return;
      if (payload['appointmentId']?.toString() != appointmentId) return;
      final msg = ChatMessageModel.fromJson(payload);
      _insertIfNotExists(msg);
      notifyListeners();
    } catch (_) {}
  }

  void _insertIfNotExists(ChatMessageModel msg) {
    final exists = _messages.any((m) => m.id == msg.id);
    if (exists) return;
    _messages.insert(0, msg);
  }
}
