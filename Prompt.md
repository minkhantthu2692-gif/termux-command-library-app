Prompt.md

Build a Production-Quality Termux Command Library

Project Mission

You are a senior Flutter engineer, mobile application architect, Firebase developer, UI/UX implementation specialist, and AI integration engineer.

Your task is to build a complete, maintainable, production-quality Android application called:

Termux Command Library

The application is a modern community-driven library for Termux commands and multi-step command guides.

The user must be able to discover, search, filter, organize, upload, copy, and execute Termux commands through a clean and intuitive mobile application.

This is not a simple static UI prototype.

Build a real application with functional:

- Authentication.
- Database.
- Offline storage.
- Online synchronization.
- CRUD operations.
- User profiles.
- Role-based permissions.
- Termux integration.
- AI assistant.
- Settings.
- Documentation.
- Testing.

1. Required Development Resources

Use the following resources when available:

- "AGENTS.md": Mandatory project-wide development rules.
- Google Stitch UI mockup: Visual reference for the application.
- Existing Flutter project: Inspect and preserve relevant existing code.
- Firebase project configuration: Use only when provided.
- Groq API key: Must be provided by the user when AI functionality is tested against the real API.

Do not invent Firebase credentials, API keys, or project identifiers.

If a required external configuration is missing:

- Implement the relevant integration.
- Document the missing configuration.
- Provide clear manual setup instructions.
- Continue with other independent development tasks.

Do not claim that the application is fully configured or production-ready until the relevant setup and testing have actually been completed.

2. Core Product Requirements

The application must provide the following features.

Authentication

- Anonymous sign-in.
- Email/password registration.
- Email/password sign-in.
- Forgot password.
- Password reset.
- Anonymous-to-registered account linking.
- Profile avatar selection.
- Nickname.
- Email.
- Password.
- Confirm password.

Command Library

- Public command browsing.
- Global search.
- Category filtering.
- Sorting.
- Pagination.
- Command details.
- Favorites.
- Pins.
- Upload.
- Edit.
- Delete.
- Multi-step commands.
- Copy command.
- Copy all commands.
- Run through Termux.

User Profile

- Avatar.
- Nickname.
- Email.
- Account overview.
- Posts.
- Favorites.
- Pinned items.

Settings

- Light theme.
- Dark theme.
- System theme.
- Accent colors.
- Blur settings.
- Vibration settings.
- Font size.
- Font family.
- English.
- Myanmar.
- Cache management.
- Account management.
- AI configuration.

AI Assistant

- Groq BYOK.
- Dynamic model fetching.
- Dynamic model selection.
- API key testing.
- Full chat.
- Contextual AI.
- File attachments.
- AI history.
- Request caching.
- Command explanation.
- Command review.
- Translation.
- Upload assistance.

3. Application Architecture

Implement a feature-first architecture.

Follow the architecture and coding rules defined in "AGENTS.md".

The application must separate:

- Presentation.
- State management.
- Business logic.
- Data repositories.
- Local database.
- Firebase data sources.
- AI provider integrations.
- Termux integration.
- Platform-specific services.

Use reusable components.

Do not put the entire application into one file.

Do not mix Firebase queries directly into UI widgets.

Do not mix Groq API requests directly into UI widgets.

Keep external services replaceable.

The application must be designed so that:

- Firebase can later be replaced by Supabase.
- Groq can later be replaced by Gemini.
- Additional AI providers can be added.
- UI screens do not need major rewrites when providers change.

4. Local Database and Firebase

SQLite

Use SQLite for:

- Cached command posts.
- Cached command details.
- Search.
- Filtering.
- Sorting.
- Local AI history.
- AI request cache.
- Local synchronization state.
- Pending operations where applicable.

Use Drift or an equivalent maintainable SQLite abstraction.

Implement migrations.

Firebase

Use:

- Firebase Authentication.
- Cloud Firestore.

Firebase Storage must never be used.

Do not upload user files to Firebase Storage.

Do not introduce Firebase Storage dependencies.

Data Ownership

Public command posts belong to their authors.

Every post must contain:

- Unique ID.
- Author UID.
- Creation timestamp.
- Update timestamp.
- Version.
- Publication status.

User-specific preferences must not modify shared public command records.

Favorite and Pin Storage

The user has explicitly approved the following approach:

Store Favorite and Pin IDs in the user's profile document.

Do not create an individual Firestore document for every favorite or pin operation.

Favorite and Pin states must be specific to the current user.

The profile document should contain:

- Favorite command IDs.
- Pinned command IDs.
- Pin ordering.

Pinned IDs must preserve their user-defined ordering.

SQLite should also maintain a local representation of these preferences for immediate UI updates.

Requirements:

- Changes persist across app restarts.
- Changes persist across sign-out and subsequent sign-in.
- Changes synchronize to Firebase.
- Changes do not affect other users.
- Local search and filtering remain fast.

Consider Firestore document-size limits.

Do not silently lose preference data when limits are approached.

Document any practical limits and migration considerations.

5. Offline-First Synchronization

The user has explicitly approved:

Realtime Listener + SQLite Local Cache.

Implement the following behavior.

Initial Application Launch

1. Load the local database.
2. Display cached command data immediately.
3. Start background synchronization.
4. Update SQLite when remote changes arrive.
5. Update the UI through local database streams.

The user must not have to wait for Firebase before browsing cached commands.

Realtime Synchronization

Use Firestore realtime listeners where appropriate.

Avoid unnecessary listeners.

Listeners must:

- Have an appropriate lifecycle.
- Be disposed when no longer needed.
- Avoid duplicate subscriptions.
- Avoid unnecessary reads.
- Synchronize relevant changes into SQLite.

Search and Filtering

Search must use local SQLite data.

Do not send a Firestore request for every search keystroke.

Support:

- Name.
- Description.
- Category.
- Tags.
- Metadata where appropriate.

Use debounce when remote operations are necessary.

Swipe-to-Refresh

Implement swipe-to-refresh on relevant list screens.

The user must be able to manually request synchronization.

Provide meaningful feedback:

- Refreshing.
- Updated.
- Offline.
- Sync failed.
- Retry available.

Do not block the UI during synchronization.

Conflict Handling

Use a documented conflict-resolution strategy.

Track:

- Update timestamps.
- Versions.
- Pending operations.

Avoid silently overwriting important user changes.

6. Authentication Implementation

Implement Firebase Anonymous Authentication and Email/Password Authentication.

Registration

Required fields:

- Profile avatar.
- Nickname.
- Email.
- Password.
- Confirm password.

Provide built-in avatars.

Nickname must be customizable.

Email Handling

If the user enters an email username without a domain:

Example:

"myusername"

Automatically complete:

"myusername@gmail.com"

Do not modify an explicitly entered domain.

Validate email syntax.

Show clear error messages.

Password Handling

Provide:

- Eye toggle.
- Password validation.
- Confirm password matching.
- Minimum length.
- Password strength indication.
- Correct keyboard type.
- Correct focus behavior.
- Keyboard actions.

Do not implement:

- OTP confirmation.
- SMS verification.
- Mandatory email verification.

Do not make authentication unnecessarily complicated.

Anonymous Account Linking

A Guest user must be able to register without losing existing account data.

Preserve appropriate:

- Favorites.
- Pins.
- Local preferences.
- User-created local data.

Handle account-linking conflicts gracefully.

7. Role-Based Access Control

Use a simple standard authorization system.

Roles:

- Guest.
- Registered User.
- Admin.

Guest

Guests can:

- Browse public commands.
- Search cached commands.
- View command details.
- Copy commands.
- Use local favorites and pins.

Guests cannot:

- Upload public commands.
- Edit public commands.
- Delete public commands.

Registered User

Registered users can:

- Browse public commands.
- Upload commands.
- Edit their own commands.
- Delete their own commands.
- Manage their profile.
- Manage favorites and pins.

Admin

Admins can:

- Browse all public commands.
- Upload commands.
- Edit any command.
- Delete any command.
- Manage inappropriate or incorrect content.

UI Authorization

Hide Edit and Delete buttons when the user is not authorized.

Do not show unauthorized users unnecessary permission dialogs.

Database Authorization

Implement Firestore Security Rules.

Verify:

- Authenticated UID.
- Post author UID.
- Admin UID or authorized admin claim.

Users must not be able to grant themselves admin privileges.

Document the admin setup process.

Do not place Firebase service-account credentials in the Flutter application.

8. Command Categories

Implement these 10 default categories:

1. Package Management.
2. Linux Distributions.
3. Shell & Scripting.
4. File & Storage.
5. Git & Version Control.
6. Programming & Development.
7. Networking & Remote Access.
8. System & Process Management.
9. Termux API & Device Tools.
10. Security & Testing.

Category definitions should be maintainable.

Use category IDs instead of relying exclusively on display names.

Support tags independently from categories.

9. Command Upload

Create a complete upload form.

Required fields:

- Name.
- Description.
- Category.
- Tags.
- Metadata.
- Command steps.

Dynamic Command Steps

The user must be able to add multiple command steps.

Every step contains:

- Title.
- Description.
- Command.
- Order.

Support:

- Add.
- Remove.
- Reorder.
- Edit.

Preserve shell syntax exactly.

Do not trim meaningful command characters.

Do not automatically rewrite command content.

Provide validation.

Support long commands and multiline input.

AI Assistance

Allow contextual AI assistance for:

- Title generation.
- Description rewriting.
- English/Myanmar translation.
- Command explanation.
- Command review.
- Potential error detection.

AI suggestions must not overwrite user content without confirmation.

The user must be able to accept, reject, or edit suggestions.

10. Command Details

Create a complete details screen.

Display:

- Name.
- Description.
- Category.
- Tags.
- Metadata.
- Author.
- Creation time.
- Update time.
- Favorite.
- Pin.
- Command steps.

Each command step must support:

- Copy.
- Run.
- Step title.
- Description.

Support Copy All Commands.

The user must be able to ask the AI assistant about the command.

Provide contextual translation and explanation.

Hide Edit/Delete controls when unauthorized.

11. Termux Integration

The app must not behave as a terminal emulator.

Provide:

- Run in Termux.
- Copy command.
- Copy all commands.
- Termux detection.
- Permission guidance.
- Installation guidance.

Official Termux releases:

https://github.com/termux/termux-app/releases

Implement the supported Android integration.

Before running:

- Display the command.
- Show a confirmation.
- Allow cancellation.
- Warn about potentially destructive operations.

Do not silently execute commands.

Do not claim successful execution without appropriate confirmation.

If Termux is missing:

- Display a helpful dialog.
- Provide the official release link.
- Explain how to install Termux.

If the required permission is missing:

- Explain the permission.
- Provide the relevant setup guidance.

12. Home Dashboard

Implement a polished dashboard.

Top Bar

Display:

- Dynamic welcome message.
- Nickname.
- AI Assistant button.
- Settings button.

Welcome messages may depend on:

- Time of day.
- New or returning user state.

Dashboard Metrics

Display:

- Total Posts.
- My Posts.
- Favorites.
- Pinned Items.

Use appropriate charts and summary cards.

Interactive Charts

Tapping a metric or chart category must filter the command list.

Pinned Commands Widget

Support:

- Horizontal scrolling.
- Drag-and-drop reordering.
- Command name.
- Description.
- Metadata.
- Run.
- Copy.

The widget must display the user's own pinned items.

Do not let one user's pin ordering affect another user's dashboard.

Global Search

Implement:

- Search input.
- Category filters.
- Sorting.
- Pagination.
- Swipe-to-refresh.

Search must operate on local SQLite data.

13. Profile Screen

Create a profile overview.

Display:

- Avatar.
- Nickname.
- Email.
- Account type.
- Posts.
- Favorites.
- Pins.

Provide category-based tabs.

Support:

- Filtering.
- Sorting.
- Viewing details.
- Editing profile information.

Do not display private information unnecessarily.

14. Settings

Implement the following settings.

Theme

- Light.
- Dark.
- System Default.

Accent Colors

Provide a professional color palette.

Blur

- Enable/Disable.
- Intensity control.

Vibration

- Off.
- Light.
- Medium.
- Strong.

Typography

- Font size.
- System default font.
- Nine readable font families.

Ensure Myanmar text renders correctly.

Use fallback fonts where necessary.

Localization

Support:

- English.
- Myanmar.

English is the default language.

All important UI strings must use localization resources.

Do not hard-code translatable text directly throughout the UI.

Data Management

Provide:

- Clear Cache.
- Reset Settings.
- Restart App.

Clear Cache must not delete:

- User account.
- Favorite IDs.
- Pin IDs.
- Public posts from the remote database.
- Important unsynchronized operations.

Account Management

Provide:

- Edit avatar.
- Edit nickname.
- Change password.
- Reset password.
- Clear account data.
- Delete account.
- Sign out.

Use appropriate confirmations.

Handle re-authentication for sensitive account operations.

15. AI Assistant

Implement a dedicated AI chat screen.

Chat Features

Support:

- Command-related questions.
- File attachments.
- Conversation history.
- Model selection.
- Message composition.
- Loading states.
- Error states.
- Retry.

Contextual Assistant

The assistant must also be available from:

- Upload screen.
- Command details screen.

Use an appropriate dialog or bottom sheet.

Support:

- Command explanations.
- Translation.
- Command review.
- Description generation.
- Title generation.
- Contextual questions.

Provider Architecture

Create a provider abstraction.

Initial provider:

- Groq.

Do not hard-code the model name.

Fetch the available model list from Groq.

Allow the user to select a model.

The architecture must support future providers such as Gemini.

BYOK

The user provides their own API key.

Store the key using secure local storage.

Do not send the API key to Firebase.

Do not log the API key.

Provide:

- Get Key.
- Test Key.
- Fetch Models.
- Model selector.
- Enable/Disable.
- Setup Guide.
- Help dialog.

AI History

Store AI history locally by default.

Support:

- Listing.
- Searching.
- Deleting individual history.
- Clearing all history.

AI Cache

Use a local request cache.

The cache key must account for:

- Provider.
- Model.
- Prompt.
- Context.
- Parameters.
- Prompt version.

Implement cache expiration.

Do not return an unrelated cached response.

File Attachments

Use a file picker.

Initially support appropriate text-based formats:

- TXT.
- MD.
- SH.
- PY.
- LOG.

Implement file size limits.

Do not upload files to Firebase Storage.

Do not send file contents to an AI provider without an explicit user action.

16. UI/UX Implementation

Use the provided Google Stitch mockup as the visual reference.

Implement a production-level interface.

The application must not look:

- Cyberpunk.
- Hacker-themed.
- Overly technical.
- Overly decorative.

Use:

- Material 3 foundations.
- Clean cards.
- Professional colors.
- Reusable design tokens.
- Consistent spacing.
- Smooth animations.
- Appropriate transitions.
- Selective frosted-glass effects.

Avoid:

- Random spacing values.
- Excessive blank spaces.
- Unnecessary dividers.
- Excessive nested cards.
- Inconsistent dimensions.
- Unnecessary animation.
- Excessive blur.

Define reusable tokens for:

- Spacing.
- Colors.
- Typography.
- Radius.
- Elevation.
- Component sizing.

Use an appropriate 4dp-based spacing system.

Do not force floating navigation and content cards to have identical widths.

17. Android System UI

Correctly handle:

- Status bar.
- Navigation bar.
- Gesture navigation.
- Three-button navigation.
- Edge-to-edge layout.
- Safe areas.

Light theme must use readable status bar icons.

Dark theme must use readable status bar icons.

Navigation bar colors must match the application theme.

Avoid black/white navigation bar mismatches.

Test appropriate Android versions and navigation modes.

18. Reusable Components

Create reusable components for:

- Buttons.
- Inputs.
- Cards.
- Command code blocks.
- Command steps.
- Search bars.
- Filters.
- Dialogs.
- Bottom sheets.
- Toasts.
- Snackbars.
- Loading states.
- Empty states.
- Error states.
- Confirmation dialogs.

Use reusable components where they improve maintainability.

Do not abstract components unnecessarily.

19. Performance

The application must feel smooth.

Requirements:

- Avoid unnecessary widget rebuilds.
- Use lazy lists.
- Use pagination.
- Use local search.
- Avoid repeated network calls.
- Avoid unnecessary listeners.
- Avoid excessive blur.
- Avoid large unnecessary assets.
- Avoid unnecessary dependencies.
- Dispose controllers and subscriptions.
- Keep the UI responsive during asynchronous operations.

Do not compromise maintainability merely to reduce code size.

20. Documentation

Create the following documentation:

README.md

Include:

- Project overview.
- Features.
- Technology stack.
- Architecture overview.
- Build instructions.

Burmese Setup Documentation

Create a dedicated Burmese Markdown file.

Explain:

- Flutter installation.
- Android development setup.
- Firebase project creation.
- Firebase Authentication configuration.
- Firestore configuration.
- Firestore Security Rules.
- Admin configuration.
- Groq API key setup.
- Termux integration.
- Android permissions.
- Build and run instructions.
- Troubleshooting.

The documentation must explain every manual step that the user needs to perform.

Do not assume the user already knows Firebase configuration.

Additional Documentation

Create:

- Architecture documentation.
- Database schema documentation.
- Synchronization documentation.
- AI provider documentation.
- Testing documentation.

21. Testing

Implement appropriate tests.

Required test areas:

- Authentication.
- Anonymous account linking.
- Firestore authorization.
- SQLite persistence.
- Synchronization.
- Search.
- Filtering.
- Sorting.
- Favorite persistence.
- Pin persistence.
- Multi-step commands.
- Termux integration.
- AI provider logic.
- AI caching.
- Theme behavior.
- Widget behavior.

Use Firebase Emulator Suite when appropriate.

Run:

- Dart format.
- Flutter analyze.
- Unit tests.
- Widget tests.
- Integration tests where possible.

Do not claim tests passed unless they have actually been executed.

22. GitHub Workflow

After every meaningful coding change:

1. Inspect modified files.
2. Format code.
3. Run static analysis.
4. Run relevant tests.
5. Review Git diff.
6. Check for secrets.
7. Summarize the changes.
8. Ask the user for permission before pushing to GitHub.

Do not push without explicit approval.

Do not commit API keys, Firebase service-account credentials, or sensitive configuration.

Do not overwrite unrelated user changes.

23. Development Execution Plan

Implement the application incrementally.

Phase 1 — Foundation

- Inspect project.
- Review UI mockup.
- Establish architecture.
- Configure dependencies.
- Create design tokens.
- Set up routing.
- Set up localization.
- Set up state management.

Phase 2 — Local Database

- Create SQLite schema.
- Implement migrations.
- Implement local repositories.
- Implement local search.
- Implement local filtering.
- Implement local sorting.

Phase 3 — Firebase

- Configure Firebase Authentication.
- Configure Firestore.
- Implement repositories.
- Implement Security Rules.
- Implement profile data.
- Implement authorization.

Phase 4 — Synchronization

- Implement realtime listeners.
- Implement SQLite updates.
- Implement listener lifecycle.
- Implement sync status.
- Implement retry.
- Implement swipe-to-refresh.
- Implement conflict handling.

Phase 5 — Authentication UI

- Splash.
- Welcome.
- Guest.
- Sign-in.
- Sign-up.
- Password reset.
- Account linking.

Phase 6 — Command Library

- Dashboard.
- Search.
- Filters.
- Sorting.
- Command list.
- Command details.
- Favorites.
- Pins.
- Pin ordering.

Phase 7 — Upload

- Dynamic command steps.
- Validation.
- Upload.
- Edit.
- Delete.
- Authorization.
- AI assistance.

Phase 8 — Profile and Settings

- Profile overview.
- Account management.
- Theme.
- Accent colors.
- Blur.
- Vibration.
- Typography.
- Localization.
- Data management.

Phase 9 — Termux Integration

- Copy.
- Run.
- Permission handling.
- Termux detection.
- Installation guidance.
- Confirmation dialogs.

Phase 10 — AI

- Provider abstraction.
- Groq provider.
- API key storage.
- Model fetching.
- Model selection.
- Chat.
- Contextual assistant.
- File picker.
- AI history.
- AI cache.

Phase 11 — Finalization

- Documentation.
- Testing.
- Performance optimization.
- Error handling.
- Accessibility.
- UI refinement.
- Final validation.

24. Important Development Rules

Do not generate a large amount of code without inspecting the project.

Do not implement the application as a single monolithic file.

Do not ignore the UI mockup.

Do not silently skip difficult features.

Do not replace real functionality with fake buttons.

Do not hard-code API keys.

Do not hard-code AI model names.

Do not use Firebase Storage.

Do not introduce OTP authentication.

Do not store user-specific favorite/pin status on shared command posts.

Do not rely solely on hidden buttons for authorization.

Do not claim that Termux commands have executed without appropriate confirmation.

Do not claim that the app is complete without relevant testing.

If a requirement cannot be implemented exactly because of Android, Firebase, or provider limitations:

- Explain the limitation.
- Implement the closest supported behavior.
- Document the required manual configuration.
- Do not misrepresent the result.

25. Final Deliverable

The final deliverable must be a complete Flutter Android project.

It must include:

- Application source code.
- Organized folder structure.
- SQLite database implementation.
- Firebase integration.
- Authentication.
- Authorization.
- Realtime synchronization.
- Command library.
- Multi-step command support.
- Upload and CRUD.
- Favorites and pins.
- Termux integration.
- AI provider abstraction.
- Groq BYOK.
- AI assistant.
- Settings.
- Profile.
- Localization.
- Light and dark themes.
- Burmese documentation.
- Appropriate tests.

The app must be maintainable and ready for continued development.

Prioritize:

1. Correct functionality.
2. Excellent user experience.
3. Maintainable architecture.
4. Performance.
5. Security appropriate for a hobby project.
6. Clear documentation.
7. Reliable testing.

Begin by inspecting the existing project and reviewing the UI mockup.

Then implement the application incrementally according to this specification and "AGENTS.md".