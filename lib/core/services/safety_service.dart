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

  /// Sends an emergency alert to Firestore (Simulated for now)
  Future<void> sendEmergencyAlert(String rideId, String location) async {
    // TODO: Implement actual Firestore trigger
    debugPrint("SOS Alert Sent for Ride: $rideId at $location");
  }
}
