import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DriverState { signedOut, offline, online, onTrip }

class AppStateViewModel extends ChangeNotifier {
  static const _stateKey = 'driverState';
  static const _rideIdKey = 'currentRideId';

  DriverState _currentState = DriverState.signedOut;
  DriverState get currentState => _currentState;

  // True while the initial state is being loaded from persistent storage.
  // The UI should show a loading indicator until this is false.
  bool isLoading = true;

  StreamSubscription<DocumentSnapshot>? _driverStatusSub;

  String? currentRideId;

  AppStateViewModel() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateIndex = prefs.getInt(_stateKey) ?? DriverState.signedOut.index;
    _currentState = DriverState.values[stateIndex];
    currentRideId = prefs.getString(_rideIdKey);
    isLoading = false;
    notifyListeners();
  }

  Future<void> _saveState(DriverState newState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stateKey, newState.index);
  }

  Future<void> _saveRideId(String? rideId) async {
    final prefs = await SharedPreferences.getInstance();
    if (rideId != null) {
      await prefs.setString(_rideIdKey, rideId);
    } else {
      await prefs.remove(_rideIdKey);
    }
  }

  void signIn() => _updateState(DriverState.offline);
  void signOut() => _updateState(DriverState.signedOut);
  void goOnline() => _updateState(DriverState.online);
  void goOffline() => _updateState(DriverState.offline);

  void acceptRide(String rideId) {
    currentRideId = rideId;
    _saveRideId(rideId);
    _updateState(DriverState.onTrip);
  }

  void endTrip() {
    currentRideId = null;
    _saveRideId(null);
    _updateState(DriverState.online);
  }

  void _updateState(DriverState newState) {
    debugPrint("🔄 AppState: Attempting state change from $_currentState to $newState");
    if (_currentState == newState) return;
    _currentState = newState;
    _saveState(newState);
    notifyListeners();
    debugPrint("✅ AppState: State successfully changed to $newState. Notified listeners.");
  }

  void startSecurityCheck(String driverId) {
    _driverStatusSub?.cancel();
    _driverStatusSub = FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) {
            signOut();
            return;
          }

          final String status = snapshot.data()?['status'] ?? 'pending';

          if (status != 'verified') {
            debugPrint("SECURITY: Driver no longer verified. Forcing logout.");
            signOut();
          }
        });
  }

  @override
  void dispose() {
    _driverStatusSub?.cancel();
    super.dispose();
  }
}
