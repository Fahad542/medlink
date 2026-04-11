import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:medlink/services/google_maps_service.dart';

/// Two-step SOS flow: **pickup** (where you are) then **destination** (hospital / drop-off).
/// Both are sent to `POST /patient/sos` as `lat`/`lng` and `destinationLat`/`destinationLng`.
class DestinationPickerView extends StatefulWidget {
  const DestinationPickerView({super.key});

  @override
  State<DestinationPickerView> createState() => _DestinationPickerViewState();
}

class _DestinationPickerViewState extends State<DestinationPickerView> {
  final Completer<GoogleMapController> _mapController = Completer();

  /// 0 = pickup, 1 = destination
  int _step = 0;
  LatLng? _pickup;
  LatLng? _workingPin;
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
      _workingPin = ll;
      _cameraTarget = ll;
    });
    await _animateTo(ll);
  }

  Future<LatLng?> _readCurrentLatLng({bool showErrors = false}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted && showErrors) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turn on location to use your current position.'),
            ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for pickup.'),
            ),
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
      _workingPin = ll;
      _cameraTarget = ll;
      if (_step == 0) {
        _pickupLabel = 'Current location';
      } else {
        _destinationLabel = 'Current location';
      }
    });
    await _animateTo(ll);
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _workingPin = position;
      if (_step == 0) {
        _pickupLabel = 'Selected on map';
      } else {
        _destinationLabel = 'Selected on map';
      }
    });
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      _searchController.clear();
      _predictions = [];
      if (step == 0) {
        _workingPin = _pickup;
      } else {
        _workingPin = null;
      }
    });
    if (step == 0 && _pickup != null) {
      _animateTo(_pickup!);
    }
  }

  void _continueFromPickup() {
    if (_workingPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose where you need pickup.')),
      );
      return;
    }
    setState(() {
      _pickup = _workingPin;
      _pickupLabel ??= 'Pickup point';
      _step = 1;
      _workingPin = null;
      _searchController.clear();
      _predictions = [];
    });
  }

  void _openReviewDialog() {
    if (_pickup == null || _workingPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose your destination (hospital / drop-off).')),
      );
      return;
    }
    final dest = _workingPin!;
    final emergencyVM = Provider.of<EmergencyViewModel>(context, listen: false);

    final summary = [
      if (_pickupLabel != null) 'Pickup: $_pickupLabel',
      if (_destinationLabel != null) 'Destination: $_destinationLabel',
    ].join('\n');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm emergency request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _ReviewRow(icon: Icons.flag_circle_outlined, label: 'Pickup', detail: _pickupLabel ?? 'Map point'),
              const SizedBox(height: 10),
              _ReviewRow(icon: Icons.local_hospital_outlined, label: 'Destination', detail: _destinationLabel ?? 'Map point'),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        emergencyVM.triggerSosWithPickupAndDestination(
                          context,
                          pickupLat: _pickup!.latitude,
                          pickupLng: _pickup!.longitude,
                          destinationLat: dest.latitude,
                          destinationLng: dest.longitude,
                          addressSummary: summary.isNotEmpty ? summary : null,
                        );
                      },
                      child: const Text('Send SOS'),
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

  Set<Marker> get _markers {
    final set = <Marker>{};
    if (_step == 0) {
      if (_workingPin != null) {
        set.add(Marker(
          markerId: const MarkerId('pickup_working'),
          position: _workingPin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Pickup',
            snippet: 'Where the ambulance should pick you up',
          ),
        ));
      }
    } else {
      if (_pickup != null) {
        set.add(Marker(
          markerId: const MarkerId('pickup_fixed'),
          position: _pickup!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Your pickup',
            snippet: 'You are picked up here',
          ),
        ));
      }
      if (_workingPin != null) {
        set.add(Marker(
          markerId: const MarkerId('destination_working'),
          position: _workingPin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Destination',
            snippet: 'Hospital / drop-off',
          ),
        ));
      }
    }
    return set;
  }

  String get _appBarTitle =>
      _step == 0 ? 'Pickup location' : 'Destination';

  String get _hintText => _step == 0
      ? 'Search pickup or tap map…'
      : 'Search hospital / destination…';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        leading: _step == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goToStep(0),
              )
            : null,
        automaticallyImplyLeading: _step == 0,
        actions: [
          if (_step == 1)
            TextButton(
              onPressed: () => _goToStep(0),
              child: const Text('Edit pickup'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                _StepDot(active: _step == 0, label: '1', title: 'Pickup'),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: _step == 1 ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                _StepDot(active: _step == 1, label: '2', title: 'Destination'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _cameraTarget,
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
              if (_workingPin != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_workingPin!, 15),
                );
              }
            },
            onTap: _onMapTapped,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search),
                      hintText: _hintText,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) async {
                      if (val.isEmpty) {
                        setState(() => _predictions = []);
                        return;
                      }
                      final results = await GoogleMapsService.searchPlaces(val);
                      setState(() => _predictions = results);
                    },
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final place = _predictions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.place_outlined,
                            color: _step == 0 ? Colors.green : Colors.red,
                          ),
                          title: Text(place['description']),
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            setState(() => _predictions = []);
                            final desc = place['description']?.toString() ?? '';
                            _searchController.text = desc;
                            final latLng = await GoogleMapsService.getPlaceDetails(
                                place['place_id']);
                            if (latLng != null) {
                              setState(() {
                                _workingPin = latLng;
                                if (_step == 0) {
                                  _pickupLabel = desc;
                                } else {
                                  _destinationLabel = desc;
                                }
                              });
                              final controller = await _mapController.future;
                              await controller.animateCamera(
                                CameraUpdate.newLatLngZoom(latLng, 15),
                              );
                              if (_step == 1 && _pickup != null) {
                                await _fitTwoPoints(_pickup!, latLng);
                              }
                            }
                          },
                        );
                      },
                    ),
                  )
              ],
            ),
          ),

          Positioned(
            bottom: 100,
            right: 20,
            child: Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _recenterMyLocation,
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _workingPin != null
                  ? (_step == 0 ? _continueFromPickup : _openReviewDialog)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _step == 0 ? 'Continue to destination' : 'Review & send SOS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;
  final String title;

  const _StepDot({
    required this.active,
    required this.label,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : Colors.grey.shade300,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : Colors.grey,
          ),
        ),
      ],
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
        Icon(icon, size: 22, color: AppColors.primary),
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
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
