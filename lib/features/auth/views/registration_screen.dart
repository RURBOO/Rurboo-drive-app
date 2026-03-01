import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/registration_viewmodel.dart';
import 'vehicle_details_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

class RegistrationScreen extends StatefulWidget {
  final String? prefilledId;
  final String? prefilledPhone;

  const RegistrationScreen({
    super.key, 
    this.prefilledId, 
    this.prefilledPhone,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationViewModel>().initializePrefilled(
        widget.prefilledId,
        widget.prefilledPhone,
      );
    });
  }

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
                    return null;
                  },
                ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),

                // 🆕 Age Field
                TextFormField(
                  controller: vm.ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.age,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppLocalizations.of(context)!.ageRequired;
                    }
                    final age = int.tryParse(v);
                    if (age == null || age < 18) {
                      return AppLocalizations.of(context)!.underageError;
                    }
                    return null;
                  },
                ).animate().fade(delay: 150.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),

                // 🆕 Gender Dropdown
                DropdownButtonFormField<String>(
                  initialValue: vm.gender,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.gender,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.people),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Male', child: Text(AppLocalizations.of(context)!.male)),
                    DropdownMenuItem(value: 'Female', child: Text(AppLocalizations.of(context)!.female)),
                    DropdownMenuItem(value: 'Other', child: Text(AppLocalizations.of(context)!.other)),
                  ],
                  onChanged: vm.setGender,
                  validator: (v) => v == null ? AppLocalizations.of(context)!.genderRequired : null,
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),

                // 🆕 Emergency Contact Phone (Optional)
                TextFormField(
                  controller: vm.emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.emergencyContactPhone,
                    hintText: "Optional",
                    prefixText: "+91 ",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone_callback),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length != 10) {
                      return AppLocalizations.of(context)!.validEmergencyPhoneError;
                    }
                    return null;
                  },
                ).animate().fade(delay: 250.ms).slideY(begin: 0.2),
                const SizedBox(height: 16),

                if (vm.prefilledPhone == null)
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
                  ).animate().fade(delay: 350.ms).slideY(begin: 0.2),
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
