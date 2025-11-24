import 'package:flutter/material.dart';
import 'dart:async';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));
  }

  Future<void> _startSplashSequence() async {
    // Malé zpoždění před spuštěním animace
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Spustit animaci loga
    _logoController.forward();
    
    // Počkat na dokončení animace loga
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Simulovat načítání
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Automaticky přepnout do aplikace
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3E5F44),
              const Color(0xFF2D4A3E),
              const Color(0xFF1E3A2E),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Jemné dekorativní prvky v pozadí s různými barvami
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4A90E2).withOpacity(0.08), // Modrá
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF5E936C).withOpacity(0.06), // Zelená
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFB84D).withOpacity(0.06), // Oranžová/žlutá
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.2,
                right: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6B8DD6).withOpacity(0.05), // Světle modrá
                  ),
                ),
              ),
              
              // Hlavní obsah
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo s jemnou animací
                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (_logoAnimation.value * 0.2),
                            child: Opacity(
                              opacity: _logoAnimation.value,
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
                    
                      const SizedBox(height: 60),
                    
                      // Jemný loading indikátor
                      AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}