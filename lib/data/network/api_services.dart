import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/network_api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for temporary register tokens (Step 2 verify-otp response).
const String _kPatientRegisterToken = 'patient_register_token';
const String _kDoctorRegisterToken = 'doctor_register_token';
const String _kDriverRegisterToken = 'driver_register_token';

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
        jsonEncode({'phone': phone, 'otp': otp, 'purpose': 'REGISTER'}),
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

  Future<dynamic> createSos(double latitude, double longitude,
      {String incidentType = "Medical Emergency",
      String severity = "High"}) async {
    try {
      return await _apiServices.getPostApiResponse(
        AppUrl.createSos,
        jsonEncode({
          "lat": latitude,
          "lng": longitude,
          "emergencyType": incidentType,
          "severity": severity
        }),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getMySos() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.createSos);
    } catch (e) {
      rethrow;
    }
  }

  // --- Emergency Contacts ---
  Future<dynamic> getEmergencyContacts() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.emergencyContacts);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> createEmergencyContact({
    required String fullName,
    required String phone,
    String? relation,
    bool isPrimary = false,
  }) async {
    try {
      final body = jsonEncode({
        'fullName': fullName,
        'phone': phone,
        if (relation != null && relation.isNotEmpty) 'relation': relation,
        'isPrimary': isPrimary,
      });
      return await _apiServices.getPostApiResponse(AppUrl.emergencyContacts, body);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateEmergencyContact(
    String contactId, {
    String? fullName,
    String? phone,
    String? relation,
    bool? isPrimary,
  }) async {
    try {
      final body = jsonEncode({
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (relation != null) 'relation': relation,
        if (isPrimary != null) 'isPrimary': isPrimary,
      });
      return await _apiServices.getPatchApiResponse(
          '${AppUrl.emergencyContacts}/$contactId', body);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteEmergencyContact(String contactId) async {
    try {
      return await _apiServices.getDeleteApiResponse(
          '${AppUrl.emergencyContacts}/$contactId');
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
        jsonEncode({'phone': phone, 'otp': otp, 'purpose': 'DOCTOR_REGISTER'}),
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

  // --- Driver registration (3 steps: send-otp, verify-otp, register) ---

  /// Driver registration Step 1: send OTP. Body: {"phone": "+..."}
  Future<dynamic> driverSendOtp(String phone) async {
    try {
      return await _apiServices.getPostApiResponse(
        AppUrl.driverRegisterStep1,
        jsonEncode({'phone': phone}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Driver registration Step 2: verify OTP. Saves register_token to SharedPreferences.
  Future<dynamic> driverVerifyOtp(String phone, String otp) async {
    try {
      final response = await _apiServices.getPostApiResponse(
        AppUrl.driverRegisterStep2,
        jsonEncode({'phone': phone, 'otp': otp, 'purpose': 'DRIVER_REGISTER'}),
      );
      final data = response is Map ? response['data'] : null;
      final token = data is Map ? data['register_token']?.toString() : null;
      if (token != null && token.isNotEmpty) {
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_kDriverRegisterToken, token);
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Driver registration Step 3: register with form-data + profilePic + driverLicenseDocument. Uses Bearer register_token.
  Future<dynamic> driverRegister(
    Map<String, String> formData,
    File? profilePicFile,
    File? driverLicenseFile,
  ) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final registerToken = sp.getString(_kDriverRegisterToken);
      if (registerToken == null || registerToken.isEmpty) {
        throw Exception('Register token expired. Please restart registration.');
      }
      final response = await _apiServices.getPostMultipartWithBearerTwoFiles(
        AppUrl.driverRegisterStep3,
        formData,
        profilePicFile,
        fileKey1: 'profilePic',
        file2: driverLicenseFile,
        fileKey2: 'driverLicenseDocument',
        bearerToken: registerToken,
      );
      await sp.remove(_kDriverRegisterToken);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// GET driver profile. Returns { success, data: { user, driverProfile } }.
  Future<dynamic> getDriverProfile() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getDriverProfile);
    } catch (e) {
      rethrow;
    }
  }

  /// GET driver dashboard summary. Returns { success, data: { totalTrips, totalEarnings } }.
  Future<dynamic> getDriverDashboard() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getDriverDashboard);
    } catch (e) {
      rethrow;
    }
  }

  /// GET driver emergency requests. Returns { success, data: [ ... ] }.
  Future<dynamic> getDriverEmergencyRequests() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getDriverEmergencyRequests);
    } catch (e) {
      rethrow;
    }
  }

  /// POST accept emergency request. Returns { success, ... }.
  Future<dynamic> acceptEmergencyRequest(String id) async {
    try {
      return await _apiServices.getPostApiResponse(
        '${AppUrl.getDriverEmergencyRequests}/$id/accept',
        {},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST decline emergency request. Returns { success, ... }.
  Future<dynamic> declineEmergencyRequest(String id) async {
    try {
      return await _apiServices.getPostApiResponse(
        '${AppUrl.getDriverEmergencyRequests}/$id/decline',
        {},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH driver online/offline status. Body: {"isAvailable": true|false}. Returns { success, data: { isAvailable } }.
  Future<dynamic> updateDriverStatus(bool isAvailable) async {
    try {
      return await _apiServices.getPatchApiResponse(
        AppUrl.updateDriverStatus,
        {'isAvailable': isAvailable},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET driver earnings summary. Returns { success, data: { totalBalance, earningsToday, earningsThisWeek } }.
  Future<dynamic> getDriverEarningsSummary() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getDriverEarningsSummary);
    } catch (e) {
      rethrow;
    }
  }

  /// GET driver earnings transactions (recent trip earnings). Query: limit, offset. Returns { success, data: [] }.
  /// Each item: id, tripNumber, amount, currency, transactionDate, type, source.
  Future<dynamic> getDriverEarningsTransactions(
      {int limit = 20, int offset = 0}) async {
    try {
      final url =
          '${AppUrl.getDriverEarningsTransactions}?limit=$limit&offset=$offset';
      return await _apiServices.getGetApiResponse(url);
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

  // Future<dynamic> registerStep6(dynamic data, [File? file]) async {
  //   try {
  //     return await _apiServices.getPostMultipartApiResponse(
  //         AppUrl.registerStep5, data, file,
  //         fileKey: 'profilePicture');
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

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
          AppUrl.patientRegisterStep1, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> doctorCheckEmail(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.doctorRegisterStep1, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> driverCheckEmail(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.driverRegisterStep1, jsonEncode(data));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> verifyEmailOtp(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.patientRegisterStep2, jsonEncode(data));
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

  Future<dynamic> getChatHistory(String patientId) async {
    try {
      final url = "${AppUrl.getChatHistory}/$patientId/doctors";
      return await _apiServices.getGetApiResponse(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getUnifiedChatHistory(
      String doctorId, String patientId) async {
    try {
      final url =
          "${AppUrl.getUnifiedChatHistory}/doctor/$doctorId/patient/$patientId";
      return await _apiServices.getGetApiResponse(url);
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
      print("========== BOOK APPOINTMENT API BODY ==========");
      print(jsonEncode(data));
      print("===============================================");
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

  Future<dynamic> getChatMessages(String recipientId,
      {int limit = 50, String? before}) async {
    try {
      String url =
          '${AppUrl.getChatMessages}/$recipientId/messages?limit=$limit';
      if (before != null) url += '&before=$before';
      return await _apiServices.getGetApiResponse(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> sendChatMessage(
      String recipientId, Map<String, String> fields, File? file) async {
    try {
      String url = '${AppUrl.sendChatMessage}/$recipientId/messages';
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

  Future<dynamic> completeAppointment(String appointmentId) async {
    try {
      final url =
          '${AppUrl.baseUrl}/patient/appointments/$appointmentId/complete';
      return await _apiServices.getPatchApiResponse(url, {});
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

  Future<dynamic> getEmergencyNumbers() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getEmergencyNumbers);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getQuickInstructions() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getQuickInstructions);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getFirstAidTopics() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getFirstAidTopics);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getHealthVideos() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getHealthVideos);
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

  Future<dynamic> submitConsultation(
      String appointmentId, Map<String, dynamic> data) async {
    print(data);
    try {
      return await _apiServices.getPostApiResponse(
        "${AppUrl.doctorAppointmentActions}/$appointmentId/consultation",
        jsonEncode(data),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPatientPrescriptions() async {
    try {
      return await _apiServices
          .getGetApiResponse(AppUrl.getPatientPrescriptions);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPrescriptionByAppointment(String appointmentId) async {
    try {
      return await _apiServices.getGetApiResponse(
          "${AppUrl.getPrescriptionByAppointment}/$appointmentId");
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> uploadTestReport(
      String prescriptionId, String testId, File file) async {
    try {
      // /{prescriptionId}/tests/{testId}/report
      final url =
          "${AppUrl.uploadTestReport}/$prescriptionId/tests/$testId/report";
      return await _apiServices.getPatchMultipartApiResponse(url, {}, file,
          fileKey: 'report');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateDoctorAvailability(bool isAvailable) async {
    try {
      return await _apiServices.getPatchApiResponse(
        AppUrl.updateDoctorAvailability,
        {"isAvailable": isAvailable},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorArticles() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.getDoctorArticles);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPatientProfileForDoctor(String patientId) async {
    try {
      return await _apiServices.getGetApiResponse(
          "${AppUrl.getPatientProfileForDoctor}/$patientId/profile");
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorChatHistory(String doctorId) async {
    try {
      return await _apiServices.getGetApiResponse(
          "${AppUrl.getDoctorChatHistory}/$doctorId/patients");
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getDoctorAppointmentsHistory([String? patientId]) async {
    try {
      String url = AppUrl.getDoctorAppointmentsHistory;
      if (patientId != null && patientId.isNotEmpty) {
        url += "?patientId=$patientId";
      }
      return await _apiServices.getGetApiResponse(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getPrescriptionDetails(String appointmentId) async {
    try {
      return await _apiServices.getGetApiResponse(
          "${AppUrl.getPrescriptionDetails}/$appointmentId/prescription-details");
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> uploadArticle({
    required String title,
    required String category,
    required String contentHtml,
    required bool isPublished,
    required String? imagePath,
  }) async {
    try {
      Map<String, String> data = {
        'title': title,
        'category': category,
        'contentHtml': contentHtml,
        'isPublished': isPublished.toString(),
      };

      File? imageFile;
      if (imagePath != null) {
        imageFile = File(imagePath);
      }

      return await _apiServices.getPostMultipartApiResponse(
        AppUrl.uploadArticle,
        data,
        imageFile,
        fileKey: 'coverImage',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET current active trip. Returns { success, data: { ... } } or null.
  Future<dynamic> getCurrentTrip() async {
    try {
      return await _apiServices
          .getGetApiResponse('${AppUrl.driverTrips}/current');
    } catch (e) {
      rethrow;
    }
  }

  /// POST mark arrival at pickup. Returns { success, status: 'ARRIVED' }.
  Future<dynamic> arriveAtPickup(String tripId) async {
    try {
      return await _apiServices.getPostApiResponse(
        '${AppUrl.driverTrips}/$tripId/arrive',
        {},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST start route (transport). Returns { success, status: 'IN_PROGRESS' }.
  Future<dynamic> startRoute(String tripId) async {
    try {
      return await _apiServices.getPostApiResponse(
        '${AppUrl.driverTrips}/$tripId/start-route',
        {},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST complete trip. Returns { success, status: 'COMPLETED' }.
  Future<dynamic> completeTrip(String tripId) async {
    try {
      return await _apiServices.getPostApiResponse(
        '${AppUrl.driverTrips}/$tripId/complete',
        {},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// GET driver trip history. Returns { success, data: [ ... ] }.
  Future<dynamic> getDriverTripHistory({int limit = 20, int offset = 0}) async {
    try {
      return await _apiServices.getGetApiResponse(
        '${AppUrl.driverTrips}?limit=$limit&offset=$offset',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Agora Token
  Future<dynamic> getAgoraToken(String channelName, String role) async {
    try {
      final url = '${AppUrl.getAgoraToken}?channelName=$channelName&role=$role';
      return await _apiServices.getGetApiResponse(url);
    } catch (e) {
      rethrow;
    }
  }

  // --- Agora / Calling ---

  Future<dynamic> initiateCall(int recipientId) async {
    try {
      return await _apiServices.getPostApiResponse(
        AppUrl.initiateCall,
        {'recipientId': recipientId},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> checkIncomingCall() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.checkIncomingCall);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getCallStatus(String channelName) async {
    try {
      final url = '${AppUrl.callStatus}?channelName=$channelName';
      return await _apiServices.getGetApiResponse(url);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateCallStatus(String channelName, String status) async {
    try {
      return await _apiServices.getPostApiResponse(
        AppUrl.updateCallStatus,
        {'channelName': channelName, 'status': status},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateDriverProfile({
    String? fullName,
    String? email,
    String? phone,
    String? vehiclePlate,
    String? vehicleType,
    String? licenseNo,
    File? profilePhoto,
  }) async {
    try {
      final Map<String, String> data = {};
      if (fullName != null) data['fullName'] = fullName;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (vehiclePlate != null) data['vehiclePlate'] = vehiclePlate;
      if (vehicleType != null) data['vehicleType'] = vehicleType;
      if (licenseNo != null) data['licenseNo'] = licenseNo;

      return await _apiServices.getPatchMultipartApiResponse(
        '${AppUrl.baseUrl}/driver/profile',
        data,
        profilePhoto,
        fileKey: 'profilePhoto',
      );
    } catch (e) {
      rethrow;
    }}

  // --- Password Reset ---
  Future<dynamic> forgotPassword(String identifier) async {
    try {
      final Map<String, dynamic> body = {};
      if (identifier.contains('@')) {
        body['email'] = identifier;
      } else {
        body['phone'] = identifier;
      }
      return await _apiServices.getPostApiResponse(
          AppUrl.forgotPassword, jsonEncode(body));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> verifyResetOtp(
      String identifier, String otp) async {
    try {
      final Map<String, dynamic> body = {
        'otp': otp,
        'purpose': 'RESET_PASSWORD'
      };
      if (identifier.contains('@')) {
        body['email'] = identifier;
      } else {
        body['phone'] = identifier;
      }
      return await _apiServices.getPostApiResponse(
          AppUrl.verifyOtp, jsonEncode(body));
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> resetPassword(String resetToken, String newPassword) async {
    try {
      final Map<String, dynamic> body = {
        'resetToken': resetToken,
        'newPassword': newPassword,
      };
      return await _apiServices.getPostApiResponse(
          AppUrl.resetPassword, jsonEncode(body));
    } catch (e) {
      rethrow;
    }
  }

  // --- Delete Account ---
  Future<dynamic> sendDeleteAccountOtp() async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.deleteAccountSendOtp, "{}");
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> verifyDeleteAccountOtp(String otp) async {
    try {
      return await _apiServices.getPostApiResponse(
          AppUrl.deleteAccountVerifyOtp, jsonEncode({'otp': otp}));
    } catch (e) {
      rethrow;
    }
  }
}
