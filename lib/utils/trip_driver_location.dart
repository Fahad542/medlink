import 'package:medlink/utils/gps_coord.dart';

/// Reads driver/ambulance coordinates from trip JSON (REST + socket shapes).
class TripDriverLocation {
  TripDriverLocation._();

  static Map<String, dynamic>? _asLocMap(Map<String, dynamic> trip) {
    double? lat;
    double? lng;

    bool take(double? la, double? lo) {
      if (!GpsCoord.isValidPair(la, lo)) return false;
      lat = la;
      lng = lo;
      return true;
    }

    if (take(
      GpsCoord.tryParse(trip['driverLat'] ??
          trip['driverLatitude'] ??
          trip['currentDriverLat'] ??
          trip['ambulanceLat']),
      GpsCoord.tryParse(trip['driverLng'] ??
          trip['driverLongitude'] ??
          trip['currentDriverLng'] ??
          trip['ambulanceLng']),
    )) {
      return _buildLatest(lat!, lng!, trip, null);
    }

    final d = trip['driver'];
    if (d is Map) {
      final dm = Map<String, dynamic>.from(d);
      if (take(
        GpsCoord.tryParse(
            dm['currentLat'] ?? dm['latitude'] ?? dm['lat']),
        GpsCoord.tryParse(
            dm['currentLng'] ?? dm['longitude'] ?? dm['lng']),
      )) {
        return _buildLatest(lat!, lng!, trip, dm);
      }
    }

    for (final key in ['latestLocation', 'driverLocation', 'lastDriverLocation']) {
      final raw = trip[key];
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        if (take(GpsCoord.latFromMap(m), GpsCoord.lngFromMap(m))) {
          return {
            'lat': lat,
            'lng': lng,
            if (GpsCoord.tryParse(m['heading']) != null)
              'heading': GpsCoord.tryParse(m['heading']),
            if (GpsCoord.tryParse(m['speed']) != null)
              'speed': GpsCoord.tryParse(m['speed']),
            if (m['createdAt'] != null) 'createdAt': m['createdAt'],
          };
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _buildLatest(
    double lat,
    double lng,
    Map<String, dynamic> trip,
    Map<String, dynamic>? driverMap,
  ) {
    final heading = GpsCoord.tryParse(driverMap?['heading']) ??
        GpsCoord.tryParse(trip['driverHeading']);
    final speed = GpsCoord.tryParse(driverMap?['speed']);
    return {
      'lat': lat,
      'lng': lng,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (trip['locationUpdatedAt'] != null)
        'createdAt': trip['locationUpdatedAt'],
    };
  }

  /// Normalized `latestLocation`-style map, or null if nothing valid.
  static Map<String, dynamic>? latestFromTrip(Map<String, dynamic>? trip) {
    if (trip == null) return null;
    return _asLocMap(trip);
  }
}
