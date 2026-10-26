# Admin configuration

Admin privileges are a Firebase Authentication **custom claim**:

```json
{ "admin": true }
```

They are never stored in a Firestore profile document. This prevents a user from
granting themselves admin by editing data the client can write.

Firestore rules check the claim directly:

```text
request.auth.token.admin == true
```

## 1. Find the user's UID

Firebase console → **Authentication** → **Users** → copy the UID, or use the
Admin SDK:

```js
const user = await admin.auth().getUserByEmail('admin@example.com');
console.log(user.uid);
```

## 2. Grant the claim with the Admin SDK

Use a trusted machine. Install the Admin SDK in a temporary directory outside the
repository, authenticate with Application Default Credentials, and run a one-off
script. **Never commit the service-account JSON.**

```bash
mkdir -p ~/firebase-admin-tools
cd ~/firebase-admin-tools
npm init -y
npm install firebase-admin
```

`set-admin-claim.mjs`:

```js
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const projectId = process.env.FIREBASE_PROJECT_ID;
const uid = process.argv[2];
const enable = process.argv[3] !== 'false';

if (!projectId || !uid) {
  console.error('Usage: FIREBASE_PROJECT_ID=... node set-admin-claim.mjs <uid> [true|false]');
  process.exit(1);
}

initializeApp({
  credential: applicationDefault(),
  projectId,
});

const auth = getAuth();
const user = await auth.getUser(uid);
const claims = { ...(user.customClaims ?? {}) };

if (enable) {
  claims.admin = true;
} else {
  delete claims.admin;
}

await auth.setCustomUserClaims(uid, claims);
console.log(`${enable ? 'Granted' : 'Removed'} admin for ${uid}`);
```

Authenticate once:

```bash
gcloud auth application-default login
# or, without gcloud:
# export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json
```

Then:

```bash
FIREBASE_PROJECT_ID=your-project-id node set-admin-claim.mjs THE_UID true
FIREBASE_PROJECT_ID=your-project-id node set-admin-claim.mjs THE_UID false
```

The script preserves any other custom claims already on the account. It does not
touch Firestore documents.

## 3. Refresh the user's token

Custom claims are embedded in the ID token. An already signed-in client keeps the
old token until it refreshes. The user should:

1. Sign out and sign in again, or
2. Restart the app after the claim is set, or
3. Use an explicit token-refresh path if one is added later.

The app's account settings include a refresh action that calls
`AuthRepository.refreshIdentityClaims()`. It is still safest to sign out and back
in after changing claims.

## 4. Verify the claim

In the Admin SDK:

```js
const user = await admin.auth().getUser(THE_UID);
console.log(user.customClaims); // { admin: true }
```

In a client after refreshing:

```dart
final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
print(token?.claims?['admin']);
```

In Firestore, the admin can now read drafts and edit or delete another user's
guide. The app exposes admin affordances based on the session's `isAdmin` flag,
but Firestore rules remain the authority.

## 5. Remove admin access

```bash
FIREBASE_PROJECT_ID=your-project-id node set-admin-claim.mjs THE_UID false
```

The user must refresh their token again. Removing admin does not remove their
account or their own guides.

## Operational guidance

- Keep the number of admins small.
- Grant admin only to accounts with strong passwords and, ideally, MFA. The app
  does not implement MFA flows; configure it in Firebase Authentication if
  needed and verify the sign-in UX separately.
- Audit account UIDs and claims periodically with the Admin SDK.
- Never put a privileged token, service-account key or admin credential in the
  Flutter app, `--dart-define`, Firestore, logs or Git.
- Do not create a `roles` collection or a `role` field as a shortcut. It would
  require a different security review and would duplicate the Auth claim.
- Server-side maintenance (bulk moderation, account migration) should use the
  Admin SDK, not a hidden client endpoint.
