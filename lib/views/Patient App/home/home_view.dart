import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:medlink/widgets/sos_button.dart';
import 'package:medlink/views/Patient%20App/Find%20a%20doctor/doctor_list_view.dart';
import 'package:medlink/views/Patient App/consultation/chat_list_view.dart';
import 'package:medlink/views/Patient App/prescription/prescription_view.dart';
import 'package:medlink/views/Patient App/home/category_list_view.dart';
import 'package:medlink/widgets/shimmer_widgets.dart';
import 'package:medlink/views/Patient App/appointment/appointment_list_view.dart';
import 'package:medlink/views/Patient App/health/health_hub_view.dart';
import 'package:medlink/views/Patient%20App/appointment/appointment_viewmodel.dart';
import 'package:medlink/views/Patient%20App/home/home_viewmodel.dart';
import 'package:medlink/models/appointment_model.dart';
import 'package:medlink/widgets/appointment_info_card.dart';
import 'package:medlink/widgets/appointment_list_shimmer.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentViewModel>(context, listen: false)
          .loadUpcomingAppointments();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, homeVM, child) {
          final userVM = Provider.of<UserViewModel>(context); // Session User
          final emergencyVM = Provider.of<EmergencyViewModel>(context);
          final appointmentVM = Provider.of<AppointmentViewModel>(context);

          return Scaffold(
            backgroundColor: Colors.grey.shade50, // Light grey background
            body: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  homeVM.fetchDoctorCategories(),
                  appointmentVM.loadUpcomingAppointments(),
                ]);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Pinned Silver AppBar
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    backgroundColor:
                        Colors.grey.shade50, // Match scaffold background
                    elevation: 0,
                    toolbarHeight: 80,
                    automaticallyImplyLeading: false,
                    titleSpacing: 20,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          // Profile Header
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _buildProfileAvatar(userVM),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Good Morning,",
                                  style: GoogleFonts.inter(
                                    // Ensure Inter
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      userVM.patient?.name ?? "Guest",
                                      style: GoogleFonts.inter(
                                        // Ensure Inter
                                        color: const Color(
                                            0xFF1E293B), // Slate 800
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Image.network(
                                      "https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Hand%20gestures/Waving%20Hand.png",
                                      width: 22, // Slightly refined size
                                      height: 22,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Badged Notification Icon
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChatListView()),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(
                                    10), // Increased padding
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.1)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/msg.png',
                                  width: 24,
                                  height: 24,
                                  color: const Color(0xFF1E293B), // Darker icon
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar (Scrolls away)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: // Professional Search Bar
                          Container(
                        height: 52, // Standard tap height
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white, // White Background
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded,
                                color: Colors.grey[600],
                                size: 24), // Neutral icon
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                style: GoogleFonts.inter(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const DoctorListView()),
                                ),
                                decoration: InputDecoration(
                                  hintText: "Search doctor, specialty...",
                                  hintStyle: GoogleFonts.inter(
                                      color: Colors.grey[400], fontSize: 14),
                                  filled: true,
                                  fillColor: Colors.white, // White Background
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets
                                      .zero, // Ensures vertical centering with Row
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Main Body Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Banner Slider
                          const SizedBox(height: 20),
                          _buildBannerSlider(context),
                          const SizedBox(height: 24),

                          // 2. SOS Button (Upper Position as requested)
                          if (!emergencyVM.isSosActive && homeVM.isSosVisible)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(
                                    top: 8, right: 8), // Space for button
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white, // Changed to white
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                          0.03), // Light shadow for depth
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Medical Emergency?",
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    16, // Restored font size
                                                color: AppColors.accent),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Long Press button for ambulance",
                                            style: GoogleFonts.inter(
                                              color: Colors.grey,
                                              fontSize:
                                                  12, // Restored font size
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 50, // Restored height
                                      width: 80, // Restored width
                                      child: SOSButton(
                                        onPressed: () => _showSOSConfirmation(
                                            context, emergencyVM),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox
                                .shrink(), // Active status moved to Main Screen overlay

                          const SizedBox(height: 24),

                          if (homeVM.categoriesLoading ||
                              homeVM.categories.isNotEmpty) ...[
                            _buildSectionHeader(
                              "Doctors Categories",
                              actionLabel: "See all",
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => CategoryListView(
                                        categories: homeVM.categories)),
                              ),
                            ),
                            _buildDoctorCategories(context),
                            const SizedBox(height: 24),
                          ],

                          // 4. Upcoming Appointment
                          if (appointmentVM.isLoading) ...[
                            _buildSectionHeader(
                              "Upcoming Appointment",
                              actionLabel: "See all",
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AppointmentListView()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const AppointmentListShimmer(itemCount: 1),
                            const SizedBox(height: 15),
                          ] else if (appointmentVM.appointments.any((a) =>
                              a.status == AppointmentStatus.upcoming ||
                              a.status == AppointmentStatus.pending ||
                              a.status == AppointmentStatus.confirmed)) ...[
                            _buildSectionHeader(
                              "Upcoming Appointment",
                              actionLabel: "See all",
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AppointmentListView()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...appointmentVM.appointments
                                .where((a) =>
                                    a.status == AppointmentStatus.upcoming ||
                                    a.status == AppointmentStatus.pending ||
                                    a.status == AppointmentStatus.confirmed)
                                .take(1) // Limit to 1
                                .map((appointment) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child: AppointmentInfoCard(
                                        appointment: appointment,
                                        showConfirmationActions: true,
                                      ),
                                    )),
                            const SizedBox(height: 15),
                          ],

                          // 4. Services Grid
                          _buildSectionHeader("Quick Services"),
                          const SizedBox(height: 15),
                          _buildQuickActionsGrid(context),

                          const SizedBox(height: 24),

                          const SizedBox(height: 100),
                        ],
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
  }

  void _showSOSConfirmation(
      BuildContext context, EmergencyViewModel emergencyVM) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Activate SOS?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to request an ambulance instantly?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        emergencyVM.triggerSos();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text("Yes, Activate"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showHideSOSConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Remove Widget?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "This will hide the SOS shortcut from your home screen.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<HomeViewModel>(context, listen: false)
                            .hideSos();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text("Remove"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {VoidCallback? onAction, String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = Provider.of<HomeViewModel>(context).quickActions;

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];

        return InkWell(
          onTap: () {
            if (action.title.contains("Doctors")) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DoctorListView()));
            } else if (action.title.contains("Prescription")) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrescriptionView()));
            } else if (action.title.contains("Consult")) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatListView()));
            } else if (action.title.contains("Health")) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const HealthHubView(showBackButton: true)));
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: action.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        action.image,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      action.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.2,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      action.subtitle,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 12, // Smaller
                        color: const Color(0xFF64748B), // Slate 500
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Arrow Button (Bottom Right)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    height: 36,
                    width: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_outward_rounded,
                        size: 18, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorCategories(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);
    final categories = homeVM.categories;

    if (homeVM.categoriesLoading) {
      return const CategoryShimmer();
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorListView(
                      initialCategory: cat.name, categoryId: cat.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02), // Very light shadow
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    padding: cat.name == 'Neurologist'
                        ? const EdgeInsets.all(2)
                        : const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                    child: Transform.scale(
                      scale: cat.name == 'Neurologist' ? 1.2 : 1.0,
                      child: Image.asset(
                        cat.image,
                        color: cat.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerSlider(BuildContext context) {
    final homeVM = Provider.of<HomeViewModel>(context);
    final banners = homeVM.banners;

    // Listen to ViewModel changes to trigger animation
    if (_pageController.hasClients &&
        _pageController.page?.round() != homeVM.currentBannerIndex) {
      // Animate only if the difference is valid to prevent jumpiness or loops
      _pageController.animateToPage(
        homeVM.currentBannerIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 160, // Original height for consistency
          child: PageView.builder(
            clipBehavior: Clip.none, // Allow pop-out effect
            controller: _pageController,
            onPageChanged: (index) {
              // Update VM state on manual swipe
              if (index != homeVM.currentBannerIndex) {
                homeVM.setBannerIndex(index);
              }
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerCard(
                context,
                type: banner.type,
                title: banner.title,
                subtitle: banner.subtitle,
                buttonText: banner.buttonText,
                colors: banner.colors,
                shadowColor: banner.shadowColor,
                image: banner.image,
                onTap: () {
                  if (banner.type == 'doctor') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DoctorListView()));
                  } else if (banner.type == 'emergency') {
                    Provider.of<EmergencyViewModel>(context, listen: false)
                        .triggerSos();
                  } else if (banner.type == 'health') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const HealthHubView(showBackButton: true)));
                  }
                },
                isCompact: banner.isCompact,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: homeVM.currentBannerIndex == index ? 24 : 6,
              decoration: BoxDecoration(
                color: homeVM.currentBannerIndex == index
                    ? AppColors.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBannerCard(
    BuildContext context, {
    required String type,
    required String title,
    required String subtitle,
    required String buttonText,
    required List<Color> colors,
    required Color shadowColor,
    required String image,
    required VoidCallback onTap,
    bool isCompact = false,
    double? imageSize,
  }) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.symmetric(horizontal: 5), // Spacing between slides
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior:
            Clip.none, // Always allow pop-out now as all are compact/styled
        children: [
          // Specialized Decorations
          // Original circular decorations for all types
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Padding(
            padding: isCompact
                ? const EdgeInsets.fromLTRB(16, 8, 16, 8) // Compact padding
                : const EdgeInsets.fromLTRB(20, 16, 16, 16), // Standard padding
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: type == "emergency"
                              ? FontWeight.w900
                              : FontWeight.bold,
                          color: Colors.white,
                          height: isCompact ? 1.5 : 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: isCompact ? 10 : 11,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 12),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: shadowColor,
                          padding: isCompact
                              ? const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2) // Compact
                              : const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8), // Refined Standard
                          elevation: type == "emergency" ? 4 : 0,
                          shadowColor:
                              type == "emergency" ? Colors.black26 : null,
                          minimumSize:
                              isCompact ? const Size(0, 24) : const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                isCompact ? 8 : (type == "health" ? 20 : 12)),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: isCompact ? 10 : 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                                type == "emergency"
                                    ? Icons.emergency_rounded
                                    : Icons.arrow_forward_rounded,
                                size: isCompact ? 10 : 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),

          // Image
          Positioned(
            right: type == "emergency" ? -60 : (type == "health" ? -40 : 0),
            bottom: 0,
            child: Image.asset(
              image,
              height: imageSize ??
                  (type == "emergency" ? 190 : (isCompact ? 190 : 130)),
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserViewModel userVM) {
    final profileImage = userVM.patient?.profileImage;
    final hasImage = profileImage != null && profileImage.isNotEmpty;

    // Local file (FileImage path)
    if (hasImage && !profileImage.startsWith('http')) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white,
        backgroundImage: FileImage(File(profileImage)),
      );
    }

    // Network image — use Image.network with errorBuilder
    final fallback = CircleAvatar(
      radius: 26,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person_rounded, color: Colors.grey.shade500, size: 28),
    );

    final imageUrl = hasImage
        ? profileImage
        : "https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=400&auto=format&fit=crop&q=60";

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade200,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
