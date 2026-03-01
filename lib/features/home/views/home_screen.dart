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
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/ride_request.dart';
import '../../../core/services/driver_preferences.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';


class HomeScreen extends StatelessWidget {
  final GlobalKey? navBarKey;
  const HomeScreen({super.key, this.navBarKey});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: _HomeScreenBody(navBarKey: navBarKey),
    );
  }
}

class _HomeScreenBody extends StatefulWidget {
  final GlobalKey? navBarKey;
  const _HomeScreenBody({this.navBarKey});

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<_HomeScreenBody> {
  late HomeViewModel _vm;
  bool isGpsEnabled = true;
  bool _initialized = false;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;

  // Onboarding Keys
  final GlobalKey _onlineKey = GlobalKey();
  final GlobalKey _gpsKey = GlobalKey();
  final GlobalKey _sosKey = GlobalKey();
  final GlobalKey _allianceKey = GlobalKey();
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];


  @override
  void initState() {
    super.initState();
    _vm = context.read<HomeViewModel>();
    WakelockPlus.enable();
    _checkGps();
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      if (mounted) {
        setState(() => isGpsEnabled = (status == ServiceStatus.enabled));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppStateViewModel>();
    // Re-initialize once state is loaded and not on-trip
    if (!appState.isLoading && !_initialized) {
      _initialized = true;
      final voiceVm = context.read<DriverVoiceViewModel>();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          _vm.initialize(appState, voiceVm: voiceVm);
          
          // Check for first time onboarding
          final isFirstTime = await DriverPreferences.isFirstTime();
          if (isFirstTime && mounted) {
            _showOnboarding();
          }
        }
      });
    }
  }

  void _showOnboarding() {
    _initTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      onClickTarget: (target) {
        debugPrint('onClickTarget: $target');
      },
      onClickOverlay: (target) {
        debugPrint('onClickOverlay: $target');
      },
      onSkip: () {
        debugPrint("skip");
        DriverPreferences.setFirstTime(false);
        return true;
      },
      onFinish: () {
        debugPrint("finish");
        DriverPreferences.setFirstTime(false);
      },
    )..show(context: context);
  }

  void _initTargets() {
    final l10n = AppLocalizations.of(context)!;
    targets.clear();
    
    targets.add(
      TargetFocus(
        identify: "Target Online",
        keyTarget: _onlineKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.tutOnlineTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    l10n.tutOnlineBody,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target GPS",
        keyTarget: _gpsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.tutGpsTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    l10n.tutGpsBody,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target SOS",
        keyTarget: _sosKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.tutSosTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    l10n.tutSosBody,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target Alliance",
        keyTarget: _allianceKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.tutAllianceTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    l10n.tutAllianceBody,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );

    if (widget.navBarKey != null) {
      targets.add(
        TargetFocus(
          identify: "Target Navigation",
          keyTarget: widget.navBarKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.tutNavTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      l10n.tutNavBody,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          ],
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
                              Colors.black.withValues(alpha: 0.9),
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
                                      key: _onlineKey,
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
                              key: _gpsKey,
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
                              key: _sosKey,
                              onTap: () async {
                                // Log to Firestore first
                                await SafetyService().sendEmergencyAlert(
                                  appState.currentState == DriverState.onTrip ? 'current_ride' : null,
                                  homeVm.driverLocation != null 
                                    ? "${homeVm.driverLocation!.latitude},${homeVm.driverLocation!.longitude}"
                                    : "Unknown"
                                );
                                await SafetyService().callPolice();
                              },

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
                  ).animate().slideY(begin: -0.5, duration: 400.ms, curve: Curves.easeOutCubic).fade(),
                ),

                if (!isOnline)
                  Positioned.fill(
                    top: 100,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.6),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.offline_bolt_rounded, color: Colors.white, size: 48),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  AppLocalizations.of(context)!.goOnlineToEarn,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ).animate().fade(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),
                          ),
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
                      key: _allianceKey,
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
                     ).animate().slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutCubic),
                   ),
              ],
            ),
    );
  }

  void _showHelpRequestDialog(BuildContext context, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.requestAlliance),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.allianceDescription),
            const SizedBox(height: 20),
            _buildHelpOption(ctx, vm, "mechanic", AppLocalizations.of(context)!.mechanicalFailure, Colors.orange),
            _buildHelpOption(ctx, vm, "medical", AppLocalizations.of(context)!.medicalEmergency, Colors.red),
            _buildHelpOption(ctx, vm, "security", AppLocalizations.of(context)!.securityThreat, Colors.blueGrey),
            _buildHelpOption(ctx, vm, "other", AppLocalizations.of(context)!.otherHelp, Colors.grey),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
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
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.allianceAlert,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
              IconButton(onPressed: onDismiss, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.nearbyDriverNeedsHelp(
              request.type == 'mechanic' ? AppLocalizations.of(context)!.mechanicalFailure :
              request.type == 'medical' ? AppLocalizations.of(context)!.medicalEmergency :
              request.type == 'security' ? AppLocalizations.of(context)!.securityThreat :
              AppLocalizations.of(context)!.otherHelp
            ),
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
            label: Text(AppLocalizations.of(context)!.goToAssist),
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (request.isBookForOthers)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.bookingForPassenger,
                          style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          request.receiverName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                (address == 'current_location' || address == 'Current Location')
                    ? AppLocalizations.of(context)!.currentLocation
                    : address,
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
