import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';

class ArticleDetailView extends StatelessWidget {
  final Map<String, String> article;

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
                    tag: article['image']!,
                    child: Image.network(
                      article['image']!,
                      fit: BoxFit.cover,
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
                onPressed: () {},
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
                          article['category']!,
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
                        article['time']!,
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    article['title']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Author Info
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=2070&auto=format&fit=crop'),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Dr. Sarah Smith",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "Medical Editor",
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Article Content (Mock)
                  Text(
                    "Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Maintaing a healthy heart is crucial for overall well-being. "
                    "Cardiovascular diseases are the leading cause of death globally, but many can be prevented with simple lifestyle changes.\n\n"
                    "Here are 5 essential tips to keep your heart strong:\n\n"
                    "1. Eat a Heart-Healthy Diet\n"
                    "Focus on fruits, vegetables, whole grains, and lean proteins. Limit sodium, sugar, and saturated fats. Foods rich in omega-3 fatty acids, like salmon and flaxseeds, are excellent for heart health.\n\n"
                    "2. Get Active\n"
                    "Aim for at least 150 minutes of moderate-intensity exercise per week. Activities like brisk walking, swimming, or cycling can significantly lower your risk of heart disease.\n\n"
                    "3. Manage Stress\n"
                    "Chronic stress can increase blood pressure and strain your heart. Practice relaxation techniques such as meditation, deep breathing exercises, or yoga.\n\n"
                    "4. Quit Smoking\n"
                    "Smoking damages your blood vessels and reduces the oxygen in your blood. Quitting is the single best thing you can do for your heart.\n\n"
                    "5. Get Quality Sleep\n"
                    "Poor sleep has been linked to high blood pressure and heart disease. Aim for 7-9 hours of quality sleep each night.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
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
}
