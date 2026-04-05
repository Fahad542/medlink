import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/Patient%20App/emergency/emergency_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:medlink/services/google_maps_service.dart';

class DestinationPickerView extends StatefulWidget {
  const DestinationPickerView({super.key});

  @override
  State<DestinationPickerView> createState() => _DestinationPickerViewState();
}

class _DestinationPickerViewState extends State<DestinationPickerView> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _selectedLocation;
  List<dynamic> _predictions = [];
  // Default to a central location if current location isn't instantly available
  final LatLng _initialLocation = const LatLng(37.7749, -122.4194);

  // You can integrate Google Places Search here if desired
  final TextEditingController _searchController = TextEditingController();

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  void _confirmDestination() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a destination on the map")),
      );
      return;
    }

    final emergencyVM = Provider.of<EmergencyViewModel>(context, listen: false);
    Navigator.pop(context); // Close the map

    // Trigger SOS setup
    _showSOSConfirmation(context, emergencyVM, _selectedLocation!);
  }

  void _showSOSConfirmation(BuildContext context, EmergencyViewModel emergencyVM, LatLng destination) {
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
                "Request ambulance to take you to selected destination?",
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
                        emergencyVM.triggerSosWithDestination(
                          context,
                          destination.latitude,
                          destination.longitude,
                        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Destination", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialLocation,
              zoom: 14.0,
            ),
            onMapCreated: (controller) => _mapController.complete(controller),
            onTap: _onMapTapped,
            markers: _selectedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
                         color: Colors.black.withOpacity(0.1),
                         blurRadius: 10,
                       )
                     ]
                   ),
                   child: TextField(
                     controller: _searchController,
                     decoration: const InputDecoration(
                       icon: Icon(Icons.search),
                       hintText: "Search location or tap map...",
                       border: InputBorder.none
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        )
                      ]
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final place = _predictions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Colors.red),
                          title: Text(place['description']),
                          onTap: () async {
                            FocusScope.of(context).unfocus();
                            setState(() => _predictions = []);
                            _searchController.text = place['description'];
                            final latLng = await GoogleMapsService.getPlaceDetails(place['place_id']);
                            if (latLng != null) {
                              _onMapTapped(latLng);
                              final controller = await _mapController.future;
                              controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
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
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _selectedLocation != null ? _confirmDestination : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Confirm Destination", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
