import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPicker extends StatefulWidget {
  final double currentLongitude;
  final double currentLatitude;

  const GoogleMapPicker({
    required this.currentLatitude,
    required this.currentLongitude,
    super.key,
  });

  @override
  State<GoogleMapPicker> createState() => _GoogleMapPickerState();
}

class _GoogleMapPickerState extends State<GoogleMapPicker> {
  GoogleMapController? mapController;
  LatLng? mapCenter;
  late places.FlutterGooglePlacesSdk googlePlace;
  List<places.AutocompletePrediction> predictions = [];
  final TextEditingController _searchController = TextEditingController();
  String selectedLocation = "Fetching location...";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    googlePlace = places.FlutterGooglePlacesSdk(
      "AIzaSyB-BKJtUYt-YuVBzZt54ALoFOfJWA430_Q", // 🔐 Replace with your actual API key
    );

    // Determine current position if not provided
    if (widget.currentLongitude == 0.0 || widget.currentLatitude == 0.0) {
      _determinePosition();
    } else {
      mapCenter = LatLng(widget.currentLatitude, widget.currentLongitude);
      _getAddressFromLatLng(mapCenter!);
    }
  }

  /// Get current location
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      mapCenter = LatLng(position.latitude, position.longitude);
    });
    _getAddressFromLatLng(mapCenter!);
  }

  /// Reverse geocode to get readable address
  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          selectedLocation =
              "${place.subLocality ?? ''} ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
        });
      }
    } catch (_) {
      setState(() => selectedLocation = "Unknown Location");
    }
  }

  /// Autocomplete search
  void autoCompleteSearch(String value) async {
    final result = await googlePlace.findAutocompletePredictions(
      value,
      countries: ['IN'],
    );
    if (result.predictions.isNotEmpty) {
      setState(() {
        predictions = result.predictions;
      });
      //String plceId = Predictions.placeId;
      // await getLatlng(plceId);
    }
  }

  Future<void> getLatlng(placeId) async {
    final details = await googlePlace.fetchPlace(
      placeId,
      fields: [
        places.PlaceField.Location,
        places.PlaceField.Name,
        places.PlaceField.Address,
      ],
    );
    final location = details.place?.latLng;

    if (location != null) {
      mapCenter = LatLng(location.lat, location.lng);
      _searchController.text = details.place!.name ?? "";
      predictions = [];
      selectedLocation = details.place!.address ?? "";
    }
    ;
    LatLng latlang = LatLng(location!.lat, location!.lng);
    mapController?.animateCamera(CameraUpdate.newLatLng(latlang));
  }

  /// Move to selected prediction
  /*Future<void> _moveToPrediction(a4
      places.AutocompletePrediction prediction,
      ) async {
    final details = await googlePlace.get(prediction.placeId.);
    if (details != null && details.result != null) {
      final loc = details.result!.geometry!.location;
      final latLng = LatLng(prediction., loc.lng);


    }
  }*/

  /// Recenter to current GPS location
  Future<void> _recenterToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    final currentLatLng = LatLng(position.latitude, position.longitude);
    mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
    setState(() {
      mapCenter = currentLatLng;
    });
    _getAddressFromLatLng(currentLatLng);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body:
          mapCenter == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
            children: [
              // 1. Google Map
              GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) => mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: mapCenter ?? const LatLng(0, 0),
                  zoom: 14,
                ),
                onCameraMove: (position) => mapCenter = position.target,
                onCameraIdle: () {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 600), () {
                    if (mapCenter != null) {
                      _getAddressFromLatLng(mapCenter!);
                    }
                  });
                },
              ),

              // 2. Center Pin (Wrapped in IgnorePointer to pass touches to the map)
              IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFC62828), // Colors.red[800]
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 10),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 4,
                          height: 15,
                          color: const Color(0xFFC62828),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Floating Search Box & Results Dropdown
              Positioned(
                top: MediaQuery.of(context).padding.top +100,
                left: 15,
                right: 15,
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: autoCompleteSearch,
                        decoration: InputDecoration(
                          hintText: "Search location...",
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search, color: Colors.black54),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (predictions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10),
                          ],
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: predictions.length,
                          shrinkWrap: true,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = predictions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined, size: 20),
                              title: Text(
                                p.primaryText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                p.secondaryText ?? "",
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                FocusScope.of(context).unfocus(); // Dismiss keyboard
                                getLatlng(p.placeId);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // 4. Recenter Button
              Positioned(
                bottom: 180,
                right: 20,
                child: FloatingActionButton(
                  mini: true,
                  heroTag: "recenter_fab",
                  backgroundColor: Colors.white,
                  onPressed: _recenterToCurrentLocation,
                  child: Icon(Icons.my_location, color: Colors.red[800]),
                ),
              ),

              // 5. Address Card (Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.location_on, color: Colors.red[800]),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Selected Location",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  selectedLocation,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          onPressed: mapCenter == null
                              ? null
                              : () => Navigator.pop(context, {
                            "Location Name": selectedLocation,
                            "Latitude": mapCenter!.latitude,
                            "Longitude": mapCenter!.longitude,
                          }),
                          child: const Text(
                            "Confirm Location",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
    );
  }
}
