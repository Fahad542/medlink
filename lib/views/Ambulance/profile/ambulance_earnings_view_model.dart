import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';

class AmbulanceEarningsViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  num _totalBalance = 0;
  num _earningsToday = 0;
  num _earningsThisWeek = 0;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingTransactions = false;
  String? _maskedPayoutCard;
  bool _hasPayoutAccount = false;

  bool get isLoading => _isLoading;
  bool get isLoadingTransactions => _isLoadingTransactions;
  List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);
  String? get maskedPayoutCard => _maskedPayoutCard;
  bool get hasPayoutAccount => _hasPayoutAccount;

  String get totalBalanceFormatted => _formatAmount(_totalBalance);
  String get earningsTodayFormatted => _formatAmount(_earningsToday);
  String get earningsThisWeekFormatted => _formatAmount(_earningsThisWeek);

  AmbulanceEarningsViewModel() {
    fetchEarningsSummary();
  }

  String _formatAmount(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  Future<void> fetchEarningsSummary() async {
    _isLoading = true;
    _isLoadingTransactions = true;
    notifyListeners();
    try {
      await Future.wait([
        _fetchSummary(),
        _fetchTransactions(),
        _fetchPayoutAccount(),
      ]);
    } finally {
      _isLoading = false;
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  Future<void> _fetchSummary() async {
    try {
      final response = await _apiServices.getDriverEarningsSummary();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          final balance = data['totalBalance'];
          _totalBalance = balance is num ? balance : (num.tryParse(balance?.toString() ?? '0') ?? 0);
          final today = data['earningsToday'];
          _earningsToday = today is num ? today : (num.tryParse(today?.toString() ?? '0') ?? 0);
          final week = data['earningsThisWeek'];
          _earningsThisWeek = week is num ? week : (num.tryParse(week?.toString() ?? '0') ?? 0);
        }
      }
    } catch (e) {
      debugPrint('AmbulanceEarningsViewModel _fetchSummary error: $e');
    }
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await _apiServices.getDriverEarningsTransactions(limit: 20, offset: 0);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _transactions = data
              .map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          _transactions = [];
        }
      } else {
        _transactions = [];
      }
    } catch (e) {
      debugPrint('AmbulanceEarningsViewModel _fetchTransactions error: $e');
      _transactions = [];
    }
  }

  Future<void> _fetchPayoutAccount() async {
    try {
      final response = await _apiServices.getDriverPayoutAccount();
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
      debugPrint('AmbulanceEarningsViewModel _fetchPayoutAccount error: $e');
      _maskedPayoutCard = null;
      _hasPayoutAccount = false;
    }
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
          await _apiServices.requestDriverWithdrawal(amount: amount, note: note);
      return response != null && response['success'] == true;
    } catch (e) {
      debugPrint('AmbulanceEarningsViewModel requestWithdrawal error: $e');
      return false;
    }
  }
}
