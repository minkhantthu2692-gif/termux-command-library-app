import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../models/auth_models.dart';
import 'cloud_gateways.dart';
import 'firebase_errors.dart';
import 'google_identity_client.dart';

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth, {GoogleIdentityClient? googleIdentity})
    : _googleIdentity = googleIdentity ?? GoogleSignInIdentityClient();

  final FirebaseAuth _auth;
  final GoogleIdentityClient _googleIdentity;

  /// Last session resolved with token claims. The synchronous `currentSession`
  /// getter cannot await `getIdTokenResult`, but reusing the resolved session
  /// avoids reporting a stale `isAdmin: false` after a claim refresh.
  AuthSession? _lastSession;

  @override
  AuthSession? get currentSession {
    final user = _auth.currentUser;
    if (user == null) return null;
    final cached = _lastSession;
    if (cached != null && cached.uid == user.uid) return cached;
    return _syncSession(user);
  }

  @override
  Stream<AuthSession?> watchSessions() {
    return _auth.authStateChanges().asyncMap(_asyncSession);
  }

  AuthSession _syncSession(User user) => AuthSession(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    isAnonymous: user.isAnonymous,
    isAdmin: false,
    isLocalOnly: false,
  );

  Future<AuthSession?> _asyncSession(
    User? user, {
    bool forceRefreshToken = false,
  }) async {
    if (user == null) {
      _lastSession = null;
      return null;
    }
    var isAdmin = false;
    try {
      final token = await user.getIdTokenResult(forceRefreshToken);
      isAdmin = token.claims?['admin'] == true;
    } catch (_) {
      // A missing claim or a refresh hiccup must not prevent sign-in. Firestore
      // rules remain the actual authorization boundary.
    }
    return _lastSession = AuthSession(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      isAnonymous: user.isAnonymous,
      isAdmin: isAdmin,
      isLocalOnly: false,
    );
  }

  @override
  Future<AuthSession> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          AppErrorCode.authRequired,
          message: 'Anonymous sign-in returned no user.',
        );
      }
      return (await _asyncSession(user))!;
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          AppErrorCode.authRequired,
          message: 'Registration returned no user.',
        );
      }
      return (await _asyncSession(user))!;
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(AppErrorCode.authRequired);
      }
      return (await _asyncSession(user))!;
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<AuthSession> signInWithProvider(
    AuthProviderKind provider, {
    bool linkAnonymous = false,
  }) async {
    try {
      return switch (provider) {
        AuthProviderKind.google => await _signInWithGoogle(
          linkAnonymous: linkAnonymous,
        ),
        // GitHub uses the device flow and calls
        // [signInWithGithubAccessToken] instead. Reject the hosted browser
        // flow explicitly so it cannot be reintroduced by accident.
        AuthProviderKind.github => throw const AppException(
          AppErrorCode.authProviderUnavailable,
          message: 'GitHub sign-in requires the device flow.',
        ),
      };
    } catch (error) {
      throw mapProviderAuthError(error);
    }
  }

  /// Uses the native Google account picker and exchanges its ID token for a
  /// Firebase credential. This avoids the Firebase hosted browser flow that
  /// fails with "missing initial state" when browser session storage is
  /// partitioned or cleared.
  Future<AuthSession> _signInWithGoogle({required bool linkAnonymous}) async {
    final identity = await _googleIdentity.authenticate();
    final firebaseCredential = GoogleAuthProvider.credential(
      idToken: identity.idToken,
    );
    final current = _auth.currentUser;
    final UserCredential credential;
    if (linkAnonymous && current != null && current.isAnonymous) {
      credential = await current.linkWithCredential(firebaseCredential);
    } else {
      credential = await _auth.signInWithCredential(firebaseCredential);
    }
    return await _completeProviderSignIn(
      credential,
      linkAnonymous: linkAnonymous,
    );
  }

  /// GitHub's token comes from the OAuth device flow. Exchanging the device
  /// code for an access token happens in [HttpGithubDeviceClient]; the client
  /// secret stays in the Firebase console and never ships in the app.
  @override
  Future<AuthSession> signInWithGithubAccessToken(
    String accessToken, {
    bool linkAnonymous = false,
  }) async {
    try {
      final firebaseCredential = GithubAuthProvider.credential(accessToken);
      final current = _auth.currentUser;
      final UserCredential credential;
      if (linkAnonymous && current != null && current.isAnonymous) {
        credential = await current.linkWithCredential(firebaseCredential);
      } else {
        credential = await _auth.signInWithCredential(firebaseCredential);
      }
      return await _completeProviderSignIn(
        credential,
        linkAnonymous: linkAnonymous,
      );
    } catch (error) {
      throw mapProviderAuthError(error);
    }
  }

  Future<AuthSession> _completeProviderSignIn(
    UserCredential credential, {
    required bool linkAnonymous,
  }) async {
    final user = credential.user;
    if (user == null) {
      throw const AppException(AppErrorCode.authRequired);
    }
    // Linking changes the token's sign_in_provider claim, which Firestore rules
    // check. Force one refresh so writes made right after the provider flow are
    // not rejected with the old anonymous token.
    return (await _asyncSession(user, forceRefreshToken: linkAnonymous))!;
  }

  @override
  Future<AuthSession> linkAnonymousAccount({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        throw const AppException(AppErrorCode.authRequired);
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final result = await user.linkWithCredential(credential);
      final linked = result.user;
      if (linked == null) {
        throw const AppException(AppErrorCode.authRequired);
      }
      // The token's sign_in_provider changes from `anonymous` to `password`;
      // refresh it so Firestore rules see the upgraded account immediately.
      return (await _asyncSession(linked, forceRefreshToken: true))!;
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AppException(AppErrorCode.authRequired);
      await user.updateDisplayName(displayName);
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AppException(AppErrorCode.authRequired);
      await user.sendEmailVerification();
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<AuthSession> refreshSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AppException(AppErrorCode.authRequired);
      await user.reload();
      return (await _asyncSession(user, forceRefreshToken: true))!;
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw const AppException(AppErrorCode.authRequired);
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AppException(AppErrorCode.authRequired);
      await user.updatePassword(newPassword);
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _lastSession = null;
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AppException(AppErrorCode.authRequired);
      await user.delete();
      _lastSession = null;
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }
}
