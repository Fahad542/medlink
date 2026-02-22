import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/user_model.dart';

enum AppointmentStatus { upcoming, completed, cancelled, unconfirmed }
enum AppointmentType { online, inPerson }

class AppointmentModel {
  final String id;
  final String doctorId;
  final String userId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final AppointmentType type;
  final DoctorModel? doctor; // For UI convenience
  final UserModel? user;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.dateTime,
    required this.status,
    required this.type,
    this.doctor,
    this.user,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    var doctorObj = json['doctor_id'];
    String doctorId = '';
    DoctorModel? doctorModel;

    if (doctorObj is Map<String, dynamic>) {
      doctorId = doctorObj['_id'] ?? '';
      // Create a partial doctor model if we have data
      doctorModel = DoctorModel(
        id: doctorId,
        name: doctorObj['full_name'] ?? 'Unknown',
        specialty: doctorObj['specialty'] ?? '',
        hospital: '', // Not provided in this endpoint
        rating: 0.0,
        imageUrl: '', // Not provided
        isAvailable: true,
        consultationFee: 0.0,
        about: '',
      );
    } else if (doctorObj is String) {
      doctorId = doctorObj;
    }

    return AppointmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: doctorId,
      userId: json['patient_id'] ?? '',
      dateTime: DateTime.tryParse("${json['date']}T${json['time']}") ?? DateTime.now(),
      status: _parseStatus(json['status']),
      type: AppointmentType.inPerson, 
      doctor: doctorModel, 
    );
  }

  static AppointmentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'booked': 
      case 'upcoming': 
        return AppointmentStatus.upcoming;
      case 'completed': 
      case 'past':
        return AppointmentStatus.completed;
      case 'cancelled': 
        return AppointmentStatus.cancelled;
      default: return AppointmentStatus.unconfirmed;
    }
  }
}
