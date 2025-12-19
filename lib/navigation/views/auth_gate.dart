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

    switch (appState.currentState) {
      case DriverState.signedOut:
        return const LoginScreen();
      case DriverState.offline:
      case DriverState.online:
        return const MainNavigator();
      case DriverState.onTrip:
        return const LiveTripScreen();
      default:
        return const LoginScreen();
    }
  }
}
