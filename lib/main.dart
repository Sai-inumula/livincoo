import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livinco/homepage.dart';
import 'package:livinco/loginfile/loginpage.dart';

import 'notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyC12SrsmZ4cNeQiNA-fVI8NHWxqdR9daO0",
          appId: "1:213477575917:android:cfab56c4bab0f0cee110e4",
          messagingSenderId: "213477575917",
          projectId: "a-rooms",
          storageBucket: "a-rooms.firebasestorage.app",
        ),
      );
    }
  } catch (e) {
    // If Firebase is already initialized, we can safely continue.
    //debugPrint("Firebase initialization info: $e");
  }


  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider(),
    providerWeb: ReCaptchaV3Provider('123456'),
  );

  final notificationService = NotificationService();
  notificationService.initialize();

  await FirebaseMessaging.instance.subscribeToTopic("allUsers");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: myHome());
  }
}

class rcTocken {
  static final rcTocken _instance = rcTocken._internal();
  String? rtocken; // Made rtocken nullable
  factory rcTocken() => _instance;
  rcTocken._internal();
}

class myHome extends StatefulWidget {
  const myHome({super.key});

  @override
  State<myHome> createState() => _myHomeState();
}

class _myHomeState extends State<myHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          FirebaseAuth.instance.currentUser != null ? homeUser() : LoginPage(),
    );
  }
}
