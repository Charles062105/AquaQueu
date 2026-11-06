import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class UserServiceFailure implements Exception {
  const UserServiceFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class UserService {
  Future<AppUser> getProfile(String uid);

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required String address,
  });
}

class FirestoreUserService implements UserService {
  FirestoreUserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<AppUser> getProfile(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw const UserServiceFailure(
          'Your customer profile could not be found.',
        );
      }
      return AppUser(
        uid: uid,
        fullName: _requiredString(data, 'fullName'),
        email: _requiredString(data, 'email'),
        phoneNumber: _requiredString(data, 'phoneNumber'),
        address: _requiredString(data, 'address'),
        role: data['role'] == 'admin' ? 'admin' : 'customer',
      );
    } on FirebaseException catch (error) {
      throw UserServiceFailure(_friendlyFirestoreMessage(error.code));
    } on FormatException catch (error) {
      throw UserServiceFailure(error.message);
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required String address,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'address': address.trim(),
      });
    } on FirebaseException catch (error) {
      throw UserServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  static String _requiredString(Map<String, dynamic> data, String field) {
    final value = data[field];
    if (value is String) return value;
    throw FormatException('The customer profile is missing $field.');
  }

  static String _friendlyFirestoreMessage(String code) => switch (code) {
    'permission-denied' =>
      'You do not have permission to access this customer profile.',
    'unavailable' =>
      'The profile service is temporarily unavailable. Try again shortly.',
    'not-found' => 'Your customer profile could not be found.',
    _ => 'The customer profile could not be loaded or saved.',
  };
}
