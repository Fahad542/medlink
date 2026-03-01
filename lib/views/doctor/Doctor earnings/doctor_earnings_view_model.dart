import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlink/data/network/api_services.dart';

class DoctorEarningsViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  double _totalBalance = 0.0;
  double _todayEarning = 0.0;
  double _thisWeekEarning = 0.0;
  String _currency = "PKR";
  List<dynamic> _recentTransactions = [];

  DoctorEarningsViewModel() {
    fetchBalance();
  }

  bool get isLoading => _isLoading;
  double get totalBalance => _totalBalance;
  double get todayEarning => _todayEarning;
  double get thisWeekEarning => _thisWeekEarning;
  String get currency => _currency;
  List<dynamic> get recentTransactions => _recentTransactions;

  Future<void> fetchBalance() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getDoctorBalance();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          _totalBalance = (data['totalBalance'] ?? 0).toDouble();
          _todayEarning = (data['todayEarning'] ?? 0).toDouble();
          _thisWeekEarning = (data['thisWeekEarning'] ?? 0).toDouble();
          _currency = data['currency'] ?? "PKR";
          _recentTransactions = data['recentTransactions'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctor balance: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void withdrawFunds() {
    // Mock withdraw logic
    _totalBalance = 0;
    notifyListeners();
  }

  String formatCurrency(double amount) {
    return '$_currency ${NumberFormat('#,##0.00').format(amount)}';
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM d, h:mm a').format(date);
    } catch(e) {
       return dateString;
    }
  }
}
