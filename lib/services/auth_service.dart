import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthIdentity {
  const AuthIdentity({required this.uid, required this.email});

  final String uid;
  final String email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  AuthIdentity? get currentUser;
  Stream<AuthIdentity?> get authStateChanges;

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
  });

  Future<void> login({required String email, required String password});
  Future<void> logout();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  AuthIdentity? get currentUser => _identityOf(_auth.currentUser);

  @override
  Stream<AuthIdentity?> get authStateChanges =>
      _auth.authStateChanges().map(_identityOf);

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure(
          'Your account could not be created. Please try again.',
        );
      }

      try {
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName.trim(),
          'email': user.email ?? email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'address': address.trim(),
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException {
        throw const AuthFailure(
          'Your account was created, but its profile could not be saved. '
          'Please sign in again later or contact support.',
        );
      }
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error.code));
    }
  }

  @override
  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error.code));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error.code));
    }
  }

  static AuthIdentity? _identityOf(User? user) {
    if (user == null) return null;
    return AuthIdentity(uid: user.uid, email: user.email ?? '');
  }

  static String _friendlyAuthMessage(String code) => switch (code) {
    'email-already-in-use' => 'An account already uses this email address.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Choose a stronger password with at least 6 characters.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' =>
      'The email or password is incorrect.',
    'user-disabled' => 'This account has been disabled. Contact support.',
    'operation-not-allowed' =>
      'Email and password sign-in is not enabled for this project.',
    'too-many-requests' =>
      'Too many attempts. Please wait a moment and try again.',
    'network-request-failed' =>
      'A network error occurred. Check your connection and try again.',
    _ => 'Authentication failed. Please try again.',
  };
}
