import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/utils/trip_fare_format.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';

class AmbulanceTripDetailView extends StatefulWidget {
  final Map<String, dynamic> trip;

  const AmbulanceTripDetailView({super.key, required this.trip});

  @override
  State<AmbulanceTripDetailView> createState() => _AmbulanceTripDetailViewState();
}

class _AmbulanceTripDetailViewState extends State<AmbulanceTripDetailView> {
  // Dummy coordinates for New York
  static const LatLng _pickupLocation = LatLng(40.7128, -74.0060);
  static const LatLng _dropoffLocation = LatLng(40.7589, -73.9851);

  late Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = {
       Marker(
        markerId: MarkerId('pickup'),
        position: _pickupLocation,
        infoWindow: InfoWindow(title: 'Pickup Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
       Marker(
        markerId: MarkerId('dropoff'),
        position: _dropoffLocation,
        infoWindow: InfoWindow(title: 'Drop-off Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: "Trip Details",
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map View
            SizedBox(
              height: 240, // Reduced from 280
              width: double.infinity,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _pickupLocation,
                      zoom: 12.5,
                    ),
                    markers: _markers,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                  // Gradient Overlay
                   Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            "Google Maps",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 11, // Reduced font
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20), // Reduced from 24
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Date & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.trip['tripNumber']?.toString() ??
                                    'Trip #${widget.trip['id']}',
                                style: GoogleFonts.inter(
                                  fontSize: 16, // Reduced from 18
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${widget.trip['date']} • ${widget.trip['time']}",
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                  fontSize: 12, // Reduced from 13
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced padding
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.trip['status'],
                              style: GoogleFonts.inter(
                                color: AppColors.success,
                                fontSize: 11, // Reduced font
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), // Reduced from 24

                      // Route Visualizer
                      _buildRouteSection(widget.trip),

                      const SizedBox(height: 24), // Reduced from 32
                      
                      // Patient Info
                      Text(
                        "Patient Details",
                        style: GoogleFonts.inter(
                          fontSize: 15, // Reduced from 16
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12), // Reduced from 16
                      Container(
                        padding: const EdgeInsets.all(12), // Reduced from 16
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16), // Reduced radius slightly
                          boxShadow: [
                             BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: CircleAvatar(
                                radius: 22, // Reduced from 24
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: const Icon(Icons.person, color: AppColors.primary, size: 22),
                              ),
                            ),
                            const SizedBox(width: 12), // Reduced gap
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.trip['patientName'],
                                    style: GoogleFonts.inter(
                                      fontSize: 15, // Reduced from 16
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "Emergency Run", 
                                    style: GoogleFonts.inter(
                                      fontSize: 12, // Reduced from 13
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            _buildActionButton(Icons.call_rounded, Colors.green),
                            const SizedBox(width: 10),
                            _buildActionButton(Icons.message_rounded, AppColors.primary),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24), // Reduced from 32

                      // Payment Breakdown
                      Text(
                        "Payment Details",
                         style: GoogleFonts.inter(
                          fontSize: 15, // Reduced from 16
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12), // Reduced from 16
                      Container(
                        padding: const EdgeInsets.all(16), // Reduced from 20
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                           boxShadow: [
                             BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._buildFareLineItems(widget.trip),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12), // Reduced
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total",
                                  style: GoogleFonts.inter(
                                    fontSize: 15, // Reduced
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.trip['earnings']?.toString() ?? '—',
                                  style: GoogleFonts.inter(
                                    fontSize: 18, // Reduced from 20
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Download Receipt Button
                      SizedBox(
                        width: double.infinity,
                        height: 48, // Reduced from 54
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            "Download Receipt",
                            style: GoogleFonts.inter(
                              fontSize: 14, // Reduced from 16
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 10
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18), // Reduced from 20
    );
  }

  Widget _buildRouteSection(Map<String, dynamic> trip) {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary), // Reduced size
                   Container(
                     width: 2, 
                     height: 30, // Reduced height
                     margin: const EdgeInsets.symmetric(vertical: 4),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [AppColors.primary, Colors.orange],
                       ),
                     ),
                   ),
                  const Icon(Icons.location_on_rounded, size: 18, color: Colors.orange), // Reduced size
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pickup",
                      style: GoogleFonts.inter(
                        fontSize: 11, // Reduced
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    const SizedBox(height: 2),
                     Text(
                      trip['pickupAddress']?.toString() ??
                          trip['location']?.toString() ??
                          'Pickup',
                       style: GoogleFonts.inter(
                        fontSize: 14, // Reduced
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 20
                     Text(
                      "Drop-off",
                      style: GoogleFonts.inter(
                        fontSize: 11, // Reduced
                        color: Colors.grey[500],
                         fontWeight: FontWeight.w600
                      ),
                    ),
                    const SizedBox(height: 2),
                     Text(
                      trip['dropoffAddress']?.toString() ??
                          trip['dropoffLabel']?.toString() ??
                          trip['location']?.toString() ??
                          'Destination',
                       style: GoogleFonts.inter(
                        fontSize: 14, // Reduced
                        fontWeight: FontWeight.w600,
                         color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  String _currencyHint(Map<String, dynamic> trip) {
    return trip['currency']?.toString() ??
        trip['fareCurrency']?.toString() ??
        (trip['payment'] is Map
            ? (trip['payment'] as Map)['currency']?.toString()
            : null) ??
        '';
  }

  List<Widget> _buildFareLineItems(Map<String, dynamic> trip) {
    final cur = _currencyHint(trip);
    String fmt(double v) => TripFareFormat.formatCfa(v, currencyHint: cur);

    final items = <Widget>[];
    void line(String label, double? amount) {
      if (amount != null && amount > 0) {
        if (items.isNotEmpty) {
          items.add(const SizedBox(height: 10));
        }
        items.add(_buildPaymentRow(label, fmt(amount)));
      }
    }

    line(
      'Base fare',
      TripFareFormat.amountForKeys(trip, ['baseFare', 'base_fare', 'baseAmount']),
    );

    final distFare = TripFareFormat.amountForKeys(
      trip,
      ['distanceFare', 'distance_fare', 'kmFare', 'perKmFare'],
    );
    final km = trip['distanceKm'] ?? trip['distance'] ?? trip['totalDistanceKm'];
    if (distFare != null) {
      final kmLabel = km != null ? ' ($km km)' : '';
      line('Distance$kmLabel', distFare);
    }

    line(
      'Time',
      TripFareFormat.amountForKeys(
        trip,
        ['timeFare', 'time_fare', 'durationFare', 'minutesFare'],
      ),
    );

    line(
      'Surge',
      TripFareFormat.amountForKeys(trip, ['surgeFare', 'surge', 'surgeAmount']),
    );

    line(
      'Fees',
      TripFareFormat.amountForKeys(trip, ['serviceFee', 'platformFee', 'tax', 'taxAmount']),
    );

    if (items.isEmpty) {
      items.add(
        Text(
          'Line items not provided — total reflects the trip fare from your records.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.35,
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500), // Reduced font
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary), // Reduced font
        ),
      ],
    );
  }
}
