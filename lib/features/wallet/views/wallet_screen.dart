import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/services/driver_preferences.dart';
import '../../../core/services/driver_voice_service.dart';
import '../../../core/constants/payment_keys.dart';
import 'package:rubo_driver/l10n/app_localizations.dart';
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
  double? _lastAttemptedAmount;

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
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    _voiceService.speak(loc.wallet_screen_voice);
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

    try {
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
    } catch (e) {
      debugPrint("Error fetching wallet data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load wallet data: $e")),
        );
      }
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
        title: Text(AppLocalizations.of(context)!.rechargeWallet),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.enterRechargeAmount,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: "₹ ",
                labelText: AppLocalizations.of(context)!.amountLabel,
                border: const OutlineInputBorder(),
                hintText: AppLocalizations.of(context)!.amountHint,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.minimumRechargeInfo,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              Navigator.pop(context);
              
              if (amount < 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.minRechargeError),
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
            child: Text(AppLocalizations.of(context)!.payNow),
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

    _lastAttemptedAmount = amount;
    
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.paymentGatewayError,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
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
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('✅ Payment successful: ${response.paymentId}');
    
    final driverId = await DriverPreferences.getDriverId();
    if (driverId != null) {
      try {
        // Direct increment for immediate feedback (Fallback if webhook is slow)
        final amount = _lastAttemptedAmount ?? 0; 
        
        // Use Batch for atomic update
        WriteBatch batch = FirebaseFirestore.instance.batch();
        DocumentReference driverRef = FirebaseFirestore.instance.collection('drivers').doc(driverId);
        
        batch.update(driverRef, {
          'walletBalance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add to history
        DocumentReference historyRef = driverRef.collection('walletHistory').doc();
        batch.set(historyRef, {
          'amount': amount,
          'type': 'credit',
          'description': 'Wallet Recharge (Razorpay)',
          'createdAt': FieldValue.serverTimestamp(),
          'paymentId': response.paymentId,
        });

        await batch.commit();
        debugPrint("🚀 Local wallet update committed");
      } catch (e) {
        debugPrint("❌ Error updating wallet locally: $e");
      }
    }

    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    _voiceService.speak(loc.payment_success_voice);
    
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.paymentSuccessMsg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    _fetchWalletData();
  }

  /// Handle Razorpay payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ Payment error: ${response.code} - ${response.message}');
    
    if (!mounted) return;
    final loc = AppLocalizations.of(context)!;
    _voiceService.speak(loc.payment_failed_voice);
    
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.paymentFailedMsg(response.message ?? "Unknown error")),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('🔄 External wallet: ${response.walletName}');
  }
  
  Future<void> _syncManualBalance() async {
    if (_currentDriverId == null) return;
    try {
      if (walletBalance > 0 && transactions.isEmpty) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(_currentDriverId)
            .collection('walletHistory')
            .add({
          'amount': walletBalance,
          'type': 'credit',
          'description': 'Manual Firebase Deposit',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text("Missing record synced successfully!"),
               backgroundColor: Colors.green,
             ),
           );
        }
        _fetchWalletData();
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("History already exists or balance is 0.")),
           );
        }
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
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
        title: Text(AppLocalizations.of(context)!.myWalletTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_problem, color: Colors.blue),
            tooltip: "Sync Missing Manual Edits",
            onPressed: _syncManualBalance,
          ),
        ],
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
                    label: Text(AppLocalizations.of(context)!.addMoneyBtn),
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
                    AppLocalizations.of(context)!.commissionInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(),

                // Transaction History Header
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)!.transactionHistory,
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
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.noTransactions,
                            style: const TextStyle(color: Colors.grey),
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
