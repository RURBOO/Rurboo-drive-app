import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideRequest {
  final String id;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final String distance;
  final LatLng pickupLatLng;
  final LatLng destLatLng;
  final String riderName;
  final String userPhone;
  final String rideOtp;

  RideRequest({
    required this.id,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.distance,
    required this.pickupLatLng,
    required this.destLatLng,
    this.riderName = "Rider",
    this.userPhone = "",
    this.rideOtp = "0000",
  });
}
