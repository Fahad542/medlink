import 'package:medlink/core/constants/app_url.dart';

class HealthArticle {
  final int id;
  final String title;
  final String category;
  final String coverImageUrl;
  final String contentHtml;
  final String publishedAt;
  final String createdAt;

  HealthArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.coverImageUrl,
    required this.contentHtml,
    required this.publishedAt,
    required this.createdAt,
  });

  factory HealthArticle.fromJson(Map<String, dynamic> json) {
    String imagePath = json['coverImageUrl'] ?? '';
    // Ensure full URL for images if backend gives relative path
    if (imagePath.startsWith('/')) {
      imagePath = AppUrl.baseUrl + imagePath.substring(1);
    } else if (!imagePath.startsWith('http')) {
      imagePath = AppUrl.baseUrl + imagePath;
    }

    return HealthArticle(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      coverImageUrl: imagePath,
      contentHtml: json['contentHtml'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
