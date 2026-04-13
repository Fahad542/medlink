import 'dart:async';

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
import 'package:video_player/video_player.dart';

import 'package:medlink/utils/utils.dart';
import 'package:medlink/models/health_article_model.dart';
import 'package:medlink/models/health_video_model.dart';

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
  late final PageController _videoPageController;
  int? _expandedFirstAidIndex;
  int _activeVideoIndex = 0;
  final Set<int> _viewRecordedVideoIds = <int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _videoPageController = PageController();
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
    _videoPageController.dispose();
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

  void _openEditArticleSheet(HealthArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadArticleBottomSheet(article: article),
    );
  }

  Future<void> _confirmDeleteArticle(HealthArticle article) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text('Are you sure you want to delete this article?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    final vm = Provider.of<HealthHubViewModel>(context, listen: false);
    final success = await vm.deleteArticle(article.id);
    if (!mounted) return;
    Utils.toastMessage(
      context,
      success ? 'Article deleted successfully' : 'Failed to delete article',
      isError: !success,
    );
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
                                  if (widget.isDoctor)
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      icon: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _openEditArticleSheet(article);
                                        } else if (value == 'delete') {
                                          _confirmDeleteArticle(article);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                                child: const Icon(
                                                  Icons.edit_rounded,
                                                  color: AppColors.primary,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Edit Article',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: const Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(7),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_forever_rounded,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Delete Article',
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
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

        if (_activeVideoIndex >= viewModel.healthVideos.length) {
          _activeVideoIndex = 0;
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.refreshData(widget.isDoctor),
          child: PageView.builder(
            controller: _videoPageController,
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: viewModel.healthVideos.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _activeVideoIndex = index;
                });
              }
            },
            itemBuilder: (context, index) {
              final video = viewModel.healthVideos[index];
              final isActive = index == _activeVideoIndex;
              if (isActive && !_viewRecordedVideoIds.contains(video.id)) {
                _viewRecordedVideoIds.add(video.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Provider.of<HealthHubViewModel>(context, listen: false)
                      .recordReelView(video.id);
                });
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                child: _ReelVideoCard(
                  key: ValueKey(video.id),
                  video: video,
                  isActive: isActive,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReelVideoCard extends StatefulWidget {
  const _ReelVideoCard({
    super.key,
    required this.video,
    required this.isActive,
  });

  final HealthVideo video;
  final bool isActive;

  @override
  State<_ReelVideoCard> createState() => _ReelVideoCardState();
}

class _ReelVideoCardState extends State<_ReelVideoCard> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant _ReelVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.videoUrl != widget.video.videoUrl) {
      _disposeController();
      _initPlayer();
      return;
    }
    _syncPlayState();
  }

  Future<void> _initPlayer() async {
    if (widget.video.videoUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
      return;
    }
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      await controller.initialize();
      controller.addListener(_onControllerUpdated);
      controller
        ..setLooping(true)
        ..setVolume(1.0);
      _controller = controller;
      if (widget.isActive) {
        await _startPlayback();
      } else {
        await controller.pause();
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = false;
        });
      }
      if (widget.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_ensurePlayingIfActive());
        });
        unawaited(_retryPlayIfStillPaused());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _startPlayback() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || !mounted) return;
    try {
      await c.play();
    } catch (_) {
      // Surface / audio focus can fail once; retry handles it.
    }
    if (mounted) setState(() {});
  }

  Future<void> _ensurePlayingIfActive() async {
    final c = _controller;
    if (!mounted || c == null || !c.value.isInitialized || !widget.isActive) {
      return;
    }
    if (!c.value.isPlaying) {
      await _startPlayback();
    }
  }

  /// Some devices (e.g. Mediatek) need a short delay before play() sticks.
  Future<void> _retryPlayIfStillPaused() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || !widget.isActive) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (!c.value.isPlaying) {
      await _startPlayback();
    }
  }

  void _syncPlayState() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (widget.isActive) {
      unawaited(_startPlayback());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ensurePlayingIfActive());
      });
    } else {
      unawaited(c.pause());
    }
  }

  void _onControllerUpdated() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _togglePlayPause() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  void _disposeController() {
    _controller?.removeListener(_onControllerUpdated);
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (!_hasError && c != null && c.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else if ((widget.video.thumbnailUrl).isNotEmpty)
            Image.network(
              widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Share.share(
                  'Check out this health video: ${widget.video.title}\n${widget.video.videoUrl}',
                );
              },
              child: const Icon(Icons.share_rounded, color: Colors.white, size: 26),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 110,
            child: Column(
              children: [
                const Icon(Icons.visibility_rounded, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  '${widget.video.viewCount}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Icon(
                  widget.video.likedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.video.likeCount}',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 70,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.video.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.video.category,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          if (!_loading && !_hasError)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: AnimatedOpacity(
                  opacity: (c?.value.isPlaying ?? false) ? 0 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white70,
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),
          if (_hasError)
            const Center(
              child: Icon(
                Icons.broken_image_rounded,
                color: Colors.white70,
                size: 44,
              ),
            ),
        ],
      ),
    );
  }
}

