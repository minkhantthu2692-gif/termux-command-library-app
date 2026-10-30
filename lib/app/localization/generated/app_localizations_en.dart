// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Termux Command Library';

  @override
  String get appTagline => 'A calm, curated library for Termux commands.';

  @override
  String get appDescription =>
      'Browse, collect and run community command guides. Built to work offline first.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get loading => 'Loading';

  @override
  String get done => 'Done';

  @override
  String get back => 'Back';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get clearAll => 'Clear all';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get copyFailed => 'Could not copy to the clipboard';

  @override
  String get run => 'Run';

  @override
  String get open => 'Open';

  @override
  String get learnMore => 'Learn more';

  @override
  String get optional => 'Optional';

  @override
  String get required => 'Required';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try again';

  @override
  String get guest => 'Guest';

  @override
  String get member => 'Member';

  @override
  String get admin => 'Admin';

  @override
  String get localOnly => 'Local only';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeGreeting => 'Welcome to your command library';

  @override
  String get welcomeBody =>
      'Discover practical Termux guides, keep the ones you love, and run them with a single confirmation.';

  @override
  String get welcomeFeatureOffline => 'Offline first';

  @override
  String get welcomeFeatureOfflineBody =>
      'Browse and keep commands even without a connection.';

  @override
  String get welcomeFeatureTermux => 'Termux aware';

  @override
  String get welcomeFeatureTermuxBody =>
      'Copy safely or send commands to Termux with clear warnings.';

  @override
  String get welcomeFeatureAi => 'Your own AI key';

  @override
  String get welcomeFeatureAiBody =>
      'Optional Groq assistance stored securely on this device.';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInSubtitle => 'Pick up where you left off.';

  @override
  String get createAccount => 'Create account';

  @override
  String get createAccountSubtitle =>
      'Publish guides and sync your collection.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithGithub => 'Continue with GitHub';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get providerSignInSlow =>
      'Still waiting for the browser? Finish signing in there, or go back and try again.';

  @override
  String get githubDeviceTitle => 'Connect GitHub';

  @override
  String get githubDeviceInstructions =>
      'Enter this code on GitHub to finish signing in.';

  @override
  String get githubDeviceCodeLabel => 'Sign-in code';

  @override
  String get githubDeviceStarting => 'Requesting a sign-in code…';

  @override
  String get githubDeviceWaiting => 'Waiting for you to authorize on GitHub…';

  @override
  String get githubDeviceOpen => 'Open GitHub';

  @override
  String get githubDeviceOpenManually =>
      'If the browser did not open, visit github.com/login/device.';

  @override
  String get githubDeviceOpenFailed =>
      'Could not open the browser. Visit github.com/login/device manually.';

  @override
  String get githubDeviceCopyCode => 'Copy code';

  @override
  String get githubDeviceCopied => 'Code copied';

  @override
  String get githubDeviceExpired =>
      'This code expired. Tap Try again for a new code.';

  @override
  String get githubDeviceDisabled =>
      'GitHub sign-in is not available. The app owner must enable Device Flow in the GitHub OAuth app.';

  @override
  String get email => 'Email';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get emailHint => 'you or you@example.com';

  @override
  String get emailHelper => 'A bare username becomes @gmail.com.';

  @override
  String get emailRequired => 'Enter an email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get password => 'Password';

  @override
  String get passwordHelper => 'At least 8 characters.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get passwordTooShort => 'Use at least 8 characters.';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordMedium => 'Fair';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsMismatch => 'Passwords do not match.';

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameHint => 'How others will see you';

  @override
  String get nicknameRequired => 'Enter a nickname.';

  @override
  String get nicknameTooShort => 'Use at least 2 characters.';

  @override
  String get nicknameTooLong => 'Use at most 40 characters.';

  @override
  String get avatar => 'Avatar';

  @override
  String get chooseAvatar => 'Choose an avatar';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get resetPasswordBody =>
      'Enter your email and we will send a secure reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetEmailSent =>
      'If an account exists for that address, a reset link is on its way.';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get noAccount => 'New here?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Your saved commands stay on this device. Cloud data will be available again the next time you sign in.';

  @override
  String get signedOutLocally => 'Signed out. You are browsing as a guest.';

  @override
  String get updatePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get reauthenticateNeeded =>
      'For your security, sign in again before continuing.';

  @override
  String get account => 'Account';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get connectedAccounts => 'Connected accounts';

  @override
  String get githubAccount => 'GitHub';

  @override
  String get githubConnectAction => 'Connect';

  @override
  String get githubConnectBody =>
      'Connect GitHub without changing your UID, favorites or guides.';

  @override
  String get githubConnectedBody =>
      'Connected. You can sign in with GitHub as well as your current method.';

  @override
  String get githubLinkSuccess => 'GitHub connected to your account.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete this account?';

  @override
  String get deleteAccountBody =>
      'This removes your account, your public guides and synced favorites. Local guest data on this device is not affected. This cannot be undone.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get clearLocalData => 'Clear local data';

  @override
  String get clearLocalDataTitle => 'Clear local data?';

  @override
  String get clearLocalDataBody =>
      'Cached community commands, AI history and local preferences will be removed from this device. Your cloud account and public guides are not deleted.';

  @override
  String get clearCache => 'Clear cached commands';

  @override
  String get clearCacheBody =>
      'Removes cached community commands while keeping your own guides, favorites and pins.';

  @override
  String get cacheCleared => 'Cached commands removed.';

  @override
  String get clearAiHistory => 'Clear AI history';

  @override
  String get aiHistoryCleared => 'AI history cleared.';

  @override
  String get deleteLocalProfile => 'Remove local profile';

  @override
  String get guestDataNote => 'Guest favorites and pins stay on this device.';

  @override
  String get guestSignInHint =>
      'Sign in to sync your collection and publish guides.';

  @override
  String get anonymousAccount => 'Anonymous account';

  @override
  String get anonymousExplanation =>
      'You can save a temporary cloud account now and add an email later.';

  @override
  String get continueAnonymously => 'Continue anonymously';

  @override
  String get upgradeAccount => 'Add email to account';

  @override
  String get upgradeAccountBody =>
      'Keep your saved collection and turn this anonymous account into a registered one.';

  @override
  String get accountUpgraded => 'Your account is now registered.';

  @override
  String get linkGuestData => 'Import guest favorites?';

  @override
  String get linkGuestDataBody =>
      'Copy the favorites and pins saved in guest mode into this account. Guest data is then removed from this device.';

  @override
  String get importGuestData => 'Import';

  @override
  String get guestDataImported => 'Guest collection imported.';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get guestModeBanner =>
      'Guest mode · favorites are local to this device';

  @override
  String get createAccountToPublish => 'Create an account to publish guides.';

  @override
  String get guestCannotPublish =>
      'Guests can browse and save commands. Sign in to publish.';

  @override
  String get cloudUnavailableTitle => 'Cloud features are not configured';

  @override
  String get cloudUnavailableBody =>
      'The app is running in local-only mode. Browsing, favorites, pins, Termux and AI still work. Add Firebase configuration (android/app/google-services.json) and rebuild to enable accounts and publishing.';

  @override
  String get firebaseSetupDocs => 'Firebase setup guide';

  @override
  String get cloudError => 'Cloud connection problem';

  @override
  String syncPending(int count) {
    return '$count change(s) waiting to sync';
  }

  @override
  String get syncComplete => 'Up to date';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncLocalOnly => 'Saved locally';

  @override
  String get syncError => 'Sync interrupted. Local data is safe.';

  @override
  String lastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeSubtitle => 'What will you build in Termux today?';

  @override
  String get browseLibrary => 'Browse library';

  @override
  String get searchCommands => 'Search commands, tags or tools';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get exploreCategories => 'Explore categories';

  @override
  String get pinnedCommands => 'Pinned';

  @override
  String get recentCommands => 'Recently updated';

  @override
  String get seeAll => 'See all';

  @override
  String get yourLibrary => 'Your library';

  @override
  String get totalCommands => 'Commands';

  @override
  String get favoritesCount => 'Favorites';

  @override
  String get pinsCount => 'Pins';

  @override
  String get myPostsCount => 'My guides';

  @override
  String get communityLibrary => 'Community library';

  @override
  String get librarySubtitle => 'Search and filter the local library.';

  @override
  String get allCommands => 'All';

  @override
  String get favorites => 'Favorites';

  @override
  String get pinned => 'Pinned';

  @override
  String get myPosts => 'My posts';

  @override
  String get drafts => 'Drafts';

  @override
  String get filters => 'Filters';

  @override
  String get sort => 'Sort';

  @override
  String get sortRecentlyUpdated => 'Recently updated';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortNameAsc => 'Name A–Z';

  @override
  String get sortMostSteps => 'Most steps';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get activeFilters => 'Filters active';

  @override
  String searchResultsFor(String query) {
    return 'Results for \"$query\"';
  }

  @override
  String get noCommandsTitle => 'No commands yet';

  @override
  String get noCommandsBody => 'Try a different search or clear the filters.';

  @override
  String get emptyFavoritesTitle => 'No favorites yet';

  @override
  String get emptyFavoritesBody =>
      'Save the commands you reach for often and they will appear here.';

  @override
  String get emptyPinsTitle => 'Nothing pinned';

  @override
  String get emptyPinsBody => 'Pin a command to keep it within easy reach.';

  @override
  String get emptyMineTitle => 'You have not published anything yet';

  @override
  String get emptyMineBody =>
      'Share a guide with the community whenever you are ready.';

  @override
  String get loadMore => 'Load more';

  @override
  String get endOfResults => 'You have reached the end.';

  @override
  String stepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String updatedTime(String time) {
    return 'Updated $time';
  }

  @override
  String byAuthor(String name) {
    return 'by $name';
  }

  @override
  String get pendingSyncBadge => 'Pending sync';

  @override
  String get seedBadge => 'Curated';

  @override
  String get draftBadge => 'Draft';

  @override
  String get commandDetails => 'Command details';

  @override
  String get overview => 'Overview';

  @override
  String get steps => 'Steps';

  @override
  String get commandsTab => 'Commands';

  @override
  String get notes => 'Notes';

  @override
  String get tags => 'Tags';

  @override
  String get metadata => 'Details';

  @override
  String get category => 'Category';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get pinCommand => 'Pin command';

  @override
  String get unpinCommand => 'Unpin command';

  @override
  String get pinnedSnack => 'Pinned';

  @override
  String get unpinnedSnack => 'Unpinned';

  @override
  String get favoritedSnack => 'Added to favorites';

  @override
  String get unfavoritedSnack => 'Removed from favorites';

  @override
  String get copyAllCommands => 'Copy all commands';

  @override
  String get runAllCommands => 'Run all in Termux';

  @override
  String get copyStep => 'Copy step';

  @override
  String get runStep => 'Run step';

  @override
  String stepNumber(int number) {
    return 'Step $number';
  }

  @override
  String get runConfirmationTitle => 'Send to Termux?';

  @override
  String get runConfirmationBody =>
      'Termux will run this command in a new session. Review it first. The app will report that the command was sent, not whether it finished.';

  @override
  String get runBackground => 'Run in the background';

  @override
  String get runBackgroundHelper =>
      'Background commands have no visible terminal output.';

  @override
  String get termuxKeepOpen => 'Keep terminal open';

  @override
  String get termuxKeepOpenHelper =>
      'Keeps the session open after the command finishes so you can read its output. Press Enter in Termux to close it.';

  @override
  String get termuxKeepOpenHint =>
      'Command finished. Press Enter to close this session.';

  @override
  String get runForeground => 'Open in Termux';

  @override
  String get confirmRun => 'Send command';

  @override
  String get commandSentToTermux => 'Command sent to Termux.';

  @override
  String get commandNotRun => 'No command was sent.';

  @override
  String get runViaTermux => 'Run via Termux';

  @override
  String get copyInstead => 'Copy instead';

  @override
  String get termuxMissingTitle => 'Termux is not installed';

  @override
  String get termuxMissingBody =>
      'Install Termux from the official GitHub releases. Play Store builds are outdated and do not support this integration.';

  @override
  String get termuxPermissionTitle => 'Termux permission required';

  @override
  String get termuxPermissionBody =>
      'Allow Termux command execution for this app. Android will ask for the RUN_COMMAND permission.';

  @override
  String get termuxExternalAppsTitle => 'Enable external commands in Termux';

  @override
  String get termuxExternalAppsBody =>
      'Open Termux and add this line to ~/.termux/termux.properties:\n\nallow-external-apps=true\n\nThen run termux-reload-settings or restart Termux.';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get openTermux => 'Open Termux';

  @override
  String get getTermux => 'Get Termux';

  @override
  String get termuxGuide => 'Termux setup guide';

  @override
  String get termuxGuideIntro =>
      'This app sends commands to Termux. It is not a terminal emulator and cannot run commands by itself.';

  @override
  String get termuxGuideButtons =>
      'Use Run via Termux on a step, or Run all in Termux on a guide. Every command is shown for confirmation before it is sent.';

  @override
  String get termuxStepInstall =>
      'Install the official Termux release (GitHub, F-Droid or a trusted mirror).';

  @override
  String get termuxStepPermission =>
      'Grant the RUN_COMMAND permission when Android asks.';

  @override
  String get termuxStepExternal =>
      'Set allow-external-apps=true in ~/.termux/termux.properties.';

  @override
  String get termuxStepReload =>
      'Run termux-reload-settings or restart Termux.';

  @override
  String get termuxStepOverlay =>
      'Allow Termux to open sessions from the background.';

  @override
  String get termuxOverlayBody =>
      'Android 10 and later blocks Termux from opening a terminal session while this app is in front unless Termux can display over other apps. Grant the permission once; background runs do not need it.';

  @override
  String get termuxOverlayGrant => 'Open Termux display settings';

  @override
  String get termuxOverlayPill => 'Display over apps';

  @override
  String get termuxOverlayTitle => 'Termux needs display permission';

  @override
  String get termuxOverlayRunBody =>
      'Android 10 and later requires the \"Display over other apps\" permission for Termux to open a terminal session while this app is in front. Grant it in Termux\'s Android settings, or turn on Run in the background in the confirmation sheet.';

  @override
  String get termuxTestTitle => 'Test the connection';

  @override
  String get termuxTestBody =>
      'Send a harmless echo command and confirm that output appears in Termux.';

  @override
  String get termuxTestButton => 'Send test command';

  @override
  String get termuxStepApi =>
      'Install Termux:API for built-in commands (optional).';

  @override
  String get termuxApiStepBody =>
      'Some guides use termux-* commands such as termux-battery-status or termux-toast. They need two separate parts:';

  @override
  String get termuxApiApk => '1. The Termux:API APK (adds the Android side).';

  @override
  String get termuxApiPackage =>
      '2. The termux-api package inside Termux (adds the commands):';

  @override
  String get termuxApiSameSource =>
      'Install Termux and Termux:API from the same source. GitHub and F-Droid builds use different signing keys, so switching sources requires uninstalling every Termux app and plugin.';

  @override
  String get termuxStatusNote =>
      'Status reflects installed apps and Android permissions. Packages installed inside Termux are not visible to this app.';

  @override
  String get termuxApiTestTitle => 'Test Termux:API';

  @override
  String get termuxApiTestBody =>
      'Send a harmless toast. If nothing appears, the APK, the package or an Android permission is missing.';

  @override
  String get termuxApiTestButton => 'Send API test';

  @override
  String get termuxApiNoteTitle => 'Termux:API commands';

  @override
  String get termuxApiConfirmNote =>
      'This guide uses termux-* commands. They only work when the Termux:API APK and the termux-api package are both installed.';

  @override
  String get termuxApiMissingTitle => 'Termux:API is required';

  @override
  String get termuxApiMissingBody =>
      'This command uses a built-in termux-* command. Install the Termux:API APK, then run pkg install termux-api inside Termux. Both parts are required.';

  @override
  String get termuxApiGuide => 'Get Termux:API';

  @override
  String get termuxApiSettings => 'Open Termux:API settings';

  @override
  String get termuxApiNotInstalled => 'Termux:API is not installed.';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get permissionGranted => 'Permission granted';

  @override
  String get permissionGrantedSnack => 'RUN_COMMAND permission granted.';

  @override
  String get riskWarningTitle => 'This command can be destructive';

  @override
  String get riskWarningBody =>
      'Review every line carefully. Termux runs with your user permissions, but some commands can still erase files or change your device.';

  @override
  String get riskMedium => 'Use with care';

  @override
  String get riskHigh => 'High risk';

  @override
  String get riskRecursiveRootDelete =>
      'Recursive deletion at a filesystem root';

  @override
  String get riskHomeDelete => 'Deletion in your home directory';

  @override
  String get riskFilesystemFormat => 'Formats or wipes a filesystem';

  @override
  String get riskRawDiskWrite => 'Writes directly to a disk device';

  @override
  String get riskSystemPermissionChange => 'Changes permissions broadly';

  @override
  String get riskForkBomb => 'Fork bomb pattern';

  @override
  String get riskSystemPower => 'Shuts down or restarts the system';

  @override
  String get riskPipeDownloadToShell => 'Pipes downloaded content into a shell';

  @override
  String get riskDestructiveGitClean => 'Discards uncommitted Git changes';

  @override
  String get riskPackageRemoval => 'Removes installed packages';

  @override
  String get riskPrivilegeEscalation => 'Requests elevated privileges';

  @override
  String get riskForceKill => 'Force-kills processes';

  @override
  String get riskAcknowledge => 'I understand the risk';

  @override
  String get newCommand => 'New command';

  @override
  String get editCommand => 'Edit command';

  @override
  String get uploadSubtitle =>
      'Share a clear, useful guide with the community.';

  @override
  String get basics => 'Basics';

  @override
  String get commandName => 'Title';

  @override
  String get commandNameHint => 'Create a Python virtual environment';

  @override
  String get commandNameRequired => 'Give your guide a title.';

  @override
  String get commandNameTooShort => 'Use at least 2 characters.';

  @override
  String get commandNameTooLong => 'Use at most 100 characters.';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint =>
      'Explain what this guide does and when to use it.';

  @override
  String get descriptionRequired => 'Add a short description.';

  @override
  String get descriptionTooLong => 'Description is too long.';

  @override
  String get categoryRequired => 'Choose a category.';

  @override
  String get tagsHint => 'Add tags, separated by commas';

  @override
  String get tagsHelper => 'Up to 10 tags. Useful for tools and tasks.';

  @override
  String get stepsTitle => 'Command steps';

  @override
  String get stepsHelper =>
      'Steps run in order. Commands are stored exactly as written.';

  @override
  String get addStep => 'Add step';

  @override
  String get removeStep => 'Remove step';

  @override
  String get newStep => 'New step';

  @override
  String get stepTitle => 'Step title';

  @override
  String get stepTitleHint => 'Update packages';

  @override
  String get stepTitleRequired => 'Give this step a title.';

  @override
  String get stepCommand => 'Command';

  @override
  String get stepCommandHint => 'pkg update && pkg upgrade -y';

  @override
  String get stepCommandRequired => 'The command cannot be empty.';

  @override
  String get stepDescription => 'Step note';

  @override
  String get stepDescriptionHint =>
      'Anything the reader should know before running this.';

  @override
  String get runMode => 'Run mode';

  @override
  String get runModeForeground => 'Open in Termux';

  @override
  String get runModeBackground => 'Background';

  @override
  String get stepLimit => 'A guide can contain at most 30 steps.';

  @override
  String get atLeastOneStep => 'Add at least one command step.';

  @override
  String get publish => 'Publish';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get publishConfirm => 'Publish this guide?';

  @override
  String get publishConfirmBody =>
      'Published guides are visible to everyone and can only be edited by you or an admin.';

  @override
  String get published => 'Guide published.';

  @override
  String get draftSaved => 'Draft saved.';

  @override
  String get guideSaved => 'Changes saved.';

  @override
  String get deleteCommandTitle => 'Delete this guide?';

  @override
  String get deleteCommandBody =>
      'The guide will be removed from the library. This cannot be undone.';

  @override
  String get commandDeleted => 'Guide deleted.';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody =>
      'Your edits to this guide have not been saved.';

  @override
  String get discard => 'Discard';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get preview => 'Preview';

  @override
  String get aiAssist => 'AI assist';

  @override
  String get aiAssistTitle => 'Write with AI';

  @override
  String get generateTitle => 'Suggest a title';

  @override
  String get rewriteDescription => 'Improve description';

  @override
  String get reviewCommand => 'Review command';

  @override
  String get explainCommand => 'Explain command';

  @override
  String get translateToMyanmar => 'Translate to Myanmar';

  @override
  String get translateToEnglish => 'Translate to English';

  @override
  String get aiAssistApplied => 'Suggestion applied.';

  @override
  String get aiNoProviderConfigured =>
      'Set up your Groq API key in AI settings first.';

  @override
  String get openAiSettings => 'Open AI settings';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get role => 'Account type';

  @override
  String get refreshRole => 'Refresh account type';

  @override
  String get refreshRoleBody => 'Reload your saved role from Firebase.';

  @override
  String get roleRefreshed => 'Account type refreshed.';

  @override
  String memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get myGuides => 'My guides';

  @override
  String get myCollection => 'My collection';

  @override
  String get accountAndSync => 'Account & sync';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Make the library feel like yours.';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColor => 'Accent color';

  @override
  String get accentIndigo => 'Indigo';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentCyan => 'Cyan';

  @override
  String get accentCoral => 'Coral';

  @override
  String get accentLime => 'Lime';

  @override
  String get accentFuchsia => 'Fuchsia';

  @override
  String get accentSlate => 'Slate';

  @override
  String get wallpaperColors => 'Wallpaper colors';

  @override
  String get wallpaperColorsHelper =>
      'Use colors from your home screen wallpaper. Choosing a palette below turns this off.';

  @override
  String get typography => 'Typography';

  @override
  String get fontFamily => 'Font family';

  @override
  String get fontSystem => 'System default';

  @override
  String get fontSize => 'Text size';

  @override
  String get fontSizePreview =>
      'The quick brown fox jumps over the lazy dog. မြန်မာစာသားကို ဖတ်ရှုရလွယ်ကူပါစေ။';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMyanmar => 'မြန်မာ';

  @override
  String get effects => 'Effects';

  @override
  String get blurEffects => 'Frosted glass';

  @override
  String get blurEffectsHelper =>
      'Subtle blur behind surfaces such as the navigation bar.';

  @override
  String get blurIntensity => 'Blur intensity';

  @override
  String get haptics => 'Haptics';

  @override
  String get vibrationIntensity => 'Vibration intensity';

  @override
  String get vibrationOff => 'Off';

  @override
  String get vibrationLight => 'Light';

  @override
  String get vibrationMedium => 'Medium';

  @override
  String get vibrationStrong => 'Strong';

  @override
  String get vibrationPreviewHint =>
      'Tap a level to preview it. Selection, success and warning cues each use a distinct rhythm.';

  @override
  String get dataAndStorage => 'Data & storage';

  @override
  String get localDatabase => 'Local database';

  @override
  String get localDatabaseBody =>
      'Commands, favorites and AI history are stored on this device with SQLite.';

  @override
  String get refreshLibrary => 'Refresh community library';

  @override
  String get refreshing => 'Refreshing…';

  @override
  String get refreshed => 'Library refreshed.';

  @override
  String get storageUsed => 'Approximate local usage';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'Your Groq key stays in secure device storage. Commands and AI history are local by default. Firebase is used only for accounts and the public library.';

  @override
  String get documentation => 'Documentation';

  @override
  String get openSource => 'Open source';

  @override
  String get licenses => 'Open-source licenses';

  @override
  String get developerMode => 'Developer details';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiAssistantSubtitle =>
      'A command-aware helper powered by your own key.';

  @override
  String get aiWelcomeTitle => 'Ask about anything in Termux';

  @override
  String get aiWelcomeBody =>
      'Explain a command, plan a workflow, or translate a guide. Your API key is stored on this device.';

  @override
  String get aiDisabledTitle => 'AI is off';

  @override
  String get aiDisabledBody =>
      'Add a Groq API key to enable the assistant. You control the key, model and history.';

  @override
  String get aiSettings => 'AI settings';

  @override
  String get aiSettingsSubtitle => 'Configure your API key and model';

  @override
  String get aiEnabled => 'AI assistant';

  @override
  String get aiEnabledHelper => 'Turns on chat and writing assistance.';

  @override
  String get aiProvider => 'Provider';

  @override
  String get aiProviderGroq => 'Groq';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyHelper =>
      'Stored with Android secure storage. It is never sent to Firebase.';

  @override
  String get getApiKey => 'Get a key';

  @override
  String get testKey => 'Test key';

  @override
  String get keyWorks => 'Key verified.';

  @override
  String get keyMissing => 'Enter an API key first.';

  @override
  String get keyInvalid => 'This key was rejected. Check it and try again.';

  @override
  String get keySaved => 'API key saved securely.';

  @override
  String get fetchModels => 'Fetch available models';

  @override
  String get modelsFetched => 'Models refreshed.';

  @override
  String get selectModel => 'Select model';

  @override
  String get selectedModel => 'Model';

  @override
  String get noModels =>
      'No models available. Test your key and fetch models again.';

  @override
  String modelContext(String tokens) {
    return '$tokens context';
  }

  @override
  String get cacheDuration => 'Response cache';

  @override
  String get cacheDurationHelper => 'Reuse identical requests to save tokens.';

  @override
  String get cacheOff => 'Off';

  @override
  String cacheHours(int count) {
    return '$count hours';
  }

  @override
  String get clearAiCache => 'Clear AI cache';

  @override
  String get aiCacheCleared => 'AI cache cleared.';

  @override
  String get aiSetupGuideBody =>
      'Open console.groq.com, sign in, create an API key, and paste it here. Keys start with gsk_. Billing and rate limits belong to your Groq account.';

  @override
  String get askAi => 'Ask the assistant';

  @override
  String get askAiHint => 'Ask about a command, error or workflow…';

  @override
  String get send => 'Send';

  @override
  String get stopGenerating => 'Stop';

  @override
  String get thinking => 'Thinking…';

  @override
  String get aiError => 'The assistant could not answer';

  @override
  String get aiEmpty => 'Start with a question about Termux.';

  @override
  String get suggestions => 'Try asking';

  @override
  String get suggestionExplain => 'Explain pkg update in plain language';

  @override
  String get suggestionScript => 'Help me write a backup script';

  @override
  String get suggestionFix => 'Why did my apt command fail?';

  @override
  String get suggestionTranslate => 'Translate this guide to Myanmar';

  @override
  String get newChat => 'New chat';

  @override
  String get chatHistory => 'Chat history';

  @override
  String get searchHistory => 'Search history';

  @override
  String get deleteConversation => 'Delete chat';

  @override
  String get deleteConversationBody =>
      'This chat will be removed from this device.';

  @override
  String get conversationDeleted => 'Chat deleted.';

  @override
  String get noConversations => 'No conversations yet';

  @override
  String get noConversationsBody =>
      'Your command questions and answers will be saved here.';

  @override
  String get attachFile => 'Attach text file';

  @override
  String get attachmentHelp => 'TXT, MD, SH, PY or LOG, up to 256 KB.';

  @override
  String get attachmentTooLarge => 'That file is larger than 256 KB.';

  @override
  String get attachmentUnsupported =>
      'Only TXT, MD, SH, PY and LOG files are supported.';

  @override
  String get attachmentAdded => 'File attached';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get attachmentNotice =>
      'The file contents will be sent to your AI provider when you send this message.';

  @override
  String get aiPrivacyNote =>
      'Messages are sent to Groq using your key. History and cache stay on this device.';

  @override
  String get aiHistory => 'AI history';

  @override
  String get clearHistory => 'Clear conversation history';

  @override
  String get clearHistoryBody =>
      'All saved conversations on this device will be deleted. API keys and commands are not affected.';

  @override
  String get copyResponse => 'Copy answer';

  @override
  String get regenerate => 'Regenerate';

  @override
  String tokensUsed(String count) {
    return '$count tokens';
  }

  @override
  String contextPinned(String title) {
    return 'Using: $title';
  }

  @override
  String get errorNetwork => 'No connection. Check your network and try again.';

  @override
  String get errorTimeout => 'That took too long. Please try again.';

  @override
  String get errorAuthRequired => 'Sign in to continue.';

  @override
  String get errorInvalidCredentials => 'The email or password is incorrect.';

  @override
  String get errorEmailInUse => 'An account already exists for this email.';

  @override
  String get errorWeakPassword =>
      'Choose a stronger password (at least 8 characters).';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errorRecentLogin => 'Sign in again to confirm this change.';

  @override
  String get errorAuthCancelled => 'Sign-in was cancelled.';

  @override
  String get errorAuthProviderUnavailable =>
      'This sign-in method is not enabled for this app yet.';

  @override
  String get errorProviderAccountExists =>
      'An account already exists for this email. Sign in with the method you used before, then connect GitHub from Account settings.';

  @override
  String get errorProviderAlreadyLinked =>
      'This sign-in method is already connected to your account.';

  @override
  String get errorProviderLinkedElsewhere =>
      'This GitHub account is already linked to a different account. Sign in to that account instead.';

  @override
  String get errorPermissionDenied =>
      'Firestore denied this action. Check the security rules.';

  @override
  String get errorFirebaseUnavailable => 'Firebase is unavailable right now.';

  @override
  String get errorFirebaseNotConfigured =>
      'Firebase is not configured in this build.';

  @override
  String get errorValidation => 'Check the highlighted fields.';

  @override
  String get errorNotFound => 'That item no longer exists.';

  @override
  String get errorDatabase =>
      'The local database could not complete that action.';

  @override
  String get errorConflict =>
      'The item changed elsewhere. Refresh and try again.';

  @override
  String get errorLimitReached => 'You reached the limit for this item.';

  @override
  String get errorAiDisabled => 'AI is disabled.';

  @override
  String get errorAiKeyMissing => 'Add your Groq API key first.';

  @override
  String get errorAiInvalidKey => 'Groq rejected the API key.';

  @override
  String get errorAiRateLimited =>
      'Groq rate limit reached. Wait a moment or check your plan.';

  @override
  String get errorAiProviderUnavailable =>
      'The AI provider is unavailable. Try again shortly.';

  @override
  String get errorAiModelUnavailable =>
      'That model is not available. Choose another model.';

  @override
  String get errorAiRequestTooLarge =>
      'This request is too large. Remove the attachment or shorten the prompt.';

  @override
  String get errorAiEmptyResponse => 'The model returned an empty answer.';

  @override
  String get errorAiCancelled => 'Generation stopped.';

  @override
  String get errorTermuxMissing => 'Termux is not installed.';

  @override
  String get errorTermuxPermission =>
      'The Termux RUN_COMMAND permission has not been granted.';

  @override
  String get errorTermuxExternalApps =>
      'Enable allow-external-apps in Termux, then retry.';

  @override
  String get errorTermux => 'Termux could not accept that command.';

  @override
  String get errorUnsupported => 'This action is not supported on this device.';

  @override
  String get errorUnknown => 'An unexpected error occurred.';

  @override
  String get offlineBanner =>
      'You are offline. Your local library still works.';

  @override
  String get errorBannerAction => 'Details';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationTooShort => 'This value is too short.';

  @override
  String get validationTooLong => 'This value is too long.';

  @override
  String get validationInvalid => 'Check this value.';

  @override
  String get publishRulesTitle => 'Publishing guidelines';

  @override
  String get publishRulesBody =>
      'Share commands you have tested. Explain risks, avoid secrets and keep each step focused. Do not post copyrighted content you cannot share.';

  @override
  String get previewEmptySteps => 'Add steps to see a preview.';

  @override
  String get today => 'today';

  @override
  String get yesterday => 'yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get readMore => 'Read more';

  @override
  String get readLess => 'Show less';

  @override
  String get reorder => 'Reorder';

  @override
  String get dragToReorder => 'Drag to reorder';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get undo => 'Undo';

  @override
  String get removedStep => 'Step removed';

  @override
  String get tag => 'Tag';

  @override
  String get allCategories => 'All categories';

  @override
  String get categoryPackage => 'Package management';

  @override
  String get categoryLinux => 'Linux distributions';

  @override
  String get categoryShell => 'Shell scripting';

  @override
  String get categoryFiles => 'Files & storage';

  @override
  String get categoryGit => 'Git & version control';

  @override
  String get categoryProgramming => 'Programming & development';

  @override
  String get categoryNetworking => 'Networking & remote';

  @override
  String get categorySystem => 'System & processes';

  @override
  String get categoryTermuxApi => 'Termux API & device';

  @override
  String get categorySecurity => 'Security testing';

  @override
  String get categoryPackageDescription =>
      'Install, update and manage packages.';

  @override
  String get categoryLinuxDescription =>
      'Run Linux environments inside Termux.';

  @override
  String get categoryShellDescription =>
      'Scripts, aliases and shell behaviour.';

  @override
  String get categoryFilesDescription =>
      'Navigate, copy, archive and clean up files.';

  @override
  String get categoryGitDescription =>
      'Track changes and collaborate with Git.';

  @override
  String get categoryProgrammingDescription =>
      'Set up languages, editors and build tools.';

  @override
  String get categoryNetworkingDescription =>
      'SSH, transfers, APIs and connectivity.';

  @override
  String get categorySystemDescription =>
      'Processes, storage, battery and diagnostics.';

  @override
  String get categoryTermuxApiDescription =>
      'Use device features through Termux:API.';

  @override
  String get categorySecurityDescription =>
      'Inspect a system you own. Use responsibly.';

  @override
  String get curatedBy => 'Curated by the Termux Library team';

  @override
  String get seedDisclaimer =>
      'Curated offline guide. Review commands before running them.';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get accountCreated => 'Your account is ready.';

  @override
  String get signInSuccess => 'Signed in.';

  @override
  String get signInToPublish => 'Sign in to publish';

  @override
  String get nameMustBeDifferent => 'Use a different title.';

  @override
  String get commandLowRisk =>
      'No obvious destructive pattern detected. This is not a guarantee of safety.';

  @override
  String get thisDevice => 'This device';

  @override
  String get securitySettings => 'Security';

  @override
  String get changeEmail => 'Change email';

  @override
  String get emailChanged => 'Email updated.';

  @override
  String get verifyEmail => 'Verify email';

  @override
  String get verificationSent => 'Verification email sent.';

  @override
  String get notVerified => 'Email not verified';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get localProfile => 'Local guest profile';

  @override
  String get localProfileBody =>
      'This profile only exists on this device. Sign in to sync it.';

  @override
  String get deleteProfileTitle => 'Remove this local profile?';

  @override
  String get deleteProfileBody =>
      'Favorites and pins saved for this guest profile will also be removed from this device.';

  @override
  String get syncSecretsNote =>
      'API keys are never synced. They stay in secure device storage.';

  @override
  String get cachePolicyNote =>
      'Cached AI answers are keyed by model, prompt, context and prompt version, and expire automatically.';

  @override
  String get clearDataSuccess => 'Local data cleared.';

  @override
  String get databaseHealthy => 'SQLite ready';

  @override
  String commandsCached(int count) {
    return '$count commands cached';
  }

  @override
  String get seedInstalled => 'Offline starter library installed';

  @override
  String get seedInstalling => 'Preparing offline starter library…';

  @override
  String get refreshFailed =>
      'Could not refresh the community library. Cached commands are still available.';

  @override
  String get signInFailed => 'Could not sign in.';

  @override
  String get registrationFailed => 'Could not create the account.';

  @override
  String get resetFailed => 'Could not send the reset email.';

  @override
  String get deleteFailed => 'Could not delete the account.';

  @override
  String get saveFailed => 'Could not save.';

  @override
  String get missingTitle => 'Title';

  @override
  String get shareGuide => 'Share a guide';

  @override
  String get shareYourFirstGuide => 'Share your first guide';

  @override
  String get openAiAssistant => 'Open assistant';

  @override
  String get aiContext => 'AI context';

  @override
  String get explainWithAi => 'Explain with AI';

  @override
  String get askAboutCommand => 'Ask about this command…';

  @override
  String get aiReply => 'Assistant';

  @override
  String get you => 'You';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get completeProfile => 'Complete profile';

  @override
  String get emailOptionalForGuest => 'Optional for guests';

  @override
  String get passwordForAnonymousUpgrade =>
      'Add an email and password to keep this collection.';

  @override
  String get refreshModelsFirst => 'Fetch models before choosing one.';

  @override
  String get noAiModelSelected => 'Choose an AI model in settings.';

  @override
  String get groq => 'Groq';

  @override
  String get requestCancelled => 'Cancelled';

  @override
  String get cacheHit => 'Cached answer';

  @override
  String get newVersionAvailable =>
      'A newer version of this guide exists online.';

  @override
  String get connectionRequired => 'This action needs a connection.';

  @override
  String get viewGuide => 'View guide';

  @override
  String get publishFailed => 'Could not publish the guide.';

  @override
  String get draftSavedLocally => 'Saved on this device.';

  @override
  String get syncOnSignIn => 'Sync starts automatically when you sign in.';

  @override
  String get syncProfile => 'Profile & collection';

  @override
  String get syncPublicCommands => 'Public command library';

  @override
  String get syncingNow => 'Syncing…';

  @override
  String get syncedCommands => 'Library is current';

  @override
  String get errorBannerRetry => 'Retry sync';

  @override
  String get noSteps => 'No steps';

  @override
  String get step => 'Step';

  @override
  String get stepCommandCopied => 'Step command copied.';

  @override
  String get allCommandsCopied => 'All commands copied.';

  @override
  String get openCommandInAi => 'Ask AI';

  @override
  String get noPermission => 'You do not have permission to do that.';

  @override
  String get ownerOnly => 'Only the author or an admin can change this guide.';

  @override
  String get guideNotAvailable => 'This guide is not available.';

  @override
  String get deletedGuide => 'This guide was removed.';

  @override
  String get storageNote =>
      'Pinned IDs keep your custom order in your profile document.';

  @override
  String get appLocked => 'App is starting';

  @override
  String get fontLicenses => 'Font licenses';

  @override
  String get attachmentReadFailed =>
      'That file could not be read. Choose a plain-text file.';

  @override
  String get saveKey => 'Save key';

  @override
  String get keyStored => 'An API key is saved on this device.';

  @override
  String get apiKeyRemoved => 'API key removed.';

  @override
  String get addMetadata => 'Add detail';

  @override
  String get metadataKey => 'Label';

  @override
  String get metadataValue => 'Value';

  @override
  String get metadataHint => 'For example: Requires Termux:API';

  @override
  String get removeMetadata => 'Remove detail';

  @override
  String get officialReleases => 'Official releases';

  @override
  String get copyCommand => 'Copy command';

  @override
  String get openDocs => 'Open documentation';

  @override
  String get builtInAvatars => 'Built-in avatars';

  @override
  String get selectAvatar => 'Select avatar';

  @override
  String get aiModel => 'AI model';

  @override
  String get requiredField => 'Required';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get changesSavedAutomatically => 'Changes are saved automatically.';

  @override
  String modelSelected(String name) {
    return 'Model set to $name.';
  }

  @override
  String get clearLocalDataBodySafe =>
      'Removes cached community commands, AI conversations, the AI cache and local preferences from this device. Your account and public guides stay online.';

  @override
  String get recentConversations => 'Recent conversations';

  @override
  String attachmentTruncated(int chars) {
    return 'This file is large, so only the first $chars characters are sent.';
  }
}
