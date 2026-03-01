import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class SafetyService {
  static const String policeNumber = "100"; // India Police
  static const String ambulanceNumber = "102"; // India Ambulance

  /// Calls the police directly
  Future<void> callPolice() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: policeNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  /// Calls the ambulance directly
  Future<void> callAmbulance() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: ambulanceNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  /// Sends an emergency alert to Firestore
  Future<void> sendEmergencyAlert(String? rideId, String? location) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('sos_incidents').add({
        'driverId': user.uid,
        'userId': null, // Can be populated if rideId is provided and fetched
        'timestamp': FieldValue.serverTimestamp(),
        'rideId': rideId,
        'status': 'active',
        'type': 'driver_sos',
        'location': location,
        'source': 'driver_app',
      });
      debugPrint("✅ SOS Incident Logged to Backend");
    } catch (e) {
      debugPrint("❌ Failed to log SOS: $e");
    }
  }
}
