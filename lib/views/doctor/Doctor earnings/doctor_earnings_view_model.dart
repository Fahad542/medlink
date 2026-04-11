import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlink/data/network/api_services.dart';

class DoctorEarningsViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  double _totalBalance = 0.0;
  double _todayEarning = 0.0;
  double _thisWeekEarning = 0.0;
  String _currency = "CFA";
  List<dynamic> _recentTransactions = [];
  String? _maskedPayoutCard;
  bool _hasPayoutAccount = false;

  DoctorEarningsViewModel() {
    fetchBalance();
  }

  bool get isLoading => _isLoading;
  double get totalBalance => _totalBalance;
  double get todayEarning => _todayEarning;
  double get thisWeekEarning => _thisWeekEarning;
  String get currency => _currency;
  List<dynamic> get recentTransactions => _recentTransactions;
  String? get maskedPayoutCard => _maskedPayoutCard;
  bool get hasPayoutAccount => _hasPayoutAccount;

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
          _currency = data['currency'] ?? "CFA";
          _recentTransactions = data['recentTransactions'] ?? [];
        }
      }
      await fetchPayoutAccount();
    } catch (e) {
      debugPrint("Error fetching doctor balance: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayoutAccount() async {
    try {
      final response = await _apiServices.getDoctorPayoutAccount();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        final masked = _extractMaskedCard(data);
        if (masked != null && masked.isNotEmpty) {
          _maskedPayoutCard = masked;
          _hasPayoutAccount = true;
        } else {
          _maskedPayoutCard = null;
          _hasPayoutAccount = false;
        }
      }
    } catch (e) {
      debugPrint("Error fetching doctor payout account: $e");
      _maskedPayoutCard = null;
      _hasPayoutAccount = false;
    }
    notifyListeners();
  }

  String? _extractMaskedCard(dynamic data) {
    if (data is! Map) return null;
    final payload = data['payoutAccount'] is Map ? data['payoutAccount'] : data;
    if (payload is! Map) return null;

    final masked = (payload['maskedCardNumber'] ?? payload['cardNumberMasked'])
        ?.toString()
        .trim();
    if (masked != null && masked.isNotEmpty) return masked;

    final last4 = payload['cardLast4']?.toString().trim();
    if (last4 != null && last4.isNotEmpty) {
      return "**** **** **** $last4";
    }
    return null;
  }

  Future<bool> requestWithdrawal({
    required double amount,
    String? note,
  }) async {
    try {
      final response =
          await _apiServices.requestDoctorWithdrawal(amount: amount, note: note);
      return response != null && response['success'] == true;
    } catch (e) {
      debugPrint("Error requesting doctor withdrawal: $e");
      return false;
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
