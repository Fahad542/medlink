/// Shared GPS parsing / sanity checks so we never treat (0,0) or junk as a real position.
class GpsCoord {
  GpsCoord._();

  static double? tryParse(dynamic v) {
    if (v == null) return null;
    final d = double.tryParse(v.toString());
    if (d == null || !d.isFinite) return null;
    return d;
  }

  /// Rejects null island (0,0), out-of-range, and non-finite values.
  static bool isValidPair(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat.abs() < 1e-6 && lng.abs() < 1e-6) return false;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    return true;
  }

  static double? latFromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return tryParse(m['lat'] ?? m['latitude']);
  }

  static double? lngFromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return tryParse(m['lng'] ?? m['longitude']);
  }

  /// Trip / SOS ids may be int or UUID string; backend payloads may mix types.
  static bool sameId(Object? a, Object? b) {
    if (a == null || b == null) return false;
    final sa = a.toString();
    final sb = b.toString();
    if (sa == sb) return true;
    final ia = int.tryParse(sa);
    final ib = int.tryParse(sb);
    if (ia != null && ib != null && ia == ib) return true;
    return false;
  }
}
