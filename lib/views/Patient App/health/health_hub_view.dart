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
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:medlink/core/localization/app_localizations.dart';

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
    
    // Videos/Reels tab is index 3 — always refetch so backend reel changes show up
    if (_tabController.index == 3) {
      if (!viewModel.isLoadingVideos) {
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
          title: widget.isDoctor
              ? context.tr('patient.health_hub.my_articles')
              : context.tr('patient.health_hub.title'),
          automaticallyImplyLeading: widget.showBackButton),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, widget.isDoctor ? 4 : 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: context.tr('patient.health_hub.search_hint'),
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
                tabs: [
                  Tab(text: context.tr('patient.health_hub.tab.articles')),
                  Tab(text: context.tr('patient.health_hub.tab.emergency')),
                  Tab(text: context.tr('patient.health_hub.tab.first_aid')),
                  Tab(text: context.tr('patient.health_hub.tab.videos')),
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
                context.tr('patient.health_hub.upload_article'),
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
        title: Text(context.tr('patient.health_hub.delete_article')),
        content: Text(context.tr('patient.health_hub.delete_article_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('common.delete')),
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
      success
          ? context.tr('patient.health_hub.article_deleted')
          : context.tr('patient.health_hub.article_delete_failed'),
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
                      context.tr('patient.health_hub.no_articles'),
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
                                                context.tr('patient.health_hub.edit_article'),
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
                                                context.tr('patient.health_hub.delete_article'),
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
                                            context.tr(
                                              'patient.health_hub.share_article_message',
                                              params: {'title': article.title},
                                            ));
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
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  context.tr(
                                    'patient.health_hub.posted_by',
                                    params: {'name': article.postedByLabel},
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                context.tr('patient.health_hub.emergency_contacts'),
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              if (viewModel.isLoadingEmergencyNumbers)
                const EmergencyContactsShimmer()
              else if (viewModel.emergencyNumbers.isEmpty)
                NoDataWidget(
                  title: context.tr('patient.health_hub.no_emergency_numbers'),
                  subTitle: context.tr('patient.health_hub.check_back_later'),
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
                                      context.tr('patient.health_hub.tap_to_call'),
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
                context.tr('patient.health_hub.quick_instructions'),
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              if (viewModel.isLoadingQuickInstructions)
                const QuickInstructionShimmer()
              else if (viewModel.quickInstructions.isEmpty)
                NoDataWidget(
                  title: context.tr('patient.health_hub.no_quick_instructions'),
                  subTitle: context.tr('patient.health_hub.check_back_later'),
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
                      context.tr('patient.health_hub.no_first_aid_topics'),
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
                  child: Center(
                    child: NoDataWidget(
                      title: context.tr('patient.health_hub.no_videos_found'),
                      subTitle: context.tr('patient.health_hub.no_videos_subtitle'),
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
                  key: ValueKey('${video.id}|${video.videoUrl}'),
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

enum _ReelSourceType { directVideo, youtube, embeddedWeb }

class _ReelVideoCardState extends State<_ReelVideoCard> {
  VideoPlayerController? _controller;
  YoutubePlayerController? _youtubeController;
  WebViewController? _webViewController;
  _ReelSourceType _sourceType = _ReelSourceType.directVideo;
  bool _loading = true;
  bool _hasError = false;
  bool _webReady = false;

  /// Avoid setState on every position tick — that breaks video texture on many devices
  /// (audio plays, picture frozen). Only snapshot fields that affect layout/chrome.
  bool _lastPlaying = false;
  bool _lastBuffering = false;
  Size _lastVideoSize = Size.zero;
  bool _lastHadError = false;

  void _maybeUpdateUiForControllerValue() {
    final v = _controller?.value;
    if (v == null || !mounted) return;
    final playing = v.isPlaying;
    final buffering = v.isBuffering;
    final sz = v.size;
    final err = v.hasError;
    if (playing == _lastPlaying &&
        buffering == _lastBuffering &&
        sz == _lastVideoSize &&
        err == _lastHadError) {
      return;
    }
    _lastPlaying = playing;
    _lastBuffering = buffering;
    _lastVideoSize = sz;
    _lastHadError = err;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _sourceType = _detectSourceType(widget.video.videoUrl);
    if (widget.isActive) {
      _initPlayer();
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(covariant _ReelVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.videoUrl != widget.video.videoUrl) {
      _disposePlayers();
      _sourceType = _detectSourceType(widget.video.videoUrl);
      if (widget.isActive) {
        _initPlayer();
      } else if (mounted) {
        setState(() {
          _loading = false;
          _hasError = false;
          _webReady = false;
        });
      }
      return;
    }
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        if (_isPlayerReady) {
          _syncPlayState();
        } else {
          _initPlayer();
        }
      } else {
        _pauseActivePlayer();
      }
    } else {
      _syncPlayState();
    }
  }

  Future<void> _initPlayer() async {
    final rawUrl = widget.video.videoUrl.trim();
    if (rawUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
        _webReady = false;
      });
    }

    try {
      switch (_sourceType) {
        case _ReelSourceType.youtube:
          await _initYoutubePlayer(rawUrl);
          break;
        case _ReelSourceType.embeddedWeb:
          await _initWebPlayer(rawUrl);
          break;
        case _ReelSourceType.directVideo:
          try {
            await _initDirectVideoPlayer(rawUrl);
          } catch (_) {
            _sourceType = _ReelSourceType.embeddedWeb;
            await _initWebPlayer(rawUrl);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error initializing reel player for ${widget.video.videoUrl}: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  _ReelSourceType _detectSourceType(String rawUrl) {
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    final host = (uri?.host ?? '').toLowerCase();

    if (YoutubePlayer.convertUrlToId(url) != null ||
        host.contains('youtube.com') ||
        host.contains('youtu.be')) {
      return _ReelSourceType.youtube;
    }

    const embeddedHosts = <String>[
      'instagram.com',
      'instagr.am',
      'tiktok.com',
      'facebook.com',
      'fb.watch',
      'twitter.com',
      'x.com',
      'vimeo.com',
      'dailymotion.com',
    ];

    if (embeddedHosts.any(host.contains)) {
      return _ReelSourceType.embeddedWeb;
    }

    return _ReelSourceType.directVideo;
  }

  String? _videoThumbnailFromUrl() {
    if (widget.video.thumbnailUrl.trim().isNotEmpty) {
      return widget.video.thumbnailUrl.trim();
    }
    final youtubeId = YoutubePlayer.convertUrlToId(widget.video.videoUrl.trim());
    if (youtubeId != null && youtubeId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
    }
    return null;
  }

  String _displaySourceLabel() {
    switch (_sourceType) {
      case _ReelSourceType.youtube:
        return 'YouTube';
      case _ReelSourceType.embeddedWeb:
        return 'External';
      case _ReelSourceType.directVideo:
        return 'Video';
    }
  }

  bool get _isPlayerReady {
    switch (_sourceType) {
      case _ReelSourceType.youtube:
        return _youtubeController != null;
      case _ReelSourceType.embeddedWeb:
        return _webViewController != null;
      case _ReelSourceType.directVideo:
        return _controller != null && _controller!.value.isInitialized;
    }
  }

  Future<void> _initDirectVideoPlayer(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      throw Exception('Invalid direct video url');
    }

    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    await controller.initialize();
    controller.addListener(_maybeUpdateUiForControllerValue);
    controller
      ..setLooping(true)
      ..setVolume(1.0);
    _controller = controller;

    if (widget.isActive) {
      await _startPlayback();
    } else {
      await controller.pause();
    }

    if (!mounted) return;
    final v = controller.value;
    _lastPlaying = v.isPlaying;
    _lastBuffering = v.isBuffering;
    _lastVideoSize = v.size;
    _lastHadError = v.hasError;
    setState(() {
      _loading = false;
      _hasError = false;
    });

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ensurePlayingIfActive());
      });
      unawaited(_retryPlayIfStillPaused());
    }
  }

  Future<void> _initWebPlayer(String rawUrl) async {
    final playableUrl = _embedPlayableUrl(rawUrl);
    final uri = Uri.tryParse(playableUrl);
    if (uri == null) {
      throw Exception('Invalid web video url');
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = false;
              _webReady = true;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = true;
              _webReady = false;
            });
          },
        ),
      )
      ..loadRequest(uri);

    _webViewController = controller;
  }

  Future<void> _initYoutubePlayer(String rawUrl) async {
    final videoId = YoutubePlayer.convertUrlToId(rawUrl);
    if (videoId == null || videoId.isEmpty) {
      throw Exception('Invalid youtube url');
    }

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: true,
        loop: true,
        isLive: false,
        forceHD: false,
        enableCaption: false,
        hideControls: true,
      ),
    );

    _youtubeController = controller;

    if (widget.isActive) {
      controller.play();
    } else {
      controller.pause();
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasError = false;
      _webReady = true;
    });
  }

  String _embedPlayableUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    final host = (uri?.host ?? '').toLowerCase();
    final pathSegments = uri?.pathSegments ?? const <String>[];

    final youtubeId = YoutubePlayer.convertUrlToId(rawUrl);
    if (youtubeId != null && youtubeId.isNotEmpty) {
      return 'https://www.youtube.com/embed/$youtubeId?playsinline=1&rel=0&modestbranding=1';
    }

    if (host.contains('instagram.com') || host.contains('instagr.am')) {
      final normalized = rawUrl.endsWith('/')
          ? rawUrl.substring(0, rawUrl.length - 1)
          : rawUrl;
      return normalized.contains('/embed') ? normalized : '$normalized/embed';
    }

    if (host.contains('tiktok.com')) {
      final videoIndex = pathSegments.indexOf('video');
      if (videoIndex != -1 && videoIndex + 1 < pathSegments.length) {
        return 'https://www.tiktok.com/embed/v2/${pathSegments[videoIndex + 1]}';
      }
    }

    if (host.contains('vimeo.com') && pathSegments.isNotEmpty) {
      final id = pathSegments.lastWhere(
        (segment) => RegExp(r'^\d+$').hasMatch(segment),
        orElse: () => '',
      );
      if (id.isNotEmpty) {
        return 'https://player.vimeo.com/video/$id';
      }
    }

    if (host.contains('dailymotion.com') && pathSegments.length >= 2) {
      if (pathSegments.first == 'video') {
        return 'https://www.dailymotion.com/embed/video/${pathSegments[1]}';
      }
    }

    return rawUrl;
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
    if (!_isPlayerReady) return;
    if (_sourceType == _ReelSourceType.youtube) {
      final c = _youtubeController;
      if (c == null) return;
      if (widget.isActive) {
        c.play();
      } else {
        c.pause();
      }
      if (mounted) setState(() {});
      return;
    }
    if (_sourceType == _ReelSourceType.directVideo) {
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
      return;
    }
  }

  Future<void> _togglePlayPause() async {
    if (_sourceType == _ReelSourceType.embeddedWeb) {
      await _openExternally();
      return;
    }

    if (_sourceType == _ReelSourceType.youtube) {
      final c = _youtubeController;
      if (c == null) return;
      if (c.value.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
      if (mounted) setState(() {});
      return;
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  void _pauseActivePlayer() {
    _controller?.pause();
    _youtubeController?.pause();
  }

  void _disposePlayers() {
    _controller?.removeListener(_maybeUpdateUiForControllerValue);
    _controller?.dispose();
    _controller = null;
    _youtubeController?.dispose();
    _youtubeController = null;
    _webViewController = null;
    _lastPlaying = false;
    _lastBuffering = false;
    _lastVideoSize = Size.zero;
    _lastHadError = false;
    _webReady = false;
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.video.videoUrl.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildPreview() {
    final thumbnail = _videoThumbnailFromUrl();
    if (thumbnail != null && thumbnail.isNotEmpty) {
      return Image.network(
        thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackPreview(),
      );
    }
    return _buildFallbackPreview();
  }

  Widget _buildFallbackPreview() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _sourceType == _ReelSourceType.youtube
                ? Icons.smart_display_rounded
                : Icons.play_circle_outline_rounded,
            color: Colors.white70,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            _displaySourceLabel(),
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMedia() {
    if (_hasError) return _buildErrorContent();
    if (!widget.isActive) return _buildPreview();
    if (_loading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ],
      );
    }

    switch (_sourceType) {
      case _ReelSourceType.youtube:
        return _buildYoutubePlayer();
      case _ReelSourceType.embeddedWeb:
        if (_webViewController == null) return _buildErrorContent();
        return WebViewWidget(controller: _webViewController!);
      case _ReelSourceType.directVideo:
        final c = _controller;
        if (c == null || !c.value.isInitialized) return _buildErrorContent();
        return ClipRect(
          child: ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width > 0 ? c.value.size.width : 1,
                height: c.value.size.height > 0 ? c.value.size.height : 1,
                child: VideoPlayer(c),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildErrorContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPreview(),
        Container(color: Colors.black.withOpacity(0.45)),
      ],
    );
  }

  Widget _buildYoutubePlayer() {
    final controller = _youtubeController;
    if (controller == null) return _buildErrorContent();

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: false,
        onReady: () {
          if (widget.isActive) {
            controller.play();
          }
        },
      ),
      builder: (context, player) {
        return Center(
          child: IgnorePointer(
            child: player,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final youtubePlaying = _youtubeController?.value.isPlaying ?? false;
    final isDirectPlaying = c?.value.isPlaying ?? false;
    final isPlaying =
        _sourceType == _ReelSourceType.youtube ? youtubePlaying : isDirectPlaying;
    final canShowPlayOverlay = widget.isActive &&
        !_loading &&
        !_hasError &&
        (_sourceType == _ReelSourceType.directVideo ||
            _sourceType == _ReelSourceType.youtube) &&
        _isPlayerReady;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          Positioned.fill(child: _buildMainMedia()),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _openExternally,
                  child: const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () {
                    Share.share(
                      context.tr(
                        'patient.health_hub.share_video_message',
                        params: {
                          'title': widget.video.title,
                          'url': widget.video.videoUrl,
                        },
                      ),
                    );
                  },
                  child: const Icon(Icons.share_rounded, color: Colors.white, size: 26),
                ),
              ],
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.28),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Text(
                    _displaySourceLabel(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canShowPlayOverlay)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _togglePlayPause,
                child: AnimatedOpacity(
                  opacity: isPlaying ? 0 : 1,
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
          if (_sourceType == _ReelSourceType.embeddedWeb && widget.isActive && !_webReady)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (_hasError)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white70,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load this video',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _openExternally,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Open link'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

