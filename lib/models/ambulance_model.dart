class AmbulanceModel {
  final String id;
  final String driverName;
  final String plateNumber;
  final double currentLat;
  final double currentLng;
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
  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    final profile = json['driver'] is Map<String, dynamic>
        ? json['driver']
        : (json['ambulance'] is Map<String, dynamic>
            ? json['ambulance']
            : (json['user'] is Map<String, dynamic> ? json['user'] : {}));

    dynamic getField(String key) => json[key] ?? profile[key];

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
      currentLat:
          double.tryParse(getField('currentLat')?.toString() ?? '0') ?? 0.0,
      currentLng:
          double.tryParse(getField('currentLng')?.toString() ?? '0') ?? 0.0,
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
      'currentLat': currentLat,
      'currentLng': currentLng,
      'vehicleType': vehicleType,
      'status': status,
      'estimatedArrival': estimatedArrival,
      'profilePhotoUrl': profilePhotoUrl,
      'phoneNumber': phoneNumber,
    };
  }
}
