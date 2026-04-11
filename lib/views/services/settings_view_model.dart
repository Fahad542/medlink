import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel with ChangeNotifier {
  final ApiServices _apiServices = ApiServices();
  String _currency = 'CFA';

  String get currency => _currency;

  SettingsViewModel() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final sp = await SharedPreferences.getInstance();
    _currency = sp.getString('app_currency') ?? 'CFA';
    notifyListeners();
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    try {
      final response = await _apiServices.getSystemSettings();
      if (response != null && response['success'] == true) {
        final data = response['settings'];
        if (data != null && data['currency'] != null) {
          _currency = data['currency'];
          final sp = await SharedPreferences.getInstance();
          await sp.setString('app_currency', _currency);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching system settings: $e');
    }
  }
}
