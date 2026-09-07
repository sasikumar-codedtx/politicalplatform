import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'config/app_colors.dart';
import 'config/app_strings.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'services/profile_service.dart';
import 'services/preloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeController.load(); // restore the saved light/dark choice
  await LocaleController.load(); // restore the saved Tamil/English choice
  await AppStrings.load(); // load the en/ta translation tables
  ProfileService.init(); // load profile on login, clear on logout
  Preloader.warm(); // warm home/news/forum/youtube caches during the splash
  runApp(const PoliticalPlatformApp());
}

class PoliticalPlatformApp extends StatefulWidget {
  const PoliticalPlatformApp({super.key});

  @override
  State<PoliticalPlatformApp> createState() => _PoliticalPlatformAppState();
}

class _PoliticalPlatformAppState extends State<PoliticalPlatformApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.isDark.addListener(_onThemeChanged);
    LocaleController.lang.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.isDark.removeListener(_onThemeChanged);
    LocaleController.lang.removeListener(_onThemeChanged);
    super.dispose();
  }

  // AppColors reads a global instead of an InheritedWidget, so const widgets
  // and pages cached by Navigator would keep their old colours until something
  // else rebuilt them (the "flips only after reopening the screen" bug).
  // Marking every element dirty repaints the whole app in the same frame.
  void _onThemeChanged() {
    void markDirty(Element el) {
      el.markNeedsBuild();
      el.visitChildren(markDirty);
    }

    (context as Element).visitChildren(markDirty);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dark = ThemeController.isDark.value;
    return MaterialApp(
      title: AppConfig.current.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(AppConfig.current, dark: false),
      darkTheme: AppTheme.build(AppConfig.current, dark: true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: LocaleController.locale,
      supportedLocales: const [Locale('en'), Locale('ta')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
