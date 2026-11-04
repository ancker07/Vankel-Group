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

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @openGps.
  ///
  /// In en, this message translates to:
  /// **'Open GPS'**
  String get openGps;

  /// No description provided for @endOfMission.
  ///
  /// In en, this message translates to:
  /// **'End of mission'**
  String get endOfMission;

  /// No description provided for @noCompletedMissions.
  ///
  /// In en, this message translates to:
  /// **'No completed missions yet.'**
  String get noCompletedMissions;

  /// No description provided for @dictate.
  ///
  /// In en, this message translates to:
  /// **'Dictate'**
  String get dictate;

  /// No description provided for @stopDictation.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopDictation;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening… speak now'**
  String get listening;

  /// No description provided for @speechUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice dictation is not available on this device.'**
  String get speechUnavailable;

  /// No description provided for @missionLocked.
  ///
  /// In en, this message translates to:
  /// **'This mission is completed. Only an admin can change it.'**
  String get missionLocked;

  /// No description provided for @assignedProfessional.
  ///
  /// In en, this message translates to:
  /// **'Assigned professional'**
  String get assignedProfessional;

  /// No description provided for @admInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get admInbox;

  /// No description provided for @admContacts.
  ///
  /// In en, this message translates to:
  /// **'Contact requests'**
  String get admContacts;

  /// No description provided for @admTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get admTeam;

  /// No description provided for @admUsers.
  ///
  /// In en, this message translates to:
  /// **'Users & roles'**
  String get admUsers;

  /// No description provided for @admPush.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get admPush;

  /// No description provided for @admAiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get admAiSettings;

  /// No description provided for @admSystem.
  ///
  /// In en, this message translates to:
  /// **'System overview'**
  String get admSystem;

  /// No description provided for @admNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get admNothingHere;

  /// No description provided for @admSearchEmails.
  ///
  /// In en, this message translates to:
  /// **'Search emails…'**
  String get admSearchEmails;

  /// No description provided for @admSync.
  ///
  /// In en, this message translates to:
  /// **'Sync & process'**
  String get admSync;

  /// No description provided for @admSyncDone.
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed'**
  String get admSyncDone;

  /// No description provided for @admIngest.
  ///
  /// In en, this message translates to:
  /// **'Process email'**
  String get admIngest;

  /// No description provided for @admIngestAll.
  ///
  /// In en, this message translates to:
  /// **'Process all'**
  String get admIngestAll;

  /// No description provided for @admIngestResult.
  ///
  /// In en, this message translates to:
  /// **'Result: {status}'**
  String admIngestResult(String status);

  /// No description provided for @admDeleteEmail.
  ///
  /// In en, this message translates to:
  /// **'Delete email'**
  String get admDeleteEmail;

  /// No description provided for @admDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Delete?'**
  String get admDeleteConfirm;

  /// No description provided for @admDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get admDelete;

  /// No description provided for @admReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get admReply;

  /// No description provided for @admReplyFrom.
  ///
  /// In en, this message translates to:
  /// **'Send from'**
  String get admReplyFrom;

  /// No description provided for @admSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get admSend;

  /// No description provided for @admSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get admSent;

  /// No description provided for @admMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get admMessage;

  /// No description provided for @admThreadMessages.
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String admThreadMessages(int count);

  /// No description provided for @admAttachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get admAttachments;

  /// No description provided for @admIngestionStatus.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get admIngestionStatus;

  /// No description provided for @admNotIngested.
  ///
  /// In en, this message translates to:
  /// **'Not processed'**
  String get admNotIngested;

  /// No description provided for @admUnknownSender.
  ///
  /// In en, this message translates to:
  /// **'Unknown sender'**
  String get admUnknownSender;

  /// No description provided for @admNoSubject.
  ///
  /// In en, this message translates to:
  /// **'(no subject)'**
  String get admNoSubject;

  /// No description provided for @admCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get admCall;

  /// No description provided for @admLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String admLastSeen(String time);

  /// No description provided for @admNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location yet'**
  String get admNoLocation;

  /// No description provided for @admOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get admOpenMap;

  /// No description provided for @admCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get admCreateUser;

  /// No description provided for @admFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get admFirstName;

  /// No description provided for @admLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get admLastName;

  /// No description provided for @admRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get admRole;

  /// No description provided for @admChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get admChangeRole;

  /// No description provided for @admResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get admResetPassword;

  /// No description provided for @admNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password (min. 8 characters)'**
  String get admNewPasswordHint;

  /// No description provided for @admPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get admPasswordTooShort;

  /// No description provided for @admDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get admDeleteUser;

  /// No description provided for @admDeleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String admDeleteUserConfirm(String name);

  /// No description provided for @admUserApproved.
  ///
  /// In en, this message translates to:
  /// **'User approved'**
  String get admUserApproved;

  /// No description provided for @admUserRejected.
  ///
  /// In en, this message translates to:
  /// **'User rejected'**
  String get admUserRejected;

  /// No description provided for @admUserCreated.
  ///
  /// In en, this message translates to:
  /// **'User created'**
  String get admUserCreated;

  /// No description provided for @admUserDeleted.
  ///
  /// In en, this message translates to:
  /// **'User deleted'**
  String get admUserDeleted;

  /// No description provided for @admRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get admRoleUpdated;

  /// No description provided for @admPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get admPasswordReset;

  /// No description provided for @admSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get admSave;

  /// No description provided for @admPendingUsers.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get admPendingUsers;

  /// No description provided for @admRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get admRolesTitle;

  /// No description provided for @admRoleUsersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String admRoleUsersCount(int count);

  /// No description provided for @admRoleFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get admRoleFull;

  /// No description provided for @admPermissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} permissions'**
  String admPermissionsCount(int count);

  /// No description provided for @admBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get admBroadcastTitle;

  /// No description provided for @admBroadcastBody.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get admBroadcastBody;

  /// No description provided for @admTargetAll.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get admTargetAll;

  /// No description provided for @admTargetSpecific.
  ///
  /// In en, this message translates to:
  /// **'Selected users'**
  String get admTargetSpecific;

  /// No description provided for @admImportant.
  ///
  /// In en, this message translates to:
  /// **'Important (alert sound)'**
  String get admImportant;

  /// No description provided for @admSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send notification'**
  String get admSendNotification;

  /// No description provided for @admNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent'**
  String get admNotificationSent;

  /// No description provided for @admHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get admHistory;

  /// No description provided for @admSelectUsers.
  ///
  /// In en, this message translates to:
  /// **'Select users'**
  String get admSelectUsers;

  /// No description provided for @admSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String admSelectedCount(int count);

  /// No description provided for @admRecipients.
  ///
  /// In en, this message translates to:
  /// **'{ok}/{total} delivered'**
  String admRecipients(int ok, int total);

  /// No description provided for @admAiModel.
  ///
  /// In en, this message translates to:
  /// **'AI model'**
  String get admAiModel;

  /// No description provided for @admAiApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get admAiApiKey;

  /// No description provided for @admSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get admSaved;

  /// No description provided for @admRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get admRequired;

  /// No description provided for @admStatAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admStatAdmins;

  /// No description provided for @admStatSyndics.
  ///
  /// In en, this message translates to:
  /// **'Syndics'**
  String get admStatSyndics;

  /// No description provided for @admStatProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Technicians'**
  String get admStatProfessionals;

  /// No description provided for @admStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending registrations'**
  String get admStatPending;

  /// No description provided for @admStatEmails.
  ///
  /// In en, this message translates to:
  /// **'Emails'**
  String get admStatEmails;

  /// No description provided for @admStatBuildings.
  ///
  /// In en, this message translates to:
  /// **'Buildings'**
  String get admStatBuildings;

  /// No description provided for @admStatInterventions.
  ///
  /// In en, this message translates to:
  /// **'Interventions'**
  String get admStatInterventions;

  /// No description provided for @admDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get admDuplicateTitle;

  /// No description provided for @admDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'This request looks like mission #{id} ({score}% similar).'**
  String admDuplicateBody(String id, String score);

  /// No description provided for @admNotDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Not a duplicate'**
  String get admNotDuplicate;

  /// No description provided for @admMergeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get admMergeDuplicate;

  /// No description provided for @admMergeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Merge into the oldest mission? The other mission is removed; its documents and history are kept.'**
  String get admMergeConfirm;

  /// No description provided for @admDuplicateDismissed.
  ///
  /// In en, this message translates to:
  /// **'Marked as not a duplicate'**
  String get admDuplicateDismissed;

  /// No description provided for @admMerged.
  ///
  /// In en, this message translates to:
  /// **'Missions merged'**
  String get admMerged;

  /// No description provided for @admFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Follow-ups'**
  String get admFollowUps;

  /// No description provided for @admFollowUpVia.
  ///
  /// In en, this message translates to:
  /// **'Attached by {reason}'**
  String admFollowUpVia(String reason);

  /// No description provided for @admReasonReference.
  ///
  /// In en, this message translates to:
  /// **'reference'**
  String get admReasonReference;

  /// No description provided for @admReasonThread.
  ///
  /// In en, this message translates to:
  /// **'conversation'**
  String get admReasonThread;

  /// No description provided for @admReasonBuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'building + title'**
  String get admReasonBuildingTitle;

  /// No description provided for @admReasonMerge.
  ///
  /// In en, this message translates to:
  /// **'merge'**
  String get admReasonMerge;

  /// No description provided for @admForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this section'**
  String get admForbidden;

  /// No description provided for @pdfGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF…'**
  String get pdfGenerating;

  /// No description provided for @pdfNoViewer.
  ///
  /// In en, this message translates to:
  /// **'PDF saved, but no app was found to open it. Install a PDF viewer.'**
  String get pdfNoViewer;

  /// No description provided for @pdfError.
  ///
  /// In en, this message translates to:
  /// **'Could not create the PDF: {error}'**
  String pdfError(String error);

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{name} is larger than 10 MB'**
  String fileTooLarge(String name);

  /// No description provided for @speechPermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. Allow it in the app settings to dictate.'**
  String get speechPermission;

  /// No description provided for @speechNetwork.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition needs an internet connection.'**
  String get speechNetwork;

  /// No description provided for @speechLanguage.
  ///
  /// In en, this message translates to:
  /// **'This language is not available for voice on your phone. Install it in your phone\'s speech settings.'**
  String get speechLanguage;

  /// No description provided for @speechRetry.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition stopped. Please try again.'**
  String get speechRetry;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @aiErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'AI error: {message}'**
  String aiErrorWithMessage(String message);

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errNoInternet;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out. Please try again.'**
  String get errTimeout;

  /// No description provided for @errServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errServer;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get errNotFound;

  /// No description provided for @errUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errUnauthorized;

  /// No description provided for @errValidation.
  ///
  /// In en, this message translates to:
  /// **'Some information is not valid.'**
  String get errValidation;

  /// No description provided for @errUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errUnknown;

  /// No description provided for @registerAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Register to become a Vanakel Group member.'**
  String get registerAdminDesc;

  /// No description provided for @registerSyndicDesc.
  ///
  /// In en, this message translates to:
  /// **'Register as a syndic to oversee properties and report issues.'**
  String get registerSyndicDesc;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Effectively Manage with Ease'**
  String get splashTagline;

  /// No description provided for @needHelpContact.
  ///
  /// In en, this message translates to:
  /// **'NEED HELP? CONTACT@VANKEL.BE'**
  String get needHelpContact;

  /// No description provided for @userFallbackName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFallbackName;

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No address'**
  String get noAddress;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get noTitle;

  /// No description provided for @missionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Mission not found'**
  String get missionNotFound;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @noPropertiesFound.
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get noPropertiesFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingFilters;

  /// No description provided for @syndicContact.
  ///
  /// In en, this message translates to:
  /// **'SYNDIC CONTACT'**
  String get syndicContact;

  /// No description provided for @noSyndicLinked.
  ///
  /// In en, this message translates to:
  /// **'No syndic linked'**
  String get noSyndicLinked;

  /// No description provided for @interventionHistory.
  ///
  /// In en, this message translates to:
  /// **'INTERVENTION HISTORY'**
  String get interventionHistory;

  /// No description provided for @missionUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mission updated successfully'**
  String get missionUpdatedSuccess;

  /// No description provided for @requestSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request sent successfully'**
  String get requestSentSuccess;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @nextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextOccurrence(String date);

  /// No description provided for @routineMaintenancePlan.
  ///
  /// In en, this message translates to:
  /// **'Routine maintenance plan.'**
  String get routineMaintenancePlan;

  /// No description provided for @deletePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete plan?'**
  String get deletePlanTitle;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @noMaintenancePlans.
  ///
  /// In en, this message translates to:
  /// **'No maintenance plans'**
  String get noMaintenancePlans;

  /// No description provided for @createFirstPlan.
  ///
  /// In en, this message translates to:
  /// **'Create your first plan to start tracking'**
  String get createFirstPlan;

  /// No description provided for @selectBuildingError.
  ///
  /// In en, this message translates to:
  /// **'Please select a building'**
  String get selectBuildingError;

  /// No description provided for @newMaintenancePlan.
  ///
  /// In en, this message translates to:
  /// **'New maintenance plan'**
  String get newMaintenancePlan;

  /// No description provided for @editMaintenancePlan.
  ///
  /// In en, this message translates to:
  /// **'Edit maintenance plan'**
  String get editMaintenancePlan;

  /// No description provided for @errorLoadingBuildings.
  ///
  /// In en, this message translates to:
  /// **'Error loading buildings'**
  String get errorLoadingBuildings;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @createPlan.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get createPlan;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// No description provided for @agoSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count}s ago'**
  String agoSeconds(int count);

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String agoDays(int count);

  /// No description provided for @teamMember.
  ///
  /// In en, this message translates to:
  /// **'TEAM MEMBER'**
  String get teamMember;

  /// No description provided for @assignedByName.
  ///
  /// In en, this message translates to:
  /// **'Assigned by {name}'**
  String assignedByName(String name);

  /// No description provided for @locationUpdatedAgo.
  ///
  /// In en, this message translates to:
  /// **'Location updated {when}'**
  String locationUpdatedAgo(String when);

  /// No description provided for @noLocationSharedYet.
  ///
  /// In en, this message translates to:
  /// **'No location shared yet'**
  String get noLocationSharedYet;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'OPEN IN GOOGLE MAPS'**
  String get openInGoogleMaps;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Important notifications'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for important notifications.'**
  String get notificationChannelDescription;

  /// No description provided for @locationSharingActive.
  ///
  /// In en, this message translates to:
  /// **'Location sharing with your team is active'**
  String get locationSharingActive;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @statusProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get statusProcessed;

  /// No description provided for @statusIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get statusIgnored;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// No description provided for @statusDeferred.
  ///
  /// In en, this message translates to:
  /// **'Waiting for context'**
  String get statusDeferred;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get statusDeactivated;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super admin'**
  String get roleSuperAdmin;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @technicianRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Field Work & Interventions'**
  String get technicianRoleSubtitle;

  /// No description provided for @technicianAccess.
  ///
  /// In en, this message translates to:
  /// **'Technician Access'**
  String get technicianAccess;

  /// No description provided for @registerTechnicianDesc.
  ///
  /// In en, this message translates to:
  /// **'Register as a technician to carry out interventions in the field.'**
  String get registerTechnicianDesc;

  /// No description provided for @locBannerServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on this phone. Turn it on so your team can see where you are.'**
  String get locBannerServicesOff;

  /// No description provided for @locBannerDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location access so your team can see where you are while you work.'**
  String get locBannerDenied;

  /// No description provided for @locBannerBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Allow it in the app settings.'**
  String get locBannerBlocked;

  /// No description provided for @locActionTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get locActionTurnOn;

  /// No description provided for @locActionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get locActionAllow;

  /// No description provided for @locRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your location?'**
  String get locRationaleTitle;

  /// No description provided for @locRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'Vanakel Group shares your position with your team while you are working, also when the app is in the background. A notification is shown while it is active. You can turn it off at any time in the phone settings.'**
  String get locRationaleBody;

  /// No description provided for @locRationaleContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get locRationaleContinue;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @batteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep sharing in the background'**
  String get batteryTitle;

  /// No description provided for @batteryBody.
  ///
  /// In en, this message translates to:
  /// **'Some phones stop apps to save battery. Allow Vanakel Group to run without battery restrictions so live tracking is not interrupted.'**
  String get batteryBody;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @notifBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off: you will miss mission and intervention alerts.'**
  String get notifBlocked;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'No maps app could be opened on this phone.'**
  String get couldNotOpenMaps;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'This link could not be opened.'**
  String get couldNotOpenLink;

  /// No description provided for @reportSentTo.
  ///
  /// In en, this message translates to:
  /// **'Report sent to {count} recipient(s)'**
  String reportSentTo(int count);

  /// No description provided for @reportPartial.
  ///
  /// In en, this message translates to:
  /// **'Report sent to {sent} recipient(s), but {failed} could not be reached'**
  String reportPartial(int sent, int failed);

  /// No description provided for @reportNotSent.
  ///
  /// In en, this message translates to:
  /// **'The report could not be sent. The changes were saved. Please try again or tell the office.'**
  String get reportNotSent;
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
