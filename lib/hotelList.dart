import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'hostelview/hostel.dart';
import 'locationbase/googlemaps.dart';

class _Amenity extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Amenity({required this.icon, required this.label, super.key});


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFC62828)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class Hotellist extends StatefulWidget {
  const Hotellist({super.key});

  @override
  State<Hotellist> createState() => _HotellistState();
}

class _HotellistState extends State<Hotellist> {
  final ScrollController _filterScrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isAialabilityloaded = false;

  bool sharingfilterVisible = true;
  String location = "Near you...";
  double? currentLatitude;
  double? currentLongitude;
  List<Map<String, dynamic>> hotels = [];
  List<Map<String, dynamic>> hotelInRange = [];
  Map<String, dynamic> bedsAvilability = {};

  bool isLoadingHotels = true;
  String gender = "all";
  int shringoption = 0;
  bool coliving = false;
  String Subscription = "monthly";

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _sortByPriceLowToHigh = false;
  bool _sortByPriceHighToLow = false;
  bool _sortByNearDistance = false;
  DateTime givedatenow() {
    return DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    sharingfilterVisible = gender != "co-living";
    _fromDate = DateTime(
        givedatenow().year, givedatenow().month, givedatenow().day, 12, 0, 0);
    _toDate = Subscription == "monthly"
        ? DateTime(
        _fromDate!.year, _fromDate!.month + 1, _fromDate!.day, 11, 0, 0)
        : DateTime(
        givedatenow().year, givedatenow().month, givedatenow().day + 1, 11, 0,
        0);
    _fetchCurrentLocation().then((value) {
      isLoadingHotels = false;
      fetchHotels().then((value) {
        isSharingAvialable( _fromDate, _toDate);
      });
    });
  }



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
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
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
  Map<String, double> minMaxLatLng() {
    final lat = currentLatitude!;
    final lng = currentLongitude!;
    const radiusKm = 15;
    final latDelta = radiusKm / 111;
    final lngDelta = radiusKm / (111 * cos(lat * pi / 180));
    return {
      'minLat': lat - latDelta,
      'maxLat': lat + latDelta,
      'minLng': lng - lngDelta,
      'maxLng': lng + lngDelta,
    };
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      helpText: "Select From Date",
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,          // Header background & selected day circle
              onPrimary: Colors.white,      // Header text & selected day text
              surface: Colors.white,        // Calendar background
              onSurface: Colors.black,      // Month/Year & default calendar text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // 'CANCEL' & 'OK' action buttons
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = DateTime(picked.year, picked.month, picked.day, 12, 0, 0);
        _toDate = Subscription == "monthly"
            ? DateTime(
            _fromDate!.year, _fromDate!.month + 1, _fromDate!.day, 11, 0, 0)
            : DateTime(
            _fromDate!.year, _fromDate!.month, _fromDate!.day + 1, 11, 0, 0);

        if(Subscription == "monthly")
            hotels=[];
          hotelInRange=[];
          isLoadingHotels = true;
          fetchHotels();


        if(Subscription != "monthly")
          _pickToDate();

      });

    }
  }

  Future<void> _pickToDate() async {
    if (_fromDate == null) return;
    final picked = Subscription!="monthly" ? await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate!.add(const Duration(days: 1)),
      firstDate: _fromDate!.add(const Duration(days: 1)),
      lastDate: _fromDate!.add(const Duration(days: 60),

      ),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,          // Header background & selected day circle
              onPrimary: Colors.white,      // Header text & selected day text
              surface: Colors.white,        // Calendar background
              onSurface: Colors.black,      // Month/Year & default calendar text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red, // 'CANCEL' & 'OK' action buttons
              ),
            ),
          ),
          child: child!,
        );
      },
    ):await showDatePicker(
      helpText: "Select To Date",
        context: context,
        initialDate: _toDate ?? _fromDate!.add(const Duration(days: 1)),
        firstDate: DateTime(
            _fromDate!.year, _fromDate!.month + 1, _fromDate!.day, 11, 0, 0),
        lastDate: DateTime(
            _fromDate!.year, _fromDate!.month + 1, _fromDate!.day, 11, 0, 0),
        builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.red,          // Header background & selected day circle
            onPrimary: Colors.white,      // Header text & selected day text
            surface: Colors.white,        // Calendar background
            onSurface: Colors.black,      // Month/Year & default calendar text
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // 'CANCEL' & 'OK' action buttons
            ),
          ),
        ),
        child: child!,
      );
    },
    );

    if (picked != null) {

      setState(() {
        _toDate = DateTime(picked.year, picked.month, picked.day, 11, 0, 0);
        hotels=[];
        hotelInRange=[];
        isLoadingHotels = true;
        fetchHotels();
      });
    }
  }

  @override
  void dispose() {
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          // PREMIUM PLATINUM HEADER
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, const Color(0xFFF5F6F8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          if (currentLatitude == null) return;
                          final selected = await Navigator.push<
                              Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GoogleMapPicker(
                                    currentLatitude: currentLatitude!,
                                    currentLongitude: currentLongitude!,
                                  ),
                            ),
                          );
                          if (selected != null) {
                            setState(() {
                              location = selected["Location Name"] ?? "";
                              currentLatitude = selected["Latitude"];
                              currentLongitude = selected["Longitude"];
                            });
                            fetchHotels();
                          }
                        },
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02),
                                  blurRadius: 5),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.location_on, color: Color(0xFFC62828),
                                  size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "Hostelhubb",
                      style: TextStyle(
                        fontSize: 22,
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FILTER ROW
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: SingleChildScrollView(
              controller: _filterScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SubscriptionType(),
                  const SizedBox(width: 10),
                  InkWell(onTap: _pickFromDate,
                      child: _DateBox(label: "From", date: _fromDate)),
                  const SizedBox(width: 10),
                  InkWell(onTap: _pickToDate,
                      child: _DateBox(label: "To", date: _toDate)),
                  const SizedBox(width: 10),
                  LivingType(),
                  const SizedBox(width: 10),
                  if (gender != "co-living") ...[
                    sharingType(),
                    const SizedBox(width: 10),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.tune, color: Colors.grey[700], size: 20),
                      onPressed: _showFilterOptions,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HOTEL LIST
          Expanded(
              child: isLoadingHotels? const Center(child: CircularProgressIndicator(
                color: Color(0xFFC62828),

              )
              ):
                  (currentLatitude == null && currentLongitude == null)
                  ? Center(child: Text("No hostels found.",
                  style: TextStyle(color: Colors.grey[500])))
                  :
              ListView.builder(
                itemCount: hotelInRange.length,
                itemBuilder: (context, index) {
                  final hotel = hotelInRange[index];
                  return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Hotelpage(
                                    collection: "Hotels",
                                    documentId: hotel['Hotel Id'],
                                    startdate:Timestamp.fromDate(_fromDate!),
                                    endDate: Timestamp.fromDate(_toDate!),
                                    Sharing: shringoption,
                                    StayTime: Subscription,
                                  ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // COMPACT IMAGE SECTION
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 140,
                                    width: double.infinity,
                                    child: PageView.builder(
                                      itemCount: (hotel['Room Photos'] as List?)
                                          ?.length ?? 0,
                                      itemBuilder: (context, pIndex) {
                                        final photos = hotel['Room Photos'] as List;
                                        return Image.network(
                                          photos[pIndex],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade300,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),

                                  // Gradient Overlay
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.45),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Gender Badge
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white24,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hotel['Gender'] == 'men'
                                                ? Icons.male
                                                : hotel['Gender'] == 'women'
                                                ? Icons.female
                                                : Icons.people,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (hotel['Gender'] ?? "All")
                                                .toString()
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Price Badge
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFD32F2F),
                                            Color(0xFFB71C1C),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "₹${hotel['Price']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Hotel Name
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: Text(
                                      hotel['Hotel Name'] ?? "Hostel Name",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14,
                                          color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          hotel['Location'] ??
                                              "Location unknown",
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "ID: ${hotel['Hotel Id'] ?? 'N/A'}",
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 28,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        if (hotel["Amenities"]?["AC"] ==
                                            true) const _Amenity(
                                            icon: Icons.ac_unit, label: "AC"),
                                        if (hotel["Amenities"]?["Parking"] ==
                                            true) const _Amenity(
                                            icon: Icons.local_parking,
                                            label: "Parking"),
                                        if (hotel["Amenities"]?["Wi-Fi"] ==
                                            true) const _Amenity(
                                            icon: Icons.wifi, label: "WiFi"),
                                        if (hotel["Amenities"]?["Gym"] ==
                                            true) const _Amenity(
                                            icon: Icons.fitness_center,
                                            label: "Gym"),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(
                                        color: Color(0xFFEEEEEE), height: 1),
                                  ),

                                  Row(
                                    children: [
                                      Text(
                                        "Sharing type:",
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      if (hotel["Gender"] != "co-living")
                                        Expanded(
                                          child: isAialabilityloaded? avialableBeds(hotel): Container(),
                                        ),

                                      if (hotel["Gender"] == "co-living")
                                        const Text(
                                          "Standard Premium",
                                          style: TextStyle(
                                            color: Color(0xFFC62828),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  )

                                ],
                              ),
                            ),
                          ],
                        ),
                      ));
                },
              )
          )
        ],
      ),
    );
  }

  Widget avialableBeds(hotel) {
    return SizedBox(
        height: 28, // Required
        child: hotel["Gender"] != "co-living" ? ListView
            .builder(
          scrollDirection: Axis.horizontal,
          itemCount: hotel["Sharing beds"].length,
          itemBuilder: (context, index) {
            final sharingData = bedsAvilability[hotel["Hotel Id"]];
            // !!! FIX: Read directly from sharingData, NOT from the function !!
            if (sharingData == null) return Container();

             if (hotel["Sharing beds"]["${index + 1}"] - sharingData["${index + 1}"]>0)
               return Container(
                   margin: const EdgeInsets.only(right: 6),
                   padding: const EdgeInsets.symmetric(
                     horizontal: 8,
                     vertical: 4,
                   ),
                   decoration: BoxDecoration(
                     color: const Color(0xFFE8F5E9),
                     borderRadius: BorderRadius.circular(6),
                   ),

                   child: Text("${index+1}",
                     style: const TextStyle(
                       color: Color(0xFF2E7D32),
                       fontSize: 9,
                       fontWeight: FontWeight.bold,
                     ),));
             else
               return SizedBox();
            /*Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),

              child: Text(
                "${hotel["Sharing beds"]["${index + 1}"]- sharingData["${index + 1}"]}",
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );*/
          },
        ) : hotel["No Rooms"] > bedsAvilability[hotel["Hotel Id"]] ? Text(
            "Premium Avialable") : Text("House full")
    );
  }

  Future<void> isSharingAvialable( DateTime? from,
      DateTime? to) async{
    if (isLoadingHotels == false)
      for (final host in hotelInRange) {
        Map<String, dynamic> sharings =
        Map<String, dynamic>.from(host["Sharing beds"] ?? {});
        if (host["Gender"] != "co-living") {
          sharings["1"] = await getCountOfsharingHostelSubScription(
              1, gender, host["Hotel Id"]);
          sharings["2"] = await getCountOfsharingHostelSubScription(
              2, gender, host["Hotel Id"]);
          sharings["3"] =await  getCountOfsharingHostelSubScription(
              3, gender, host["Hotel Id"]);
          sharings["4"] = await getCountOfsharingHostelSubScription(
              4, gender, host["Hotel Id"]);
          sharings["5"] = await getCountOfsharingHostelSubScription(
              5, gender, host["Hotel Id"]);
          setState(() {
            bedsAvilability[host["Hotel Id"]] = sharings;
          });
          //print(bedsAvilability);

        }

        else {
          bedsAvilability[host["Hotel Id"]] =
              getCountOfsharingHotelsSubscription(
                  1, gender, host["Hotel Id"]);
        }


      }
    setState(() {
      isAialabilityloaded = true;
    });

  }


  Future<int> getCountOfsharingHostelSubScription(sharing, gender,
      String hotelId) async {
    AggregateQuerySnapshot snapshotSubscriotion = await FirebaseFirestore
        .instance
        .collection('Bookings').where('Monthly',isEqualTo: false).where('AC',isEqualTo: false)
    .where("hotel ID", isEqualTo: hotelId)
    .where('sharing',isEqualTo: sharing)
        .where('startDate', isLessThan: Timestamp.fromDate(_toDate!))
        .where('endDate', isGreaterThan:Timestamp.fromDate(_fromDate!)).count()
        .get();
    //print(_toDate);
    //print(Timestamp.fromDate(_toDate!));

    AggregateQuerySnapshot snapshotm = await FirebaseFirestore.instance
        .collection('Bookings').
    where("AC", isEqualTo: false).where('Monthly',isEqualTo: true).
    where('hotel ID', isEqualTo: hotelId).
       where('sharing', isEqualTo: sharing).
    where('renewed', whereIn: [2,1,7]).
        count()
        .get();
    //print("${hotelId}-${sharing}");

    /*AggregateQuerySnapshot snapshotDayBookings = await FirebaseFirestore
        .instance
        .collection('Bookings')
        .where("AC", isEqualTo: false)
        .where('Sharing', isEqualTo: sharing).
    where('hotel ID', isEqualTo: hotelId)
        .where('Monthly', isEqualTo: false)
        .where('startDate', isLessThan: Timestamp.fromDate(_toDate!))
        .where('endDate', isGreaterThan: Timestamp.fromDate(_fromDate!))
        .count()
        .get();*/


    //print(snapshotm.count);
   // print(snapshotDayBookings.count);
   // print(sharing);
    //print(snapshotSubscriotion.count);
    int mon = (snapshotm.count ??0);// (snapshotDayBookings.count ??0);
    int day = (snapshotSubscriotion.count ??0);

    return mon + day;}


  Future<int> getCountOfsharingHotelsSubscription(sharing, gender,
      String hotelId) async {
    AggregateQuerySnapshot snapshotSubscriotion = await FirebaseFirestore
        .instance
        .collection('Bookings').where("Gender", isNotEqualTo: "co-living")
        .where("AC", isEqualTo: false).
    where('hotel ID', isEqualTo: hotelId).
    where('renewed', whereIn: [1, 7])
        .where('startDate', isLessThan: Timestamp.fromDate(_toDate!))
        .where('endDate', isGreaterThan: Timestamp.fromDate(_fromDate!))
        .count()
        .get();
    AggregateQuerySnapshot snapshotPending = await FirebaseFirestore.instance
        .collection('Bookings').where("Gender", isNotEqualTo: "co-living").
    where("AC", isEqualTo: false).
    where('hotel ID', isEqualTo: hotelId).
    where('renewed', whereIn: [2])
        .count()
        .get();
    AggregateQuerySnapshot snapshotDayBookings = await FirebaseFirestore
        .instance
        .collection('Bookings').where("Gender", isNotEqualTo: "co-living")
        .where("AC", isEqualTo: false).
    where('hotel ID', isEqualTo: hotelId)
        .where('Monthly', isEqualTo: false)
        .where('startDate', isLessThan: Timestamp.fromDate(_toDate!))
        .where('endDate', isGreaterThan: Timestamp.fromDate(_fromDate!))
        .count()
        .get();
    int avialableCount = (snapshotSubscriotion.count ?? 0) +
        (snapshotPending.count ?? 0) + (snapshotDayBookings.count ?? 0);

    return avialableCount;
  }




  Future<void> fetchHotels() async {
    if (currentLatitude == null) return;
    try {
      final minMax = minMaxLatLng();
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("Hotels")
          .where(
          "Location Details.Latitude", isGreaterThanOrEqualTo: minMax['minLat'])
          .where(
          "Location Details.Latitude", isLessThanOrEqualTo: minMax['maxLat'])
          .get();

      hotels =
          querySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
      setState(() => hotelInRange = hotels);
      filterHotels();
    } catch (e) {
      setState(() => isLoadingHotels = false);
    }
  }


  Future<int> getHotelCount() async {
    AggregateQuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Hotels')
        .where('city', isEqualTo: 'Hyderabad')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter & Sort", style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC62828))),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _sortByNearDistance,
                    title: const Text("Show Closest First"),
                    onChanged: (v) =>
                        setModalState(() => _sortByNearDistance = v!),
                  ),
                  CheckboxListTile(
                    value: _sortByPriceLowToHigh,
                    title: const Text("Price: Low to High"),
                    onChanged: (v) {
                      setModalState(() {
                        _sortByPriceLowToHigh = v!;
                        if (v) _sortByPriceHighToLow = false;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _sortByPriceLowToHigh = false;
                              _sortByNearDistance = false;
                            });
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text("Clear"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC62828)),
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text(
                              "Apply", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget LivingType() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: gender,
          style: TextStyle(color: Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w700),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Types')),
            DropdownMenuItem(value: 'men', child: Text('Men')),
            DropdownMenuItem(value: 'women', child: Text('Women')),
            DropdownMenuItem(value: 'co-living', child: Text('Co-living')),
          ],
          onChanged: (v) {
            setState(() {
              gender = v!;
              fetchHotels();
            });
          },
        ),
      ),
    );
  }

  Widget sharingType() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: shringoption,
          style: TextStyle(color: Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w700),
          items: const [
            DropdownMenuItem(value: 0, child: Text('Any Sharing')),
            DropdownMenuItem(value: 1, child: Text('1 Bed')),
            DropdownMenuItem(value: 2, child: Text('2 Bed')),
            DropdownMenuItem(value: 3, child: Text('3 Bed')),
            DropdownMenuItem(value: 4, child: Text('4 Bed')),
            DropdownMenuItem(value: 5, child: Text('5 Bed')),
          ],
          onChanged: (value){
            setState(() {
              shringoption = value!;

            });
            filterHotels();
          },
        ),
      ),
    );
  }

  Widget SubscriptionType() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: Subscription,
          style: TextStyle(color: Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w700),
          items: const [
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            DropdownMenuItem(value: 'day', child: Text('Daily')),
          ],
          onChanged:
          (value) {
            setState(() {
              Subscription = value!;
              if(Subscription == "day")
              _toDate=DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day+1, 11, 0, 0);
              if(Subscription == "monthly")
                _toDate=DateTime(_fromDate!.year, _fromDate!.month+1, _fromDate!.day, 11, 0, 0);
              fetchHotels();
            });
          }),
      ),
    );
  }

  void filterHotels() {
    setState(() {
      hotelInRange = hotels.where((hotele) {
        final String hotelGender = hotele["Gender"] ?? "";

        // 1. Gender Filter Check
        bool matchesGender = (gender == "all") || (hotelGender == gender);
        if (!matchesGender) return false;

        // 2. Sharing Option Filter Check
        if (shringoption > 0) {
          final Map? sharingbeds = hotele["Sharing beds"];
          final Map? sharingData = bedsAvilability[hotele["Hotel Id"]];

          // Safely extract values (handles String or int key types, defaulting to 0 if null)
          final int totalBeds = sharingbeds?["$shringoption"] ?? sharingbeds?[shringoption] ?? 0;
          final int takenBeds = sharingData?["$shringoption"] ?? sharingData?[shringoption] ?? 0;

          final int available = totalBeds - takenBeds;
          return available > 0;
        }

        return true;
      }).toList();

      isLoadingHotels = false;
    });
  }

  void isHotelAvailable(Map<String, dynamic> hotel, DateTime? from,
      DateTime? to,) {
    //int overlaps =  getCountOfsharingHotelsSubscription("1", gender, hotel["hotel ID"]);
    /*for (final booking in bookings.values) {
      if (booking["startDate"] == null) continue;
      final start = DateTime.parse(booking["startDate"]);
      final end = DateTime.parse(booking["endDate"]);
      if (from.isBefore(end) && to.isAfter(start)) overlaps++;
    }*/

  }

}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  const _DateBox({required this.label, this.date, super.key});
  @override
  Widget build(BuildContext context) {
    final text = date == null ? label : "${date!.day}/${date!.month}";
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 14, color: Color(0xFFC62828)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
