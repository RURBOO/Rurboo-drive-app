import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../../../core/utils/safe_parser.dart';
import '../../../state/app_state_viewmodel.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../core/services/driver_voice_service.dart';
import '../../../core/services/notification_service.dart';

import '../../wallet/views/wallet_screen.dart';
import '../services/location_service.dart';
import 'driver_voice_viewmodel.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';
import '../../../navigation/views/auth_gate.dart';

import '../../../core/models/ride_request.dart';
import '../../../core/models/help_request.dart';

class HomeViewModel extends ChangeNotifier {

  bool _isDisposed = false;
  DateTime _lastNotify = DateTime.fromMillisecondsSinceEpoch(0);

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  LatLng? _driverLocation;
  LatLng? get driverLocation => _driverLocation;
  
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<QuerySnapshot>? _rideSubscription;

  RideRequest? _newRideRequest;
  RideRequest? get newRideRequest => _newRideRequest;

  bool _isLocationReady = false;
  bool get isLocationReady => _isLocationReady;

  String? _driverVehicleType;
  late AppStateViewModel _appState;

  // final double _searchRadiusKm = 5.0; // Unused for now

  bool _hasInitialZoom = false;

  bool _hasLocationError = false;
  bool get hasLocationError => _hasLocationError;

  // Voice VM Injection
  DriverVoiceViewModel? _voiceVm;

  DateTime _lastGeoQueryTime = DateTime.now().subtract(
    const Duration(minutes: 1),
  );
  
  DateTime _lastLocationUpdate = DateTime.now().subtract(const Duration(seconds: 10));

  String? _mapStyle;
  String? get mapStyle => _mapStyle;

  @override
  void dispose() {
    _isDisposed = true;
    _rideSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize(AppStateViewModel appState, {DriverVoiceViewModel? voiceVm}) async {
    _appState = appState;
    if (voiceVm != null) _voiceVm = voiceVm;

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
    
    // Load dark map style
    rootBundle.loadString('assets/map_styles/dark_mode.json').then((style) {
      _mapStyle = style;
      notifyListeners();
    });

    if (_driverLocation != null && !_hasInitialZoom) {
      mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 16),
      );
      _hasInitialZoom = true;
    }
  }

  void recenterMap() {
    if (mapController != null && _driverLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 17),
      );
    }
  }
  
  Future<String?> getCurrentAddress() async {
    if (_driverLocation == null) return null;
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        _driverLocation!.latitude,
        _driverLocation!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Construct a readable address
        String address = "";
        if (place.name != null && place.name!.isNotEmpty) address += "${place.name}, ";
        if (place.subLocality != null && place.subLocality!.isNotEmpty) address += "${place.subLocality}, ";
        if (place.locality != null && place.locality!.isNotEmpty) address += place.locality!;
        
        return address.isEmpty ? "Unknown Location" : address;
      }
    } catch (e) {
      debugPrint("Address Fetch Error: $e");
    }
    return null;
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

            _currentPosition = position;
            _driverLocation = LatLng(position.latitude, position.longitude);
            _isLocationReady = true;
            _updateDriverMarker();

            // --- 🔹 LIVE TRACKING: Update Firestore for Admin/User ---
            if (DateTime.now().difference(_lastLocationUpdate).inSeconds > 5) {
               _lastLocationUpdate = DateTime.now();
               DriverPreferences.getDriverId().then((driverId) {
                 if (driverId != null) {
                   FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
                     'currentLocation': GeoPoint(position.latitude, position.longitude),
                     'heading': position.heading,
                     'speed': position.speed,
                     'lastLocationUpdate': FieldValue.serverTimestamp(),
                   }).catchError((e) => debugPrint("Location Sync Error: $e"));
                 }
               });
            }
            // ----------------------------------------------------------

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

    _driverVehicleType ??= await DriverPreferences.getVehicleType();
    debugPrint("LISTENER: Monitoring 'pending' rides. Driver Vehicle Type: $_driverVehicleType");

    // Listen to all pending rides and filter by distance client-side for maximum reliability
    _rideSubscription = FirebaseFirestore.instance
        .collection('rideRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (_isDisposed) return;
      debugPrint("LISTENER: Received snapshot with ${snapshot.docs.length} pending rides");

      if (_appState.currentState != DriverState.online) {
        return;
      }

      RideRequest? foundRequest;
      double closestDist = double.infinity;
      const double maxRadiusMeters = 20000; // 20km
      
      if (_driverLocation == null) {
        debugPrint("LISTENER: Driver location is null, skipping proximity check");
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final pickupCoords = data['pickupCoords'];
        if (pickupCoords == null) continue;

        final GeoPoint p = pickupCoords as GeoPoint;
        double dist = Geolocator.distanceBetween(
          _driverLocation!.latitude,
          _driverLocation!.longitude,
          p.latitude,
          p.longitude,
        );

        // Optional: Filter by category if driver has one
        final String rideCategory = (data['vehicleCategory'] ?? '').toString().toLowerCase();
        final String driverCategory = (_driverVehicleType ?? '').toLowerCase();
        bool categoryMatch = rideCategory == 'all' || rideCategory == driverCategory || rideCategory.isEmpty;

        debugPrint("LISTENER: Checking Ride[${doc.id}] - Dist: ${dist.toStringAsFixed(0)}m, Cat: $rideCategory (Driver: $driverCategory), Match: $categoryMatch");

        if (dist <= maxRadiusMeters && categoryMatch) {
          if (dist < closestDist) {
            closestDist = dist;
            final destCoords = data['destinationCoords'] as GeoPoint?;
            
            foundRequest = RideRequest(
              id: doc.id,
              pickupAddress: SafeParser.toStr(data['pickupAddress']),
              destinationAddress: SafeParser.toStr(data['destinationAddress']),
              fare: SafeParser.toDouble(data['fare']),
              distance: "${(dist / 1000).toStringAsFixed(1)} km",
              pickupLatLng: LatLng(p.latitude, p.longitude),
              destLatLng: destCoords != null 
                  ? LatLng(destCoords.latitude, destCoords.longitude)
                  : LatLng(p.latitude, p.longitude),
              userId: SafeParser.toStr(data['userId']),
              receiverName: SafeParser.toStr(data['receiverName']),
              receiverPhone: SafeParser.toStr(data['receiverPhone']),
              isBookForOthers: data['isBookForOthers'] == true,
            );
          }
        }
      }

      if (_newRideRequest?.id != foundRequest?.id) {
        _newRideRequest = foundRequest;
        if (_newRideRequest == null) {
          debugPrint("LISTENER: No suitable ride found in this snapshot.");
          _clearRoute();
        } else {
          _voiceVm?.announceNewRide(
            _newRideRequest!.pickupAddress,
            _newRideRequest!.distance
          );

          // Show notification with localizations if context available
          String title = "🚖 New Ride Request!";
          String body = "Pickup: ${_newRideRequest!.pickupAddress}";

          try {
            // If we had a global context or static l10n, we could use it here.
            // For now, these are the primary ones.
            // I'll use a simple bilingual string as a backup.
            title = "🚖 New Ride Request! / नई राइड!";
          } catch (_) {}

          NotificationService().showLocalNotification(
            title: title,
            body: body,
            payload: _newRideRequest!.id,
          );
        }
        _safeNotifyListeners();
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
    debugPrint("TOGGLE ONLINE: Requesting status -> $newStatus");
    final voiceService = DriverVoiceService();
    
    if (!context.mounted) {
      debugPrint("TOGGLE ONLINE: Context not mounted, aborting.");
      return;
    }

    if (!newStatus) {
      debugPrint("TOGGLE ONLINE: Going OFFLINE");
      voiceService.announceGoingOffline();
      appState.goOffline();
      _stopListeningToRides();
      _locationSubscription?.cancel();
      _isLocationReady = false;
      _clearRoute();
      notifyListeners();
      return;
    }

    // GPS Check before going online
    debugPrint("TOGGLE ONLINE: Checking GPS Readiness...");
    if (!_isLocationReady) {
      debugPrint("TOGGLE ONLINE: GPS not ready, attempting to fetch location...");
      final locationService = LocationService();
      final latLng = await locationService.getCurrentLocation();
      if (latLng != null) {
        _driverLocation = latLng;
        _isLocationReady = true;
        _hasLocationError = false;
        debugPrint("TOGGLE ONLINE: GPS Fixed: $latLng");
      } else {
        debugPrint("TOGGLE ONLINE: GPS Failed!");
        _hasLocationError = true;
        notifyListeners();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.gpsNotReady)),
          );
        }
        return;
      }
    }

    // AUTH CHECK
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.sessionInvalid)),
          );
       }
       return;
    }

    final driverId = await DriverPreferences.getDriverId();
    debugPrint("TOGGLE ONLINE: Driver ID: $driverId");
    
    if (driverId == null || user.uid != driverId) {
      if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.accountMismatch)),
          );
      }
      return; 
    }

    try {
      debugPrint("TOGGLE ONLINE: Checking and Settling Dues...");
      await _checkAndSettleDues(driverId);

      debugPrint("TOGGLE ONLINE: Fetching Wallet Balance...");
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();
      final double walletBalance =
          (doc.data()!['walletBalance'] as num?)?.toDouble() ?? 0.0;
      debugPrint("TOGGLE ONLINE: Wallet Balance: $walletBalance");

      if (context.mounted) {
        if (walletBalance < 0) {
          debugPrint("TOGGLE ONLINE: Blocked due to Negative Balance");
          voiceService.announceNegativeWallet();
          _showBlockScreen(
            context,
            walletBalance,
            AppLocalizations.of(context)!.negativeBalanceWarning,
          );
          notifyListeners();
          return;
        }

        debugPrint("TOGGLE ONLINE: Success! Proceeding Online.");
        voiceService.announceGoingOnline();
        _proceedOnline(appState);
      }
    } catch (e) {
      debugPrint("TOGGLE ONLINE ERROR: $e");
    }
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
            Text(
              AppLocalizations.of(context)!.walletRechargeRequired,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                child: Text(
                  AppLocalizations.of(context)!.goToWalletAndRecharge,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey)),
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



  void _stopListeningToRides() {
    _rideSubscription?.cancel();
    _rideSubscription = null;
    _newRideRequest = null;
  }

  void _stopListeningToLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
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

      // AUTH CHECK
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != driverId) {
        throw Exception("Auth Mistmatch. Please relogin.");
      }

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
        Navigator.pop(context); // Close loading dialog
        
        // Give the navigator a tick to process the pop before we swap the entire root widget tree
        Future.delayed(Duration.zero, () {
          if (!context.mounted) return;
          debugPrint("🚕 HomeViewModel: Triggering appState.acceptRide($rideId)");
          
          // 1. Shutdown all Home Screen listeners immediately
          _stopListeningToRides();
          _stopListeningToLocation();
          _newRideRequest = null;
          markers.clear();
          polylines.clear();
          notifyListeners();
          
          // 2. Update Global State
          appState.acceptRide(rideId);
          
          // 3. NUCLEAR OPTION: Forced Navigation Refresh
          // This wipes out any accidentally pushed MainNavigator copies and forces AuthGate rebuild
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
          
          // 🔊 VOICE ANNOUNCEMENT
          _voiceVm?.announceRideAccepted();
        });
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

    // If commission is 0, we don't need to do anything complex.
    // We can just skip the settlement logic to avoid permission issues
    // since we can't write to protected fields from the client anyway.
    if (commissionDue <= 0) {
      debugPrint("Settlement skipped: Commission Due is $commissionDue");
      return;
    }

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

    // NOTE: Real settlement (deducting balance) should be done by Cloud Functions.
    // The client only checks if it SHOULD be done to block the user if needed.
    // For now, we will just log it. The Cloud Function 'dailySettlement' handles the actual deduction.
    
    if (needsSettlement) {
       debugPrint("Daily Settlement Required for ₹$commissionDue. Waiting for Cloud Function.");
    }
  }

  void rejectRide() {
    _newRideRequest = null;
    _clearRoute();
    _safeNotifyListeners();
  }

  // ===========================================================================
  // 🛡️ DRIVER ALLIANCE (SOS/HELP) FEATURES
  // ===========================================================================

  StreamSubscription<List<DocumentSnapshot>>? _helpSubscription;
  HelpRequest? _nearbyHelpRequest;
  HelpRequest? get nearbyHelpRequest => _nearbyHelpRequest;

  bool _isHelpActive = false;
  bool get isHelpActive => _isHelpActive;
  String? _activeHelpId;

  // 1️⃣ REQUEST HELP (SOS)
  Future<void> requestHelp(BuildContext context, String type, String description) async {
    if (_driverLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not available!")),
      );
      return;
    }

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) return;

      final doc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
      final name = doc.data()?['name'] ?? 'Driver';
      final phone = doc.data()?['phone'] ?? '';

      final GeoFirePoint myLocation = GeoFirePoint(
        GeoPoint(_driverLocation!.latitude, _driverLocation!.longitude),
      );

      final helpData = {
        'driverId': driverId,
        'driverName': name,
        'driverPhone': phone,
        'type': type,
        'description': description,
        'status': 'active',
        'timestamp': FieldValue.serverTimestamp(),
        'location': myLocation.data,
      };

      final ref = await FirebaseFirestore.instance.collection('helpRequests').add(helpData);
      
      _activeHelpId = ref.id;
      _isHelpActive = true;
      notifyListeners();

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text("Help Signal Sent to nearby drivers!"),
             backgroundColor: Colors.redAccent,
             duration: Duration(seconds: 5),
           ),
        );
      }
    } catch (e) {
      debugPrint("Help Request Error: $e");
    }
  }

  // 2️⃣ CANCEL/RESOLVE HELP
  Future<void> resolveHelpRequest() async {
    if (_activeHelpId == null) return;
    
    try {
      await FirebaseFirestore.instance.collection('helpRequests').doc(_activeHelpId).update({
        'status': 'resolved',
      });
      _isHelpActive = false;
      _activeHelpId = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Resolve Help Error: $e");
    }
  }

  // 3️⃣ LISTEN FOR NEARBY HELP (Background Awareness)
  // Calling this inside _startListeningToLocation or initialize
  void startListeningToHelpRequests() {
    if (_helpSubscription != null) return;
    if (_driverLocation == null) return;

    final CollectionReference<Map<String, dynamic>> collectionRef =
        FirebaseFirestore.instance.collection('helpRequests');

    final GeoFirePoint center = GeoFirePoint(
      GeoPoint(_driverLocation!.latitude, _driverLocation!.longitude),
    );

    // Radius: 10km for help
    _helpSubscription = GeoCollectionReference(collectionRef).subscribeWithin(
      center: center,
      radiusInKm: 10.0, 
      field: 'location',
       geopointFrom: (data) {
          if (data['location'] != null && data['location']['geopoint'] != null) {
            return (data['location'] as Map)['geopoint'] as GeoPoint;
          }
          return const GeoPoint(0, 0);
       },
      queryBuilder: (query) => query.where('status', isEqualTo: 'active'),
      strictMode: true,
    ).listen((List<DocumentSnapshot> docs) async {
       if (_isDisposed) return;
       
       HelpRequest? closestHelp;
       double minDistance = double.infinity;
       final myId = await DriverPreferences.getDriverId();

       for (var doc in docs) {
         final data = doc.data() as Map<String, dynamic>;
         // Don't alert my own request
         if (data['driverId'] == myId) continue;

         final GeoPoint loc = (data['location'] as Map)['geopoint'];
         double dist = Geolocator.distanceBetween(
             _driverLocation!.latitude, _driverLocation!.longitude, 
             loc.latitude, loc.longitude
         );

         // Alert only if extremely close (e.g., 5km) or urgent
         if (dist < minDistance) {
            minDistance = dist;
            closestHelp = HelpRequest.fromFirestore(doc);
         }
       }

       if (closestHelp != null && _nearbyHelpRequest?.id != closestHelp.id) {
         _nearbyHelpRequest = closestHelp;
         notifyListeners();
         
         // 🔔 TRIGGER ALERT
         NotificationService().showLocalNotification(
           title: "🆘 Driver Needs Help!", 
           body: "${closestHelp.type.toUpperCase()}: ${closestHelp.distanceText(minDistance)} away.",
         );
         
         // Play Sound via Voice Service (or reuse Notification sound)
         _voiceVm?.announceGeneral("Alert. A driver needs help nearby.");
       }
    });
  }

  void dismissHelpAlert() {
    _nearbyHelpRequest = null;
    notifyListeners();
  }
}

extension HelpDistance on HelpRequest {
  String distanceText(double meters) {
    if (meters < 1000) return "${meters.toStringAsFixed(0)}m";
    return "${(meters / 1000).toStringAsFixed(1)}km";
  }
}

