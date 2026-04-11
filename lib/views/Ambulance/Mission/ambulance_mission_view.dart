import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/core/constants/app_url.dart';
import 'package:medlink/services/google_maps_service.dart';
import 'package:medlink/views/Ambulance/Mission/ambulance_mission_view_model.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/call/call_view_model.dart';
import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/widgets/custom_button.dart';
import 'package:medlink/widgets/emergency_action_dialog.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medlink/utils/gps_coord.dart';
import 'package:medlink/utils/vehicle_map_marker.dart';

class AmbulanceMissionView extends StatefulWidget {
  const AmbulanceMissionView({super.key});

  @override
  State<AmbulanceMissionView> createState() => _AmbulanceMissionViewState();
}

class _AmbulanceMissionViewState extends State<AmbulanceMissionView> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool hasInitialFit = false;

  List<LatLng> _routePoints = [];
  List<LatLng> _patientToHospitalLeg = [];
  String? _patientToHospitalKey;
  bool _patientToHospitalFetching = false;
  LatLng? _lastRoutedTargetPos;
  LatLng? _lastRoutedDriverPos;
  bool _isFetchingRoute = false;
  String _etaText = "";

  BitmapDescriptor? _vehicleIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final icon = await VehicleMapMarker.forContext(context);
        if (mounted) setState(() => _vehicleIcon = icon);
      } catch (_) {
        if (mounted) {
          setState(() => _vehicleIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure));
        }
      }
    });
  }

  Future<void> _fitCamera(List<LatLng> points) async {
    if (!_mapController.isCompleted || points.isEmpty) return;
    final controller = await _mapController.future;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15),
        ),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  void _updateRouteIfNeeded(LatLng driverPos, LatLng targetPos) async {
    if (_isFetchingRoute) return;

    double distanceMoved = 0;
    if (_lastRoutedDriverPos != null) {
      distanceMoved = Geolocator.distanceBetween(
        _lastRoutedDriverPos!.latitude,
        _lastRoutedDriverPos!.longitude,
        driverPos.latitude,
        driverPos.longitude,
      );
    }
    
    final targetChanged = _lastRoutedTargetPos == null ||
        _lastRoutedTargetPos!.latitude != targetPos.latitude ||
        _lastRoutedTargetPos!.longitude != targetPos.longitude;
    bool shouldFetch = _routePoints.isEmpty ||
        targetChanged ||
        distanceMoved > 50;

    if (shouldFetch) {
      if (targetChanged && mounted) {
        setState(() => _routePoints = []);
      }
      _isFetchingRoute = true;
      final routeData = await GoogleMapsService.getRouteCoordinates(driverPos, targetPos);
      if (routeData != null && mounted) {
        final pts = routeData['points'];
        if (pts is List<LatLng> && pts.length >= 2) {
          setState(() {
            _routePoints = List<LatLng>.from(pts);
            _etaText = routeData['durationText']?.toString() ?? '';
            _lastRoutedTargetPos = targetPos;
            _lastRoutedDriverPos = driverPos;
          });
        }
      }
      _isFetchingRoute = false;
    }
  }

  Future<void> _syncPatientToHospitalRoad(LatLng? pickup, LatLng? drop) async {
    if (pickup == null || drop == null) return;
    final key =
        '${pickup.latitude.toStringAsFixed(5)}_${pickup.longitude.toStringAsFixed(5)}_'
        '${drop.latitude.toStringAsFixed(5)}_${drop.longitude.toStringAsFixed(5)}';
    if (_patientToHospitalKey == key && _patientToHospitalLeg.isNotEmpty) {
      return;
    }
    if (_patientToHospitalFetching) return;
    _patientToHospitalFetching = true;
    final routeData =
        await GoogleMapsService.getRouteCoordinates(pickup, drop);
    _patientToHospitalFetching = false;
    if (!mounted || routeData == null) return;
    final raw = routeData['points'];
    if (raw is! List<LatLng>) return;
    setState(() {
      _patientToHospitalKey = key;
      _patientToHospitalLeg = List<LatLng>.from(raw);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AmbulanceMissionViewModel(),
      child: Consumer<AmbulanceMissionViewModel>(
        builder: (context, viewModel, child) {
          final driverPos = GpsCoord.isValidPair(
                  viewModel.driverLat, viewModel.driverLng)
              ? LatLng(viewModel.driverLat!, viewModel.driverLng!)
              : null;
          final pickupPos =
              (viewModel.pickupLat != null && viewModel.pickupLng != null)
                  ? LatLng(viewModel.pickupLat!, viewModel.pickupLng!)
                  : null;
          final dropoffPos =
              (viewModel.dropoffLat != null && viewModel.dropoffLng != null)
                  ? LatLng(viewModel.dropoffLat!, viewModel.dropoffLng!)
                  : null;

          final apiPhase = (viewModel.apiTripStatus ?? '').toUpperCase();
          final targetPos = (apiPhase == 'IN_PROGRESS' && dropoffPos != null)
              ? dropoffPos
              : (pickupPos ?? dropoffPos);

          if (driverPos != null && targetPos != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _updateRouteIfNeeded(driverPos, targetPos);
            });
          }

          if (pickupPos != null && dropoffPos != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _syncPatientToHospitalRoad(pickupPos, dropoffPos);
            });
          }

          final driverIcon = _vehicleIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
          final markers = <Marker>{
            if (driverPos != null)
              Marker(
                markerId: const MarkerId('driver'),
                position: driverPos,
                icon: driverIcon,
                rotation: viewModel.driverHeading ?? 0.0,
                flat: true,
                anchor: const Offset(0.5, 0.5),
                infoWindow: const InfoWindow(
                  title: 'Your ambulance',
                  snippet: 'Live position',
                ),
              ),
            if (pickupPos != null)
              Marker(
                markerId: const MarkerId('pickup'),
                position: pickupPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(
                  title: 'Patient pickup',
                  snippet: 'Patient is here',
                ),
              ),
            if (dropoffPos != null)
              Marker(
                markerId: const MarkerId('dropoff'),
                position: dropoffPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
                infoWindow: const InfoWindow(
                  title: 'Destination',
                  snippet: 'Hospital / drop-off',
                ),
              ),
          };

          final polylines = <Polyline>{
            if (_patientToHospitalLeg.length >= 2)
              Polyline(
                polylineId: const PolylineId('planned_patient_hospital'),
                points: _patientToHospitalLeg,
                color: Colors.grey.shade500,
                width: 4,
                patterns: [
                  PatternItem.dash(22),
                  PatternItem.gap(12),
                ],
              ),
            if (driverPos != null &&
                targetPos != null &&
                _routePoints.length >= 2)
              Polyline(
                polylineId: PolylineId(
                    'drive_${targetPos.latitude}_${targetPos.longitude}'),
                points: _routePoints,
                color: AppColors.primary,
                width: 6,
              ),
          };

          final cameraTarget =
              driverPos ?? pickupPos ?? dropoffPos ?? const LatLng(0, 0);

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
            body: Stack(
              children: [
                // 1. Google Map Layer
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      0.7, // Map takes 70% height initially
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: cameraTarget, zoom: 13),
                    onMapCreated: (c) {
                      if (!_mapController.isCompleted)
                        _mapController.complete(c);
                    },
                    markers: markers,
                    polylines: polylines,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),

                // 2. Top Header (Floating)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.navigation,
                                  color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Estimated Arrival",
                                  style: GoogleFonts.inter(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _etaText.isNotEmpty ? _etaText : viewModel.missionData['eta'],
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Live",
                                style: GoogleFonts.inter(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Bottom Sheet
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        // Grab Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Patient Info
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: (viewModel.missionData[
                                                      'patientPhotoUrl'] !=
                                                  null &&
                                              viewModel.missionData[
                                                      'patientPhotoUrl']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(
                                              AppUrl.getFullUrl(viewModel
                                                  .missionData[
                                                      'patientPhotoUrl']
                                                  .toString()),
                                            )
                                          : null,
                                      child: (viewModel.missionData[
                                                      'patientPhotoUrl'] !=
                                                  null &&
                                              viewModel.missionData[
                                                      'patientPhotoUrl']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? null
                                          : const Icon(Icons.person,
                                              color: Colors.grey, size: 30),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          viewModel.missionData['patientName'],
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on,
                                                size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                viewModel
                                                    .missionData['location'],
                                                style: GoogleFonts.inter(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Call Button
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Image.asset(
                                            'assets/Icons/chat.png',
                                            height: 20,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            final patientId = viewModel
                                                .missionData['patientId']
                                                ?.toString();
                                            final patientName = viewModel
                                                .missionData['patientName'];
                                            final photoUrl = viewModel
                                                .missionData['patientPhotoUrl'];

                                            if (patientId != null) {
                                              final userVM =
                                                  Provider.of<UserViewModel>(
                                                      context,
                                                      listen: false);
                                              final driverId = userVM
                                                      .loginSession
                                                      ?.data
                                                      ?.user
                                                      ?.id
                                                      ?.toString() ??
                                                  '0';

                                              final sosId = viewModel.missionData['sosId'];
                                              final tripId = viewModel.missionData['tripId'];

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChatView(
                                                    recipientName: patientName,
                                                    doctorId:
                                                        driverId, // Driver acting as sender
                                                    patientId: patientId,
                                                    profileImage: photoUrl,
                                                    sosId: sosId,
                                                    tripId: tripId,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Patient contact not available")),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Image.asset(
                                            'assets/Icons/phone.png',
                                            height: 20,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            final patientId = viewModel
                                                .missionData['patientId'];
                                            final patientName = viewModel
                                                .missionData['patientName'];
                                            // We don't have patient photo in missionData yet, maybe update ViewModel?
                                            // For now pass null
                                            if (patientId != null) {
                                              Provider.of<CallViewModel>(
                                                      context,
                                                      listen: false)
                                                  .initiateCall(
                                                      context,
                                                      patientId,
                                                      patientName,
                                                      null);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Patient contact not available")),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 24),

                              // Timeline
                              _buildTimeline(viewModel.status),

                              const SizedBox(height: 32),

                              // Main Action Button
                              if (viewModel.status != MissionStatus.completed)
                                CustomButton(
                                  text: _getNextStatusButtonText(
                                      viewModel.status),
                                  backgroundColor: AppColors.primary,
                                  onPressed: () {
                                    _showConfirmationDialog(
                                      context,
                                      viewModel,
                                      _getNextStatusActionName(
                                          viewModel.status),
                                    );
                                  },
                                )
                              else
                                CustomButton(
                                  text: "Return to Dashboard",
                                  backgroundColor: Colors.grey[800],
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildTimeline(MissionStatus currentStatus) {
    // 0: Dispatched, 1: OnRoute, 2: Arrived, 3: Transporting, 4: Completed
    int currentStep = currentStatus.index;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimelineStep(0, currentStep, "Start"),
        _buildTimelineLine(0, currentStep),
        _buildTimelineStep(2, currentStep,
            "Pickup"), // skipping 1 visual for simplicity or mapping slightly differently
        _buildTimelineLine(2, currentStep),
        _buildTimelineStep(3, currentStep, "Route"),
        _buildTimelineLine(3, currentStep),
        _buildTimelineStep(4, currentStep, "Dropoff"),
      ],
    );
  }

  Widget _buildTimelineStep(int stepIndex, int currentStep, String label) {
    bool isCompleted = currentStep >= stepIndex;
    bool isCurrent = currentStep == stepIndex;

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : Colors.grey[200],
            border: isCurrent
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isCompleted ? AppColors.textPrimary : Colors.grey[400],
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine(int stepIndex, int currentStep) {
    bool isCompleted = currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? AppColors.primary : Colors.grey[200],
        margin: const EdgeInsets.only(bottom: 18), // Align with dots
      ),
    );
  }

  String _getNextStatusButtonText(MissionStatus status) {
    switch (status) {
      case MissionStatus.dispatched:
        return "Start Route";
      case MissionStatus.onRoute:
        return "Arrived at Location";
      case MissionStatus.arrived:
        return "Start Transport";
      case MissionStatus.transporting:
        return "Complete Mission";
      case MissionStatus.completed:
        return "Done";
    }
  }

  String _getNextStatusActionName(MissionStatus status) {
    switch (status) {
      case MissionStatus.dispatched:
        return "Start the Route";
      case MissionStatus.onRoute:
        return "Confirm Arrival";
      case MissionStatus.arrived:
        return "Start Transportation";
      case MissionStatus.transporting:
        return "Complete the Mission";
      case MissionStatus.completed:
        return "Finish";
    }
  }

  void _showConfirmationDialog(BuildContext context,
      AmbulanceMissionViewModel viewModel, String action) {
    showDialog(
      context: context,
      builder: (ctx) => EmergencyActionDialog(
        title: "Confirmation",
        message: "Are you sure you want to $action?",
        actionText: "Confirm",
        actionColor: AppColors.primary,
        onConfirm: () {
          Navigator.pop(ctx);
          viewModel.updateStatus();
        },
      ),
    );
  }
}
