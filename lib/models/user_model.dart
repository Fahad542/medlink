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
  final String? dateOfBirth;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

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
    this.dateOfBirth,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Some APIs nest patient details inside a 'patient' or 'profile' object
    final profile = json['patient'] is Map<String, dynamic> 
        ? json['patient'] 
        : (json['profile'] is Map<String, dynamic> 
            ? json['profile'] 
            : (json['patient_profile'] is Map<String, dynamic> 
                ? json['patient_profile'] 
                : {}));

    dynamic getField(String key) => json[key] ?? profile[key];

    return UserModel(
      id: getField('id') ?? getField('_id') ?? getField('user_id') ?? '',
      name: getField('name') ?? getField('fullName') ?? getField('full_name') ?? '',
      email: getField('email') ?? '',
      phoneNumber: getField('phoneNumber') ?? getField('phone_number') ?? getField('phone') ?? getField('mobile') ?? getField('contact') ?? '',
      profileImage: getField('profileImage') ?? getField('profile_image') ?? getField('profile_image_url'),
      gender: getField('gender') ?? getField('sex'),
      bloodGroup: getField('bloodGroup') ?? getField('blood_group') ?? getField('blood_type') ?? getField('bloodGroup'),
      age: getField('age') is int ? getField('age') : int.tryParse(getField('age')?.toString() ?? ''),
      weight: getField('weight') is num ? (getField('weight') as num).toDouble() : double.tryParse(getField('weight')?.toString() ?? ''),
      height: getField('height') is num ? (getField('height') as num).toDouble() : double.tryParse(getField('height')?.toString() ?? ''),
      nextAppointment: getField('nextAppointment') ?? getField('next_appointment'),
      dateOfBirth: getField('dateOfBirth') ?? getField('dob') ?? getField('date_of_birth') ?? getField('birth_date') ?? getField('birthDate'),
      address: getField('address') ?? getField('location') ?? getField('residential_address') ?? getField('home_address'),
      emergencyContactName: getField('emergencyContactName') ?? getField('emergency_contact_name'),
      emergencyContactPhone: getField('emergencyContactPhone') ?? getField('emergency_contact_phone'),
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
      'dateOfBirth': dateOfBirth,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }
}
