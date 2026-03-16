import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';

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
    Locale('fr'),
    Locale('nl'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Vanakel Group'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @propertyAddress.
  ///
  /// In en, this message translates to:
  /// **'Property Address'**
  String get propertyAddress;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// No description provided for @syndic.
  ///
  /// In en, this message translates to:
  /// **'Syndic'**
  String get syndic;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Simplify Property Management'**
  String get onboardingTitle;

  /// No description provided for @onboardingDesc.
  ///
  /// In en, this message translates to:
  /// **'Streamline interventions and interventions with our powerful management platform.'**
  String get onboardingDesc;

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

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @dutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get dutch;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @businessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get businessDetails;

  /// No description provided for @propertyOverview.
  ///
  /// In en, this message translates to:
  /// **'Property Overview'**
  String get propertyOverview;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @adminPortal.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get adminPortal;

  /// No description provided for @syndicAccess.
  ///
  /// In en, this message translates to:
  /// **'Syndic Access'**
  String get syndicAccess;

  /// No description provided for @managedProperties.
  ///
  /// In en, this message translates to:
  /// **'Managed Properties'**
  String get managedProperties;

  /// No description provided for @activeAssets.
  ///
  /// In en, this message translates to:
  /// **'active assets'**
  String get activeAssets;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @newMissions.
  ///
  /// In en, this message translates to:
  /// **'New Missions'**
  String get newMissions;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @delayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get delayed;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @syndicPortal.
  ///
  /// In en, this message translates to:
  /// **'Syndic Portal'**
  String get syndicPortal;

  /// No description provided for @needIntervention.
  ///
  /// In en, this message translates to:
  /// **'Need an intervention?'**
  String get needIntervention;

  /// No description provided for @createRequestDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new request for your buildings.'**
  String get createRequestDesc;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @myInterventions.
  ///
  /// In en, this message translates to:
  /// **'My Interventions'**
  String get myInterventions;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Real-time Updates & Notifications'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Stay informed with instant alerts and updates on all critical activities and interventions.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Reports & Analytics'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Access detailed insights and generate professional reports to make data-driven decisions.'**
  String get onboardingDesc3;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @missions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get missions;

  /// No description provided for @interventions.
  ///
  /// In en, this message translates to:
  /// **'Interventions'**
  String get interventions;

  /// No description provided for @missionsInbox.
  ///
  /// In en, this message translates to:
  /// **'Missions Inbox'**
  String get missionsInbox;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequestsYet;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalDesc.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully created. For security reasons, an administrator must review and approve your access before you can enter the workplace.'**
  String get pendingApprovalDesc;

  /// No description provided for @statusVerification.
  ///
  /// In en, this message translates to:
  /// **'Status Verification'**
  String get statusVerification;

  /// No description provided for @statusVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'We are currently verifying your professional credentials.'**
  String get statusVerificationDesc;

  /// No description provided for @emailConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Email Confirmation'**
  String get emailConfirmation;

  /// No description provided for @emailConfirmationDesc.
  ///
  /// In en, this message translates to:
  /// **'You will receive an email notification as soon as your account is activated.'**
  String get emailConfirmationDesc;

  /// No description provided for @checkingStatusFor.
  ///
  /// In en, this message translates to:
  /// **'Checking status for: {email}'**
  String checkingStatusFor(Object email);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @latestSlips.
  ///
  /// In en, this message translates to:
  /// **'Latest Slips'**
  String get latestSlips;

  /// No description provided for @fullHistory.
  ///
  /// In en, this message translates to:
  /// **'Full History'**
  String get fullHistory;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @allSyndics.
  ///
  /// In en, this message translates to:
  /// **'All Syndics'**
  String get allSyndics;
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
      <String>['en', 'fr', 'nl'].contains(locale.languageCode);

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
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
