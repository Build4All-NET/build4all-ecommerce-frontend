import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get invalidPhone;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get passwordTooShort;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @noAccountText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountText;

  /// No description provided for @signUpText.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpText;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginWithEmail;

  /// No description provided for @loginWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get loginWithPhone;

  /// No description provided for @loginMissingIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or phone number.'**
  String get loginMissingIdentifier;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to sign up.'**
  String get registerSubtitle;

  /// No description provided for @registerStep1Of3.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 3'**
  String get registerStep1Of3;

  /// No description provided for @registerWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign up with email'**
  String get registerWithEmail;

  /// No description provided for @registerWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign up with phone'**
  String get registerWithPhone;

  /// No description provided for @registerContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinueButton;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @alreadyHaveAccountText.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccountText;

  /// No description provided for @verifyCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get verifyCodeTitle;

  /// No description provided for @verifyCodeSubtitleEmail.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to your email.'**
  String get verifyCodeSubtitleEmail;

  /// No description provided for @verifyCodeSubtitlePhone.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to your phone.'**
  String get verifyCodeSubtitlePhone;

  /// No description provided for @verificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCodeLabel;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid verification code.'**
  String get invalidVerificationCode;

  /// No description provided for @verifyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButtonLabel;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a username and your real name.'**
  String get completeProfileSubtitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @firstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// No description provided for @usernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters.'**
  String get usernameTooShort;

  /// No description provided for @publicProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfileLabel;

  /// No description provided for @publicProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'If enabled, your profile and activities can be found by other users.'**
  String get publicProfileDescription;

  /// No description provided for @saveProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfileButton;

  /// No description provided for @profileCompletedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile completed successfully. You can now log in.'**
  String get profileCompletedSuccessMessage;

  /// No description provided for @profileCompletedErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete profile. Please try again.'**
  String get profileCompletedErrorMessage;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon.'**
  String get featureComingSoon;

  /// No description provided for @changePhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a profile photo'**
  String get changePhotoHint;

  /// No description provided for @previousStepButton.
  ///
  /// In en, this message translates to:
  /// **'Previous Step'**
  String get previousStepButton;

  /// No description provided for @completeProfileNamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile - Names'**
  String get completeProfileNamesTitle;

  /// No description provided for @completeProfileNamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please provide your first and last name.'**
  String get completeProfileNamesSubtitle;

  /// No description provided for @firstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNameHint;

  /// No description provided for @lastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get lastNameHint;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @completeProfileUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile - Username'**
  String get completeProfileUsernameTitle;

  /// No description provided for @completeProfileUsernameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username for your account.'**
  String get completeProfileUsernameSubtitle;

  /// No description provided for @completeProfilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile - Photo'**
  String get completeProfilePhotoTitle;

  /// No description provided for @completeProfilePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a profile picture to personalize your account.'**
  String get completeProfilePhotoSubtitle;

  /// No description provided for @nextStepButton.
  ///
  /// In en, this message translates to:
  /// **'Next Step'**
  String get nextStepButton;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋'**
  String get home_welcome;

  /// No description provided for @home_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search products, brands...'**
  String get home_search_hint;

  /// No description provided for @home_banner_title.
  ///
  /// In en, this message translates to:
  /// **'Special Offers'**
  String get home_banner_title;

  /// No description provided for @home_banner_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Save up to 50% on selected items.'**
  String get home_banner_subtitle;

  /// No description provided for @home_banner_button.
  ///
  /// In en, this message translates to:
  /// **'Start shopping'**
  String get home_banner_button;

  /// No description provided for @home_items_default_title.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get home_items_default_title;

  /// No description provided for @home_recommended_title.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get home_recommended_title;

  /// No description provided for @home_popular_title.
  ///
  /// In en, this message translates to:
  /// **'Popular now'**
  String get home_popular_title;

  /// No description provided for @home_bookings_title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming bookings'**
  String get home_bookings_title;

  /// No description provided for @home_reviews_title.
  ///
  /// In en, this message translates to:
  /// **'Latest reviews'**
  String get home_reviews_title;

  /// No description provided for @home_flash_sale_title.
  ///
  /// In en, this message translates to:
  /// **'Flash Sale'**
  String get home_flash_sale_title;

  /// No description provided for @home_new_arrivals_title.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get home_new_arrivals_title;

  /// No description provided for @home_best_sellers_title.
  ///
  /// In en, this message translates to:
  /// **'Best Sellers'**
  String get home_best_sellers_title;

  /// No description provided for @home_top_rated_title.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get home_top_rated_title;

  /// No description provided for @home_why_shop_title.
  ///
  /// In en, this message translates to:
  /// **'Why Shop With Us'**
  String get home_why_shop_title;

  /// No description provided for @home_why_shop_free_shipping_title.
  ///
  /// In en, this message translates to:
  /// **'Free Shipping'**
  String get home_why_shop_free_shipping_title;

  /// No description provided for @home_why_shop_free_shipping_subtitle.
  ///
  /// In en, this message translates to:
  /// **'On all orders over \$50'**
  String get home_why_shop_free_shipping_subtitle;

  /// No description provided for @home_why_shop_easy_returns_title.
  ///
  /// In en, this message translates to:
  /// **'Easy Returns'**
  String get home_why_shop_easy_returns_title;

  /// No description provided for @home_why_shop_easy_returns_subtitle.
  ///
  /// In en, this message translates to:
  /// **'30-day return policy'**
  String get home_why_shop_easy_returns_subtitle;

  /// No description provided for @home_why_shop_secure_payment_title.
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get home_why_shop_secure_payment_title;

  /// No description provided for @home_why_shop_secure_payment_subtitle.
  ///
  /// In en, this message translates to:
  /// **'100% protected transactions'**
  String get home_why_shop_secure_payment_subtitle;

  /// No description provided for @home_why_shop_support_title.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get home_why_shop_support_title;

  /// No description provided for @home_why_shop_support_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Always here to help you'**
  String get home_why_shop_support_subtitle;

  /// No description provided for @connection_offline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get connection_offline;

  /// No description provided for @connection_server_down.
  ///
  /// In en, this message translates to:
  /// **'Server is not responding'**
  String get connection_server_down;

  /// No description provided for @profile_login_required.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your profile.'**
  String get profile_login_required;

  /// No description provided for @connection_issue.
  ///
  /// In en, this message translates to:
  /// **'Connection issue'**
  String get connection_issue;

  /// No description provided for @explore_title.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore_title;

  /// No description provided for @explore_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search ..'**
  String get explore_search_hint;

  /// No description provided for @explore_items_title.
  ///
  /// In en, this message translates to:
  /// **'All activities'**
  String get explore_items_title;

  /// No description provided for @explore_empty_message.
  ///
  /// In en, this message translates to:
  /// **'No results found. Try another keyword.'**
  String get explore_empty_message;

  /// No description provided for @explore_category_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get explore_category_all;

  /// No description provided for @explore_results_label.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} =1{1 result} other{{count} results}}'**
  String explore_results_label(int count);

  /// No description provided for @explore_sort_relevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get explore_sort_relevance;

  /// No description provided for @explore_sort_price_low_high.
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get explore_sort_price_low_high;

  /// No description provided for @explore_sort_price_high_low.
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get explore_sort_price_high_low;

  /// No description provided for @explore_sort_date_soonest.
  ///
  /// In en, this message translates to:
  /// **'Soonest date'**
  String get explore_sort_date_soonest;

  /// No description provided for @profileMotto.
  ///
  /// In en, this message translates to:
  /// **'Live your hobby!'**
  String get profileMotto;

  /// No description provided for @profile_load_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile. Please try again.'**
  String get profile_load_error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage account'**
  String get manageAccount;

  /// No description provided for @profileMakePrivate.
  ///
  /// In en, this message translates to:
  /// **'Make profile private'**
  String get profileMakePrivate;

  /// No description provided for @profileMakePublic.
  ///
  /// In en, this message translates to:
  /// **'Make profile public'**
  String get profileMakePublic;

  /// No description provided for @setInactive.
  ///
  /// In en, this message translates to:
  /// **'Set account inactive'**
  String get setInactive;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get profileLogoutConfirm;

  /// No description provided for @deactivate_title.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get deactivate_title;

  /// No description provided for @deactivate_warning.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm deactivation.'**
  String get deactivate_warning;

  /// No description provided for @current_password_label.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get current_password_label;

  /// No description provided for @language_note.
  ///
  /// In en, this message translates to:
  /// **'Changing language will restart some screens.'**
  String get language_note;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your app content and settings.'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get adminProductsTitle;

  /// No description provided for @adminProductsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products yet. Tap + to add your first product.'**
  String get adminProductsEmpty;

  /// No description provided for @adminProductsNewArrivals.
  ///
  /// In en, this message translates to:
  /// **'New arrivals'**
  String get adminProductsNewArrivals;

  /// No description provided for @adminProductsBestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best sellers'**
  String get adminProductsBestSellers;

  /// No description provided for @adminProductsDiscounted.
  ///
  /// In en, this message translates to:
  /// **'Discounted products'**
  String get adminProductsDiscounted;

  /// No description provided for @adminProductsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get adminProductsSearchPlaceholder;

  /// No description provided for @accountInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is inactive'**
  String get accountInactiveTitle;

  /// No description provided for @accountInactiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is currently inactive. Do you want to reactivate it to continue?'**
  String get accountInactiveBody;

  /// No description provided for @reactivateButton.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get reactivateButton;

  /// No description provided for @accountReactivated.
  ///
  /// In en, this message translates to:
  /// **'Your account has been reactivated successfully'**
  String get accountReactivated;

  /// No description provided for @chooseSignInRole.
  ///
  /// In en, this message translates to:
  /// **'Choose how to sign in'**
  String get chooseSignInRole;

  /// No description provided for @enterAsOwner.
  ///
  /// In en, this message translates to:
  /// **'Enter as Owner (Admin)'**
  String get enterAsOwner;

  /// No description provided for @enterAsUser.
  ///
  /// In en, this message translates to:
  /// **'Enter as User'**
  String get enterAsUser;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @loginInactiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate your account?'**
  String get loginInactiveTitle;

  /// No description provided for @loginInactiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account \"{name}\" is currently inactive. Do you want to reactivate it and continue?'**
  String loginInactiveMessage(Object name);

  /// No description provided for @loginInactiveReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get loginInactiveReactivate;

  /// No description provided for @loginInactiveCancel.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get loginInactiveCancel;

  /// No description provided for @loginInactiveRequired.
  ///
  /// In en, this message translates to:
  /// **'You must reactivate your account to sign in as user.'**
  String get loginInactiveRequired;

  /// No description provided for @loginChooseRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how to sign in'**
  String get loginChooseRoleTitle;

  /// No description provided for @loginEnterAsOwner.
  ///
  /// In en, this message translates to:
  /// **'Enter as Owner (Admin)'**
  String get loginEnterAsOwner;

  /// No description provided for @loginEnterAsUser.
  ///
  /// In en, this message translates to:
  /// **'Enter as User'**
  String get loginEnterAsUser;

  /// No description provided for @loginRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get loginRoleLabel;

  /// No description provided for @loginUserFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get loginUserFallbackLabel;

  /// No description provided for @loginInactiveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been reactivated successfully.'**
  String get loginInactiveSuccess;

  /// No description provided for @productBadgeOnSale.
  ///
  /// In en, this message translates to:
  /// **'On sale'**
  String get productBadgeOnSale;

  /// No description provided for @productStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get productStatusDraft;

  /// No description provided for @productStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get productStatusActive;

  /// No description provided for @productStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get productStatusArchived;

  /// No description provided for @errorNetworkNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet or server unreachable.'**
  String get errorNetworkNoInternet;

  /// No description provided for @errorNetworkServerDown.
  ///
  /// In en, this message translates to:
  /// **'The server is not responding. Please try again later.'**
  String get errorNetworkServerDown;

  /// No description provided for @errorServerUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected server error. Please try again.'**
  String get errorServerUnexpected;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @errorAuthUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorAuthUnauthorized;

  /// No description provided for @errorAuthForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get errorAuthForbidden;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutLabel;

  /// No description provided for @adminDashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get adminDashboardQuickActions;

  /// No description provided for @adminOverviewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Overview & analytics'**
  String get adminOverviewAnalytics;

  /// No description provided for @adminProjectsOwners.
  ///
  /// In en, this message translates to:
  /// **'Projects & owners'**
  String get adminProjectsOwners;

  /// No description provided for @adminUsersManagers.
  ///
  /// In en, this message translates to:
  /// **'Users & managers'**
  String get adminUsersManagers;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminSettings;

  /// No description provided for @adminSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {role}'**
  String adminSignedInAs(Object role);

  /// No description provided for @adminProductCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create product'**
  String get adminProductCreateTitle;

  /// No description provided for @adminProductNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminProductNameLabel;

  /// No description provided for @adminProductNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: MacBook Pro'**
  String get adminProductNameHint;

  /// No description provided for @adminProductNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get adminProductNameRequired;

  /// No description provided for @adminProductDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminProductDescriptionLabel;

  /// No description provided for @adminProductDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Short description...'**
  String get adminProductDescriptionHint;

  /// No description provided for @adminProductPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get adminProductPriceLabel;

  /// No description provided for @adminProductPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get adminProductPriceRequired;

  /// No description provided for @adminProductPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than 0'**
  String get adminProductPriceInvalid;

  /// No description provided for @adminProductStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get adminProductStockLabel;

  /// No description provided for @adminProductStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminProductStatusLabel;

  /// No description provided for @adminProductImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get adminProductImageUrlLabel;

  /// No description provided for @adminProductSkuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get adminProductSkuLabel;

  /// No description provided for @adminProductTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Product type'**
  String get adminProductTypeLabel;

  /// No description provided for @adminProductTypeSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get adminProductTypeSimple;

  /// No description provided for @adminProductTypeVariable.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get adminProductTypeVariable;

  /// No description provided for @adminProductTypeGrouped.
  ///
  /// In en, this message translates to:
  /// **'Grouped'**
  String get adminProductTypeGrouped;

  /// No description provided for @adminProductTypeExternal.
  ///
  /// In en, this message translates to:
  /// **'External'**
  String get adminProductTypeExternal;

  /// No description provided for @adminProductVirtualLabel.
  ///
  /// In en, this message translates to:
  /// **'Virtual product'**
  String get adminProductVirtualLabel;

  /// No description provided for @adminProductDownloadableLabel.
  ///
  /// In en, this message translates to:
  /// **'Downloadable'**
  String get adminProductDownloadableLabel;

  /// No description provided for @adminProductDownloadUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Download URL'**
  String get adminProductDownloadUrlLabel;

  /// No description provided for @adminProductExternalUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'External URL'**
  String get adminProductExternalUrlLabel;

  /// No description provided for @adminProductButtonTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Button text'**
  String get adminProductButtonTextLabel;

  /// No description provided for @adminProductButtonTextHint.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get adminProductButtonTextHint;

  /// No description provided for @adminProductSaleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get adminProductSaleSectionTitle;

  /// No description provided for @adminProductSalePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale price'**
  String get adminProductSalePriceLabel;

  /// No description provided for @adminProductSaleStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale start date'**
  String get adminProductSaleStartLabel;

  /// No description provided for @adminProductSaleEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale end date'**
  String get adminProductSaleEndLabel;

  /// No description provided for @adminProductAttributesTitle.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get adminProductAttributesTitle;

  /// No description provided for @adminProductAttributeCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Attribute code'**
  String get adminProductAttributeCodeLabel;

  /// No description provided for @adminProductAttributeValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get adminProductAttributeValueLabel;

  /// No description provided for @adminProductAddAttribute.
  ///
  /// In en, this message translates to:
  /// **'Add attribute'**
  String get adminProductAddAttribute;

  /// No description provided for @adminProductEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get adminProductEditTitle;

  /// No description provided for @adminProductCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminProductCategoryLabel;

  /// No description provided for @adminProductItemTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Item type'**
  String get adminProductItemTypeLabel;

  /// No description provided for @adminStockHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: 50'**
  String get adminStockHint;

  /// No description provided for @adminProductImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get adminProductImageLabel;

  /// No description provided for @adminProductPickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick image'**
  String get adminProductPickImage;

  /// No description provided for @adminRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminRemove;

  /// No description provided for @adminProductSkuHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: SKU-123'**
  String get adminProductSkuHint;

  /// No description provided for @adminProductDownloadUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get adminProductDownloadUrlHint;

  /// No description provided for @adminProductExternalUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get adminProductExternalUrlHint;

  /// No description provided for @adminProductSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save product'**
  String get adminProductSaveButton;

  /// No description provided for @adminNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get adminNoCategories;

  /// No description provided for @adminCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get adminCreateCategory;

  /// No description provided for @adminNoItemTypes.
  ///
  /// In en, this message translates to:
  /// **'No item types found'**
  String get adminNoItemTypes;

  /// No description provided for @adminCreateItemType.
  ///
  /// In en, this message translates to:
  /// **'Create item type'**
  String get adminCreateItemType;

  /// No description provided for @adminTaxesTitle.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get adminTaxesTitle;

  /// No description provided for @adminTaxRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Rules'**
  String get adminTaxRulesTitle;

  /// No description provided for @adminTaxAddRule.
  ///
  /// In en, this message translates to:
  /// **'Add tax rule'**
  String get adminTaxAddRule;

  /// No description provided for @adminTaxNoRules.
  ///
  /// In en, this message translates to:
  /// **'No tax rules found.'**
  String get adminTaxNoRules;

  /// No description provided for @adminTaxCreateRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Tax Rule'**
  String get adminTaxCreateRuleTitle;

  /// No description provided for @adminTaxEditRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Tax Rule'**
  String get adminTaxEditRuleTitle;

  /// No description provided for @adminTaxRuleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Rule name'**
  String get adminTaxRuleNameLabel;

  /// No description provided for @adminTaxRuleNameHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Standard VAT 11%'**
  String get adminTaxRuleNameHint;

  /// No description provided for @adminTaxRuleNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Tax rule name is required'**
  String get adminTaxRuleNameRequired;

  /// No description provided for @adminTaxRuleRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate (%)'**
  String get adminTaxRuleRateLabel;

  /// No description provided for @adminTaxRuleRateHint.
  ///
  /// In en, this message translates to:
  /// **'11.00'**
  String get adminTaxRuleRateHint;

  /// No description provided for @adminTaxRuleRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Rate is required'**
  String get adminTaxRuleRateRequired;

  /// No description provided for @adminTaxRuleRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Rate must be a valid number > 0'**
  String get adminTaxRuleRateInvalid;

  /// No description provided for @adminTaxAppliesToShippingLabel.
  ///
  /// In en, this message translates to:
  /// **'Applies to shipping'**
  String get adminTaxAppliesToShippingLabel;

  /// No description provided for @adminTaxEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get adminTaxEnabledLabel;

  /// No description provided for @adminTaxCountryIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Country ID (optional)'**
  String get adminTaxCountryIdLabel;

  /// No description provided for @adminTaxCountryIdHint.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get adminTaxCountryIdHint;

  /// No description provided for @adminTaxRegionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Region ID (optional)'**
  String get adminTaxRegionIdLabel;

  /// No description provided for @adminTaxRegionIdHint.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get adminTaxRegionIdHint;

  /// No description provided for @adminTaxRateShort.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get adminTaxRateShort;

  /// No description provided for @adminTaxAppliesToShippingShort.
  ///
  /// In en, this message translates to:
  /// **'Shipping tax'**
  String get adminTaxAppliesToShippingShort;

  /// No description provided for @adminTaxEnabledShort.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get adminTaxEnabledShort;

  /// No description provided for @adminCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminCancel;

  /// No description provided for @adminCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get adminCreate;

  /// No description provided for @adminUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get adminUpdate;

  /// No description provided for @adminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEdit;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @adminSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get adminSessionExpired;

  /// No description provided for @adminTaxCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get adminTaxCountryLabel;

  /// No description provided for @adminTaxCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get adminTaxCountryHint;

  /// No description provided for @adminTaxRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get adminTaxRegionLabel;

  /// No description provided for @adminTaxSelectCountryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select country first'**
  String get adminTaxSelectCountryFirst;

  /// No description provided for @adminTaxRegionHint.
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get adminTaxRegionHint;

  /// No description provided for @adminTaxRulesTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Tax Rules'**
  String get adminTaxRulesTitleShort;

  /// No description provided for @adminTaxRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage tax rules for your products.'**
  String get adminTaxRulesSubtitle;

  /// No description provided for @taxPreviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Calculating tax preview...'**
  String get taxPreviewLoading;

  /// No description provided for @taxPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax Preview'**
  String get taxPreviewTitle;

  /// No description provided for @itemsTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Items Tax'**
  String get itemsTaxLabel;

  /// No description provided for @shippingTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping Tax'**
  String get shippingTaxLabel;

  /// No description provided for @totalTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Tax'**
  String get totalTaxLabel;

  /// No description provided for @taxClassNone.
  ///
  /// In en, this message translates to:
  /// **'No Tax'**
  String get taxClassNone;

  /// No description provided for @taxClassStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard Rate'**
  String get taxClassStandard;

  /// No description provided for @taxClassReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced Rate'**
  String get taxClassReduced;

  /// No description provided for @taxClassZero.
  ///
  /// In en, this message translates to:
  /// **'Zero Rate'**
  String get taxClassZero;

  /// No description provided for @taxClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Class'**
  String get taxClassLabel;

  /// No description provided for @taxClassHint.
  ///
  /// In en, this message translates to:
  /// **'Select tax class'**
  String get taxClassHint;

  /// No description provided for @adminTaxCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Country is required'**
  String get adminTaxCountryRequired;

  /// No description provided for @adminTaxRegionRequired.
  ///
  /// In en, this message translates to:
  /// **'Region is required'**
  String get adminTaxRegionRequired;

  /// No description provided for @adminTaxRulePresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Rule Preset'**
  String get adminTaxRulePresetLabel;

  /// No description provided for @adminTaxRulePresetHint.
  ///
  /// In en, this message translates to:
  /// **'Select a preset to auto-fill fields'**
  String get adminTaxRulePresetHint;

  /// No description provided for @adminCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get adminCustom;

  /// No description provided for @adminTaxAutoNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate name'**
  String get adminTaxAutoNameLabel;

  /// No description provided for @adminShippingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping Methods'**
  String get adminShippingTitle;

  /// No description provided for @adminShippingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add method'**
  String get adminShippingAdd;

  /// No description provided for @adminShippingNoMethods.
  ///
  /// In en, this message translates to:
  /// **'No shipping methods yet'**
  String get adminShippingNoMethods;

  /// No description provided for @adminShippingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create shipping method'**
  String get adminShippingCreateTitle;

  /// No description provided for @adminShippingEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit shipping method'**
  String get adminShippingEditTitle;

  /// No description provided for @adminShippingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminShippingNameLabel;

  /// No description provided for @adminShippingNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get adminShippingNameRequired;

  /// No description provided for @adminShippingDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminShippingDescLabel;

  /// No description provided for @adminShippingTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Method type'**
  String get adminShippingTypeLabel;

  /// No description provided for @adminShippingTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get adminShippingTypeHint;

  /// No description provided for @adminShippingFlatRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Flat rate'**
  String get adminShippingFlatRateLabel;

  /// No description provided for @adminShippingPerKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get adminShippingPerKgLabel;

  /// No description provided for @adminShippingThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Free shipping threshold'**
  String get adminShippingThresholdLabel;

  /// No description provided for @adminShippingCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get adminShippingCountryLabel;

  /// No description provided for @adminShippingCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get adminShippingCountryHint;

  /// No description provided for @adminShippingCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Country is required'**
  String get adminShippingCountryRequired;

  /// No description provided for @adminShippingRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get adminShippingRegionLabel;

  /// No description provided for @adminShippingRegionHint.
  ///
  /// In en, this message translates to:
  /// **'Select region (optional)'**
  String get adminShippingRegionHint;

  /// No description provided for @adminShippingSelectCountryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select country first'**
  String get adminShippingSelectCountryFirst;

  /// No description provided for @adminShippingEnabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get adminShippingEnabledLabel;

  /// No description provided for @adminShippingEnabledShort.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get adminShippingEnabledShort;

  /// No description provided for @adminShippingTypeShort.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminShippingTypeShort;

  /// No description provided for @shippingTypeFlatRate.
  ///
  /// In en, this message translates to:
  /// **'Flat rate'**
  String get shippingTypeFlatRate;

  /// No description provided for @shippingTypeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get shippingTypeFree;

  /// No description provided for @shippingTypeWeightBased.
  ///
  /// In en, this message translates to:
  /// **'Weight based'**
  String get shippingTypeWeightBased;

  /// No description provided for @shippingTypePriceBased.
  ///
  /// In en, this message translates to:
  /// **'Price based'**
  String get shippingTypePriceBased;

  /// No description provided for @shippingTypePricePerKg.
  ///
  /// In en, this message translates to:
  /// **'Price per kg'**
  String get shippingTypePricePerKg;

  /// No description provided for @shippingTypeLocalPickup.
  ///
  /// In en, this message translates to:
  /// **'Local pickup'**
  String get shippingTypeLocalPickup;

  /// No description provided for @shippingTypeFreeOverThreshold.
  ///
  /// In en, this message translates to:
  /// **'Free over threshold'**
  String get shippingTypeFreeOverThreshold;

  /// No description provided for @adminConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get adminConfirmDelete;

  /// No description provided for @adminShippingCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create method'**
  String get adminShippingCreateButton;

  /// No description provided for @adminDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get adminDeleted;

  /// No description provided for @refreshLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// No description provided for @adminEnabledOnly.
  ///
  /// In en, this message translates to:
  /// **'Enabled only'**
  String get adminEnabledOnly;

  /// No description provided for @adminShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get adminShowAll;

  /// No description provided for @adminDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled only'**
  String get adminDisabled;

  /// No description provided for @adminActive.
  ///
  /// In en, this message translates to:
  /// **'Active only'**
  String get adminActive;

  /// No description provided for @adminCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get adminCreated;

  /// No description provided for @adminUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get adminUpdated;

  /// No description provided for @adminHomeBannersTitle.
  ///
  /// In en, this message translates to:
  /// **'Home Banners'**
  String get adminHomeBannersTitle;

  /// No description provided for @adminHomeBannerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add banner'**
  String get adminHomeBannerAdd;

  /// No description provided for @adminHomeBannerNoBanners.
  ///
  /// In en, this message translates to:
  /// **'No banners yet'**
  String get adminHomeBannerNoBanners;

  /// No description provided for @adminHomeBannerCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create home banner'**
  String get adminHomeBannerCreateTitle;

  /// No description provided for @adminHomeBannerEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit home banner'**
  String get adminHomeBannerEditTitle;

  /// No description provided for @adminHomeBannerTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adminHomeBannerTitleLabel;

  /// No description provided for @adminHomeBannerSubtitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get adminHomeBannerSubtitleLabel;

  /// No description provided for @adminHomeBannerTargetTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Target type'**
  String get adminHomeBannerTargetTypeLabel;

  /// No description provided for @adminHomeBannerTargetIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Target ID'**
  String get adminHomeBannerTargetIdLabel;

  /// No description provided for @adminHomeBannerTargetUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Target URL'**
  String get adminHomeBannerTargetUrlLabel;

  /// No description provided for @adminHomeBannerSortOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get adminHomeBannerSortOrderLabel;

  /// No description provided for @adminHomeBannerActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminHomeBannerActiveLabel;

  /// No description provided for @adminImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Banner image'**
  String get adminImageLabel;

  /// No description provided for @adminChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get adminChooseFromGallery;

  /// No description provided for @adminTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get adminTakePhoto;

  /// No description provided for @adminRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminRemoveImage;

  /// No description provided for @adminImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Image is required'**
  String get adminImageRequired;

  /// No description provided for @adminTargetShort.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get adminTargetShort;

  /// No description provided for @adminSortShort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get adminSortShort;

  /// No description provided for @adminUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get adminUntitled;

  /// No description provided for @adminHomeBannerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit banner'**
  String get adminHomeBannerEdit;

  /// No description provided for @adminHomeBannerCreate.
  ///
  /// In en, this message translates to:
  /// **'Create banner'**
  String get adminHomeBannerCreate;

  /// No description provided for @adminHomeBannerImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Banner image'**
  String get adminHomeBannerImageLabel;

  /// No description provided for @adminHomeBannerImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Image is required'**
  String get adminHomeBannerImageRequired;

  /// No description provided for @adminPickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get adminPickFromGallery;

  /// No description provided for @adminPickFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get adminPickFromCamera;

  /// No description provided for @adminHomeBannerSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get adminHomeBannerSortLabel;

  /// No description provided for @adminHomeBannerLoadingTargets.
  ///
  /// In en, this message translates to:
  /// **'Loading targets...'**
  String get adminHomeBannerLoadingTargets;

  /// No description provided for @adminHomeBannerTargetTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select target type'**
  String get adminHomeBannerTargetTypeHint;

  /// No description provided for @adminHomeBannerTargetNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get adminHomeBannerTargetNone;

  /// No description provided for @adminHomeBannerTargetCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminHomeBannerTargetCategory;

  /// No description provided for @adminHomeBannerTargetProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get adminHomeBannerTargetProduct;

  /// No description provided for @adminHomeBannerTargetUrl.
  ///
  /// In en, this message translates to:
  /// **'External URL'**
  String get adminHomeBannerTargetUrl;

  /// No description provided for @adminHomeBannerUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get adminHomeBannerUrlRequired;

  /// No description provided for @adminHomeBannerTargetCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminHomeBannerTargetCategoryLabel;

  /// No description provided for @adminHomeBannerTargetCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get adminHomeBannerTargetCategoryHint;

  /// No description provided for @adminHomeBannerCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get adminHomeBannerCategoryRequired;

  /// No description provided for @adminHomeBannerTargetProductLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get adminHomeBannerTargetProductLabel;

  /// No description provided for @adminHomeBannerTargetProductHint.
  ///
  /// In en, this message translates to:
  /// **'Select product'**
  String get adminHomeBannerTargetProductHint;

  /// No description provided for @adminHomeBannerProductRequired.
  ///
  /// In en, this message translates to:
  /// **'Product is required'**
  String get adminHomeBannerProductRequired;

  /// No description provided for @adminActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminActiveLabel;

  /// No description provided for @adminNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No options'**
  String get adminNoOptions;

  /// No description provided for @noResultsLabel.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResultsLabel;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchLabel;

  /// No description provided for @adminProductsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get adminProductsSearchHint;

  /// No description provided for @adminProductsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All products'**
  String get adminProductsFilterAll;

  /// No description provided for @adminProductEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update product details'**
  String get adminProductEditSubtitle;

  /// No description provided for @adminProductCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new product'**
  String get adminProductCreateSubtitle;

  /// No description provided for @adminProductSectionBasicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get adminProductSectionBasicInfoTitle;

  /// No description provided for @adminProductSectionPricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get adminProductSectionPricingTitle;

  /// No description provided for @adminProductSectionBasicInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, description, type, SKU'**
  String get adminProductSectionBasicInfoSubtitle;

  /// No description provided for @adminProductSectionPricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Price, sale, stock'**
  String get adminProductSectionPricingSubtitle;

  /// No description provided for @adminProductSectionMetaTitle.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get adminProductSectionMetaTitle;

  /// No description provided for @adminProductSectionMetaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'SEO title & description'**
  String get adminProductSectionMetaSubtitle;

  /// No description provided for @adminSelectCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select category first'**
  String get adminSelectCategoryFirst;

  /// No description provided for @adminProductImageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get adminProductImageSectionTitle;

  /// No description provided for @adminProductImageSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload product image'**
  String get adminProductImageSectionSubtitle;

  /// No description provided for @adminProductSectionConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Product configuration'**
  String get adminProductSectionConfigTitle;

  /// No description provided for @adminProductSectionConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Virtual, downloadable, external'**
  String get adminProductSectionConfigSubtitle;

  /// No description provided for @adminProductSaleSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set sale price and duration'**
  String get adminProductSaleSectionSubtitle;

  /// No description provided for @adminProductAttributesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add custom attributes'**
  String get adminProductAttributesSubtitle;

  /// No description provided for @cart_title.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get cart_title;

  /// No description provided for @cart_empty_message.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty. Start adding items!'**
  String get cart_empty_message;

  /// No description provided for @cart_total_label.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get cart_total_label;

  /// No description provided for @cart_checkout_button.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get cart_checkout_button;

  /// No description provided for @cart_item_added.
  ///
  /// In en, this message translates to:
  /// **'Item added to cart'**
  String get cart_item_added;

  /// No description provided for @cart_item_removed.
  ///
  /// In en, this message translates to:
  /// **'Item removed from cart'**
  String get cart_item_removed;

  /// No description provided for @cart_clear_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the cart?'**
  String get cart_clear_confirmation;

  /// No description provided for @cart_item_quantity_label.
  ///
  /// In en, this message translates to:
  /// **'Quantity:'**
  String get cart_item_quantity_label;

  /// No description provided for @cart_item_updated.
  ///
  /// In en, this message translates to:
  /// **'Cart item updated'**
  String get cart_item_updated;

  /// No description provided for @cart_checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cart_checkout;

  /// No description provided for @cart_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get cart_clear;

  /// No description provided for @cart_empty_cta.
  ///
  /// In en, this message translates to:
  /// **'Browse Products'**
  String get cart_empty_cta;

  /// No description provided for @cart_cleared.
  ///
  /// In en, this message translates to:
  /// **'Cart has been cleared'**
  String get cart_cleared;

  /// No description provided for @adminProductNoAttributesHint.
  ///
  /// In en, this message translates to:
  /// **'No attributes added yet.'**
  String get adminProductNoAttributesHint;

  /// No description provided for @cart_add_button.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get cart_add_button;

  /// No description provided for @home_book_now_button.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get home_book_now_button;

  /// No description provided for @home_view_details_button.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get home_view_details_button;

  /// No description provided for @cart_login_required_title.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get cart_login_required_title;

  /// No description provided for @cart_login_required_message.
  ///
  /// In en, this message translates to:
  /// **'Please log in to proceed to checkout.'**
  String get cart_login_required_message;

  /// No description provided for @cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_button;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login_button;

  /// No description provided for @cart_item_added_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Item added to cart'**
  String get cart_item_added_snackbar;

  /// No description provided for @coupons_title.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get coupons_title;

  /// No description provided for @coupons_saved.
  ///
  /// In en, this message translates to:
  /// **'Coupon saved successfully'**
  String get coupons_saved;

  /// No description provided for @coupons_deleted.
  ///
  /// In en, this message translates to:
  /// **'Coupon deleted successfully'**
  String get coupons_deleted;

  /// No description provided for @coupons_empty.
  ///
  /// In en, this message translates to:
  /// **'No coupons yet. Create your first one!'**
  String get coupons_empty;

  /// No description provided for @coupons_type_percent.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get coupons_type_percent;

  /// No description provided for @coupons_type_fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount'**
  String get coupons_type_fixed;

  /// No description provided for @coupons_type_free_shipping.
  ///
  /// In en, this message translates to:
  /// **'Free shipping'**
  String get coupons_type_free_shipping;

  /// No description provided for @coupons_inactive_badge.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get coupons_inactive_badge;

  /// No description provided for @coupons_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete coupon'**
  String get coupons_delete_title;

  /// No description provided for @coupons_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete coupon {code}?'**
  String coupons_delete_confirm(Object code);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @coupons_add.
  ///
  /// In en, this message translates to:
  /// **'Add coupon'**
  String get coupons_add;

  /// No description provided for @coupons_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit coupon'**
  String get coupons_edit;

  /// No description provided for @coupons_code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get coupons_code;

  /// No description provided for @coupons_code_required.
  ///
  /// In en, this message translates to:
  /// **'Coupon code is required'**
  String get coupons_code_required;

  /// No description provided for @coupons_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get coupons_description;

  /// No description provided for @coupons_type.
  ///
  /// In en, this message translates to:
  /// **'Discount type'**
  String get coupons_type;

  /// No description provided for @coupons_value_percent.
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get coupons_value_percent;

  /// No description provided for @coupons_value_amount.
  ///
  /// In en, this message translates to:
  /// **'Discount amount'**
  String get coupons_value_amount;

  /// No description provided for @coupons_value_required.
  ///
  /// In en, this message translates to:
  /// **'Discount value is required'**
  String get coupons_value_required;

  /// No description provided for @coupons_value_invalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid discount value'**
  String get coupons_value_invalid;

  /// No description provided for @coupons_max_uses.
  ///
  /// In en, this message translates to:
  /// **'Max uses'**
  String get coupons_max_uses;

  /// No description provided for @coupons_min_order_amount.
  ///
  /// In en, this message translates to:
  /// **'Min order amount'**
  String get coupons_min_order_amount;

  /// No description provided for @coupons_max_discount_amount.
  ///
  /// In en, this message translates to:
  /// **'Max discount amount'**
  String get coupons_max_discount_amount;

  /// No description provided for @coupons_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get coupons_active;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @adminCouponsTitle.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get adminCouponsTitle;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading checkout…'**
  String get checkoutLoading;

  /// No description provided for @checkoutEmptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty.'**
  String get checkoutEmptyCart;

  /// No description provided for @checkoutGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get checkoutGoBack;

  /// No description provided for @checkoutItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get checkoutItemsTitle;

  /// No description provided for @checkoutAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get checkoutAddressTitle;

  /// No description provided for @checkoutCountryIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Country ID'**
  String get checkoutCountryIdLabel;

  /// No description provided for @checkoutCountryIdHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get checkoutCountryIdHint;

  /// No description provided for @checkoutRegionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Region ID'**
  String get checkoutRegionIdLabel;

  /// No description provided for @checkoutRegionIdHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get checkoutRegionIdHint;

  /// No description provided for @checkoutCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get checkoutCityLabel;

  /// No description provided for @checkoutCityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get checkoutCityHint;

  /// No description provided for @checkoutPostalCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get checkoutPostalCodeLabel;

  /// No description provided for @checkoutPostalCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get checkoutPostalCodeHint;

  /// No description provided for @checkoutApplyAddress.
  ///
  /// In en, this message translates to:
  /// **'Update shipping'**
  String get checkoutApplyAddress;

  /// No description provided for @checkoutCouponTitle.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get checkoutCouponTitle;

  /// No description provided for @checkoutCouponLabel.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get checkoutCouponLabel;

  /// No description provided for @checkoutCouponHint.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon (optional)'**
  String get checkoutCouponHint;

  /// No description provided for @checkoutShippingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get checkoutShippingTitle;

  /// No description provided for @checkoutNoShippingMethods.
  ///
  /// In en, this message translates to:
  /// **'No shipping methods found. Update address then refresh.'**
  String get checkoutNoShippingMethods;

  /// No description provided for @checkoutRefreshShipping.
  ///
  /// In en, this message translates to:
  /// **'Refresh shipping'**
  String get checkoutRefreshShipping;

  /// No description provided for @checkoutSelectShipping.
  ///
  /// In en, this message translates to:
  /// **'Please select a shipping method'**
  String get checkoutSelectShipping;

  /// No description provided for @checkoutPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get checkoutPaymentTitle;

  /// No description provided for @checkoutPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get checkoutPaymentCash;

  /// No description provided for @checkoutStripeNote.
  ///
  /// In en, this message translates to:
  /// **'Stripe requires payment confirmation (coming next).'**
  String get checkoutStripeNote;

  /// No description provided for @checkoutSelectPayment.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get checkoutSelectPayment;

  /// No description provided for @checkoutSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get checkoutSummaryTitle;

  /// No description provided for @checkoutSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get checkoutSubtotal;

  /// No description provided for @checkoutShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get checkoutShipping;

  /// No description provided for @checkoutTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get checkoutTax;

  /// No description provided for @checkoutTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get checkoutTotal;

  /// No description provided for @checkoutPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get checkoutPlaceOrder;

  /// No description provided for @orderSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummaryTitle;

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout'**
  String get secureCheckout;

  /// No description provided for @itemsSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Items subtotal'**
  String get itemsSubtotalLabel;

  /// No description provided for @shippingLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shippingLabel;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @taxesShippingNote.
  ///
  /// In en, this message translates to:
  /// **'Taxes and shipping are calculated based on your address.'**
  String get taxesShippingNote;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @noOptions.
  ///
  /// In en, this message translates to:
  /// **'No options'**
  String get noOptions;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @missingUserToken.
  ///
  /// In en, this message translates to:
  /// **'Missing user token'**
  String get missingUserToken;

  /// No description provided for @itemNumber.
  ///
  /// In en, this message translates to:
  /// **'Item #{id}'**
  String itemNumber(int id);

  /// No description provided for @qtyPriceLine.
  ///
  /// In en, this message translates to:
  /// **'x{qty} • {price}'**
  String qtyPriceLine(int qty, String price);

  /// No description provided for @checkoutOrderPlacedToast.
  ///
  /// In en, this message translates to:
  /// **'Order placed ✅ (# {orderId})'**
  String checkoutOrderPlacedToast(int orderId);

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String orderTitle(int orderId);

  /// No description provided for @orderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String orderDateLabel(String date);

  /// No description provided for @orderItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderItemsTitle;

  /// No description provided for @orderQtyUnitLine.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty} • Unit: {unit}'**
  String orderQtyUnitLine(int qty, String unit);

  /// No description provided for @grandTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotalLabel;

  /// No description provided for @downloadInvoicePdf.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice PDF'**
  String get downloadInvoicePdf;

  /// No description provided for @checkoutErrorCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get checkoutErrorCartEmpty;

  /// No description provided for @checkoutErrorSelectPayment.
  ///
  /// In en, this message translates to:
  /// **'Select a payment method'**
  String get checkoutErrorSelectPayment;

  /// No description provided for @checkoutErrorSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get checkoutErrorSelectCountry;

  /// No description provided for @checkoutErrorSelectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select a region'**
  String get checkoutErrorSelectRegion;

  /// No description provided for @checkoutErrorEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get checkoutErrorEnterCity;

  /// No description provided for @checkoutErrorEnterPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Enter postal code'**
  String get checkoutErrorEnterPostalCode;

  /// No description provided for @checkoutErrorSelectShipping.
  ///
  /// In en, this message translates to:
  /// **'Select a shipping method'**
  String get checkoutErrorSelectShipping;

  /// No description provided for @checkoutErrorShippingMissing.
  ///
  /// In en, this message translates to:
  /// **'Shipping method is missing'**
  String get checkoutErrorShippingMissing;

  /// No description provided for @checkoutErrorStripeNotReady.
  ///
  /// In en, this message translates to:
  /// **'Stripe not wired yet'**
  String get checkoutErrorStripeNotReady;

  /// No description provided for @commonDash.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get commonDash;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String orderDetailsTitle(Object orderId);

  /// No description provided for @orderDetailsDateLine.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String orderDetailsDateLine(Object date);

  /// No description provided for @orderDetailsItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderDetailsItemsTitle;

  /// No description provided for @orderDetailsItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item #{itemId}'**
  String orderDetailsItemFallback(Object itemId);

  /// No description provided for @orderDetailsQtyUnitLine.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}  •  Unit: {unitPrice}'**
  String orderDetailsQtyUnitLine(Object qty, Object unitPrice);

  /// No description provided for @orderDetailsSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get orderDetailsSubtotal;

  /// No description provided for @orderDetailsShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get orderDetailsShipping;

  /// No description provided for @orderDetailsTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get orderDetailsTax;

  /// No description provided for @orderDetailsCouponLine.
  ///
  /// In en, this message translates to:
  /// **'Coupon ({code})'**
  String orderDetailsCouponLine(Object code);

  /// No description provided for @orderDetailsGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get orderDetailsGrandTotal;

  /// No description provided for @orderDetailsDownloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice PDF'**
  String get orderDetailsDownloadInvoice;

  /// No description provided for @common_stock_label.
  ///
  /// In en, this message translates to:
  /// **'Stock: {stock}'**
  String common_stock_label(Object stock);

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get ordersTitle;

  /// No description provided for @ordersLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your orders...'**
  String get ordersLoading;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When you place an order, it will show up here.'**
  String get ordersEmptyBody;

  /// No description provided for @ordersReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get ordersReload;

  /// No description provided for @ordersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersFilterAll;

  /// No description provided for @ordersFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ordersFilterPending;

  /// No description provided for @ordersFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersFilterCompleted;

  /// No description provided for @ordersFilterCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get ordersFilterCanceled;

  /// No description provided for @ordersNoResultsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No orders match this filter.'**
  String get ordersNoResultsForFilter;

  /// No description provided for @ordersQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get ordersQtyLabel;

  /// No description provided for @ordersPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ordersPaid;

  /// No description provided for @ordersUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get ordersUnpaid;

  /// No description provided for @ordersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ordersStatusPending;

  /// No description provided for @ordersStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersStatusCompleted;

  /// No description provided for @ordersStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get ordersStatusCanceled;

  /// No description provided for @ordersStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get ordersStatusUnknown;

  /// No description provided for @ordersUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get ordersUnknownItem;

  /// No description provided for @ordersQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get ordersQty;

  /// No description provided for @profileLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your profile.'**
  String get profileLoginRequired;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile.'**
  String get profileLoadFailed;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get publicProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifications_empty_title;

  /// No description provided for @notifications_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'When something happens, it’ll show up here. For now… peace and quiet 😌'**
  String get notifications_empty_subtitle;

  /// No description provided for @notifications_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get notifications_retry;

  /// No description provided for @privacy_policy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy_title;

  /// No description provided for @privacy_policy_intro_title.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get privacy_policy_intro_title;

  /// No description provided for @privacy_policy_intro_body.
  ///
  /// In en, this message translates to:
  /// **'This policy explains what we collect, why we collect it, and how you control your data.'**
  String get privacy_policy_intro_body;

  /// No description provided for @privacy_policy_collect_title.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get privacy_policy_collect_title;

  /// No description provided for @privacy_policy_collect_body.
  ///
  /// In en, this message translates to:
  /// **'Basic profile info (name, email/phone), account settings, and app usage needed to provide the service.'**
  String get privacy_policy_collect_body;

  /// No description provided for @privacy_policy_use_title.
  ///
  /// In en, this message translates to:
  /// **'How we use your data'**
  String get privacy_policy_use_title;

  /// No description provided for @privacy_policy_use_body.
  ///
  /// In en, this message translates to:
  /// **'To run the app, personalize your experience, improve features, and keep the platform secure.'**
  String get privacy_policy_use_body;

  /// No description provided for @privacy_policy_share_title.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get privacy_policy_share_title;

  /// No description provided for @privacy_policy_share_body.
  ///
  /// In en, this message translates to:
  /// **'We don’t sell your data. We only share what’s needed with trusted services (like hosting) to operate the app.'**
  String get privacy_policy_share_body;

  /// No description provided for @privacy_policy_security_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get privacy_policy_security_title;

  /// No description provided for @privacy_policy_security_body.
  ///
  /// In en, this message translates to:
  /// **'We use standard security practices, but no system is 100% perfect. Keep your password private.'**
  String get privacy_policy_security_body;

  /// No description provided for @privacy_policy_choices_title.
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get privacy_policy_choices_title;

  /// No description provided for @privacy_policy_choices_body.
  ///
  /// In en, this message translates to:
  /// **'You can change visibility (public/private), update profile info, or request account actions based on the app features.'**
  String get privacy_policy_choices_body;

  /// No description provided for @privacy_policy_contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacy_policy_contact_title;

  /// No description provided for @privacy_policy_contact_body.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about privacy, contact the app support team.'**
  String get privacy_policy_contact_body;

  /// No description provided for @privacy_policy_last_updated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: Dec 19, 2025'**
  String get privacy_policy_last_updated;

  /// No description provided for @home_bottom_slide_thankyou_title.
  ///
  /// In en, this message translates to:
  /// **'THANK YOU'**
  String get home_bottom_slide_thankyou_title;

  /// No description provided for @home_bottom_slide_thankyou_message.
  ///
  /// In en, this message translates to:
  /// **'We appreciate your trust. Our team works daily to keep quality high and service fast.'**
  String get home_bottom_slide_thankyou_message;

  /// No description provided for @home_bottom_slide_secure_title.
  ///
  /// In en, this message translates to:
  /// **'SECURE & SAFE'**
  String get home_bottom_slide_secure_title;

  /// No description provided for @home_bottom_slide_secure_message.
  ///
  /// In en, this message translates to:
  /// **'Secure payments, controlled products, and clean packaging — the basics done right.'**
  String get home_bottom_slide_secure_message;

  /// No description provided for @home_bottom_slide_support_title.
  ///
  /// In en, this message translates to:
  /// **'REAL SUPPORT'**
  String get home_bottom_slide_support_title;

  /// No description provided for @home_bottom_slide_support_message.
  ///
  /// In en, this message translates to:
  /// **'Need help? We reply. No “seen” and disappear vibes 😅'**
  String get home_bottom_slide_support_message;

  /// No description provided for @home_bottom_benefit_contact.
  ///
  /// In en, this message translates to:
  /// **'CONTACT AN\nACCREDITED EXPERT'**
  String get home_bottom_benefit_contact;

  /// No description provided for @home_bottom_benefit_secure_payments.
  ///
  /// In en, this message translates to:
  /// **'SECURED\nPAYMENTS'**
  String get home_bottom_benefit_secure_payments;

  /// No description provided for @home_bottom_benefit_authentic_products.
  ///
  /// In en, this message translates to:
  /// **'AUTHENTIC &\nCONTROLLED PRODUCTS'**
  String get home_bottom_benefit_authentic_products;

  /// No description provided for @home_bottom_benefit_free_delivery_above.
  ///
  /// In en, this message translates to:
  /// **'FREE DELIVERY\nABOVE {amount}'**
  String home_bottom_benefit_free_delivery_above(String amount);

  /// No description provided for @home_trailing_limited_time.
  ///
  /// In en, this message translates to:
  /// **'Limited time'**
  String get home_trailing_limited_time;

  /// No description provided for @home_trailing_see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get home_trailing_see_all;

  /// No description provided for @home_sale_tag.
  ///
  /// In en, this message translates to:
  /// **'SALE'**
  String get home_sale_tag;

  /// No description provided for @home_stock_label.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String home_stock_label(int count);

  /// No description provided for @home_bookings_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Bookings feed not wired yet.'**
  String get home_bookings_placeholder;

  /// No description provided for @home_footer_contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get home_footer_contact_title;

  /// No description provided for @home_footer_contact_desc.
  ///
  /// In en, this message translates to:
  /// **'Need help? We’re one message away.'**
  String get home_footer_contact_desc;

  /// No description provided for @home_footer_free_delivery_title.
  ///
  /// In en, this message translates to:
  /// **'Free delivery'**
  String get home_footer_free_delivery_title;

  /// No description provided for @home_footer_free_delivery_desc.
  ///
  /// In en, this message translates to:
  /// **'Available on selected orders and areas.'**
  String get home_footer_free_delivery_desc;

  /// No description provided for @home_footer_returns_title.
  ///
  /// In en, this message translates to:
  /// **'Easy returns'**
  String get home_footer_returns_title;

  /// No description provided for @home_footer_returns_desc.
  ///
  /// In en, this message translates to:
  /// **'Simple return policy on eligible items.'**
  String get home_footer_returns_desc;

  /// No description provided for @ownerPaymentSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout Gateways'**
  String get ownerPaymentSettingsTitle;

  /// No description provided for @ownerPaymentSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'How your customers pay you'**
  String get ownerPaymentSettingsDesc;

  /// No description provided for @ownerPaymentConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get ownerPaymentConfigure;

  /// No description provided for @ownerPaymentIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get ownerPaymentIncomplete;

  /// No description provided for @ownerPaymentConfigHint.
  ///
  /// In en, this message translates to:
  /// **'Configure fields below. Required fields must be filled.'**
  String get ownerPaymentConfigHint;

  /// No description provided for @paymentMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout Gateways'**
  String get paymentMethodsTitle;

  /// No description provided for @paymentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get paymentSearchHint;

  /// No description provided for @paymentNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get paymentNoResults;

  /// No description provided for @paymentConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get paymentConfigure;

  /// No description provided for @paymentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get paymentCancel;

  /// No description provided for @paymentSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get paymentSave;

  /// No description provided for @paymentFillFields.
  ///
  /// In en, this message translates to:
  /// **'Fill the fields below, then Save.'**
  String get paymentFillFields;

  /// No description provided for @paymentSavedKeepHint.
  ///
  /// In en, this message translates to:
  /// **'Saved (leave empty to keep)'**
  String get paymentSavedKeepHint;

  /// No description provided for @paymentRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'• required'**
  String get paymentRequiredLabel;

  /// No description provided for @paymentIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get paymentIncomplete;

  /// No description provided for @adminPaymentConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout Gateways'**
  String get adminPaymentConfigTitle;

  /// No description provided for @checkoutConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm checkout'**
  String get checkoutConfirmDialogTitle;

  /// Warning shown before placing order: cart will be cleared after checkout.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue with checkout?'**
  String checkoutConfirmCartCleared(int itemCount);

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @adminOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get adminOrdersTitle;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get adminAllTime;

  /// No description provided for @adminLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get adminLast7Days;

  /// No description provided for @adminLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get adminLast30Days;

  /// No description provided for @adminClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get adminClear;

  /// No description provided for @adminKpiOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get adminKpiOrders;

  /// No description provided for @adminKpiGrossSales.
  ///
  /// In en, this message translates to:
  /// **'Gross Sales'**
  String get adminKpiGrossSales;

  /// No description provided for @adminKpiPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get adminKpiPaid;

  /// No description provided for @adminKpiOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get adminKpiOutstanding;

  /// No description provided for @adminKpiAvgOrder.
  ///
  /// In en, this message translates to:
  /// **'Avg Order'**
  String get adminKpiAvgOrder;

  /// No description provided for @adminFullyPaidPercent.
  ///
  /// In en, this message translates to:
  /// **'Fully paid: {percent}%'**
  String adminFullyPaidPercent(Object percent);

  /// No description provided for @adminPaidRevenueLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Paid revenue (last 7 days)'**
  String get adminPaidRevenueLast7Days;

  /// No description provided for @adminNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get adminNoOrders;

  /// No description provided for @adminNoOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing the status filter, date range, or pull to refresh.'**
  String get adminNoOrdersHint;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminOrderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String adminOrderDetailsTitle(Object id);

  /// No description provided for @adminOrderFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order.'**
  String get adminOrderFailedToLoad;

  /// No description provided for @adminPaymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get adminPaymentSummary;

  /// No description provided for @adminOrderInfo.
  ///
  /// In en, this message translates to:
  /// **'Order Info'**
  String get adminOrderInfo;

  /// No description provided for @adminStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminStatus;

  /// No description provided for @adminOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order Total'**
  String get adminOrderTotal;

  /// No description provided for @adminPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get adminPaid;

  /// No description provided for @adminRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get adminRemaining;

  /// No description provided for @adminPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get adminPaymentMethod;

  /// No description provided for @adminCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get adminCurrency;

  /// No description provided for @adminShippingCity.
  ///
  /// In en, this message translates to:
  /// **'Shipping City'**
  String get adminShippingCity;

  /// No description provided for @adminShippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get adminShippingMethod;

  /// No description provided for @adminCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get adminCoupon;

  /// No description provided for @adminItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items ({count})'**
  String adminItemsCount(Object count);

  /// No description provided for @adminCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get adminCustomer;

  /// No description provided for @adminQtyPriceLine.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}  •  Price: {price}'**
  String adminQtyPriceLine(Object qty, Object price);

  /// No description provided for @adminOrderCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String adminOrderCardTitle(Object id);

  /// No description provided for @adminItemsShort.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String adminItemsShort(Object count);

  /// No description provided for @adminPaidShort.
  ///
  /// In en, this message translates to:
  /// **'Paid: {amount}'**
  String adminPaidShort(Object amount);

  /// No description provided for @adminRemainingShort.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String adminRemainingShort(Object amount);

  /// No description provided for @adminFullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully paid'**
  String get adminFullyPaid;

  /// No description provided for @adminOrderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminOrderStatusPending;

  /// No description provided for @adminOrderStatusCancelRequested.
  ///
  /// In en, this message translates to:
  /// **'Cancel requested'**
  String get adminOrderStatusCancelRequested;

  /// No description provided for @adminOrderStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get adminOrderStatusCanceled;

  /// No description provided for @adminOrderStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminOrderStatusRejected;

  /// No description provided for @adminOrderStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get adminOrderStatusRefunded;

  /// No description provided for @adminOrderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get adminOrderStatusCompleted;

  /// No description provided for @adminMarkCashPaidBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this order as paid in cash?'**
  String get adminMarkCashPaidBody;

  /// No description provided for @adminMarkCashPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid in cash'**
  String get adminMarkCashPaid;

  /// No description provided for @adminMarkCashPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark order as paid'**
  String get adminMarkCashPaidTitle;

  /// No description provided for @adminMarkCashPaidButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get adminMarkCashPaidButton;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we’ll send you a code.'**
  String get forgotSubtitle;

  /// No description provided for @forgotSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get forgotSendCode;

  /// No description provided for @forgotTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: check spam/junk folder too 👀'**
  String get forgotTip;

  /// No description provided for @forgotVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get forgotVerifyTitle;

  /// No description provided for @forgotVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}'**
  String forgotVerifySubtitle(Object email);

  /// No description provided for @forgotNewPassTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get forgotNewPassTitle;

  /// No description provided for @forgotNewPassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make it strong — future you will thank you.'**
  String get forgotNewPassSubtitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @savePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePasswordButton;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel;

  /// No description provided for @codeTooShort.
  ///
  /// In en, this message translates to:
  /// **'Code is too short'**
  String get codeTooShort;

  /// No description provided for @verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @checkoutFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get checkoutFullNameLabel;

  /// No description provided for @checkoutFullNameHint.
  ///
  /// In en, this message translates to:
  /// **' your Name'**
  String get checkoutFullNameHint;

  /// No description provided for @checkoutAddressLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get checkoutAddressLineLabel;

  /// No description provided for @checkoutAddressLineHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Building, floor, street name'**
  String get checkoutAddressLineHint;

  /// No description provided for @checkoutPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get checkoutPhoneLabel;

  /// No description provided for @checkoutPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. +961 70 123 456'**
  String get checkoutPhoneHint;

  /// No description provided for @checkoutNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery notes (optional)'**
  String get checkoutNotesLabel;

  /// No description provided for @checkoutNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Call me when you arrive'**
  String get checkoutNotesHint;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCode;

  /// No description provided for @adminShippingTotal.
  ///
  /// In en, this message translates to:
  /// **'Shipping total'**
  String get adminShippingTotal;

  /// No description provided for @adminItemsTaxTotal.
  ///
  /// In en, this message translates to:
  /// **'Items tax total'**
  String get adminItemsTaxTotal;

  /// No description provided for @adminShippingTaxTotal.
  ///
  /// In en, this message translates to:
  /// **'Shipping tax total'**
  String get adminShippingTaxTotal;

  /// No description provided for @adminExcelImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Excel Import'**
  String get adminExcelImportTitle;

  /// No description provided for @adminExcelImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import data using an Excel template prepared by Build4All.'**
  String get adminExcelImportSubtitle;

  /// No description provided for @adminExcelPickBtn.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get adminExcelPickBtn;

  /// No description provided for @adminExcelFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected file'**
  String get adminExcelFileLabel;

  /// No description provided for @adminExcelNoFile.
  ///
  /// In en, this message translates to:
  /// **'No Excel file selected yet'**
  String get adminExcelNoFile;

  /// No description provided for @adminExcelValidateBtn.
  ///
  /// In en, this message translates to:
  /// **'Validate Excel'**
  String get adminExcelValidateBtn;

  /// No description provided for @adminExcelImportBtn.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get adminExcelImportBtn;

  /// No description provided for @adminExcelErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get adminExcelErrorsTitle;

  /// No description provided for @adminExcelWarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get adminExcelWarningsTitle;

  /// No description provided for @adminExcelReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace existing data'**
  String get adminExcelReplaceTitle;

  /// No description provided for @adminExcelReplaceHint.
  ///
  /// In en, this message translates to:
  /// **'If enabled, we delete existing tenant data before importing the new file.'**
  String get adminExcelReplaceHint;

  /// No description provided for @adminExcelReplaceScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace scope'**
  String get adminExcelReplaceScopeLabel;

  /// No description provided for @adminExcelProTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro tip'**
  String get adminExcelProTipTitle;

  /// No description provided for @adminExcelProTipBody.
  ///
  /// In en, this message translates to:
  /// **' Always validate the Excel file before importing to avoid partial or invalid data.'**
  String get adminExcelProTipBody;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @adminExcelDownloadTemplateBtn.
  ///
  /// In en, this message translates to:
  /// **'Download Excel Template'**
  String get adminExcelDownloadTemplateBtn;

  /// No description provided for @adminExcelTemplateDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Excel template downloaded'**
  String get adminExcelTemplateDownloaded;

  /// No description provided for @adminExcelTemplateReadyMsg.
  ///
  /// In en, this message translates to:
  /// **'Your Excel template is ready.'**
  String get adminExcelTemplateReadyMsg;

  /// No description provided for @adminExcelOpenTemplateBtn.
  ///
  /// In en, this message translates to:
  /// **'Open Template'**
  String get adminExcelOpenTemplateBtn;

  /// No description provided for @adminExcelShareTemplateBtn.
  ///
  /// In en, this message translates to:
  /// **'Share template'**
  String get adminExcelShareTemplateBtn;

  /// No description provided for @adminExcelShareTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Share the Excel template via email or other apps.'**
  String get adminExcelShareTemplateHint;

  /// No description provided for @adminExcelStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1 · Download Template'**
  String get adminExcelStep1Title;

  /// No description provided for @adminExcelStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Download the official Excel template, fill it, then upload it back.'**
  String get adminExcelStep1Subtitle;

  /// No description provided for @adminExcelTemplateSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Excel template downloaded successfully'**
  String get adminExcelTemplateSavedToast;

  /// No description provided for @adminExcelSavedLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get adminExcelSavedLocationTitle;

  /// No description provided for @adminExcelSavedLocationBody.
  ///
  /// In en, this message translates to:
  /// **'The Excel template has been saved locally on your device.'**
  String get adminExcelSavedLocationBody;

  /// No description provided for @adminExcelStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2 · Upload & Validate'**
  String get adminExcelStep2Title;

  /// No description provided for @adminExcelStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload the filled Excel file and validate its content.'**
  String get adminExcelStep2Subtitle;

  /// No description provided for @ai_chat_hint.
  ///
  /// In en, this message translates to:
  /// **'Ask about this item…'**
  String get ai_chat_hint;

  /// No description provided for @ai_chat_suggested_question.
  ///
  /// In en, this message translates to:
  /// **'Give me a quick summary and key details about this item.'**
  String get ai_chat_suggested_question;

  /// No description provided for @ai_chat_error_send_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get ai_chat_error_send_failed;

  /// No description provided for @ai_ask_button.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get ai_ask_button;

  /// No description provided for @common_sale_tag.
  ///
  /// In en, this message translates to:
  /// **'SALE'**
  String get common_sale_tag;

  /// No description provided for @common_description_title.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get common_description_title;

  /// No description provided for @common_attributes_title.
  ///
  /// In en, this message translates to:
  /// **'Attributes'**
  String get common_attributes_title;

  /// No description provided for @common_sku_label.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get common_sku_label;

  /// No description provided for @common_stock_label_plain.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get common_stock_label_plain;

  /// No description provided for @common_tax_label.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get common_tax_label;

  /// No description provided for @common_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @ai_prompt_summary.
  ///
  /// In en, this message translates to:
  /// **'Summarize this item'**
  String get ai_prompt_summary;

  /// No description provided for @ai_prompt_features.
  ///
  /// In en, this message translates to:
  /// **'What are the main features?'**
  String get ai_prompt_features;

  /// No description provided for @ai_prompt_best_use.
  ///
  /// In en, this message translates to:
  /// **'Is this good for me?'**
  String get ai_prompt_best_use;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out Of Stock'**
  String get outOfStock;

  /// No description provided for @authUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already in use.'**
  String get authUsernameTaken;

  /// No description provided for @authEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authEmailAlreadyExists;

  /// No description provided for @authPhoneAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered.'**
  String get authPhoneAlreadyExists;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this email/phone.'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get authWrongPassword;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email/phone or password.'**
  String get authInvalidCredentials;

  /// No description provided for @authAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'Your account is inactive. Reactivate to continue.'**
  String get authAccountInactive;

  /// No description provided for @httpValidationError.
  ///
  /// In en, this message translates to:
  /// **'Some fields are invalid.'**
  String get httpValidationError;

  /// No description provided for @httpConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict. Please retry.'**
  String get httpConflict;

  /// No description provided for @httpUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized.'**
  String get httpUnauthorized;

  /// No description provided for @httpForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permission to do this.'**
  String get httpForbidden;

  /// No description provided for @httpNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get httpNotFound;

  /// No description provided for @httpServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try later.'**
  String get httpServerError;

  /// No description provided for @networkNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get networkNoInternet;

  /// No description provided for @networkTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out.'**
  String get networkTimeout;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error.'**
  String get networkError;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @adminMissingAdminToken.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get adminMissingAdminToken;

  /// No description provided for @adminGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get adminGenericError;

  /// No description provided for @adminCategoryFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminCategoryFallbackName;

  /// No description provided for @adminItemTypeFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Item type'**
  String get adminItemTypeFallbackName;

  /// No description provided for @adminDeleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get adminDeleteCategoryTitle;

  /// No description provided for @adminDeleteCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?\n\nThis may also delete its item types (depending on backend rules).'**
  String adminDeleteCategoryMessage(String name);

  /// No description provided for @adminDeleteItemTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item type?'**
  String get adminDeleteItemTypeTitle;

  /// No description provided for @adminDeleteItemTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String adminDeleteItemTypeMessage(String name);

  /// No description provided for @adminDeleteCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get adminDeleteCategoryTooltip;

  /// No description provided for @adminDeleteItemTypeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete item type'**
  String get adminDeleteItemTypeTooltip;

  /// No description provided for @adminNewCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get adminNewCategoryTitle;

  /// No description provided for @adminNewCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Laptops'**
  String get adminNewCategoryHint;

  /// No description provided for @adminNewItemTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'New item type'**
  String get adminNewItemTypeTitle;

  /// No description provided for @adminNewItemTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Laptop'**
  String get adminNewItemTypeHint;

  /// No description provided for @adminSelectCategoryBeforeCreateItemType.
  ///
  /// In en, this message translates to:
  /// **'Please select a category before creating an item type.'**
  String get adminSelectCategoryBeforeCreateItemType;

  /// No description provided for @adminSelectCategoryBeforeSavingProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a category before saving.'**
  String get adminSelectCategoryBeforeSavingProduct;

  /// No description provided for @adminMissingCurrencyConfig.
  ///
  /// In en, this message translates to:
  /// **'Currency is missing for this app. Configure currency first.'**
  String get adminMissingCurrencyConfig;

  /// No description provided for @adminButtonTextDefaultAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get adminButtonTextDefaultAddToCart;

  /// No description provided for @adminPriceExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 120.00'**
  String get adminPriceExampleHint;

  /// No description provided for @commonDateFormatHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get commonDateFormatHint;

  /// No description provided for @adminAttributeValueExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Samsung'**
  String get adminAttributeValueExampleHint;

  /// No description provided for @adminProductAttributeValueHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Samsung'**
  String get adminProductAttributeValueHint;

  /// No description provided for @adminDashboardHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboardHeroTitle;

  /// No description provided for @adminDashboardAup.
  ///
  /// In en, this message translates to:
  /// **'AUP {id}'**
  String adminDashboardAup(Object id);

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @sendRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequestLabel;

  /// No description provided for @upgradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeLabel;

  /// No description provided for @requestUpgradeLabel.
  ///
  /// In en, this message translates to:
  /// **'Request upgrade'**
  String get requestUpgradeLabel;

  /// No description provided for @licenseChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking license…'**
  String get licenseChecking;

  /// No description provided for @licenseAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Access granted '**
  String get licenseAccessGranted;

  /// No description provided for @licenseAccessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Access blocked'**
  String get licenseAccessBlocked;

  /// No description provided for @licenseLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Limit reached: {active}/{allowed} users'**
  String licenseLimitReached(Object active, Object allowed);

  /// No description provided for @adminDashboardStatusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking plan…'**
  String get adminDashboardStatusChecking;

  /// No description provided for @adminDashboardStatusLicenseFailed.
  ///
  /// In en, this message translates to:
  /// **'License check failed'**
  String get adminDashboardStatusLicenseFailed;

  /// No description provided for @adminDashboardStatusLimitReached.
  ///
  /// In en, this message translates to:
  /// **'User limit reached — upgrade required'**
  String get adminDashboardStatusLimitReached;

  /// No description provided for @adminDashboardStatusAccessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Access blocked'**
  String get adminDashboardStatusAccessBlocked;

  /// No description provided for @adminDashboardStatusOk.
  ///
  /// In en, this message translates to:
  /// **'All systems go '**
  String get adminDashboardStatusOk;

  /// No description provided for @adminDashboardActionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} actions'**
  String adminDashboardActionsCount(Object count);

  /// No description provided for @upgradeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade request'**
  String get upgradeSheetTitle;

  /// No description provided for @upgradeSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to send a request.'**
  String get upgradeSheetSubtitle;

  /// No description provided for @noUpgradeAvailable.
  ///
  /// In en, this message translates to:
  /// **'No upgrade available.'**
  String get noUpgradeAvailable;

  /// No description provided for @upgradeRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent '**
  String get upgradeRequestSent;

  /// No description provided for @planGeneric.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planGeneric;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planProHostedDb.
  ///
  /// In en, this message translates to:
  /// **'Pro Hosted DB'**
  String get planProHostedDb;

  /// No description provided for @planDedicated.
  ///
  /// In en, this message translates to:
  /// **'Dedicated'**
  String get planDedicated;

  /// No description provided for @planProHostedDbDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited users (hosted by Build4All)'**
  String get planProHostedDbDesc;

  /// No description provided for @planDedicatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Dedicated server (needs setup/assignment)'**
  String get planDedicatedDesc;

  /// No description provided for @adminActionProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog & pricing'**
  String get adminActionProductsSubtitle;

  /// No description provided for @adminActionShippingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Methods & fees'**
  String get adminActionShippingSubtitle;

  /// No description provided for @adminActionPaymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stripe & setup'**
  String get adminActionPaymentSubtitle;

  /// No description provided for @adminActionTaxesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tax rules'**
  String get adminActionTaxesSubtitle;

  /// No description provided for @adminActionBannersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Homepage banners'**
  String get adminActionBannersSubtitle;

  /// No description provided for @adminActionCouponsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discount codes'**
  String get adminActionCouponsSubtitle;

  /// No description provided for @adminActionOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage & track'**
  String get adminActionOrdersSubtitle;

  /// No description provided for @adminActionExcelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk import'**
  String get adminActionExcelSubtitle;

  /// No description provided for @adminProfileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile…'**
  String get adminProfileLoading;

  /// No description provided for @adminMyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get adminMyProfileTitle;

  /// No description provided for @adminMyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {role}'**
  String adminMyProfileSubtitle(Object role);

  /// No description provided for @manageProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageProfileLabel;

  /// No description provided for @aupIdLabel.
  ///
  /// In en, this message translates to:
  /// **'AUP ID'**
  String get aupIdLabel;

  /// No description provided for @businessIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Business ID'**
  String get businessIdLabel;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @adminIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin ID'**
  String get adminIdLabel;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @copiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied '**
  String get copiedLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @createdAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAtLabel;

  /// No description provided for @updatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated at'**
  String get updatedAtLabel;

  /// No description provided for @adminProductSaleDatesBothRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select both sale start and sale end dates.'**
  String get adminProductSaleDatesBothRequired;

  /// No description provided for @adminProductSaleEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Sale end date must be after the sale start date.'**
  String get adminProductSaleEndBeforeStart;

  /// No description provided for @adminProductSaleStartInPast.
  ///
  /// In en, this message translates to:
  /// **'Sale start date cannot be in the past.'**
  String get adminProductSaleStartInPast;

  /// No description provided for @adminProductSaleEndInPast.
  ///
  /// In en, this message translates to:
  /// **'Sale end date cannot be in the past.'**
  String get adminProductSaleEndInPast;

  /// No description provided for @adminProductSalePriceRequiredForDates.
  ///
  /// In en, this message translates to:
  /// **'Please enter a sale price when sale dates are set.'**
  String get adminProductSalePriceRequiredForDates;

  /// No description provided for @adminProductSalePriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Sale price must be a valid number greater than 0.'**
  String get adminProductSalePriceInvalid;

  /// No description provided for @adminProductSalePriceMustBeLess.
  ///
  /// In en, this message translates to:
  /// **'Sale price must be less than the regular price.'**
  String get adminProductSalePriceMustBeLess;

  /// No description provided for @adminProductSaleEndAutoCleared.
  ///
  /// In en, this message translates to:
  /// **'Sale end date was cleared because it was before the start date.'**
  String get adminProductSaleEndAutoCleared;

  /// No description provided for @forbiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permission to do this.'**
  String get forbiddenLabel;

  /// No description provided for @notFoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get notFoundLabel;

  /// No description provided for @serverErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverErrorLabel;

  /// No description provided for @networkErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get networkErrorLabel;

  /// No description provided for @errPasswordLen6to8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errPasswordLen6to8;

  /// No description provided for @errPasswordNeedSpecial.
  ///
  /// In en, this message translates to:
  /// **'Password must include at least 1 special character (e.g. !@#).'**
  String get errPasswordNeedSpecial;

  /// No description provided for @hintPasswordRuleOwner.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get hintPasswordRuleOwner;

  /// No description provided for @msgProductDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully.'**
  String get msgProductDeleted;

  /// No description provided for @adminProductDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product'**
  String get adminProductDeleteDialogTitle;

  /// No description provided for @adminProductDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String adminProductDeleteDialogBody(Object name);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @adminProductDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully.'**
  String get adminProductDeleteSuccess;

  /// No description provided for @adminProductDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product.'**
  String get adminProductDeleteFailed;

  /// No description provided for @adminProductDeleteBlockedCart.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this product because it’s currently in customers’ carts. '**
  String get adminProductDeleteBlockedCart;

  /// No description provided for @adminProductDeleteBlockedOrders.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this product because it’s linked to existing orders. '**
  String get adminProductDeleteBlockedOrders;

  /// No description provided for @adminProductDeleteBlockedGeneric.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this product because it’s linked to other records (orders or carts). '**
  String get adminProductDeleteBlockedGeneric;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get errSessionExpired;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permission to perform this action.'**
  String get errForbidden;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errNotFound;

  /// No description provided for @adminProductsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products.\n{details}'**
  String adminProductsLoadFailed(Object details);

  /// No description provided for @adminProductsCountPill.
  ///
  /// In en, this message translates to:
  /// **'{filtered} / {total}'**
  String adminProductsCountPill(Object filtered, Object total);

  /// No description provided for @adminCategoryDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully.'**
  String get adminCategoryDeleteSuccess;

  /// No description provided for @adminItemTypeDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Item type deleted successfully.'**
  String get adminItemTypeDeleteSuccess;

  /// No description provided for @adminCategoryDeleteBlockedItems.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this category because it’s used by {count} item(s).'**
  String adminCategoryDeleteBlockedItems(Object count);

  /// No description provided for @adminItemTypeDeleteBlockedItems.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this item type because it’s used by {count} item(s).'**
  String adminItemTypeDeleteBlockedItems(Object count);

  /// No description provided for @adminCategoryDeleteBlockedGeneric.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this category because it’s still being used.'**
  String get adminCategoryDeleteBlockedGeneric;

  /// No description provided for @adminItemTypeDeleteBlockedGeneric.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this item type because it’s still being used.'**
  String get adminItemTypeDeleteBlockedGeneric;

  /// No description provided for @adminConflictGeneric.
  ///
  /// In en, this message translates to:
  /// **'This action can’t be completed right now.'**
  String get adminConflictGeneric;

  /// No description provided for @adminCategoryDeleteBlockedTypes.
  ///
  /// In en, this message translates to:
  /// **'You can’t delete this category because it still has {count} item type(s). Delete/move the types first.'**
  String adminCategoryDeleteBlockedTypes(Object count);

  /// No description provided for @adminRejectOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject order?'**
  String get adminRejectOrderTitle;

  /// No description provided for @adminRejectOrderBody.
  ///
  /// In en, this message translates to:
  /// **'This will mark the order as rejected. Continue?'**
  String get adminRejectOrderBody;

  /// No description provided for @adminRejectOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get adminRejectOrderButton;

  /// No description provided for @authGateContinueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as…'**
  String get authGateContinueAs;

  /// No description provided for @authGateRoleAdminOwner.
  ///
  /// In en, this message translates to:
  /// **'Admin / Owner'**
  String get authGateRoleAdminOwner;

  /// No description provided for @authGateRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get authGateRoleUser;

  /// No description provided for @appAccessTitleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Access Removed'**
  String get appAccessTitleDeleted;

  /// No description provided for @appAccessTitleExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Expired'**
  String get appAccessTitleExpired;

  /// No description provided for @appAccessTitleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App Unavailable'**
  String get appAccessTitleUnavailable;

  /// No description provided for @appAccessMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'This app is no longer available.'**
  String get appAccessMessageDeleted;

  /// No description provided for @appAccessMessageExpired.
  ///
  /// In en, this message translates to:
  /// **'This app subscription has expired.'**
  String get appAccessMessageExpired;

  /// No description provided for @appAccessMessageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You no longer have access to this app.'**
  String get appAccessMessageUnavailable;

  /// No description provided for @appAccessOwnerDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'This app has been disabled by the owner or is no longer active.'**
  String get appAccessOwnerDisabledHint;

  /// No description provided for @appAccessRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get appAccessRetry;

  /// No description provided for @appAccessBlockedButton.
  ///
  /// In en, this message translates to:
  /// **'Access blocked'**
  String get appAccessBlockedButton;

  /// No description provided for @pasteButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get pasteButtonLabel;

  /// No description provided for @codeReadyToVerifyHint.
  ///
  /// In en, this message translates to:
  /// **'Code ready to verify'**
  String get codeReadyToVerifyHint;

  /// No description provided for @enterSixDigitCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit verification code'**
  String get enterSixDigitCodeHint;

  /// No description provided for @accountAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Account already verified. Please log in.'**
  String get accountAlreadyVerified;

  /// No description provided for @ordersDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String ordersDetailsTitle(Object orderId);

  /// No description provided for @ordersDetailsItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get ordersDetailsItemsTitle;

  /// No description provided for @ordersDetailsQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get ordersDetailsQty;

  /// No description provided for @ordersDetailsUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get ordersDetailsUnit;

  /// No description provided for @ordersDetailsLineTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get ordersDetailsLineTotal;

  /// No description provided for @ordersDetailsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ordersDetailsStatus;

  /// No description provided for @ordersDetailsOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order Total'**
  String get ordersDetailsOrderTotal;

  /// No description provided for @ordersDetailsPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get ordersDetailsPayment;

  /// No description provided for @ordersDetailsPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ordersDetailsPaidAmount;

  /// No description provided for @ordersDetailsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get ordersDetailsRemaining;

  /// No description provided for @editProfile_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfile_emailLabel;

  /// No description provided for @editProfile_invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get editProfile_invalidEmail;

  /// No description provided for @editProfile_usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Username contains invalid characters'**
  String get editProfile_usernameInvalid;

  /// No description provided for @editProfile_codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to:'**
  String get editProfile_codeSentTo;

  /// No description provided for @editProfile_verifyNewEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify new email'**
  String get editProfile_verifyNewEmailTitle;

  /// No description provided for @editProfile_codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get editProfile_codeLabel;

  /// No description provided for @editProfile_codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code required'**
  String get editProfile_codeRequired;

  /// No description provided for @editProfile_resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get editProfile_resend;

  /// No description provided for @editProfile_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get editProfile_verify;

  /// No description provided for @editProfile_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get editProfile_change;

  /// No description provided for @editProfile_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get editProfile_remove;

  /// No description provided for @editProfile_codeSentToast.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your new email'**
  String get editProfile_codeSentToast;

  /// No description provided for @editProfile_emailUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Email updated successfully'**
  String get editProfile_emailUpdatedToast;

  /// No description provided for @home_stock_left_label.
  ///
  /// In en, this message translates to:
  /// **'Only {count} left'**
  String home_stock_left_label(int count);

  /// No description provided for @editProfile_firstNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'First name contains invalid characters'**
  String get editProfile_firstNameInvalid;

  /// No description provided for @editProfile_lastNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Last name contains invalid characters'**
  String get editProfile_lastNameInvalid;

  /// No description provided for @licenseDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'License details'**
  String get licenseDetailsTitle;

  /// No description provided for @licensePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get licensePlanLabel;

  /// No description provided for @licensePlanCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan code'**
  String get licensePlanCodeLabel;

  /// No description provided for @licenseStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get licenseStatusLabel;

  /// No description provided for @licensePeriodEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Period end'**
  String get licensePeriodEndLabel;

  /// No description provided for @licenseDaysLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get licenseDaysLeftLabel;

  /// No description provided for @licenseUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get licenseUsersLabel;

  /// No description provided for @licenseUsersRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Users remaining'**
  String get licenseUsersRemainingLabel;

  /// No description provided for @licenseRequiresDedicatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Requires dedicated'**
  String get licenseRequiresDedicatedLabel;

  /// No description provided for @licenseDedicatedInfraReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Dedicated infra ready'**
  String get licenseDedicatedInfraReadyLabel;

  /// No description provided for @licenseBlockingReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocking reason'**
  String get licenseBlockingReasonLabel;

  /// No description provided for @upgradeRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Upgrade request is pending approval'**
  String get upgradeRequestPending;

  /// No description provided for @payNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNowLabel;

  /// No description provided for @billingCycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingCycleMonthly;

  /// No description provided for @billingCycleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get billingCycleYearly;

  /// No description provided for @upgradeBillingCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'BILLING CYCLE'**
  String get upgradeBillingCycleLabel;

  /// No description provided for @upgradePaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get upgradePaymentMethodLabel;

  /// No description provided for @upgradeNoPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'No payment method is currently available. Please contact support.'**
  String get upgradeNoPaymentMethods;

  /// No description provided for @upgradePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'PRICE'**
  String get upgradePriceLabel;

  /// No description provided for @perMonthSuffix.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get perMonthSuffix;

  /// No description provided for @perYearSuffix.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get perYearSuffix;

  /// No description provided for @upgradeYearlyDiscountBadge.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get upgradeYearlyDiscountBadge;

  /// No description provided for @upgradePlansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load upgrade plans.'**
  String get upgradePlansLoadError;

  /// No description provided for @upgradePaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful. Your plan has been upgraded.'**
  String get upgradePaymentSuccess;

  /// No description provided for @upgradePaymentCanceled.
  ///
  /// In en, this message translates to:
  /// **'Payment was canceled.'**
  String get upgradePaymentCanceled;

  /// No description provided for @upgradePaymentMissingConfig.
  ///
  /// In en, this message translates to:
  /// **'Payment configuration is missing.'**
  String get upgradePaymentMissingConfig;

  /// No description provided for @upgradePaymentUnsupportedProvider.
  ///
  /// In en, this message translates to:
  /// **'Payment provider is not supported yet.'**
  String get upgradePaymentUnsupportedProvider;

  /// No description provided for @requestUpgradePendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requestUpgradePendingLabel;

  /// No description provided for @upgradeRequestStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Upgrade request status'**
  String get upgradeRequestStatusLabel;

  /// No description provided for @upgradeRequestPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested plan'**
  String get upgradeRequestPlanLabel;

  /// No description provided for @upgradeRequestAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested at'**
  String get upgradeRequestAtLabel;

  /// No description provided for @upgradeRequestNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision note'**
  String get upgradeRequestNoteLabel;

  /// No description provided for @upgradeStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get upgradeStatusPending;

  /// No description provided for @upgradeStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get upgradeStatusApproved;

  /// No description provided for @upgradeStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get upgradeStatusRejected;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @checkoutCouponChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking coupon…'**
  String get checkoutCouponChecking;

  /// No description provided for @checkoutCouponApplied.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied'**
  String get checkoutCouponApplied;

  /// No description provided for @checkoutCouponAppliedDiscount.
  ///
  /// In en, this message translates to:
  /// **'Applied • -{discount}'**
  String checkoutCouponAppliedDiscount(String discount);

  /// No description provided for @checkoutCouponInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon'**
  String get checkoutCouponInvalid;

  /// No description provided for @checkoutCouponFailed.
  ///
  /// In en, this message translates to:
  /// **'Coupon could not be applied.'**
  String get checkoutCouponFailed;

  /// No description provided for @checkoutOrderPlacedWithCode.
  ///
  /// In en, this message translates to:
  /// **'Order placed: {code}'**
  String checkoutOrderPlacedWithCode(String code);

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @checkoutCartEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get checkoutCartEmptyError;

  /// No description provided for @checkoutPaymentMissingCode.
  ///
  /// In en, this message translates to:
  /// **'Payment method code is missing'**
  String get checkoutPaymentMissingCode;

  /// No description provided for @checkoutCountryRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get checkoutCountryRequiredError;

  /// No description provided for @checkoutRegionRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Select a region'**
  String get checkoutRegionRequiredError;

  /// No description provided for @checkoutCityRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get checkoutCityRequiredError;

  /// No description provided for @checkoutAddressRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get checkoutAddressRequiredError;

  /// No description provided for @checkoutPhoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter phone'**
  String get checkoutPhoneRequiredError;

  /// No description provided for @checkoutShippingMissingError.
  ///
  /// In en, this message translates to:
  /// **'Shipping method is missing'**
  String get checkoutShippingMissingError;

  /// No description provided for @checkoutStripeCanceled.
  ///
  /// In en, this message translates to:
  /// **'Payment canceled'**
  String get checkoutStripeCanceled;

  /// No description provided for @checkoutStripeClientSecretMissing.
  ///
  /// In en, this message translates to:
  /// **'Checkout did not return Stripe client secret'**
  String get checkoutStripeClientSecretMissing;

  /// No description provided for @checkoutStripePublishableKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Checkout did not return Stripe publishable key'**
  String get checkoutStripePublishableKeyMissing;

  /// No description provided for @home_support_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get home_support_sheet_title;

  /// No description provided for @home_support_option_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get home_support_option_whatsapp;

  /// No description provided for @home_support_option_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get home_support_option_email;

  /// No description provided for @home_support_not_configured.
  ///
  /// In en, this message translates to:
  /// **'Support contact details are not configured.'**
  String get home_support_not_configured;

  /// No description provided for @home_support_email_not_configured.
  ///
  /// In en, this message translates to:
  /// **'Support email is not configured.'**
  String get home_support_email_not_configured;

  /// No description provided for @home_support_phone_not_configured.
  ///
  /// In en, this message translates to:
  /// **'Support phone number is not configured.'**
  String get home_support_phone_not_configured;

  /// No description provided for @home_support_open_email_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app.'**
  String get home_support_open_email_failed;

  /// No description provided for @home_support_open_whatsapp_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get home_support_open_whatsapp_failed;

  /// No description provided for @home_support_invalid_phone.
  ///
  /// In en, this message translates to:
  /// **'Invalid support number.'**
  String get home_support_invalid_phone;

  /// No description provided for @checkoutBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout blocked'**
  String get checkoutBlockedTitle;

  /// No description provided for @adminTaxRuleRateMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Rate must be 0 or more'**
  String get adminTaxRuleRateMustBePositive;

  /// No description provided for @adminTaxRuleRateTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Rate cannot be greater than 100%'**
  String get adminTaxRuleRateTooHigh;

  /// No description provided for @checkoutCouponExpired.
  ///
  /// In en, this message translates to:
  /// **'Coupon expired.'**
  String get checkoutCouponExpired;

  /// No description provided for @checkoutCouponUsageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Coupon usage limit reached.'**
  String get checkoutCouponUsageLimitReached;

  /// No description provided for @checkoutCouponMinimumNotReached.
  ///
  /// In en, this message translates to:
  /// **'Minimum order amount not reached for this coupon.'**
  String get checkoutCouponMinimumNotReached;

  /// No description provided for @checkoutCouponDidNotAffectOrder.
  ///
  /// In en, this message translates to:
  /// **'Coupon did not affect this order.'**
  String get checkoutCouponDidNotAffectOrder;

  /// No description provided for @adminProductStatusSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Product status'**
  String get adminProductStatusSectionTitle;

  /// No description provided for @adminProductStatusSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control product visibility and lifecycle'**
  String get adminProductStatusSectionSubtitle;

  /// No description provided for @adminProductStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No statuses available'**
  String get adminProductStatusUnavailable;

  /// No description provided for @adminProductStatusRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a product status'**
  String get adminProductStatusRequired;

  /// No description provided for @home_coming_soon_button.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get home_coming_soon_button;

  /// No description provided for @connection_reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connection_reconnecting;

  /// No description provided for @adminProductSectionSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale settings'**
  String get adminProductSectionSaleTitle;

  /// No description provided for @adminProductSectionSaleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure sale price and sale period.'**
  String get adminProductSectionSaleSubtitle;

  /// No description provided for @adminProductLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get adminProductLoadingCategories;

  /// No description provided for @adminProductLoadingItemTypes.
  ///
  /// In en, this message translates to:
  /// **'Loading item types...'**
  String get adminProductLoadingItemTypes;

  /// No description provided for @adminProductSelectCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get adminProductSelectCategoryHint;

  /// No description provided for @adminProductSelectItemTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select an item type'**
  String get adminProductSelectItemTypeHint;

  /// No description provided for @adminProductSectionCategoryTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Category & type'**
  String get adminProductSectionCategoryTypeTitle;

  /// No description provided for @adminProductSectionCategoryTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the category and item type for this product'**
  String get adminProductSectionCategoryTypeSubtitle;

  /// No description provided for @adminCreateCategoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create new category'**
  String get adminCreateCategoryTooltip;

  /// No description provided for @adminCreateItemTypeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create new item type'**
  String get adminCreateItemTypeTooltip;

  /// No description provided for @adminProductSalePriceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 99.99'**
  String get adminProductSalePriceHint;

  /// No description provided for @adminProductSaleStartHint.
  ///
  /// In en, this message translates to:
  /// **'Select sale start date'**
  String get adminProductSaleStartHint;

  /// No description provided for @adminProductSaleEndHint.
  ///
  /// In en, this message translates to:
  /// **'Select sale end date'**
  String get adminProductSaleEndHint;

  /// No description provided for @checkoutPaymentMethodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Selected payment method is not available,please call support'**
  String get checkoutPaymentMethodUnavailable;

  /// No description provided for @adminDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get adminDisable;

  /// No description provided for @adminDisableShippingMethodMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disable this shipping method? It will no longer appear at checkout.'**
  String get adminDisableShippingMethodMessage;

  /// No description provided for @adminShippingMethodDisabled.
  ///
  /// In en, this message translates to:
  /// **'Shipping method disabled successfully'**
  String get adminShippingMethodDisabled;

  /// No description provided for @adminDisabledLabel.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get adminDisabledLabel;

  /// No description provided for @adminDisabledOnly.
  ///
  /// In en, this message translates to:
  /// **'Disabled only'**
  String get adminDisabledOnly;

  /// No description provided for @adminAllLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminAllLabel;

  /// No description provided for @openLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLinkLabel;

  /// No description provided for @downloadNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadNowLabel;

  /// No description provided for @downloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadLabel;

  /// No description provided for @downloadReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready to download'**
  String get downloadReadyLabel;

  /// No description provided for @downloadAfterPurchaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Available after purchase'**
  String get downloadAfterPurchaseLabel;

  /// No description provided for @externalProductLabel.
  ///
  /// In en, this message translates to:
  /// **'External product'**
  String get externalProductLabel;

  /// No description provided for @productTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Product type'**
  String get productTypeLabel;

  /// No description provided for @invalidExternalUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Invalid external URL'**
  String get invalidExternalUrlLabel;

  /// No description provided for @missingExternalUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Missing external URL'**
  String get missingExternalUrlLabel;

  /// No description provided for @couldNotOpenLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get couldNotOpenLinkLabel;

  /// No description provided for @invalidDownloadUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Invalid download URL'**
  String get invalidDownloadUrlLabel;

  /// No description provided for @missingDownloadUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Missing download URL'**
  String get missingDownloadUrlLabel;

  /// No description provided for @couldNotStartDownloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Could not start the download'**
  String get couldNotStartDownloadLabel;

  /// No description provided for @adminDownloadableMustBeSimple.
  ///
  /// In en, this message translates to:
  /// **'Downloadable product must use Simple product type'**
  String get adminDownloadableMustBeSimple;

  /// No description provided for @adminDownloadableMustBeVirtual.
  ///
  /// In en, this message translates to:
  /// **'Downloadable product must be virtual'**
  String get adminDownloadableMustBeVirtual;

  /// No description provided for @adminDownloadUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Download URL is required for downloadable product'**
  String get adminDownloadUrlRequired;

  /// No description provided for @adminExternalUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'External URL is required for external product'**
  String get adminExternalUrlRequired;

  /// No description provided for @adminExternalCannotBeDownloadable.
  ///
  /// In en, this message translates to:
  /// **'External product cannot be downloadable'**
  String get adminExternalCannotBeDownloadable;

  /// No description provided for @adminDownloadableRulesHint.
  ///
  /// In en, this message translates to:
  /// **'Downloadable products are saved as Simple + Virtual and require a download URL.'**
  String get adminDownloadableRulesHint;

  /// No description provided for @adminAllAttributeTypesAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'All available attribute types are already added'**
  String get adminAllAttributeTypesAlreadyAdded;

  /// No description provided for @adminUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'failed to pick image'**
  String get adminUploadFailed;

  /// Common clear action label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// Common previous action tooltip
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonPrev;

  /// Common next action tooltip
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Common confirm action label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Language label English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get commonEnglish;

  /// Language label French
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get commonFrench;

  /// Language label Arabic
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get commonArabic;

  /// Quantity short label
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get commonQty;

  /// Full name label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get commonFullName;

  /// Phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get commonPhone;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get commonAddress;

  /// City label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get commonCity;

  /// Postal code label
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get commonPostalCode;

  /// Unit column label
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get commonUnit;

  /// Total column label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// Item fallback label
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get commonItem;

  /// Provider label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get commonProvider;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// Reference label
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get commonRef;

  /// Customer label
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get commonCustomer;

  /// Method label
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get commonMethod;

  /// Retry action label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Admin order edit dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get adminOrderEditTitle;

  /// Hint in admin order edit dialog
  ///
  /// In en, this message translates to:
  /// **'Set quantity to 0 to remove an item.'**
  String get adminOrderEditRemoveHint;

  /// Admin order invoice download failed message
  ///
  /// In en, this message translates to:
  /// **'Invoice download failed: {error}'**
  String adminOrderInvoiceDownloadFailed(Object error);

  /// Admin order missing shipping edit guard
  ///
  /// In en, this message translates to:
  /// **'This order cannot be edited yet because shipping country or shipping method is missing in the order details response.'**
  String get adminOrderCannotEditMissingShipping;

  /// Tooltip for admin dashboard notifications button
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get adminDashboardNotificationsTooltip;

  /// Set image as main label
  ///
  /// In en, this message translates to:
  /// **'Set main'**
  String get adminProductSetMain;

  /// Coupon valid from label
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get couponValidFrom;

  /// Coupon valid to label
  ///
  /// In en, this message translates to:
  /// **'Valid To'**
  String get couponValidTo;

  /// Excel replace scope tenant safe option
  ///
  /// In en, this message translates to:
  /// **'TENANT (safe)'**
  String get excelReplaceScopeTenantSafe;

  /// Excel replace scope full dangerous option
  ///
  /// In en, this message translates to:
  /// **'FULL (dangerous)'**
  String get excelReplaceScopeFullDangerous;

  /// Order code label
  ///
  /// In en, this message translates to:
  /// **'Order code'**
  String get orderDetailsOrderCode;

  /// Order recipient name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get orderDetailsName;

  /// Order recipient phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get orderDetailsPhone;

  /// Order recipient address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get orderDetailsAddress;

  /// Order recipient city label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get orderDetailsCity;

  /// Order recipient postal code label
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get orderDetailsPostalCode;

  /// Payment label in order details
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get orderDetailsPayment;

  /// Invoice title
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceTitle;

  /// Invoice items section title
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get invoiceItems;

  /// Invoice order label
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get invoiceOrder;

  /// Invoice date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get invoiceDate;

  /// Invoice shipping label
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get invoiceShipping;

  /// Invoice subtotal label
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get invoiceSubtotal;

  /// Invoice tax label
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get invoiceTax;

  /// Invoice grand total label
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get invoiceGrandTotal;

  /// Invoice coupon line label
  ///
  /// In en, this message translates to:
  /// **'Coupon ({code})'**
  String invoiceCouponLine(Object code);

  /// Restore action label
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreLabel;

  /// Restore deleted account sheet title
  ///
  /// In en, this message translates to:
  /// **'Restore deleted account?'**
  String get restoreDeletedAccountTitle;

  /// Restore deleted account sheet message
  ///
  /// In en, this message translates to:
  /// **'This account was deleted, but it can still be restored. Do you want to reactivate it now?'**
  String get restoreDeletedAccountMessage;

  /// Account restored success toast
  ///
  /// In en, this message translates to:
  /// **'Account restored successfully'**
  String get accountRestoredSuccessfully;

  /// Admin mark paid confirm text
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get adminOrderMarkPaid;

  /// Admin complete confirm text
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get adminOrderComplete;

  /// Admin reject confirm text
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminOrderReject;

  /// Admin reopen confirm text
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get adminOrderReopen;

  /// Admin restore confirm text
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get adminOrderRestore;

  /// No description provided for @adminOrderSequenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Seq'**
  String get adminOrderSequenceLabel;

  /// No description provided for @adminOrderInternalIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Internal ID'**
  String get adminOrderInternalIdLabel;

  /// No description provided for @adminPaymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get adminPaymentMethodLabel;

  /// No description provided for @adminOrderCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get adminOrderCompleteTitle;

  /// No description provided for @adminOrderCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'This will mark the order as completed.'**
  String get adminOrderCompleteBody;

  /// No description provided for @adminOrderReopenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reopen (Cancel + Unpay)'**
  String get adminOrderReopenTitle;

  /// No description provided for @adminOrderReopenBody.
  ///
  /// In en, this message translates to:
  /// **'This will cancel the order and reset payment back to UNPAID.'**
  String get adminOrderReopenBody;

  /// No description provided for @adminOrderRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore to Pending'**
  String get adminOrderRestoreTitle;

  /// No description provided for @adminOrderRestoreBody.
  ///
  /// In en, this message translates to:
  /// **'This will restore the order back to Pending.'**
  String get adminOrderRestoreBody;

  /// No description provided for @commonSomethingWentWrongTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonSomethingWentWrongTryAgain;

  /// No description provided for @orderDetailsInvoiceDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Invoice download failed'**
  String orderDetailsInvoiceDownloadFailed(Object error);

  /// No description provided for @stripeWebhookSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Stripe webhook setup'**
  String get stripeWebhookSetupTitle;

  /// No description provided for @stripeWebhookSetupDescription.
  ///
  /// In en, this message translates to:
  /// **'To make payment status update correctly inside the app, create a Stripe webhook and select the required events below.'**
  String get stripeWebhookSetupDescription;

  /// No description provided for @stripeWebhookStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Open your Stripe Dashboard.'**
  String get stripeWebhookStep1;

  /// No description provided for @stripeWebhookStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Go to Developers > Webhooks.'**
  String get stripeWebhookStep2;

  /// No description provided for @stripeWebhookStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Click “Add endpoint”.'**
  String get stripeWebhookStep3;

  /// No description provided for @stripeWebhookStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Paste the webhook URL shown below.'**
  String get stripeWebhookStep4;

  /// No description provided for @stripeWebhookStep5.
  ///
  /// In en, this message translates to:
  /// **'5. Select these events:'**
  String get stripeWebhookStep5;

  /// No description provided for @stripeWebhookStep6.
  ///
  /// In en, this message translates to:
  /// **'6. Click “Add endpoint”.'**
  String get stripeWebhookStep6;

  /// No description provided for @stripeWebhookStep7.
  ///
  /// In en, this message translates to:
  /// **'7. Copy the Signing Secret from Stripe.'**
  String get stripeWebhookStep7;

  /// No description provided for @stripeWebhookStep8.
  ///
  /// In en, this message translates to:
  /// **'8. Paste the Signing Secret in this payment configuration and save.'**
  String get stripeWebhookStep8;

  /// No description provided for @stripeWebhookImportant.
  ///
  /// In en, this message translates to:
  /// **'Important: Without this webhook, Stripe may receive the payment, but the app may still show the order as unpaid.'**
  String get stripeWebhookImportant;

  /// No description provided for @stripeWebhookUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Webhook URL'**
  String get stripeWebhookUrlLabel;

  /// No description provided for @stripeWebhookCopyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy webhook URL'**
  String get stripeWebhookCopyButton;

  /// No description provided for @stripeWebhookCopied.
  ///
  /// In en, this message translates to:
  /// **'Webhook URL copied'**
  String get stripeWebhookCopied;

  /// No description provided for @stripeWebhookOpenStripe.
  ///
  /// In en, this message translates to:
  /// **'Open Stripe'**
  String get stripeWebhookOpenStripe;

  /// No description provided for @stripeWebhookMustTestFirst.
  ///
  /// In en, this message translates to:
  /// **'Please test Stripe connection and webhook before saving.'**
  String get stripeWebhookMustTestFirst;

  /// No description provided for @connectionSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Connection succeeded'**
  String get connectionSucceeded;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @paymentTestingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get paymentTestingConnection;

  /// No description provided for @paymentTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get paymentTestConnection;

  /// No description provided for @paymentOpenProviderDocs.
  ///
  /// In en, this message translates to:
  /// **'Open provider docs'**
  String get paymentOpenProviderDocs;

  /// No description provided for @paymentOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get paymentOn;

  /// No description provided for @paymentOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get paymentOff;

  /// No description provided for @paymentLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get paymentLearnMore;

  /// No description provided for @paymentCouldNotOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link.'**
  String get paymentCouldNotOpenUrl;

  /// No description provided for @paymentInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number: {field}'**
  String paymentInvalidNumber(Object field);

  /// No description provided for @paymentMissingRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Missing required field: {field}'**
  String paymentMissingRequiredField(Object field);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
