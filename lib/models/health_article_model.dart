import 'package:medlink/core/constants/app_url.dart';

class HealthArticle {
  final int id;
  final String title;
  final String category;
  final String coverImageUrl;
  final String contentHtml;
  final String publishedAt;
  final String createdAt;
  final bool isPublished;

  HealthArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.coverImageUrl,
    required this.contentHtml,
    required this.publishedAt,
    required this.createdAt,
    required this.isPublished,
  });

  factory HealthArticle.fromJson(Map<String, dynamic> json) {
    String imagePath = json['coverImageUrl'] ?? '';
    if (imagePath.isNotEmpty) {
      imagePath = AppUrl.getFullUrl(imagePath);
    }

    return HealthArticle(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      coverImageUrl: imagePath,
      contentHtml: json['contentHtml'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isPublished: json['isPublished'] == true,
    );
  }
}
