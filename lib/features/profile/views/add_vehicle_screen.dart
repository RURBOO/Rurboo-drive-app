import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profile/viewmodels/vehicles_viewmodel.dart';

class AddVehicleScreen extends StatelessWidget {
  const AddVehicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehiclesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Add New Vehicle")),
      body: Form(
        key: vm.addVehicleFormKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: vm.selectedType,
                  isExpanded: true,
                  items: [
                    'Bike taxi',
                    'E-Rikshaw',
                    'Auto Rikshaw',
                    'Comfort Car',
                    'Big Car',
                    'Carrier Truck'
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: vm.setVehicleType,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: vm.modelController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Make & Model',
                hintText: 'e.g. Maruti Dzire',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: vm.numberController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number Plate',
                hintText: 'e.g. DL 5S 1234',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.length < 5) ? "Invalid Number" : null,
            ),
            
            const SizedBox(height: 24),
            const Text("Upload Documents", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildUploadTile(
              title: "Vehicle RC (Registration)",
              file: vm.rcFile,
              onTap: () => vm.pickImage('rc'),
            ),
            
            _buildUploadTile(
              title: "Vehicle Photo (Front)",
              file: vm.vehicleImageFile,
              onTap: () => vm.pickImage('vehicle'),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              onPressed: vm.isLoading ? null : () => vm.addNewVehicle(context),
              child: vm.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit for Verification"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: file != null 
            ? Image.file(file, width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.upload_file, size: 30),
        title: Text(title),
        subtitle: Text(file != null ? "Uploaded" : "Tap to upload", 
          style: TextStyle(color: file != null ? Colors.green : Colors.grey)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
