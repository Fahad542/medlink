import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:medlink/data/app_exceptions.dart';
import 'package:medlink/data/network/base_api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkApiService extends BaseApiServices {
  static MediaType _mediaTypeForFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'jpeg':
      case 'jpg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    final String? sessionStr = sp.getString('user_session_v2');
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (sessionStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(sessionStr);
        // UserLoginModel has token inside data.access_token
        final String? token =
            data['data'] != null ? data['data']['access_token'] : null;

        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        if (kDebugMode) print("Error parsing session string: $e");
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
      final body = data is Map ? jsonEncode(data) : data;
      final response = await http
          .post(
            Uri.parse(url),
            body: body,
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
      final body = data is Map ? jsonEncode(data) : data;
      final response = await http
          .patch(
            Uri.parse(url),
            body: body,
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }

    return responseJson;
  }

  /// POST multipart with optional Bearer token (e.g. register_token from verify-otp for patient register).
  /// When [bearerToken] is set, sends Authorization: Bearer <token> so register API returns access_token.
  Future getPostMultipartWithOptionalBearer(
    String url,
    Map<String, String> fields,
    File? file, {
    String? bearerToken,
    String fileKey = 'profilePic',
  }) async {
    dynamic responseJson;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      if (bearerToken != null && bearerToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $bearerToken';
      } else {
        final headers = await _getHeaders();
        if (headers.containsKey('Authorization')) {
          request.headers['Authorization'] = headers['Authorization']!;
        }
      }
      request.headers['accept'] = '*/*';

      fields.forEach((key, value) {
        if (value.isNotEmpty) request.fields[key] = value;
      });

      if (kDebugMode) {
        print("Register request URL: $url");
        print(
            "Register request has Auth: ${bearerToken != null && bearerToken.isNotEmpty}");
        print("Register request fields: ${request.fields.keys.toList()}");
      }

      if (file != null && file.existsSync() && file.lengthSync() > 0) {
        final filename = file.path.split('/').last;
        final contentType = _mediaTypeForFilename(filename);
        request.files.add(await http.MultipartFile.fromPath(
          fileKey,
          file.path,
          filename: filename,
          contentType: contentType,
        ));
        if (kDebugMode) {
          print("Register request file: $filename contentType: $contentType");
        }
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);
      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  /// POST multipart with Bearer token and two file parts (e.g. doctor register: profilePic + medicalLicenseDocument).
  Future getPostMultipartWithBearerTwoFiles(
    String url,
    Map<String, String> fields,
    File? file1, {
    String fileKey1 = 'profilePic',
    File? file2,
    String fileKey2 = 'medicalLicenseDocument',
    required String bearerToken,
  }) async {
    dynamic responseJson;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'Bearer $bearerToken';
      request.headers['accept'] = '*/*';

      fields.forEach((key, value) {
        if (value.isNotEmpty) request.fields[key] = value;
      });

      if (file1 != null && file1.existsSync() && file1.lengthSync() > 0) {
        final filename = file1.path.split('/').last;
        request.files.add(await http.MultipartFile.fromPath(
          fileKey1,
          file1.path,
          filename: filename,
          contentType: _mediaTypeForFilename(filename),
        ));
      }
      if (file2 != null && file2.existsSync() && file2.lengthSync() > 0) {
        final filename = file2.path.split('/').last;
        request.files.add(await http.MultipartFile.fromPath(
          fileKey2,
          file2.path,
          filename: filename,
          contentType: _mediaTypeForFilename(filename),
        ));
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);
      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  @override
  Future getPostMultipartApiResponse(String url, dynamic data, File? file,
      {String fileKey = 'image'}) async {
    return _sendMultipartRequest('POST', url, data, file, fileKey: fileKey);
  }

  @override
  Future getPatchMultipartApiResponse(String url, dynamic data, File? file,
      {String fileKey = 'image'}) async {
    return _sendMultipartRequest('PATCH', url, data, file, fileKey: fileKey);
  }

  Future<dynamic> _sendMultipartRequest(
      String method, String url, dynamic data, File? file,
      {String fileKey = 'image'}) async {
    print(url);
    dynamic responseJson;
    try {
      var request = http.MultipartRequest(method, Uri.parse(url));

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      request.headers['accept'] = '*/*';

      if (kDebugMode) {
        print("Req Method: $method");
        print("Req URL: $url");
        print("Req Data Type: ${data.runtimeType}");
        print("Req Data Value: $data");
      }

      if (data != null && data is Map) {
        data.forEach((key, value) {
          if (value != null) {
            request.fields[key.toString()] = value.toString();
          }
        });
        if (kDebugMode) {
          print("Final Multipart Headers: ${request.headers}");
          print("Final Multipart Fields Sent: ${request.fields}");
        }
      }

      // Add file if provided
      if (file != null && file.existsSync() && file.lengthSync() > 0) {
        final filename = file.path.split('/').last;
        final contentType = _mediaTypeForFilename(filename);
        request.files.add(await http.MultipartFile.fromPath(
          fileKey,
          file.path,
          filename: filename,
          contentType: contentType,
        ));
        if (kDebugMode) {
          print("Multipart request file: $filename contentType: $contentType");
        }
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 25));
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
          throw UnauthorizedException(
              responseJson['message'] ?? 'Invalid credentials');
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
          throw FetchDataException(
              responseJson['message'] ?? 'Internal Server Error');
        } catch (e) {
          throw FetchDataException(response.body);
        }
      default:
        throw FetchDataException(
            'Error occurred while communicating with server with status code : ${response.statusCode}. Body: ${response.body}');
    }
  }
}
