import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DriverState { signedOut, offline, online, onTrip }

class AppStateViewModel extends ChangeNotifier {
  static const _stateKey = 'driverState';

  DriverState _currentState = DriverState.signedOut;
  DriverState get currentState => _currentState;
  StreamSubscription<DocumentSnapshot>? _driverStatusSub;

  String? currentRideId;

  AppStateViewModel() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateIndex = prefs.getInt(_stateKey) ?? DriverState.signedOut.index;
    _currentState = DriverState.values[stateIndex];
    notifyListeners();
  }

  Future<void> _saveState(DriverState newState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stateKey, newState.index);
  }

  void signIn() => _updateState(DriverState.offline);
  void signOut() => _updateState(DriverState.signedOut);
  void goOnline() => _updateState(DriverState.online);
  void goOffline() => _updateState(DriverState.offline);

  void acceptRide(String rideId) {
    currentRideId = rideId;
    _updateState(DriverState.onTrip);
  }

  void endTrip() {
    currentRideId = null;
    _updateState(DriverState.online);
  }

  void _updateState(DriverState newState) {
    if (_currentState == newState) return;
    _currentState = newState;
    _saveState(newState);
    notifyListeners();
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
