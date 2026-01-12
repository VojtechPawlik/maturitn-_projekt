import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/localization_service.dart';
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
  bool _isLoading = false;
  String? _passwordError;
  String? _emailSuccessMessage; // Pro zprávu o odeslání reset hesla
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
    _passwordController.addListener(() {
      // Vymazat chybu při změně hesla
      if (_passwordError != null) {
        setState(() {
          _passwordError = null;
        });
        // Znovu validovat, aby se chyba odstranila
        _formKey.currentState?.validate();
      }
    });
  }

  Future<void> _loadRememberMePreference() async {
    final bool rememberMe = await _authService.shouldRememberUser();
    setState(() {
      _rememberMe = rememberMe;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      
      // Nastavit session po úspěšném přihlášení
      await SessionManager().loginUser(
        email: _emailController.text.trim(),
        nickname: 'Uživatel', // Default nickname
        rememberMe: _rememberMe,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Předáme true pro indikaci úspěšného přihlášení
      }
    } catch (e) {
      if (mounted) {
        final String errorMessage = e.toString();
        
        // Pokud se jedná o neověřený email, nabídnout možnost přejít na verification screen
        if (errorMessage.contains('není ověřen')) {
          _showEmailVerificationDialog();
        } else {
          // Zobrazit chybu pod polem pro heslo
          setState(() {
            _passwordError = 'Zadané špatné heslo';
          });
          // Znovu validovat formulář, aby se zobrazila chyba
          _formKey.currentState?.validate();
        }
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
      setState(() {
        _emailSuccessMessage = 'Zadejte email pro reset hesla';
      });
      _formKey.currentState?.validate();
      return;
    }

    setState(() {
      _emailSuccessMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _emailSuccessMessage = 'Email pro reset hesla byl odeslán na $email';
        });
        _formKey.currentState?.validate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailSuccessMessage = e.toString();
        });
        _formKey.currentState?.validate();
      }
    }
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(LocalizationService.translate('login')),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 32),
              // Nadpis
              const Text(
                'Přihlášení',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5F44),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Email pole
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  errorText: _emailSuccessMessage != null && _emailSuccessMessage!.contains('Zadejte') 
                      ? _emailSuccessMessage 
                      : null,
                  helperText: _emailSuccessMessage != null && !_emailSuccessMessage!.contains('Zadejte')
                      ? _emailSuccessMessage
                      : null,
                  helperStyle: TextStyle(
                    color: _emailSuccessMessage != null && _emailSuccessMessage!.contains('odeslán')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                onChanged: (_) {
                  if (_emailSuccessMessage != null) {
                    setState(() {
                      _emailSuccessMessage = null;
                    });
                    _formKey.currentState?.validate();
                  }
                },
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
                  // Pokud je nastavena chyba z API, zobrazit ji
                  if (_passwordError != null) {
                    return _passwordError;
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


