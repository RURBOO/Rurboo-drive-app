import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../../state/app_state_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeScreenBody(),
    );
  }
}

class _HomeScreenBody extends StatefulWidget {
  const _HomeScreenBody({Key? key}) : super(key: key);

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  late HomeViewModel _vm;
  bool isGpsEnabled = true;
  bool _isRideSheetVisible = false;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  @override
  void initState() {
    super.initState();
    _vm = context.read<HomeViewModel>();
    final appState = context.read<AppStateViewModel>();

    WakelockPlus.enable();
    _checkGps();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.initialize(appState);
      _vm.addListener(_onRideStateChanged);
      _onRideStateChanged();
    });

    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      if (mounted)
        setState(() => isGpsEnabled = (status == ServiceStatus.enabled));
    });
  }

  void _onRideStateChanged() {
    if (!mounted) return;
    final homeVm = context.read<HomeViewModel>();

    if (homeVm.newRideRequest != null && !_isRideSheetVisible) {
      print("UI: Opening Ride Sheet");
      setState(() => _isRideSheetVisible = true);

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (ctx) => _RideRequestSheet(
          request: homeVm.newRideRequest!,
          onAccept: () async {
            Navigator.pop(ctx);
            setState(() => _isRideSheetVisible = false);
            await homeVm.acceptRide(context, context.read<AppStateViewModel>());
          },
          onReject: () {
            Navigator.pop(ctx);
            setState(() => _isRideSheetVisible = false);
            homeVm.rejectRide();
          },
        ),
      ).whenComplete(() {
        if (mounted) setState(() => _isRideSheetVisible = false);
      });
    } else if (homeVm.newRideRequest == null && _isRideSheetVisible) {
      print("UI: Closing Ride Sheet (User Cancelled)");
      Navigator.pop(context);
      setState(() => _isRideSheetVisible = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ride was cancelled by user"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkGps() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() => isGpsEnabled = enabled);
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _serviceStatusStream?.cancel();
    _vm.removeListener(_onRideStateChanged);
    super.dispose();
  }

  void _handleRideRequestChanges() {
    if (!mounted) return;
    final homeVm = context.read<HomeViewModel>();

    if (homeVm.newRideRequest != null && !_isRideSheetVisible) {
      _isRideSheetVisible = true;
      _showRideRequestSheet();
    } else if (homeVm.newRideRequest == null) {
      if (_isRideSheetVisible) {
        Navigator.pop(context);
        _isRideSheetVisible = false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Ride Request Cancelled")));
      }
    }
  }

  void _showRideRequestSheet() {
    final homeVm = context.read<HomeViewModel>();
    final appState = context.read<AppStateViewModel>();

    if (!mounted) return;
    if (_isRideSheetVisible) return;

    if (homeVm.newRideRequest != null) {
      _isRideSheetVisible = true;

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (sheetContext) => _RideRequestSheet(
          request: homeVm.newRideRequest!,
          onAccept: () async {
            Navigator.pop(sheetContext);
            _isRideSheetVisible = false;
            await homeVm.acceptRide(context, appState);
          },
          onReject: () {
            Navigator.pop(sheetContext);
            _isRideSheetVisible = false;
            homeVm.rejectRide();
          },
        ),
      ).whenComplete(() {
        _isRideSheetVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final appState = context.watch<AppStateViewModel>();

    final isOnline =
        appState.currentState == DriverState.online ||
        appState.currentState == DriverState.onTrip;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                if (isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: homeVm.isLocationReady
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 12,
                          color: homeVm.isLocationReady
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          homeVm.isLocationReady ? "GPS Ready" : "Searching...",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: homeVm.isLocationReady
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                Text(
                  isOnline ? "You are Online" : "You are Offline",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOnline ? Colors.green : Colors.red,
                  ),
                ),
                Switch(
                  value: isOnline,
                  onChanged: (newStatus) {
                    if (appState.currentState == DriverState.onTrip) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot go offline during a trip"),
                        ),
                      );
                      return;
                    }
                    if (newStatus && !isGpsEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Turn on GPS first!")),
                      );
                      return;
                    }
                    homeVm.toggleOnlineStatus(newStatus, appState, context);
                  },
                  activeTrackColor: Colors.green.shade200,
                  activeColor: Colors.green.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
      body: homeVm.hasLocationError
          ? SizedBox.expand(
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_disabled,
                        size: 72,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Location Required",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          "We couldn't detect your location.\n\n"
                          "Please ensure:\n"
                          "• GPS is turned ON\n"
                          "• Internet is connected\n"
                          "• Location permission is allowed",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          homeVm.initialize(appState);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: homeVm.onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.59, 78.96),
                    zoom: 4.0,
                  ),
                  markers: homeVm.markers,
                  polylines: homeVm.polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  padding: const EdgeInsets.only(bottom: 100),
                ),

                if (!isOnline)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(
                      child: Text(
                        "You are Offline.\nGo Online to earn.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (!isGpsEnabled)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "GPS is turned off! You cannot work.",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () => Geolocator.openLocationSettings(),
                            child: const Text("TURN ON"),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RideRequestSheet extends StatelessWidget {
  final RideRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RideRequestSheet({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "New Ride Request",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${request.fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                request.distance,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildAddressRow(
            icon: Icons.my_location,
            address: request.pickupAddress,
          ),
          const SizedBox(height: 16),
          _buildAddressRow(
            icon: Icons.location_on,
            address: request.destinationAddress,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Accept", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Reject", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required String address,
    Color color = Colors.blue,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
