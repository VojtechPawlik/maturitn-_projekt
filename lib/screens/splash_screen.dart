import 'package:flutter/material.dart';
import 'dart:async';
import 'main_screen.dart';
import '../services/localization_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startSplashSequence() async {
    // Malé zpoždění před spuštěním animace
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Spustit animaci loga
    _logoController.forward();
    
    // Počkat na dokončení animace loga
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Spustit fade animaci pro obsah
    _fadeController.forward();
    
    // Simulovat načítání
    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() {
      _isLoading = false;
    });
  }

  void _startApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E5F44), // Zelená místo modré
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                // Logo s animací
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -100 * (1 - _logoAnimation.value)),
                      child: Opacity(
                        opacity: _logoAnimation.value.clamp(0.0, 1.0),
                        child: Image.asset(
                          'assets/images/logo_a_text.png',
                          width: 500,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 48),
              
              // Načítací indikátor nebo obsah
              if (_isLoading)
                Column(
                  children: [
                    CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5E936C)),
                  strokeWidth: 3,
                ),
                    SizedBox(height: 16),
                    Text(
                      LocalizationService.isEnglish ? 'Loading...' : 'Načítání...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              else
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Tlačítko Start aplikace
                      FilledButton(
                        onPressed: _startApp,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3E5F44),
                          minimumSize: const Size(200, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          LocalizationService.isEnglish ? 'Start App' : 'Spustit aplikaci',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Verze aplikace
                      Text(
                        LocalizationService.isEnglish ? 'Version 1.0.0' : 'Verze 1.0.0',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}