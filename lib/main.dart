import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io' show Platform;
import 'screens/tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      // Initialize Firebase
      if (kIsWeb) {
        // Web platform - Firebase will auto-detect config from environment
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyCW7EP0EC_7g1qIHs8tV8gPKZKqM0RCi3I",
            appId: "1:719454456615:web:default",
            messagingSenderId: "719454456615",
            projectId: "rovereturntrackingapp",
            storageBucket: "rovereturntrackingapp.firebasestorage.app",
          ),
        );
      } else if (Platform.isIOS) {
        // iOS platform - use default initialization (uses GoogleService-Info.plist)
        // The plist file now matches the Android project configuration
        await Firebase.initializeApp();
      } else {
        // Android platform - use default initialization (uses google-services.json)
        await Firebase.initializeApp();
      }
    }
  } catch (e) {
    // Log the error - Firebase is required for the app to work properly
    if (kDebugMode) {
      print('Firebase initialization error: $e');
    }
    // Don't rethrow - allow app to run but Firebase features won't work
    // This prevents app crash but user will see Firebase errors in UI
  }
  
  runApp(const TrackingApp());
}

class TrackingApp extends StatelessWidget {
  const TrackingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TrackingScreen(),
    );
  }
}
