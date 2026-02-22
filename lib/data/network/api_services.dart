import 'dart:convert';
import 'dart:io';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/data/network/network_api_services.dart';

class ApiServices {
  final _apiServices = NetworkApiService();

  // --- Auth & Patient Methods ---
  
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

  Future<dynamic> getAppointments() async {
    try {
      return await _apiServices.getGetApiResponse(AppUrl.get_appointments);
    } catch (e) { rethrow; }
  }

  Future<dynamic> bookAppointment(dynamic data) async {
    try {
      return await _apiServices.getPostApiResponse(AppUrl.book_appointments, jsonEncode(data));
    } catch (e) { rethrow; }
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

  Future<dynamic> getFirstAidTopics() async {
    try {
      print("Fetching First Aid Topics from: ${AppUrl.get_first_aid_topics}");
      return await _apiServices.getGetApiResponse(AppUrl.get_first_aid_topics);
    } catch (e) {
      rethrow;
    }
  }
}
