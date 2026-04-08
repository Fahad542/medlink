import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/models/ambulance_model.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/call/call_view_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/views/Patient App/emergency/emergency_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medlink/services/google_maps_service.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';

class AmbulanceTrackingView extends StatefulWidget {
  final AmbulanceModel ambulance;

  const AmbulanceTrackingView({super.key, required this.ambulance});

  @override
  State<AmbulanceTrackingView> createState() => _AmbulanceTrackingViewState();
}

class _AmbulanceTrackingViewState extends State<AmbulanceTrackingView>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final Completer<GoogleMapController> _mapController = Completer();
  bool hasInitialFit = false;
  bool _isNavigatingBack = false;
  bool _reviewPromptShown = false;

  List<LatLng> _routePoints = [];
  LatLng? _lastRoutedTargetPos;
  LatLng? _lastRoutedDriverPos;
  bool _isFetchingRoute = false;
  String _etaText = "";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Future<void> _fitCamera(List<LatLng> points) async {
    if (!_mapController.isCompleted || points.isEmpty) return;
    final controller = await _mapController.future;
    if (points.length == 1) {
      await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 14));
    } else {
      LatLngBounds bounds = _boundsFromLatLngList(points);
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
        if (latLng.longitude < y0) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  void _updateRouteIfNeeded(LatLng driverPos, LatLng targetPos) async {
    if (_isFetchingRoute) return;
    
    // Calculate distance moved by driver to avoid too many API calls
    double distanceMoved = 0;
    if (_lastRoutedDriverPos != null) {
      distanceMoved = Geolocator.distanceBetween(
        _lastRoutedDriverPos!.latitude,
        _lastRoutedDriverPos!.longitude,
        driverPos.latitude,
        driverPos.longitude,
      );
    }

    // Fetch if:
    // 1. No route yet
    // 2. Target changed (e.g. from pickup to dropoff)
    // 3. Driver moved significantly (more than 50 meters)
    bool shouldFetch = _routePoints.isEmpty || 
          _lastRoutedTargetPos == null || 
          _lastRoutedTargetPos!.latitude != targetPos.latitude || 
          _lastRoutedTargetPos!.longitude != targetPos.longitude ||
          distanceMoved > 50;
    
    if (shouldFetch) {
      _isFetchingRoute = true;
      final routeData = await GoogleMapsService.getRouteCoordinates(driverPos, targetPos);
      if (routeData != null && mounted) {
        setState(() {
           _routePoints = routeData['points'];
           _etaText = routeData['durationText'];
           _lastRoutedTargetPos = targetPos;
           _lastRoutedDriverPos = driverPos;
        });
      }
      _isFetchingRoute = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyVM = Provider.of<EmergencyViewModel>(context);
    final ambulance = emergencyVM.assignedAmbulance ?? widget.ambulance;
    final etaText = _etaText.isNotEmpty ? _etaText : (emergencyVM.sosEtaText.isNotEmpty
        ? emergencyVM.sosEtaText
        : ambulance.estimatedArrival);

    final trip = emergencyVM.activeTrip;
    final latestLocation = trip?['latestLocation'] is Map
        ? Map<String, dynamic>.from(trip?['latestLocation'])
        : null;
    
    // Driver current position
    final driverLat = _toDouble(latestLocation?['lat']) ?? _toDouble(emergencyVM.assignedAmbulance?.currentLat);
    final driverLng = _toDouble(latestLocation?['lng']) ?? _toDouble(emergencyVM.assignedAmbulance?.currentLng);

    // Pickup Pos (where the patient is)
    final pickupLat = _toDouble(trip?['pickupLat']) ?? _toDouble(trip?['sos']?['latitude']);
    final pickupLng = _toDouble(trip?['pickupLng']) ?? _toDouble(trip?['sos']?['longitude']);
    
    // Dropoff Pos (destination)
    final dropoffLat = _toDouble(trip?['dropoffLat']) ?? _toDouble(trip?['sos']?['destinationLat']);
    final dropoffLng = _toDouble(trip?['dropoffLng']) ?? _toDouble(trip?['sos']?['destinationLng']);

    final status = emergencyVM.sosStatus?.toUpperCase() ?? '';
    final isTransporting = status == 'ARRIVED' || status == 'TRANSPORTING' || status == 'IN_PROGRESS';

    LatLng? driverPos = (driverLat != null && driverLng != null) ? LatLng(driverLat, driverLng) : null;
    LatLng? pickupPos = (pickupLat != null && pickupLng != null) ? LatLng(pickupLat, pickupLng) : null;
    LatLng? dropoffPos = (dropoffLat != null && dropoffLng != null) ? LatLng(dropoffLat, dropoffLng) : null;

    // Determine target based on status (Indrive style)
    final targetPos = (isTransporting && dropoffPos != null) ? dropoffPos : (pickupPos ?? dropoffPos);

    if (driverPos != null && targetPos != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateRouteIfNeeded(driverPos, targetPos);
      });
    }

    final markers = <Marker>{
      if (driverPos != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      if (pickupPos != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPos,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (dropoffPos != null)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };

    final polylines = <Polyline>{
      if (driverPos != null && targetPos != null)
        Polyline(
          polylineId: PolylineId('route_${targetPos.latitude}_${targetPos.longitude}'),
          points: _routePoints.isEmpty ? [driverPos, targetPos] : _routePoints,
          color: AppColors.primary,
          width: 6,
        ),
    };

    final cameraTarget =
        driverPos ?? pickupPos ?? dropoffPos ?? const LatLng(0, 0);

    // Safe auto-close if trip is completed
    if (!emergencyVM.isSosActive) {
      if (!_isNavigatingBack) {
        _isNavigatingBack = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final tripId = emergencyVM.lastCompletedTripId;
            if (!_reviewPromptShown && tripId != null && tripId.isNotEmpty) {
              _reviewPromptShown = true;
              _showDriverReviewBottomSheet(context, tripId);
            } else {
              Navigator.of(context).pop();
            }
          }
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_mapController.isCompleted) return;
      final controller = await _mapController.future;
      final points = <LatLng>[
        if (driverPos != null) driverPos,
        if (targetPos != null) targetPos,
      ];
      if (points.isEmpty) return;

      if (!hasInitialFit) {
        _fitCamera(points);
        hasInitialFit = true;
      } else if (driverPos != null) {
        controller.animateCamera(CameraUpdate.newLatLng(driverPos));
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          const Color(0xFF212529), // Dark background for status bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: cameraTarget, zoom: 14),
            onMapCreated: (c) {
              if (!_mapController.isCompleted) _mapController.complete(c);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: polylines,
          ),

          // 2. Premium Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slim Handle
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Removed SizedBox spacer

                      // ETA Header (Refined)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ARRIVING IN",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11, // Reduced
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2), // Tighter spacing
                              Text(
                                etaText,
                                style: const TextStyle(
                                  fontSize: 24, // Reduced from 32
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFECFDF5), // Very light green
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text(
                                  "ON TIME",
                                  style: TextStyle(
                                    color: Color(0xFF10B981), // Emerald 500
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Collapsible Content
                      AnimatedCrossFade(
                        firstChild: Column(
                          children: [
                            const SizedBox(height: 24),
                            Divider(color: Colors.grey[100], height: 1),
                            const SizedBox(height: 24),

                            // Driver & Vehicle Info (Cleaner look)
                            Row(
                              children: [
                                Container(
                                  height: 50, // Reduced from 64
                                  width: 50, // Reduced from 64
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                    image: DecorationImage(
                                      image: NetworkImage(widget.ambulance
                                              .profilePhotoUrl.isNotEmpty
                                          ? AppUrl.getFullUrl(
                                              ambulance.profilePhotoUrl)
                                          : 'https://img.freepik.com/free-photo/portrait-smiling-male-doctor_171337-1532.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            ambulance.driverName,
                                            style: const TextStyle(
                                              fontSize: 16, // Reduced from 18
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified,
                                              size: 16,
                                              color: AppColors.primary)
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Paramedic • ${ambulance.plateNumber}",
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: Colors.amber, size: 16),
                                          const SizedBox(width: 2),
                                          const Text(
                                            "4.9",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13),
                                          ),
                                          Text(
                                            " (112)",
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Action Buttons (Modern)
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      final userVM = Provider.of<UserViewModel>(
                                          context,
                                          listen: false);
                                      final currentUserId = userVM
                                              .loginSession?.data?.user?.id
                                              ?.toString() ??
                                          "0";
                                      final emergencyVM =
                                          Provider.of<EmergencyViewModel>(
                                              context,
                                              listen: false);
                                      final sosId = emergencyVM.sosId;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatView(
                                            recipientName:
                                                widget.ambulance.driverName,
                                            doctorId: widget.ambulance.id,
                                            patientId: currentUserId,
                                            sosId: sosId,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Image.asset("assets/Icons/chat.png",
                                        width: 22, height: 22),
                                    label: const Text("Message"),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFF1F5F9), // Slate 100
                                      foregroundColor:
                                          const Color(0xFF475569), // Slate 600
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final driverId =
                                          int.tryParse(widget.ambulance.id);
                                      if (driverId != null) {
                                        Provider.of<CallViewModel>(context,
                                                listen: false)
                                            .initiateCall(
                                                context,
                                                driverId,
                                                widget.ambulance.driverName,
                                                widget
                                                    .ambulance.profilePhotoUrl);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Driver contact not available")),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.phone_rounded,
                                        size: 22),
                                    label: const Text("Call Driver"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                          0xFF10B981), // Emerald 500
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      elevation: 0,
                                      shadowColor: const Color(0xFF10B981)
                                          .withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        secondChild: const SizedBox(width: double.infinity),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCallDriverBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFF212529),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 60),
              // Driver Avatar with Pulse
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: DecorationImage(
                    image: NetworkImage(widget
                            .ambulance.profilePhotoUrl.isNotEmpty
                        ? AppUrl.getFullUrl(widget.ambulance.profilePhotoUrl)
                        : 'https://img.freepik.com/free-photo/portrait-smiling-male-doctor_171337-1532.jpg'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Driver Name & Status
              Text(
                widget.ambulance.driverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Calling ${widget.ambulance.phoneNumber}...",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),

              const Spacer(),

              // Action Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallActionButton(
                        Icons.mic_off_rounded, Colors.white, Colors.grey[800]!),
                    _buildCallActionButton(Icons.videocam_off_rounded,
                        Colors.white, Colors.grey[800]!),
                    _buildCallActionButton(
                        Icons.volume_up_rounded, Colors.black, Colors.white),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_end_rounded,
                        color: Colors.white, size: 32),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallActionButton(IconData icon, Color iconColor, Color bgColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  void _showDriverReviewBottomSheet(BuildContext context, String tripId) {
    final api = ApiServices();
    final emergencyVM = Provider.of<EmergencyViewModel>(context, listen: false);
    final commentController = TextEditingController();
    int rating = 0;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (ctx, setState) => WillPopScope(
            onWillPop: () async => false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rate your driver",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () => setState(() => rating = index + 1),
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Write optional feedback",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (rating <= 0) {
                                Utils.toastMessage(
                                  context,
                                  "Please select a star rating first",
                                  isError: true,
                                );
                                return;
                              }
                              setState(() => submitting = true);
                              bool ok = false;
                              try {
                                final res = await api.submitDriverReview(
                                  tripId,
                                  rating: rating,
                                  comment: commentController.text.trim(),
                                );
                                ok = res != null && res['success'] == true;
                              } catch (_) {}

                              if (!context.mounted) return;
                              if (ok) {
                                emergencyVM.clearCompletedTripReviewPrompt();
                                Navigator.pop(ctx);
                                Navigator.of(context).pop();
                                Utils.toastMessage(
                                  context,
                                  "Thanks for reviewing your driver",
                                );
                              } else {
                                setState(() => submitting = false);
                                Utils.toastMessage(
                                  context,
                                  "Unable to submit review",
                                  isError: true,
                                );
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Submit Review"),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Glow Effect
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // 2. Core Line
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Simulate a path from Hospital to Ambulance
    path.moveTo(80, 190);
    path.lineTo(80, 215); // Down to intersection
    path.lineTo(size.width * 0.4 + 20, 215); // Across
    path.lineTo(size.width * 0.4 + 20, 300); // Down to ambulance

    canvas.drawPath(path, glowPaint); // Draw glow first
    canvas.drawPath(path, paint); // Draw core line
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
