import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/earnings_viewmodel.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EarningsViewModel()..fetchEarnings(),
      child: const _EarningsScreenBody(),
    );
  }
}

class _EarningsScreenBody extends StatelessWidget {
  const _EarningsScreenBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EarningsViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Earnings"),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<EarningsViewModel>().fetchEarnings(),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<EarningsViewModel>().fetchEarnings(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailedCard(
                    context,
                    title: "Today's Earnings",
                    gross: vm.todayGross,
                    commission: vm.todayCommission,
                    net: vm.todayNet,
                    rides: vm.todayRides,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 16),

                  _buildDetailedCard(
                    context,
                    title: "This Week",
                    gross: vm.weeklyGross,
                    commission: vm.weeklyCommission,
                    net: vm.weeklyNet,
                    rides: null,
                    color: Colors.blue,
                  ),

                  const Padding(
                    padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: Text(
                      "Recent History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (vm.rideHistory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text("No rides yet.")),
                    )
                  else
                    ...vm.rideHistory.map(
                      (ride) => _buildRideHistoryTile(ride),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailedCard(
    BuildContext context, {
    required String title,
    required double gross,
    required double commission,
    required double net,
    int? rides,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (rides != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$rides Rides",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            '₹${gross.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Cash Collected",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const Divider(color: Colors.white24, height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "- ₹${commission.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Platform Fee",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${net.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Net Profit",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistoryTile(EarningItem ride) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ride.date,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${ride.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (ride.commission > 0)
                      Text(
                        "- ₹${ride.commission.toStringAsFixed(0)} Fee",
                        style: const TextStyle(fontSize: 10, color: Colors.red),
                      )
                    else
                      const Text(
                        "Free Trial",
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.pickup,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.square, color: Colors.red, size: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.drop,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
