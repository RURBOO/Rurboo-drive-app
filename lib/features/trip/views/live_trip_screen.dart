import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/services/driver_preferences.dart';
import '../../../core/services/navigation_service.dart';
import '../../../core/services/safety_service.dart';
import '../../../core/widgets/swipe_button.dart';
import '../../../state/app_state_viewmodel.dart';
import '../viewmodels/live_trip_viewmodel.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

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

    // Handle Ride Cancelled by User
    vm.onRideCancelledByUser = () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.rideCancelled),
          content: Text(AppLocalizations.of(context)!.rideCancelledByUser),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await DriverPreferences.clearCurrentRideId();
                if (mounted) {
                  context.read<AppStateViewModel>().endTrip();
                }
              },
              child: Text(AppLocalizations.of(context)!.ok),
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

  Future<void> _handleStartTrip(BuildContext context, LiveTripViewModel vm) async {
    final otpController = TextEditingController();
    
    // Show Premium OTP Dialog
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.enterOtp,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ask the customer for the 4-digit OTP to start the ride."),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx, true);
            },
            child: Text(AppLocalizations.of(context)!.verifyOtp),
          ),
        ],
      ),
    );

    if (success == true) {
      if (!context.mounted) return;
      final verified = await vm.verifyOtpAndStartTrip(otpController.text);
      if (!context.mounted) return;
      if (verified) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Trip Started!"), backgroundColor: Colors.green),
         );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Incorrect OTP"), backgroundColor: Colors.red),
         );
         // Reset swipe button if needed? 
         // SwipeButton automatically resets on exception, so we might want to throw or handle UI reset.
         throw Exception("Incorrect OTP");
      }
    } else {
      throw Exception("Cancelled");
    }
  }

  void _showCancelConfirmation(
    BuildContext context,
    LiveTripViewModel vm,
    AppStateViewModel appState,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          AppLocalizations.of(context)!.confirmCancel, 
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!.confirmCancelMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.noGoBack, style: const TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              vm.cancelRide(context, appState);
            },
            child: Text(AppLocalizations.of(context)!.yesCancel),
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
              Text("Error: ${vm.errorMsg}", style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.read<AppStateViewModel>().endTrip(),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    final isArriving = vm.currentStage == TripStage.arrivingToPickup;
    final statusColor = isArriving ? Colors.blue : Colors.green;
    final statusText = isArriving 
        ? AppLocalizations.of(context)!.arrivingAtPickup 
        : "On Trip - ${AppLocalizations.of(context)!.droppingCustomer}";

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map
          GoogleMap(
            onMapCreated: (controller) {
              vm.mapController = controller;
              if (vm.driverLocation != null) {
                if (!context.mounted) return;
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
                  color: Colors.black, // Premium black route
                  width: 5,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
            },
            markers: {
              if (vm.driverLocation != null)
                Marker(
                  markerId: const MarkerId('driver'),
                  position: vm.driverLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  rotation: 0, // Should use bearing if available
                ),
              Marker(
                markerId: const MarkerId('target'),
                position: vm.currentTarget,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  isArriving ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
                ),
              ),
            },
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(top: 100, bottom: 320), // Map padding for overlays
          ),

          // 2. Top Status Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trip_origin, color: statusColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Action Buttons (Right Side)
          Positioned(
            right: 16,
            bottom: 300, // Above bottom sheet
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "sos",
                  onPressed: () => SafetyService().callPolice(),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.sos, color: Colors.white),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "nav",
                  onPressed: () => NavigationService().launchMap(vm.currentTarget),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  child: const Icon(Icons.navigation),
                ),
              ],
            ),
          ),

          // 4. Premium Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Handle Bar
                   Center(
                     child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                   ),
                   const SizedBox(height: 20),
                   
                   // Rider Info
                   Row(
                     children: [
                       CircleAvatar(
                         backgroundColor: Colors.grey[200],
                         radius: 24,
                         child: const Icon(Icons.person, color: Colors.grey),
                       ),
                       const SizedBox(width: 16),
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
                             const SizedBox(height: 4),
                             Text(
                               vm.currentAddress,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                               style: TextStyle(color: Colors.grey[600], fontSize: 14),
                             ),
                           ],
                         ),
                       ),
                       // Call Button
                       IconButton(
                         onPressed: () => vm.callUser(),
                         icon: Container(
                           padding: const EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: Colors.green.withValues(alpha: 0.1),
                             shape: BoxShape.circle,
                           ),
                           child: const Icon(Icons.call, color: Colors.green, size: 24),
                         ),
                       ),
                   ]),
                   
                   const SizedBox(height: 24),
                   
                   // Trip Details (Fare, Distance)
                   Row(
                     children: [
                       _buildInfoChip(Icons.attach_money, "₹${vm.tripDetails?.fare.toStringAsFixed(0) ?? '0'}"),
                       const SizedBox(width: 12),
                       _buildInfoChip(Icons.access_time, vm.tripDurationMins == null ? "Calculating..." : "${vm.tripDurationMins} min"),
                     ],
                   ),
                   
                   const SizedBox(height: 30),
                   
                   // Swipe to Act
                   if (vm.isWaitingForApproval)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.waitingForApproval,
                              style: const TextStyle(
                                color: Colors.amber, 
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                   else
                     SwipeButton(
                       text: isArriving 
                           ? "Slide to Start Trip" 
                           : "Slide to End Trip",
                       color: isArriving ? Colors.black : Colors.red,
                       icon: isArriving ? Icons.play_arrow : Icons.stop,
                       onSwipe: () async {
                          final connectivity = await Connectivity().checkConnectivity();
                          if (connectivity.contains(ConnectivityResult.none)) {
                          if (!context.mounted) return;
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("No Internet Connection"), backgroundColor: Colors.red),
                             );
                             throw Exception("No Internet");
                          }
  
                          if (!context.mounted) return;

                          if (isArriving) {
                            await _handleStartTrip(context, vm);
                          } else {
                            // Check distance before ending
                            if (vm.driverLocation != null && vm.dropLocation != null) {
                              final double distMeters = Geolocator.distanceBetween(
                                vm.driverLocation!.latitude,
                                vm.driverLocation!.longitude,
                                vm.dropLocation!.latitude,
                                vm.dropLocation!.longitude,
                              );

                              // 100m Threshold & Not yet approved
                              if (distMeters > 100 && !vm.isRideEndApproved) {
                                // Show Approval Dialog
                                final bool? request = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.rideSafetyWarning),
                                    content: Text(AppLocalizations.of(context)!.endRideTooFar),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text(AppLocalizations.of(context)!.cancel),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text(AppLocalizations.of(context)!.requestApproval),
                                      ),
                                    ],
                                  ),
                                );

                                if (request == true) {
                                  await vm.requestEndRideApproval();
                                }
                                // Throw exception to reset swipe button
                                throw Exception("Distance Check Failed"); 
                              }
                            }

                            // If distance < 100m OR Approved -> End Trip
                            await vm.endTrip(context, appState);
                          }
                       },
                     ),
                   
                   const SizedBox(height: 16),
                   
                   // Cancel Button (Only visible if arriving)
                   if (isArriving)
                     Center(
                       child: TextButton(
                         onPressed: () => _showCancelConfirmation(context, vm, appState),
                         child: Text(
                           AppLocalizations.of(context)!.cancelRide,
                           style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                         ),
                       ),
                     ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
