class LiveTripDetails {
  final String riderName;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final String rideOtp;
  final String userPhone;

  LiveTripDetails({
    required this.riderName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.rideOtp,
    required this.userPhone,
  });
}
