import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../core/utils/image_utils.dart';

class VehiclesViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> vehicles = [];
  bool isLoading = false;
  
  // For Adding New Vehicle
  final TextEditingController modelController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  String selectedType = 'Bike taxi';
  File? rcFile;
  File? vehicleImageFile;
  
  final GlobalKey<FormState> addVehicleFormKey = GlobalKey<FormState>();

  Future<void> fetchVehicles() async {
    isLoading = true;
    notifyListeners();

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) return;

      final query = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('vehicles')
          .orderBy('createdAt', descending: true)
          .get();

      vehicles = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // If no vehicles found in subcollection, migrate current driver vehicle to subcollection
      if (vehicles.isEmpty) {
        await _migrateCurrentVehicle(driverId);
      }

    } catch (e) {
      debugPrint("Error fetching vehicles: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _migrateCurrentVehicle(String driverId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      if (data['vehicleNumber'] == null) return; // Already migrated or invalid

      // Create vehicle entry
      final vehicleData = {
        'vehicleType': data['vehicleType'],
        'vehicleModel': data['vehicleModel'],
        'vehicleNumber': data['vehicleNumber'],
        'rcImage': data['rcImage'],
        'vehicleImage': data['vehicleImage'], // Might be null for old users
        'isVerified': data['status'] == 'verified',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('vehicles')
          .add(vehicleData);
      
      // Refresh list
      final query = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('vehicles')
          .get();
          
      vehicles = query.docs.map((d) {
        final dData = d.data();
        dData['id'] = d.id;
        return dData;
      }).toList();
      
    } catch (e) {
      debugPrint("Migration failed: $e");
    }
  }

  Future<void> pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    
    if (image != null) {
      if (type == 'rc') {
        rcFile = File(image.path);
      } else if (type == 'vehicle') {
        vehicleImageFile = File(image.path);
      }
      notifyListeners();
    }
  }

  void setVehicleType(String? type) {
    if (type != null) {
      selectedType = type;
      notifyListeners();
    }
  }

  Future<void> addNewVehicle(BuildContext context) async {
    if (!addVehicleFormKey.currentState!.validate()) return;
    if (rcFile == null || vehicleImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both RC and Vehicle Photo")),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) throw Exception("Driver ID not found");

      final rcBase64 = await ImageUtils.convertFileToBase64(rcFile!);
      final vehicleBase64 = await ImageUtils.convertFileToBase64(vehicleImageFile!);

      if (rcBase64 == null || vehicleBase64 == null) throw Exception("Image processing failed");

      final newVehicle = {
        'vehicleType': selectedType,
        'vehicleModel': modelController.text.trim(),
        'vehicleNumber': numberController.text.trim().toUpperCase(),
        'rcImage': rcBase64,
        'vehicleImage': vehicleBase64,
        'isVerified': false, // New vehicles need approval
        'isActive': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .collection('vehicles')
          .add(newVehicle);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle added! Waiting for verification.")),
        );
        Navigator.pop(context);
      }
      
      // Reset form
      modelController.clear();
      numberController.clear();
      rcFile = null;
      vehicleImageFile = null;
      
      fetchVehicles(); // Refresh list

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateVehicle(String vehicleId, Map<String, dynamic> vehicleData) async {
    if (vehicleData['isVerified'] != true) {
      return; // Cannot activate unverified vehicle
    }

    isLoading = true;
    notifyListeners();

    try {
      final driverId = await DriverPreferences.getDriverId();
      if (driverId == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final driverRef = FirebaseFirestore.instance.collection('drivers').doc(driverId);
      final vehiclesRef = driverRef.collection('vehicles');

      // 1. Update all vehicles to inactive
      for (var v in vehicles) {
        if (v['isActive'] == true) {
          batch.update(vehiclesRef.doc(v['id']), {'isActive': false});
        }
      }

      // 2. Set selected vehicle to active
      batch.update(vehiclesRef.doc(vehicleId), {'isActive': true});

      // 3. Update Main Profile with active vehicle details (for ride logic)
      batch.update(driverRef, {
        'vehicleType': vehicleData['vehicleType'],
        'vehicleModel': vehicleData['vehicleModel'],
        'vehicleNumber': vehicleData['vehicleNumber'],
        'vehicleImage': vehicleData['vehicleImage'], // Update profile image to match vehicle? Or separate field?
        // Note: We might want to keep 'profileImage' distinct from 'vehicleImage'
      });

      await batch.commit();

      // 4. Update Local Preferences
      await DriverPreferences.saveVehicleType(vehicleData['vehicleType']);

      await fetchVehicles(); // Refresh UI

    } catch (e) {
      debugPrint("Error activating vehicle: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
