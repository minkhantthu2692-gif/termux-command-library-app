import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../models/auth_models.dart';
import 'cloud_gateways.dart';
import 'firebase_errors.dart';

class FirebaseAuthGateway implements AuthGateway {
  FirebaseAuthGateway(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthSession? get currentSession {
    final user = _auth.currentUser;
    return user == null ? null : _syncSession(user);
  }

  @override
  Stream<AuthSession?> watchSessions() {
    return _auth.authStateChanges().asyncMap(_asyncSession);
  }

  AuthSession _syncSession(User user) => AuthSession(
    uid: user.uid,
    email: user.email,
    isAnonymous: user.isAnonymous,
    isAdmin: false,
    isLocalOnly: false,
  );

  Future<AuthSession?> _asyncSession(User? user) async {
    if (user == null) return null;
    var isAdmin = false;
    try {
      final token = await user.getIdTokenResult();
      isAdmin = token.claims?['admin'] == true;
    } catch (_) {
      // A missing claim or a refresh hiccup must not prevent sign-in. Firestore
      // rules remain the actual authorization boundary.
    }
    return AuthSession(
      uid: user.uid,
      email: user.email,
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
      return (await _asyncSession(linked))!;
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
  Future<void> reload() async {
    try {
      await _auth.currentUser?.reload();
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
    } catch (error) {
      throw mapFirebaseAuthError(error);
    }
  }
}
