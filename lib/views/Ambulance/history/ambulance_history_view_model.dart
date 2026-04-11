import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/trip_fare_format.dart';
import 'package:intl/intl.dart';

class AmbulanceHistoryViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get trips => _trips;
  bool get isLoading => _isLoading;

  AmbulanceHistoryViewModel();

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getDriverTripHistory();
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          _trips = data.whereType<Map>().map<Map<String, dynamic>>((raw) {
            final trip = Map<String, dynamic>.from(raw);
            final at = trip['requestedAt'] ??
                trip['createdAt'] ??
                trip['completedAt'] ??
                trip['updatedAt'];
            final patient = trip['patient'];
            final patientName = trip['patientName']?.toString() ??
                (patient is Map
                    ? (patient['fullName'] ?? patient['name'])?.toString()
                    : null) ??
                'Unknown';

            return {
              ...trip,
              'tripNumber':
                  trip['tripNumber']?.toString() ?? '#${trip['id']}',
              'patientName': patientName,
              'date': _formatDate(at?.toString()),
              'time': _formatTime(at?.toString()),
              'status': trip['status']?.toString() ?? 'Unknown',
              'location': trip['pickupAddress']?.toString() ??
                  trip['pickup_address']?.toString() ??
                  'Pickup',
              'dropoffLabel': trip['dropoffAddress']?.toString() ??
                  trip['dropoff_address']?.toString(),
              'earnings': TripFareFormat.display(trip),
              'rawStatus': trip['status'],
            };
          }).toList();
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
