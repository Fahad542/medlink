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
        AppUrl.patientRegisterStep1,
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
        AppUrl.patientRegisterStep2,
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
  Future<dynamic> patientRegister(
      Map<String, String> formData, File? file) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final registerToken = sp.getString(_kPatientRegisterToken);
      if (registerToken == null || registerToken.isEmpty) {
        throw Exception('Register token expired. Please restart registration.');
      }
      final response = await _apiServices.getPostMultipartWithOptionalBearer(
        AppUrl.patientRegisterStep3,
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
        AppUrl.doctorRegisterStep1,
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
        AppUrl.doctorRegisterStep2,
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
        AppUrl.doctorRegisterStep3,
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
      return await _apiServices.getPostApiResponse(
          AppUrl.loginEndPoint, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> registerV1Step(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.registerStep1, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> registerStep1(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.registerStep1, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> registerStep2(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.registerStep2, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> registerStep3(dynamic data, [File? file]) async {
    try {
      if (file != null) {
        return await _apiServices.getPostMultipartApiResponse(
            AppUrl.registerStep3, data, file,
            fileKey: 'profilePicture');
      } else {
        return await _apiServices.getPostApiResponse(
            AppUrl.registerStep3, jsonEncode(data));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> registerStep6(dynamic data, [File? file]) async {
    try {
      return await _apiServices.getPostMultipartApiResponse(
          AppUrl.registerStep5, data, file,
          fileKey: 'profilePicture');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> registerApi(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.register, data);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> checkEmail(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.checkEmail, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> verifyEmailOtp(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.verifyEmail, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctors() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getDoctors);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorCategories() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getDoctorsCategories);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getAvailableDoctorsBySpecialty({String? specialtyId}) async {
    try {
      String url = AppUrl.getDoctorsBySpecialty;
      if (specialtyId != null && specialtyId.isNotEmpty) {
        url += "?specialtyId=$specialtyId";
      }
      return await _apiServices.getGetApiResponse(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getAppointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPatientProfile() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getPatientProfile);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorProfile() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getDoctorProfile);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> bookAppointment(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.bookAppointments, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updatePatientProfile(
      Map<String, String> formData, File? file) async {
    try {
      return await _apiServices.getPatchMultipartApiResponse(
        AppUrl.updatePatientProfile,
        formData,
        file,
        fileKey: 'profilePic',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateDoctorProfile(
      Map<String, String> formData, File? file) async {
    try {
      return await _apiServices.getPatchMultipartApiResponse(
        AppUrl.updateDoctorProfile,
        formData,
        file,
        fileKey: 'profilePic',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getChatMessages(String appointmentId,
      {int limit = 50, String? before}) async {
    try {
      String url =
          '${AppUrl.getChatMessages}/$appointmentId/messages?limit=$limit';
      if (before != null) url += '&before=$before';
      return await _apiServices.getGetApiResponse(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> sendChatMessage(
      String appointmentId, Map<String, String> fields, File? file) async {
    try {
      String url = '${AppUrl.sendChatMessage}/$appointmentId/messages';
      if (file != null) {
        return await _apiServices.getPostMultipartApiResponse(url, fields, file,
            fileKey: 'file');
      } else {
        return await _apiServices.getPostApiResponse(url, jsonEncode(fields));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> cancelAppointment(String appointmentId, String reason) async {
    try {
      final url = '${AppUrl.patientCancelAppointment}/$appointmentId/cancel';
      final payload = {"cancelReason": reason};
      return await _apiServices.getPatchApiResponse(url, payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getUpcomingAppointments() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getUpcomingAppointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getCancelledAppointments() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getCancelledAppointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPastAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getPastAppointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getHealthArticles() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getHealthArticles);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getPatientAppointments(String patientId,
      {String? status}) async {
    try {
      String url = '${AppUrl.getAppointments}/$patientId';
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
      return await _apiServices.getGetApiResponse(AppUrl.getDoctorPatients);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getFirstAidTopics() async {
    try {
      print("Fetching First Aid Topics from: ${AppUrl.getFirstAidTopics}");
      return await _apiServices.getGetApiResponse(AppUrl.getFirstAidTopics);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorMonthlyEarnings(int year, int month) async {
    try {
      return await _apiServices.getGetApiResponse(
          '${AppUrl.getDoctorEarningsByMonth}?year=$year&month=$month');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorBalance() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getDoctorBalance);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorUpcomingAppointments() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getDoctorUpcomingAppointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorPastAppointments() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getDoctorPastAppointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorCancelledAppointments() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getDoctorCancelledAppointments);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> approveAppointment(String id) async {
    try {
      return await _apiServices.getPatchApiResponse(
          "${AppUrl.doctorAppointmentActions}/$id/approve", {});
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> doctorCancelAppointment(String id, String reason) async {
    try {
      return await _apiServices.getPatchApiResponse(
          "${AppUrl.doctorAppointmentActions}/$id/cancel",
          {"cancelReason": reason});
    } catch (e) {
      rethrow;
    }
  }
}
