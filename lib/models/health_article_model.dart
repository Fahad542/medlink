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
  /// From DB when article is linked to a user (doctor).
  final int? authorId;
  /// Resolved display: author name if [authorId] set and name exists, else "Medlink Admin".
  final String postedByLabel;
  final String? authorProfilePhotoUrl;

  HealthArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.coverImageUrl,
    required this.contentHtml,
    required this.publishedAt,
    required this.createdAt,
    required this.isPublished,
    this.authorId,
    required this.postedByLabel,
    this.authorProfilePhotoUrl,
  });

  factory HealthArticle.fromJson(Map<String, dynamic> json) {
    String imagePath = json['coverImageUrl'] ?? '';
    if (imagePath.isNotEmpty) {
      imagePath = AppUrl.getFullUrl(imagePath);
    }

    final rawAid = json['authorId'];
    final int? authorId = rawAid is int
        ? rawAid
        : int.tryParse(rawAid?.toString() ?? '');

    String postedBy = 'Medlink Admin';
    String? authorPhoto;
    final author = json['author'];
    if (authorId != null &&
        authorId > 0 &&
        author is Map<String, dynamic>) {
      final name = author['fullName']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        postedBy = name;
      }
      final p = author['profilePhotoUrl']?.toString();
      if (p != null && p.trim().isNotEmpty) {
        authorPhoto = AppUrl.getFullUrl(p.trim());
      }
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
      authorId: authorId,
      postedByLabel: postedBy,
      authorProfilePhotoUrl: authorPhoto,
    );
  }
}
