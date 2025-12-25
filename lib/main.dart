import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'screens/tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    // For web, Firebase will use default options if not provided
    // For mobile, it will use google-services.json / GoogleService-Info.plist
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
    } else {
      // Mobile platforms - use default initialization
      await Firebase.initializeApp();
    }
  } catch (e) {
    // If Firebase is already initialized, that's okay
    if (kDebugMode) {
      print('Firebase initialization note: $e');
    }
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
