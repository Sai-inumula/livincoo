/*import 'package:flutter/material.dart';

class hostelListPage extends StatefulWidget {
  const hostelListPage({super.key});

  @override
  State<hostelListPage> createState() => _hostelListPageState();
}

class _hostelListPageState extends State<hostelListPage> {

  final ScrollController _filterScrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> _fetchCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          location = "Hyderabad";
          currentLatitude = 17.3850;
          currentLongitude = 78.4867;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          location = "Hyderabad";
          currentLatitude = 17.3850;
          currentLongitude = 78.4867;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          location = "${p.name}, ${p.subLocality}, ${p.locality}";
        });
      }
    } catch (e) {
      setState(() {
        location = "Hyderabad";
        currentLatitude = 17.3850;
        currentLongitude = 78.4867;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(stream: , builder: builder),
    );
  }
}*/
