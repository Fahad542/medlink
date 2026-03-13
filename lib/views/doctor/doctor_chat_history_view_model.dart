import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/doctor_chat_history_model.dart';

class DoctorChatHistoryViewModel extends ChangeNotifier {
  final _apiService = ApiServices();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DoctorChatHistoryModel? _chatHistory;
  DoctorChatHistoryModel? get chatHistory => _chatHistory;

  Future<void> fetchChatHistory(String doctorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getDoctorChatHistory(doctorId);
      _chatHistory = DoctorChatHistoryModel.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching chat history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
