import 'dart:io';

abstract class BaseApiServices {
  Future<dynamic> getGetApiResponse(String url);
  Future<dynamic> getPostApiResponse(String url, dynamic data);
  Future<dynamic> getPutApiResponse(String url, dynamic data);
  Future<dynamic> getPatchApiResponse(String url, dynamic data);
  Future<dynamic> getDeleteApiResponse(String url);
  Future<dynamic> getPostMultipartApiResponse(String url, dynamic data, File? file,
      {String fileKey = 'image'});
  Future<dynamic> getPatchMultipartApiResponse(
      String url, dynamic data, File? file,
      {String fileKey = 'image'});
  Future<dynamic> getMultipartApiResponse(dynamic request);
}
