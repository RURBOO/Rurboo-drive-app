// Notification service - Firebase Cloud Messaging
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'driver_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final notification = message.notification;
  if (notification != null) {
    final service = NotificationService();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_notify');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    await service._localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // CRITICAL: Channel must be created in background isolate
    // Android 8+ silently drops notifications if channel doesn't exist here
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ride_request_channel',
      'Ride Alerts',
      description: 'High priority alerts for new rides',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alert_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList(const [0, 1000, 500, 1000, 500, 1000]), // ✅ Added
    );
    await service._localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.showLocalNotification(
      title: notification.title ?? "New Ride Request!",
      body: notification.body ?? "Check the app for details.",
    );
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint("Notification Permission Denied");
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_notify');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ride_request_channel',
      'Ride Alerts',
      description: 'High priority alerts for new rides',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alert_sound'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList(const [
        0, 1000, 500, 1000, 500, 1000,
      ]),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("☀️ Foreground Message: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    await _saveToken();
    _fcm.onTokenRefresh.listen(_updateTokenInFirestore);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ride_request_channel',
      'Ride Alerts',
      channelDescription: 'High priority alerts for new rides',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alert_sound'),
      icon: '@drawable/ic_stat_notify',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 20000, // ✅ 20 seconds
      additionalFlags: Int32List.fromList([4]),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
      );
    }
  }

  Future<void> _saveToken() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _updateTokenInFirestore(token);
    }
  }

  Future<void> _updateTokenInFirestore(String token) async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId != null) {
      debugPrint("🔥 FCM Token: $token");
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
    }
  }
}
