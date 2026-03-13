import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient App/health/article_detail_view.dart';
import 'package:medlink/views/Patient App/health/health_hub_viewmodel.dart';
import 'package:medlink/widgets/shimmer_widgets.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'package:medlink/utils/utils.dart';

import '../../../widgets/custom_network_image.dart';
import '../../../widgets/no_data_widget.dart';
import '../../doctor/Articles/upload_article_bottom_sheet.dart';

class HealthHubView extends StatefulWidget {
  final bool showBackButton;
  final bool isDoctor;
  const HealthHubView(
      {super.key, this.showBackButton = false, this.isDoctor = false});

  @override
  State<HealthHubView> createState() => _HealthHubViewState();
}

class _HealthHubViewState extends State<HealthHubView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _expandedFirstAidIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<HealthHubViewModel>(context, listen: false);
      if (viewModel.healthArticles.isEmpty && !viewModel.isLoadingArticles) {
        if (widget.isDoctor) {
          viewModel.fetchDoctorArticles();
        } else {
          viewModel.fetchHealthArticles();
        }
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    
    final viewModel = Provider.of<HealthHubViewModel>(context, listen: false);

    // Emergency tab is index 1
    if (_tabController.index == 1) {
      if (viewModel.emergencyNumbers.isEmpty && !viewModel.isLoadingEmergencyNumbers) {
        viewModel.fetchEmergencyNumbers();
      }
      if (viewModel.quickInstructions.isEmpty && !viewModel.isLoadingQuickInstructions) {
        viewModel.fetchQuickInstructions();
      }
    }
    
    // First Aid is index 2
    if (_tabController.index == 2) {
      if (viewModel.firstAidTopics.isEmpty && !viewModel.isLoadingFirstAid) {
        viewModel.fetchFirstAidTopics();
      }
    }
    
    // Videos/Reels tab is index 3
    if (_tabController.index == 3) {
      if (viewModel.healthVideos.isEmpty && !viewModel.isLoadingVideos) {
        viewModel.fetchHealthVideos();
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
      appBar: CustomAppBar(
          title: widget.isDoctor ? "My Articles" : "Health Hub",
          automaticallyImplyLeading: widget.showBackButton),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, widget.isDoctor ? 4 : 20),
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
          if (!widget.isDoctor)
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
                labelStyle:
                    GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 13),
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
            child: widget.isDoctor
                ? _buildArticlesTab()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildArticlesTab(),
                      _buildEmergencyTab(),
                      _buildFirstAidTab(),
                      _buildVideosTab(),
                    ],
                  ),
          ),
          
        ],
      ),
      floatingActionButton: widget.isDoctor
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const UploadArticleBottomSheet(),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                "Upload Article",
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.normal),
              ),
            )
          : null,
    );
  }

  String _stripHtml(String html) {
    if (html.isEmpty) return "";
    // Simple regex to remove HTML tags
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return html.replaceAll(exp, '').trim();
  }

  Widget _buildArticlesTab() {
    return Consumer<HealthHubViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingArticles) {
          return RefreshIndicator(
            onRefresh: () => viewModel.refreshData(widget.isDoctor),
            child: ListView.separated(
              padding:
                  EdgeInsets.fromLTRB(20, widget.isDoctor ? 0 : 10, 20, 100),
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) => const ArticleShimmer(),
            ),
          );
        }

        if (viewModel.healthArticles.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => viewModel.refreshData(widget.isDoctor),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Text(
                      "No health articles available.",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.refreshData(widget.isDoctor),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            itemCount: viewModel.healthArticles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final article = viewModel.healthArticles[index];
              DateTime date;
              String formattedDate = "5 min read";
              try {
                date = DateTime.parse(article.publishedAt);
                formattedDate = DateFormat('MMM d, yyyy').format(date);
              } catch (e) {
                // fallback
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ArticleDetailView(article: article)));
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image on the Left
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomNetworkImage(
                            imageUrl: article.coverImageUrl,
                            width: 100,
                            height: 110, // Slightly reduced height
                            fit: BoxFit.cover,
                            borderRadius: 16,
                            errorAssetImage: 'assets/No-Image.png',
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info on the Right
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Row: Title + Share Icon
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      article.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Share.share(
                                          "${article.title}\n\nCheck out this article on Medlink!");
                                    },
                                    child: const Icon(Icons.share_outlined,
                                        color: Colors.black87, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _stripHtml(article.contentHtml),
                                maxLines: 1, // Reduced to 1 line to save space
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Bottom Row: Date/Category + Green Arrow Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: GoogleFonts.inter(
                                            color: Colors.grey[500],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          article.category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Green Arrow Button
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_outward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmergencyTab() {
    return Consumer<HealthHubViewModel>(
      builder: (context, viewModel, child) {
        return RefreshIndicator(
          onRefresh: () => viewModel.refreshData(widget.isDoctor),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            children: [
              Text(
                "Emergency Contacts",
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              if (viewModel.isLoadingEmergencyNumbers)
                const EmergencyContactsShimmer()
              else if (viewModel.emergencyNumbers.isEmpty)
                const NoDataWidget(
                  title: "No emergency numbers",
                  subTitle: "Check back later",
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: viewModel.emergencyNumbers.map((contact) {
                      final isLast = contact == viewModel.emergencyNumbers.last;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.call,
                                    color: Colors.red, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.title,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Colors.black),
                                    ),
                                    Text(
                                      "Tap to call",
                                      style: GoogleFonts.inter(
                                          color: Colors.grey[500],
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final Uri launchUri =
                                      Uri(scheme: 'tel', path: contact.phone);
                                  if (await canLaunchUrl(launchUri)) {
                                    await launchUrl(launchUri);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.call, size: 14),
                                label: Text(
                                  contact.phone,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (!isLast)
                            const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                "Quick Instructions",
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              if (viewModel.isLoadingQuickInstructions)
                const QuickInstructionShimmer()
              else if (viewModel.quickInstructions.isEmpty)
                const NoDataWidget(
                  title: "No quick instructions",
                  subTitle: "Check back later",
                )
              else
                ...viewModel.quickInstructions.map((instruction) =>
                    _buildInstructionCard(instruction.title,
                        instruction.content, Icons.medical_services_rounded)),
            ],
          ),
        );
      },
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
          return RefreshIndicator(
              onRefresh: () => viewModel.refreshData(widget.isDoctor),
              child: const FirstAidShimmer());
        }

        if (viewModel.firstAidTopics.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => viewModel.refreshData(widget.isDoctor),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Text(
                      "No first aid topics available.",
                      style: GoogleFonts.inter(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.refreshData(widget.isDoctor),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            itemCount: viewModel.firstAidTopics.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final topic = viewModel.firstAidTopics[index];
              final style = viewModel.getTopicStyle(topic.title);

              final isExpanded = _expandedFirstAidIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey(topic.id),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedFirstAidIndex = expanded ? index : null;
                      });
                    },
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (style["color"] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        style["icon"] as IconData,
                        color: style["color"] as Color,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      topic.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: !isExpanded
                        ? Text(
                            topic.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                    trailing: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xff009b8b).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xff009b8b),
                        size: 20,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          topic.content,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    return Consumer<HealthHubViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingVideos) {
          return RefreshIndicator(
              onRefresh: () => viewModel.refreshData(widget.isDoctor),
              child: const VideoReelsShimmer());
        }

        if (viewModel.healthVideos.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => viewModel.refreshData(widget.isDoctor),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: const Center(
                    child: NoDataWidget(
                      title: "No Videos Found",
                      subTitle:
                          "We're currently preparing informational videos for you. Please check back later!",
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.refreshData(widget.isDoctor),
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: viewModel.healthVideos.length,
            itemBuilder: (context, index) {
              final video = viewModel.healthVideos[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      image: DecorationImage(
                        image: NetworkImage(
                            'https://picsum.photos/400/800?random=$index'),
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
                          child: GestureDetector(
                            onTap: () {
                              Share.share(
                                  'Check out this health video: ${video.title}\n${video.videoUrl}');
                            },
                            child: _buildReelAction(Icons.share, ""),
                          ),
                        ),

                        // Content (Bottom)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  video.category,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),

                        // Play Button Center
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              if (video.videoUrl.isNotEmpty) {
                                final Uri url = Uri.parse(video.videoUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                } else {
                                  if (context.mounted) {
                                    Utils.toastMessage(
                                        context, "Could not launch video URL",
                                        isError: true);
                                  }
                                }
                              } else {
                                Utils.toastMessage(
                                    context, "Video URL is missing",
                                    isError: true);
                              }
                            },
                            child: const Icon(
                              Icons.play_circle_outline_rounded,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
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

