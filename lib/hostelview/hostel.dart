import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:livinco/payments/paymentpage.dart';

import '../payments/cashfree.dart';

class Hotelpage extends StatefulWidget {
  final String collection;
  final String documentId;
  final Timestamp startdate;
  final Timestamp endDate;
  final int Sharing;
  final String StayTime;

  const Hotelpage({
    required this.collection,
    required this.documentId,
    required this.startdate,
    required this.endDate,
    required this.Sharing,
    required this.StayTime,
    super.key,
  });

  @override
  State<Hotelpage> createState() => _HotelpageState();
}

class _HotelpageState extends State<Hotelpage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String hotelname = "";
  int sharing = 0;
  int TotalNoOfRooms = 0;
  Map<String, dynamic> hoteldata = {};
  bool selectedAC = false;

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchHotel() async {
    return FirebaseFirestore.instance
        .collection(widget.collection)
        .doc(widget.documentId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection(widget.collection).doc(widget.documentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Hostel not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String hotelName = data['Hotel Name'] ?? "";
          final String location = data['Location'] ?? "";
          final amenities = data['Amenities'] ?? {};

          TotalNoOfRooms = data["No Rooms"] ?? 0;
          hotelname = hotelName;
          hoteldata = data;

          List<dynamic> images = [
            ...?data['Room Photos'],
            ...?data['Lobby Potos'],
            ...?data["Washroom Photos"],
            ...?data['Building Photos'],
          ];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PREMIUM IMAGE GALLERY
                Stack(
                  children: [
                    SizedBox(
                      height: 350,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Hotel information
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ...
                        ],
                      ),
                    ),
                  ],
                ),

                // DETAILS CONTENT
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DATE SELECTION CARD
                        _buildPremiumSection(
                          title: "Stay Schedule",
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                _buildDateInfo("Check-in", widget.startdate, Icons.login),
                                Container(width: 1, height: 40, color: Colors.grey[200]),
                                _buildDateInfo("Check-out", widget.endDate, Icons.logout),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // PRICE & PAYMENT INFO
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("TOTAL PRICE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  Text(
                                    sharing == 0 ? "Select Sharing" : "₹${calculateTotalPrice(hoteldata)}",
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("PAY NOW", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),

                                  Text(
                                    "₹${(widget.StayTime == "monthly" ? calculateTotalPrice(hoteldata) / 10 : calculateTotalPrice(hoteldata) / 4).toStringAsFixed(0)}",
                                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.w900),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                        sharing!=0?Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Pay remaining at checkin"),
                        ):SizedBox.shrink(),

                        const SizedBox(height: 30),

                        // SELECTION SECTION
                        if (data["Gender"] == "co-living") ...[
                          _buildSelectionSection("Guest Selection (Non-AC)", _buildGuestSelector(false)),
                          const SizedBox(height: 20),
                          _buildSelectionSection("Guest Selection (AC)", _buildGuestSelector(true)),
                        ] else ...[
                          _buildSelectionSection("Sharing Type (Non-AC)", _buildSharingSelector(data, false)),
                          const SizedBox(height: 20),
                          _buildSelectionSection("Sharing Type (AC)", _buildSharingSelector(data, true)),
                        ],

                        const SizedBox(height: 30),

                        // AMENITIES
                        _buildPremiumSection(
                          title: "Amenities",
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (amenities["AC"] == true) _buildAmenityChip(Icons.ac_unit, "AC"),
                              if (amenities["Parking"] == true) _buildAmenityChip(Icons.local_parking, "Parking"),
                              if (amenities["Hot Water"] == true || amenities["Hot water"] == true) _buildAmenityChip(Icons.water_drop, "Hot Water"),
                              if (amenities["Gym"] == true) _buildAmenityChip(Icons.fitness_center, "Gym"),
                              if (amenities["Wi-Fi"] == true) _buildAmenityChip(Icons.wifi, "Wi-Fi"),
                              if (amenities["Pool"] == true) _buildAmenityChip(Icons.pool, "Pool"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ABOUT
                        _buildPremiumSection(
                          title: "About this property",
                          child: Text(
                            "Experience luxury living with premium facilities, strict safety standards, and a community of like-minded individuals. \n\n"
                            "• Check-in: 12:00 PM\n"
                            "• Check-out: 11:00 AM\n"
                            "• Valid ID proof mandatory",
                            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.6),
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
      bottomNavigationBar: _buildPremiumBottomBar(),
    );
  }

  Widget _buildPremiumSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50), letterSpacing: -0.5)),
        const SizedBox(height: 15),
        child,
      ],
    );
  }

  Widget _buildDateInfo(String label,Timestamp date, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: const Color(0xFFC62828)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text("${date.toDate().day}/${date.toDate().month}/${date.toDate().year}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFC62828)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSelectionSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildGuestSelector(bool isAC) {
    return Row(
      children: [1, 2].map((val) {
        bool isSelected = sharing == val && selectedAC == isAC;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() {
              selectedAC = isAC;
              sharing = val;
            }),
            child: _buildSelectionTile(val.toString(), isSelected),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSharingSelector(Map<String, dynamic> data, bool isAC) {
    Map<String, dynamic> avialability = isAC
        ? isACSharingAvialable(data, widget.startdate, widget.endDate)
        : isSharingAvialable(data, widget.startdate, widget.endDate);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [1, 2, 3, 4].map((val) {
          bool isAvailable = (avialability[val.toString()] ?? 0) > 0;
          bool isSelected = sharing == val && selectedAC == isAC;

          if (!isAvailable) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                selectedAC = isAC;
                sharing = val;
              }),
              child: _buildSelectionTile("${val} Sharing", isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectionTile(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFC62828) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFC62828).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildPremiumBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFFD32F2F).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => showBookingPolicySheet(context),
            child: const Text("Confirm & Pay", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
  Future<int> getCountOfsharingHostelSubScription(sharing, gender,
      String hotelId) async {
    AggregateQuerySnapshot day = await FirebaseFirestore
        .instance
        .collection('Bookings').where('Monthly',isEqualTo: false).where('AC',isEqualTo: false)
        .where("hotel ID", isEqualTo: hotelId)
        .where('sharing',isEqualTo: sharing)
        .where('startDate', isLessThan: widget.endDate)
        .where('endDate', isGreaterThan:widget.startdate).count()
        .get();

    AggregateQuerySnapshot mon = await FirebaseFirestore.instance
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


   // print(snapshotm.count);
    // print(snapshotDayBookings.count);
    // print(sharing);
    //print(snapshotSubscriotion.count);
    int month = (mon.count ??0);// (snapshotDayBookings.count ??0);
    int daily = (day.count ??0);

    return month + daily;
  }

  //---------------------Price Calculation & Logic (KEPT AS IS)----------------------------------

  int getNumberOfDays(start, end) {
    final startRaw =  start.toDate();
    final endRaw = end.toDate();
    final startDate = DateTime(startRaw.year, startRaw.month, startRaw.day);
    final endDate = DateTime(endRaw.year, endRaw.month, endRaw.day);
    return endDate.difference(startDate).inDays;
  }

  int calculateTotalPrice(Map<String, dynamic> data) {
    final bool isMonthly = widget.StayTime == 'monthly';
    final Map<String, dynamic> sharingPrice = data["Sharing price"] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> acsharing = data["ac price"] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> dayPrice = data["Day Price"] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> acdayPrice = data["acday price"] as Map<String, dynamic>? ?? {};
    final int pricePerUnit = isMonthly
        ? selectedAC ? (acsharing[sharing.toString()] ?? 0) : (sharingPrice[sharing.toString()] ?? 0)
        : selectedAC ? (acdayPrice[sharing.toString()] ?? 0) : (dayPrice[sharing.toString()] ?? 0);
    if (isMonthly) return pricePerUnit;
    return pricePerUnit * getNumberOfDays(widget.startdate, widget.endDate);
  }

  isSharingAvialable(hotel, from, to) {
    final Map<String, dynamic> beds = hotel["Sharing beds"] ?? {"1": 0, "2": 0, "3": 0, "4": 10};
    if (beds.values.every((value) => value == 0)) return beds;
    final Map<String, dynamic> bookings = Map<String, dynamic>.from(hotel["bookings"] ?? {});
    Map<String, dynamic> sharinglist = {"1": beds["1"] ?? 0, "2": beds["2"] ?? 0, "3": beds["3"] ?? 0, "4": beds["4"] ?? 0,"5":beds["5"] ?? 0};
    for (final entry in bookings.entries) {
      final booking = entry.value;
      if (booking["startDate"] == null || booking["endDate"] == null) continue;
      final Timestamp existingStart = booking["startDate"];
      final Timestamp existingEnd = booking["endDate"];
      final Timestamp fromDate = from;
      final Timestamp toDate = to;
      final bool isSubscribed = booking["renewed"] == 1 || booking["renewed"] == 2;
      final bool isOverlap = (fromDate.millisecondsSinceEpoch <existingEnd.microsecondsSinceEpoch) && (toDate.microsecondsSinceEpoch > existingStart.microsecondsSinceEpoch);
      final bool isAC = booking["AC"] ?? false;
      if ((isOverlap || isSubscribed) && !isAC) {
        sharinglist[booking["sharing"].toString()] = (sharinglist[booking["sharing"].toString()] ?? 0) - 1;
      }
    }
    return sharinglist;
  }

  isACSharingAvialable(hotel, from, to) {
    final Map<String, dynamic> beds = hotel["Ac beds"] ?? {"1": 0, "2": 0, "3": 0, "4": 10};
    if (beds.values.every((value) => value == 0)) return beds;
    final Map<String, dynamic> bookings = Map<String, dynamic>.from(hotel["bookings"] ?? {});
    Map<String, dynamic> sharinglist = {"1": beds["1"] ?? 0, "2": beds["2"] ?? 0, "3": beds["3"] ?? 0, "4": beds["4"] ?? 0};
    for (final entry in bookings.entries) {
      final booking = entry.value;
      if (booking["startDate"] == null || booking["endDate"] == null) continue;
      final existingStart = booking["startDate"];
      final existingEnd =  booking["endDate"];
      final Timestamp fromDate = from ;
      final Timestamp toDate = to;
      final bool isSubscribed = booking["renewed"] == 1 || booking["renewed"] == 2;
      final bool isAC = booking["AC"] ?? false;
      final bool isOverlap = (fromDate.millisecondsSinceEpoch < existingEnd.microsecondsSinceEpoch) && (toDate.microsecondsSinceEpoch > existingStart.microsecondsSinceEpoch);
      if ((isOverlap || isSubscribed) && isAC) {
        sharinglist[booking["sharing"].toString()] = (sharinglist[booking["sharing"].toString()] ?? 0) - 1;
      }
    }
    return sharinglist;
  }

  // ------------Bookings functions (KEPT AS IS)--------------------------
  Future<void> uploadSubscriptionColiving(String HotelName, price) async {
    final hotelRef = FirebaseFirestore.instance.collection(widget.collection).doc(widget.documentId);
    final bookingIdRef = FirebaseFirestore.instance.collection("Bookings");
    final bookingIdsnap = await bookingIdRef.get();
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(hotelRef);
      if (!snapshot.exists) throw Exception("Hotel not found");
      final data = snapshot.data()!;
      final int totalRooms = selectedAC ? data["Ac rooms"] : data["No Rooms"] ?? 0;
      final Map<String, dynamic> bookings = Map<String, dynamic>.from(data["bookings"] ?? {});
      Timestamp newStart = widget.startdate;
      Timestamp newEnd = widget.endDate;
      int overlaps = 0;
      for (final entry in bookings.entries) {
        final booking = entry.value;
        Timestamp existingStart = booking["startDate"];
        Timestamp existingEnd = booking["endDate"];
        int renewed = booking["renewed"] ?? 3;
        bool isOverlap = ((newStart.seconds < existingEnd.seconds) && (newEnd.seconds > existingStart.seconds)) || (renewed == 1 || renewed == 2);
        bool isAC = booking["AC"] ?? false;
        if (sharing <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("select Guest")));
          throw Exception("select Guest");
        }
        if (isOverlap && (selectedAC ? isAC == true : isAC == false)) overlaps++;
      }
      if (overlaps >= totalRooms) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No rooms available")));
        throw Exception("No rooms available");
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CashfreeApiPage(price: widget.StayTime == "monthly" ?
            calculateTotalPrice(data) / 10 : calculateTotalPrice(data) / 4,)
        ),
      );
     /* Map<String, dynamic> payment = await Navigator.push(context, MaterialPageRoute(builder: (context) =>
          RazorpayPage(price: widget.StayTime == "monthly" ? calculateTotalPrice(data) / 10 : calculateTotalPrice(data) / 4)));*/
      int bookingId = int.parse("${bookingIdsnap.docs.last.id}") + 1;
      if (result["Success"] == true) {
        bookings["${bookingId}"] = {
          "AC": selectedAC,
          "startDate": widget.startdate, "renewed": widget.StayTime == "monthly" ? 1 : 0,
          "endDate": widget.endDate, "bookingId": "${bookingId}", "sharing": sharing, "room number": 1};
        bookings["${bookingId}"] = {"AC": selectedAC,
          "startDate": widget.startdate, "renewed": widget.StayTime == "monthly" ? 1 : 0,
          "endDate": widget.endDate, "bookingId": "${bookingId}", "sharing": sharing, "room number": 1};
        bookingIdRef.doc("${bookingId}").set({"AC": selectedAC,
          "Monthly": widget.StayTime == "monthly", "checkedIn": false, "hotel ID":
          widget.documentId, "startDate": widget.startdate, "reneweddate": {"1": widget.startdate},
          "payment Dates": {"1": DateTime.now().toString()},
          "renewed": widget.StayTime == "monthly" ? 1 : 0,
          "paymentIds": widget.StayTime == "monthly" ? {"1": {"pID": result["PaymentId"], "Vendor Received": false, "PDate": DateTime.now().toString(), "Cancelled": false,
            "Returned to Customer": false, "price": price, "paid": price / 10, "TobePaid": price - (price / 10), "OnlineBooking": true}} : {"paymentId": result["PaymentId"], "Vendor Received": false, "PDate": DateTime.now().toString(), "Cancelled": false, "Returned to Customer": false, "price": price, "paid": price / 4, "TobePaid": price - price / 4, "OnlineBooking": true}, "endDate": widget.endDate, "createdAt": FieldValue.serverTimestamp(), "bookingId": "${bookingId}", "phone": "${FirebaseAuth.instance.currentUser!.phoneNumber}", "status": "Confirmed", "hotel name": HotelName, "price": price, "sharing": sharing, "room number": 0, "Dated on": "${DateTime.now().day - DateTime.now().month - DateTime.now().year}"});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subscription successful")));
        setState(() {
          sharing=0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("payment unsuccessful")));
        setState(() {
          sharing=0;
        });
      }

    });

  }

  Future<void> uploadSubscriptionHostel(String HotelName, price) async {
    final hotelRef = FirebaseFirestore.instance.collection(widget.collection).doc(widget.documentId);
    final bookingIdRef = FirebaseFirestore.instance.collection("Bookings");
    final QuerySnapshot querySnapshot = await bookingIdRef.orderBy("bookingId", descending: true).limit(1).get();
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(hotelRef);
      if (!snapshot.exists) throw Exception("Hotel not found");
      final data = snapshot.data()!;
      final Map<String, dynamic> bookings = Map<String, dynamic>.from(data["bookings"] ?? {});
      Timestamp newStart = widget.startdate;
      Timestamp newEnd = widget.endDate;
      Map<String, dynamic> avialability = selectedAC ? isACSharingAvialable(data, newStart, newEnd) : isSharingAvialable(data, newStart, newEnd);
      if (sharing <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("select sharing")));
        throw Exception("select sharing");
      }
      if (avialability["${sharing}"] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No rooms available")));
        throw Exception("No rooms available");
      }
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CashfreeApiPage(price: widget.StayTime == "monthly" ?
          calculateTotalPrice(data) / 10 : calculateTotalPrice(data) / 4,)
        ),
      );
     /* Map<String, dynamic> payment = await Navigator.push(context,
          MaterialPageRoute(builder: (context) => RazorpayPage(price: widget.StayTime == "monthly" ?
          calculateTotalPrice(data) / 10 : calculateTotalPrice(data) / 4)));*/


      int bookingId = int.parse("${querySnapshot.docs.last.id}") + 1;
      if (result["Success"] == true) {
        hotelRef.update({"bookings.$bookingId": {"AC": selectedAC,
          "startDate":newStart,
          "renewed": widget.StayTime == "monthly" ? 1 : 0,
          "endDate": newEnd,
          "bookingId": "${bookingId}", "sharing": sharing, "room number": 0}});
        bookingIdRef.doc("${bookingId}").set({"AC": selectedAC,
          "Monthly": widget.StayTime == "monthly", "checkedIn": false,
          "hotel ID": widget.documentId, "startDate": widget.startdate,
          "reneweddate": {'1': widget.startdate},
          "payment Dates": {"1": DateTime.now().toString()},
          "renewed": widget.StayTime == "monthly" ? 1 : 0,
          "renewed": widget.StayTime == "monthly" ? 1 : 0,
          "paymentIds": widget.StayTime == "monthly" ?
          {"1": {"pID": result["PaymentId"],
            "Vendor Received": false, "PDate": DateTime.now().toString(),
            "Cancelled": false,
            "Returned to Customer": false,
            "price": price,
            "paid": price / 10,
            "paidAtHostel":0,
            "paidOnline":price / 10,
            "TobePaid": price - price / 10,
            "OnlineBooking": true}} :
          {"paymentId": result["PaymentId"],
            "paidAtHostel":0,
            "paidOnline":price / 4,
            "Vendor Received": false, "PDate": DateTime.now().toString(),
            "Cancelled": false, "Returned to Customer": false, "price": price,
            "paid": price / 4, "TobePaid": price - price / 4, "OnlineBooking": true},
          "endDate": widget.endDate, "createdAt": FieldValue.serverTimestamp(),
          "bookingId": "${bookingId}", "phone": "${FirebaseAuth.instance.currentUser!.phoneNumber}",
          "status": "Confirmed", "hotel name": HotelName, "price": price, "sharing": sharing,
          "room number": 0, "Dated on": "${DateTime.now().day / DateTime.now().month / DateTime.now().year}"});
        await FirebaseMessaging.instance.subscribeToTopic("$bookingId");
        transaction.update(hotelRef, {"bookings": bookings});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subscription successful")));
        setState(() {
          sharing=0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("payment unsuccessful")));
        setState(() {

          sharing=0;
        });
      }
    });
  }

  void showBookingPolicySheet(BuildContext context) {
    bool isChecked = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text("Booking Policy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  const Text("Cancellation Policy:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("• No free cancellation.\n• 50% amount will be deducted from amount paid in advance on cancellation.\n• Remaining amount will be refunded.\n• Refund will be processed within 15-20 working days.\n• Cancellation allowed only Up to Before 2 hours of check In", style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  const Text("Booking Policy:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("• Valid ID proof is mandatory at check-in.\n• Only in Coliving: Unmarried couples are allowed.\n • Pets are not allowed.\n• Check-in time: 12:00 PM\n• Check-out time: 11:00 AM", style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(children: [Checkbox(value: isChecked, onChanged: (value) => setState(() => isChecked = value!)), const Expanded(child: Text("I agree to the booking & cancellation policy", style: TextStyle(fontSize: 13)))]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: isChecked ? () async { Navigator.pop(context); if (hoteldata["Gender"] == "co-living") { await uploadSubscriptionColiving(hotelname, calculateTotalPrice(hoteldata)); } else { await uploadSubscriptionHostel(hotelname, calculateTotalPrice(hoteldata)); } } : null, child: const Text("Confirm Booking"))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
