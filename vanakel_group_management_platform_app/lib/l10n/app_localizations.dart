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

  /// No description provided for @technician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technician;

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
  /// **'MAINTENANCE'**
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

  /// No description provided for @searchInterventions.
  ///
  /// In en, this message translates to:
  /// **'Search interventions...'**
  String get searchInterventions;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select Status'**
  String get selectStatus;

  /// No description provided for @selectSector.
  ///
  /// In en, this message translates to:
  /// **'Select Sector'**
  String get selectSector;

  /// No description provided for @selectUrgency.
  ///
  /// In en, this message translates to:
  /// **'Select Urgency'**
  String get selectUrgency;

  /// No description provided for @selectBuilding.
  ///
  /// In en, this message translates to:
  /// **'Select Building'**
  String get selectBuilding;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @noInterventionsFound.
  ///
  /// In en, this message translates to:
  /// **'No interventions found'**
  String get noInterventionsFound;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @viewSlip.
  ///
  /// In en, this message translates to:
  /// **'VIEW SLIP'**
  String get viewSlip;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get high;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get critical;

  /// No description provided for @searchMissions.
  ///
  /// In en, this message translates to:
  /// **'Search missions...'**
  String get searchMissions;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgency;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @sector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get sector;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @filterByUrgency.
  ///
  /// In en, this message translates to:
  /// **'Filter by Urgency'**
  String get filterByUrgency;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @filterBySector.
  ///
  /// In en, this message translates to:
  /// **'Filter by Sector'**
  String get filterBySector;

  /// No description provided for @filterByBuilding.
  ///
  /// In en, this message translates to:
  /// **'Filter by Building'**
  String get filterByBuilding;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get allStatuses;

  /// No description provided for @allUrgencies.
  ///
  /// In en, this message translates to:
  /// **'All urgencies'**
  String get allUrgencies;

  /// No description provided for @allSectors.
  ///
  /// In en, this message translates to:
  /// **'All sectors'**
  String get allSectors;

  /// No description provided for @allBuildings.
  ///
  /// In en, this message translates to:
  /// **'All buildings'**
  String get allBuildings;

  /// No description provided for @noSectorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sectors available'**
  String get noSectorsAvailable;

  /// No description provided for @noBuildingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No buildings available'**
  String get noBuildingsAvailable;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @noMissionsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No missions match your filters'**
  String get noMissionsMatchFilters;

  /// No description provided for @pendingRequest.
  ///
  /// In en, this message translates to:
  /// **'Pending Request'**
  String get pendingRequest;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get needsReview;

  /// No description provided for @aiDetectedMission.
  ///
  /// In en, this message translates to:
  /// **'AI DETECTED MISSION'**
  String get aiDetectedMission;

  /// No description provided for @retryFetchingMissions.
  ///
  /// In en, this message translates to:
  /// **'Retry Fetching Missions'**
  String get retryFetchingMissions;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @noSyndic.
  ///
  /// In en, this message translates to:
  /// **'No Syndic'**
  String get noSyndic;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get details;

  /// No description provided for @approveMission.
  ///
  /// In en, this message translates to:
  /// **'Approve Mission'**
  String get approveMission;

  /// No description provided for @approveMissionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this mission and turn it into an intervention?'**
  String get approveMissionConfirm;

  /// No description provided for @missionApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mission approved successfully'**
  String get missionApprovedSuccess;

  /// No description provided for @rejectMission.
  ///
  /// In en, this message translates to:
  /// **'Reject Mission'**
  String get rejectMission;

  /// No description provided for @rejectMissionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this mission?'**
  String get rejectMissionConfirm;

  /// No description provided for @missionRejected.
  ///
  /// In en, this message translates to:
  /// **'Mission rejected'**
  String get missionRejected;

  /// No description provided for @mission.
  ///
  /// In en, this message translates to:
  /// **'MISSION'**
  String get mission;

  /// No description provided for @reviewDocuments.
  ///
  /// In en, this message translates to:
  /// **'REVIEW DOCUMENTS'**
  String get reviewDocuments;

  /// No description provided for @interventionDateOptional.
  ///
  /// In en, this message translates to:
  /// **'INTERVENTION DATE (OPTIONAL)'**
  String get interventionDateOptional;

  /// No description provided for @selectDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select date...'**
  String get selectDatePlaceholder;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'APPROVE'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'REJECT'**
  String get reject;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgent;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'NORMAL'**
  String get normal;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get low;

  /// No description provided for @electricity.
  ///
  /// In en, this message translates to:
  /// **'ELECTRICITY'**
  String get electricity;

  /// No description provided for @tiling.
  ///
  /// In en, this message translates to:
  /// **'TILING'**
  String get tiling;

  /// No description provided for @sanitary.
  ///
  /// In en, this message translates to:
  /// **'SANITARY'**
  String get sanitary;

  /// No description provided for @heating.
  ///
  /// In en, this message translates to:
  /// **'HEATING'**
  String get heating;

  /// No description provided for @plumbing.
  ///
  /// In en, this message translates to:
  /// **'PLUMBING'**
  String get plumbing;

  /// No description provided for @painting.
  ///
  /// In en, this message translates to:
  /// **'PAINTING'**
  String get painting;

  /// No description provided for @woodwork.
  ///
  /// In en, this message translates to:
  /// **'WOODWORK'**
  String get woodwork;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get general;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get other;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'LOADING...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get error;

  /// No description provided for @onSiteContact.
  ///
  /// In en, this message translates to:
  /// **'ON-SITE CONTACT'**
  String get onSiteContact;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get name;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'GSM / TEL'**
  String get phoneTitle;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'EMAIL (OPTIONAL)'**
  String get emailOptional;

  /// No description provided for @syndicCustomerInfo.
  ///
  /// In en, this message translates to:
  /// **'SYNDIC / CUSTOMER INFO'**
  String get syndicCustomerInfo;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer...'**
  String get selectCustomer;

  /// No description provided for @errorLoadingSyndics.
  ///
  /// In en, this message translates to:
  /// **'Error loading syndics'**
  String get errorLoadingSyndics;

  /// No description provided for @interventionDescription.
  ///
  /// In en, this message translates to:
  /// **'INTERVENTION DESCRIPTION'**
  String get interventionDescription;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'UPDATE STATUS'**
  String get updateStatus;

  /// No description provided for @technicalObservations.
  ///
  /// In en, this message translates to:
  /// **'TECHNICAL OBSERVATIONS'**
  String get technicalObservations;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'PHOTOS'**
  String get photos;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS'**
  String get documents;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get register;

  /// No description provided for @interventionRegisteredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Intervention registered successfully'**
  String get interventionRegisteredSuccess;

  /// No description provided for @technicalFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Technical feedback or observations...'**
  String get technicalFeedbackHint;

  /// No description provided for @improveWithAi.
  ///
  /// In en, this message translates to:
  /// **'IMPROVE WITH AI'**
  String get improveWithAi;

  /// No description provided for @noteImprovedWithAi.
  ///
  /// In en, this message translates to:
  /// **'Note improved with AI'**
  String get noteImprovedWithAi;

  /// No description provided for @mediaAudit.
  ///
  /// In en, this message translates to:
  /// **'MEDIA & AUDIT'**
  String get mediaAudit;

  /// No description provided for @auditTraceability.
  ///
  /// In en, this message translates to:
  /// **'AUDIT TRACEABILITY'**
  String get auditTraceability;

  /// No description provided for @interventionInitializedOn.
  ///
  /// In en, this message translates to:
  /// **'INTERVENTION INITIALIZED ON'**
  String get interventionInitializedOn;

  /// No description provided for @locationAccess.
  ///
  /// In en, this message translates to:
  /// **'LOCATION & ACCESS'**
  String get locationAccess;

  /// No description provided for @createMaintenancePlan.
  ///
  /// In en, this message translates to:
  /// **'CREATE MAINTENANCE PLAN'**
  String get createMaintenancePlan;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'MAINTENANCE TITLE'**
  String get maintenanceTitle;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'START DATE'**
  String get startDate;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'FREQUENCY'**
  String get frequency;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'YEARLY'**
  String get yearly;

  /// No description provided for @quarterly.
  ///
  /// In en, this message translates to:
  /// **'QUARTERLY'**
  String get quarterly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY'**
  String get monthly;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get description;

  /// No description provided for @maintenancePlanAutoInfo.
  ///
  /// In en, this message translates to:
  /// **'Interventions will be created automatically for the next 5 years.'**
  String get maintenancePlanAutoInfo;

  /// No description provided for @confirmPlan.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PLAN'**
  String get confirmPlan;

  /// No description provided for @maintenancePlanCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Maintenance plan created successfully'**
  String get maintenancePlanCreatedSuccess;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'SAVE RECORD'**
  String get saveRecord;

  /// No description provided for @chooseSaveMode.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE SAVE MODE'**
  String get chooseSaveMode;

  /// No description provided for @saveOnly.
  ///
  /// In en, this message translates to:
  /// **'SAVE ONLY'**
  String get saveOnly;

  /// No description provided for @saveSendEmail.
  ///
  /// In en, this message translates to:
  /// **'SAVE & SEND EMAIL'**
  String get saveSendEmail;

  /// No description provided for @saveSendWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'SAVE & SEND WHATSAPP'**
  String get saveSendWhatsapp;

  /// No description provided for @registerInterventionTitle.
  ///
  /// In en, this message translates to:
  /// **'REGISTER INTERVENTION'**
  String get registerInterventionTitle;

  /// No description provided for @missionDetails.
  ///
  /// In en, this message translates to:
  /// **'Mission Details'**
  String get missionDetails;

  /// No description provided for @chooseADate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date...'**
  String get chooseADate;

  /// No description provided for @missionHeader.
  ///
  /// In en, this message translates to:
  /// **'MISSION'**
  String get missionHeader;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @couldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {fileName}'**
  String couldNotOpen(Object fileName);

  /// No description provided for @aiDetected.
  ///
  /// In en, this message translates to:
  /// **'AI Detected'**
  String get aiDetected;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdOn(Object date);

  /// No description provided for @delayReasonHeader.
  ///
  /// In en, this message translates to:
  /// **'DELAY REASON'**
  String get delayReasonHeader;

  /// No description provided for @whyIsItDelayed.
  ///
  /// In en, this message translates to:
  /// **'WHY IS IT DELAYED?'**
  String get whyIsItDelayed;

  /// No description provided for @selectAReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason'**
  String get selectAReason;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'ADDITIONAL DETAILS'**
  String get additionalDetails;

  /// No description provided for @enterSpecificDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter specific details about the delay...'**
  String get enterSpecificDetails;

  /// No description provided for @newScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'NEW SCHEDULED DATE (OPTIONAL)'**
  String get newScheduledDate;

  /// No description provided for @selectNewDate.
  ///
  /// In en, this message translates to:
  /// **'Select new date'**
  String get selectNewDate;

  /// No description provided for @confirmDelay.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM DELAY'**
  String get confirmDelay;

  /// No description provided for @extractedSyndicUnmatched.
  ///
  /// In en, this message translates to:
  /// **'EXTRACTED SYNDIC (UNMATCHED)'**
  String get extractedSyndicUnmatched;

  /// No description provided for @notMatchedToDatabase.
  ///
  /// In en, this message translates to:
  /// **'NOT MATCHED TO DATABASE'**
  String get notMatchedToDatabase;

  /// No description provided for @syndicManager.
  ///
  /// In en, this message translates to:
  /// **'SYNDIC / MANAGER'**
  String get syndicManager;

  /// No description provided for @delayReasonMissingPart.
  ///
  /// In en, this message translates to:
  /// **'Missing part'**
  String get delayReasonMissingPart;

  /// No description provided for @delayReasonNoAccess.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get delayReasonNoAccess;

  /// No description provided for @delayReasonClientUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Client unavailable'**
  String get delayReasonClientUnavailable;

  /// No description provided for @delayReasonWaitingValidation.
  ///
  /// In en, this message translates to:
  /// **'Waiting validation'**
  String get delayReasonWaitingValidation;

  /// No description provided for @delayReasonWeather.
  ///
  /// In en, this message translates to:
  /// **'Bad weather'**
  String get delayReasonWeather;

  /// No description provided for @delayReasonSubcontractor.
  ///
  /// In en, this message translates to:
  /// **'Subcontractor unavailable'**
  String get delayReasonSubcontractor;

  /// No description provided for @delayReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get delayReasonOther;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @noBioProvided.
  ///
  /// In en, this message translates to:
  /// **'No bio provided'**
  String get noBioProvided;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMismatch;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String fieldRequired(Object field);

  /// No description provided for @minChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count} characters required'**
  String minChars(Object count);

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String profileUpdateError(Object error);

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry! It happens. Please enter the email address associated with your account.'**
  String get forgotPasswordDesc;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get resetLinkSent;

  /// No description provided for @rememberPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember password?'**
  String get rememberPassword;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @otpSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We have sent a 6-digit code to your email. Please enter it below to verify your account.'**
  String get otpSentMessage;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @enterAllDigits.
  ///
  /// In en, this message translates to:
  /// **'Please enter all 6 digits'**
  String get enterAllDigits;

  /// No description provided for @otpResentSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP resent successfully'**
  String get otpResentSuccess;

  /// No description provided for @adminRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Central Management & Control'**
  String get adminRoleSubtitle;

  /// No description provided for @syndicRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Property Overview & Requests'**
  String get syndicRoleSubtitle;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @updateRequest.
  ///
  /// In en, this message translates to:
  /// **'Update Request'**
  String get updateRequest;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @onSiteContactName.
  ///
  /// In en, this message translates to:
  /// **'On-Site Contact Name'**
  String get onSiteContactName;

  /// No description provided for @onSiteContactPhone.
  ///
  /// In en, this message translates to:
  /// **'On-Site Contact Phone'**
  String get onSiteContactPhone;

  /// No description provided for @onSiteContactEmail.
  ///
  /// In en, this message translates to:
  /// **'On-Site Contact Email'**
  String get onSiteContactEmail;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @enterSubject.
  ///
  /// In en, this message translates to:
  /// **'e.g., Water Leak'**
  String get enterSubject;

  /// No description provided for @selectBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'Select building...'**
  String get selectBuildingHint;

  /// No description provided for @selectSyndicHint.
  ///
  /// In en, this message translates to:
  /// **'Select syndic...'**
  String get selectSyndicHint;
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
