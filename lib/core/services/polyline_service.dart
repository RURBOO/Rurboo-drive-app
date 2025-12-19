import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMins;

  RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMins,
  });
}

class PolylineService {
  Future<RouteInfo?> getRouteData(LatLng start, LatLng end) async {
    final String startCoords = "${start.longitude},${start.latitude}";
    final String endCoords = "${end.longitude},${end.latitude}";

    final Uri url = Uri.parse(
      "https://router.project-osrm.org/route/v1/driving/"
      "$startCoords;$endCoords"
      "?overview=full&geometries=geojson",
    );

    try {
      final response = await http
          .get(url, headers: const {"User-Agent": "RuboDriver/1.0"})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);

      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        return null;
      }

      final route = data['routes'][0];
      final List coordinates = route['geometry']['coordinates'];

      final List<LatLng> points = coordinates.map<LatLng>((coord) {
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();

      return RouteInfo(
        points: points,
        distanceKm: (route['distance'] as num).toDouble() / 1000,
        durationMins: (route['duration'] as num).toDouble() / 60,
      );
    } catch (e) {
      if (kDebugMode) {
        print("OSRM Route Error: $e");
      }
      return null;
    }
  }
}
