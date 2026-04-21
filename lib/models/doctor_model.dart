import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_url.dart';

class DoctorModel {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final String imageUrl;
  final bool isAvailable;
  final double consultationFee;
  final String about;
  final String experience;
  final String location;
  final List<String> availabilityDays;
  final String startTime;
  final String endTime;
  final int sessionDuration;
  final List<dynamic> rawAvailability;
  final int totalReviews;
  final int totalPatients;
  final List<Map<String, dynamic>> recentReviews;
  final int patientsCount;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.imageUrl,
    required this.isAvailable,
    required this.consultationFee,
    required this.about,
    this.experience = "5",
    this.location = "Nairobi",
    this.availabilityDays = const ["Mon", "Tue", "Wed", "Thu", "Fri"],
    this.startTime = "09:00 AM",
    this.endTime = "05:00 PM",
    this.sessionDuration = 30,
    this.rawAvailability = const [],
    this.totalReviews = 0,
    this.totalPatients = 0,
    this.recentReviews = const [],
    this.patientsCount = 0,
  });
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    String getImageUrl(String? path) {
      if (path == null || path.trim().isEmpty) return '';
      final lowerPath = path.toLowerCase();
      if (lowerPath.contains('unsplash.com') ||
          lowerPath.contains('randomuser.me') ||
          lowerPath.contains('pravatar.cc') ||
          lowerPath.contains('placeholder.com') ||
          lowerPath.contains('via.placeholder')) {
        return '';
      }
      return AppUrl.getFullUrl(path);
    }

    final profile = json['doctorProfile'] is Map<String, dynamic>
        ? json['doctorProfile']
        : (json['doctor'] is Map<String, dynamic>
            ? json['doctor']
            : (json['profile'] is Map<String, dynamic>
                ? json['profile']
                : (json['user'] is Map<String, dynamic> ? json['user'] : {})));

    dynamic getField(String key) => json[key] ?? profile[key];

    String parsedSpecialty = 'General';
    if (json['doctorSpecialties'] is List &&
        (json['doctorSpecialties'] as List).isNotEmpty) {
      var firstSpec = json['doctorSpecialties'][0];
      if (firstSpec['specialty'] is Map &&
          firstSpec['specialty']['name'] != null) {
        parsedSpecialty = firstSpec['specialty']['name'];
      }
    } else {
      parsedSpecialty = getField('specialty') ?? 'General';
    }

    final rawAvailability = (getField('availability') as List<dynamic>?) ?? [];
    final parsedRecentReviewsRaw = (json['recentReviews'] ??
        json['reviews'] ??
        getField('recentReviews') ??
        getField('reviews')) as List<dynamic>?;
    final parsedRecentReviews = (parsedRecentReviewsRaw ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    double parsedRating =
        double.tryParse(getField('rating')?.toString() ?? '0') ?? 0.0;
    if (parsedRating == 0) {
      parsedRating = double.tryParse(getField('averageRating')?.toString() ??
              getField('avgRating')?.toString() ??
              '0') ??
          0.0;
    }

    int parsedTotalReviews =
        int.tryParse(getField('reviewCount')?.toString() ?? '0') ?? 0;
    if (parsedTotalReviews == 0) {
      parsedTotalReviews = int.tryParse(getField('totalReviews')?.toString() ??
              getField('reviewsCount')?.toString() ??
              '0') ??
          0;
    }
    if (parsedTotalReviews == 0 && parsedRecentReviews.isNotEmpty) {
      parsedTotalReviews = parsedRecentReviews.length;
    }
    if (parsedTotalReviews == 0 && parsedRecentReviewsRaw != null) {
      parsedTotalReviews = parsedRecentReviewsRaw.length;
    }

    int parsedTotalPatients =
        int.tryParse(getField('totalPatients')?.toString() ?? '0') ?? 0;
    if (parsedTotalPatients == 0) {
      parsedTotalPatients = int.tryParse(
              getField('patientsCount')?.toString() ??
                  getField('totalPatientCount')?.toString() ??
                  '0') ??
          0;
    }
    int parsedPatientsCount = int.tryParse(
            getField('patientsCount')?.toString() ??
                getField('totalPatients')?.toString() ??
                getField('patientCount')?.toString() ??
                '0') ??
        0;

    String extractTime(bool isStart) {
      if (rawAvailability.isEmpty) return isStart ? "09:00 AM" : "05:00 PM";
      final first = rawAvailability.first;
      String? val = isStart
          ? (first['morningStart'] ?? first['startTime'])
          : (first['eveningEnd'] ?? first['morningEnd'] ?? first['endTime']);

      if (val == null) return isStart ? "09:00 AM" : "05:00 PM";

      if (val.contains('T')) {
        return DateFormat("hh:mm a").format(DateTime.parse(val).toLocal());
      }

      try {
        final parts = val.split(':');
        final hr = int.parse(parts[0]);
        final mn = int.parse(parts[1]);
        final periods = hr >= 12 ? "PM" : "AM";
        final hrStr = (hr % 12 == 0 ? 12 : hr % 12).toString().padLeft(2, '0');
        return "$hrStr:${mn.toString().padLeft(2, '0')} $periods";
      } catch (e) {
        return val;
      }
    }

    return DoctorModel(
      id: getField('_id')?.toString() ?? getField('id')?.toString() ?? '',
      name: getField('full_name') ??
          getField('fullName') ??
          getField('name') ??
          'Unknown Doctor',
      specialty: parsedSpecialty,
      hospital: getField('hospital_name') ??
          getField('hospital') ??
          getField('clinicName') ??
          'Unknown Hospital',
      rating: parsedRating,
      imageUrl: getImageUrl(getField('profile_image_url') ??
          getField('profilePhotoUrl') ??
          getField('imageUrl')),
      isAvailable: getField('isAvailable') ?? getField('isActive') ?? true,
      consultationFee: double.tryParse(
              getField('consultation_fee')?.toString() ??
                  getField('consultationFee')?.toString() ??
                  '0') ??
          0.0,
      about: getField('about') ??
          getField('bio') ??
          'Experienced specialist dedicated to providing comprehensive care.',
      experience: (getField('experience_years') ??
              getField('experience') ??
              getField('yearsExperience') ??
              getField('experienceInYears') ??
              getField('yearsOfExperience') ??
              0)
          .toString(),
      location: getField('clinicAddress') ??
          getField('location') ??
          'Unknown Location',
      availabilityDays: rawAvailability
          .where((e) =>
              e['morningStart'] != null ||
              e['eveningStart'] != null ||
              e['startTime'] != null)
          .map((e) => {
                0: "Sun",
                1: "Mon",
                2: "Tue",
                3: "Wed",
                4: "Thu",
                5: "Fri",
                6: "Sat"
              }[e['dayOfWeek']])
          .whereType<String>()
          .toSet()
          .toList(),
      startTime: extractTime(true),
      endTime: extractTime(false),
      sessionDuration: int.tryParse(
              getField('sessionDurationMin')?.toString() ??
                  getField('sessionDuration')?.toString() ??
                  '30') ??
          30,
      rawAvailability: rawAvailability,
      totalReviews: parsedTotalReviews,
      totalPatients: parsedTotalPatients,
      recentReviews: parsedRecentReviews,
      patientsCount: parsedPatientsCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'hospital': hospital,
      'rating': rating,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'consultationFee': consultationFee,
      'about': about,
      'experience': experience,
      'location': location,
      'availabilityDays': availabilityDays,
      'startTime': startTime,
      'endTime': endTime,
      'sessionDuration': sessionDuration,
      'rawAvailability': rawAvailability,
      'totalReviews': totalReviews,
      'totalPatients': totalPatients,
      'recentReviews': recentReviews,
      'patientsCount': patientsCount,
    };
  }
}
