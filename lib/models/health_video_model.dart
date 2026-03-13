class HealthVideo {
  final int id;
  final String title;
  final String videoUrl;
  final String category;
  final String createdAt;

  HealthVideo({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.category,
    required this.createdAt,
  });

  factory HealthVideo.fromJson(Map<String, dynamic> json) {
    return HealthVideo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      category: json['category'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'videoUrl': videoUrl,
      'category': category,
      'createdAt': createdAt,
    };
  }
}
