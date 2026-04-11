class HealthVideo {
  final int id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String category;
  final int viewCount;
  final int likeCount;
  final String createdAt;
  final bool likedByMe;

  HealthVideo({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.category,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.createdAt,
    this.likedByMe = false,
  });

  factory HealthVideo.fromJson(Map<String, dynamic> json) {
    return HealthVideo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      category: json['category'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      likedByMe: json['likedByMe'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'createdAt': createdAt,
      'likedByMe': likedByMe,
    };
  }
}
