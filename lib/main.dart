import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:strike_app/firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'strike-app',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'Strike!',
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(), // Změněno z MainScreen na SplashScreen
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
