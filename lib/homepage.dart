import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livinco/bookings/bookingslist.dart';
import 'package:livinco/hotelList.dart';
import 'package:livinco/profilepage/profile.dart';

class homeUser extends StatefulWidget {
  const homeUser({super.key});

  @override
  State<homeUser> createState() => _homeUserState();
}

class _homeUserState extends State<homeUser> {
  int Index = 0;
  List pages = [Hotellist(), MyBookings(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
        statusBarBrightness: Brightness.light, // For iOS (dark icons)
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black38,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: BottomNavigationBar(
              elevation: 0,
              iconSize: 26,
              currentIndex: Index,
              selectedItemColor: const Color(0xFFC62828),
              unselectedItemColor: Colors.grey[400],
              backgroundColor: Colors.transparent,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              onTap: (i) => setState(() => Index = i),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.grid_view_rounded),
                  ),
                  label: "Explore",
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.confirmation_number_outlined),
                  ),
                  label: "My Stays",
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.person_2_outlined),
                  ),
                  label: "Account",
                ),
              ],
            ),
          ),
        ),
      ),
      body: pages[Index],
    ));
  }
}
