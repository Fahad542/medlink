import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/chat_history_model.dart';
import 'package:medlink/views/services/session_view_model.dart';

class ChatListViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  final UserViewModel _userViewModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ChatHistoryModel> _chatHistory = [];
  List<ChatHistoryModel> get chatHistory => _chatHistory;

  ChatListViewModel(this._userViewModel) {
    fetchChatHistory();
  }

  Future<void> fetchChatHistory() async {
    final patientId = _userViewModel.patient?.id;
    if (patientId == null) {
      debugPrint("No patient ID found in Session");
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getChatHistory(patientId);
      
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _chatHistory = data.map((json) => ChatHistoryModel.fromJson(json)).toList();
      } else {
        _chatHistory = [];
      }
      
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Support for RefreshIndicator
  Future<void> onRefresh() => fetchChatHistory();
}
