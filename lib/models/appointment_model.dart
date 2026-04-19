import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/models/doctor_model.dart';
import 'package:medlink/models/user_model.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  upcoming,
  completed,
  cancelled,
  unconfirmed,
  rescheduled,
}

enum AppointmentType { online, inPerson }

/// API payload for booking; must match backend enum (see `AppointmentModel.fromJson`).
extension AppointmentTypeApi on AppointmentType {
  String get consultKindValue =>
      this == AppointmentType.online ? 'VIDEO' : 'IN_PERSON';
}

/// Short labels for UI lists and badges.
extension AppointmentTypeUi on AppointmentType {
  String get shortLabel =>
      this == AppointmentType.online ? 'Online' : 'In clinic';
}

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
  /// From API `scheduledStart` when present; may be null if only legacy `date`/`time` fields exist.
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? createdAt;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? reason;
  final DoctorModel? doctor; // For UI convenience
  final UserModel? user;
  final Map<String, dynamic>? vitals;
  final PrescriptionModel? prescription;
  final bool isPaid;

  /// Effective slot start for display and sorting (scheduledStart from API, else parsed dateTime).
  DateTime get displayScheduledStart => (scheduledStart ?? dateTime).toLocal();

  AppointmentModel({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.dateTime,
    this.scheduledStart,
    this.scheduledEnd,
    this.createdAt,
    required this.status,
    required this.type,
    this.reason,
    this.doctor,
    this.user,
    this.vitals,
    this.prescription,
    this.isPaid = false,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();
    }
    if (v is double) {
      return DateTime.fromMillisecondsSinceEpoch(v.round(), isUtc: true)
          .toLocal();
    }
    String s = v.toString().trim();
    if (s.isEmpty) return null;
    // Some JSON encoders use space instead of "T" between date and time.
    if (s.contains(' ') && !s.contains('T') && RegExp(r'^\d{4}-\d{2}-\d{2} ')
        .hasMatch(s)) {
      s = s.replaceFirst(' ', 'T');
    }
    final parsed = DateTime.tryParse(s);
    return parsed?.toLocal();
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    var doctorObj = json['doctor'] ?? json['doctor_id'];
    String doctorId = json['doctorId']?.toString() ?? '';
    DoctorModel? doctorModel;

    if (doctorObj is Map<String, dynamic>) {
      doctorId = doctorObj['id']?.toString() ??
          doctorObj['_id']?.toString() ??
          doctorId;

      try {
        final parsed = DoctorModel.fromJson(doctorObj);
        doctorModel = parsed;
        doctorId = parsed.id.isNotEmpty ? parsed.id : doctorId;
      } catch (_) {
        String clinicName = '';
        if (doctorObj['doctorProfile'] is Map) {
          clinicName = doctorObj['doctorProfile']['clinicName'] ?? '';
        }

        String photoUrl = AppUrl.getFullUrl(
            doctorObj['profilePhotoUrl']?.toString() ??
                doctorObj['profile_image_url']?.toString());

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
      }
    } else if (doctorObj is String) {
      doctorId = doctorObj;
    }

    final DateTime? scheduledStartRaw = _parseDate(
        json['scheduledStart'] ?? json['scheduled_start']);
    final DateTime? scheduledEndRaw = _parseDate(
        json['scheduledEnd'] ?? json['scheduled_end']);
    final DateTime? createdAtRaw = _parseDate(
        json['createdAt'] ?? json['created_at']);

    DateTime parsedDate = DateTime.now();
    if (scheduledStartRaw != null) {
      parsedDate = scheduledStartRaw;
    } else if (json['date'] != null && json['time'] != null) {
      final combined =
          "${json['date']}T${json['time']}".replaceAll(' ', 'T');
      final raw = DateTime.tryParse(combined);
      parsedDate = raw != null ? raw.toLocal() : DateTime.now();
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
      scheduledStart: scheduledStartRaw,
      scheduledEnd: scheduledEndRaw,
      createdAt: createdAtRaw,
      status: _parseStatus(json['status']),
      type: _parseConsultKind(json),
      reason: json['reason'],
      doctor: doctorModel,
      user: patientModel,
      vitals: json['vitals'],
      prescription: json['prescription'] != null
          ? PrescriptionModel.fromJson(json['prescription'])
          : null,
      isPaid: json['isPaid'] ?? false,
    );
  }

  static AppointmentType _parseConsultKind(Map<String, dynamic> json) {
    final v = json['consultKind'] ??
        json['consulKind'] ??
        json['consultationType'] ??
        json['consultation_kind'];
    if (v == null) return AppointmentType.inPerson;
    final s = v.toString().toUpperCase().replaceAll('-', '_');
    if (s == 'VIDEO' ||
        s == 'ONLINE' ||
        s == 'VIRTUAL' ||
        s == 'TELEMEDICINE') {
      return AppointmentType.online;
    }
    return AppointmentType.inPerson;
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
      case 'canceled': // US spelling from some APIs
        return AppointmentStatus.cancelled;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      default:
        return AppointmentStatus.unconfirmed;
    }
  }

  /// Still shown on doctor "upcoming" dashboard/lists (exclude cancelled/completed).
  bool get isDoctorUpcomingSlot {
    switch (status) {
      case AppointmentStatus.cancelled:
      case AppointmentStatus.completed:
        return false;
      default:
        return true;
    }
  }

  /// Doctor may cancel these; completed/cancelled cannot be cancelled again.
  static bool doctorCanCancel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        return false;
      default:
        return true;
    }
  }

  /// Newest bookings first ([createdAt] descending). Null [createdAt] sorts last.
  static void sortByCreatedAtDescending(List<AppointmentModel> list) {
    list.sort((a, b) {
      final ca = a.createdAt;
      final cb = b.createdAt;
      if (ca == null && cb == null) return 0;
      if (ca == null) return 1;
      if (cb == null) return -1;
      return cb.compareTo(ca);
    });
  }
}
