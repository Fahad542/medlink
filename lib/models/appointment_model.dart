import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/user_model.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  upcoming,
  completed,
  cancelled,
  unconfirmed
}

enum AppointmentType { online, inPerson }

class PrescriptionModel {
  final String id;
  final String? diagnosis;
  final String? notes;
  final List<dynamic>? items;
  final List<dynamic>? tests;

  PrescriptionModel({
    required this.id,
    this.diagnosis,
    this.notes,
    this.items,
    this.tests,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id']?.toString() ?? '',
      diagnosis: json['diagnosis'],
      notes: json['notes'],
      items: json['items'],
      tests: json['tests'],
    );
  }
}

class AppointmentModel {
  final String id;
  final String doctorId;
  final String userId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? reason;
  final DoctorModel? doctor; // For UI convenience
  final UserModel? user;
  final Map<String, dynamic>? vitals;
  final PrescriptionModel? prescription;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.dateTime,
    required this.status,
    required this.type,
    this.reason,
    this.doctor,
    this.user,
    this.vitals,
    this.prescription,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    var doctorObj = json['doctor'] ?? json['doctor_id'];
    String doctorId = json['doctorId']?.toString() ?? '';
    DoctorModel? doctorModel;

    if (doctorObj is Map<String, dynamic>) {
      doctorId = doctorObj['id']?.toString() ??
          doctorObj['_id']?.toString() ??
          doctorId;

      String clinicName = '';
      if (doctorObj['doctorProfile'] is Map) {
        clinicName = doctorObj['doctorProfile']['clinicName'] ?? '';
      }

      String photoUrl = AppUrl.getFullUrl(
          doctorObj['profilePhotoUrl']?.toString() ??
              doctorObj['profile_image_url']?.toString());

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
      parsedDate = DateTime.tryParse(json['scheduledStart'])?.toLocal() ??
          DateTime.now();
    } else if (json['date'] != null && json['time'] != null) {
      parsedDate = DateTime.tryParse("${json['date']}T${json['time']}") ??
          DateTime.now();
    }

    UserModel? patientModel;
    if (json['patient'] != null && json['patient'] is Map<String, dynamic>) {
      patientModel = UserModel.fromJson(json['patient']);
    }

    return AppointmentModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      doctorId: doctorId,
      userId:
          json['patientId']?.toString() ?? json['patient_id']?.toString() ?? '',
      dateTime: parsedDate,
      status: _parseStatus(json['status']),
      type: json['consultKind'] == 'VIDEO'
          ? AppointmentType.online
          : AppointmentType.inPerson,
      reason: json['reason'],
      doctor: doctorModel,
      user: patientModel,
      vitals: json['vitals'],
      prescription: json['prescription'] != null
          ? PrescriptionModel.fromJson(json['prescription'])
          : null,
    );
  }

  static AppointmentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'booked':
      case 'upcoming':
        return AppointmentStatus.upcoming;
      case 'completed':
        return AppointmentStatus.completed;
      case 'past':
        return AppointmentStatus.unconfirmed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.unconfirmed;
    }
  }
}
