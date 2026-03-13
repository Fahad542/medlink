import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/models/prescription_detail_model.dart';

class PrescriptionDetailViewModel extends ChangeNotifier {
  final _apiService = ApiServices();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  PrescriptionDetailData? _details;
  PrescriptionDetailData? get details => _details;

  Future<void> fetchPrescriptionDetails(String appointmentId) async {
    _isLoading = true;
    _details = null;
    notifyListeners();

    try {
      final response = await _apiService.getPrescriptionDetails(appointmentId);
      final model = PrescriptionDetailModel.fromJson(response);
      if (model.success == true) {
        _details = model.data;
      }
    } catch (e) {
      print("Error fetching prescription details: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
