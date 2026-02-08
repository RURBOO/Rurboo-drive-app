import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../../../state/app_state_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/driver_voice_viewmodel.dart';
import '../../../core/services/safety_service.dart';
import '../../../core/models/ride_request.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

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
  const _HomeScreenBody();

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  late HomeViewModel _vm;
  bool isGpsEnabled = true;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  @override
  void initState() {
    super.initState();
    _vm = context.read<HomeViewModel>();
    final appState = context.read<AppStateViewModel>();
    
    WakelockPlus.enable();
    _checkGps();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceVm = context.read<DriverVoiceViewModel>();
      _vm.initialize(appState, voiceVm: voiceVm);
    });

    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      if (mounted) {
        setState(() => isGpsEnabled = (status == ServiceStatus.enabled));
      }
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final appState = context.watch<AppStateViewModel>();

    final isOnline = appState.currentState == DriverState.online || 
                     appState.currentState == DriverState.onTrip;
    // Helper to check if GPS permission is granted and service is enabled
    // homeVm.isLocationReady is updated by the VM based on events
    
    return Scaffold(
      body: homeVm.hasLocationError
          ? SizedBox.expand(
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!.locationPermissionNeeded,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => homeVm.initialize(appState),
                        child: Text(AppLocalizations.of(context)!.retry),
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
                  initialCameraPosition: CameraPosition(
                    target: homeVm.driverLocation ?? const LatLng(0, 0),
                    zoom: 16,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  style: homeVm.mapStyle,
                  markers: homeVm.markers,
                  polylines: homeVm.polylines,
                  padding: const EdgeInsets.only(top: 100, bottom: 200), // Adjusted padding
                ),

                // Floating Top Bar (Status)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Status Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isOnline 
                                        ? AppLocalizations.of(context)!.youAreOnline 
                                        : AppLocalizations.of(context)!.youAreOffline,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: isOnline,
                                      onChanged: (newStatus) {
                                          if (appState.currentState == DriverState.onTrip) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(AppLocalizations.of(context)!.cannotGoOfflineTrip),
                                            ),
                                          );
                                          return;
                                        }
                                        if (newStatus && !isGpsEnabled) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(AppLocalizations.of(context)!.turnOnGpsFirst)),
                                          );
                                          return;
                                        }
                                        homeVm.toggleOnlineStatus(newStatus, appState, context);
                                      },
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: Colors.green.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // GPS Status
                            GestureDetector(
                              onTap: () {
                                homeVm.recenterMap();
                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (ctx) => _GPSInfoSheet(homeVm: homeVm),
                                );
                              },
                              child: Container(
                                 width: 40,
                                 height: 40,
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   shape: BoxShape.circle,
                                   boxShadow: [
                                     BoxShadow(
                                       color: Colors.black.withValues(alpha: 0.1),
                                       blurRadius: 8,
                                     ),
                                   ],
                                 ),
                                 child: Icon(
                                   Icons.gps_fixed,
                                   size: 20,
                                   color: homeVm.isLocationReady ? Colors.green : Colors.orange,
                                 ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // SOS Button
                            GestureDetector(
                              onTap: () => SafetyService().callPolice(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.sos, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 🔒 SECURITY BANNER (Only when Online)
                      if (isOnline)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.9), // Slightly transparent blue
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.securityTracking,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                if (!isOnline)
                  Positioned.fill(
                    top: 100,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.offline_bolt, color: Colors.white, size: 60),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.goOnlineToEarn,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (!isGpsEnabled)
                  Positioned(
                    top: 100,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_off, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.gpsOffMessage,
                              style: const TextStyle(
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
                            child: Text(AppLocalizations.of(context)!.turnOn),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  
                // 🤝 DRIVER ALLIANCE BUTTON (Right Side)
                if (isOnline)
                  Positioned(
                    right: 16,
                    bottom: 240, // Above Ride Request Sheet area
                    child: FloatingActionButton(
                      heroTag: 'alliance_btn',
                      onPressed: () => _showHelpRequestDialog(context, homeVm),
                      backgroundColor: Colors.amber[700],
                      child: const Icon(Icons.handshake, color: Colors.white),
                    ),
                  ),

                // 🆘 NEARBY HELP ALERT (Bottom Sheet Overlay)
                if (homeVm.nearbyHelpRequest != null)
                   Positioned(
                     bottom: 0,
                     left: 0,
                     right: 0,
                     child: _NearbyHelpAlertSheet(
                       request: homeVm.nearbyHelpRequest!,
                       onDismiss: homeVm.dismissHelpAlert,
                     ),
                   ),

                // Ride Request Sheet
                if (homeVm.newRideRequest != null)
                   Positioned(
                     bottom: 0,
                     left: 0,
                     right: 0,
                     child: _RideRequestSheet(
                       request: homeVm.newRideRequest!,
                       onAccept: () async {
                         await homeVm.acceptRide(context, appState);
                       },
                       onReject: () {
                         homeVm.rejectRide();
                       },
                     ),
                   ),
              ],
            ),
    );
  }

  void _showHelpRequestDialog(BuildContext context, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Request Driver Alliance"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ask nearby drivers for help. Select issue type:"),
            const SizedBox(height: 20),
            _buildHelpOption(ctx, vm, "mechanic", "🔧 Mechanical Failure", Colors.orange),
            _buildHelpOption(ctx, vm, "medical", "🚑 Medical Emergency", Colors.red),
            _buildHelpOption(ctx, vm, "security", "🛡️ Security Threat", Colors.blueGrey),
            _buildHelpOption(ctx, vm, "other", "⚠️ Other Help", Colors.grey),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption(BuildContext ctx, HomeViewModel vm, String type, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
        ),
        onPressed: () => vm.requestHelp(context, type, "Emergency Assistance Requested"),
        child: Text(label),
      ),
    );
  }
}

class _NearbyHelpAlertSheet extends StatelessWidget {
  final dynamic request; 
  final VoidCallback onDismiss;

  const _NearbyHelpAlertSheet({required this.request, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 2),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Alliance Alert!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
              IconButton(onPressed: onDismiss, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "A nearby driver needs ${request.type.toString().toUpperCase()} help!",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text("Driver: ${request.driverName} • ${request.driverPhone}"),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
               onDismiss();
            }, 
            icon: const Icon(Icons.navigation),
            label: const Text("Go to Assist"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.newRideRequest,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "₹${request.fare.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLocationRow(
            context,
            Icons.my_location, 
            Colors.green, 
            AppLocalizations.of(context)!.pickup,
            request.pickupAddress
          ),
          const SizedBox(height: 20), // Spacing between rows
          _buildLocationRow(
            context,
            Icons.location_on, 
            Colors.red, 
            AppLocalizations.of(context)!.drop,
            request.destinationAddress
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.reject,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.accept,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GPSInfoSheet extends StatelessWidget {
  final HomeViewModel homeVm;

  const _GPSInfoSheet({required this.homeVm});

  @override
  Widget build(BuildContext context) {
    final speedKmh = (homeVm.currentPosition?.speed ?? 0) * 3.6;
    final accuracy = homeVm.currentPosition?.accuracy ?? 0;
    final isGpsFixed = homeVm.isLocationReady;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGpsFixed ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: isGpsFixed ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                isGpsFixed ? AppLocalizations.of(context)!.gpsConnected : AppLocalizations.of(context)!.searchingGpsStatus,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 32),
          
          _buildInfoRow(
            Icons.speed,
            AppLocalizations.of(context)!.currentSpeed,
            "${speedKmh.toStringAsFixed(1)} km/h",
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.my_location,
            AppLocalizations.of(context)!.gpsAccuracy,
            "${accuracy.toStringAsFixed(1)} meters",
          ),
          const SizedBox(height: 16),
          
          Text(
            AppLocalizations.of(context)!.currentLocation,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String?>(
            future: homeVm.getCurrentAddress(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: [
                    const SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.fetchingAddress),
                  ],
                );
              }
              return Text(
                snapshot.data ?? AppLocalizations.of(context)!.addressNotAvailable,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                homeVm.recenterMap();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.center_focus_strong),
              label: Text(AppLocalizations.of(context)!.recenterMap),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
