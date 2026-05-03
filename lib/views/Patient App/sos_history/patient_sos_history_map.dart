import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';

/// Read-only map for SOS history: pickup, drop-off / destination, optional last vehicle ping.
class PatientSosHistoryMap extends StatefulWidget {
  final Map<String, dynamic> sos;

  const PatientSosHistoryMap({super.key, required this.sos});

  @override
  State<PatientSosHistoryMap> createState() => _PatientSosHistoryMapState();
}

class _PatientSosHistoryMapState extends State<PatientSosHistoryMap> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _didFit = false;

  LatLng? _parse(dynamic lat, dynamic lng) {
    final la = lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '');
    final ln = lng is num ? lng.toDouble() : double.tryParse(lng?.toString() ?? '');
    if (la == null || ln == null) return null;
    if (!la.isFinite || !ln.isFinite) return null;
    if (la.abs() > 90 || ln.abs() > 180) return null;
    return LatLng(la, ln);
  }

  bool _samePoint(LatLng a, LatLng b) {
    const eps = 1e-5;
    return (a.latitude - b.latitude).abs() < eps &&
        (a.longitude - b.longitude).abs() < eps;
  }

  LatLngBounds _boundsFromPoints(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;
    for (final latLng in list) {
      x1 = math.max(x1, latLng.latitude);
      x0 = math.min(x0, latLng.latitude);
      y1 = math.max(y1, latLng.longitude);
      y0 = math.min(y0, latLng.longitude);
    }
    if ((x1 - x0).abs() < 1e-4) {
      x0 -= 0.002;
      x1 += 0.002;
    }
    if ((y1 - y0).abs() < 1e-4) {
      y0 -= 0.002;
      y1 += 0.002;
    }
    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  Future<void> _fitCamera(List<LatLng> points) async {
    if (_didFit || !mounted) return;
    if (!_mapController.isCompleted || points.isEmpty) return;
    _didFit = true;
    final controller = await _mapController.future;
    if (!mounted) return;
    try {
      if (points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 14.5),
        );
      } else {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromPoints(points), 56),
        );
      }
    } catch (_) {
      if (mounted) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 13),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.sos['trip'];
    final tripMap = trip is Map ? Map<String, dynamic>.from(trip) : null;

    final sosPickup = _parse(widget.sos['lat'], widget.sos['lng']);
    final sosDest = _parse(
      widget.sos['destinationLat'],
      widget.sos['destinationLng'],
    );

    LatLng? tripPickup;
    LatLng? tripDrop;
    if (tripMap != null) {
      tripPickup = _parse(tripMap['pickupLat'], tripMap['pickupLng']);
      tripDrop = _parse(tripMap['dropoffLat'], tripMap['dropoffLng']);
    }

    final pickup = tripPickup ?? sosPickup;
    final dropoff = tripDrop ?? sosDest;

    LatLng? vehicle;
    if (tripMap != null && tripMap['latestLocation'] is Map) {
      final loc = Map<String, dynamic>.from(tripMap['latestLocation'] as Map);
      vehicle = _parse(loc['lat'], loc['lng']);
    }

    final markers = <Marker>{};
    final fitPoints = <LatLng>[];

    void addMarker(LatLng? p, String id, String title, double hue) {
      if (p == null) return;
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: p,
          infoWindow: InfoWindow(title: title),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
      final dup = fitPoints.any((e) => _samePoint(e, p));
      if (!dup) fitPoints.add(p);
    }

    if (pickup != null) {
      addMarker(pickup, 'pickup', 'Pickup / SOS location', BitmapDescriptor.hueGreen);
    }
    if (dropoff != null &&
        (pickup == null || !_samePoint(pickup, dropoff))) {
      addMarker(dropoff, 'dropoff', 'Drop-off / destination', BitmapDescriptor.hueRed);
    }
    if (vehicle != null) {
      final skipV = (pickup != null && _samePoint(vehicle, pickup)) ||
          (dropoff != null && _samePoint(vehicle, dropoff));
      if (!skipV) {
        addMarker(
          vehicle,
          'vehicle',
          'Last vehicle position',
          BitmapDescriptor.hueAzure,
        );
      }
    }

    if (markers.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              'No map coordinates for this request',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final initial = fitPoints.isNotEmpty
        ? fitPoints.first
        : const LatLng(9.0765, 7.3986);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initial,
                zoom: fitPoints.length <= 1 ? 14.5 : 11,
              ),
              markers: markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              liteModeEnabled: false,
              onMapCreated: (c) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(c);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitCamera(fitPoints);
                });
              },
            ),
            Positioned(
              bottom: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Locations',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
