import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profile/viewmodels/vehicles_viewmodel.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<VehiclesViewModel>().fetchVehicles()
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VehiclesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("My Vehicles")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: vm,
                child: const AddVehicleScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.vehicles.isEmpty
              ? const Center(
                  child: Text("No vehicles found. Add one to start."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vm.vehicles[index];
                    final bool isActive = vehicle['isActive'] == true;
                    final bool isVerified = vehicle['isVerified'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isActive 
                            ? const BorderSide(color: Colors.green, width: 2)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Vehicle Icon/Image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getVehicleIcon(vehicle['vehicleType']),
                                    size: 30,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vehicle['vehicleModel'] ?? 'Unknown Model',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${vehicle['vehicleType']} • ${vehicle['vehicleNumber']}",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isVerified ? Icons.verified : Icons.pending,
                                            size: 16,
                                            color: isVerified ? Colors.green : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isVerified ? "Verified" : "Pending Verification",
                                            style: TextStyle(
                                              color: isVerified ? Colors.green : Colors.orange,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Active/Switch Button
                                if (isVerified)
                                isActive
                                    ? const Chip(
                                        label: Text("Active", style: TextStyle(color: Colors.white)),
                                        backgroundColor: Colors.green,
                                      )
                                    : OutlinedButton(
                                        onPressed: () => vm.activateVehicle(vehicle['id'], vehicle),
                                        child: const Text("Switch"),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getVehicleIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'bike taxi': return Icons.two_wheeler;
      case 'auto rikshaw': return Icons.electric_rickshaw; // Fallback if available or generic
      case 'e-rikshaw': return Icons.electric_rickshaw;
      case 'carrier truck': return Icons.local_shipping;
      case 'big car': 
      case 'comfort car':
        return Icons.directions_car;
      default: return Icons.directions_car;
    }
  }
}
