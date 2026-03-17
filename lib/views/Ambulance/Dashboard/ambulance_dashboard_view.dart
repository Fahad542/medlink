import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Ambulance/Dashboard/ambulance_dashboard_view_model.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/emergency_action_dialog.dart';
import 'package:medlink/views/Ambulance/Mission/ambulance_mission_view.dart'
    as medlink_app;
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:medlink/core/constants/app_url.dart';

class AmbulanceDashboardView extends StatefulWidget {
  const AmbulanceDashboardView({super.key});

  @override
  State<AmbulanceDashboardView> createState() => _AmbulanceDashboardViewState();
}

class _AmbulanceDashboardViewState extends State<AmbulanceDashboardView> {
  @override
  void initState() {
    super.initState();
    // Re-fetch profile when this view is initialized
    // But since we use Provider(create:...), the ViewModel init calls it.
    // However, if we navigate back to this tab in a persistent BottomNav,
    // initState might not run again if the widget is kept alive.
    // For standard navigation, it works.
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceDashboardViewModel(),
      child: Consumer<AmbulanceDashboardViewModel>(
        builder: (context, viewModel, child) {
          // Listen for route pop results if we navigate to profile and back?
          // Since Profile is in another tab, this view might not know.
          // But if we use a shared UserViewModel or similar, it would update.
          // Currently using local VM.
          // Let's add a visibility detector or just rely on init.
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Column(
              children: [
                // 1. Stack for Header + Overlapping KPIs
                SizedBox(
                  height: 250, // Reduced height
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gradient Background & Profile Info
                      _buildPremiumHeader(context, viewModel),

                      // Overlapping KPI Card
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 0, // Align to bottom of Stack
                        child: _buildOverlappingKPIs(viewModel),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Spacing after overlap

                // 2. Main Content Area (List or Empty State) with pull-to-refresh
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => viewModel.refreshDashboard(),
                    color: AppColors.primary,
                    child: viewModel.isOnline
                        ? _buildRequestListOrScanning(context, viewModel)
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 270,
                              child: _buildOfflineState(),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumHeader(
      BuildContext context, AmbulanceDashboardViewModel viewModel) {
    final driverName = Provider.of<UserViewModel>(context).driver?.driverName;
    final displayName = (driverName != null && driverName.trim().isNotEmpty)
        ? driverName.trim()
        : 'Driver';
    return Container(
      height: 200, // Reduced height
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00695C), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 56, // Adjusted size
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: viewModel.profilePhotoUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                  AppUrl.getFullUrl(viewModel.profilePhotoUrl)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: viewModel.profilePhotoUrl.isEmpty
                        ? const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person,
                                color: Colors.white, size: 28),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, Driver",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Online Toggle
              Transform.scale(
                scale: 0.9, // Scale down the switch
                child: Switch(
                  value: viewModel.isOnline,
                  onChanged: viewModel.toggleOnlineStatus,
                  activeColor: AppColors.success,
                  activeTrackColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingKPIs(AmbulanceDashboardViewModel viewModel) {
    if (viewModel.isLoadingDashboard) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _buildKPIShimmer()),
              VerticalDivider(color: Colors.grey[200], thickness: 1, width: 24),
              Expanded(child: _buildKPIShimmer()),
            ],
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // Softer shadow
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
          vertical: 16, horizontal: 20), // Increased vertical padding slightly
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildKPIItem(
              "Total Earnings",
              "\$${viewModel.earnings}",
              Icons.account_balance_wallet_rounded,
              Colors.green,
            ),
            VerticalDivider(color: Colors.grey[200], thickness: 1, width: 24),
            _buildKPIItem(
              "Total Trips",
              "${viewModel.completedTrips}",
              Icons.directions_car_rounded,
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestListOrScanning(
      BuildContext context, AmbulanceDashboardViewModel viewModel) {
    if (viewModel.activeRequests.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 270,
          child: _buildScanningState(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: viewModel.activeRequests.length,
      itemBuilder: (context, index) {
        final request = viewModel.activeRequests[index];
        return _buildRequestCard(context, viewModel, request);
      },
    );
  }

  Widget _buildRequestCard(BuildContext context,
      AmbulanceDashboardViewModel viewModel, Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Cleaner shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.red, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "EMERGENCY",
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                request['time'],
                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          Text(
            request['incident'],
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.bold), // Smaller Title
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            request['location'],
            style: GoogleFonts.inter(
                color: Colors.grey[600], fontSize: 11), // Smaller Subtitle
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8), // Reduced spacing
          Row(
            children: [
              _buildCompactInfo(Icons.near_me, request['distance']),
              const SizedBox(width: 12),
              _buildCompactInfo(Icons.medical_services, request['severity']),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[700],
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EmergencyActionDialog(
                          title: "Decline Request",
                          message:
                              "Are you sure you want to decline this emergency request? This action cannot be undone.",
                          actionText: "Decline",
                          actionColor: Colors.grey[700]!,
                          onConfirm: () {
                            viewModel.declineRequest(request['id']);
                            Navigator.pop(context); // Close dialog
                          },
                        ),
                      );
                    },
                    child: const Text("Decline"),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: "ACCEPT",
                  backgroundColor: AppColors.success,
                  height: 32, // Compact height
                  fontSize: 12, // Compact text
                  verticalPadding: 0,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EmergencyActionDialog(
                        title: "Accept Request",
                        message:
                            "Are you sure you want to accept this emergency request? Verify your readiness before proceeding.",
                        actionText: "Accept",
                        actionColor: AppColors.success,
                        onConfirm: () async {
                          // Close dialog first to avoid blocking UI or multiple clicks
                          Navigator.pop(context);

                          // Show loading indicator or handle state if needed
                          final success =
                              await viewModel.acceptRequest(request['id']);

                          if (success && context.mounted) {
                            // Proceed to mission view
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const medlink_app.AmbulanceMissionView()),
                            );
                          } else if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Failed to accept request. It may have been taken."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]), // Decreased size
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulse Animation
          Stack(
            alignment: Alignment.center,
            children: [
              _buildRipple(200, 0.1),
              _buildRipple(150, 0.15),
              _buildRipple(100, 0.2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.radar_rounded,
                    size: 40, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            "Scanning for requests...",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You will be notified of nearby emergencies",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 100), // Spacing for bottom panel
        ],
      ),
    );
  }

  Widget _buildRipple(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_rounded,
                size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          const Text(
            "You are currently Offline",
            style: TextStyle(
              fontSize: 18,
              //color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Go online to start receiving requests",
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
