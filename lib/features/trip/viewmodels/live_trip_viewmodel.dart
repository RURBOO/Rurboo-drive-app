import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/driver_preferences.dart';
import '../../../core/services/polyline_service.dart';
import '../../../state/app_state_viewmodel.dart';
import '../models/live_trip_model.dart';

enum TripStage { arrivingToPickup, tripInProgress }

class LiveTripViewModel extends ChangeNotifier {
  final PolylineService _polyService = PolylineService();

  GoogleMapController? mapController;

  TripStage _currentStage = TripStage.arrivingToPickup;
  TripStage get currentStage => _currentStage;

  LiveTripDetails? tripDetails;

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

  Timer? _noShowTimer;
  bool canCancelWithoutPenalty = false;

  String tripEta = "Calculating...";

  Future<void> init(AppStateViewModel appState) async {
    isLoading = true;
    notifyListeners();

    try {
      currentRideId = appState.currentRideId;

      if (currentRideId == null) {
        currentRideId = await DriverPreferences.getCurrentRideId();
      }

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

    tripDetails = LiveTripDetails(
      riderName: (data['userName'] ?? "Rider").toString(),
      userPhone: (data['userPhone'] ?? "").toString(),
      pickupAddress: data['pickupAddress'] ?? 'Unknown Pickup',
      destinationAddress: data['destinationAddress'] ?? 'Unknown Drop',
      fare: (data['fare'] as num?)?.toDouble() ?? 0.0,
      rideOtp: data['otp']?.toString() ?? "0000",
    );

    _currentStage = data['status'] == 'in_progress'
        ? TripStage.tripInProgress
        : TripStage.arrivingToPickup;

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
    if (_currentStage == TripStage.arrivingToPickup) {
      _noShowTimer = Timer(const Duration(minutes: 5), () {
        canCancelWithoutPenalty = true;
        notifyListeners();
      });
    }
  }

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

          if (status == 'cancelled' || status == 'closed') {
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
          } catch (e) {}

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

  Future<bool> verifyOtpAndStartTrip(String inputOtp) async {
    if (tripDetails == null) return false;

    if (inputOtp == tripDetails!.rideOtp) {
      await FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId)
          .update({'status': 'in_progress'});

      _currentStage = TripStage.tripInProgress;

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

      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      final configDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('rates')
          .get();

      if (!driverDoc.exists) throw Exception("Driver profile missing");

      final driverData = driverDoc.data()!;
      final configData = configDoc.data();

      final double fare = tripDetails!.fare;

      final int trialDays = (configData?['trial_days'] ?? 15) as int;
      final double percent = (configData?['commission_percent'] ?? 15)
          .toDouble();
      final double minLimit =
          (configData?['min_wallet_balance_limit'] as num?)?.toDouble() ??
          -500.0;

      final Timestamp createdAtTs = driverData['createdAt'] ?? Timestamp.now();
      final DateTime joinedDate = createdAtTs.toDate();
      final int daysSinceJoining = DateTime.now().difference(joinedDate).inDays;

      double commissionAmount = 0.0;
      if (daysSinceJoining >= trialDays) {
        commissionAmount = (fare * percent) / 100;
      }

      final double currentWallet =
          (driverData['walletBalance'] as num?)?.toDouble() ?? 0.0;
      final double newWalletBalance = currentWallet - commissionAmount;

      final bool allowedOnline = newWalletBalance >= minLimit;

      final batch = FirebaseFirestore.instance.batch();

      final rideRef = FirebaseFirestore.instance
          .collection('rideRequests')
          .doc(currentRideId);

      final driverRef = FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId);

      final earningRef = driverRef.collection('earnings').doc();

      batch.update(rideRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'commissionDeducted': commissionAmount,
      });

      batch.set(earningRef, {
        'rideId': currentRideId,
        'amount': fare,
        'pickup': tripDetails!.pickupAddress,
        'drop': tripDetails!.destinationAddress,
        'grossAmount': fare,
        'commission': commissionAmount,
        'isTrial': daysSinceJoining < trialDays,
        'balanceAfter': newWalletBalance,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(driverRef, {
        'walletBalance': FieldValue.increment(-commissionAmount),
        'totalRides': FieldValue.increment(1),
        'isOnline': allowedOnline,
        'lastWalletUpdate': FieldValue.serverTimestamp(),
      });

      await batch.commit().timeout(const Duration(seconds: 10));
      await DriverPreferences.clearCurrentRideId();

      if (!allowedOnline) {
        appState.goOffline();
        if (context.mounted) {
          _showImmediateBlockDialog(context, newWalletBalance);
        }
      } else {
        appState.endTrip();
        if (context.mounted) {
          final msg = daysSinceJoining < trialDays
              ? "Free Trial Active. You kept 100% of fare."
              : "Trip ended. ₹${commissionAmount.toStringAsFixed(0)} platform fee deducted.";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: daysSinceJoining < trialDays
                  ? Colors.green
                  : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("End Trip Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error ending trip. Please check internet."),
          ),
        );
      }
    }
  }

  void _showImmediateBlockDialog(BuildContext context, double balance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("Credit Limit Reached"),
          content: Text(
            "Your wallet balance (₹${balance.toStringAsFixed(0)}) has crossed the limit.\n\n"
            "You have been taken Offline. Please clear dues to receive new rides.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

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
    tripEta = "Calculating...";
    notifyListeners();

    try {
      final routeInfo = await _polyService.getRouteData(start, end);

      if (routeInfo != null && routeInfo.points.isNotEmpty) {
        routePoints = routeInfo.points;

        final mins = routeInfo.durationMins.round();
        tripEta = mins < 1 ? "1 min" : "$mins mins";

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
