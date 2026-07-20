import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'services/profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ProfileService.init(); // load profile on login, clear on logout
  runApp(const PoliticalPlatformApp());
}

class PoliticalPlatformApp extends StatelessWidget {
  const PoliticalPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.current.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(AppConfig.current),
      home: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _showSplash = true;
  bool _showOnboarding = false;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
      _showOnboarding = true;
    });
  }

  void _onOnboardingDone() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    if (_showOnboarding) {
      return OnboardingScreen(onDone: _onOnboardingDone);
    }

    return const MainShell();
  }
}
