import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/trip/views/live_trip_screen.dart';
import 'main_navigator.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateViewModel>();

    debugPrint("🔄 AuthGate: Current State is ${appState.currentState}. Loading: ${appState.isLoading}");

    // Wait for persisted state to load — prevents flash to wrong screen
    if (appState.isLoading) {
      debugPrint("⏳ AuthGate: State is loading... showing spinner.");
      return const Scaffold(
        key: ValueKey('auth_loading'),
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    switch (appState.currentState) {
      case DriverState.signedOut:
        debugPrint("🔐 AuthGate: Mode = SIGNED_OUT");
        return const LoginScreen(key: ValueKey('login_screen'));
      case DriverState.offline:
      case DriverState.online:
        debugPrint("🏠 AuthGate: Mode = ${appState.currentState.name.toUpperCase()} (Showing MainNavigator)");
        return const MainNavigator(key: ValueKey('main_navigator'));
      case DriverState.onTrip:
        debugPrint("🚀 AuthGate: Mode = ON_TRIP (Switching to LiveTripScreen)");
        return const LiveTripScreen(key: ValueKey('live_trip_screen'));
    }
  }
}
