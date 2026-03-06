import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/chat_message_model.dart';

class ChatViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final String appointmentId;
  final int currentUserId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ChatMessageModel> _messages = [];
  List<ChatMessageModel> get messages => _messages;

  ChatViewModel({required this.appointmentId, required this.currentUserId}) {
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getChatMessages(appointmentId);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        final List<dynamic> messagesList =
            (data is Map && data.containsKey('messages'))
                ? data['messages']
                : (data is List ? data : []);

        final List<ChatMessageModel> fetchedMessages = messagesList
            .map((json) => ChatMessageModel.fromJson(json))
            .toList();

        // Sort messages by sentAt in descending order (newest first)
        // since we use reverse: true in ListView.builder
        fetchedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        _messages = fetchedMessages;
      }
    } catch (e) {
      debugPrint("Error fetching chat messages: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String body, {File? file}) async {
    final Map<String, String> fields = {
      'messageType': file != null ? 'IMAGE' : 'TEXT',
      'body': body,
    };

    try {
      final response =
          await _apiServices.sendChatMessage(appointmentId, fields, file);
      if (response != null && response['success'] == true) {
        // Optimistically add message or re-fetch
        final newMessage = ChatMessageModel.fromJson(response['data']);
        _messages.insert(
            0, newMessage); // Assuming new messages at top for list
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }
}
