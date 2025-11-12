import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:strike_app/firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );  
  
  // Načíst uložený jazyk
  await LocalizationService.loadSavedLanguage();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService().darkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Strike!',
          theme: ThemeData(
            primaryColor: const Color(0xFF3E5F44),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3E5F44),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            primaryColor: const Color(0xFF3E5F44),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3E5F44),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
