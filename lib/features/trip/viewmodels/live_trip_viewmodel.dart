import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../views/driver_ride_summary_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/driver_preferences.dart';
import '../../../core/services/driver_voice_service.dart';
import '../../../core/services/polyline_service.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../../core/models/ride_request.dart';

enum TripStage { arrivingToPickup, tripInProgress }

class LiveTripViewModel extends ChangeNotifier {
  final PolylineService _polyService = PolylineService();
  final DriverVoiceService _voiceService = DriverVoiceService();

  GoogleMapController? mapController;

  TripStage _currentStage = TripStage.arrivingToPickup;
  TripStage get currentStage => _currentStage;

  RideRequest? tripDetails;

  LatLng? pickupLocation;
  LatLng? dropLocation;
  LatLng? driverLocation;

  String? currentRideId;
  bool isLoading = true;
  String? errorMsg;

  List<LatLng> routePoints = [];

  StreamSubscription<DocumentSnapshot>? _rideStream;
  StreamSubscription<Position>? _gpsStream;

  VoidCallback? onRideCancelledByUser;
  VoidCallback? onEndRideApproved;
  bool _suspendAutoCamera = false;


  bool canCancelWithoutPenalty = false;

  String tripEta = "Calculating...";

  // Localized Voice Strings
  String voiceNavigatingToPickup = "Navigating to pickup location.";
  String voiceTripStarted = "Trip started. Navigate to destination.";
  String voiceCustomerCancelled = "Customer has cancelled the ride.";
  String voiceTripCompletedPrefix = "Trip completed. Total fare rupees ";


  Future<void> init(AppStateViewModel appState) async {
    isLoading = true;
    errorMsg = null;
    notifyListeners();

    try {
      currentRideId = appState.currentRideId;
      debugPrint("🚀 LiveTripViewModel: Initializing for RideID: $currentRideId");

      currentRideId ??= await DriverPreferences.getCurrentRideId();
      debugPrint("🚀 LiveTripViewModel: Resolved RideID from Prefs: $currentRideId");

      if (currentRideId == null) {
        throw Exception("No active ride found in state or preferences.");
      }

      final rideDoc = await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId)
          .get();

      if (!rideDoc.exists) {
        throw Exception("Ride document ($currentRideId) does not exist in Firestore.");
      }

      final data = rideDoc.data();
      if (data == null) {
        throw Exception("Ride document ($currentRideId) contains no data.");
      }

      debugPrint("🚀 LiveTripViewModel: Ride data fetched successfully. Parsing...");
      _parseRideData(data);

      debugPrint("🚀 LiveTripViewModel: Starting listeners...");
      _listenToRideStatus();
      _startGpsBroadcast();

      isLoading = false;
      notifyListeners();
      debugPrint("🚀 LiveTripViewModel: Initialization complete.");
    } catch (e, stack) {
      errorMsg = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint("❌ LiveTripViewModel: Initialization error: $e");
      debugPrint("❌ LiveTripViewModel: Stack: $stack");
    }
  }

  void _parseRideData(Map<String, dynamic> data) {
    try {
      final pGeo = data['pickupCoords'] as GeoPoint?;
      final dGeo = data['destinationCoords'] as GeoPoint?;

      if (pGeo == null || dGeo == null) {
        throw Exception("Missing critical coordinates (pickup/destination) in ride data.");
      }

      pickupLocation = LatLng(pGeo.latitude, pGeo.longitude);
      dropLocation = LatLng(dGeo.latitude, dGeo.longitude);

      if (data['driverLocation'] != null) {
        final drGeo = data['driverLocation'] as GeoPoint;
        driverLocation = LatLng(drGeo.latitude, drGeo.longitude);
      } else {
        driverLocation = pickupLocation;
      }

      tripDetails = RideRequest(
        id: currentRideId!,
        riderName: (data['userName'] ?? "Rider").toString(),
        userPhone: (data['userPhone'] ?? "").toString(),
        pickupAddress: data['pickupAddress'] ?? 'Unknown Pickup',
        destinationAddress: data['destinationAddress'] ?? 'Unknown Drop',
        fare: (data['fare'] as num?)?.toDouble() ?? 0.0,
        distance: (data['distance'] ?? "0 km").toString(),
        pickupLatLng: pickupLocation!,
        destLatLng: dropLocation!,
        rideOtp: data['otp']?.toString() ?? "0000",
        userId: data['userId']?.toString() ?? "",
      );

      debugPrint("🚀 LiveTripViewModel: Status from DB is ${data['status']}");
      _currentStage = (data['status'] == 'in_progress')
          ? TripStage.tripInProgress
          : TripStage.arrivingToPickup;

      debugPrint("🚀 LiveTripViewModel: Final Stage resolved to $_currentStage");

      if (_currentStage == TripStage.arrivingToPickup) {
        _voiceService.speak(voiceNavigatingToPickup);
      } else {
        _voiceService.speak(voiceTripStarted);
      }

      _updateRouteLine();
    } catch (e) {
      debugPrint("❌ LiveTripViewModel: Parsing error: $e");
      rethrow;
    }
  }

  Future<void> callUser() async {
    final phone = tripDetails?.userPhone;
    if (phone == null || phone.isEmpty) {
      debugPrint("No user phone number found");
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phone);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
    }
  }

  void startNoShowTimer() {
    // Timer for no-show could be implemented here
    if (_currentStage == TripStage.arrivingToPickup) {
      canCancelWithoutPenalty = true;
      notifyListeners();
    }
  }

  bool isWaitingForApproval = false;
  bool isRideEndApproved = false;

  void _listenToRideStatus() {
    _rideStream = FirebaseFirestore.instance
        .collection('rideRequests')
        .doc(currentRideId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            onRideCancelledByUser?.call();
            return;
          }

          final data = snapshot.data();
          final status = data?['status'];
          final String? cancelledBy = data?['cancelledBy'];

          // Check approval status
          if (data?['endRideApproved'] == true) {
            bool wasNotApproved = !isRideEndApproved;
            isRideEndApproved = true;
            isWaitingForApproval = false;
            notifyListeners();
            if (wasNotApproved) {
              onEndRideApproved?.call();
            }
          } else if (data?['endRideRejected'] == true) {
             isWaitingForApproval = false;
             isRideEndApproved = false;
             notifyListeners();
             // You might want to expose an error message or callback here
          }
          
          if (status == 'cancelled') {
            if (cancelledBy == 'user') {
               _voiceService.speak(voiceCustomerCancelled);
              _gpsStream?.cancel();
              isWaitingForApproval = false;
              
              // CRITICAL FIX: Clear the ride immediately so the driver is not stuck
              DriverPreferences.clearCurrentRideId();
              
              notifyListeners();
              onRideCancelledByUser?.call();
            }
            return;
          }

          if (status == 'closed') {
            _gpsStream?.cancel();
            
            // CRITICAL FIX: Clear the ride immediately
            DriverPreferences.clearCurrentRideId();
            
            onRideCancelledByUser?.call();
            return;
          }

          if (status == 'in_progress' &&
              _currentStage != TripStage.tripInProgress) {
            _currentStage = TripStage.tripInProgress;
            _updateRouteLine();
            notifyListeners();
          }
        });
  }

  Future<void> requestEndRideApproval() async {
    if (currentRideId == null) return;
    try {
      isWaitingForApproval = true;
      notifyListeners();
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId)
          .update({
            'endRideRequested': true,
            'endRideRejected': false, // Reset rejection if trying again
            'endRideApproved': false,
          });
    } catch (e) {
      isWaitingForApproval = false;
      notifyListeners();
      debugPrint("Error requesting approval: $e");
      rethrow;
    }
  }

  Future<void> _startGpsBroadcast() async {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    _gpsStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((position) async {
          if (mapController == null) return;

          driverLocation = LatLng(position.latitude, position.longitude);

          try {
            if (!_suspendAutoCamera) {
              await mapController?.animateCamera(
                CameraUpdate.newLatLng(driverLocation!),
              );
            }
          } catch (e) {
            debugPrint("Camera update error: $e");
          }

          notifyListeners();

          if (currentRideId != null) {
            FirebaseFirestore.instance
                .collection('rideRequests')
                .doc(currentRideId)
                .update({
                  'driverLocation': GeoPoint(
                    position.latitude,
                    position.longitude,
                  ),
                })
                .onError(
                  (e, s) => debugPrint("Firestore loc update failed: $e"),
                );
          }
        });
  }

  Future<void> cancelRide(
    BuildContext context,
    AppStateViewModel appState,
  ) async {
    if (currentRideId == null) return;

    try {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              const Center(child: CircularProgressIndicator(color: Colors.red)),
        );
      }

      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId)
          .update({
            'status': 'cancelled',
            'cancelledBy': 'driver',
            'cancelledAt': FieldValue.serverTimestamp(),
          });

      await DriverPreferences.clearCurrentRideId();

      isWaitingForApproval = false;
      isRideEndApproved = false;
      notifyListeners();

      appState.endTrip();

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error cancelling: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> verifyOtpAndStartTrip(String inputOtp) async {
    tripDetails ??= RideRequest(
      id: "ride_dummy_${DateTime.now().millisecondsSinceEpoch}",
      pickupAddress: "123 Main St, City Center",
      destinationAddress: "456 Market Rd, Tech Park",
      fare: 250.0,
      distance: "5.2 km",
      pickupLatLng: const LatLng(37.4219983, -122.084),
      destLatLng: const LatLng(37.42796133580664, -122.085749655962),
      riderName: "Dummy Rider",
      userPhone: "1234567890",
      rideOtp: "0000",
      userId: "dummy_user_id",
    );
    if (tripDetails == null) return false;

    if (inputOtp == tripDetails!.rideOtp) {
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId)
          .update({'status': 'in_progress'});

      _currentStage = TripStage.tripInProgress;
      
      _voiceService.speak(voiceTripStarted);

      await _updateRouteLine();

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> endTrip(BuildContext context, AppStateViewModel appState) async {
    if (currentRideId == null || tripDetails == null) {
      throw Exception("Invalid Trip State: Missing Ride ID or Details");
    }

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) throw Exception("Driver ID not found");

      // AUTH CHECK
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != driverId) {
        throw Exception("Auth Session Invalid");
      }


      final double totalFare = tripDetails?.fare ?? 0.0;
      
      final rideRef = FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId);

      await rideRef.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'finalFare': totalFare,
      }).timeout(const Duration(seconds: 10));

      await DriverPreferences.clearCurrentRideId();

      appState.endTrip();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverRideSummaryScreen(
              rideId: currentRideId!,
              fare: totalFare,
              passengerName: tripDetails!.riderName,
              passengerId: tripDetails!.userId,
            ),
          ),
        );
      }
      
      _voiceService.speak("$voiceTripCompletedPrefix${totalFare.toStringAsFixed(0)}");
      
    } catch (e) {
      debugPrint("EndTrip Error: $e");
      rethrow; // Rethrow so SwipeButton knows it failed
    }
  }



  int? tripDurationMins;

  Future<void> _updateRouteLine() async {
    LatLng? start;
    LatLng? end;

    if (_currentStage == TripStage.arrivingToPickup) {
      start = driverLocation ?? pickupLocation;
      end = pickupLocation;
    } else {
      start = pickupLocation;
      end = dropLocation;
    }

    if (start == null || end == null) return;

    _suspendAutoCamera = true;

    routePoints = [start, end];
    tripDurationMins = null; // Reset to calculating
    notifyListeners();

    try {
      final routeInfo = await _polyService.getRouteData(start, end);

      if (routeInfo != null && routeInfo.points.isNotEmpty) {
        routePoints = routeInfo.points;
        tripDurationMins = routeInfo.durationMins.round();
        if (tripDurationMins! < 1) tripDurationMins = 1;

        notifyListeners();

        _fitCameraToRoute(routePoints);
      }
    } catch (e) {
      debugPrint("Route fetch failed: $e");
    } finally {
      _suspendAutoCamera = false;
    }
  }

  void _fitCameraToRoute(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLat = points.first.latitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  String get currentHeader => _currentStage == TripStage.arrivingToPickup
      ? "Arriving at Pickup"
      : "Dropping Customer";

  String get currentAddress => _currentStage == TripStage.arrivingToPickup
      ? tripDetails!.pickupAddress
      : tripDetails!.destinationAddress;

  LatLng get currentTarget => _currentStage == TripStage.arrivingToPickup
      ? pickupLocation!
      : dropLocation!;

  @override
  void dispose() {
    _gpsStream?.cancel();
    _rideStream?.cancel();
    mapController = null;
    super.dispose();
  }
}
