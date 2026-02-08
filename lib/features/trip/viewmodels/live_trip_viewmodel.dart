import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  bool _suspendAutoCamera = false;


  bool canCancelWithoutPenalty = false;

  String tripEta = "Calculating...";

  Future<void> init(AppStateViewModel appState) async {
    isLoading = true;
    notifyListeners();

    try {
      currentRideId = appState.currentRideId;

      currentRideId ??= await DriverPreferences.getCurrentRideId();

      if (currentRideId == null) {
        throw Exception("No active ride found");
      }

      final rideDoc = await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId)
          .get();

      if (!rideDoc.exists) {
        throw Exception("Ride does not exist");
      }

      _parseRideData(rideDoc.data()!);

      _listenToRideStatus();

      _startGpsBroadcast();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMsg = e.toString();
      isLoading = false;
      notifyListeners();
      debugPrint("LiveTrip init error: $e");
    }
  }

  void _parseRideData(Map<String, dynamic> data) {
    final pGeo = data['pickupCoords'] as GeoPoint;
    final dGeo = data['destinationCoords'] as GeoPoint;

    pickupLocation = LatLng(pGeo.latitude, pGeo.longitude);
    dropLocation = LatLng(dGeo.latitude, dGeo.longitude);

    if (data['driverLocation'] != null) {
      final dGeo = data['driverLocation'] as GeoPoint;
      driverLocation = LatLng(dGeo.latitude, dGeo.longitude);
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
    );

    _currentStage = data['status'] == 'in_progress'
        ? TripStage.tripInProgress
        : TripStage.arrivingToPickup;

    if (_currentStage == TripStage.arrivingToPickup) {
      _voiceService.announceNavigatingToPickup();
    } else {
      _voiceService.announceTripStarted();
    }

    _updateRouteLine();
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
            isRideEndApproved = true;
            isWaitingForApproval = false;
            notifyListeners();
          } else if (data?['endRideRejected'] == true) {
             isWaitingForApproval = false;
             isRideEndApproved = false;
             notifyListeners();
             // You might want to expose an error message or callback here
          }
          
          if (status == 'cancelled') {
            if (cancelledBy == 'user') {
               _voiceService.announceCustomerCancelled();
              _gpsStream?.cancel();
              onRideCancelledByUser?.call();
            }
            return;
          }

          if (status == 'closed') {
            _gpsStream?.cancel();
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
    );
    if (tripDetails == null) return false;

    if (inputOtp == tripDetails!.rideOtp) {
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId)
          .update({'status': 'in_progress'});

      _currentStage = TripStage.tripInProgress;
      
      _voiceService.announceTripStarted();

      await _updateRouteLine();

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> endTrip(BuildContext context, AppStateViewModel appState) async {
    if (currentRideId == null || tripDetails == null) return;

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) throw Exception("Driver ID not found");


      final configDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('rates')
          .get();

      final configData = configDoc.data();

      final double totalFare = tripDetails!.fare;
      final double percent =
          (configData?['commission_percent'] as num?)?.toDouble() ?? 20.0;
      final double commission = (totalFare * percent) / 100;

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      final rideRef = FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId);
      final driverRef = FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId);
      final earningsRef = driverRef.collection('earnings').doc();

      batch.update(rideRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'finalFare': totalFare,
        'commission': commission,
      });

      batch.update(driverRef, {
        'totalRides': FieldValue.increment(1),
        'dailyCommissionDue': FieldValue.increment(commission),
        'isOnline': true,
      });

      batch.set(earningsRef, {
        'rideId': currentRideId,
        'amount': totalFare,
        'commission': commission,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit().timeout(const Duration(seconds: 10));
      await DriverPreferences.clearCurrentRideId();

      appState.endTrip();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Trip Ended. ₹${commission.toStringAsFixed(0)} added to Today's Dues.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _voiceService.announceTripCompleted(totalFare.toStringAsFixed(0));
      
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
