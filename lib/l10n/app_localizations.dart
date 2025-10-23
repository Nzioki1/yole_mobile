import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'YOLE'**
  String get appTitle;

  /// Main description text on splash screen
  ///
  /// In en, this message translates to:
  /// **'Send money to the DRC quickly and securely'**
  String get sendMoneyDescription;

  /// Get started button text
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// Log in button text
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// English language label
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// French language label
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// Create account button text
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Welcome screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Email verification instruction
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmail;

  /// Check email instruction
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// KYC verification screen title
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycVerification;

  /// Phone verification screen title
  ///
  /// In en, this message translates to:
  /// **'Phone Verification'**
  String get phoneVerification;

  /// Phone number input instruction
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// Send OTP button text
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// OTP input instruction
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterOTP;

  /// Verify button text
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// ID document upload title
  ///
  /// In en, this message translates to:
  /// **'Upload ID Document'**
  String get uploadID;

  /// Take selfie button text
  ///
  /// In en, this message translates to:
  /// **'Take Selfie'**
  String get takeSelfie;

  /// Verification complete screen title
  ///
  /// In en, this message translates to:
  /// **'Verification Complete'**
  String get verificationComplete;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Transactions tab label
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// Favorites navigation label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Welcome screen headline
  ///
  /// In en, this message translates to:
  /// **'Quick and convenient'**
  String get quickAndConvenient;

  /// Welcome screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Send and receive money in minutes.'**
  String get sendAndReceiveMoney;

  /// Already have account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Home screen greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, John 👋'**
  String get goodAfternoon;

  /// Send money screen title
  ///
  /// In en, this message translates to:
  /// **'Send Money'**
  String get sendMoney;

  /// Receive money button text
  ///
  /// In en, this message translates to:
  /// **'Receive Money'**
  String get receiveMoney;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Recent transactions section title
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// Login screen welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// Email address setting
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Forgot password screen title
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// Sign up prompt text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// Sign up link text
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// Log out button text
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Create account screen title
  ///
  /// In en, this message translates to:
  /// **'Join Yole today'**
  String get joinYoleToday;

  /// Transaction status - completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Transaction status - processing
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// Transaction status - pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Transaction status - failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Transaction status - cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Transaction status - delivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Email verification screen title
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// Email verification code instruction
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your email'**
  String get enterVerificationCode;

  /// Resend verification code button
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// KYC verification instruction
  ///
  /// In en, this message translates to:
  /// **'Complete your verification'**
  String get completeVerification;

  /// ID document screen title
  ///
  /// In en, this message translates to:
  /// **'ID Document'**
  String get idDocument;

  /// ID document upload instruction
  ///
  /// In en, this message translates to:
  /// **'Upload your ID document'**
  String get uploadIdDocument;

  /// Selfie instruction
  ///
  /// In en, this message translates to:
  /// **'Take a selfie to complete verification'**
  String get takeSelfieInstruction;

  /// Verification success message
  ///
  /// In en, this message translates to:
  /// **'Your verification is complete!'**
  String get verificationSuccess;

  /// Amount input screen title
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// Recipient input screen title
  ///
  /// In en, this message translates to:
  /// **'Enter Recipient'**
  String get enterRecipient;

  /// Transaction review screen title
  ///
  /// In en, this message translates to:
  /// **'Review Transaction'**
  String get reviewTransaction;

  /// Payment method screen title
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Transaction result screen title
  ///
  /// In en, this message translates to:
  /// **'Transaction Result'**
  String get transactionResult;

  /// Reset password button text
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Email reset instruction
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password.'**
  String get enterEmailToReset;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// OTP input screen title
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOTPCode;

  /// Verification code input label
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// Verify OTP button text
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOTP;

  /// ID capture screen title
  ///
  /// In en, this message translates to:
  /// **'Capture ID'**
  String get captureID;

  /// Selfie capture screen title
  ///
  /// In en, this message translates to:
  /// **'Capture Selfie'**
  String get captureSelfie;

  /// Verification error screen title
  ///
  /// In en, this message translates to:
  /// **'Verification Error'**
  String get verificationError;

  /// Verification failed message
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// Try again button text
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Amount input label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Recipient input label
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// Payment method selection instruction
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// Confirm payment button text
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// Transaction success message
  ///
  /// In en, this message translates to:
  /// **'Transaction Successful'**
  String get transactionSuccessful;

  /// Transaction failed message
  ///
  /// In en, this message translates to:
  /// **'Transaction Failed'**
  String get transactionFailed;

  /// Back to home button text
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// Step indicator text
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String stepXofY(int step, int total);

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Country field label
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Send reset link button text
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// Remember password text
  ///
  /// In en, this message translates to:
  /// **'Remember your password? '**
  String get rememberPassword;

  /// You can now text
  ///
  /// In en, this message translates to:
  /// **'You can now:'**
  String get youCanNow;

  /// Opening in browser message
  ///
  /// In en, this message translates to:
  /// **'Opening in browser...'**
  String get openingInBrowser;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailPlaceholder;

  /// Phone input placeholder
  ///
  /// In en, this message translates to:
  /// **'123 456 7890'**
  String get phonePlaceholder;

  /// Identity verification title
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// Identity verification description
  ///
  /// In en, this message translates to:
  /// **'We need to verify your identity to comply with regulations and keep your money safe.'**
  String get verifyIdentityDescription;

  /// What you need section header
  ///
  /// In en, this message translates to:
  /// **'What you\'ll need:'**
  String get whatYouNeed;

  /// Government ID requirement
  ///
  /// In en, this message translates to:
  /// **'Government-issued ID (passport, driver\'s license)'**
  String get governmentId;

  /// Clear photo requirement
  ///
  /// In en, this message translates to:
  /// **'Clear photo of your face'**
  String get clearPhoto;

  /// Time required
  ///
  /// In en, this message translates to:
  /// **'2-3 minutes of your time'**
  String get timeRequired;

  /// Document upload section title
  ///
  /// In en, this message translates to:
  /// **'Document Upload'**
  String get documentUpload;

  /// Upload clear photo instruction
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of your government ID'**
  String get uploadClearPhoto;

  /// Document upload success message
  ///
  /// In en, this message translates to:
  /// **'Document uploaded successfully!'**
  String get documentUploadedSuccess;

  /// Verified status
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Take photo button text
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Upload from gallery button text
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get uploadFromGallery;

  /// Document requirements header
  ///
  /// In en, this message translates to:
  /// **'Make sure your document:'**
  String get makeSureDocument;

  /// Document visibility requirement
  ///
  /// In en, this message translates to:
  /// **'Is clearly visible and not blurry'**
  String get clearlyVisible;

  /// Document corners requirement
  ///
  /// In en, this message translates to:
  /// **'Shows all four corners'**
  String get showFourCorners;

  /// Document expiration requirement
  ///
  /// In en, this message translates to:
  /// **'Is not expired'**
  String get notExpired;

  /// Selfie verification section title
  ///
  /// In en, this message translates to:
  /// **'Selfie Verification'**
  String get selfieVerification;

  /// Selfie capture success message
  ///
  /// In en, this message translates to:
  /// **'Selfie captured successfully!'**
  String get selfieCapturedSuccess;

  /// Best results header
  ///
  /// In en, this message translates to:
  /// **'For best results:'**
  String get forBestResults;

  /// Look at camera instruction
  ///
  /// In en, this message translates to:
  /// **'Look directly at the camera'**
  String get lookAtCamera;

  /// Remove glasses instruction
  ///
  /// In en, this message translates to:
  /// **'Remove glasses and hats'**
  String get removeGlasses;

  /// Good lighting instruction
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting'**
  String get ensureGoodLighting;

  /// Reset instructions message
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you reset instructions.'**
  String get weWillSendInstructions;

  /// Email validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Valid email validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Check email reset instructions
  ///
  /// In en, this message translates to:
  /// **'Check your email — we\'ve sent you reset instructions.'**
  String get checkEmailResetInstructions;

  /// Follow link instruction
  ///
  /// In en, this message translates to:
  /// **'Follow the link in the email to reset your password.'**
  String get followLinkToReset;

  /// Back to login button text
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// Didn't receive email question
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email?'**
  String get didntReceiveEmail;

  /// Verification code instruction
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to confirm your identity.'**
  String get weWillSendVerificationCode;

  /// Country selection placeholder
  ///
  /// In en, this message translates to:
  /// **'Select your country'**
  String get selectYourCountry;

  /// Standard rates disclaimer
  ///
  /// In en, this message translates to:
  /// **'Standard message and data rates may apply.'**
  String get standardRatesApply;

  /// Send verification code button text
  ///
  /// In en, this message translates to:
  /// **'Send verification code'**
  String get sendVerificationCode;

  /// Enter 6-digit code instruction
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// Enter 6-digit code with phone number
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {phoneNumber}.'**
  String enterSixDigitCodeSent(String phoneNumber);

  /// Didn't receive code question
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// Resend code button text
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// Verify code button text
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get verifyCode;

  /// Verification success message
  ///
  /// In en, this message translates to:
  /// **'Verification successful'**
  String get verificationSuccessful;

  /// Account ready message
  ///
  /// In en, this message translates to:
  /// **'You\'re all set to start using your account.'**
  String get youAreAllSet;

  /// Send money to DRC feature item
  ///
  /// In en, this message translates to:
  /// **'Send money to DRC'**
  String get sendMoneyToDRC;

  /// Track transactions feature
  ///
  /// In en, this message translates to:
  /// **'Track your transactions'**
  String get trackTransactions;

  /// Manage favorites feature
  ///
  /// In en, this message translates to:
  /// **'Manage your favorites'**
  String get manageFavorites;

  /// Access account securely feature
  ///
  /// In en, this message translates to:
  /// **'Access your account securely'**
  String get accessAccountSecurely;

  /// Welcome message with celebration emoji
  ///
  /// In en, this message translates to:
  /// **'Welcome to Yole! 🎉'**
  String get welcomeToYole;

  /// Verification link instruction
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to your email address. Click the link to activate your account.'**
  String get weSentVerificationLink;

  /// Sending status
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// Resend in text
  ///
  /// In en, this message translates to:
  /// **'Resend in'**
  String get resendIn;

  /// Resend verification email button
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// Wrong email text
  ///
  /// In en, this message translates to:
  /// **'Wrong email? '**
  String get wrongEmail;

  /// Go back button text
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// Search contacts hint text
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContacts;

  /// Preferences section header
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Default currency setting
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrency;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Account section header
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Personal information setting
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// History navigation label
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// All transactions header
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Route not found message
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// Navigation test screen title
  ///
  /// In en, this message translates to:
  /// **'Navigation Test'**
  String get navigationTest;

  /// Go to home button text
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Change password setting
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Biometric login setting
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// Two-factor authentication setting
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthentication;

  /// Help center setting
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// Terms and conditions setting
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// Privacy policy setting
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Security section header
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Support section header
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Create account description text
  ///
  /// In en, this message translates to:
  /// **'Create your account to start sending money'**
  String get createAccountDescription;

  /// First name field placeholder
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNamePlaceholder;

  /// Last name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNamePlaceholder;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get passwordPlaceholder;

  /// Country validation message
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get pleaseSelectCountry;

  /// Required field validation message
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get thisFieldRequired;

  /// Email required validation message
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Valid email validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// Password required validation message
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Password length validation message
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get useAtLeast6Characters;

  /// Standard message and data rates disclaimer
  ///
  /// In en, this message translates to:
  /// **'Standard message and data rates may apply.'**
  String get standardMessageRates;

  /// OTP verification message with phone number
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {phoneNumber}'**
  String enterSixDigitCodeWeSentTo(String phoneNumber);

  /// Track transactions feature item
  ///
  /// In en, this message translates to:
  /// **'Track your transactions'**
  String get trackYourTransactions;

  /// Manage favorites feature item
  ///
  /// In en, this message translates to:
  /// **'Manage your favorites'**
  String get manageYourFavorites;

  /// Access account securely feature item
  ///
  /// In en, this message translates to:
  /// **'Access your account securely'**
  String get accessYourAccountSecurely;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
