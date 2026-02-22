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
    String baseUrl = "https://peristomatic-hecht-kynlee.ngrok-free.dev";
    
    String getImageUrl(String? path) {
      if (path == null || path.isEmpty) return 'https://i.pravatar.cc/300';
      if (path.startsWith('http')) return path;
      return '$baseUrl$path';
    }

    return DoctorModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['full_name'] ?? json['name'] ?? 'Unknown Doctor',
      specialty: json['specialty'] ?? 'General',
      hospital: json['hospital_name'] ?? json['hospital'] ?? 'Unknown Hospital',
      rating: (json['rating'] ?? 0).toDouble(),
      imageUrl: getImageUrl(json['profile_image_url'] ?? json['imageUrl']),
      isAvailable: json['isAvailable'] ?? true, // Default to true if missing
      consultationFee: (json['consultation_fee'] ?? json['consultationFee'] ?? 0).toDouble(),
      about: json['about'] ?? 'Experienced specialist dedicated to providing comprehensive care.',
      experience: (json['experience_years'] ?? json['experience'] ?? 0).toString(),
      location: json['location'] ?? 'Nairobi',
      availabilityDays: (json['availabilityDays'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ["Mon", "Tue", "Wed", "Thu", "Fri"],
      startTime: json['startTime'] ?? "09:00 AM",
      endTime: json['endTime'] ?? "05:00 PM",
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
