import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authService, required this.userService}) {
    _subscription = authService.authStateChanges.listen(
      (identity) => unawaited(_handleAuthState(identity)),
      onError: (Object error, StackTrace stackTrace) {
        _errorMessage = 'Authentication status could not be checked.';
        _isLoading = false;
        notifyListeners();
      },
    );
    unawaited(_handleAuthState(authService.currentUser));
  }

  final AuthService authService;
  final UserService userService;
  late final StreamSubscription<AuthIdentity?> _subscription;
  int _profileRequest = 0;

  AuthIdentity? _identity;
  AppUser? _profile;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _profileError;

  AuthIdentity? get identity => _identity;
  AppUser? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _identity != null;
  bool get isAdmin => _identity != null && _profile?.role == 'admin';
  String get role => isAdmin ? 'admin' : 'customer';
  String? get errorMessage => _errorMessage;
  String? get profileError => _profileError;

  Future<bool> login({required String email, required String password}) async {
    _beginSubmission();
    try {
      await authService.login(email: email, password: password);
      await _handleAuthState(authService.currentUser);
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _errorMessage = 'Sign in failed. Please try again.';
      return false;
    } finally {
      _endSubmission();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    _beginSubmission();
    try {
      await authService.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        password: password,
      );
      await _handleAuthState(authService.currentUser);
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _errorMessage = 'Account registration failed. Please try again.';
      return false;
    } finally {
      _endSubmission();
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();
      await _handleAuthState(authService.currentUser);
    } on AuthFailure catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile(AppUser profile) async {
    if (profile.uid != _identity?.uid) {
      throw const UserServiceFailure(
        'You can only update your own customer profile.',
      );
    }
    await userService.updateProfile(
      uid: profile.uid,
      fullName: profile.fullName,
      phoneNumber: profile.phoneNumber,
      address: profile.address,
    );
    _profile = profile;
    notifyListeners();
  }

  Future<void> reloadProfile() async {
    final identity = _identity;
    if (identity != null) await _handleAuthState(identity);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _handleAuthState(AuthIdentity? identity) async {
    final request = ++_profileRequest;
    _identity = identity;
    _profile = null;
    _profileError = null;
    _errorMessage = null;
    _isLoading = identity != null;
    notifyListeners();

    if (identity == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final profile = await userService.getProfile(identity.uid);
      if (request == _profileRequest) _profile = profile;
    } on UserServiceFailure catch (error) {
      if (request == _profileRequest) _profileError = error.message;
    } catch (error) {
      if (request == _profileRequest) {
        _profileError = 'Your customer profile could not be loaded.';
      }
    } finally {
      if (request == _profileRequest) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _beginSubmission() {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _endSubmission() {
    _isSubmitting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
