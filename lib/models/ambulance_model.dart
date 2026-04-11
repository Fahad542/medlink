import 'package:medlink/utils/gps_coord.dart';

class AmbulanceModel {
  final String id;
  final String driverName;
  final String plateNumber;
  /// Live GPS when known; null until backend/socket sends a real fix (never 0,0 placeholder).
  final double? currentLat;
  final double? currentLng;
  final String vehicleType;
  final String status; // Enroute, Arrived, Idle
  final String estimatedArrival;
  final String profilePhotoUrl;
  final String phoneNumber;

  AmbulanceModel({
    required this.id,
    required this.driverName,
    required this.plateNumber,
    required this.currentLat,
    required this.currentLng,
    required this.vehicleType,
    required this.status,
    required this.estimatedArrival,
    required this.profilePhotoUrl,
    required this.phoneNumber,
  });

  AmbulanceModel withDriverLocation(double lat, double lng) {
    if (!GpsCoord.isValidPair(lat, lng)) return this;
    return AmbulanceModel(
      id: id,
      driverName: driverName,
      plateNumber: plateNumber,
      currentLat: lat,
      currentLng: lng,
      vehicleType: vehicleType,
      status: status,
      estimatedArrival: estimatedArrival,
      profilePhotoUrl: profilePhotoUrl,
      phoneNumber: phoneNumber,
    );
  }

  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    final profile = json['driver'] is Map<String, dynamic>
        ? json['driver']
        : (json['ambulance'] is Map<String, dynamic>
            ? json['ambulance']
            : (json['user'] is Map<String, dynamic> ? json['user'] : {}));

    dynamic getField(String key) => json[key] ?? profile[key];

    Map<String, dynamic>? nestedLoc;
    for (final key in ['latestLocation', 'currentLocation', 'lastKnownLocation']) {
      final top = json[key];
      if (top is Map) {
        nestedLoc = Map<String, dynamic>.from(top);
        break;
      }
      if (profile is Map) {
        final inner = profile[key];
        if (inner is Map) {
          nestedLoc = Map<String, dynamic>.from(inner);
          break;
        }
      }
    }

    var lat = GpsCoord.tryParse(getField('currentLat') ?? getField('latitude'));
    var lng = GpsCoord.tryParse(getField('currentLng') ?? getField('longitude'));

    if (!GpsCoord.isValidPair(lat, lng) && nestedLoc != null) {
      lat = GpsCoord.latFromMap(nestedLoc);
      lng = GpsCoord.lngFromMap(nestedLoc);
    }

    final valid = GpsCoord.isValidPair(lat, lng);

    return AmbulanceModel(
      id: getField('id')?.toString() ?? getField('user_id')?.toString() ?? '',
      driverName: getField('driverName') ??
          getField('fullName') ??
          getField('driver_name') ??
          '',
      plateNumber: getField('vehiclePlate') ??
          getField('plateNumber') ??
          getField('plate_number') ??
          '',
      currentLat: valid ? lat : null,
      currentLng: valid ? lng : null,
      vehicleType:
          getField('vehicleType') ?? getField('vehicle_type') ?? 'Ambulance',
      status: getField('status') ?? 'Idle',
      estimatedArrival: getField('estimatedArrival') ?? '20 min',
      profilePhotoUrl:
          getField('profilePhotoUrl') ?? getField('profile_photo_url') ?? '',
      phoneNumber: getField('phoneNumber') ?? getField('phone') ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverName': driverName,
      'plateNumber': plateNumber,
      if (currentLat != null) 'currentLat': currentLat,
      if (currentLng != null) 'currentLng': currentLng,
      'vehicleType': vehicleType,
      'status': status,
      'estimatedArrival': estimatedArrival,
      'profilePhotoUrl': profilePhotoUrl,
      'phoneNumber': phoneNumber,
    };
  }
}
