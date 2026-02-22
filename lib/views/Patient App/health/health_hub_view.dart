import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/health/article_detail_view.dart';
import 'package:medlink/views/Patient App/health/health_hub_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthHubView extends StatefulWidget {
  final bool showBackButton;
  const HealthHubView({super.key, this.showBackButton = false});

  @override
  State<HealthHubView> createState() => _HealthHubViewState();
}

class _HealthHubViewState extends State<HealthHubView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    // First Aid is index 2
    if (_tabController.index == 2) {
      final viewModel = Provider.of<HealthHubViewModel>(context, listen: false);
      if (viewModel.firstAidTopics.isEmpty && !viewModel.isLoadingFirstAid) {
        viewModel.fetchFirstAidTopics();
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(title: "Health Hub", automaticallyImplyLeading: widget.showBackButton),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search articles, guides, symptoms...",
                hintStyle: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.normal, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),

          // 2. Tab Bar
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  spreadRadius: 0,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              padding: const EdgeInsets.all(4),
              isScrollable: false, // Changed to false to fit all 4
              tabs: const [
                Tab(text: "Articles"),
                Tab(text: "Emerg."),
                Tab(text: "First Aid"),
                Tab(text: "Videos"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildArticlesTab(),
                _buildEmergencyTab(),
                _buildFirstAidTab(),
                _buildVideosTab(),
              ],
            ),
          ),
          
          // Bottom padding for main navigation bar
          const SizedBox(height: 20), 
        ],
      ),
    );
  }

  Widget _buildArticlesTab() {
    final articles = [
      {
        "title": "10 Natural Foods to Boost Testosterone and Men's Health",
        "category": "Healthy Lifestyle",
        "date": "November 12, 2025",
        "time": "5 min read",
        "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=2070&auto=format&fit=crop"
      },
      {
        "title": "Understanding Anxiety and Stress Management",
        "category": "Mental Health",
        "date": "October 24, 2025",
        "time": "7 min read",
        "image": "https://images.unsplash.com/photo-1474418397713-7ede21d49118?q=80&w=2053&auto=format&fit=crop"
      },
      {
        "title": "The Ultimate Guide to Superfoods",
        "category": "Nutrition",
        "date": "September 05, 2025",
        "time": "4 min read",
        "image": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=2053&auto=format&fit=crop"
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: articles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final article = articles[index];
        return GestureDetector(
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => ArticleDetailView(article: article)));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Large Image
                ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(0)), // Reference has image at top, but usually card style implies top rounded. Wait, reference image shows card with padding around image? No, image is full width top.
                // Re-checking reference: Image is at the top of the card.
                // BUT, looking closely at the provided image, the image HAS rounded corners on all sides and sits INSIDE the white card with padding?
                // Left/Right/Top have padding? 
                // Let's look: The image has rounded corners. There is white space above and sides? No, it looks like a standard card with image at top.
                // Wait, "10 Natural Foods..." text is below.
                // Let's assume standard "Blog Card" look: Image Top (Rounded), Content Bottom.
                // Actually, let's add some padding around the image like a "contained" look if that's what's implied, but standard is full width.
                // User said "is tarha ki" (like this).
                // I will use full width top image for cleanliness, or maybe padding 12 and rounded image.
                // Let's go with Padding 12 + Rounded Image for a "premium" look.
                
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                     borderRadius: BorderRadius.circular(20),
                     child: Image.network(
                        article['image']!,
                        height: 120, // Reduced height
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                  ),
                ),
              ),
              
              // 2. Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            article['title']!,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.share_outlined, color: Colors.black, size: 20), // Share Icon
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Date & Category & Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date: ${article['date']}",
                              style: GoogleFonts.inter(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                             Text(
                              article['category']!,
                              style: GoogleFonts.inter(
                                color: Colors.grey[500], 
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        
                        // Blue Button
                        Container(
                          height: 44, width: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primary, // Theme Color
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_outward_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )));});

  }

  Widget _buildEmergencyTab() {
    final emergencyContacts = [
      {"name": "Ambulance", "number": "112", "icon": Icons.medical_services_rounded, "color": Colors.red},
      {"name": "Police", "number": "100", "icon": Icons.local_police_rounded, "color": Colors.blue},
      {"name": "Fire Dep.", "number": "101", "icon": Icons.local_fire_department_rounded, "color": Colors.orange},
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Increased bottom padding
      children: [
        Text(
          "Emergency Contacts",
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16), // Reduced padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: emergencyContacts.map((contact) {
              final isLast = contact == emergencyContacts.last;
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10), // Reduced icon padding
                        decoration: BoxDecoration(
                          color: (contact["color"] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(contact["icon"] as IconData, color: contact["color"] as Color, size: 20), // Reduced icon size
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact["name"] as String,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black),
                            ),
                            Text(
                              "Tap to call",
                              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                           final Uri launchUri = Uri(scheme: 'tel', path: contact["number"] as String);
                           if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Smaller radius
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact button
                          minimumSize: Size.zero, 
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.call, size: 14),
                        label: Text(
                          contact["number"] as String,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) const Divider(height: 24, color: Color(0xFFF1F5F9)), // Reduced divider height
                ],
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Quick Instructions",
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        _buildInstructionCard(
          "Unconscious Person",
          "Check breathing. If not breathing, start CPR immediately. Call ambulance.",
          Icons.person_off_rounded,
        ),
        const SizedBox(height: 10),
        _buildInstructionCard(
          "Severe Bleeding",
          "Apply pressure to wound. Elevate injured part.",
          Icons.bloodtype_rounded,
        ),
      ],
    );
  }

  Widget _buildInstructionCard(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(icon, color: Colors.grey[700], size: 24), // Smaller icon
           const SizedBox(width: 12),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   title,
                   style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                 ),
                 const SizedBox(height: 2),
                 Text(
                   description,
                   style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12, height: 1.3),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildFirstAidTab() {
    return Consumer<HealthHubViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingFirstAid) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.firstAidTopics.isEmpty) {
          return Center(
            child: Text(
              "No first aid topics available.",
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Increased bottom padding
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Changed to 3 columns for smaller items
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1, // Reduced height
          ),
          itemCount: viewModel.firstAidTopics.length,
          itemBuilder: (context, index) {
            final topic = viewModel.firstAidTopics[index];
            final style = viewModel.getTopicStyle(topic.title);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (style["color"] as Color).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {}, // Future detail view or expansion
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), // Reduced
                      decoration: BoxDecoration(
                        color: (style["color"] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(style["icon"] as IconData, color: style["color"] as Color, size: 22), // Reduced
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        topic.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12, // Smaller text
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVideosTab() {
    final videos = [
      {
        "title": "5 Minute Morning Yoga",
        "doctor": "Dr. Sarah Johnson",
        "role": "Yoga Instructor",
        "image": "https://images.unsplash.com/photo-1544367563-12123d8965cd?q=80&w=2070&auto=format&fit=crop",
        "likes": "1.2k",
        "comments": "45"
      },
      {
        "title": "Understanding Blood Pressure",
        "doctor": "Dr. Mark Wilson",
        "role": "Cardiologist",
        "image": "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?q=80&w=2070&auto=format&fit=crop",
        "likes": "856",
        "comments": "23"
      },
      {
        "title": "Healthy Diet Tips",
        "doctor": "Dr. Emily Chen", 
        "role": "Nutritionist",
        "image": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=2053&auto=format&fit=crop",
        "likes": "2.5k",
        "comments": "120"
      },
    ];

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100), // Increased bottom padding
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: NetworkImage(video['image']!),
                  fit: BoxFit.cover,
                  opacity: 0.8,
                ),
              ),
          child: Stack(
            children: [
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              
              // Share Button (Top Right)
              Positioned(
                top: 20,
                right: 20,
                child: _buildReelAction(Icons.share, ""),
              ),

              // Content (Bottom)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title']!,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video['role']!,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10), // Reduced space to move title down
                  ],
                ),
              ),
              
              // Play Button Center
              const Center(
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        )));
      },
    );
  }

  Widget _buildReelAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}

