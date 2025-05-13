import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set correct Realtime DB URL
  FirebaseDatabase.instance.refFromURL(
      "https://iot-app-6153d-default-rtdb.asia-southeast1.firebasedatabase.app/");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => const AuthWrapper(), // Default route
        '/login': (context) => const LoginScreen(), // Login screen route
        '/register': (context) => const RegisterScreen(), // Register screen route
        '/main': (context) => const MainScreen(), // Main screen route
      },
    );
  }
}