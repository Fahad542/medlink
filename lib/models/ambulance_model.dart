class AmbulanceModel {
  final String id;
  final String driverName;
  final String plateNumber;
  final double currentLat;
  final double currentLng;
  final String vehicleType;
  final String status; // Enroute, Arrived, Idle
  final String estimatedArrival;

  AmbulanceModel({
    required this.id,
    required this.driverName,
    required this.plateNumber,
    required this.currentLat,
    required this.currentLng,
    required this.vehicleType,
    required this.status,
    required this.estimatedArrival,
  });
  factory AmbulanceModel.fromJson(Map<String, dynamic> json) {
    return AmbulanceModel(
      id: json['id'] ?? json['user_id'] ?? '',
      driverName: json['driverName'] ?? json['driver_name'] ?? '',
      plateNumber: json['plateNumber'] ?? json['plate_number'] ?? '',
      currentLat: (json['currentLat'] ?? 0).toDouble(),
      currentLng: (json['currentLng'] ?? 0).toDouble(),
      vehicleType: json['vehicleType'] ?? json['vehicle_type'] ?? 'Ambulance',
      status: json['status'] ?? 'Idle',
      estimatedArrival: json['estimatedArrival'] ?? '20 min',
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
    };
  }
}
