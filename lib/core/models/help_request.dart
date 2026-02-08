import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HelpRequest {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String type; // 'mechanic', 'medical', 'security', 'other'
  final String description;
  final LatLng location;
  final DateTime timestamp;
  final String status; // 'active', 'resolved'

  HelpRequest({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.type,
    required this.description,
    required this.location,
    required this.timestamp,
    required this.status,
  });

  factory HelpRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geo = data['location']['geopoint'] as GeoPoint;
    
    return HelpRequest(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? 'Unknown Driver',
      driverPhone: data['driverPhone'] ?? '',
      type: data['type'] ?? 'other',
      description: data['description'] ?? '',
      location: LatLng(geo.latitude, geo.longitude),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'type': type,
      'description': description,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'location': {
        'geopoint': GeoPoint(location.latitude, location.longitude),
        'geohash': '', // Will be filled by GeoFlutterFire helper
      },
    };
  }
}
