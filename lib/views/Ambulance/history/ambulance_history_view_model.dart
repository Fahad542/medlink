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
              'paymentMethodLabel': _paymentMethodLabel(trip),
              'paidAtLabel': _paidAtLabel(trip),
              'rawStatus': trip['status'],
            };
          }).toList();
          await _enrichTripsForPaymentMeta();
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
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  String _paymentMethodLabel(Map<String, dynamic> trip) {
    final payment = trip['payment'];
    final raw = trip['paymentMethod'] ??
        trip['payment_method'] ??
        trip['method'] ??
        (payment is Map ? payment['method'] : null) ??
        (payment is Map ? payment['type'] : null);

    if (raw == null) return '—';
    final value = raw.toString().trim();
    if (value.isEmpty) return '—';

    final normalized = value.toLowerCase();
    if (normalized.contains('cash')) return 'Cash';
    if (normalized.contains('card')) return 'Card';
    if (normalized.contains('online')) return 'Online';
    if (normalized.contains('wallet')) return 'Wallet';

    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _paidAtLabel(Map<String, dynamic> trip) {
    final payment = trip['payment'];
    final paidAtRaw = trip['paidAt'] ??
        trip['paid_at'] ??
        trip['paymentCompletedAt'] ??
        trip['payment_completed_at'] ??
        (payment is Map ? payment['paidAt'] : null) ??
        (payment is Map ? payment['paid_at'] : null) ??
        (payment is Map ? payment['completedAt'] : null);

    if (paidAtRaw == null) return '—';
    final value = paidAtRaw.toString();
    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return value;
    }
  }

  Future<void> _enrichTripsForPaymentMeta() async {
    final indicesToFetch = <int>[];
    for (var i = 0; i < _trips.length; i++) {
      final trip = _trips[i];
      final needsPaymentMethod = (trip['paymentMethodLabel']?.toString() ?? '—') == '—';
      final needsPaidAt = (trip['paidAtLabel']?.toString() ?? '—') == '—';
      if (needsPaymentMethod || needsPaidAt) {
        final id = trip['id'];
        if (id != null) indicesToFetch.add(i);
      }
    }

    if (indicesToFetch.isEmpty) return;

    final updatedTrips = List<Map<String, dynamic>>.from(_trips);

    await Future.wait(indicesToFetch.map((index) async {
      final trip = updatedTrips[index];
      final tripId = trip['id']?.toString();
      if (tripId == null || tripId.isEmpty) return;

      try {
        final response = await _apiServices.getDriverTripDetails(tripId);
        if (response is! Map || response['success'] != true) return;
        final data = response['data'];
        if (data is! Map) return;

        final details = Map<String, dynamic>.from(data);
        final merged = <String, dynamic>{...trip, ...details};

        updatedTrips[index] = {
          ...merged,
          'paymentMethodLabel': _paymentMethodLabel(merged),
          'paidAtLabel': _paidAtLabel(merged),
        };
      } catch (_) {
        // Keep list responsive even if one detail request fails.
      }
    }));

    _trips = updatedTrips;
  }
}
