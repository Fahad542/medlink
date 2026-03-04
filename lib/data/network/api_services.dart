import 'dart:convert';
import 'dart:io';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/network_api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for temporary register tokens (Step 2 verify-otp response).
const String _kPatientRegisterToken = 'patient_register_token';
const String _kDoctorRegisterToken = 'doctor_register_token';

class ApiServices {
  final _apiServices = NetworkApiService();

  // --- Auth & Patient Methods ---

  /// Patient registration Step 1: send OTP to phone. Body: {"phone": "+..."}
  Future<dynamic> patientSendOtp(String phone) async {
    try {
      return await _apiServices.getPostApiResponse(
        AppUrl.patient_register_step1,
        jsonEncode({'phone': phone}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Patient registration Step 2: verify OTP. Saves register_token to SharedPreferences.
  /// Body: {"phone": "+...", "otp": "..."}
  Future<dynamic> patientVerifyOtp(String phone, String otp) async {
    try {
      final response = await _apiServices.getPostApiResponse(
        AppUrl.patient_register_step2,
        jsonEncode({'phone': phone, 'otp': otp}),
      );
      final data = response is Map ? response['data'] : null;
      final token = data is Map ? data['register_token']?.toString() : null;
      if (token != null && token.isNotEmpty) {
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_kPatientRegisterToken, token);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Patient registration Step 3: register with form-data. Uses Bearer register_token from prefs.
  /// On success, does not clear register_token here; caller should save session then clear token.
  Future<dynamic> patientRegister(Map<String, String> formData, File? file) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final registerToken = sp.getString(_kPatientRegisterToken);
      if (registerToken == null || registerToken.isEmpty) {
        throw Exception('Register token expired. Please restart registration.');
      }
      final response = await _apiServices.getPostMultipartWithOptionalBearer(
        AppUrl.patient_register_step3,
        formData,
        file,
        bearerToken: registerToken,
        fileKey: 'profilePic',
      );
      await sp.remove(_kPatientRegisterToken);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // --- Doctor registration (3 steps: send-otp, verify-otp, register) ---

  /// Doctor registration Step 1: send OTP. Body: {"phone": "+..."}
  Future<dynamic> doctorSendOtp(String phone) async {
    try {
      return await _apiServices.getPostApiResponse(
        AppUrl.doctor_register_step1,
        jsonEncode({'phone': phone}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Doctor registration Step 2: verify OTP. Saves register_token to SharedPreferences.
  Future<dynamic> doctorVerifyOtp(String phone, String otp) async {
    try {
      final response = await _apiServices.getPostApiResponse(
        AppUrl.doctor_register_step2,
        jsonEncode({'phone': phone, 'otp': otp}),
      );
      final data = response is Map ? response['data'] : null;
      final token = data is Map ? data['register_token']?.toString() : null;
      if (token != null && token.isNotEmpty) {
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_kDoctorRegisterToken, token);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Doctor registration Step 3: register with form-data + profilePic + medicalLicenseDocument. Uses Bearer register_token.
  Future<dynamic> doctorRegister(
    Map<String, String> formData,
    File? profilePicFile,
    File? medicalLicenseFile,
  ) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final registerToken = sp.getString(_kDoctorRegisterToken);
      if (registerToken == null || registerToken.isEmpty) {
        throw Exception('Register token expired. Please restart registration.');
      }
      final response = await _apiServices.getPostMultipartWithBearerTwoFiles(
        AppUrl.doctor_register_step3,
        formData,
        profilePicFile,
        fileKey1: 'profilePic',
        file2: medicalLicenseFile,
        fileKey2: 'medicalLicenseDocument',
        bearerToken: registerToken,
      );
      await sp.remove(_kDoctorRegisterToken);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> loginApi(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.loginEndPint, jsonEncode(data));
    } catch (e) { rethrow; }
  }

  Future<dynamic> registerV1Step(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.registerstep1, jsonEncode(data));
    } catch (e) { rethrow; }
  }

  Future<dynamic> registerStep1(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.registerstep1, jsonEncode(data));
    } catch (e) { rethrow; }
  }

  Future<dynamic> registerStep2(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.registerstep2, jsonEncode(data));
    } catch (e) { rethrow; }
  }

  Future<dynamic> registerStep3(dynamic data, [File? file]) async {
    try {
      if (file != null) {
        return await _apiServices.getPostMultipartApiResponse(
            AppUrl.registerstep3, data, file, fileKey: 'profilePicture');
      } else {
        return await _apiServices.getPostApiResponse(AppUrl.registerstep3, jsonEncode(data));
      }
    } catch (e) { rethrow; }
  }

  Future<dynamic> registerStep6(dynamic data, [File? file]) async {
    try {
      return await _apiServices.getPostMultipartApiResponse(
          AppUrl.registerstep5, data, file, fileKey: 'profilePicture');
    } catch (e) { rethrow; }
  }

  Future<dynamic> registerApi(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.register, data);
    } catch (e) { rethrow; }
  }

  Future<dynamic> checkEmail(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.check_email, jsonEncode(data));
    } catch (e) { rethrow; }
  }

  Future<dynamic> verifyEmailOtp(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.verify_email, jsonEncode(data));
    } catch (e) { rethrow; }
  }

  Future<dynamic> getDoctors() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_doctors);
    } catch (e) { rethrow; }
  }

  Future<dynamic> getDoctorCategories() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_doctors_categories);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getAvailableDoctorsBySpecialty(int specialtyId) async {
    try {
      return await _apiServices.getGetApiResponse('${AppUrl.get_doctors_by_specialty}?specialtyId=$specialtyId');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_appointments);
    } catch (e) { rethrow; }
  }

  Future<dynamic> getPatientProfile() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_patient_profile);
    } catch (e) { rethrow; }
  }

  Future<dynamic> bookAppointment(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.book_appointments, jsonEncode(data));
    } catch (e) { rethrow; }
  }

  Future<dynamic> cancelAppointment(String appointmentId, String reason) async {
    try {
      final url = '${AppUrl.cancel_appointment}/$appointmentId/cancel';
      final payload = jsonEncode({"reason": reason});
      return await _apiServices.getPatchApiResponse(url, payload);
    } catch (e) { rethrow; }
  }


  Future<dynamic> getUpcomingAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_upcoming_appointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getCancelledAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_cancelled_appointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPastAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_past_appointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getHealthArticles() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_health_articles);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getPatientAppointments(String patientId, {String? status}) async {
    try {
      String url = '${AppUrl.get_appointments}/$patientId';
      if (status != null) {
        url += '?status=$status';
      }

      print("Fetching Patient Appointments from: $url");
      final response = await _apiServices.getGetApiResponse(url);
      
      if (response is List) {
        return response;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching appointments: $e");
      return [];
    }
  }

  // --- Doctor Specific Methods ---

  Future<dynamic> getDoctorPatients() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_doctor_patients);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getFirstAidTopics() async {
    try {
      print("Fetching First Aid Topics from: ${AppUrl.get_first_aid_topics}");
      return await _apiServices.getGetApiResponse(AppUrl.get_first_aid_topics);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorMonthlyEarnings(int year, int month) async {
    try {
      return await _apiServices.getGetApiResponse('${AppUrl.get_doctor_earnings_by_month}?year=$year&month=$month');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorBalance() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_doctor_balance);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorUpcomingAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_doctor_upcoming_appointments);
    } catch (e) {
      rethrow;
    }
  }
}
