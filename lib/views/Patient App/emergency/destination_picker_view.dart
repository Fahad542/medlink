import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medlink/services/google_maps_service.dart';
import 'package:medlink/utils/utils.dart';

/// Two-step SOS flow: **pickup** (where you are) then **destination** (hospital / drop-off).
/// Both are sent to `POST /patient/sos` as `lat`/`lng` and `destinationLat`/`destinationLng`.
class DestinationPickerView extends StatefulWidget {
  const DestinationPickerView({super.key});

  @override
  State<DestinationPickerView> createState() => _DestinationPickerViewState();
}

class _DestinationPickerViewState extends State<DestinationPickerView> {
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng? _pickup;
  LatLng? _destination;
  bool _isMapPressing = false;
  LatLng _cameraTarget = const LatLng(37.7749, -122.4194);

  List<dynamic> _predictions = [];
  final TextEditingController _searchController = TextEditingController();

  String? _pickupLabel;
  String? _destinationLabel;

  @override
  void initState() {
    super.initState();
    _bootstrapPickupFromGps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapPickupFromGps() async {
    final ll = await _readCurrentLatLng(showErrors: true);
    if (!mounted || ll == null) return;
    setState(() {
      _pickup = ll;
      _cameraTarget = ll;
      _pickupLabel = 'Fetching address...';
    });
    await _animateTo(ll);
    _setAddressLabelForLatLng(ll, forPickup: true);
  }

  Future<LatLng?> _readCurrentLatLng({bool showErrors = false}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && showErrors) {
          Utils.toastMessage(
            context,
            'Turn on location to use your current position.',
            isError: true,
          );
        }
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted && showErrors) {
          Utils.toastMessage(
            context,
            'Location permission is required for pickup.',
            isError: true,
          );
        }
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('DestinationPickerView: location $e');
      return null;
    }
  }

  Future<void> _animateTo(LatLng target) async {
    if (!_mapController.isCompleted) return;
    final c = await _mapController.future;
    await c.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
  }

  Future<void> _fitTwoPoints(LatLng a, LatLng b) async {
    if (!_mapController.isCompleted) return;
    final c = await _mapController.future;
    final south = a.latitude < b.latitude ? a.latitude : b.latitude;
    final north = a.latitude > b.latitude ? a.latitude : b.latitude;
    final west = a.longitude < b.longitude ? a.longitude : b.longitude;
    final east = a.longitude > b.longitude ? a.longitude : b.longitude;
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        100,
      ),
    );
  }

  Future<void> _recenterMyLocation() async {
    final ll = await _readCurrentLatLng(showErrors: true);
    if (!mounted || ll == null) return;
    setState(() {
      _pickup = ll;
      _cameraTarget = ll;
      _pickupLabel = 'Fetching address...';
    });
    await _animateTo(ll);
    _setAddressLabelForLatLng(ll, forPickup: true);
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      // In this unified view, map tap usually sets destination if pickup is already set, 
      // or allows moving the "active" pin. Let's assume it moves the destination if search is active.
      _destination = position;
      _destinationLabel = 'Fetching address...';
    });
    _setAddressLabelForLatLng(position, forPickup: false);
  }

  Future<void> _setAddressLabelForLatLng(
    LatLng latLng, {
    required bool forPickup,
  }) async {
    final address = await GoogleMapsService.getAddressFromLatLng(
      latLng.latitude,
      latLng.longitude,
    );
    if (!mounted) return;
    setState(() {
      final resolved = (address != null && address.trim().isNotEmpty)
          ? address
          : 'Selected location';
      if (forPickup) {
        _pickupLabel = resolved;
      } else {
        _destinationLabel = resolved;
        _searchController.text = resolved;
      }
    });
  }

  String _calculateMockFare() {
    if (_pickup == null || _destination == null) return '0';
    final distanceMeters = Geolocator.distanceBetween(
      _pickup!.latitude,
      _pickup!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    final distanceKm = distanceMeters / 1000;
    // Base fare 150 + 50 per km
    final fare = 150 + (distanceKm * 50);
    return NumberFormat.decimalPattern().format(fare.round());
  }

  void _triggerFindDriver() {
    if (_pickup == null || _destination == null) {
      Utils.toastMessage(
        context,
        'Please select both pickup and destination.',
        isError: true,
      );
      return;
    }
    _showConfirmRequestDialog();
  }

  void _showConfirmRequestDialog() {
    if (_pickup == null || _destination == null) return;
    final emergencyVM = Provider.of<EmergencyViewModel>(context, listen: false);
    final summary = [
      if (_pickupLabel != null) 'Pickup: $_pickupLabel',
      if (_destinationLabel != null) 'Destination: $_destinationLabel',
      'Fare: ${_calculateMockFare()} Your Fare',
    ].join('\n');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirm request',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please verify pickup and destination before sending SOS.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: _ReviewRow(
                  icon: Icons.location_on_outlined,
                  label: 'Pickup',
                  detail: _pickupLabel ?? 'Map point',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _ReviewRow(
                  icon: Icons.location_on_outlined,
                  label: 'Destination',
                  detail: _destinationLabel ?? 'Map point',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        emergencyVM.triggerSosWithPickupAndDestination(
                          context,
                          pickupLat: _pickup!.latitude,
                          pickupLng: _pickup!.longitude,
                          destinationLat: _destination!.latitude,
                          destinationLng: _destination!.longitude,
                          addressSummary: summary,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Send SOS',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
  }

  void _setMapPressState(bool isPressing) {
    if (_isMapPressing == isPressing) return;
    setState(() => _isMapPressing = isPressing);
  }

  Set<Marker> get _markers {
    final set = <Marker>{};
    if (_pickup != null) {
      set.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickup!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    if (_destination != null) {
      set.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Listener(
            onPointerDown: (_) => _setMapPressState(true),
            onPointerUp: (_) => _setMapPressState(false),
            onPointerCancel: (_) => _setMapPressState(false),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _cameraTarget,
                zoom: 14.0,
              ),
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                if (_pickup != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_pickup!, 15),
                  );
                }
              },
              onTap: _onMapTapped,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              style: _mapStyle,
            ),
          ),

          // Floating Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 380, // Adjusted for larger bottom panel
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _recenterMyLocation,
              child: const Icon(Icons.near_me_outlined, color: Colors.black),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    final results = await GoogleMapsService.searchPlaces(value);
    if (!mounted) return;
    setState(() => _predictions = results);
  }

  Future<void> _onPredictionTap(dynamic place) async {
    FocusScope.of(context).unfocus();
    setState(() => _predictions = []);
    final desc = place['description']?.toString() ?? '';
    _searchController.text = desc;
    final latLng = await GoogleMapsService.getPlaceDetails(place['place_id']);
    if (latLng == null || !mounted) return;

    setState(() {
      _destination = latLng;
      _destinationLabel = desc;
    });

    if (_pickup != null) {
      await _fitTwoPoints(_pickup!, latLng);
    } else {
      await _animateTo(latLng);
    }
  }

  void _showRouteSearchSheet() {
    _setMapPressState(false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RouteSearchSheet(
        initialPickup: _pickupLabel ?? '',
        initialDestination: _destinationLabel ?? '',
        pickupLL: _pickup,
        destinationLL: _destination,
        onSelection: (pickup, dest, pickupLL, destLL) {
          setState(() {
            if (pickupLL != null) {
              _pickup = pickupLL;
              _pickupLabel = pickup;
            }
            if (destLL != null) {
              _destination = destLL;
              _destinationLabel = dest;
              _searchController.text = dest;
            }
          });
          if (_pickup != null && _destination != null) {
            _fitTwoPoints(_pickup!, _destination!);
          } else if (_destination != null) {
            _animateTo(_destination!);
          }
        },
      ),
    );
  }

  Widget _buildBottomPanel() {
    final compact = _isMapPressing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: compact ? 8 : 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: compact ? 10 : 24),
          if (!compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select pick up and designation',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          if (!compact) const SizedBox(height: 24),
          if (compact) const SizedBox(height: 4),
          
          // Tap area to open search
          if (!compact)
            GestureDetector(
              onTap: _showRouteSearchSheet,
              child: Container(
                color: Colors.transparent,
                child: Column(
                  children: [
                  // Pickup Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: Colors.green, size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _pickupLabel ?? 'Set pickup location',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Destination Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _destinationLabel != null 
                      ? Row(
                          children: [
                            const Icon(Icons.radio_button_checked, color: Colors.redAccent, size: 22),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'To',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _destinationLabel!,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.black54, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'To',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Search hospital...',
                                  style: GoogleFonts.inter(
                                    fontSize: 16, 
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ],
                ),
              ),
            ),
          
          if (!compact && _pickup != null && _destination != null) ...[
            const SizedBox(height: 20),
            // Fare Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      'FCA',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '${_calculateMockFare()} ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: '   Your Fare',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.auto_graph_rounded, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
          
          SizedBox(height: compact ? 8 : 24),
          
          // Final Action Row
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _triggerFindDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergency,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Activate SOS',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const String _mapStyle = ''; // Add custom map style here if needed
}

class _RouteSearchSheet extends StatefulWidget {
  final String initialPickup;
  final String initialDestination;
  final LatLng? pickupLL;
  final LatLng? destinationLL;
  final Function(String, String, LatLng?, LatLng?) onSelection;

  const _RouteSearchSheet({
    required this.initialPickup,
    required this.initialDestination,
    this.pickupLL,
    this.destinationLL,
    required this.onSelection,
  });

  @override
  State<_RouteSearchSheet> createState() => _RouteSearchSheetState();
}

class _RouteSearchSheetState extends State<_RouteSearchSheet> {
  static const String _recentKey = 'destination_picker_recent_locations_v1';
  static const int _maxRecentItems = 8;

  final List<Map<String, dynamic>> _recentSelections = [];

  late TextEditingController _fromController;
  late TextEditingController _toController;
  final FocusNode _fromNode = FocusNode();
  final FocusNode _toNode = FocusNode();
  
  List<dynamic> _predictions = [];
  bool _isSearchingTo = true;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.initialPickup);
    _toController = TextEditingController(text: widget.initialDestination);
    
    _fromNode.addListener(() => setState(() {}));
    _toNode.addListener(() => setState(() {}));
    _loadInitialResults();
  }

  Future<void> _loadInitialResults() async {
    await _loadRecentSelections();
    if (!mounted) return;

    final toQuery = _toController.text.trim();
    final fromQuery = _fromController.text.trim();
    final initialQuery = toQuery.isNotEmpty ? toQuery : fromQuery;
    if (initialQuery.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    final searchingTo = toQuery.isNotEmpty;
    _isSearchingTo = searchingTo;
    final LatLng? origin = searchingTo ? widget.pickupLL : widget.destinationLL;
    final results =
        await GoogleMapsService.searchPlaces(initialQuery, origin: origin);
    if (!mounted) return;
    setState(() => _predictions = results);
  }

  Future<void> _loadRecentSelections() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_recentKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final parsed = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _recentSelections
        ..clear()
        ..addAll(parsed.take(_maxRecentItems));
    } catch (_) {
      // Keep UI resilient if cached JSON is invalid.
    }
  }

  Future<void> _persistRecentSelections() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_recentKey, jsonEncode(_recentSelections));
    } catch (_) {
      // Ignore cache failures; selection flow should still work.
    }
  }

  void _cacheRecentSelection(Map<String, dynamic> entry) {
    _recentSelections.removeWhere((e) =>
        (e['place_id'] != null && e['place_id'] == entry['place_id']) ||
        (e['description'] != null && e['description'] == entry['description']));
    _recentSelections.insert(0, entry);
    if (_recentSelections.length > _maxRecentItems) {
      _recentSelections.removeRange(_maxRecentItems, _recentSelections.length);
    }
    _persistRecentSelections();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromNode.dispose();
    _toNode.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String value, bool forTo) async {
    _isSearchingTo = forTo;
    if (value.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    
    // Use the relevant origin for distance calculation:
    // If searching for 'From', use the current 'Destination' as origin (if it exists)
    // If searching for 'To', use the current 'Pickup' as origin (if it exists)
    final LatLng? origin = forTo ? widget.pickupLL : widget.destinationLL;
    
    final results = await GoogleMapsService.searchPlaces(value, origin: origin);
    if (!mounted) return;
    setState(() => _predictions = results);
  }

  @override
  Widget build(BuildContext context) {
    final activeQuery =
        (_isSearchingTo ? _toController.text : _fromController.text).trim();
    final showRecentMode = activeQuery.isEmpty || _predictions.isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'Enter your route',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // From Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _fromNode.hasFocus ? Icons.search : Icons.radio_button_checked, 
                    color: _fromNode.hasFocus ? Colors.black : Colors.green, 
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextField(
                          controller: _fromController,
                          focusNode: _fromNode,
                          onTap: () => setState(() => _isSearchingTo = false),
                          onChanged: (v) => _onSearch(v, false),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_fromController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _isSearchingTo = false;
                        _fromController.clear();
                        _predictions = [];
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // To Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _toNode.hasFocus ? Icons.search : Icons.radio_button_checked, 
                    color: _toNode.hasFocus ? Colors.black : Colors.redAccent, 
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextField(
                          controller: _toController,
                          focusNode: _toNode,
                          autofocus: true,
                          onTap: () => setState(() => _isSearchingTo = true),
                          onChanged: (v) => _onSearch(v, true),
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            hintText: 'Destination',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_toController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() {
                        _isSearchingTo = true;
                        _toController.clear();
                        _predictions = [];
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Static Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              showRecentMode ? 'Recent Searches' : 'Search Results',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results List
          Expanded(
            child: Builder(
              builder: (context) {
                final resultsToShow =
                    _predictions.isNotEmpty ? _predictions : _recentSelections;
                if (resultsToShow.isEmpty) {
                  return Center(
                    child: Text(
                      showRecentMode
                          ? 'No recent locations'
                          : 'No search results',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  );
                }
                return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: resultsToShow.length,
              itemBuilder: (context, index) {
                final p = resultsToShow[index];
                final title = p['structured_formatting']?['main_text'] ??
                    p['main_text'] ??
                    p['description'] ??
                    '';
                final subtitle = p['structured_formatting']?['secondary_text'] ??
                    p['secondary_text'] ??
                    '';
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined, color: Colors.black54),
                  ),
                  title: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!showRecentMode && p['distance_meters'] != null)
                        Text(
                          '${(p['distance_meters'] / 1000).toStringAsFixed(1)}km',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                  onTap: () async {
                    final double? recentLat = (p['lat'] is num)
                        ? (p['lat'] as num).toDouble()
                        : double.tryParse(p['lat']?.toString() ?? '');
                    final double? recentLng = (p['lng'] is num)
                        ? (p['lng'] as num).toDouble()
                        : double.tryParse(p['lng']?.toString() ?? '');
                    final latLng = (recentLat != null && recentLng != null)
                        ? LatLng(recentLat, recentLng)
                        : await GoogleMapsService.getPlaceDetails(p['place_id']);
                    if (latLng == null) return;

                    final recentEntry = <String, dynamic>{
                      ...Map<String, dynamic>.from(p),
                      'description': p['description'] ?? title,
                      'main_text': title,
                      'secondary_text': subtitle,
                      'lat': latLng.latitude,
                      'lng': latLng.longitude,
                    };
                    _cacheRecentSelection(recentEntry);
                    
                    if (_isSearchingTo) {
                      widget.onSelection(_fromController.text, title, null, latLng);
                    } else {
                      widget.onSelection(title, _toController.text, latLng, null);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.black87),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
