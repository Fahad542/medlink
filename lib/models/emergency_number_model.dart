class EmergencyNumber {
  final int id;
  final String title;
  final String phone;
  final String createdAt;

  EmergencyNumber({
    required this.id,
    required this.title,
    required this.phone,
    required this.createdAt,
  });

  factory EmergencyNumber.fromJson(Map<String, dynamic> json) {
    return EmergencyNumber(
      id: json['id'],
      title: json['title'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'phone': phone,
      'createdAt': createdAt,
    };
  }
}
