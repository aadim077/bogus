import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class UserState {
  final String uid;
  final String email;
  final String username;
  final bool isAdmin;
  UserState({
    required this.uid,
    required this.email,
    required this.username,
    required this.isAdmin,
  });
}

class AuthService extends ChangeNotifier {
  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;
  final FirestoreService _db = FirestoreService();

  Stream<UserState?> get userStream async* {
    await for (final fa.User? u in _auth.authStateChanges()) {
      if (u == null) {
        yield null;
      } else {
        final profile = await _db.getUser(u.uid);
        final isAdmin = profile?['isAdmin'] == true;
        yield UserState(
          uid: u.uid,
          email: u.email ?? '',
          username: profile?['username'] ?? '',
          isAdmin: isAdmin,
        );
      }
    }
  }

  Future<fa.UserCredential> signUp(
      String email, String password, String username) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    //  Save with username
    await _db.createUser(
      cred.user!.uid,
      email,
      username: username,
      role: "user",
    );
    return cred;
  }

  Future<fa.UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async => _auth.signOut();

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    return await _db.getUser(uid);
  }
}
