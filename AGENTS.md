AGENTS.md

Termux Command Library — Development Guidelines

1. Project Overview

Build a production-quality Android application named Termux Command Library using Flutter and Dart.

The application is a community-driven library for Termux commands and multi-step command guides.

Users can:

- Browse public commands.
- Search, filter, and sort commands.
- Upload command guides.
- Create multi-step command sequences.
- Copy commands.
- Execute commands through Termux integration.
- Favorite and pin commands.
- Manage their profile.
- Customize the application.
- Use an optional AI assistant powered by Groq BYOK.

The application must be smooth, lightweight, maintainable, and visually polished.

Do not treat this project as a disposable prototype.

2. Mandatory Technology Stack

Use:

- Flutter.
- Dart.
- Android as the primary platform.
- Firebase Authentication.
- Cloud Firestore.
- SQLite for local persistence.
- Drift as the preferred SQLite abstraction.
- Riverpod for state management.
- go_router for navigation.
- flutter_secure_storage for sensitive local secrets.
- Material 3 with a custom design system.

Use suitable maintained packages when they provide clear value.

Do not add dependencies without a reason.

Firebase Storage is explicitly prohibited.

Firebase must be used only for Authentication and Database functionality in this project.

Do not introduce Firebase Storage, Cloud Storage, or other Firebase Storage-based solutions.

3. Architecture

Use a maintainable feature-first architecture.

Recommended structure:

lib/
app/
app.dart
router/
theme/
localization/
core/
constants/
errors/
extensions/
utils/
design_system/
widgets/
data/
local/
database/
dao/
remote/
firebase/
repositories/
features/
authentication/
home/
command_library/
command_details/
upload/
profile/
settings/
ai_assistant/
services/
termux/
ai/
secure_storage/
clipboard/
haptics/
shared/
widgets/

This structure is a guideline. Adapt it when necessary without compromising separation of concerns.

Architecture Requirements

- Separate UI from business logic.
- Separate business logic from persistence.
- Use repositories for data access.
- Use interfaces or abstractions for external services.
- Keep Firebase-specific implementation out of feature UI.
- Keep AI-provider-specific implementation out of feature UI.
- Use dependency injection.
- Avoid global mutable state.
- Avoid circular dependencies.
- Avoid oversized files.
- Avoid putting the entire application into a single file.

The application must remain maintainable if Firebase is replaced by Supabase or another backend.

The AI system must remain maintainable if Groq is replaced by Gemini or another provider.

4. State Management

Use Riverpod consistently.

Requirements:

- Keep state management predictable.
- Avoid unnecessary rebuilds.
- Separate loading, success, empty, and error states.
- Use immutable state where appropriate.
- Dispose resources correctly.
- Avoid unnecessary network calls.
- Avoid duplicated state.
- Keep UI responsive during asynchronous operations.

5. Database Architecture

Local Database

Use SQLite through Drift.

SQLite is the primary local source for:

- Cached public commands.
- Search.
- Filtering.
- Sorting.
- Cached command details.
- Pending synchronization operations.
- Local AI history.
- AI request cache.
- Non-sensitive application data.

Sensitive API keys must not be stored in SQLite.

Use schema migrations.

Do not delete local data unexpectedly during upgrades.

Firebase Database

Use Cloud Firestore for:

- Public command posts.
- User profiles.
- User favorite IDs.
- User pinned IDs and ordering.
- Authentication-related profile metadata.
- Online synchronization.

Do not use Firebase Storage.

Favorite and Pin Storage

Favorites and Pins belong to individual users.

Do not store user-specific favorite or pin status directly on shared public command documents.

Store favorite command IDs and pinned command IDs in the user's profile document.

Pinned IDs must preserve user-defined ordering.

Maintain a local SQLite representation for immediate UI access.

The state must survive:

- App restarts.
- Device restarts.
- Sign-out and subsequent sign-in.
- Offline periods.

Do not create a separate Firestore document for every favorite or pin operation unless explicitly approved.

Consider Firestore document-size limits and provide a reasonable migration path if the collection grows significantly.

6. Offline-First Synchronization

The application must use SQLite as the primary source for displaying and searching cached data.

Use Firestore realtime listeners for online synchronization.

Required behavior:

1. Load local SQLite data immediately.
2. Display cached content without waiting for Firebase.
3. Start background synchronization.
4. Update SQLite when remote changes arrive.
5. Notify the UI through local database streams.
6. Keep the UI responsive during synchronization.
7. Provide a manual swipe-to-refresh action.
8. Display synchronization errors without blocking local usage.
9. Retry failed operations appropriately.
10. Avoid unnecessary listener creation.

Do not perform Firebase queries for every search input.

Search, filter, and sort should operate on SQLite data.

Use pagination for large datasets.

Use appropriate debounce for remote query changes.

Prevent duplicate records during synchronization.

Handle timestamps and document versions consistently.

If an offline mutation is supported, store it in a local pending-operation queue and synchronize it when connectivity returns.

Do not silently discard pending changes.

Handle conflicting updates using a documented conflict-resolution strategy.

7. Authentication

Support:

- Firebase Anonymous Authentication.
- Email/Password Registration.
- Email/Password Sign-in.
- Password Reset.
- Anonymous-to-Registered Account Linking.
- Sign Out.
- Account Deletion.

Registration fields:

- Avatar.
- Nickname.
- Email.
- Password.
- Confirm Password.

Email Handling

If the user enters a username without a domain, support automatic Gmail completion.

Example:

"myusername" -> "myusername@gmail.com"

Do not alter explicitly entered non-Gmail domains.

Validate email syntax.

Password Handling

Provide:

- Password visibility toggle.
- Confirm password matching.
- Password validation.
- Clear validation messages.
- Appropriate keyboard types.
- Correct focus traversal.
- Keyboard actions.
- Loading states.
- Error states.

Do not implement:

- OTP confirmation.
- SMS verification.
- Mandatory email verification flows.

Do not implement unnecessary authentication steps.

8. Authorization

Use a simple, standard authorization model.

Roles:

- Guest.
- Registered User.
- Admin.

Each command post must contain an immutable author UID.

Authorization requirements:

- Guests may browse public posts.
- Guests may use local favorites and pins.
- Guests cannot upload public posts.
- Registered users may upload.
- Registered users may edit/delete their own posts.
- Admins may manage all posts.

Do not rely only on hiding buttons.

Enforce authorization through Firestore Security Rules.

The application must not allow users to modify their own role or admin status.

Do not hard-code a privileged Firebase service-account secret into the application.

Admin configuration must be documented.

9. Command Data Model

A command post should support:

- id.
- name.
- description.
- categoryId.
- tags.
- metadata.
- steps.
- authorUid.
- createdAt.
- updatedAt.
- version.
- status.

Each command step should support:

- id.
- order.
- title.
- description.
- command.
- runMode.

A command may contain multiple sequential steps.

Support:

- Add step.
- Remove step.
- Reorder steps.
- Edit steps.
- Copy individual steps.
- Copy all commands.

Preserve:

- Newlines.
- Whitespace.
- Shell syntax.
- Quoting.
- Special characters.

Do not automatically modify command strings.

Do not assume all commands are one line.

10. Termux Integration

The app is not a terminal emulator.

Provide:

- Copy command.
- Copy all commands.
- Run through Termux integration.
- Termux availability detection.
- Permission guidance.
- Termux installation guidance.

Official Termux releases:

https://github.com/termux/termux-app/releases

Use Android-compatible Termux integration.

Do not claim that a command has executed unless the integration actually confirms the relevant action.

Do not silently execute commands.

Before execution:

- Show the command.
- Provide an appropriate confirmation.
- Allow cancellation.
- Display warnings for potentially destructive commands.

The user must understand whether a command will be executed or copied.

Handle unavailable Termux and missing permissions gracefully.

11. AI Provider Architecture

Implement a provider abstraction.

The application must not directly depend on Groq throughout the UI.

Create an AI provider interface that supports:

- API key validation.
- Model listing.
- Model selection.
- Chat requests.
- Contextual requests.
- Error handling.
- Usage metadata where available.

Initial provider:

- Groq.

Future providers may include:

- Gemini.
- Other compatible providers.

Do not hard-code a model name.

Fetch available models dynamically from the provider API.

Allow the user to select a model.

BYOK

Users must provide their own API key.

Store API keys using secure local storage.

Never send API keys to Firebase.

Never include API keys in:

- Logs.
- Crash reports.
- Analytics.
- AI history.
- GitHub commits.

Provide:

- Get Key.
- Test Key.
- Fetch Models.
- Model selector.
- Enable/Disable AI.
- Setup guide.
- Help dialog.

Do not claim that secure storage makes a compromised device completely secure.

12. AI Assistant

The assistant must support:

Full Chat

- Command-related conversations.
- File attachments.
- Model selection.
- Chat history.
- Contextual explanations.

Contextual Assistant

- Upload form assistance.
- Command detail assistance.
- Title generation.
- Description rewriting.
- English/Myanmar translation.
- Command review.
- Command explanation.

AI Cache

Use local caching to reduce unnecessary API calls.

Cache identity must account for:

- Provider.
- Model.
- Prompt.
- Context.
- Relevant request parameters.
- Prompt version.

Use a configurable cache expiration policy.

Do not return incorrect cached results when request contexts differ.

AI History

Store AI history locally by default.

Support:

- History listing.
- Search.
- Delete individual history.
- Clear all history.

Do not synchronize AI history to Firebase by default.

Do not send file contents without an explicit user action.

Limit supported file types and file sizes.

13. UI/UX Design System

The application must feel like a premium productivity application.

Do not use:

- Hacker themes.
- Cyberpunk themes.
- Excessive neon colors.
- Excessive technical decorations.
- Random spacing values.
- Excessive blank spaces.
- Excessive nested cards.
- Unnecessary dividers.

Use:

- Material 3 foundations.
- Consistent spacing tokens.
- Consistent typography.
- Professional colors.
- Reusable components.
- Subtle animations.
- Selective frosted-glass effects.
- Clean card layouts.
- Appropriate information density.

Define reusable design tokens for:

- Colors.
- Spacing.
- Typography.
- Radii.
- Elevation.
- Icon sizes.
- Animation durations.
- Component dimensions.

Use a 4dp-based spacing system.

Do not force unrelated components to share the same width.

14. Theme and Android System UI

Support:

- Light.
- Dark.
- System Default.

Correctly handle:

- Status bar color.
- Status bar icon brightness.
- Navigation bar color.
- Navigation bar icon brightness.
- Gesture navigation.
- Three-button navigation.
- Safe areas.
- Edge-to-edge layouts.

The navigation bar must match the application theme.

Avoid black/white mismatches.

Ensure status bar icons remain visible in both themes.

Do not assume all Android devices behave identically.

Test on appropriate Android versions.

15. Customization

Provide:

- Accent color selection.
- Blur enable/disable.
- Blur intensity.
- Vibration intensity.
- Font size.
- Font family.
- System default font.
- Nine popular readable font families.
- English.
- Myanmar.

Myanmar text must remain readable.

Use appropriate font fallback when a selected font does not contain Myanmar glyphs.

Avoid unnecessary bundled font files.

Respect font licenses.

16. Account Management

Provide:

- Edit avatar.
- Edit nickname.
- Change password.
- Reset password.
- Clear account data.
- Delete account.
- Sign out.

Destructive operations require confirmation.

Use appropriate re-authentication for sensitive account operations.

Clearly explain the difference between clearing local data and deleting an account.

Do not silently delete public posts when the user clears local cache.

17. Performance

Performance is a core requirement.

Avoid:

- Unnecessary rebuilds.
- Excessive animations.
- Excessive blur.
- Large bundled assets.
- Unnecessary dependencies.
- Unbounded database queries.
- Repeated API calls.
- Long-running synchronous operations on the UI thread.

Use lazy lists and pagination.

Keep search responsive.

Use appropriate image caching and memory management.

Do not compromise maintainability merely to reduce file count.

18. Error Handling

Provide meaningful errors for:

- Network failures.
- Authentication failures.
- Firebase permission errors.
- AI API failures.
- Rate limits.
- Invalid API keys.
- Missing Termux.
- Missing Termux permissions.
- Database failures.
- Invalid command input.

Use appropriate:

- Dialogs.
- Bottom sheets.
- Snackbars.
- Toasts.
- Inline validation.
- Retry actions.

Avoid generic errors when a useful explanation is possible.

19. Code Quality

Requirements:

- Follow Dart conventions.
- Use meaningful names.
- Write reusable components.
- Avoid giant files.
- Avoid duplicated logic.
- Document complex logic.
- Comment important architectural decisions.
- Keep comments useful and accurate.
- Avoid unnecessary comments that simply repeat the code.
- Use typed models.
- Handle null safety correctly.
- Use immutable models where appropriate.
- Maintain clear file boundaries.

Do not leave unfinished placeholders for required features.

Do not claim that a feature is complete if it has not been implemented and tested.

20. Testing

Create appropriate tests.

Required areas:

- Authentication.
- Anonymous account linking.
- Firestore authorization.
- Repository logic.
- SQLite persistence.
- Synchronization.
- Search and filtering.
- Favorite and pin persistence.
- Multi-step command handling.
- Termux integration.
- AI provider logic.
- AI cache.
- Theme behavior.
- Widget behavior.

Use Firebase Emulator Suite where appropriate.

Run:

- Dart formatting.
- Flutter analysis.
- Unit tests.
- Widget tests.
- Relevant integration tests.

Resolve errors before claiming completion.

21. GitHub Workflow

After each meaningful coding change:

1. Inspect the changes.
2. Run formatting.
3. Run static analysis.
4. Run relevant tests.
5. Inspect the Git diff.
6. Identify sensitive files.
7. Explain the changes.
8. Ask the user for permission before pushing to GitHub.

Do not push without explicit user approval.

Never commit API keys, Firebase service-account credentials, or other secrets.

Do not overwrite unrelated user changes.

22. Documentation

Create documentation in Markdown.

Required:

- README.md.
- Burmese setup documentation.
- Firebase setup.
- Firebase Authentication setup.
- Firestore setup.
- Security Rules.
- Admin configuration.
- Groq API setup.
- Android Termux integration setup.
- Build instructions.
- Troubleshooting.
- Architecture overview.
- Data synchronization overview.

The Burmese documentation must explain all manual setup steps clearly.

23. Development Workflow

Follow this order:

1. Inspect the project.
2. Review the provided UI mockup.
3. Establish architecture.
4. Establish design tokens.
5. Configure Flutter and dependencies.
6. Implement local database.
7. Implement Firebase repositories.
8. Implement authentication.
9. Implement synchronization.
10. Implement command library.
11. Implement upload and details.
12. Implement profile and settings.
13. Implement Termux integration.
14. Implement AI provider abstraction.
15. Implement AI assistant.
16. Implement documentation.
17. Implement tests.
18. Validate the complete application.

Do not implement everything in one giant file or one unreviewable change.

If an external credential or manual configuration is required, document it and request the necessary input.

Do not invent credentials or claim external setup has been completed when it has not.

24. Final Acceptance Criteria

The application must:

- Build successfully.
- Launch successfully.
- Support offline browsing.
- Synchronize online data.
- Preserve user favorites and pins.
- Enforce owner/admin authorization.
- Support multi-step commands.
- Support copy and Termux execution.
- Support BYOK AI.
- Provide a consistent light/dark theme.
- Maintain a clean and professional UI.
- Include Burmese setup documentation.
- Include appropriate tests.

Prioritize correctness, usability, maintainability, and performance over unnecessary complexity.