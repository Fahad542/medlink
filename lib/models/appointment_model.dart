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
    var doctorObj = json['doctor'] ?? json['doctor_id'];
    String doctorId = json['doctorId']?.toString() ?? '';
    DoctorModel? doctorModel;

    if (doctorObj is Map<String, dynamic>) {
      doctorId = doctorObj['id']?.toString() ?? doctorObj['_id']?.toString() ?? doctorId;
      
      String clinicName = '';
      if (doctorObj['doctorProfile'] is Map) {
         clinicName = doctorObj['doctorProfile']['clinicName'] ?? '';
      }

      String photoUrl = doctorObj['profilePhotoUrl'] ?? doctorObj['profile_image_url'] ?? '';
      if (photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
        photoUrl = 'https://medlink-be-production.up.railway.app$photoUrl';
      }

      // Create a partial doctor model if we have data
      doctorModel = DoctorModel(
        id: doctorId,
        name: doctorObj['fullName'] ?? doctorObj['full_name'] ?? 'Unknown',
        specialty: doctorObj['specialty'] ?? 'Specialist',
        hospital: clinicName,
        rating: 0.0,
        imageUrl: photoUrl,
        isAvailable: true,
        consultationFee: 0.0,
        about: '',
      );
    } else if (doctorObj is String) {
      doctorId = doctorObj;
    }

    DateTime parsedDate = DateTime.now();
    if (json['scheduledStart'] != null) {
      parsedDate = DateTime.tryParse(json['scheduledStart'])?.toLocal() ?? DateTime.now();
    } else if (json['date'] != null && json['time'] != null) {
      parsedDate = DateTime.tryParse("${json['date']}T${json['time']}") ?? DateTime.now();
    }

    UserModel? patientModel;
    if (json['patient'] != null && json['patient'] is Map<String, dynamic>) {
      patientModel = UserModel.fromJson(json['patient']);
    }

    return AppointmentModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      doctorId: doctorId,
      userId: json['patientId']?.toString() ?? json['patient_id']?.toString() ?? '',
      dateTime: parsedDate,
      status: _parseStatus(json['status']),
      type: json['consultKind'] == 'VIDEO' ? AppointmentType.online : AppointmentType.inPerson, 
      doctor: doctorModel, 
      user: patientModel,
    );
  }

  static AppointmentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'booked': 
      case 'upcoming': 
      case 'pending':
      case 'confirmed':
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
