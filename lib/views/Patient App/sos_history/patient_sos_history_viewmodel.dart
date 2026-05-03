import 'package:flutter/foundation.dart';
import 'package:medlink/data/network/api_services.dart';

/// Parses `GET /patient/sos` — same shapes as [EmergencyViewModel] (`success.data` or raw list).
List<Map<String, dynamic>> parsePatientSosListResponse(dynamic response) {
  if (response == null) return [];
  if (response is List) {
    return response
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (response is Map) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  return [];
}

class PatientSosHistoryViewModel extends ChangeNotifier {
  PatientSosHistoryViewModel({ApiServices? api})
      : _api = api ?? ApiServices();

  final ApiServices _api;

  bool _loading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _items = [];

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  Future<void> refresh() => load();

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.getMySos();
      if (response is Map && response['success'] == false) {
        _items = [];
        _errorMessage =
            response['message']?.toString() ?? 'Could not load emergency history';
      } else {
        _items = parsePatientSosListResponse(response);
      }
    } catch (e) {
      _items = [];
      _errorMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
