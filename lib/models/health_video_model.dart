class HealthVideo {
  final int id;
  final String title;
  final String? _description;
  final String videoUrl;
  final String? _thumbnailUrl;
  final String category;
  final String createdAt;
  final int? _viewCount;
  final int? _likeCount;
  final bool? _likedByMe;

  String get description => _description ?? '';
  String get thumbnailUrl => _thumbnailUrl ?? '';
  int get viewCount => _viewCount ?? 0;
  int get likeCount => _likeCount ?? 0;
  bool get likedByMe => _likedByMe ?? false;

  HealthVideo({
    required this.id,
    required this.title,
    String? description,
    required this.videoUrl,
    String? thumbnailUrl,
    required this.category,
    required this.createdAt,
    int? viewCount,
    int? likeCount,
    bool? likedByMe,
  })  : _description = description,
        _thumbnailUrl = thumbnailUrl,
        _viewCount = viewCount,
        _likeCount = likeCount,
        _likedByMe = likedByMe;

  factory HealthVideo.fromJson(Map<String, dynamic> json) {
    return HealthVideo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      category: json['category'] ?? '',
      createdAt: json['createdAt'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      likedByMe: json['likedByMe'] == true,
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
