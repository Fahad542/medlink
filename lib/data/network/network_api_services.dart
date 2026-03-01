import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:medlink/data/app_exceptions.dart';
import 'package:medlink/data/network/base_api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkApiService extends BaseApiServices {
  Future<Map<String, String>> _getHeaders() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    
    // First try V2 session
    final String? sessionV2 = sp.getString('user_session_v2');
    Map<String, String> headers = {'Content-Type': 'application/json'};
    
    if (sessionV2 != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(sessionV2);
        final String? token = data['data'] != null ? data['data']['access_token'] : null;
        if (token != null && token.isNotEmpty) {
          print("Extracted Token for Header: $token");
          headers['Authorization'] = 'Bearer $token'; 
          return headers;
        }
      } catch (e) {
        print("Error parsing session_v2 string: $e");
      }
    }

    // Fallback to V1 session
    final String? sessionStr = sp.getString('user_session');
    if (sessionStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(sessionStr);
        final String? token = data['access_token'] ?? data['token'];
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token'; // or according to backend requirement
        } else {
          print("Token is null or empty in SharedPreferences");
        }
      } catch (e) {
        // Ignore JSON parse error
        print("Error parsing session string: $e");
      }
    }
    return headers;
  }

  @override
  Future getGetApiResponse(String url) async {
    print(url);
    dynamic responseJson;
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  @override
  Future getPostApiResponse(String url, dynamic data) async {
    print(url);
    dynamic responseJson;
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse(url),
            body: data,
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  @override
  Future getPatchApiResponse(String url, dynamic data) async {
    print(url);
    dynamic responseJson;
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse(url),
            body: data,
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  @override
  Future getPostMultipartApiResponse(String url, dynamic data, File? file, {String fileKey = 'image'}) async {
    print(url);
    dynamic responseJson;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      request.headers['accept'] = '*/*';
      
      print("Req URL: $url");
      print("Req Data Type: ${data.runtimeType}");
      print("Req Data Value: $data");

      if (data != null && data is Map) {
        data.forEach((key, value) {
          if (value != null) {
            request.fields[key.toString()] = value.toString();
          }
        });
        print("Final Multipart Headers: ${request.headers}");
        print("Final Multipart Fields Sent: ${request.fields}");
      } else {
        print("Req Data is NULL or NOT a Map");
      }
      
      // Add file if provided
      if (file != null) {
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();
        var multipartFile = http.MultipartFile(
          fileKey, // Key expected by server
          stream,
          length,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);
      
      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  dynamic returnResponse(http.Response response) {
    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    switch (response.statusCode) {
      case 200:
      case 201:
        try {
          dynamic responseJson = jsonDecode(response.body);
          print("Api resposne: ${responseJson}");
          return responseJson;
        } catch (e) {
          throw FetchDataException("Invalid JSON response: ${response.body}");
        }
      case 400:
        try {
           dynamic responseJson = jsonDecode(response.body);
           throw BadRequestException(responseJson['message']);
        } catch (e) {
           throw BadRequestException(response.body);
        }
      case 401:
        try {
          dynamic responseJson = jsonDecode(response.body);
          throw UnauthorizedException(responseJson['message'] ?? 'Invalid credentials');
        } catch (e) {
           throw UnauthorizedException('Invalid credentials');
        }
      case 404:
        try {
          dynamic responseJson = jsonDecode(response.body);
          throw UnauthorizedException(responseJson['message']);
        } catch (e) {
           throw UnauthorizedException(response.body);
        }
      case 422:
        try {
          dynamic responseJson = jsonDecode(response.body);
          throw InvalidInputException(responseJson['message']);
        } catch (e) {
           throw InvalidInputException(response.body);
        }
      case 500:
        try {
          dynamic responseJson = jsonDecode(response.body);
          throw FetchDataException(responseJson['message'] ?? 'Internal Server Error');
        } catch (e) {
           throw FetchDataException(response.body);
        }
      default:
        throw FetchDataException(
            'Error occurred while communicating with server with status code : ${response.statusCode}. Body: ${response.body}');
    }
  }
}
