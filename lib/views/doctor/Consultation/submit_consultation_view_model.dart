import 'package:flutter/material.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';

import 'package:medlink/models/appointment_model.dart';

class SubmitConsultationViewModel extends ChangeNotifier {
  final ApiServices _apiServices = ApiServices();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void populateFromAppointment(AppointmentModel appointment) {
    if (appointment.status == AppointmentStatus.completed ||
        appointment.prescription != null) {
      // Notes & Diagnosis
      chiefComplaintController.text = appointment.prescription?.notes ?? '';
      provisionalDiagnosisController.text =
          appointment.prescription?.diagnosis ?? '';

      // Vitals
      if (appointment.vitals != null) {
        bpSystolicController.text =
            appointment.vitals!['bpSystolic']?.toString() ?? '';
        bpDiastolicController.text =
            appointment.vitals!['bpDiastolic']?.toString() ?? '';
        pulseController.text =
            appointment.vitals!['heartRate']?.toString() ?? '';
        temperatureController.text =
            appointment.vitals!['temperatureC']?.toString() ?? '';
        weightController.text =
            appointment.vitals!['weightKg']?.toString() ?? '';
      }

      // Medications
      if (appointment.prescription?.items != null) {
        medications = appointment.prescription!.items!
            .map((item) => {
                  "medicineName": item['medicineName']?.toString() ?? '',
                  "dosage": item['dosage']?.toString() ?? '',
                  "frequency": item['frequency']?.toString() ?? '',
                })
            .toList();
      }

      // Tests
      if (appointment.prescription?.tests != null) {
        tests = appointment.prescription!.tests!
            .map((test) => {
                  "testName": test['testName']?.toString() ?? '',
                  "notes": test['notes']?.toString() ?? '',
                })
            .toList();
      }
      notifyListeners();
    }
  }

  // Diagnosis
  final TextEditingController chiefComplaintController =
      TextEditingController();
  final TextEditingController provisionalDiagnosisController =
      TextEditingController();

  // Vitals
  final TextEditingController bpSystolicController = TextEditingController();
  final TextEditingController bpDiastolicController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();
  final TextEditingController temperatureController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  // Medications
  List<Map<String, String>> medications = [];
  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();

  // Tests
  List<Map<String, String>> tests = [];
  final TextEditingController testNameController = TextEditingController();
  final TextEditingController testNotesController = TextEditingController();

  void addMedication() {
    if (medicineNameController.text.isNotEmpty) {
      medications.add({
        "medicineName": medicineNameController.text.trim(),
        "dosage": dosageController.text.trim(),
        "frequency": frequencyController.text.trim(),
      });
      medicineNameController.clear();
      dosageController.clear();
      frequencyController.clear();
      notifyListeners();
    }
  }

  void removeMedication(int index) {
    medications.removeAt(index);
    notifyListeners();
  }

  void addTest() {
    if (testNameController.text.isNotEmpty) {
      tests.add({
        "testName": testNameController.text.trim(),
        "notes": testNotesController.text.trim(),
      });
      testNameController.clear();
      testNotesController.clear();
      notifyListeners();
    }
  }

  void removeTest(int index) {
    tests.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitConsultation(
      BuildContext context, String appointmentId) async {
    if (chiefComplaintController.text.isEmpty ||
        provisionalDiagnosisController.text.isEmpty) {
      Utils.toastMessage(context, "Please fill diagnosis details",
          isError: true);
      return false;
    }

    // AUTO-ADD: If user typed a medicine/test but forgot to click the small 'Add' button
    if (medicineNameController.text.isNotEmpty) {
      addMedication();
    }
    if (testNameController.text.isNotEmpty) {
      addTest();
    }

    _isLoading = true;
    notifyListeners();

    try {
      final bpSystolic = int.tryParse(bpSystolicController.text.trim());
      final bpDiastolic = int.tryParse(bpDiastolicController.text.trim());
      final pulse = int.tryParse(pulseController.text.trim());
      final temperature = double.tryParse(temperatureController.text.trim());
      final weight = double.tryParse(weightController.text.trim());

      final vitalsValidationError = _validateVitals(
        bpSystolic: bpSystolic,
        bpDiastolic: bpDiastolic,
        pulse: pulse,
        temperatureC: temperature,
        weightKg: weight,
      );
      if (vitalsValidationError != null) {
        Utils.toastMessage(context, vitalsValidationError, isError: true);
        return false;
      }

      final Map<String, dynamic> data = {
        "chiefComplaint": chiefComplaintController.text.trim(),
        "provisionalDiagnosis": provisionalDiagnosisController.text.trim(),
        "vitals": {
          "bpSystolic": bpSystolic,
          "bpDiastolic": bpDiastolic,
          "pulse": pulse,
          "temperatureC": temperature,
          "weightKg": weight,
        },
        "tests": tests,
        "medications": medications,
      };

      final response =
          await _apiServices.submitConsultation(appointmentId, data);

      if (response != null && response['success'] == true) {
        Utils.toastMessage(context, "Consultation submitted successfully");
        return true;
      }
      return false;
    } catch (e) {
      Utils.toastError(context, e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _validateVitals({
    int? bpSystolic,
    int? bpDiastolic,
    int? pulse,
    double? temperatureC,
    double? weightKg,
  }) {
    final errors = <String>[];

    if (bpSystolic != null && (bpSystolic < 50 || bpSystolic > 250)) {
      errors.add('Systolic BP must be between 50 and 250');
    }
    if (bpDiastolic != null && (bpDiastolic < 30 || bpDiastolic > 160)) {
      errors.add('Diastolic BP must be between 30 and 160');
    }
    if (pulse != null && (pulse < 30 || pulse > 250)) {
      errors.add('Pulse must be between 30 and 250');
    }
    if (temperatureC != null && (temperatureC < 25 || temperatureC > 115)) {
      errors.add('Temperature must be between 25 and 115');
    }
    if (weightKg != null && (weightKg < 1 || weightKg > 500)) {
      errors.add('Weight must be between 1 and 500');
    }

    if (errors.isEmpty) return null;
    return errors.join(', ');
  }

  @override
  void dispose() {
    chiefComplaintController.dispose();
    provisionalDiagnosisController.dispose();
    bpSystolicController.dispose();
    bpDiastolicController.dispose();
    pulseController.dispose();
    temperatureController.dispose();
    weightController.dispose();
    medicineNameController.dispose();
    dosageController.dispose();
    frequencyController.dispose();
    testNameController.dispose();
    testNotesController.dispose();
    super.dispose();
  }
}
