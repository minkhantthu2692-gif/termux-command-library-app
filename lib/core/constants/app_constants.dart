/// Central constants for the application. Keeping these in one place avoids
/// magic strings in repositories and UI code.
abstract final class AppConstants {
  static const appName = 'Termux Command Library';
  static const packageName = 'com.termuxcommandlibrary.mm';

  // Firestore collections. Firebase is used only for Auth and Firestore.
  static const commandsCollection = 'commands';
  static const usersCollection = 'users';

  // Local database.
  static const databaseName = 'termux_command_library';
  static const currentSeedVersion = 3;

  // Content limits.
  static const maxCommandNameLength = 100;
  static const maxDescriptionLength = 4000;
  static const maxStepTitleLength = 120;
  static const maxStepDescriptionLength = 2000;
  static const maxCommandLength = 64000;
  static const maxTags = 10;
  static const maxTagLength = 32;
  static const maxSteps = 30;
  static const maxMetadataEntries = 12;
  static const maxMetadataValueLength = 500;

  // Profile limits. Firestore documents are capped at 1 MiB. These caps keep
  // the arrays comfortably below that limit and are documented in
  // docs/synchronization.md along with the migration path to collections.
  static const maxNicknameLength = 40;
  static const maxFavoriteIds = 5000;
  static const maxPinnedIds = 200;

  // Pagination / search.
  static const pageSize = 20;
  static const maxPageSize = 100;
  static const localSearchDebounce = Duration(milliseconds: 280);
  static const syncPageSize = 100;
  static const syncMaxPagesPerRefresh = 10;

  // AI.
  static const aiPromptVersion = '2026-10-26.v1';
  static const aiMaxAttachmentBytes = 256 * 1024;
  static const aiMaxAttachmentFiles = 1;

  /// Only the leading portion of a selected text file is placed in a prompt.
  /// This keeps a single message comfortably below [aiMaxMessageCharacters]
  /// and avoids sending an unexpectedly large context to the provider.
  static const aiMaxPromptAttachmentCharacters = 20000;
  static const aiMaxComposerCharacters = 12000;
  static const aiDefaultCacheHours = 24;
  static const aiMaxHistoryMessages = 60;
  static const aiMaxMessageCharacters = 48000;
  static const aiModelsTtl = Duration(days: 1);
  static const groqProviderId = 'groq';

  // URLs used for guidance. They are not credentials.
  static const termuxReleasesUrl =
      'https://github.com/termux/termux-app/releases';
  static const termuxApiUrl = 'https://github.com/termux/termux-api';
  static const groqConsoleUrl = 'https://console.groq.com/keys';
  static const groqDocsUrl = 'https://console.groq.com/docs';
  static const projectRepositoryUrl =
      'https://github.com/your-account/termux-command-library';

  // Guest/local identity. This is deliberately not a Firebase UID; it only
  // namespaces on-device favorites and pins until the user links an account.
  static const localUidPrefix = 'local-guest-';
  static const seedAuthorUid = 'termux-library';
  static const seedAuthorName = 'Termux Library';

  // Supported AI attachment file extensions (text based only).
  static const supportedAttachmentExtensions = <String>[
    'txt',
    'md',
    'sh',
    'py',
    'log',
  ];

  // Intent channel used by android/app/src/main/.../MainActivity.kt.
  static const nativeChannel = 'dev.termuxlibrary/native';
}
