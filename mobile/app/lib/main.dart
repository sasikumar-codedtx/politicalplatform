import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'screens/phone_login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PoliticalPlatformApp());
}

class PoliticalPlatformApp extends StatelessWidget {
  const PoliticalPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(AppConfig.current.primaryColor);

    return MaterialApp(
      title: AppConfig.current.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const DashboardScreen();
          return const PhoneLoginScreen();
        },
      ),
    );
  }
}
