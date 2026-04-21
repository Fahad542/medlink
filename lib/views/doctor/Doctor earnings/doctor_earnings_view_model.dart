import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medlink/data/network/api_services.dart';

class DoctorEarningsViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  double _totalBalance = 0.0;
  /// Max amount allowed for a new withdrawal request (excludes pending/processing).
  double _availableToWithdraw = 0.0;
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
  double get availableToWithdraw => _availableToWithdraw;
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
          final atw = data['availableToWithdraw'];
          if (atw != null) {
            _availableToWithdraw = (atw is num)
                ? atw.toDouble()
                : double.tryParse(atw.toString()) ?? _totalBalance;
          } else {
            _availableToWithdraw = _totalBalance;
          }
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

  /// Backend may send `user` as a string, nested `patient`, or alternate keys.
  String transactionUserDisplayName(Map<String, dynamic> m) {
    for (final key in [
      'user',
      'patientName',
      'userName',
      'memberName',
      'customerName',
    ]) {
      final v = m[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v != null && v is! Map && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    for (final nestedKey in ['patient', 'patientUser', 'member']) {
      final raw = m[nestedKey];
      if (raw is Map) {
        final p = Map<String, dynamic>.from(raw);
        for (final key in ['name', 'fullName', 'full_name', 'displayName']) {
          final v = p[key];
          if (v != null && v.toString().trim().isNotEmpty) {
            return v.toString().trim();
          }
        }
      }
    }
    final appointment = m['appointment'];
    if (appointment is Map) {
      final a = Map<String, dynamic>.from(appointment);
      final inner = a['patient'] ?? a['user'];
      if (inner is Map) {
        final p = Map<String, dynamic>.from(inner);
        for (final key in ['name', 'fullName', 'full_name']) {
          final v = p[key];
          if (v != null && v.toString().trim().isNotEmpty) {
            return v.toString().trim();
          }
        }
      }
    }
    final userObj = m['user'];
    if (userObj is Map) {
      final u = Map<String, dynamic>.from(userObj);
      for (final key in ['name', 'fullName', 'full_name']) {
        final v = u[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
    }
    return 'Unknown User';
  }
}
