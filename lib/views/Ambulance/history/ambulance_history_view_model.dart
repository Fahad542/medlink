import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:intl/intl.dart';

class AmbulanceHistoryViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get trips => _trips;
  bool get isLoading => _isLoading;

  AmbulanceHistoryViewModel() {
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getDriverTripHistory();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _trips = List<Map<String, dynamic>>.from(data.map((trip) {
            return {
              "id": trip['id'],
              "tripNumber": trip['tripNumber'] ?? '#${trip['id']}',
              "patientName": trip['patientName'] ?? 'Unknown',
              "date": _formatDate(trip['requestedAt']),
              "time": _formatTime(trip['requestedAt']),
              "status": trip['status'] ?? 'Unknown',
              "location": trip['pickupAddress'] ?? 'Pickup',
              "earnings": trip['fareAmount'] != null
                  ? '${trip['currency'] ?? 'CFA'} ${trip['fareAmount']}'
                  : '—',
              "currency": trip['currency'] ?? 'CFA',
              "rawStatus": trip['status'] // For logic checks
            };
          }));
        }
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }
}
