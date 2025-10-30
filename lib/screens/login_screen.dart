import 'package:flutter/material.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMePreference() async {
    final bool rememberMe = await _authService.shouldRememberUser();
    setState(() {
      _rememberMe = rememberMe;
    });
  }

  Future<void> _signInWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Předáme true pro indikaci úspěšného přihlášení
        _showSuccessMessage('Úspěšně přihlášen!');
      }
    } catch (e) {
      if (mounted) {
        final String errorMessage = e.toString();
        
        // Pokud se jedná o neověřený email, nabídnout možnost přejít na verification screen
        if (errorMessage.contains('není ověřen')) {
          _showEmailVerificationDialog();
        } else {
          _showErrorMessage(errorMessage);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle(rememberMe: _rememberMe);
      
      if (result != null && mounted) {
        Navigator.of(context).pop(true);
        _showSuccessMessage('Úspěšně přihlášen přes Google!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithApple(rememberMe: _rememberMe);
      
      if (result != null && mounted) {
        Navigator.of(context).pop(true);
        _showSuccessMessage('Úspěšně přihlášen přes Apple!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showErrorMessage('Zadejte email pro reset hesla');
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        _showSuccessMessage('Email pro reset hesla byl odeslán na $email');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email není ověřen'),
        content: const Text(
          'Váš email ještě není ověřen. Zkontrolujte svou emailovou schránku a klikněte na ověřovací odkaz, nebo přejděte na obrazovku ověření.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmailVerificationScreen(
                    email: _emailController.text.trim(),
                  ),
                ),
              );
            },
            child: const Text('Přejít k ověření'),
          ),
        ],
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přihlášení'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Logo nebo název aplikace
              const SizedBox(height: 32),
              const Icon(
                Icons.sports_soccer,
                size: 80,
                color: Color(0xFF0A84FF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Strike!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A84FF),
                ),
              ),
              const SizedBox(height: 48),

              // Email pole
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Zadejte email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Neplatný formát emailu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Heslo pole
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Heslo',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Zadejte heslo';
                  }
                  if (value.length < 6) {
                    return 'Heslo musí mít alespoň 6 znaků';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Zapamatovat si přihlášení a zapomenuté heslo
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  ),
                  const Text('Zůstat přihlášen'),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Zapomenuté heslo?'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tlačítko pro přihlášení emailem
              FilledButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Přihlásit se', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),

              // Oddělovač
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('nebo'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // Přihlášení přes Google
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.account_circle, color: Colors.red),
                label: const Text('Pokračovat s Google'),
              ),
              const SizedBox(height: 12),

              // Přihlášení přes Apple (pouze na iOS/macOS)
              if (Platform.isIOS || Platform.isMacOS)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithApple,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.apple, color: Colors.black),
                  label: const Text('Pokračovat s Apple', style: TextStyle(color: Colors.black)),
                ),
              
              const SizedBox(height: 32),

              // Registrace
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nemáte účet?'),
                  TextButton(
                    onPressed: _navigateToRegister,
                    child: const Text('Zaregistrujte se'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


