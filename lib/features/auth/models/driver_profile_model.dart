import 'package:cloud_firestore/cloud_firestore.dart';

class DriverProfileModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleNumber;
  final bool isOnline;
  final String status;
  final DateTime createdAt;
  final double rating;
  final int totalRides;

  DriverProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleNumber,
    this.isOnline = false,
    this.status = 'pending',
    required this.createdAt,
    this.rating = 5.0,
    this.totalRides = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'isOnline': isOnline,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'rating': rating,
      'totalRides': totalRides,
    };
  }
}
