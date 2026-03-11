import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';

class PrescriptionViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _prescriptions = [];
  List<dynamic> get prescriptions => _prescriptions;

  Future<void> fetchPrescriptions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.getPatientPrescriptions();
      if (response != null && response['success'] == true) {
        _prescriptions = response['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching prescriptions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadReport(String prescriptionId, String testId, File file, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiServices.uploadTestReport(prescriptionId, testId, file);
      if (response != null && response['success'] == true) {
        Utils.toastMessage(context, "Report uploaded successfully");
        await fetchPrescriptions(); // Refresh list
        return true;
      }
      return false;
    } catch (e) {
      Utils.toastMessage(context, e.toString(), isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
