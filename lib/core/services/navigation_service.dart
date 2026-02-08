import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationService {
  /// Launches Google Maps navigation to the specified destination
  Future<void> launchMap(LatLng destination) async {
    final Uri googleMapsUrl = Uri.parse(
        'google.navigation:q=${destination.latitude},${destination.longitude}&mode=d'); // d for driving

    // Fallback URL if deep link doesn't work (opens in browser)
    final Uri browserUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else {
        if (await canLaunchUrl(browserUrl)) {
          await launchUrl(browserUrl);
        } else {
          throw Exception('Could not launch Google Maps');
        }
      }
    } catch (e) {
      throw Exception('Error launching map: $e');
    }
  }
}
