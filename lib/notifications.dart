import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';
// Make sure you're importing the main.dart for the navigatorKey

Future<void> handler(RemoteMessage message) async {
  if (message != null) {}
}

Future<void> handleMessage(RemoteMessage? message) async {
  if (message != null) {}
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future initpushNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  // Initialize the notification service
  Future<void> initialize() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      //print('Failed to request notification permissions: $e');
    }
    initpushNotification();
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);
    try {
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      //print('Failed to initialize local notifications plugin: $e');
    }

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'heads_up_channel', // Channel ID
      'Heads-Up Notifications', // Channel name
      description: 'Channel for floating notifications.',
      importance: Importance.high,
      playSound: true,
    );
    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      //print('Failed to create notification channel: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      //print('Subscribed to topic: $topic');
    } catch (e) {
      //print('Failed to subscribe to topic: $e');
    }
  }

  Future<void> unsubScribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {}
  }

  // Use navigatorKey to navigate
}

class GlobalState {
  static final GlobalState _instance = GlobalState._internal();
  late String uniqueId; // Variable to hold the unique ID

  factory GlobalState() {
    return _instance; // Return the singleton instance
  }

  GlobalState._internal(); // Private constructor
}

class notificationScreen extends StatefulWidget {
  const notificationScreen({Key? key}) : super(key: key);
  static const route = '/ntification-screen';

  @override
  State<notificationScreen> createState() => _notificationScreenState();
}

class _notificationScreenState extends State<notificationScreen> {
  @override
  Widget build(BuildContext context) {
    final message = ModalRoute.of(context)!.settings.arguments;

    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("hyhyhyhyhyhyhyhyhyhy")],
        ),
      ),
    );
  }
}
