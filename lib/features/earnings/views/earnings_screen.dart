import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/earnings_viewmodel.dart';
import 'ride_history_screen.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.earnings),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
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
              onRefresh: () => context.read<EarningsViewModel>().fetchEarnings(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDetailedCard(
                    context,
                    title: AppLocalizations.of(context)!.todayEarnings,
                    gross: vm.todayGross,
                    commission: vm.todayCommission,
                    net: vm.todayNet,
                    rides: vm.todayRides,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  
                  // Weekly Chart Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.thisWeek,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: vm.dailyEarnings.isEmpty 
                                  ? 100 
                                  : (vm.dailyEarnings.reduce((a, b) => a > b ? a : b) * 1.2),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  // tooltipBgColor: Colors.black, // Deprecated in v0.68+
                                  getTooltipColor: (_) => Colors.black,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '₹${rod.toY.round()}',
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < vm.dailyLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            vm.dailyLabels[value.toInt()],
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(vm.dailyEarnings.length, (index) {
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: vm.dailyEarnings[index],
                                      color: vm.dailyEarnings[index] > 0 ? Colors.green : Colors.grey.shade300,
                                      width: 12,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      backDrawRodData: BackgroundBarChartRodData(
                                        show: true,
                                        toY: (vm.dailyEarnings.isEmpty 
                                            ? 100 
                                            : (vm.dailyEarnings.reduce((a, b) => a > b ? a : b) * 1.2)),
                                        color: Colors.grey.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                Text(
                                  "₹${vm.weeklyGross.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                             Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Net",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                Text(
                                  "₹${vm.weeklyNet.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.recentHistory,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RideHistoryScreen(),
                              ),
                            );
                          },
                          child: Text(AppLocalizations.of(context)!.viewAll),
                        ),
                      ],
                    ),
                  ),

                  if (vm.rideHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text(AppLocalizations.of(context)!.noRides)),
                    )
                  else
                    ...vm.rideHistory.map(
                      (ride) => _buildRideHistoryTile(context, ride),
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
            color: color.withValues(alpha: 0.2),
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
                    "$rides ${AppLocalizations.of(context)!.rides}",
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
          Text(
            AppLocalizations.of(context)!.grossEarnings,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                  Text(
                    AppLocalizations.of(context)!.platformFee,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  Text(
                    AppLocalizations.of(context)!.netProfit,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideHistoryTile(BuildContext context, EarningItem ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.currency_rupee, color: Colors.green, size: 20),
        ),
        title: Text(
          ride.pickup,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const SizedBox(height: 4),
             Text(
              ride.drop,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
               style: TextStyle(color: Colors.grey[600], fontSize: 12),
             ),
             const SizedBox(height: 4),
             Text(
               ride.date,
               style: TextStyle(color: Colors.grey[400], fontSize: 10),
             ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${ride.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            if (ride.commission > 0)
              Text(
                "- ₹${ride.commission.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 10, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
