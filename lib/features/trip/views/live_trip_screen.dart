import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/services/driver_preferences.dart';
import '../../../state/app_state_viewmodel.dart';
import '../viewmodels/live_trip_viewmodel.dart';

class LiveTripScreen extends StatefulWidget {
  const LiveTripScreen({super.key});

  @override
  State<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends State<LiveTripScreen> {
  late LiveTripViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = LiveTripViewModel();
    WakelockPlus.enable();

    vm.onRideCancelledByUser = () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Ride Cancelled"),
          content: const Text("The user has cancelled this ride."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await DriverPreferences.clearCurrentRideId();
                if (mounted) {
                  context.read<AppStateViewModel>().endTrip();
                }
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.init(context.read<AppStateViewModel>());
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LiveTripViewModel>.value(
      value: vm,
      child: const _LiveTripScreenBody(),
    );
  }
}

class _LiveTripScreenBody extends StatelessWidget {
  const _LiveTripScreenBody();

  void _showOtpDialog(BuildContext context, LiveTripViewModel vm) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Enter Customer OTP"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(hintText: "Ask rider for OTP"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await vm.verifyOtpAndStartTrip(
                otpController.text,
              );
              if (success && context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Trip Started!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Incorrect OTP"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(
    BuildContext context,
    LiveTripViewModel vm,
    AppStateViewModel appState,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Ride?", style: TextStyle(color: Colors.red)),
        content: const Text(
          "Are you sure you want to cancel this ride? Frequent cancellations may affect your rating.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "No, Go Back",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vm.cancelRide(context, appState);
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LiveTripViewModel>();
    final appState = context.read<AppStateViewModel>();

    if (vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vm.errorMsg != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Error: ${vm.errorMsg}"),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.read<AppStateViewModel>().endTrip();
                },
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.currentHeader,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled,
                  size: 14,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  vm.tripEta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GoogleMap(
                  onMapCreated: (controller) {
                    vm.mapController = controller;
                    if (vm.driverLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(vm.driverLocation!, 16),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: vm.driverLocation ?? vm.pickupLocation!,
                    zoom: 15.0,
                  ),
                  polylines: {
                    if (vm.routePoints.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId("route"),
                        points: vm.routePoints,
                        color: Colors.blue,
                        width: 5,
                      ),
                  },
                  markers: {
                    if (vm.driverLocation != null)
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: vm.driverLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                        infoWindow: const InfoWindow(title: "You"),
                      ),
                    Marker(
                      markerId: const MarkerId('target'),
                      position: vm.currentTarget,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        vm.currentStage == TripStage.arrivingToPickup
                            ? BitmapDescriptor.hueGreen
                            : BitmapDescriptor.hueRed,
                      ),
                      infoWindow: InfoWindow(
                        title: vm.currentStage == TripStage.arrivingToPickup
                            ? "Pickup"
                            : "Drop",
                      ),
                    ),
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  padding: const EdgeInsets.only(bottom: 200),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vm.tripDetails?.riderName ?? "Rider",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                vm.currentAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          height: 46,
                          width: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: IconButton(
                            onPressed: () => vm.callUser(),
                            icon: const Icon(Icons.call, color: Colors.white),
                            splashRadius: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              vm.currentStage == TripStage.arrivingToPickup
                              ? Colors.blue
                              : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final connectivity = await Connectivity()
                              .checkConnectivity();
                          if (connectivity.contains(ConnectivityResult.none)) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "No Internet! Cannot update trip.",
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }

                          if (vm.currentStage == TripStage.arrivingToPickup) {
                            _showOtpDialog(context, vm);
                          } else {
                            vm.endTrip(context, appState);
                          }
                        },
                        child: Text(
                          vm.currentStage == TripStage.arrivingToPickup
                              ? "START TRIP (ENTER OTP)"
                              : "END TRIP",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showCancelConfirmation(context, vm, appState),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text(
                          "Cancel Ride",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton.extended(
              heroTag: "navigate_btn",
              onPressed: () async {
                final lat = vm.currentTarget.latitude;
                final lng = vm.currentTarget.longitude;
                final Uri googleMapsUrl = Uri.parse(
                  "google.navigation:q=$lat,$lng&mode=d",
                );
                final Uri webUrl = Uri.parse(
                  "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
                );

                if (await canLaunchUrl(googleMapsUrl)) {
                  await launchUrl(googleMapsUrl);
                } else {
                  await launchUrl(webUrl);
                }
              },
              label: const Text("Navigate"),
              icon: const Icon(Icons.navigation),
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
