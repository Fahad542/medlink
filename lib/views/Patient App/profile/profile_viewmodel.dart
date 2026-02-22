import 'package:flutter/material.dart';

class ConsultationViewModel extends ChangeNotifier {
  // Logic for video/chat
}

class ProfileViewModel extends ChangeNotifier {
  // Logic for profile updates
  bool _notificationsEnabled = true;
  String _currentLanguage = "English";

  bool get notificationsEnabled => _notificationsEnabled;
  String get currentLanguage => _currentLanguage;

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void changeLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }
}
