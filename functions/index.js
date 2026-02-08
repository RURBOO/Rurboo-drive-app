/**
 * ============================================================================
 * RURBOO DRIVER APP - CLOUD FUNCTIONS
 * ============================================================================
 * 
 * Production-ready Cloud Functions for wallet management and commission
 * settlement with full idempotency and transaction support.
 * 
 * CRITICAL FEATURES:
 * ✅ Webhook signature verification
 * ✅ Idempotency protection (prevents double credits)
 * ✅ Firestore transactions (atomic operations)
 * ✅ Daily settlement at 11:59 PM IST
 * ✅ Comprehensive error handling and logging
 * 
 * ============================================================================
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();

// ============================================================================
// RAZORPAY WEBHOOK HANDLER
// ============================================================================

/**
 * Handles Razorpay payment webhooks with full idempotency protection
 * 
 * ENDPOINT: POST /razorpayWebhook
 * 
 * SECURITY:
 * - Verifies webhook signature using HMAC-SHA256
 * - Validates payment event type
 * - Checks driver existence
 * 
 * IDEMPOTENCY:
 * - Queries walletHistory for existing razorpayPaymentId
 * - Returns 200 OK if already processed (prevents double credit)
 * 
 * ATOMICITY:
 * - Uses Firestore transaction to ensure:
 *   1. Wallet balance is credited
 *   2. History entry is created
 *   Both succeed or both fail (no partial updates)
 */
exports.razorpayWebhook = functions
  .region('asia-south1')
  .https.onRequest(async (req, res) => {
    // STEP 1: Validate HTTP method
    if (req.method !== 'POST') {
      console.error('Invalid request method:', req.method);
      return res.status(405).send('Method Not Allowed');
    }

    // STEP 2: Extract webhook signature and secret
    const webhookSecret = functions.config().razorpay?.webhook_secret;
    const razorpaySignature = req.headers['x-razorpay-signature'];

    if (!webhookSecret) {
      console.error('CRITICAL: Razorpay webhook secret not configured');
      return res.status(500).send('Server configuration error');
    }

    // STEP 3: Verify webhook signature (SECURITY)
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(JSON.stringify(req.body))
      .digest('hex');

    if (razorpaySignature !== expectedSignature) {
      console.error('❌ Invalid webhook signature - potential security breach');
      console.error('Expected:', expectedSignature);
      console.error('Received:', razorpaySignature);
      return res.status(400).send('Invalid signature');
    }

    // STEP 4: Parse webhook payload
    const event = req.body.event;
    const payload = req.body.payload?.payment?.entity;

    if (!payload) {
      console.error('Missing payment payload');
      return res.status(400).send('Invalid payload');
    }

    // STEP 5: Filter events (only process successful payments)
    if (event !== 'payment.captured') {
      console.log(`ℹ️  Ignoring webhook event: ${event}`);
      return res.status(200).send('Event ignored');
    }

    // STEP 6: Extract payment details
    const paymentId = payload.id;
    const orderId = payload.order_id;
    const amountInPaise = payload.amount;
    const amount = amountInPaise / 100; // Convert paise to rupees
    const driverId = payload.notes?.driverId;

    // STEP 7: Validate required fields
    if (!driverId) {
      console.error('❌ Missing driverId in payment notes');
      console.error('Payment ID:', paymentId);
      return res.status(400).send('Missing driverId in notes');
    }

    if (!paymentId || !orderId) {
      console.error('❌ Missing payment ID or order ID');
      return res.status(400).send('Incomplete payment data');
    }

    console.log('📥 Processing payment webhook:');
    console.log('  Payment ID:', paymentId);
    console.log('  Order ID:', orderId);
    console.log('  Amount:', `₹${amount}`);
    console.log('  Driver ID:', driverId);

    try {
      const driverRef = db.collection('drivers').doc(driverId);
      const walletHistoryRef = driverRef.collection('walletHistory');

      // STEP 8: IDEMPOTENCY CHECK (CRITICAL)
      // Check if this payment was already processed
      const existingTransaction = await walletHistoryRef
        .where('razorpayPaymentId', '==', paymentId)
        .limit(1)
        .get();

      if (!existingTransaction.empty) {
        console.log(`⚠️  Payment ${paymentId} already processed. Returning success to prevent retry.`);
        return res.status(200).send('Already processed');
      }

      // STEP 9: ATOMIC TRANSACTION (CRITICAL)
      // Credit wallet and create history entry atomically
      await db.runTransaction(async (transaction) => {
        // Read driver document
        const driverDoc = await transaction.get(driverRef);

        if (!driverDoc.exists) {
          throw new Error(`Driver ${driverId} not found in database`);
        }

        const currentBalance = driverDoc.data().walletBalance || 0;
        const newBalance = currentBalance + amount;

        // Update 1: Credit driver wallet balance
        transaction.update(driverRef, {
          walletBalance: newBalance,
          lastWalletUpdate: admin.firestore.FieldValue.serverTimestamp()
        });

        // Update 2: Create wallet history entry (audit trail + idempotency key)
        const historyDocRef = walletHistoryRef.doc();
        transaction.set(historyDocRef, {
          amount: amount,
          type: 'credit',
          description: `Wallet recharge via Razorpay`,
          balanceAfter: newBalance,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId, // IDEMPOTENCY KEY
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✅ Successfully credited ₹${amount} to driver ${driverId}`);
        console.log(`   Previous balance: ₹${currentBalance}`);
        console.log(`   New balance: ₹${newBalance}`);
      });

      return res.status(200).send('Success');

    } catch (error) {
      console.error('❌ Webhook processing error:', error);
      console.error('Stack:', error.stack);
      return res.status(500).send('Internal server error');
    }
  });


// ============================================================================
// DAILY COMMISSION SETTLEMENT
// ============================================================================

/**
 * Scheduled function that runs daily at 11:59 PM IST
 * Settles commission by deducting dailyCommissionDue from walletBalance
 * 
 * SCHEDULE: 59 23 * * * (11:59 PM daily)
 * TIMEZONE: Asia/Kolkata (IST)
 * 
 * PROCESS:
 * 1. Query all drivers with dailyCommissionDue > 0
 * 2. For each driver, atomically:
 *    - Deduct dailyCommissionDue from walletBalance
 *    - Reset dailyCommissionDue to 0
 *    - Update lastSettlementDate
 *    - Create settlement entry in walletHistory (audit)
 * 
 * TRANSACTION SAFETY:
 * - Uses Firestore transactions to prevent race conditions
 * - Handles concurrent recharges safely
 */
exports.dailySettlement = functions
  .region('asia-south1')
  .pubsub
  .schedule('59 23 * * *') // 11:59 PM daily
  .timeZone('Asia/Kolkata') // IST timezone
  .onRun(async (context) => {
    console.log('⏰ ============================================');
    console.log('⏰ DAILY SETTLEMENT STARTED');
    console.log('⏰ Timestamp:', new Date().toISOString());
    console.log('⏰ ============================================');

    try {
      // Query all drivers with pending commission
      const driversSnapshot = await db.collection('drivers')
        .where('dailyCommissionDue', '>', 0)
        .get();

      console.log(`📊 Found ${driversSnapshot.size} drivers with pending commission`);

      if (driversSnapshot.empty) {
        console.log('ℹ️  No drivers to settle. Exiting.');
        return null;
      }

      // Process each driver in parallel (with transaction safety)
      const settlementPromises = driversSnapshot.docs.map(async (driverDoc) => {
        const driverId = driverDoc.id;
        const driverRef = db.collection('drivers').doc(driverId);

        try {
          // ATOMIC TRANSACTION for each driver settlement
          await db.runTransaction(async (transaction) => {
            // Re-read fresh data inside transaction
            const freshDoc = await transaction.get(driverRef);

            if (!freshDoc.exists) {
              console.error(`❌ Driver ${driverId} no longer exists`);
              return;
            }

            const data = freshDoc.data();
            const currentBalance = data.walletBalance || 0;
            const commissionDue = data.dailyCommissionDue || 0;

            // Skip if no commission due (might have been settled already)
            if (commissionDue === 0) {
              console.log(`ℹ️  Driver ${driverId}: No commission due (already settled)`);
              return;
            }

            const newBalance = currentBalance - commissionDue;

            console.log(`💰 Driver ${driverId}:`);
            console.log(`   Commission Due: ₹${commissionDue}`);
            console.log(`   Current Balance: ₹${currentBalance}`);
            console.log(`   New Balance: ₹${newBalance}`);

            // Update 1: Deduct commission from wallet
            transaction.update(driverRef, {
              walletBalance: newBalance,
              dailyCommissionDue: 0,
              lastSettlementDate: admin.firestore.FieldValue.serverTimestamp()
            });

            // Update 2: Create settlement audit entry in walletHistory
            const historyRef = driverRef.collection('walletHistory').doc();
            transaction.set(historyRef, {
              amount: commissionDue,
              type: 'settlement',
              description: 'Daily commission settlement',
              balanceAfter: newBalance,
              settlementDate: admin.firestore.FieldValue.serverTimestamp(),
              createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
          });

          console.log(`✅ Settled driver ${driverId} successfully`);

        } catch (error) {
          console.error(`❌ Settlement failed for driver ${driverId}:`, error);
          // Continue processing other drivers even if one fails
        }
      });

      // Wait for all settlements to complete
      await Promise.all(settlementPromises);

      console.log('✅ ============================================');
      console.log('✅ DAILY SETTLEMENT COMPLETED');
      console.log('✅ ============================================');

      return null;

    } catch (error) {
      console.error('❌ CRITICAL: Daily settlement job failed:', error);
      console.error('Stack:', error.stack);
      throw error; // Re-throw to mark job as failed in Cloud Scheduler
    }
  });


// ============================================================================
// RIDE COMPLETION TRIGGER
// ============================================================================

/**
 * Firestore trigger that updates dailyCommissionDue when ride is completed
 * 
 * TRIGGER: rideRequests/{rideId} onUpdate
 * 
 * LOGIC:
 * - Detects status change from any state to 'completed'
 * - Calculates 20% commission from finalFare
 * - Increments driver's dailyCommissionDue
 * 
 * NOTE: Wallet balance is NOT updated here
 * Commission is accumulated and deducted at 11:59 PM by dailySettlement
 */
exports.onRideCompleted = functions
  .region('asia-south1')
  .firestore
  .document('rideRequests/{rideId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const rideId = context.params.rideId;

    // Only trigger when status changes to 'completed'
    if (beforeData.status !== 'completed' && afterData.status === 'completed') {
      const driverId = afterData.driverId;
      const fare = afterData.finalFare || 0;
      const commissionRate = 0.20; // 20%
      const commission = fare * commissionRate;

      if (!driverId) {
        console.error(`❌ Ride ${rideId} marked complete but no driverId found`);
        return;
      }

      if (commission === 0) {
        console.log(`ℹ️  Ride ${rideId} has zero fare/commission`);
        return;
      }

      console.log(`🚗 Ride completed: ${rideId}`);
      console.log(`   Driver ID: ${driverId}`);
      console.log(`   Fare: ₹${fare}`);
      console.log(`   Commission (20%): ₹${commission}`);

      try {
        const driverRef = db.collection('drivers').doc(driverId);

        // Increment dailyCommissionDue
        await driverRef.update({
          dailyCommissionDue: admin.firestore.FieldValue.increment(commission)
        });

        console.log(`✅ Added ₹${commission} to driver ${driverId}'s commission due`);

      } catch (error) {
        console.error(`❌ Error updating commission for driver ${driverId}:`, error);
        console.error('Stack:', error.stack);
      }
    }
  });


// ============================================================================
// UTILITY FUNCTIONS (FOR TESTING/MIGRATION)
// ============================================================================

/**
 * Manual trigger for testing settlement
 * Call via: firebase functions:shell > testSettlement()
 */
exports.testSettlement = functions
  .region('asia-south1')
  .https.onRequest(async (req, res) => {
    console.log('🧪 TEST SETTLEMENT TRIGGERED MANUALLY');

    try {
      // Call the actual settlement function logic
      await exports.dailySettlement.run(null);
      res.status(200).send('Test settlement completed successfully');
    } catch (error) {
      console.error('Test settlement failed:', error);
      res.status(500).send('Test settlement failed: ' + error.message);
    }
  });
