import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../core/services/driver_voice_service.dart';
import '../../../core/constants/payment_keys.dart';
import '../models/wallet_transaction.dart';
import 'package:intl/intl.dart';


/// Production-ready Wallet Screen with Razorpay payment gateway integration
/// 
/// Features:
/// ✅ Real-time wallet balance listener  
/// ✅ Razorpay payment integration
/// ✅ Commission due display
/// ✅ Transaction history with settlement entries
/// ✅ Negative balance warning
/// ✅ Voice announcements for balance and transactions
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double walletBalance = 0.0;
  double todaysDue = 0.0;
  bool isLoading = true;
  List<WalletTransaction> transactions = [];
  
  late Razorpay _razorpay;
  String? _currentDriverId;
  final _voiceService = DriverVoiceService();

  @override
  void initState() {
    super.initState();
    _initVoice();
    _initializeRazorpay();
    _fetchWalletData();
    _listenToWalletChanges(); // Real-time updates
  }

  Future<void> _initVoice() async {
    await _voiceService.init();
    _voiceService.announceWalletScreen();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  /// Initialize Razorpay SDK
  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Fetch initial wallet data
  Future<void> _fetchWalletData() async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return;

    _currentDriverId = driverId;

    final driverDoc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();

    final historyQuery = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .collection('walletHistory')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    if (mounted) {
      setState(() {
        walletBalance =
            (driverDoc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;

        todaysDue =
            (driverDoc.data()?['dailyCommissionDue'] as num?)?.toDouble() ??
            0.0;

        transactions = historyQuery.docs
            .map((d) => WalletTransaction.fromFirestore(d))
            .toList();

        isLoading = false;
      });
    }
  }

  /// Real-time listener for wallet balance changes
  void _listenToWalletChanges() async {
    final driverId = await DriverPreferences.getDriverId();
    if (driverId == null) return;

    FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || !snapshot.exists) return;

      setState(() {
        walletBalance =
            (snapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        todaysDue =
            (snapshot.data()?['dailyCommissionDue'] as num?)?.toDouble() ?? 0.0;
      });
    });
  }

  /// Show recharge dialog
  Future<void> _addMoney() async {
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recharge Wallet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter amount to add to your wallet",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: "₹ ",
                labelText: "Amount",
                border: OutlineInputBorder(),
                hintText: "e.g. 500",
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "💡 Minimum: ₹100",
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              Navigator.pop(context);
              
              if (amount < 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Minimum recharge amount is ₹100"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              _startRazorpayPayment(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Pay Now"),
          ),
        ],
      ),
    );
  }

  /// Start Razorpay payment flow
  Future<void> _startRazorpayPayment(double amount) async {
    if (_currentDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver ID not found")),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // IMPORTANT: Validate Razorpay API key is configured
      if (PaymentKeys.razorpayKeyId.contains("PLACEHOLDER")) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⚠️ Payment gateway not configured. Please contact support.",
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        debugPrint("❌ RAZORPAY KEY NOT CONFIGURED - Update PaymentKeys.razorpayKeyId");
        return;
      }
      
      final options = {
        'key': PaymentKeys.razorpayKeyId, // ✅ Using constant from PaymentKeys
        'amount': (amount * 100).toInt(), // Convert to paise
        'name': PaymentKeys.appName,
        'description': PaymentKeys.description,
        'prefill': {
          'contact': '',
          'email': ''
        },
        'notes': {
          'driverId': _currentDriverId, // CRITICAL: Used by webhook to identify driver
        },
        'theme': {
          'color': '#2E7D32' // Green color
        }
      };

      if (mounted) Navigator.pop(context); // Close loading dialog

      _razorpay.open(options);
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error starting payment: $e")),
        );
      }
    }
  }

  /// Handle Razorpay payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ Payment successful: ${response.paymentId}');
    
    // Voice announcement
    _voiceService.announceSuccess("Payment successful! Wallet will be updated shortly.");
    
    // Webhook will automatically credit wallet
    // Just show success message and refresh
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment successful! Wallet will be updated shortly."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );

    // Refresh wallet data after 2 seconds (give webhook time to process)
    Future.delayed(const Duration(seconds: 2), () {
      _fetchWalletData();
    });
  }

  /// Handle Razorpay payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment error: ${response.code} - ${response.message}');
    
    // Voice announcement
    _voiceService.announceError("Payment failed. Please try again.");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Payment failed: ${response.message}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('🔄 External wallet: ${response.walletName}');
  }

  Widget _buildCard(String title, double amount, Color bg, {bool showWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: showWarning ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (showWarning) ...[
                const SizedBox(width: 4),
                const Icon(Icons.warning, color: Colors.red, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNegativeBalance = walletBalance < 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Negative Balance Warning Banner
                if (isNegativeBalance)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Your wallet is negative. Recharge to go online!",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Balance Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          "Wallet Balance",
                          walletBalance,
                          isNegativeBalance ? Colors.red : Colors.black,
                          showWarning: isNegativeBalance,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCard(
                          "Today's Due",
                          todaysDue,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add Money Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _addMoney,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Money via Razorpay"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                
                // Info Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "💡 Commission is deducted daily at 11:59 PM",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(),

                // Transaction History Header
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

                // Transaction List
                Expanded(
                  child: transactions.isEmpty
                      ? const Center(
                          child: Text(
                            "No transactions yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isCredit = tx.type == 'credit';
                            final isSettlement = tx.type == 'settlement';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSettlement
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : isCredit
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                child: Icon(
                                  isSettlement
                                      ? Icons.schedule
                                      : isCredit
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                  color: isSettlement
                                      ? Colors.orange
                                      : isCredit
                                          ? Colors.green
                                          : Colors.red,
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
                                  color: isSettlement
                                      ? Colors.orange
                                      : isCredit
                                          ? Colors.green
                                          : Colors.red,
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
