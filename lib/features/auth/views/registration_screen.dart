import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/registration_viewmodel.dart';
import 'vehicle_details_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.driverRegistration)),
      body: Consumer<RegistrationViewModel>(
        builder: (context, vm, _) {
          return Form(
            key: vm.personalInfoFormKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  AppLocalizations.of(context)!.personalDetails,
                  style: theme.textTheme.headlineLarge,
                ).animate().fade().slideY(begin: 0.2),
                const SizedBox(height: 20),

                TextFormField(
                  controller: vm.nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.fullName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return AppLocalizations.of(context)!.nameRequired;
                    }
                    if (v.trim().length < 3) {
                      return AppLocalizations.of(context)!.nameLengthError;
                    }
                    if (RegExp(r'[0-9]').hasMatch(v)) {
                      return AppLocalizations.of(context)!.nameNumberError;
                    }
                    return null;
                  },
                ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),

                TextFormField(
                  controller: vm.phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.phoneNumber,
                    prefixText: "+91 ",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.phoneRequired;
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                      return AppLocalizations.of(context)!.validMobileError;
                    }
                    return null;
                  },
                ).animate().fade(delay: 150.ms).slideY(begin: 0.2),
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
                  child: Text(AppLocalizations.of(context)!.nextVehicleDetails),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
              ],
            ),
          );
        },
      ),
    );
  }
}
