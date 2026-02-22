import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorEarningsViewModel extends ChangeNotifier {
  double _balance = 2450.50;
  List<Map<String, dynamic>> _transactions = [];

  DoctorEarningsViewModel() {
    _loadTransactions();
  }

  double get balance => _balance;
  List<Map<String, dynamic>> get transactions => _transactions;

  void _loadTransactions() {
    // Mock transactions
    _transactions = List.generate(5, (index) => {
      'type': 'Consultation',
      'user': 'Patient ${index + 1}',
      'date': DateTime.now().subtract(Duration(days: index)),
      'amount': 50.00,
      'isCredit': true,
    });
    notifyListeners();
  }

  void withdrawFunds() {
    // Mock withdraw logic
    _balance = 0;
    notifyListeners();
  }

  String formatCurrency(double amount) {
    return NumberFormat.simpleCurrency().format(amount);
  }

  String formatDate(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date);
  }
}
