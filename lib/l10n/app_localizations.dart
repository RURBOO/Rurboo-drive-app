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
  /// **'By continuing, you agree to our\nTerms of Service & Privacy Policy'**
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

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @toggleAppTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle app theme'**
  String get toggleAppTheme;

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

  /// No description provided for @tutOnlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get tutOnlineTitle;

  /// No description provided for @tutOnlineBody.
  ///
  /// In en, this message translates to:
  /// **'Slide this switch to start receiving ride requests from nearby customers.'**
  String get tutOnlineBody;

  /// No description provided for @tutGpsTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS Status'**
  String get tutGpsTitle;

  /// No description provided for @tutGpsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap here to see your current speed and GPS accuracy. Green means you\'re ready!'**
  String get tutGpsBody;

  /// No description provided for @tutSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get tutSosTitle;

  /// No description provided for @tutSosBody.
  ///
  /// In en, this message translates to:
  /// **'In case of emergency, tap this button to immediately alert local authorities.'**
  String get tutSosBody;

  /// No description provided for @tutAllianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Alliance'**
  String get tutAllianceTitle;

  /// No description provided for @tutAllianceBody.
  ///
  /// In en, this message translates to:
  /// **'Mechanical failure or medical emergency? Tap this to ask nearby drivers for help.'**
  String get tutAllianceBody;

  /// No description provided for @tutNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation Bar'**
  String get tutNavTitle;

  /// No description provided for @tutNavBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between Map, your Earnings, and Profile details easily from here.'**
  String get tutNavBody;

  /// No description provided for @slideToStart.
  ///
  /// In en, this message translates to:
  /// **'Slide to Start Trip'**
  String get slideToStart;

  /// No description provided for @slideToEnd.
  ///
  /// In en, this message translates to:
  /// **'Slide to End Trip'**
  String get slideToEnd;

  /// No description provided for @tripStartedMsg.
  ///
  /// In en, this message translates to:
  /// **'Trip Started!'**
  String get tripStartedMsg;

  /// No description provided for @incorrectOtpMsg.
  ///
  /// In en, this message translates to:
  /// **'Incorrect OTP'**
  String get incorrectOtpMsg;

  /// No description provided for @askOtpDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask the customer for the 4-digit OTP to start the ride.'**
  String get askOtpDescription;

  /// No description provided for @onTripHeader.
  ///
  /// In en, this message translates to:
  /// **'On Trip - {status}'**
  String onTripHeader(Object status);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @selectPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select your preferred language'**
  String get selectPreferredLanguage;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @ageRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get ageRequired;

  /// No description provided for @underageError.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old'**
  String get underageError;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get genderRequired;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Phone'**
  String get emergencyContactPhone;

  /// No description provided for @validEmergencyPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Valid 10-digit phone required'**
  String get validEmergencyPhoneError;

  /// No description provided for @otp_screen_voice.
  ///
  /// In en, this message translates to:
  /// **'OTP screen. Please enter the 6 digit verification code sent to your mobile.'**
  String get otp_screen_voice;

  /// No description provided for @otp_resend_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend OTP. Please try again.'**
  String get otp_resend_failed;

  /// No description provided for @otp_resend_success.
  ///
  /// In en, this message translates to:
  /// **'New OTP sent successfully!'**
  String get otp_resend_success;

  /// No description provided for @otp_send_error.
  ///
  /// In en, this message translates to:
  /// **'Error sending OTP'**
  String get otp_send_error;

  /// No description provided for @otp_6_digit_error.
  ///
  /// In en, this message translates to:
  /// **'Please enter 6 digit OTP'**
  String get otp_6_digit_error;

  /// No description provided for @login_screen_voice.
  ///
  /// In en, this message translates to:
  /// **'Login screen. Please enter your phone number.'**
  String get login_screen_voice;

  /// No description provided for @phone_number_voice.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone_number_voice;

  /// No description provided for @wallet_screen_voice.
  ///
  /// In en, this message translates to:
  /// **'Wallet screen'**
  String get wallet_screen_voice;

  /// No description provided for @payment_success_voice.
  ///
  /// In en, this message translates to:
  /// **'Payment successful! Your wallet has been recharged.'**
  String get payment_success_voice;

  /// No description provided for @payment_failed_voice.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get payment_failed_voice;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String errorGeneric(String msg);

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @emergencyRequest.
  ///
  /// In en, this message translates to:
  /// **'Emergency Assistance Requested'**
  String get emergencyRequest;

  /// No description provided for @driverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name} • {phone}'**
  String driverLabel(String name, String phone);

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternet;

  /// No description provided for @tripCompletedFare.
  ///
  /// In en, this message translates to:
  /// **'Trip completed. Total fare rupees {fare}'**
  String tripCompletedFare(String fare);

  /// No description provided for @rideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Ride Completed'**
  String get rideCompleted;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get tripCompleted;

  /// No description provided for @droppedOff.
  ///
  /// In en, this message translates to:
  /// **'You successfully dropped off {name}.'**
  String droppedOff(String name);

  /// No description provided for @amountToCollect.
  ///
  /// In en, this message translates to:
  /// **'Amount to Collect / Final Fare'**
  String get amountToCollect;

  /// No description provided for @paymentModeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentModeCash;

  /// No description provided for @ratePassenger.
  ///
  /// In en, this message translates to:
  /// **'Rate Passenger'**
  String get ratePassenger;

  /// No description provided for @addCommentPassenger.
  ///
  /// In en, this message translates to:
  /// **'Add a comment about the passenger...'**
  String get addCommentPassenger;

  /// No description provided for @submitReviewExit.
  ///
  /// In en, this message translates to:
  /// **'Submit Review & Exit'**
  String get submitReviewExit;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @reportIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue...'**
  String get reportIssueHint;

  /// No description provided for @reportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully!'**
  String get reportSuccess;

  /// No description provided for @submitText.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitText;

  /// No description provided for @skipText.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipText;

  /// No description provided for @errorSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Error submitting review: {msg}'**
  String errorSubmitReview(String msg);

  /// No description provided for @errorSkipReview.
  ///
  /// In en, this message translates to:
  /// **'Error skipping review: {msg}'**
  String errorSkipReview(String msg);

  /// No description provided for @errorReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String errorReportSubmit(String msg);

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @enterOtpSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to +91 {phone}'**
  String enterOtpSent(String phone);

  /// No description provided for @verifyAndRegister.
  ///
  /// In en, this message translates to:
  /// **'Verify & Register'**
  String get verifyAndRegister;

  /// No description provided for @verifyAndLogin.
  ///
  /// In en, this message translates to:
  /// **'Verify & Login'**
  String get verifyAndLogin;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in ({sec})'**
  String resendOtpIn(String sec);

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? Resend'**
  String get didntReceiveCode;

  /// No description provided for @resendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Resending OTP'**
  String get resendingOtp;

  /// No description provided for @resendFailed.
  ///
  /// In en, this message translates to:
  /// **'Resend failed: {msg}'**
  String resendFailed(String msg);

  /// No description provided for @errorSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String errorSendOtp(String msg);

  /// No description provided for @invalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get invalidOtp;

  /// No description provided for @uploadDocsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents (3/3)'**
  String get uploadDocsTitle;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @vehicleDetailsTitle2.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Details (2/3)'**
  String get vehicleDetailsTitle2;

  /// No description provided for @nextUploadDocs.
  ///
  /// In en, this message translates to:
  /// **'Next: Upload Documents'**
  String get nextUploadDocs;

  /// No description provided for @pendingApprovalMsg.
  ///
  /// In en, this message translates to:
  /// **'Still Pending. Please wait for Admin approval.'**
  String get pendingApprovalMsg;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get locationPermissionTitle;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @uploadRcAndPhoto.
  ///
  /// In en, this message translates to:
  /// **'Please upload both RC and Vehicle Photo'**
  String get uploadRcAndPhoto;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired. Please login again.'**
  String get sessionExpired;

  /// No description provided for @vehicleAddedPending.
  ///
  /// In en, this message translates to:
  /// **'Vehicle added! Waiting for verification.'**
  String get vehicleAddedPending;

  /// No description provided for @errorText.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String errorText(String msg);

  /// No description provided for @noVehiclesFound.
  ///
  /// In en, this message translates to:
  /// **'No vehicles found. Add one to start.'**
  String get noVehiclesFound;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @switchVehicle.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchVehicle;

  /// No description provided for @addNewVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add New Vehicle'**
  String get addNewVehicle;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get thankYou;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been submitted successfully. We appreciate your input.'**
  String get feedbackSubmitted;

  /// No description provided for @errorFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error submitting feedback: {msg}'**
  String errorFeedback(String msg);

  /// No description provided for @driverSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Support'**
  String get driverSupportTitle;

  /// No description provided for @cannotPerformAction.
  ///
  /// In en, this message translates to:
  /// **'Cannot perform action'**
  String get cannotPerformAction;

  /// No description provided for @ticketSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Ticket submitted successfully. We will contact you soon.'**
  String get ticketSubmitted;

  /// No description provided for @ticketFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit ticket: {msg}'**
  String ticketFailed(String msg);

  /// No description provided for @submitTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get submitTicket;

  /// No description provided for @walletLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wallet data: {msg}'**
  String walletLoadFailed(String msg);

  /// No description provided for @driverIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Driver ID not found'**
  String get driverIdNotFound;

  /// No description provided for @paymentStartError.
  ///
  /// In en, this message translates to:
  /// **'Error starting payment: {msg}'**
  String paymentStartError(String msg);

  /// No description provided for @recordSynced.
  ///
  /// In en, this message translates to:
  /// **'Missing record synced successfully!'**
  String get recordSynced;

  /// No description provided for @historyExistsOrZero.
  ///
  /// In en, this message translates to:
  /// **'History already exists or balance is 0.'**
  String get historyExistsOrZero;

  /// No description provided for @cancelError.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling: {msg}'**
  String cancelError(String msg);

  /// No description provided for @rechargeWalletEarnings.
  ///
  /// In en, this message translates to:
  /// **'Recharge Wallet / वॉलेट रिचार्ज'**
  String get rechargeWalletEarnings;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How much commission does Rurboo charge?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'Rurboo charges a standard commission of 20% on the total fare for each completed ride. This helps us maintain the platform, market to riders, and provide support to you.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'How do I get paid?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'Your earnings (minus the 20% commission) are accumulated in your driver wallet. Payouts are processed weekly to your registered bank account or UPI ID.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'What if a rider cancels?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'If a rider cancels after you have already traveled a significant distance towards the pickup location, you may be eligible for a cancellation fee.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'How can I improve my rating?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'Keep your vehicle clean, be polite to riders, drive safely, and follow the navigation route. Good service leads to higher ratings.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'Is there a penalty for declining rides?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'We understand you may not accept every ride. However, a high acceptance rate may unlock special incentives.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In en, this message translates to:
  /// **'How do I contact support?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In en, this message translates to:
  /// **'You can contact support via the \'Help & Support\' section in the app. Email: adarshpandey@rurboo.com or Phone: +91 8810220691'**
  String get faqA6;

  /// No description provided for @feedbackHeading.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback!'**
  String get feedbackHeading;

  /// No description provided for @feedbackSubheading.
  ///
  /// In en, this message translates to:
  /// **'Let us know how we can improve your experience.'**
  String get feedbackSubheading;

  /// No description provided for @feedbackCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get feedbackCategory;

  /// No description provided for @feedbackSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get feedbackSubject;

  /// No description provided for @feedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get feedbackDescription;

  /// No description provided for @feedbackDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your feedback or suggestion in detail...'**
  String get feedbackDescriptionHint;

  /// No description provided for @feedbackSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get feedbackSubjectRequired;

  /// No description provided for @feedbackDescRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get feedbackDescRequired;

  /// No description provided for @feedbackDescMin.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get feedbackDescMin;

  /// No description provided for @feedbackSubmitBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get feedbackSubmitBtn;

  /// No description provided for @feedbackCatSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackCatSuggestion;

  /// No description provided for @feedbackCatAppIssue.
  ///
  /// In en, this message translates to:
  /// **'App Issue'**
  String get feedbackCatAppIssue;

  /// No description provided for @feedbackCatPaymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue'**
  String get feedbackCatPaymentIssue;

  /// No description provided for @feedbackCatSafetyConcern.
  ///
  /// In en, this message translates to:
  /// **'Safety Concern'**
  String get feedbackCatSafetyConcern;

  /// No description provided for @feedbackCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCatOther;

  /// No description provided for @helpHowCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get helpHowCanWeHelp;

  /// No description provided for @helpSubheading.
  ///
  /// In en, this message translates to:
  /// **'Our dedicated support team is here to assist you with any questions or issues.'**
  String get helpSubheading;

  /// No description provided for @helpSubmitTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit a Ticket'**
  String get helpSubmitTicket;

  /// No description provided for @helpReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get helpReason;

  /// No description provided for @helpSelectReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason'**
  String get helpSelectReason;

  /// No description provided for @helpDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get helpDescription;

  /// No description provided for @helpDescRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get helpDescRequired;

  /// No description provided for @helpAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach a screenshot/document (Optional)'**
  String get helpAttachFile;

  /// No description provided for @helpImageAttached.
  ///
  /// In en, this message translates to:
  /// **'Image attached: {name}'**
  String helpImageAttached(String name);

  /// No description provided for @helpReason1.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue'**
  String get helpReason1;

  /// No description provided for @helpReason2.
  ///
  /// In en, this message translates to:
  /// **'App Bug'**
  String get helpReason2;

  /// No description provided for @helpReason3.
  ///
  /// In en, this message translates to:
  /// **'Ride Issue'**
  String get helpReason3;

  /// No description provided for @helpReason4.
  ///
  /// In en, this message translates to:
  /// **'Account Issue'**
  String get helpReason4;

  /// No description provided for @helpReason5.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get helpReason5;

  /// No description provided for @walletRechargeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recharge & Transaction History'**
  String get walletRechargeSubtitle;

  /// No description provided for @helpAndLegal.
  ///
  /// In en, this message translates to:
  /// **'Help & Support and Legal'**
  String get helpAndLegal;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Rubo Driver v1.0.0'**
  String get appVersion;

  /// No description provided for @pendingApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile is currently under review by the Admin Team.\n\nOnce approved, you will be able to accept rides and start earning.'**
  String get pendingApprovalBody;

  /// No description provided for @checkingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking Status...'**
  String get checkingStatus;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshStatus;

  /// No description provided for @signOutGoBack.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutGoBack;

  /// No description provided for @paymentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentModeLabel;

  /// No description provided for @alertMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional Message'**
  String get alertMessageOptional;

  /// No description provided for @writeAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Write alert message...'**
  String get writeAlertMessage;

  /// No description provided for @helpSignalSent.
  ///
  /// In en, this message translates to:
  /// **'Help Signal Sent to nearby drivers!'**
  String get helpSignalSent;
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
