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

// ============================================================================
// FARE CALCULATION & COMMISSION CONFIG
// ============================================================================

/**
 * Provides secure fare calculation for requested distance and vehicle type.
 * Preventing client-side fare tampering.
 * 
 * CALLABLE: provideFare({ vehicleKey, distanceKm })
 */
exports.provideFare = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
    }

    const { vehicleKey, distanceKm } = data;
    if (!vehicleKey || distanceKm === undefined) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing vehicleKey or distanceKm');
    }

    try {
      // 2. Fetch latest rates from Firestore config
      const configDoc = await db.collection('config').doc('rates').get();
      const rates = configDoc.exists ? configDoc.data() : {};

      const _defaultRates = {
        'bike': { 'base_fare': 40, 'per_km': 9, 'night_charge': 10 },
        'auto': { 'base_fare': 80, 'per_km': 16, 'night_charge': 20 },
        'car': { 'base_fare': 150, 'per_km': 25, 'night_charge': 40 },
        'erickshaw': { 'base_fare': 60, 'per_km': 13, 'night_charge': 15 },
        'bigcar': { 'base_fare': 200, 'per_km': 30, 'night_charge': 50 },
        'carriertruck': { 'base_fare': 250, 'per_km': 40, 'night_charge': 60 },
      };

      let rateData = rates[vehicleKey] || _defaultRates[vehicleKey] || _defaultRates['car'];

      const baseFare = parseFloat(rateData.base_fare || 100);
      const perKmRate = parseFloat(rateData.per_km || 20);
      const includedKm = 2;

      // 3. Distance math
      let fare = baseFare;
      if (distanceKm > includedKm) {
        fare = baseFare + ((distanceKm - includedKm) * perKmRate);
      }

      // 4. Night Charge (10 PM to 5 AM IST)
      const now = new Date();
      const istOffset = 5.5 * 60 * 60 * 1000;
      const istTime = new Date(now.getTime() + istOffset);
      const hour = istTime.getUTCHours();

      if (hour >= 22 || hour < 5) {
        fare += parseFloat(rateData.night_charge || 0);
      }

      const finalFare = Math.round(fare);

      console.log(`💰 Secure Fare Calculated for ${vehicleKey}: ₹${finalFare} (${distanceKm}km)`);

      return {
        fare: finalFare,
        vehicleKey: vehicleKey,
        distanceKm: distanceKm,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      };

    } catch (error) {
      console.error('❌ Fare calculation error:', error);
      throw new functions.https.HttpsError('internal', 'Failed to calculate fare');
    }
  });

/**
 * Firestore trigger that updates dailyCommissionDue when ride is completed
 * USES DYNAMIC RATES from config/rates
 */
exports.onRideCompleted = functions
  .region('asia-south1')
  .firestore
  .document('rideRequests/{rideId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const rideId = context.params.rideId;

    if (beforeData.status !== 'completed' && afterData.status === 'completed') {
      const driverId = afterData.driverId;
      const fare = afterData.finalFare || afterData.fare || 0;

      try {
        // 1. Fetch dynamic commission rate
        const configDoc = await db.collection('config').doc('rates').get();
        let commissionRate = 0.20; // Default 20%
        if (configDoc.exists && configDoc.data().commission_percent) {
          commissionRate = configDoc.data().commission_percent / 100;
        }

        const commission = fare * commissionRate;

        if (!driverId || commission === 0) return;

        const driverRef = db.collection('drivers').doc(driverId);

        // 2. Transact wallet history + commission due + user ride count
        await db.runTransaction(async (transaction) => {
          // Update driver commission
          transaction.update(driverRef, {
            dailyCommissionDue: admin.firestore.FieldValue.increment(commission)
          });

          // Update user ride count
          if (afterData.userId) {
            const userRef = db.collection('users').doc(afterData.userId);
            transaction.update(userRef, {
              totalRides: admin.firestore.FieldValue.increment(1)
            });
          }

          // Log the commission for transparency
          const logRef = driverRef.collection('walletHistory').doc();
          transaction.set(logRef, {
            amount: commission,
            type: 'debit_pending',
            description: `Commission for ride ${rideId}`,
            rideId: rideId,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });

        console.log(`✅ Commission ₹${commission.toFixed(2)} (${(commissionRate * 100)}%) applied for ride ${rideId}`);

      } catch (error) {
        console.error(`❌ Error updating commission for ride ${rideId}:`, error);
      }
    }
  });


// ============================================================================
// STALE RIDE CLEANUP (AUTO-CANCEL)
// ============================================================================

/**
 * Scheduled function that runs every 5 minutes.
 * Cancels rides that are in 'searching' status for more than 5 minutes.
 */
exports.autoCancelRide = functions
  .region('asia-south1')
  .pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

    console.log(`🧹 Checking for stale rides created before: ${fiveMinutesAgo.toISOString()}`);

    try {
      const staleRidesSnapshot = await db.collection('rideRequests')
        .where('status', '==', 'searching')
        .where('createdAt', '<', fiveMinutesAgo)
        .get();

      if (staleRidesSnapshot.empty) {
        console.log('🧹 No stale rides found.');
        return null;
      }

      console.log(`🧹 Found ${staleRidesSnapshot.size} stale rides. Cancelling...`);

      const batch = db.batch();
      staleRidesSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          status: 'cancelled',
          cancelledBy: 'system',
          cancelReason: 'No drivers found within timeout',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      });

      await batch.commit();
      console.log('✅ Successfully cancelled stale rides.');
      return null;

    } catch (error) {
      console.error('❌ Error in autoCancelRide:', error);
      return null;
    }
  });

