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
  });
  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    String baseUrl = "https://medlink-be-production.up.railway.app";
    
    String getImageUrl(String? path) {
      if (path == null || path.isEmpty) return 'https://i.pravatar.cc/300';
      if (path.startsWith('http')) return path;
      return '$baseUrl$path';
    }

    final profile = json['doctorProfile'] is Map<String, dynamic> 
        ? json['doctorProfile'] 
        : (json['doctor'] is Map<String, dynamic> 
            ? json['doctor'] 
            : (json['profile'] is Map<String, dynamic> 
                ? json['profile'] 
                : (json['user'] is Map<String, dynamic>
                    ? json['user']
                    : {})));

    dynamic getField(String key) => json[key] ?? profile[key];

    String parsedSpecialty = 'General';
    if (json['doctorSpecialties'] is List && (json['doctorSpecialties'] as List).isNotEmpty) {
      var firstSpec = json['doctorSpecialties'][0];
      if (firstSpec['specialty'] is Map && firstSpec['specialty']['name'] != null) {
         parsedSpecialty = firstSpec['specialty']['name'];
      }
    } else {
      parsedSpecialty = getField('specialty') ?? 'General';
    }

    return DoctorModel(
      id: getField('_id')?.toString() ?? getField('id')?.toString() ?? '',
      name: getField('full_name') ?? getField('fullName') ?? getField('name') ?? 'Unknown Doctor',
      specialty: parsedSpecialty,
      hospital: getField('hospital_name') ?? getField('hospital') ?? getField('clinicName') ?? 'Unknown Hospital',
      rating: double.tryParse(getField('rating')?.toString() ?? '0') ?? 0.0,
      imageUrl: getImageUrl(getField('profile_image_url') ?? getField('profilePhotoUrl') ?? getField('imageUrl')),
      isAvailable: getField('isAvailable') ?? getField('isActive') ?? true, // Default to true if missing
      consultationFee: double.tryParse(getField('consultation_fee')?.toString() ?? getField('consultationFee')?.toString() ?? '0') ?? 0.0,
      about: getField('about') ?? getField('bio') ?? 'Experienced specialist dedicated to providing comprehensive care.',
      experience: (getField('experience_years') ?? getField('experience') ?? getField('yearsExperience') ?? 0).toString(),
      location: getField('location') ?? 'Unknown Location',
      availabilityDays: (getField('availabilityDays') as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ["Mon", "Tue", "Wed", "Thu", "Fri"],
      startTime: getField('startTime') ?? "09:00 AM",
      endTime: getField('endTime') ?? "05:00 PM",
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
    };
  }
}
