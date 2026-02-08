import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/registration_viewmodel.dart';
import 'document_upload_screen.dart';

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistrationViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Details (2/3)")),
      body: Form(
        key: vm.vehicleInfoFormKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Vehicle Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              initialValue: vm.vehicleType,
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
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: vm.vehicleModelController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Make & Model',
                hintText: 'e.g. Maruti Dzire, Honda Activa',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.length < 3)
                  ? "Enter valid vehicle model"
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: vm.vehicleNumberController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number Plate',
                hintText: 'e.g. DL 5S 1234',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Vehicle Number is required";
                if (v.length < 6) return "Invalid Vehicle Number";
                return null;
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (vm.vehicleInfoFormKey.currentState!.validate()) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: vm,
                        child: const DocumentUploadScreen(),
                      ),
                    ),
                  );
                }
              },
              child: const Text("Next: Upload Documents"),
            ),
          ],
        ),
      ),
    );
  }
}
