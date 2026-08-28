import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../payments/paymentpage.dart';

class MyBookings extends StatefulWidget {
  const MyBookings({super.key});

  @override
  State<MyBookings> createState() => _MyBookingsState();
}

class _MyBookingsState extends State<MyBookings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime dateTimeNow = DateTime.now();
  bool isSubscriptions = true;

  @override
  Widget build(BuildContext context) {
    final phone = _auth.currentUser?.phoneNumber;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "My Stays",
          style: TextStyle(
            color: Color(0xFFC62828),
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildMetallicToggle(),
          ),
        ),
      ),
      body: phone == null
          ? const Center(child: Text("Please sign in to view your stays"))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection("Bookings").where("phone", isEqualTo: phone).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyView();
                }

                final allDocs = snapshot.data!.docs;

                final subscribedDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data["Monthly"] == true &&
                      (data['renewed'] == 1 || data['renewed'] == 2 || data['renewed'] == 3 || data['renewed'] == 4 || data['renewed'] == 7);
                }).toList().reversed.toList();

                final bookedDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['Monthly'] == false && (data['renewed'] == 0 || data['renewed'] == 5 || data['renewed'] == 6);
                }).toList().reversed.toList();

                var currentDocs = isSubscriptions ? subscribedDocs : bookedDocs;

                if (currentDocs.isEmpty) return _emptyView();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: currentDocs.length,
                  itemBuilder: (context, index) {
                    final data = currentDocs[index].data() as Map<String, dynamic>;
                    return _bookingCard(
                      bookingId: data['bookingId'] ?? "N/A",
                      hotel: data['hotel name'] ?? "Hotel",
                      checkIn: data["startDate"],
                      checkOut: data['endDate'] ?? "",
                      price: data['price']?.toString() ?? "0",
                      status: data['status'] ?? "pending",
                      renewed: data['renewed'] ?? 0,
                      monthly: data['Monthly'] ?? false,
                      hotelId: data['hotel ID'] ?? "",
                      checkedIn: data["checkedIn"] ?? false,
                      paymentIds: data["paymentIds"] ?? {},
                      sharing: data["sharing"],
                      refundInitiaed: data["refund Initiatd"] ?? false,
                      refundAmount: "${data["Refund Amount"] ?? '0'}",
                      complaintRaised: data["Complaint Raised"] ?? false,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildMetallicToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleButton("Subscriptions", isSubscriptions, () => setState(() => isSubscriptions = true))),
          Expanded(child: _buildToggleButton("One-time Stays", !isSubscriptions, () => setState(() => isSubscriptions = false))),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: active ? const Color(0xFFC62828) : Colors.grey[600],
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No booking history found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _bookingCard({
    required String bookingId,
    required String hotel,
    required Timestamp checkIn,
    required  Timestamp checkOut,
    required String price,
    required String status,
    required num renewed,
    required bool monthly,
    required String hotelId,
    required bool checkedIn,
    required Map<String, dynamic> paymentIds,
    required sharing,
    required bool refundInitiaed,
    required String refundAmount,
    required bool complaintRaised,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hotel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50), letterSpacing: -0.5)),
                      Text("Booking ID: $bookingId", style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (!complaintRaised)
                  IconButton(
                    onPressed: () => showIssuePopup(context, bookingId, hotelId),
                    icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF5F5F5)),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(

              children: [
                _buildInfoRow(Icons.calendar_today_rounded, "Check In", "${checkIn.toDate().day}/${checkIn.toDate().month}/${checkIn.toDate().year} | 12:00 PM"),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.logout_rounded, "Check Out", "${checkOut.toDate().day}/${checkOut.toDate().month}/${checkOut.toDate().year} | 11:00 AM"),
                const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(height: 1, color: Color(0xFFF5F5F5))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PAID AMOUNT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                        Text(
                          renewed == 0 ? "₹${paymentIds["paid"] ?? '0'}" : "₹${paymentIds["${paymentIds.length}"]?["paid"] ?? '0'}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                        ),
                      ],

                    ),


                    _buildStatusChip(renewed),

                  ],
                ),
                if( renewed!=7)
                if ((paymentIds["TobePaid"] ?? 0) != 0 || (paymentIds["1"]?["TobePaid"] ?? 0) != 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [

                      const Icon(Icons.info_outline, size: 12, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        renewed == 0 ? "Pay at hotel: ₹${paymentIds["TobePaid"]}" : "Pay at hotel: ₹${paymentIds["1"]?["TobePaid"]}",
                        style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),

                      if(checkIn.toDate().difference(dateTimeNow).inHours>2 &&( renewed != 4 && renewed != 5))
                        _deleteButton(hotelId, bookingId)

                    ],
                  ),
                ],
              ],
            ),
          ),

          if (renewed == 4 || renewed == 5) _buildRefundSection(refundAmount, refundInitiaed),
          _buildActionSection(checkedIn, renewed, hotelId, bookingId, checkIn),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFC62828)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
  Widget _deleteButton(hotelId, bookingId){
    return Container(
      alignment: Alignment.center,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.2))),

      child: TextButton(onPressed: (){
        showCancellationPolicyBottomSheet(context: context, onConfirm: () => showCancellationPolicyBottomSheet(context: context, onConfirm: () => CancelBooking(hotelId, bookingId)));
      }, child: const Text(
          "Cancell", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))),);
  }

  Widget _buildStatusChip(num renewed) {
    Color color;
    String text;
    switch (renewed) {
      case 0: color = Colors.blue; text = "Booked"; break;
      case 1: color = Colors.green; text = "Subscribed"; break;
      case 2: color = Colors.orange; text = "Pending Payment"; break;
      case 3: color = Colors.grey; text = "Expired"; break;
      case 4: color = Colors.red; text = "Cancelled"; break;
      case 5: color = Colors.red; text = "Cancelled"; break;
      case 6: color = Colors.blueGrey; text = "Stay Ended"; break;
      default: color = Colors.green; text = "Renewed"; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildRefundSection(String amount, bool initiated) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("REFUND AMOUNT: ₹$amount", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFC62828))),
          const SizedBox(height: 4),
          Text(initiated ? "Refund Initiated" : "Refund Processing (15 days)", style: TextStyle(fontSize: 11, color: Colors.red[300])),
        ],
      ),
    );
  }

  Widget _buildActionSection(bool checkedIn, num renewed, String hotelId, String bookingId, Timestamp checkIn) {
    bool canCancel = (renewed == 0 || renewed == 1) && !checkedIn &&
        DateTime(dateTimeNow.year, dateTimeNow.month, dateTimeNow.day).isAtSameMomentAs(DateTime(checkIn.toDate().day, checkIn.toDate().month, checkIn.toDate().year));
    bool canRenew = checkedIn && (renewed == 1 || renewed == 2 || renewed == 7);

    if (!canCancel && !canRenew) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          if (canRenew)
            Expanded(
              child: _buildMetallicButton("Renew Subscription", const Color(0xFFC62828), () => reneweBooking(hotelId, bookingId)),
            ),
          if (canCancel)
            Expanded(
              child: _buildMetallicButton("Cancel Stay", Colors.grey[800]!, () {
                showCancellationPolicyBottomSheet(context: context, onConfirm: () => showCancellationPolicyBottomSheet(context: context, onConfirm: () => CancelBooking(hotelId, bookingId)));
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildMetallicButton(String label, Color color, VoidCallback onTap) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  // --- REUSED LOGIC ---
  Future<void> reneweBooking(String hotelId, String bookingId) async {
    final bookingRef = _firestore.collection("Bookings").doc(bookingId);
    final hotelRef = _firestore.collection("Hotels").doc(hotelId);
    final bookingSnap = await bookingRef.get();
    final hotelSnap = await hotelRef.get();
    if (!bookingSnap.exists || !hotelSnap.exists) return;
    final data = bookingSnap.data()!;
    final hotelData = hotelSnap.data()!;
    final Map<String, dynamic> hotelBookings = Map<String, dynamic>.from(hotelData["bookings"] ?? {});
    final Map<String, dynamic> renewDates = Map<String, dynamic>.from(data["reneweddate"] ?? {});
    final Map<String, dynamic> paymentIds = Map<String, dynamic>.from(data["paymentIds"] ?? {});
    final Map<String, dynamic> pPrice = Map<String, dynamic>.from(hotelData["Sharing price"] ?? {});
    final Map<String, dynamic> acPrice = Map<String, dynamic>.from(hotelData["ac price"] ?? {});
    final price = data["AC"] ? acPrice[data["sharing"].toString()] : pPrice[data["sharing"].toString()];

    final payment = await Navigator.push(context, MaterialPageRoute(builder: (_) => RazorpayPage(price: price)));
    if (payment == null || payment["Success"] != true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Failed")));
      return;
    }

    DateTime due = data["endDate"].toDate();
    DateTime nextDue = DateTime(due.year, due.month + 1, due.day, 11, 0, 0);
    paymentIds["${paymentIds.length + 1}"] = {
      "pID": payment["PaymentId"],
      "Vendor Received": false,
      "PDate": DateTime.timestamp(),
      "Cancelled": false,
      "Returned to Customer": false,
      "price": price, "paid": price,
      "TobePaid": 0, "Refunded": false, "OnlineBooking": true, "paidAtHostel": 0, "paidOnline": price};
    renewDates["${renewDates.length + 1}"] = due.toString();
    hotelBookings[bookingId] =
    {"startDate": data["startDate"], "AC": data["AC"], "renewed": 7,
      "endDate": Timestamp.fromDate(nextDue),
      "bookingId": bookingId, "sharing": data["sharing"], "room number": data["room number"]};

    await _firestore.runTransaction((transaction) async {
      transaction.update(hotelRef, {"bookings": hotelBookings});
      transaction.update(bookingRef, {
        "paymentIds": paymentIds, "endDate": Timestamp.fromDate(nextDue),
        "reneweddate": renewDates, "renewed": 7, "status": "confirmed"});
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subscription Renewed")));
  }

  Future<void> CancelBooking(String hotelId, String bookingId) async {
    final bookingRef = _firestore.collection("Bookings").doc(bookingId);
    final hotelRef = _firestore.collection("Hotels").doc(hotelId);
    final bookingSnap = await bookingRef.get();
    if (!bookingSnap.exists) return;
    final data = bookingSnap.data()!;
    final bool monthly = data["Monthly"];
    final Map<String, dynamic> paymentIds = Map<String, dynamic>.from(data["paymentIds"] ?? {});


    await _firestore.runTransaction((transaction) async {
      transaction.update(hotelRef, {"renewed": monthly ? 4 : 5});
      transaction.update(bookingRef, {
        "canclledDate": DateTime.now().toString(),
        "renewed": monthly ? 4 : 5,
        "status": "Cancelled",
        "refund Initiatd": false,
        "Refund Amount": monthly
            ? paymentIds["1"]["paid"].toInt()/2// - ((paymentIds["1"]["paid"].toInt() + paymentIds["1"]["TobePaid"].toInt()) / 10)
            : paymentIds["paid"].toInt() /2//- ((paymentIds["paid"].toInt() + paymentIds["TobePaid"].toInt()) / 10),
      });
    });
  }

  void showCancellationPolicyBottomSheet({required BuildContext context, required VoidCallback onConfirm}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.grey[900]!, Colors.grey[800]!, Colors.black]), borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), border: Border.all(color: Colors.white10, width: 0.5)),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 25),
              const Text("Cancellation Policy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
              const SizedBox(height: 20),
              _buildPolicyRow("50% will be deducted from the paid amount."),
              _buildPolicyRow("Refund will be processed within 15 working days."),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red[700]!, Colors.red[900]!]), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
                child: ElevatedButton(onPressed: () { Navigator.pop(context); onConfirm(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Confirm Cancellation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPolicyRow(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("• ", style: TextStyle(color: Colors.red[400], fontSize: 16)), Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)))]));
  }

  Future<void> createComplaint({required String issueText, required String customerId, required String bookingId, required String hotelId}) async {
    final BookingRef = _firestore.collection("Bookings").doc(bookingId);
    final bookingIdRef = _firestore.collection("Complaints");
    final querySnapshot = await bookingIdRef.orderBy("complaintId", descending: true).limit(1).get();
    final newId = querySnapshot.docs.isEmpty ? 1 : int.parse(querySnapshot.docs.last.id) + 1;
    await _firestore.collection('Complaints').doc("$newId").set({
      "complaintId": "$newId", "createdDate": Timestamp.now(), "issue": issueText, "summary": "", "assignedTo": "", "isResolved": false, "customerId": customerId, "bookingId": bookingId, "HotelId": hotelId, "chat": {"${DateTime.now()}-$customerId": issueText},
    });
    BookingRef.update({"Complaint Raised": true});
  }

  void showIssuePopup(BuildContext context, String bookingId, hotelId) {
    final TextEditingController issueController = TextEditingController();
    bool isLoading = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Raise a Complaint", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(controller: issueController, maxLines: 4, decoration: const InputDecoration(labelText: "Describe your issue", border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text("Cancel")),
                          ElevatedButton(
                            onPressed: isLoading ? null : () async {
                              if (issueController.text.trim().isEmpty) return;
                              setState(() => isLoading = true);
                              await createComplaint(customerId: _auth.currentUser!.phoneNumber ?? "N/A", issueText: issueController.text.trim(), bookingId: bookingId, hotelId: hotelId);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint submitted")));
                            },
                            child: isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Submit"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
