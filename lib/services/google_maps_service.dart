import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static const String _apiKey = "AIzaSyDfxcDdlq5IDIHjpRQKeAHepYIFaSYvVMQ";
  static const String _baseUrl = "https://maps.googleapis.com/maps/api";

  // Decode Polyline string format into LatLng list
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Fetch Route from A to B
  static Future<Map<String, dynamic>?> getRouteCoordinates(
      LatLng origin, LatLng destination) async {
    try {
      final String url =
          "$_baseUrl/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_apiKey";
      print("Fetching route from Google: $url");
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("Google Directions API Response Status: ${data['status']}");
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final String polylineString =
              data['routes'][0]['overview_polyline']['points'];
          final List<LatLng> decodedPoints = decodePolyline(polylineString);

          final String durationText =
              data['routes'][0]['legs'][0]['duration']['text'];
          final int durationValue =
              data['routes'][0]['legs'][0]['duration']['value'];

          print("Successfully fetched route points: ${decodedPoints.length}");
          return {
            'points': decodedPoints,
            'durationText': durationText,
            'durationValue': durationValue
          };
        } else {
          print(
              "Directions API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}");
        }
      } else {
        print("HTTP Error from Directions API: ${response.statusCode}");
      }
      return null;
    } catch (e) {
      print("Google Maps Directions Error: $e");
      return null;
    }
  }

  // Fetch Places Autocomplete
  static Future<List<dynamic>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    try {
      final String url =
          "$_baseUrl/place/autocomplete/json?input=$query&key=$_apiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'];
        }
      }
      return [];
    } catch (e) {
      print("Google Maps Places Error: $e");
      return [];
    }
  }

  // Get LatLng of a Selected Place
  static Future<LatLng?> getPlaceDetails(String placeId) async {
    try {
      final String url =
          "$_baseUrl/place/details/json?place_id=$placeId&key=$_apiKey";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      print("Google Maps Places Details Error: $e");
      return null;
    }
  }
}
