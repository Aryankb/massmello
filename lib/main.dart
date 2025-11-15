import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:massmello/theme.dart';
import 'package:massmello/screens/splash_screen.dart';
import 'package:massmello/services/notification_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
    
    // Initialize Notification Service
    await NotificationService().initialize();
    debugPrint('✅ Notification Service initialized');
  } catch (e) {
    debugPrint('❌ Error initializing Firebase/Notifications: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'massmello - Alzheimer\'s Care',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
