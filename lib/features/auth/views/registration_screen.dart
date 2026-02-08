import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/registration_viewmodel.dart';
import 'vehicle_details_screen.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Registration (1/3)")),
      body: Consumer<RegistrationViewModel>(
        builder: (context, vm, _) {
          return Form(
            key: vm.personalInfoFormKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  "Personal Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: vm.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Name is required";
                    }
                    if (v.trim().length < 3) {
                      return "Name must be at least 3 characters";
                    }
                    if (RegExp(r'[0-9]').hasMatch(v)) {
                      return "Name cannot contain numbers";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: vm.phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixText: "+91 ",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Phone number is required";
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                      return "Enter a valid 10-digit mobile number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (vm.personalInfoFormKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VehicleDetailsScreen(),
                        ),
                      );
                    }
                  },
                  child: const Text("Next: Vehicle Details"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
