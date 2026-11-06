import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_admin_service.dart';
import 'services/firestore_order_service.dart';
import 'services/product_service.dart';
import 'services/user_service.dart';

const _emulatorFirebaseOptions = FirebaseOptions(
  apiKey: 'fake-api-key',
  appId: '1:1234567890:android:emulator',
  messagingSenderId: '1234567890',
  projectId: 'demo-aquaqueue',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const useEmulators = bool.fromEnvironment('AQUAQUEUE_USE_FIREBASE_EMULATORS');
  if (useEmulators && !kDebugMode) {
    throw StateError('Firebase emulators may only be used in debug builds.');
  }
  await Firebase.initializeApp(
    options: useEmulators
        ? _emulatorFirebaseOptions
        : DefaultFirebaseOptions.currentPlatform,
  );
  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
  }
  runApp(
    AquaQueueApp(
      authService: FirebaseAuthService(),
      userService: FirestoreUserService(),
      productService: FirestoreProductService(),
      orderService: FirestoreOrderService(),
      adminService: FirestoreAdminService(),
    ),
  );
}
