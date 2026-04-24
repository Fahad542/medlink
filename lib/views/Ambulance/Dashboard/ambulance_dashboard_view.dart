import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Ambulance/Dashboard/ambulance_dashboard_view_model.dart';
import 'package:medlink/views/Ambulance/Ambulance%20main/ambulance_main_view_model.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/views/Ambulance/Mission/ambulance_mission_view.dart'
    as medlink_app;
import 'package:medlink/views/services/session_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medlink/services/google_maps_service.dart';

import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/utils/utils.dart';

class AmbulanceDashboardView extends StatefulWidget {
  const AmbulanceDashboardView({super.key});

  @override
  State<AmbulanceDashboardView> createState() => _AmbulanceDashboardViewState();
}

class _AmbulanceDashboardViewState extends State<AmbulanceDashboardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanRippleController;
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _coordLabel(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Not available';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  static LatLngBounds _boundsForPoints(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _openRequestMapDecisionSheet(
    BuildContext context,
    AmbulanceDashboardViewModel viewModel,
    Map<String, dynamic> request,
  ) async {
    final pickupLat = _toDouble(request['lat']);
    final pickupLng = _toDouble(request['lng']);
    final dropLat = _toDouble(request['destinationLat']);
    final dropLng = _toDouble(request['destinationLng']);
    final pickup = (pickupLat != null && pickupLng != null)
        ? LatLng(pickupLat, pickupLng)
        : null;
    final drop = (dropLat != null && dropLng != null)
        ? LatLng(dropLat, dropLng)
        : null;
    final points = <LatLng>[
      if (pickup != null) pickup,
      if (drop != null) drop,
    ];
    final hasMapPoints = points.isNotEmpty;
    final markers = <Marker>{
      if (pickup != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      if (drop != null)
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          infoWindow: const InfoWindow(title: 'Drop-off'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
    };
    List<LatLng> routePoints = [];
    String? routeDurationText;
    if (pickup != null && drop != null) {
      try {
        final route = await GoogleMapsService.getRouteCoordinates(
          pickup,
          drop,
        );
        if (route != null && route['points'] is List<LatLng>) {
          routePoints = List<LatLng>.from(route['points'] as List<LatLng>);
          routeDurationText = route['durationText']?.toString();
        }
      } catch (_) {}
    }
    if (!mounted || !context.mounted) return;
    final effectiveLinePoints =
        routePoints.length >= 2 ? routePoints : (pickup != null && drop != null ? [pickup, drop] : <LatLng>[]);
    final polylines = <Polyline>{
      if (effectiveLinePoints.length >= 2)
        Polyline(
          polylineId: const PolylineId('pickup_drop_line'),
          points: effectiveLinePoints,
          color: AppColors.primary,
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
    };

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (pageContext) {
          var processing = false;
          return StatefulBuilder(
            builder: (ctx, setStateSheet) {
              Future<void> handleAccept() async {
                if (processing) return;
                setStateSheet(() => processing = true);
                final mainVm = Provider.of<AmbulanceMainViewModel>(
                  context,
                  listen: false,
                );
                try {
                  if (mainVm.hasActiveTrip) {
                    if (context.mounted) {
                      Utils.toastMessage(
                        context,
                        'You already have an active trip. Complete it before accepting another request.',
                        isError: true,
                      );
                    }
                    return;
                  }
                  final success = await viewModel.acceptRequest(request['id']);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    await mainVm.checkActiveTrip(startPolling: false);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const medlink_app.AmbulanceMissionView(),
                      ),
                    );
                  } else if (!success && context.mounted) {
                    Utils.toastMessage(
                      context,
                      "Failed to accept request. It may have been taken.",
                      isError: true,
                    );
                  }
                } finally {
                  if (ctx.mounted) setStateSheet(() => processing = false);
                }
              }

              Future<void> handleDecline() async {
                if (processing) return;
                setStateSheet(() => processing = true);
                try {
                  await viewModel.declineRequest(request['id']);
                  if (context.mounted) Navigator.pop(context);
                } finally {
                  if (ctx.mounted) setStateSheet(() => processing = false);
                }
              }

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Route Preview'),
                  backgroundColor: Colors.white,
                ),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      children: [
                        Row(
                      children: [
                        const Icon(Icons.map_outlined, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Check route before decision',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (routeDurationText != null &&
                            routeDurationText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              routeDurationText,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (pickup != null && drop != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Showing shortest road route',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                        const SizedBox(height: 10),
                        Expanded(
                          child: hasMapPoints
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: pickup ?? drop ?? const LatLng(0, 0),
                              zoom: 14,
                            ),
                            markers: markers,
                            polylines: polylines,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            onMapCreated: (c) async {
                              await Future<void>.delayed(
                                  const Duration(milliseconds: 120));
                              if (points.length == 1) {
                                c.animateCamera(
                                  CameraUpdate.newLatLngZoom(points.first, 15),
                                );
                              } else if (points.length > 1) {
                                c.animateCamera(
                                  CameraUpdate.newLatLngBounds(
                                    _boundsForPoints(points),
                                    64,
                                  ),
                                );
                              }
                            },
                                  ),
                                )
                              : Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'Map coordinates unavailable',
                                    style: GoogleFonts.inter(color: Colors.grey[700]),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        _routeInfoTile(
                      icon: Icons.place_outlined,
                      iconColor: Colors.red,
                      title: 'Pickup',
                      subtitle:
                          request['location']?.toString() ?? 'Location unavailable',
                      coord: _coordLabel(pickupLat, pickupLng),
                    ),
                        const SizedBox(height: 8),
                        _routeInfoTile(
                      icon: Icons.flag_outlined,
                      iconColor: Colors.blue,
                      title: 'Drop-off',
                      subtitle: (drop != null)
                          ? 'Selected on map by patient'
                          : 'Drop location not shared',
                      coord: _coordLabel(dropLat, dropLng),
                    ),
                        const SizedBox(height: 12),
                        Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: processing ? null : handleDecline,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[800],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: processing ? null : handleAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: processing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Accept',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _routeInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String coord,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  coord,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scanRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    // Re-fetch profile when this view is initialized
    // But since we use Provider(create:...), the ViewModel init calls it.
    // However, if we navigate back to this tab in a persistent BottomNav,
    // initState might not run again if the widget is kept alive.
    // For standard navigation, it works.
  }

  @override
  void dispose() {
    _scanRippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AmbulanceDashboardViewModel>(
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
              "${viewModel.currency} ${viewModel.earnings}",
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
    final remaining = viewModel.remainingAcceptTimeForRequest(request);
    final progress =
        viewModel.acceptProgressFractionFor(request).clamp(0.0, 1.0);
    final countdownColor = progress < 0.2
        ? Colors.red
        : (progress < 0.45 ? Colors.orange : AppColors.primary);

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
            request['location']?.toString() ?? '',
            style: GoogleFonts.inter(
                color: Colors.grey[600], fontSize: 11), // Smaller Subtitle
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Accept within',
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    AmbulanceDashboardViewModel.formatCountdownMmSs(remaining),
                    style: GoogleFonts.inter(
                      color: countdownColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(countdownColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          Row(
            children: [
              Icon(Icons.near_me, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request['distance']?.toString() ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _openRequestMapDecisionSheet(context, viewModel, request),
              icon: const Icon(Icons.map_outlined, size: 16),
              label: Text(
                "View pickup & drop on map",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withOpacity(0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
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
                    onPressed: () =>
                        _openRequestMapDecisionSheet(context, viewModel, request),
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
                  onPressed: () =>
                      _openRequestMapDecisionSheet(context, viewModel, request),
                ),
              ),
            ],
          ),
        ],
      ),
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
              _buildRipple(220, 0.30, 0.00),
              _buildRipple(175, 0.42, 0.24),
              _buildRipple(130, 0.55, 0.48),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.42),
                      blurRadius: 26,
                      spreadRadius: 8,
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

  Widget _buildRipple(double size, double opacity, double phase) {
    return AnimatedBuilder(
      animation: _scanRippleController,
      builder: (context, child) {
        final t = (_scanRippleController.value + phase) % 1.0;
        final scale = 0.55 + (0.75 * t);
        final visibleOpacity = (1.0 - t) * opacity;
        return Opacity(
          opacity: visibleOpacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withOpacity(opacity),
            width: 2.4,
          ),
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
