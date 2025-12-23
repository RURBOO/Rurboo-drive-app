import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/services/driver_preferences.dart';
import '../models/wallet_transaction.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0.0;
  bool isLoading = true;
  List<WalletTransaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return;

    final driverDoc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();

    final historyQuery = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .collection('walletHistory')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    if (mounted) {
      setState(() {
        balance =
            (driverDoc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        transactions = historyQuery.docs
            .map((d) => WalletTransaction.fromFirestore(d))
            .toList();
        isLoading = false;
      });
    }
  }

  Future<void> _addMoney() async {
    final amountController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Top Up Wallet"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: "₹ ",
            labelText: "Amount",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _processRecharge(double.tryParse(amountController.text) ?? 0);
            },
            child: const Text("Pay via UPI"),
          ),
        ],
      ),
    );
  }

  Future<void> _processRecharge(double amount) async {
    if (amount <= 0) return;
    setState(() => isLoading = true);

    try {
      final driverId = await DriverPreferences.getDriverId();
      final batch = FirebaseFirestore.instance.batch();
      final driverRef = FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId);

      batch.update(driverRef, {'walletBalance': FieldValue.increment(amount)});

      batch.set(driverRef.collection('walletHistory').doc(), {
        'amount': amount,
        'type': 'credit',
        'description': 'Wallet Recharge (UPI)',
        'balanceAfter': balance + amount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await _fetchWalletData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Recharge Successful!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet"), elevation: 0),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Current Balance",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹ ${balance.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: balance < 0 ? Colors.redAccent : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _addMoney,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Money"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Transaction History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isCredit = tx.type == 'credit';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCredit
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          tx.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          DateFormat('MMM d, hh:mm a').format(tx.date),
                        ),
                        trailing: Text(
                          "${isCredit ? '+' : '-'} ₹${tx.amount.toStringAsFixed(0)}",
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
