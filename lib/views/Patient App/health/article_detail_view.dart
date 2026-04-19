import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/models/health_article_model.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:medlink/widgets/custom_network_image.dart';

class ArticleDetailView extends StatelessWidget {
  final HealthArticle article;

  const ArticleDetailView({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Hero(
                    tag: article.coverImageUrl,
                    child: CustomNetworkImage(
                      imageUrl: article.coverImageUrl,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      errorAssetImage: 'assets/No-Image.png',
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildAppBarButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              _buildAppBarButton(
                icon: Icons.bookmark_border_rounded,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              _buildAppBarButton(
                icon: Icons.share_rounded,
                onPressed: () {
                  try {
                    Share.share(
                      "Check out this article on Medlink: ${article.title}\n\n${_stripHtml(article.contentHtml).substring(0, 100)}...",
                      subject: "Health Article",
                    );
                  } catch (e) {
                    debugPrint("Error sharing article: $e");
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(article.publishedAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 20, // Reduced from 24
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20), // Slightly reduced spacing

                  // Posted by (author from DB, else Medlink Admin)
                  Row(
                    children: [
                      _articleAuthorAvatar(article),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.postedByLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              article.postedByLabel == 'Medlink Admin'
                                  ? 'Editorial team'
                                  : 'Posted by author',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Article Content
                  Text(
                    "Overview",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]), // Reduced from 18
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _stripHtml(article.contentHtml),
                    style: TextStyle(
                      fontSize: 14, // Reduced from 16
                      height: 1.7, // Slightly tighter line height
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '5 min read';
    try {
      DateTime date = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return '5 min read';
    }
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  Widget _articleAuthorAvatar(HealthArticle article) {
    final url = article.authorProfilePhotoUrl;
    if (url != null && url.isNotEmpty) {
      return CustomNetworkImage(
        width: 40,
        height: 40,
        shape: BoxShape.circle,
        imageUrl: url,
        placeholderName: article.postedByLabel,
      );
    }
    final isAdmin = article.postedByLabel == 'Medlink Admin';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.12),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Icon(
        isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_rounded,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }

  Widget _buildAppBarButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }


  Widget _buildArticleImagePlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      child: Image.asset(
        'assets/No-Image.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
