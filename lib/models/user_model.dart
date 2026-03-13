import 'package:medlink/core/constants/app_url.dart';

class UserModel {
  final String id;
  final String name;
  final String? email;
  final String phoneNumber;
  final String? profileImage;
  final String? gender;
  final String? bloodGroup;
  final int? age;
  final double? weight;
  final double? height;
  final String? nextAppointment;
  final String? lastAppointmentId;
  final String? dateOfBirth;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? role;
  final bool? isActive;
  final bool? isVerified;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.phoneNumber,
    this.profileImage,
    this.gender,
    this.bloodGroup,
    this.age,
    this.weight,
    this.height,
    this.nextAppointment,
    this.lastAppointmentId,
    this.dateOfBirth,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.role,
    this.isActive,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Some APIs nest patient details inside a 'patient' or 'profile' object
    final profile = json['patient'] is Map<String, dynamic>
        ? json['patient']
        : (json['patientProfile'] is Map<String, dynamic>
            ? json['patientProfile']
            : (json['profile'] is Map<String, dynamic>
                ? json['profile']
                : (json['patient_profile'] is Map<String, dynamic>
                    ? json['patient_profile']
                    : (json['user'] is Map<String, dynamic>
                        ? json['user']
                        : {}))));

    dynamic getField(String key) => json[key] ?? profile[key];

    final profileImageRaw = getField('profileImage') ??
        getField('profilePhotoUrl') ??
        getField('profile_image') ??
        getField('profile_image_url');
        
    String? rawUrl = profileImageRaw?.toString();
    if (rawUrl != null) {
      final lowerPath = rawUrl.toLowerCase();
      if (lowerPath.contains('unsplash.com') ||
          lowerPath.contains('randomuser.me') ||
          lowerPath.contains('pravatar.cc') ||
          lowerPath.contains('placeholder.com') ||
          lowerPath.contains('via.placeholder')) {
        rawUrl = null;
      }
    }
    
    String? profileImageUrl = AppUrl.getFullUrl(rawUrl);

    return UserModel(
      id: getField('id')?.toString() ??
          getField('_id')?.toString() ??
          getField('user_id')?.toString() ??
          '',
      name: getField('name') ??
          getField('fullName') ??
          getField('full_name') ??
          '',
      email: getField('email') ?? '',
      phoneNumber: getField('phoneNumber') ??
          getField('phone_number') ??
          getField('phone') ??
          getField('mobile') ??
          getField('contact') ??
          '',
      profileImage: profileImageUrl,
      gender: getField('gender') ?? getField('sex'),
      bloodGroup: getField('bloodGroup') ??
          getField('blood_group') ??
          getField('blood_type'),
      age: getField('age') is int
          ? getField('age')
          : int.tryParse(getField('age')?.toString() ?? ''),
      weight: getField('weight') is num
          ? (getField('weight') as num).toDouble()
          : (getField('weightKg') is num
              ? (getField('weightKg') as num).toDouble()
              : double.tryParse(getField('weight')?.toString() ??
                  getField('weightKg')?.toString() ??
                  '')),
      height: getField('height') is num
          ? (getField('height') as num).toDouble()
          : (getField('heightCm') is num
              ? (getField('heightCm') as num).toDouble()
              : double.tryParse(getField('height')?.toString() ??
                  getField('heightCm')?.toString() ??
                  '')),
      nextAppointment:
          getField('nextAppointment') ?? getField('next_appointment'),
      lastAppointmentId: getField('lastAppointmentId')?.toString() ??
          getField('last_appointment_id')?.toString(),
      dateOfBirth: getField('dateOfBirth') ??
          getField('dob') ??
          getField('date_of_birth') ??
          getField('birth_date') ??
          getField('birthDate'),
      address: getField('address') ??
          getField('location') ??
          getField('residential_address') ??
          getField('home_address'),
      emergencyContactName: getField('emergencyContactName') ??
          getField('emergency_contact_name'),
      emergencyContactPhone: getField('emergencyContactPhone') ??
          getField('emergency_contact_phone'),
      role: getField('role') as String?,
      isActive: getField('isActive') as bool?,
      isVerified: getField('isVerified') as bool?,
      createdAt: getField('createdAt') as String?,
      updatedAt: getField('updatedAt') as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'age': age,
      'weight': weight,
      'height': height,
      'nextAppointment': nextAppointment,
      'lastAppointmentId': lastAppointmentId,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'role': role,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
