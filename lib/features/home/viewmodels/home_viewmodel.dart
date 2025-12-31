import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

import '../../../core/utils/safe_parser.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../core/services/polyline_service.dart';
import '../../wallet/views/wallet_screen.dart';
import '../services/location_service.dart';

class RideRequest {
  final String id;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final String distance;
  final LatLng pickupLatLng;
  final LatLng destLatLng;

  RideRequest({
    required this.id,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.distance,
    required this.pickupLatLng,
    required this.destLatLng,
  });
}

class HomeViewModel extends ChangeNotifier {
  final PolylineService _polyService = PolylineService();

  bool _isDisposed = false;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  LatLng? _driverLocation;
  LatLng? get driverLocation => _driverLocation;

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<DocumentSnapshot>>? _rideSubscription;

  RideRequest? _newRideRequest;
  RideRequest? get newRideRequest => _newRideRequest;

  bool _isLocationReady = false;
  bool get isLocationReady => _isLocationReady;

  String? _driverVehicleType;

  final double _searchRadiusKm = 5.0;

  bool _hasInitialZoom = false;

  bool _hasLocationError = false;
  bool get hasLocationError => _hasLocationError;

  DateTime _lastGeoQueryTime = DateTime.now().subtract(
    const Duration(minutes: 1),
  );

  @override
  void dispose() {
    _isDisposed = true;
    _rideSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize(AppStateViewModel appState) async {
    _hasLocationError = false;
    notifyListeners();

    final locationService = LocationService();
    final latLng = await locationService.getCurrentLocation();

    if (latLng == null) {
      _hasLocationError = true;
      _isLocationReady = false;
      notifyListeners();
      return;
    }

    _driverLocation = latLng;
    _isLocationReady = true;
    _updateDriverMarker();

    if (mapController != null && !_hasInitialZoom) {
      mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 16),
      );
      _hasInitialZoom = true;
    }

    notifyListeners();

    if (appState.currentState == DriverState.online) {
      _startListeningToLocation();
      _startListeningToRides();
    }
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    final now = DateTime.now();
    if (now.difference(_lastNotify).inMilliseconds < 300) return;
    _lastNotify = now;
    notifyListeners();
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (_driverLocation != null && !_hasInitialZoom) {
      mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 16),
      );
      _hasInitialZoom = true;
    }
  }

  Future<void> _getCurrentLocationInstant() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _driverLocation = LatLng(position.latitude, position.longitude);
      _isLocationReady = true;
      _updateDriverMarker();

      if (mapController != null && !_hasInitialZoom) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_driverLocation!, 16),
        );
        _hasInitialZoom = true;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }
  }

  void _startListeningToLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isLocationReady = false;
      _safeNotifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _isLocationReady = false;
        _safeNotifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _isLocationReady = false;
      _safeNotifyListeners();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android &&
        (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always)) {
      final accuracyStatus = await Geolocator.getLocationAccuracy();

      if (accuracyStatus == LocationAccuracyStatus.reduced) {
        debugPrint("Approximate location detected. Forcing precise location.");

        _isLocationReady = false;
        _safeNotifyListeners();

        await Geolocator.openLocationSettings();
        return;
      }
    }

    _locationSubscription?.cancel();

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 3),

        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "You are Online",
          notificationText: "Receiving rides in background...",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (_isDisposed) return;

            _driverLocation = LatLng(position.latitude, position.longitude);
            _isLocationReady = true;
            _updateDriverMarker();

            if (_newRideRequest == null && mapController != null) {
              if (!_hasInitialZoom) {
                mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_driverLocation!, 16),
                );
                _hasInitialZoom = true;
              } else {
                mapController!.animateCamera(
                  CameraUpdate.newLatLng(_driverLocation!),
                );
              }
            }

            if (DateTime.now().difference(_lastGeoQueryTime).inSeconds > 45) {
              _startListeningToRides();
            }

            _safeNotifyListeners();
          },
          onError: (e) {
            debugPrint("GPS Error: $e");
            _isLocationReady = false;
            _safeNotifyListeners();
          },
        );
  }

  void _updateDriverMarker() {
    if (_driverLocation == null) return;

    final driverMarker = Marker(
      markerId: const MarkerId('me'),
      position: _driverLocation!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      rotation: 0,
    );

    if (_newRideRequest != null) {
      markers.removeWhere((m) => m.markerId.value == 'me');
      markers.add(driverMarker);
    } else {
      markers = {driverMarker};
    }
  }

  void _startListeningToRides() async {
    await _rideSubscription?.cancel();
    _rideSubscription = null;

    _lastGeoQueryTime = DateTime.now();

    if (_driverVehicleType == null) {
      _driverVehicleType = await DriverPreferences.getVehicleType();
      if (_driverVehicleType == null) {
        print("ERROR: Driver Vehicle Type is NULL. Cannot filter rides.");
        return;
      }
    }

    final CollectionReference<Map<String, dynamic>> collectionRef =
        FirebaseFirestore.instance.collection('rideRequests');

    final GeoFirePoint center = GeoFirePoint(
      GeoPoint(_driverLocation!.latitude, _driverLocation!.longitude),
    );

    print("LISTENER STARTED: Type='$_driverVehicleType' | Radius=50km");

    _rideSubscription = GeoCollectionReference(collectionRef)
        .subscribeWithin(
          center: center,
          radiusInKm: 5.0,
          field: 'pickupGeo',
          geopointFrom: (data) {
            if (data['pickupGeo'] != null &&
                data['pickupGeo']['geopoint'] != null) {
              return (data['pickupGeo'] as Map)['geopoint'] as GeoPoint;
            }
            return const GeoPoint(0, 0);
          },
          strictMode: true,
        )
        .listen((List<DocumentSnapshot<Map<String, dynamic>>> docs) {
          if (_isDisposed) return;

          RideRequest? foundRequest;
          double closestDist = double.infinity;

          print("FIRESTORE EVENT: Found ${docs.length} docs in radius.");

          for (var doc in docs) {
            final data = doc.data();
            if (data == null) continue;

            final String docId = doc.id;
            final String status = data['status'] ?? 'unknown';
            final String rideCategory = (data['vehicleCategory'] ?? '')
                .toString();
            final String driverCategory = _driverVehicleType ?? '';

            print("--- Checking Ride: $docId ---");
            print("Server Status: '$status'");
            print(
              "Server Category: '$rideCategory' vs Driver: '$driverCategory'",
            );

            bool isCategoryMatch =
                rideCategory.trim().toLowerCase() ==
                driverCategory.trim().toLowerCase();
            bool isStatusMatch = status == 'pending';

            if (isStatusMatch && isCategoryMatch) {
              final GeoPoint p = data['pickupCoords'];
              final GeoPoint d = data['destinationCoords'];

              double dist = Geolocator.distanceBetween(
                _driverLocation!.latitude,
                _driverLocation!.longitude,
                p.latitude,
                p.longitude,
              );

              print("MATCH FOUND! Distance: $dist meters");

              if (dist < closestDist) {
                closestDist = dist;
                foundRequest = RideRequest(
                  id: docId,
                  pickupAddress: SafeParser.toStr(data['pickupAddress']),
                  destinationAddress: SafeParser.toStr(
                    data['destinationAddress'],
                  ),
                  fare: SafeParser.toDouble(data['fare']),
                  distance: "${(dist / 1000).toStringAsFixed(1)} km",
                  pickupLatLng: LatLng(p.latitude, p.longitude),
                  destLatLng: LatLng(d.latitude, d.longitude),
                );
              }
            } else {
              print("SKIPPED: Status or Category mismatch.");
            }
          }

          if (_newRideRequest?.id != foundRequest?.id) {
            print("STATE UPDATE: New Ride = ${foundRequest?.id ?? 'NULL'}");
            _newRideRequest = foundRequest;

            if (_newRideRequest == null) {
              _clearRoute();
            }
            notifyListeners();
          }
        });
  }

  void _clearRoute() {
    polylines.clear();
    markers.removeWhere((m) => m.markerId.value != 'me');
  }

  Future<void> toggleOnlineStatus(
    bool newStatus,
    AppStateViewModel appState,
    BuildContext context,
  ) async {
    if (!newStatus) {
      appState.goOffline();
      _stopListeningToRides();
      _locationSubscription?.cancel();
      _isLocationReady = false;
      _clearRoute();
      notifyListeners();
      return;
    }

    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return;

    try {
      await _checkAndSettleDues(driverId);

      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();
      final double walletBalance =
          (doc.data()!['walletBalance'] as num?)?.toDouble() ?? 0.0;

      if (walletBalance < 0) {
        _showBlockScreen(
          context,
          walletBalance,
          "Daily Settlement Complete.\nYour wallet balance is negative (₹${walletBalance.toStringAsFixed(0)}).\n\nPlease recharge to start today's shift.",
        );
        notifyListeners();
        return;
      }

      _proceedOnline(appState);
    } catch (e) {}
  }

  void _showBlockScreen(BuildContext context, double balance, String msg) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 60,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              "Wallet Recharge Required",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Go to Wallet & Recharge",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedOnline(AppStateViewModel appState) {
    appState.goOnline();
    _startListeningToLocation();
    _startListeningToRides();
    _safeNotifyListeners();
  }

  Future<void> _simulateRecharge(BuildContext context, double amount) async {
    Navigator.pop(context);

    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return;

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .update({
          'walletBalance': FieldValue.increment(amount),
          'lastWalletUpdate': FieldValue.serverTimestamp(),
        });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment successful. You can go online now."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _stopListeningToRides() {
    _rideSubscription?.cancel();
    _rideSubscription = null;
    _newRideRequest = null;
  }

  Future<void> acceptRide(
    BuildContext context,
    AppStateViewModel appState,
  ) async {
    if (_newRideRequest == null) return;

    final String rideId = _newRideRequest!.id;
    final LatLng currentLoc = _driverLocation ?? const LatLng(0, 0);

    _stopListeningToRides();
    _locationSubscription?.cancel();
    notifyListeners();

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) throw Exception("Driver ID missing");

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final rideRef = FirebaseFirestore.instance
            .collection('rideRequests')
            .doc(rideId);
        final driverRef = FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId);

        final rideSnapshot = await transaction.get(rideRef);
        final driverSnapshot = await transaction.get(driverRef);

        if (!rideSnapshot.exists) throw Exception("Ride no longer exists");

        if (rideSnapshot.data()?['status'] != 'pending') {
          throw Exception(
            "Ride already accepted by another driver or cancelled",
          );
        }

        final driverData = driverSnapshot.data()!;

        transaction.update(rideRef, {
          'status': 'accepted',
          'driverId': driverId,
          'driverName': driverData['name'] ?? 'Driver',
          'driverPhone': driverData['phone'] ?? '',
          'carName': driverData['vehicleModel'] ?? 'Car',
          'carNumber': driverData['vehicleNumber'] ?? 'XXX',
          'driverRating': (driverData['rating'] as num?)?.toDouble() ?? 5.0,
          'driverLocation': GeoPoint(currentLoc.latitude, currentLoc.longitude),
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      await DriverPreferences.saveCurrentRideId(rideId);

      if (context.mounted) {
        Navigator.pop(context);
        appState.acceptRide(rideId);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        String errorMsg = "Something went wrong";
        if (e.toString().contains("already accepted") ||
            e.toString().contains("cancelled")) {
          errorMsg = "Ride was just taken by another driver.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }

      _startListeningToLocation();
      _startListeningToRides();
    }
  }

  Future<void> _checkAndSettleDues(String driverId) async {
    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final double commissionDue =
        (data['dailyCommissionDue'] as num?)?.toDouble() ?? 0.0;

    final Timestamp? lastSettlementTs = data['lastSettlementDate'];
    final DateTime now = DateTime.now();
    bool needsSettlement = true;

    if (lastSettlementTs != null) {
      final DateTime lastDate = lastSettlementTs.toDate();
      if (lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day) {
        needsSettlement = false;
      }
    }

    if (needsSettlement && commissionDue > 0) {
      print("Performing Daily Settlement: -₹$commissionDue");

      final batch = FirebaseFirestore.instance.batch();
      final driverRef = FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId);
      final walletRef = driverRef.collection('walletHistory').doc();

      batch.update(driverRef, {
        'walletBalance': FieldValue.increment(-commissionDue),
        'dailyCommissionDue': 0,
        'lastSettlementDate': FieldValue.serverTimestamp(),
      });

      batch.set(walletRef, {
        'amount': commissionDue,
        'type': 'debit',
        'description': 'Daily Settlement (Yesterday)',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } else if (needsSettlement && commissionDue == 0) {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({'lastSettlementDate': FieldValue.serverTimestamp()});
    }
  }

  void rejectRide() {
    _newRideRequest = null;
    _clearRoute();
    _safeNotifyListeners();
  }
}
