import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('my'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Termux Command Library'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'A calm, curated library for Termux commands.'**
  String get appTagline;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @copyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy to the clipboard'**
  String get copyFailed;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

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

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only'**
  String get localOnly;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @welcomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your command library'**
  String get welcomeGreeting;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Discover practical Termux guides, keep the ones you love, and run them with a single confirmation.'**
  String get welcomeBody;

  /// No description provided for @welcomeFeatureOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline first'**
  String get welcomeFeatureOffline;

  /// No description provided for @welcomeFeatureOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Browse and keep commands even without a connection.'**
  String get welcomeFeatureOfflineBody;

  /// No description provided for @welcomeFeatureTermux.
  ///
  /// In en, this message translates to:
  /// **'Termux aware'**
  String get welcomeFeatureTermux;

  /// No description provided for @welcomeFeatureTermuxBody.
  ///
  /// In en, this message translates to:
  /// **'Copy safely or send commands to Termux with clear warnings.'**
  String get welcomeFeatureTermuxBody;

  /// No description provided for @welcomeFeatureAi.
  ///
  /// In en, this message translates to:
  /// **'Your own AI key'**
  String get welcomeFeatureAi;

  /// No description provided for @welcomeFeatureAiBody.
  ///
  /// In en, this message translates to:
  /// **'Optional Groq assistance stored securely on this device.'**
  String get welcomeFeatureAiBody;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off.'**
  String get signInSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Publish guides and sync your collection.'**
  String get createAccountSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithGithub.
  ///
  /// In en, this message translates to:
  /// **'Continue with GitHub'**
  String get continueWithGithub;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @providerSignInSlow.
  ///
  /// In en, this message translates to:
  /// **'Still waiting for the browser? Finish signing in there, or go back and try again.'**
  String get providerSignInSlow;

  /// No description provided for @githubDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub'**
  String get githubDeviceTitle;

  /// No description provided for @githubDeviceInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter this code on GitHub to finish signing in.'**
  String get githubDeviceInstructions;

  /// No description provided for @githubDeviceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign-in code'**
  String get githubDeviceCodeLabel;

  /// No description provided for @githubDeviceStarting.
  ///
  /// In en, this message translates to:
  /// **'Requesting a sign-in code…'**
  String get githubDeviceStarting;

  /// No description provided for @githubDeviceWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you to authorize on GitHub…'**
  String get githubDeviceWaiting;

  /// No description provided for @githubDeviceOpen.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub'**
  String get githubDeviceOpen;

  /// No description provided for @githubDeviceOpenManually.
  ///
  /// In en, this message translates to:
  /// **'If the browser did not open, visit github.com/login/device.'**
  String get githubDeviceOpenManually;

  /// No description provided for @githubDeviceOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the browser. Visit github.com/login/device manually.'**
  String get githubDeviceOpenFailed;

  /// No description provided for @githubDeviceCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get githubDeviceCopyCode;

  /// No description provided for @githubDeviceCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get githubDeviceCopied;

  /// No description provided for @githubDeviceExpired.
  ///
  /// In en, this message translates to:
  /// **'This code expired. Tap Try again for a new code.'**
  String get githubDeviceExpired;

  /// No description provided for @githubDeviceDisabled.
  ///
  /// In en, this message translates to:
  /// **'GitHub sign-in is not available. The app owner must enable Device Flow in the GitHub OAuth app.'**
  String get githubDeviceDisabled;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you or you@example.com'**
  String get emailHint;

  /// No description provided for @emailHelper.
  ///
  /// In en, this message translates to:
  /// **'A bare username becomes @gmail.com.'**
  String get emailHelper;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get passwordHelper;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordTooShort;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// No description provided for @passwordMedium.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordMedium;

  /// No description provided for @passwordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsMismatch;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'How others will see you'**
  String get nicknameHint;

  /// No description provided for @nicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a nickname.'**
  String get nicknameRequired;

  /// No description provided for @nicknameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 2 characters.'**
  String get nicknameTooShort;

  /// No description provided for @nicknameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use at most 40 characters.'**
  String get nicknameTooLong;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get chooseAvatar;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a secure reset link.'**
  String get resetPasswordBody;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for that address, a reset link is on its way.'**
  String get resetEmailSent;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your saved commands stay on this device. Cloud data will be available again the next time you sign in.'**
  String get signOutBody;

  /// No description provided for @signedOutLocally.
  ///
  /// In en, this message translates to:
  /// **'Signed out. You are browsing as a guest.'**
  String get signedOutLocally;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get updatePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @reauthenticateNeeded.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again before continuing.'**
  String get reauthenticateNeeded;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected accounts'**
  String get connectedAccounts;

  /// No description provided for @githubAccount.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get githubAccount;

  /// No description provided for @githubConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get githubConnectAction;

  /// No description provided for @githubConnectBody.
  ///
  /// In en, this message translates to:
  /// **'Connect GitHub without changing your UID, favorites or guides.'**
  String get githubConnectBody;

  /// No description provided for @githubConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Connected. You can sign in with GitHub as well as your current method.'**
  String get githubConnectedBody;

  /// No description provided for @githubLinkSuccess.
  ///
  /// In en, this message translates to:
  /// **'GitHub connected to your account.'**
  String get githubLinkSuccess;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This removes your account, your public guides and synced favorites. Local guest data on this device is not affected. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountConfirm;

  /// No description provided for @clearLocalData.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get clearLocalData;

  /// No description provided for @clearLocalDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local data?'**
  String get clearLocalDataTitle;

  /// No description provided for @clearLocalDataBody.
  ///
  /// In en, this message translates to:
  /// **'Cached community commands, AI history and local preferences will be removed from this device. Your cloud account and public guides are not deleted.'**
  String get clearLocalDataBody;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cached commands'**
  String get clearCache;

  /// No description provided for @clearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'Removes cached community commands while keeping your own guides, favorites and pins.'**
  String get clearCacheBody;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cached commands removed.'**
  String get cacheCleared;

  /// No description provided for @clearAiHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear AI history'**
  String get clearAiHistory;

  /// No description provided for @aiHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'AI history cleared.'**
  String get aiHistoryCleared;

  /// No description provided for @deleteLocalProfile.
  ///
  /// In en, this message translates to:
  /// **'Remove local profile'**
  String get deleteLocalProfile;

  /// No description provided for @guestDataNote.
  ///
  /// In en, this message translates to:
  /// **'Guest favorites and pins stay on this device.'**
  String get guestDataNote;

  /// No description provided for @guestSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your collection and publish guides.'**
  String get guestSignInHint;

  /// No description provided for @anonymousAccount.
  ///
  /// In en, this message translates to:
  /// **'Anonymous account'**
  String get anonymousAccount;

  /// No description provided for @anonymousExplanation.
  ///
  /// In en, this message translates to:
  /// **'You can save a temporary cloud account now and add an email later.'**
  String get anonymousExplanation;

  /// No description provided for @continueAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Continue anonymously'**
  String get continueAnonymously;

  /// No description provided for @upgradeAccount.
  ///
  /// In en, this message translates to:
  /// **'Add email to account'**
  String get upgradeAccount;

  /// No description provided for @upgradeAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your saved collection and turn this anonymous account into a registered one.'**
  String get upgradeAccountBody;

  /// No description provided for @accountUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Your account is now registered.'**
  String get accountUpgraded;

  /// No description provided for @linkGuestData.
  ///
  /// In en, this message translates to:
  /// **'Import guest favorites?'**
  String get linkGuestData;

  /// No description provided for @linkGuestDataBody.
  ///
  /// In en, this message translates to:
  /// **'Copy the favorites and pins saved in guest mode into this account. Guest data is then removed from this device.'**
  String get linkGuestDataBody;

  /// No description provided for @importGuestData.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importGuestData;

  /// No description provided for @guestDataImported.
  ///
  /// In en, this message translates to:
  /// **'Guest collection imported.'**
  String get guestDataImported;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @guestModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Guest mode · favorites are local to this device'**
  String get guestModeBanner;

  /// No description provided for @createAccountToPublish.
  ///
  /// In en, this message translates to:
  /// **'Create an account to publish guides.'**
  String get createAccountToPublish;

  /// No description provided for @guestCannotPublish.
  ///
  /// In en, this message translates to:
  /// **'Guests can browse and save commands. Sign in to publish.'**
  String get guestCannotPublish;

  /// No description provided for @cloudUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud features are not configured'**
  String get cloudUnavailableTitle;

  /// No description provided for @cloudUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The app is running in local-only mode. Browsing, favorites, pins, Termux and AI still work. Add Firebase configuration (android/app/google-services.json) and rebuild to enable accounts and publishing.'**
  String get cloudUnavailableBody;

  /// No description provided for @firebaseSetupDocs.
  ///
  /// In en, this message translates to:
  /// **'Firebase setup guide'**
  String get firebaseSetupDocs;

  /// No description provided for @cloudError.
  ///
  /// In en, this message translates to:
  /// **'Cloud connection problem'**
  String get cloudError;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count} change(s) waiting to sync'**
  String syncPending(int count);

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncComplete;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved locally'**
  String get syncLocalOnly;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync interrupted. Local data is safe.'**
  String get syncError;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String lastSynced(String time);

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What will you build in Termux today?'**
  String get homeSubtitle;

  /// No description provided for @browseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Browse library'**
  String get browseLibrary;

  /// No description provided for @searchCommands.
  ///
  /// In en, this message translates to:
  /// **'Search commands, tags or tools'**
  String get searchCommands;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @exploreCategories.
  ///
  /// In en, this message translates to:
  /// **'Explore categories'**
  String get exploreCategories;

  /// No description provided for @pinnedCommands.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedCommands;

  /// No description provided for @recentCommands.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get recentCommands;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @yourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get yourLibrary;

  /// No description provided for @totalCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get totalCommands;

  /// No description provided for @favoritesCount.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesCount;

  /// No description provided for @pinsCount.
  ///
  /// In en, this message translates to:
  /// **'Pins'**
  String get pinsCount;

  /// No description provided for @myPostsCount.
  ///
  /// In en, this message translates to:
  /// **'My guides'**
  String get myPostsCount;

  /// No description provided for @communityLibrary.
  ///
  /// In en, this message translates to:
  /// **'Community library'**
  String get communityLibrary;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search and filter the local library.'**
  String get librarySubtitle;

  /// No description provided for @allCommands.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCommands;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get myPosts;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @sortRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get sortRecentlyUpdated;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get sortNameAsc;

  /// No description provided for @sortMostSteps.
  ///
  /// In en, this message translates to:
  /// **'Most steps'**
  String get sortMostSteps;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters active'**
  String get activeFilters;

  /// No description provided for @searchResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Results for \"{query}\"'**
  String searchResultsFor(String query);

  /// No description provided for @noCommandsTitle.
  ///
  /// In en, this message translates to:
  /// **'No commands yet'**
  String get noCommandsTitle;

  /// No description provided for @noCommandsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or clear the filters.'**
  String get noCommandsBody;

  /// No description provided for @emptyFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get emptyFavoritesTitle;

  /// No description provided for @emptyFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Save the commands you reach for often and they will appear here.'**
  String get emptyFavoritesBody;

  /// No description provided for @emptyPinsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing pinned'**
  String get emptyPinsTitle;

  /// No description provided for @emptyPinsBody.
  ///
  /// In en, this message translates to:
  /// **'Pin a command to keep it within easy reach.'**
  String get emptyPinsBody;

  /// No description provided for @emptyMineTitle.
  ///
  /// In en, this message translates to:
  /// **'You have not published anything yet'**
  String get emptyMineTitle;

  /// No description provided for @emptyMineBody.
  ///
  /// In en, this message translates to:
  /// **'Share a guide with the community whenever you are ready.'**
  String get emptyMineBody;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @endOfResults.
  ///
  /// In en, this message translates to:
  /// **'You have reached the end.'**
  String get endOfResults;

  /// No description provided for @stepCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String stepCount(int count);

  /// No description provided for @updatedTime.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String updatedTime(String time);

  /// No description provided for @byAuthor.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byAuthor(String name);

  /// No description provided for @pendingSyncBadge.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get pendingSyncBadge;

  /// No description provided for @seedBadge.
  ///
  /// In en, this message translates to:
  /// **'Curated'**
  String get seedBadge;

  /// No description provided for @draftBadge.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftBadge;

  /// No description provided for @commandDetails.
  ///
  /// In en, this message translates to:
  /// **'Command details'**
  String get commandDetails;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @commandsTab.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get commandsTab;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @metadata.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get metadata;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @pinCommand.
  ///
  /// In en, this message translates to:
  /// **'Pin command'**
  String get pinCommand;

  /// No description provided for @unpinCommand.
  ///
  /// In en, this message translates to:
  /// **'Unpin command'**
  String get unpinCommand;

  /// No description provided for @pinnedSnack.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinnedSnack;

  /// No description provided for @unpinnedSnack.
  ///
  /// In en, this message translates to:
  /// **'Unpinned'**
  String get unpinnedSnack;

  /// No description provided for @favoritedSnack.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoritedSnack;

  /// No description provided for @unfavoritedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get unfavoritedSnack;

  /// No description provided for @copyAllCommands.
  ///
  /// In en, this message translates to:
  /// **'Copy all commands'**
  String get copyAllCommands;

  /// No description provided for @runAllCommands.
  ///
  /// In en, this message translates to:
  /// **'Run all in Termux'**
  String get runAllCommands;

  /// No description provided for @copyStep.
  ///
  /// In en, this message translates to:
  /// **'Copy step'**
  String get copyStep;

  /// No description provided for @runStep.
  ///
  /// In en, this message translates to:
  /// **'Run step'**
  String get runStep;

  /// No description provided for @stepNumber.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String stepNumber(int number);

  /// No description provided for @runConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Send to Termux?'**
  String get runConfirmationTitle;

  /// No description provided for @runConfirmationBody.
  ///
  /// In en, this message translates to:
  /// **'Termux will run this command in a new session. Review it first. The app will report that the command was sent, not whether it finished.'**
  String get runConfirmationBody;

  /// No description provided for @runBackground.
  ///
  /// In en, this message translates to:
  /// **'Run in the background'**
  String get runBackground;

  /// No description provided for @runBackgroundHelper.
  ///
  /// In en, this message translates to:
  /// **'Background commands have no visible terminal output.'**
  String get runBackgroundHelper;

  /// No description provided for @termuxKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep terminal open'**
  String get termuxKeepOpen;

  /// No description provided for @termuxKeepOpenHelper.
  ///
  /// In en, this message translates to:
  /// **'Keeps the session open after the command finishes so you can read its output. Press Enter in Termux to close it.'**
  String get termuxKeepOpenHelper;

  /// No description provided for @termuxKeepOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Command finished. Press Enter to close this session.'**
  String get termuxKeepOpenHint;

  /// No description provided for @runForeground.
  ///
  /// In en, this message translates to:
  /// **'Open in Termux'**
  String get runForeground;

  /// No description provided for @confirmRun.
  ///
  /// In en, this message translates to:
  /// **'Send command'**
  String get confirmRun;

  /// No description provided for @commandSentToTermux.
  ///
  /// In en, this message translates to:
  /// **'Command sent to Termux.'**
  String get commandSentToTermux;

  /// No description provided for @commandNotRun.
  ///
  /// In en, this message translates to:
  /// **'No command was sent.'**
  String get commandNotRun;

  /// No description provided for @runViaTermux.
  ///
  /// In en, this message translates to:
  /// **'Run via Termux'**
  String get runViaTermux;

  /// No description provided for @copyInstead.
  ///
  /// In en, this message translates to:
  /// **'Copy instead'**
  String get copyInstead;

  /// No description provided for @termuxMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Termux is not installed'**
  String get termuxMissingTitle;

  /// No description provided for @termuxMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Install Termux from the official GitHub releases. Play Store builds are outdated and do not support this integration.'**
  String get termuxMissingBody;

  /// No description provided for @termuxPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Termux permission required'**
  String get termuxPermissionTitle;

  /// No description provided for @termuxPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Termux command execution for this app. Android will ask for the RUN_COMMAND permission.'**
  String get termuxPermissionBody;

  /// No description provided for @termuxExternalAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable external commands in Termux'**
  String get termuxExternalAppsTitle;

  /// No description provided for @termuxExternalAppsBody.
  ///
  /// In en, this message translates to:
  /// **'Open Termux and add this line to ~/.termux/termux.properties:\n\nallow-external-apps=true\n\nThen run termux-reload-settings or restart Termux.'**
  String get termuxExternalAppsBody;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermission;

  /// No description provided for @openTermux.
  ///
  /// In en, this message translates to:
  /// **'Open Termux'**
  String get openTermux;

  /// No description provided for @getTermux.
  ///
  /// In en, this message translates to:
  /// **'Get Termux'**
  String get getTermux;

  /// No description provided for @termuxGuide.
  ///
  /// In en, this message translates to:
  /// **'Termux setup guide'**
  String get termuxGuide;

  /// No description provided for @termuxGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'This app sends commands to Termux. It is not a terminal emulator and cannot run commands by itself.'**
  String get termuxGuideIntro;

  /// No description provided for @termuxGuideButtons.
  ///
  /// In en, this message translates to:
  /// **'Use Run via Termux on a step, or Run all in Termux on a guide. Every command is shown for confirmation before it is sent.'**
  String get termuxGuideButtons;

  /// No description provided for @termuxStepInstall.
  ///
  /// In en, this message translates to:
  /// **'Install the official Termux release (GitHub, F-Droid or a trusted mirror).'**
  String get termuxStepInstall;

  /// No description provided for @termuxStepPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant the RUN_COMMAND permission when Android asks.'**
  String get termuxStepPermission;

  /// No description provided for @termuxStepExternal.
  ///
  /// In en, this message translates to:
  /// **'Set allow-external-apps=true in ~/.termux/termux.properties.'**
  String get termuxStepExternal;

  /// No description provided for @termuxStepReload.
  ///
  /// In en, this message translates to:
  /// **'Run termux-reload-settings or restart Termux.'**
  String get termuxStepReload;

  /// No description provided for @termuxStepOverlay.
  ///
  /// In en, this message translates to:
  /// **'Allow Termux to open sessions from the background.'**
  String get termuxStepOverlay;

  /// No description provided for @termuxOverlayBody.
  ///
  /// In en, this message translates to:
  /// **'Android 10 and later blocks Termux from opening a terminal session while this app is in front unless Termux can display over other apps. Grant the permission once; background runs do not need it.'**
  String get termuxOverlayBody;

  /// No description provided for @termuxOverlayGrant.
  ///
  /// In en, this message translates to:
  /// **'Open Termux display settings'**
  String get termuxOverlayGrant;

  /// No description provided for @termuxOverlayPill.
  ///
  /// In en, this message translates to:
  /// **'Display over apps'**
  String get termuxOverlayPill;

  /// No description provided for @termuxOverlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Termux needs display permission'**
  String get termuxOverlayTitle;

  /// No description provided for @termuxOverlayRunBody.
  ///
  /// In en, this message translates to:
  /// **'Android 10 and later requires the \"Display over other apps\" permission for Termux to open a terminal session while this app is in front. Grant it in Termux\'s Android settings, or turn on Run in the background in the confirmation sheet.'**
  String get termuxOverlayRunBody;

  /// No description provided for @termuxTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test the connection'**
  String get termuxTestTitle;

  /// No description provided for @termuxTestBody.
  ///
  /// In en, this message translates to:
  /// **'Send a harmless echo command and confirm that output appears in Termux.'**
  String get termuxTestBody;

  /// No description provided for @termuxTestButton.
  ///
  /// In en, this message translates to:
  /// **'Send test command'**
  String get termuxTestButton;

  /// No description provided for @termuxStepApi.
  ///
  /// In en, this message translates to:
  /// **'Install Termux:API for built-in commands (optional).'**
  String get termuxStepApi;

  /// No description provided for @termuxApiStepBody.
  ///
  /// In en, this message translates to:
  /// **'Some guides use termux-* commands such as termux-battery-status or termux-toast. They need two separate parts:'**
  String get termuxApiStepBody;

  /// No description provided for @termuxApiApk.
  ///
  /// In en, this message translates to:
  /// **'1. The Termux:API APK (adds the Android side).'**
  String get termuxApiApk;

  /// No description provided for @termuxApiPackage.
  ///
  /// In en, this message translates to:
  /// **'2. The termux-api package inside Termux (adds the commands):'**
  String get termuxApiPackage;

  /// No description provided for @termuxApiSameSource.
  ///
  /// In en, this message translates to:
  /// **'Install Termux and Termux:API from the same source. GitHub and F-Droid builds use different signing keys, so switching sources requires uninstalling every Termux app and plugin.'**
  String get termuxApiSameSource;

  /// No description provided for @termuxStatusNote.
  ///
  /// In en, this message translates to:
  /// **'Status reflects installed apps and Android permissions. Packages installed inside Termux are not visible to this app.'**
  String get termuxStatusNote;

  /// No description provided for @termuxApiTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Termux:API'**
  String get termuxApiTestTitle;

  /// No description provided for @termuxApiTestBody.
  ///
  /// In en, this message translates to:
  /// **'Send a harmless toast. If nothing appears, the APK, the package or an Android permission is missing.'**
  String get termuxApiTestBody;

  /// No description provided for @termuxApiTestButton.
  ///
  /// In en, this message translates to:
  /// **'Send API test'**
  String get termuxApiTestButton;

  /// No description provided for @termuxApiNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Termux:API commands'**
  String get termuxApiNoteTitle;

  /// No description provided for @termuxApiConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'This guide uses termux-* commands. They only work when the Termux:API APK and the termux-api package are both installed.'**
  String get termuxApiConfirmNote;

  /// No description provided for @termuxApiMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Termux:API is required'**
  String get termuxApiMissingTitle;

  /// No description provided for @termuxApiMissingBody.
  ///
  /// In en, this message translates to:
  /// **'This command uses a built-in termux-* command. Install the Termux:API APK, then run pkg install termux-api inside Termux. Both parts are required.'**
  String get termuxApiMissingBody;

  /// No description provided for @termuxApiGuide.
  ///
  /// In en, this message translates to:
  /// **'Get Termux:API'**
  String get termuxApiGuide;

  /// No description provided for @termuxApiSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Termux:API settings'**
  String get termuxApiSettings;

  /// No description provided for @termuxApiNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Termux:API is not installed.'**
  String get termuxApiNotInstalled;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission granted'**
  String get permissionGranted;

  /// No description provided for @permissionGrantedSnack.
  ///
  /// In en, this message translates to:
  /// **'RUN_COMMAND permission granted.'**
  String get permissionGrantedSnack;

  /// No description provided for @riskWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'This command can be destructive'**
  String get riskWarningTitle;

  /// No description provided for @riskWarningBody.
  ///
  /// In en, this message translates to:
  /// **'Review every line carefully. Termux runs with your user permissions, but some commands can still erase files or change your device.'**
  String get riskWarningBody;

  /// No description provided for @riskMedium.
  ///
  /// In en, this message translates to:
  /// **'Use with care'**
  String get riskMedium;

  /// No description provided for @riskHigh.
  ///
  /// In en, this message translates to:
  /// **'High risk'**
  String get riskHigh;

  /// No description provided for @riskRecursiveRootDelete.
  ///
  /// In en, this message translates to:
  /// **'Recursive deletion at a filesystem root'**
  String get riskRecursiveRootDelete;

  /// No description provided for @riskHomeDelete.
  ///
  /// In en, this message translates to:
  /// **'Deletion in your home directory'**
  String get riskHomeDelete;

  /// No description provided for @riskFilesystemFormat.
  ///
  /// In en, this message translates to:
  /// **'Formats or wipes a filesystem'**
  String get riskFilesystemFormat;

  /// No description provided for @riskRawDiskWrite.
  ///
  /// In en, this message translates to:
  /// **'Writes directly to a disk device'**
  String get riskRawDiskWrite;

  /// No description provided for @riskSystemPermissionChange.
  ///
  /// In en, this message translates to:
  /// **'Changes permissions broadly'**
  String get riskSystemPermissionChange;

  /// No description provided for @riskForkBomb.
  ///
  /// In en, this message translates to:
  /// **'Fork bomb pattern'**
  String get riskForkBomb;

  /// No description provided for @riskSystemPower.
  ///
  /// In en, this message translates to:
  /// **'Shuts down or restarts the system'**
  String get riskSystemPower;

  /// No description provided for @riskPipeDownloadToShell.
  ///
  /// In en, this message translates to:
  /// **'Pipes downloaded content into a shell'**
  String get riskPipeDownloadToShell;

  /// No description provided for @riskDestructiveGitClean.
  ///
  /// In en, this message translates to:
  /// **'Discards uncommitted Git changes'**
  String get riskDestructiveGitClean;

  /// No description provided for @riskPackageRemoval.
  ///
  /// In en, this message translates to:
  /// **'Removes installed packages'**
  String get riskPackageRemoval;

  /// No description provided for @riskPrivilegeEscalation.
  ///
  /// In en, this message translates to:
  /// **'Requests elevated privileges'**
  String get riskPrivilegeEscalation;

  /// No description provided for @riskForceKill.
  ///
  /// In en, this message translates to:
  /// **'Force-kills processes'**
  String get riskForceKill;

  /// No description provided for @riskAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand the risk'**
  String get riskAcknowledge;

  /// No description provided for @newCommand.
  ///
  /// In en, this message translates to:
  /// **'New command'**
  String get newCommand;

  /// No description provided for @editCommand.
  ///
  /// In en, this message translates to:
  /// **'Edit command'**
  String get editCommand;

  /// No description provided for @uploadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share a clear, useful guide with the community.'**
  String get uploadSubtitle;

  /// No description provided for @basics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get basics;

  /// No description provided for @commandName.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commandName;

  /// No description provided for @commandNameHint.
  ///
  /// In en, this message translates to:
  /// **'Create a Python virtual environment'**
  String get commandNameHint;

  /// No description provided for @commandNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give your guide a title.'**
  String get commandNameRequired;

  /// No description provided for @commandNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 2 characters.'**
  String get commandNameTooShort;

  /// No description provided for @commandNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Use at most 100 characters.'**
  String get commandNameTooLong;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Explain what this guide does and when to use it.'**
  String get descriptionHint;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a short description.'**
  String get descriptionRequired;

  /// No description provided for @descriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Description is too long.'**
  String get descriptionTooLong;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a category.'**
  String get categoryRequired;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'Add tags, separated by commas'**
  String get tagsHint;

  /// No description provided for @tagsHelper.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 tags. Useful for tools and tasks.'**
  String get tagsHelper;

  /// No description provided for @stepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Command steps'**
  String get stepsTitle;

  /// No description provided for @stepsHelper.
  ///
  /// In en, this message translates to:
  /// **'Steps run in order. Commands are stored exactly as written.'**
  String get stepsHelper;

  /// No description provided for @addStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get addStep;

  /// No description provided for @removeStep.
  ///
  /// In en, this message translates to:
  /// **'Remove step'**
  String get removeStep;

  /// No description provided for @newStep.
  ///
  /// In en, this message translates to:
  /// **'New step'**
  String get newStep;

  /// No description provided for @stepTitle.
  ///
  /// In en, this message translates to:
  /// **'Step title'**
  String get stepTitle;

  /// No description provided for @stepTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Update packages'**
  String get stepTitleHint;

  /// No description provided for @stepTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Give this step a title.'**
  String get stepTitleRequired;

  /// No description provided for @stepCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get stepCommand;

  /// No description provided for @stepCommandHint.
  ///
  /// In en, this message translates to:
  /// **'pkg update && pkg upgrade -y'**
  String get stepCommandHint;

  /// No description provided for @stepCommandRequired.
  ///
  /// In en, this message translates to:
  /// **'The command cannot be empty.'**
  String get stepCommandRequired;

  /// No description provided for @stepDescription.
  ///
  /// In en, this message translates to:
  /// **'Step note'**
  String get stepDescription;

  /// No description provided for @stepDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Anything the reader should know before running this.'**
  String get stepDescriptionHint;

  /// No description provided for @runMode.
  ///
  /// In en, this message translates to:
  /// **'Run mode'**
  String get runMode;

  /// No description provided for @runModeForeground.
  ///
  /// In en, this message translates to:
  /// **'Open in Termux'**
  String get runModeForeground;

  /// No description provided for @runModeBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get runModeBackground;

  /// No description provided for @stepLimit.
  ///
  /// In en, this message translates to:
  /// **'A guide can contain at most 30 steps.'**
  String get stepLimit;

  /// No description provided for @atLeastOneStep.
  ///
  /// In en, this message translates to:
  /// **'Add at least one command step.'**
  String get atLeastOneStep;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @publishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Publish this guide?'**
  String get publishConfirm;

  /// No description provided for @publishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Published guides are visible to everyone and can only be edited by you or an admin.'**
  String get publishConfirmBody;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Guide published.'**
  String get published;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get draftSaved;

  /// No description provided for @guideSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved.'**
  String get guideSaved;

  /// No description provided for @deleteCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this guide?'**
  String get deleteCommandTitle;

  /// No description provided for @deleteCommandBody.
  ///
  /// In en, this message translates to:
  /// **'The guide will be removed from the library. This cannot be undone.'**
  String get deleteCommandBody;

  /// No description provided for @commandDeleted.
  ///
  /// In en, this message translates to:
  /// **'Guide deleted.'**
  String get commandDeleted;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits to this guide have not been saved.'**
  String get discardChangesBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @aiAssist.
  ///
  /// In en, this message translates to:
  /// **'AI assist'**
  String get aiAssist;

  /// No description provided for @aiAssistTitle.
  ///
  /// In en, this message translates to:
  /// **'Write with AI'**
  String get aiAssistTitle;

  /// No description provided for @generateTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggest a title'**
  String get generateTitle;

  /// No description provided for @rewriteDescription.
  ///
  /// In en, this message translates to:
  /// **'Improve description'**
  String get rewriteDescription;

  /// No description provided for @reviewCommand.
  ///
  /// In en, this message translates to:
  /// **'Review command'**
  String get reviewCommand;

  /// No description provided for @explainCommand.
  ///
  /// In en, this message translates to:
  /// **'Explain command'**
  String get explainCommand;

  /// No description provided for @translateToMyanmar.
  ///
  /// In en, this message translates to:
  /// **'Translate to Myanmar'**
  String get translateToMyanmar;

  /// No description provided for @translateToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Translate to English'**
  String get translateToEnglish;

  /// No description provided for @aiAssistApplied.
  ///
  /// In en, this message translates to:
  /// **'Suggestion applied.'**
  String get aiAssistApplied;

  /// No description provided for @aiNoProviderConfigured.
  ///
  /// In en, this message translates to:
  /// **'Set up your Groq API key in AI settings first.'**
  String get aiNoProviderConfigured;

  /// No description provided for @openAiSettings.
  ///
  /// In en, this message translates to:
  /// **'Open AI settings'**
  String get openAiSettings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get role;

  /// No description provided for @refreshRole.
  ///
  /// In en, this message translates to:
  /// **'Refresh account type'**
  String get refreshRole;

  /// No description provided for @refreshRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Reload your saved role from Firebase.'**
  String get refreshRoleBody;

  /// No description provided for @roleRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Account type refreshed.'**
  String get roleRefreshed;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @myGuides.
  ///
  /// In en, this message translates to:
  /// **'My guides'**
  String get myGuides;

  /// No description provided for @myCollection.
  ///
  /// In en, this message translates to:
  /// **'My collection'**
  String get myCollection;

  /// No description provided for @accountAndSync.
  ///
  /// In en, this message translates to:
  /// **'Account & sync'**
  String get accountAndSync;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make the library feel like yours.'**
  String get settingsSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @accentIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get accentIndigo;

  /// No description provided for @accentTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get accentTeal;

  /// No description provided for @accentRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get accentRose;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// No description provided for @accentViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get accentViolet;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentCyan.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get accentCyan;

  /// No description provided for @accentCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get accentCoral;

  /// No description provided for @accentLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get accentLime;

  /// No description provided for @accentFuchsia.
  ///
  /// In en, this message translates to:
  /// **'Fuchsia'**
  String get accentFuchsia;

  /// No description provided for @accentSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get accentSlate;

  /// No description provided for @wallpaperColors.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper colors'**
  String get wallpaperColors;

  /// No description provided for @wallpaperColorsHelper.
  ///
  /// In en, this message translates to:
  /// **'Use colors from your home screen wallpaper. Choosing a palette below turns this off.'**
  String get wallpaperColorsHelper;

  /// No description provided for @typography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get typography;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get fontFamily;

  /// No description provided for @fontSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get fontSystem;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get fontSize;

  /// No description provided for @fontSizePreview.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog. မြန်မာစာသားကို ဖတ်ရှုရလွယ်ကူပါစေ။'**
  String get fontSizePreview;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMyanmar.
  ///
  /// In en, this message translates to:
  /// **'မြန်မာ'**
  String get languageMyanmar;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effects;

  /// No description provided for @blurEffects.
  ///
  /// In en, this message translates to:
  /// **'Frosted glass'**
  String get blurEffects;

  /// No description provided for @blurEffectsHelper.
  ///
  /// In en, this message translates to:
  /// **'Subtle blur behind surfaces such as the navigation bar.'**
  String get blurEffectsHelper;

  /// No description provided for @blurIntensity.
  ///
  /// In en, this message translates to:
  /// **'Blur intensity'**
  String get blurIntensity;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @vibrationIntensity.
  ///
  /// In en, this message translates to:
  /// **'Vibration intensity'**
  String get vibrationIntensity;

  /// No description provided for @vibrationOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get vibrationOff;

  /// No description provided for @vibrationLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get vibrationLight;

  /// No description provided for @vibrationMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get vibrationMedium;

  /// No description provided for @vibrationStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get vibrationStrong;

  /// No description provided for @vibrationPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a level to preview it. Selection, success and warning cues each use a distinct rhythm.'**
  String get vibrationPreviewHint;

  /// No description provided for @dataAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & storage'**
  String get dataAndStorage;

  /// No description provided for @localDatabase.
  ///
  /// In en, this message translates to:
  /// **'Local database'**
  String get localDatabase;

  /// No description provided for @localDatabaseBody.
  ///
  /// In en, this message translates to:
  /// **'Commands, favorites and AI history are stored on this device with SQLite.'**
  String get localDatabaseBody;

  /// No description provided for @refreshLibrary.
  ///
  /// In en, this message translates to:
  /// **'Refresh community library'**
  String get refreshLibrary;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get refreshing;

  /// No description provided for @refreshed.
  ///
  /// In en, this message translates to:
  /// **'Library refreshed.'**
  String get refreshed;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Approximate local usage'**
  String get storageUsed;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your Groq key stays in secure device storage. Commands and AI history are local by default. Firebase is used only for accounts and the public library.'**
  String get privacyBody;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// No description provided for @openSource.
  ///
  /// In en, this message translates to:
  /// **'Open source'**
  String get openSource;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get licenses;

  /// No description provided for @developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer details'**
  String get developerMode;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A command-aware helper powered by your own key.'**
  String get aiAssistantSubtitle;

  /// No description provided for @aiWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about anything in Termux'**
  String get aiWelcomeTitle;

  /// No description provided for @aiWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Explain a command, plan a workflow, or translate a guide. Your API key is stored on this device.'**
  String get aiWelcomeBody;

  /// No description provided for @aiDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'AI is off'**
  String get aiDisabledTitle;

  /// No description provided for @aiDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Add a Groq API key to enable the assistant. You control the key, model and history.'**
  String get aiDisabledBody;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI settings'**
  String get aiSettings;

  /// No description provided for @aiSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your API key and model'**
  String get aiSettingsSubtitle;

  /// No description provided for @aiEnabled.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get aiEnabled;

  /// No description provided for @aiEnabledHelper.
  ///
  /// In en, this message translates to:
  /// **'Turns on chat and writing assistance.'**
  String get aiEnabledHelper;

  /// No description provided for @aiProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get aiProvider;

  /// No description provided for @aiProviderGroq.
  ///
  /// In en, this message translates to:
  /// **'Groq'**
  String get aiProviderGroq;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @apiKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'Stored with Android secure storage. It is never sent to Firebase.'**
  String get apiKeyHelper;

  /// No description provided for @getApiKey.
  ///
  /// In en, this message translates to:
  /// **'Get a key'**
  String get getApiKey;

  /// No description provided for @testKey.
  ///
  /// In en, this message translates to:
  /// **'Test key'**
  String get testKey;

  /// No description provided for @keyWorks.
  ///
  /// In en, this message translates to:
  /// **'Key verified.'**
  String get keyWorks;

  /// No description provided for @keyMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter an API key first.'**
  String get keyMissing;

  /// No description provided for @keyInvalid.
  ///
  /// In en, this message translates to:
  /// **'This key was rejected. Check it and try again.'**
  String get keyInvalid;

  /// No description provided for @keySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved securely.'**
  String get keySaved;

  /// No description provided for @fetchModels.
  ///
  /// In en, this message translates to:
  /// **'Fetch available models'**
  String get fetchModels;

  /// No description provided for @modelsFetched.
  ///
  /// In en, this message translates to:
  /// **'Models refreshed.'**
  String get modelsFetched;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select model'**
  String get selectModel;

  /// No description provided for @selectedModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get selectedModel;

  /// No description provided for @noModels.
  ///
  /// In en, this message translates to:
  /// **'No models available. Test your key and fetch models again.'**
  String get noModels;

  /// No description provided for @modelContext.
  ///
  /// In en, this message translates to:
  /// **'{tokens} context'**
  String modelContext(String tokens);

  /// No description provided for @cacheDuration.
  ///
  /// In en, this message translates to:
  /// **'Response cache'**
  String get cacheDuration;

  /// No description provided for @cacheDurationHelper.
  ///
  /// In en, this message translates to:
  /// **'Reuse identical requests to save tokens.'**
  String get cacheDurationHelper;

  /// No description provided for @cacheOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get cacheOff;

  /// No description provided for @cacheHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String cacheHours(int count);

  /// No description provided for @clearAiCache.
  ///
  /// In en, this message translates to:
  /// **'Clear AI cache'**
  String get clearAiCache;

  /// No description provided for @aiCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'AI cache cleared.'**
  String get aiCacheCleared;

  /// No description provided for @aiSetupGuideBody.
  ///
  /// In en, this message translates to:
  /// **'Open console.groq.com, sign in, create an API key, and paste it here. Keys start with gsk_. Billing and rate limits belong to your Groq account.'**
  String get aiSetupGuideBody;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant'**
  String get askAi;

  /// No description provided for @askAiHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about a command, error or workflow…'**
  String get askAiHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @stopGenerating.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopGenerating;

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinking;

  /// No description provided for @aiError.
  ///
  /// In en, this message translates to:
  /// **'The assistant could not answer'**
  String get aiError;

  /// No description provided for @aiEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start with a question about Termux.'**
  String get aiEmpty;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get suggestions;

  /// No description provided for @suggestionExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain pkg update in plain language'**
  String get suggestionExplain;

  /// No description provided for @suggestionScript.
  ///
  /// In en, this message translates to:
  /// **'Help me write a backup script'**
  String get suggestionScript;

  /// No description provided for @suggestionFix.
  ///
  /// In en, this message translates to:
  /// **'Why did my apt command fail?'**
  String get suggestionFix;

  /// No description provided for @suggestionTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate this guide to Myanmar'**
  String get suggestionTranslate;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get chatHistory;

  /// No description provided for @searchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get searchHistory;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteConversation;

  /// No description provided for @deleteConversationBody.
  ///
  /// In en, this message translates to:
  /// **'This chat will be removed from this device.'**
  String get deleteConversationBody;

  /// No description provided for @conversationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted.'**
  String get conversationDeleted;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversations;

  /// No description provided for @noConversationsBody.
  ///
  /// In en, this message translates to:
  /// **'Your command questions and answers will be saved here.'**
  String get noConversationsBody;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach text file'**
  String get attachFile;

  /// No description provided for @attachmentHelp.
  ///
  /// In en, this message translates to:
  /// **'TXT, MD, SH, PY or LOG, up to 256 KB.'**
  String get attachmentHelp;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is larger than 256 KB.'**
  String get attachmentTooLarge;

  /// No description provided for @attachmentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Only TXT, MD, SH, PY and LOG files are supported.'**
  String get attachmentUnsupported;

  /// No description provided for @attachmentAdded.
  ///
  /// In en, this message translates to:
  /// **'File attached'**
  String get attachmentAdded;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @attachmentNotice.
  ///
  /// In en, this message translates to:
  /// **'The file contents will be sent to your AI provider when you send this message.'**
  String get attachmentNotice;

  /// No description provided for @aiPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Messages are sent to Groq using your key. History and cache stay on this device.'**
  String get aiPrivacyNote;

  /// No description provided for @aiHistory.
  ///
  /// In en, this message translates to:
  /// **'AI history'**
  String get aiHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation history'**
  String get clearHistory;

  /// No description provided for @clearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'All saved conversations on this device will be deleted. API keys and commands are not affected.'**
  String get clearHistoryBody;

  /// No description provided for @copyResponse.
  ///
  /// In en, this message translates to:
  /// **'Copy answer'**
  String get copyResponse;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @tokensUsed.
  ///
  /// In en, this message translates to:
  /// **'{count} tokens'**
  String tokensUsed(String count);

  /// No description provided for @contextPinned.
  ///
  /// In en, this message translates to:
  /// **'Using: {title}'**
  String contextPinned(String title);

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'That took too long. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue.'**
  String get errorAuthRequired;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password (at least 8 characters).'**
  String get errorWeakPassword;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errorTooManyRequests;

  /// No description provided for @errorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to confirm this change.'**
  String get errorRecentLogin;

  /// No description provided for @errorAuthCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get errorAuthCancelled;

  /// No description provided for @errorAuthProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled for this app yet.'**
  String get errorAuthProviderUnavailable;

  /// No description provided for @errorProviderAccountExists.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email. Sign in with the method you used before, then connect GitHub from Account settings.'**
  String get errorProviderAccountExists;

  /// No description provided for @errorProviderAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is already connected to your account.'**
  String get errorProviderAlreadyLinked;

  /// No description provided for @errorProviderLinkedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This GitHub account is already linked to a different account. Sign in to that account instead.'**
  String get errorProviderLinkedElsewhere;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Firestore denied this action. Check the security rules.'**
  String get errorPermissionDenied;

  /// No description provided for @errorFirebaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Firebase is unavailable right now.'**
  String get errorFirebaseUnavailable;

  /// No description provided for @errorFirebaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase is not configured in this build.'**
  String get errorFirebaseNotConfigured;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields.'**
  String get errorValidation;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That item no longer exists.'**
  String get errorNotFound;

  /// No description provided for @errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'The local database could not complete that action.'**
  String get errorDatabase;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'The item changed elsewhere. Refresh and try again.'**
  String get errorConflict;

  /// No description provided for @errorLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You reached the limit for this item.'**
  String get errorLimitReached;

  /// No description provided for @errorAiDisabled.
  ///
  /// In en, this message translates to:
  /// **'AI is disabled.'**
  String get errorAiDisabled;

  /// No description provided for @errorAiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Add your Groq API key first.'**
  String get errorAiKeyMissing;

  /// No description provided for @errorAiInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'Groq rejected the API key.'**
  String get errorAiInvalidKey;

  /// No description provided for @errorAiRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Groq rate limit reached. Wait a moment or check your plan.'**
  String get errorAiRateLimited;

  /// No description provided for @errorAiProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The AI provider is unavailable. Try again shortly.'**
  String get errorAiProviderUnavailable;

  /// No description provided for @errorAiModelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That model is not available. Choose another model.'**
  String get errorAiModelUnavailable;

  /// No description provided for @errorAiRequestTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This request is too large. Remove the attachment or shorten the prompt.'**
  String get errorAiRequestTooLarge;

  /// No description provided for @errorAiEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'The model returned an empty answer.'**
  String get errorAiEmptyResponse;

  /// No description provided for @errorAiCancelled.
  ///
  /// In en, this message translates to:
  /// **'Generation stopped.'**
  String get errorAiCancelled;

  /// No description provided for @errorTermuxMissing.
  ///
  /// In en, this message translates to:
  /// **'Termux is not installed.'**
  String get errorTermuxMissing;

  /// No description provided for @errorTermuxPermission.
  ///
  /// In en, this message translates to:
  /// **'The Termux RUN_COMMAND permission has not been granted.'**
  String get errorTermuxPermission;

  /// No description provided for @errorTermuxExternalApps.
  ///
  /// In en, this message translates to:
  /// **'Enable allow-external-apps in Termux, then retry.'**
  String get errorTermuxExternalApps;

  /// No description provided for @errorTermux.
  ///
  /// In en, this message translates to:
  /// **'Termux could not accept that command.'**
  String get errorTermux;

  /// No description provided for @errorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This action is not supported on this device.'**
  String get errorUnsupported;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnknown;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your local library still works.'**
  String get offlineBanner;

  /// No description provided for @errorBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get errorBannerAction;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get validationRequired;

  /// No description provided for @validationTooShort.
  ///
  /// In en, this message translates to:
  /// **'This value is too short.'**
  String get validationTooShort;

  /// No description provided for @validationTooLong.
  ///
  /// In en, this message translates to:
  /// **'This value is too long.'**
  String get validationTooLong;

  /// No description provided for @validationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check this value.'**
  String get validationInvalid;

  /// No description provided for @publishRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Publishing guidelines'**
  String get publishRulesTitle;

  /// No description provided for @publishRulesBody.
  ///
  /// In en, this message translates to:
  /// **'Share commands you have tested. Explain risks, avoid secrets and keep each step focused. Do not post copyrighted content you cannot share.'**
  String get publishRulesBody;

  /// No description provided for @previewEmptySteps.
  ///
  /// In en, this message translates to:
  /// **'Add steps to see a preview.'**
  String get previewEmptySteps;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get readLess;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @removedStep.
  ///
  /// In en, this message translates to:
  /// **'Step removed'**
  String get removedStep;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tag;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @categoryPackage.
  ///
  /// In en, this message translates to:
  /// **'Package management'**
  String get categoryPackage;

  /// No description provided for @categoryLinux.
  ///
  /// In en, this message translates to:
  /// **'Linux distributions'**
  String get categoryLinux;

  /// No description provided for @categoryShell.
  ///
  /// In en, this message translates to:
  /// **'Shell scripting'**
  String get categoryShell;

  /// No description provided for @categoryFiles.
  ///
  /// In en, this message translates to:
  /// **'Files & storage'**
  String get categoryFiles;

  /// No description provided for @categoryGit.
  ///
  /// In en, this message translates to:
  /// **'Git & version control'**
  String get categoryGit;

  /// No description provided for @categoryProgramming.
  ///
  /// In en, this message translates to:
  /// **'Programming & development'**
  String get categoryProgramming;

  /// No description provided for @categoryNetworking.
  ///
  /// In en, this message translates to:
  /// **'Networking & remote'**
  String get categoryNetworking;

  /// No description provided for @categorySystem.
  ///
  /// In en, this message translates to:
  /// **'System & processes'**
  String get categorySystem;

  /// No description provided for @categoryTermuxApi.
  ///
  /// In en, this message translates to:
  /// **'Termux API & device'**
  String get categoryTermuxApi;

  /// No description provided for @categorySecurity.
  ///
  /// In en, this message translates to:
  /// **'Security testing'**
  String get categorySecurity;

  /// No description provided for @categoryPackageDescription.
  ///
  /// In en, this message translates to:
  /// **'Install, update and manage packages.'**
  String get categoryPackageDescription;

  /// No description provided for @categoryLinuxDescription.
  ///
  /// In en, this message translates to:
  /// **'Run Linux environments inside Termux.'**
  String get categoryLinuxDescription;

  /// No description provided for @categoryShellDescription.
  ///
  /// In en, this message translates to:
  /// **'Scripts, aliases and shell behaviour.'**
  String get categoryShellDescription;

  /// No description provided for @categoryFilesDescription.
  ///
  /// In en, this message translates to:
  /// **'Navigate, copy, archive and clean up files.'**
  String get categoryFilesDescription;

  /// No description provided for @categoryGitDescription.
  ///
  /// In en, this message translates to:
  /// **'Track changes and collaborate with Git.'**
  String get categoryGitDescription;

  /// No description provided for @categoryProgrammingDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up languages, editors and build tools.'**
  String get categoryProgrammingDescription;

  /// No description provided for @categoryNetworkingDescription.
  ///
  /// In en, this message translates to:
  /// **'SSH, transfers, APIs and connectivity.'**
  String get categoryNetworkingDescription;

  /// No description provided for @categorySystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Processes, storage, battery and diagnostics.'**
  String get categorySystemDescription;

  /// No description provided for @categoryTermuxApiDescription.
  ///
  /// In en, this message translates to:
  /// **'Use device features through Termux:API.'**
  String get categoryTermuxApiDescription;

  /// No description provided for @categorySecurityDescription.
  ///
  /// In en, this message translates to:
  /// **'Inspect a system you own. Use responsibly.'**
  String get categorySecurityDescription;

  /// No description provided for @curatedBy.
  ///
  /// In en, this message translates to:
  /// **'Curated by the Termux Library team'**
  String get curatedBy;

  /// No description provided for @seedDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Curated offline guide. Review commands before running them.'**
  String get seedDisclaimer;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready.'**
  String get accountCreated;

  /// No description provided for @signInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in.'**
  String get signInSuccess;

  /// No description provided for @signInToPublish.
  ///
  /// In en, this message translates to:
  /// **'Sign in to publish'**
  String get signInToPublish;

  /// No description provided for @nameMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'Use a different title.'**
  String get nameMustBeDifferent;

  /// No description provided for @commandLowRisk.
  ///
  /// In en, this message translates to:
  /// **'No obvious destructive pattern detected. This is not a guarantee of safety.'**
  String get commandLowRisk;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySettings;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// No description provided for @emailChanged.
  ///
  /// In en, this message translates to:
  /// **'Email updated.'**
  String get emailChanged;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmail;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent.'**
  String get verificationSent;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get notVerified;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @localProfile.
  ///
  /// In en, this message translates to:
  /// **'Local guest profile'**
  String get localProfile;

  /// No description provided for @localProfileBody.
  ///
  /// In en, this message translates to:
  /// **'This profile only exists on this device. Sign in to sync it.'**
  String get localProfileBody;

  /// No description provided for @deleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this local profile?'**
  String get deleteProfileTitle;

  /// No description provided for @deleteProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Favorites and pins saved for this guest profile will also be removed from this device.'**
  String get deleteProfileBody;

  /// No description provided for @syncSecretsNote.
  ///
  /// In en, this message translates to:
  /// **'API keys are never synced. They stay in secure device storage.'**
  String get syncSecretsNote;

  /// No description provided for @cachePolicyNote.
  ///
  /// In en, this message translates to:
  /// **'Cached AI answers are keyed by model, prompt, context and prompt version, and expire automatically.'**
  String get cachePolicyNote;

  /// No description provided for @clearDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared.'**
  String get clearDataSuccess;

  /// No description provided for @databaseHealthy.
  ///
  /// In en, this message translates to:
  /// **'SQLite ready'**
  String get databaseHealthy;

  /// No description provided for @commandsCached.
  ///
  /// In en, this message translates to:
  /// **'{count} commands cached'**
  String commandsCached(int count);

  /// No description provided for @seedInstalled.
  ///
  /// In en, this message translates to:
  /// **'Offline starter library installed'**
  String get seedInstalled;

  /// No description provided for @seedInstalling.
  ///
  /// In en, this message translates to:
  /// **'Preparing offline starter library…'**
  String get seedInstalling;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the community library. Cached commands are still available.'**
  String get refreshFailed;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in.'**
  String get signInFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account.'**
  String get registrationFailed;

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the reset email.'**
  String get resetFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account.'**
  String get deleteFailed;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save.'**
  String get saveFailed;

  /// No description provided for @missingTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get missingTitle;

  /// No description provided for @shareGuide.
  ///
  /// In en, this message translates to:
  /// **'Share a guide'**
  String get shareGuide;

  /// No description provided for @shareYourFirstGuide.
  ///
  /// In en, this message translates to:
  /// **'Share your first guide'**
  String get shareYourFirstGuide;

  /// No description provided for @openAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Open assistant'**
  String get openAiAssistant;

  /// No description provided for @aiContext.
  ///
  /// In en, this message translates to:
  /// **'AI context'**
  String get aiContext;

  /// No description provided for @explainWithAi.
  ///
  /// In en, this message translates to:
  /// **'Explain with AI'**
  String get explainWithAi;

  /// No description provided for @askAboutCommand.
  ///
  /// In en, this message translates to:
  /// **'Ask about this command…'**
  String get askAboutCommand;

  /// No description provided for @aiReply.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiReply;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfile;

  /// No description provided for @emailOptionalForGuest.
  ///
  /// In en, this message translates to:
  /// **'Optional for guests'**
  String get emailOptionalForGuest;

  /// No description provided for @passwordForAnonymousUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Add an email and password to keep this collection.'**
  String get passwordForAnonymousUpgrade;

  /// No description provided for @refreshModelsFirst.
  ///
  /// In en, this message translates to:
  /// **'Fetch models before choosing one.'**
  String get refreshModelsFirst;

  /// No description provided for @noAiModelSelected.
  ///
  /// In en, this message translates to:
  /// **'Choose an AI model in settings.'**
  String get noAiModelSelected;

  /// No description provided for @groq.
  ///
  /// In en, this message translates to:
  /// **'Groq'**
  String get groq;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get requestCancelled;

  /// No description provided for @cacheHit.
  ///
  /// In en, this message translates to:
  /// **'Cached answer'**
  String get cacheHit;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A newer version of this guide exists online.'**
  String get newVersionAvailable;

  /// No description provided for @connectionRequired.
  ///
  /// In en, this message translates to:
  /// **'This action needs a connection.'**
  String get connectionRequired;

  /// No description provided for @viewGuide.
  ///
  /// In en, this message translates to:
  /// **'View guide'**
  String get viewGuide;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish the guide.'**
  String get publishFailed;

  /// No description provided for @draftSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device.'**
  String get draftSavedLocally;

  /// No description provided for @syncOnSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sync starts automatically when you sign in.'**
  String get syncOnSignIn;

  /// No description provided for @syncProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile & collection'**
  String get syncProfile;

  /// No description provided for @syncPublicCommands.
  ///
  /// In en, this message translates to:
  /// **'Public command library'**
  String get syncPublicCommands;

  /// No description provided for @syncingNow.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncingNow;

  /// No description provided for @syncedCommands.
  ///
  /// In en, this message translates to:
  /// **'Library is current'**
  String get syncedCommands;

  /// No description provided for @errorBannerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get errorBannerRetry;

  /// No description provided for @noSteps.
  ///
  /// In en, this message translates to:
  /// **'No steps'**
  String get noSteps;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @stepCommandCopied.
  ///
  /// In en, this message translates to:
  /// **'Step command copied.'**
  String get stepCommandCopied;

  /// No description provided for @allCommandsCopied.
  ///
  /// In en, this message translates to:
  /// **'All commands copied.'**
  String get allCommandsCopied;

  /// No description provided for @openCommandInAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get openCommandInAi;

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do that.'**
  String get noPermission;

  /// No description provided for @ownerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the author or an admin can change this guide.'**
  String get ownerOnly;

  /// No description provided for @guideNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This guide is not available.'**
  String get guideNotAvailable;

  /// No description provided for @deletedGuide.
  ///
  /// In en, this message translates to:
  /// **'This guide was removed.'**
  String get deletedGuide;

  /// No description provided for @storageNote.
  ///
  /// In en, this message translates to:
  /// **'Pinned IDs keep your custom order in your profile document.'**
  String get storageNote;

  /// No description provided for @appLocked.
  ///
  /// In en, this message translates to:
  /// **'App is starting'**
  String get appLocked;

  /// No description provided for @fontLicenses.
  ///
  /// In en, this message translates to:
  /// **'Font licenses'**
  String get fontLicenses;

  /// No description provided for @attachmentReadFailed.
  ///
  /// In en, this message translates to:
  /// **'That file could not be read. Choose a plain-text file.'**
  String get attachmentReadFailed;

  /// No description provided for @saveKey.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get saveKey;

  /// No description provided for @keyStored.
  ///
  /// In en, this message translates to:
  /// **'An API key is saved on this device.'**
  String get keyStored;

  /// No description provided for @apiKeyRemoved.
  ///
  /// In en, this message translates to:
  /// **'API key removed.'**
  String get apiKeyRemoved;

  /// No description provided for @addMetadata.
  ///
  /// In en, this message translates to:
  /// **'Add detail'**
  String get addMetadata;

  /// No description provided for @metadataKey.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get metadataKey;

  /// No description provided for @metadataValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get metadataValue;

  /// No description provided for @metadataHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Requires Termux:API'**
  String get metadataHint;

  /// No description provided for @removeMetadata.
  ///
  /// In en, this message translates to:
  /// **'Remove detail'**
  String get removeMetadata;

  /// No description provided for @officialReleases.
  ///
  /// In en, this message translates to:
  /// **'Official releases'**
  String get officialReleases;

  /// No description provided for @copyCommand.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get copyCommand;

  /// No description provided for @openDocs.
  ///
  /// In en, this message translates to:
  /// **'Open documentation'**
  String get openDocs;

  /// No description provided for @builtInAvatars.
  ///
  /// In en, this message translates to:
  /// **'Built-in avatars'**
  String get builtInAvatars;

  /// No description provided for @selectAvatar.
  ///
  /// In en, this message translates to:
  /// **'Select avatar'**
  String get selectAvatar;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'AI model'**
  String get aiModel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @changesSavedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Changes are saved automatically.'**
  String get changesSavedAutomatically;

  /// No description provided for @modelSelected.
  ///
  /// In en, this message translates to:
  /// **'Model set to {name}.'**
  String modelSelected(String name);

  /// No description provided for @clearLocalDataBodySafe.
  ///
  /// In en, this message translates to:
  /// **'Removes cached community commands, AI conversations, the AI cache and local preferences from this device. Your account and public guides stay online.'**
  String get clearLocalDataBodySafe;

  /// No description provided for @recentConversations.
  ///
  /// In en, this message translates to:
  /// **'Recent conversations'**
  String get recentConversations;

  /// No description provided for @attachmentTruncated.
  ///
  /// In en, this message translates to:
  /// **'This file is large, so only the first {chars} characters are sent.'**
  String attachmentTruncated(int chars);
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
      <String>['en', 'my'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
