import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/bindings/initial_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - gracefully handle if not configured)
  // Uncomment when Firebase is properly configured with google-services.json
  // try {
  //   await Firebase.initializeApp();
  // } catch (e) {
  //   // Firebase not configured - app will work in offline-only mode
  //   debugPrint('Firebase not initialized: $e');
  // }

  await InitialBinding().dependencies();
  runApp(const App());
}
