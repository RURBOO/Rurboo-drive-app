import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'RURBOO Driver'**
  String get appName;

  /// No description provided for @youAreOnline.
  ///
  /// In en, this message translates to:
  /// **'You are Online'**
  String get youAreOnline;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are Offline'**
  String get youAreOffline;

  /// No description provided for @goOnlineToEarn.
  ///
  /// In en, this message translates to:
  /// **'You are Offline.\nGo Online to earn.'**
  String get goOnlineToEarn;

  /// No description provided for @gpsReady.
  ///
  /// In en, this message translates to:
  /// **'GPS Ready'**
  String get gpsReady;

  /// No description provided for @searchingGps.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searchingGps;

  /// No description provided for @newRideRequest.
  ///
  /// In en, this message translates to:
  /// **'New Ride Request'**
  String get newRideRequest;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get drop;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'START TRIP (ENTER OTP)'**
  String get startTrip;

  /// No description provided for @endTrip.
  ///
  /// In en, this message translates to:
  /// **'END TRIP'**
  String get endTrip;

  /// No description provided for @cancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride'**
  String get cancelRide;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Customer OTP'**
  String get enterOtp;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'My Earnings'**
  String get earnings;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Ride History'**
  String get history;

  /// No description provided for @todayEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get todayEarnings;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get thisWeek;

  /// No description provided for @recentHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent History'**
  String get recentHistory;

  /// No description provided for @grossEarnings.
  ///
  /// In en, this message translates to:
  /// **'Gross Earnings'**
  String get grossEarnings;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @cashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash Collected'**
  String get cashCollected;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @rideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride Cancelled'**
  String get rideCancelled;

  /// No description provided for @rideCancelledByUser.
  ///
  /// In en, this message translates to:
  /// **'The user has cancelled this ride.'**
  String get rideCancelledByUser;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride?'**
  String get confirmCancel;

  /// No description provided for @confirmCancelMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this ride? Frequent cancellations may affect your rating.'**
  String get confirmCancelMsg;

  /// No description provided for @noGoBack.
  ///
  /// In en, this message translates to:
  /// **'No, Go Back'**
  String get noGoBack;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @arrivingAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Arriving at Pickup'**
  String get arrivingAtPickup;

  /// No description provided for @droppingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Dropping Customer'**
  String get droppingCustomer;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get mins;

  /// No description provided for @tripStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip Started!'**
  String get tripStarted;

  /// No description provided for @incorrectOtp.
  ///
  /// In en, this message translates to:
  /// **'Incorrect OTP'**
  String get incorrectOtp;

  /// No description provided for @rides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get rides;

  /// No description provided for @noRides.
  ///
  /// In en, this message translates to:
  /// **'No rides yet.'**
  String get noRides;

  /// No description provided for @freeTrial.
  ///
  /// In en, this message translates to:
  /// **'Free Trial'**
  String get freeTrial;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No ride history found'**
  String get noHistory;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completed;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Needed'**
  String get locationPermissionNeeded;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @securityTracking.
  ///
  /// In en, this message translates to:
  /// **'Your location is being tracked for security reasons.'**
  String get securityTracking;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @rideSafetyWarning.
  ///
  /// In en, this message translates to:
  /// **'Ride Safety Warning'**
  String get rideSafetyWarning;

  /// No description provided for @endRideTooFar.
  ///
  /// In en, this message translates to:
  /// **'You are far from the destination. Request passenger approval to end ride?'**
  String get endRideTooFar;

  /// No description provided for @requestApproval.
  ///
  /// In en, this message translates to:
  /// **'Request Approval'**
  String get requestApproval;

  /// No description provided for @waitingForApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Passenger Approval...'**
  String get waitingForApproval;

  /// No description provided for @rideEndApproved.
  ///
  /// In en, this message translates to:
  /// **'Passenger approved ride end.'**
  String get rideEndApproved;

  /// No description provided for @rideEndRejected.
  ///
  /// In en, this message translates to:
  /// **'Passenger rejected ride end.'**
  String get rideEndRejected;

  /// No description provided for @driveEarnGrow.
  ///
  /// In en, this message translates to:
  /// **'Drive. Earn. Grow.'**
  String get driveEarnGrow;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @newDriver.
  ///
  /// In en, this message translates to:
  /// **'New Driver?'**
  String get newDriver;

  /// No description provided for @registerHere.
  ///
  /// In en, this message translates to:
  /// **'Register Here'**
  String get registerHere;

  /// No description provided for @termsPrivacyLogin.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our\\nTerms of Service & Privacy Policy'**
  String get termsPrivacyLogin;

  /// No description provided for @driverRegistration.
  ///
  /// In en, this message translates to:
  /// **'Driver Registration'**
  String get driverRegistration;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameLengthError.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get nameLengthError;

  /// No description provided for @nameNumberError.
  ///
  /// In en, this message translates to:
  /// **'Name cannot contain numbers'**
  String get nameNumberError;

  /// No description provided for @nextVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Next: Vehicle Details'**
  String get nextVehicleDetails;

  /// No description provided for @validMobileError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get validMobileError;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @gpsOffMessage.
  ///
  /// In en, this message translates to:
  /// **'GPS is turned off! You cannot work.'**
  String get gpsOffMessage;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'TURN ON'**
  String get turnOn;

  /// No description provided for @gpsConnected.
  ///
  /// In en, this message translates to:
  /// **'GPS Connected'**
  String get gpsConnected;

  /// No description provided for @searchingGpsStatus.
  ///
  /// In en, this message translates to:
  /// **'Searching for GPS...'**
  String get searchingGpsStatus;

  /// No description provided for @currentSpeed.
  ///
  /// In en, this message translates to:
  /// **'Current Speed'**
  String get currentSpeed;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS Accuracy'**
  String get gpsAccuracy;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// No description provided for @recenterMap.
  ///
  /// In en, this message translates to:
  /// **'Recenter Map'**
  String get recenterMap;

  /// No description provided for @fetchingAddress.
  ///
  /// In en, this message translates to:
  /// **'Fetching address...'**
  String get fetchingAddress;

  /// No description provided for @cannotGoOfflineTrip.
  ///
  /// In en, this message translates to:
  /// **'Cannot go offline during a trip'**
  String get cannotGoOfflineTrip;

  /// No description provided for @turnOnGpsFirst.
  ///
  /// In en, this message translates to:
  /// **'Turn on GPS first!'**
  String get turnOnGpsFirst;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @faqs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get faqs;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @feedbackAndSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Suggestions'**
  String get feedbackAndSuggestions;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @myDocuments.
  ///
  /// In en, this message translates to:
  /// **'My Documents'**
  String get myDocuments;

  /// No description provided for @drivingLicense.
  ///
  /// In en, this message translates to:
  /// **'Driving License'**
  String get drivingLicense;

  /// No description provided for @rc.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration (RC)'**
  String get rc;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Insurance'**
  String get insurance;

  /// No description provided for @vehicleFront.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Front Photo'**
  String get vehicleFront;

  /// No description provided for @numberPlateHint.
  ///
  /// In en, this message translates to:
  /// **'Ensure number plate is visible'**
  String get numberPlateHint;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Uploaded successfully ✓'**
  String get uploadSuccess;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to Upload'**
  String get tapToUpload;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @personalDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetailsTitle;

  /// No description provided for @vehicleDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details'**
  String get vehicleDetailsTitle;

  /// No description provided for @vehicleMakeModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Make & Model'**
  String get vehicleMakeModel;

  /// No description provided for @vehicleNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get vehicleNumberLabel;

  /// No description provided for @phoneCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Phone number cannot be changed'**
  String get phoneCannotBeChanged;

  /// No description provided for @newRideNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'🚖 New Ride Request!'**
  String get newRideNotificationTitle;

  /// No description provided for @newRideNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {address}'**
  String newRideNotificationBody(Object address);

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @voiceAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Voice Announcements'**
  String get voiceAnnouncements;

  /// No description provided for @turnOnOffVoice.
  ///
  /// In en, this message translates to:
  /// **'Turn on/off app voice'**
  String get turnOnOffVoice;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @myVehicles.
  ///
  /// In en, this message translates to:
  /// **'My Vehicles'**
  String get myVehicles;

  /// No description provided for @manageVehicles.
  ///
  /// In en, this message translates to:
  /// **'Manage Vehicles'**
  String get manageVehicles;

  /// No description provided for @voiceAnnouncementsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Voice announcements enabled'**
  String get voiceAnnouncementsEnabled;

  /// No description provided for @voiceAnnouncementsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Voice announcements disabled'**
  String get voiceAnnouncementsDisabled;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language / भाषा चुनें'**
  String get selectLanguageTitle;

  /// No description provided for @securityCheck.
  ///
  /// In en, this message translates to:
  /// **'Security Check'**
  String get securityCheck;

  /// No description provided for @reauthRequired.
  ///
  /// In en, this message translates to:
  /// **'For security, please logout and login again to delete your account.'**
  String get reauthRequired;

  /// No description provided for @logoutNow.
  ///
  /// In en, this message translates to:
  /// **'Logout Now'**
  String get logoutNow;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent. You will lose your ride history, earnings data, and profile details immediately.'**
  String get deleteAccountDesc;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason for leaving (Optional)'**
  String get reasonOptional;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Account'**
  String get permanentlyDelete;

  /// No description provided for @accountDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully.'**
  String get accountDeletedSuccess;

  /// No description provided for @pendingDuesError.
  ///
  /// In en, this message translates to:
  /// **'You have pending dues of ₹{amount}. Please clear them before deleting your account.'**
  String pendingDuesError(Object amount);

  /// No description provided for @bookingForPassenger.
  ///
  /// In en, this message translates to:
  /// **'Booking for Passenger'**
  String get bookingForPassenger;

  /// No description provided for @rechargeWallet.
  ///
  /// In en, this message translates to:
  /// **'Recharge Wallet'**
  String get rechargeWallet;

  /// No description provided for @enterRechargeAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount to add to your wallet'**
  String get enterRechargeAmount;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get amountHint;

  /// No description provided for @minimumRechargeInfo.
  ///
  /// In en, this message translates to:
  /// **'💡 Minimum: ₹100'**
  String get minimumRechargeInfo;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @minRechargeError.
  ///
  /// In en, this message translates to:
  /// **'Minimum recharge amount is ₹100'**
  String get minRechargeError;

  /// No description provided for @paymentGatewayError.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Payment gateway not configured. Please contact support.'**
  String get paymentGatewayError;

  /// No description provided for @paymentSuccessVoice.
  ///
  /// In en, this message translates to:
  /// **'Payment successful! Your wallet has been recharged.'**
  String get paymentSuccessVoice;

  /// No description provided for @paymentSuccessMsg.
  ///
  /// In en, this message translates to:
  /// **'Payment successful! Wallet updated.'**
  String get paymentSuccessMsg;

  /// No description provided for @paymentFailedVoice.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get paymentFailedVoice;

  /// No description provided for @paymentFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {error}'**
  String paymentFailedMsg(Object error);

  /// No description provided for @myWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get myWalletTitle;

  /// No description provided for @negativeBalanceWarning.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is negative. Recharge to go online!'**
  String get negativeBalanceWarning;

  /// No description provided for @walletBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalanceLabel;

  /// No description provided for @todaysDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Due'**
  String get todaysDueLabel;

  /// No description provided for @addMoneyBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Money via Razorpay'**
  String get addMoneyBtn;

  /// No description provided for @commissionInfo.
  ///
  /// In en, this message translates to:
  /// **'💡 Commission is deducted daily at 11:59 PM'**
  String get commissionInfo;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @walletRechargeDescription.
  ///
  /// In en, this message translates to:
  /// **'Wallet Recharge (Razorpay)'**
  String get walletRechargeDescription;

  /// No description provided for @gpsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Cannot go online: GPS not ready'**
  String get gpsNotReady;

  /// No description provided for @sessionInvalid.
  ///
  /// In en, this message translates to:
  /// **'Session Invalid. Please logout and login again.'**
  String get sessionInvalid;

  /// No description provided for @accountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Account Mismatch. Please relogin to sync.'**
  String get accountMismatch;

  /// No description provided for @walletRechargeRequired.
  ///
  /// In en, this message translates to:
  /// **'Wallet Recharge Required'**
  String get walletRechargeRequired;

  /// No description provided for @goToWalletAndRecharge.
  ///
  /// In en, this message translates to:
  /// **'Go to Wallet & Recharge'**
  String get goToWalletAndRecharge;

  /// No description provided for @requestAlliance.
  ///
  /// In en, this message translates to:
  /// **'Request Driver Alliance'**
  String get requestAlliance;

  /// No description provided for @allianceDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask nearby drivers for help. Select issue type:'**
  String get allianceDescription;

  /// No description provided for @mechanicalFailure.
  ///
  /// In en, this message translates to:
  /// **'🔧 Mechanical Failure'**
  String get mechanicalFailure;

  /// No description provided for @medicalEmergency.
  ///
  /// In en, this message translates to:
  /// **'🚑 Medical Emergency'**
  String get medicalEmergency;

  /// No description provided for @securityThreat.
  ///
  /// In en, this message translates to:
  /// **'🛡️ Security Threat'**
  String get securityThreat;

  /// No description provided for @otherHelp.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Other Help'**
  String get otherHelp;

  /// No description provided for @allianceAlert.
  ///
  /// In en, this message translates to:
  /// **'Alliance Alert!'**
  String get allianceAlert;

  /// No description provided for @nearbyDriverNeedsHelp.
  ///
  /// In en, this message translates to:
  /// **'A nearby driver needs {type} help!'**
  String nearbyDriverNeedsHelp(Object type);

  /// No description provided for @goToAssist.
  ///
  /// In en, this message translates to:
  /// **'Go to Assist'**
  String get goToAssist;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
