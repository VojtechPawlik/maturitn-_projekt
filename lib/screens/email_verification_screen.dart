import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailVerificationScreen({
    super.key, 
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _isResendingEmail = false;
  bool _canResendEmail = false;
  int _resendCooldown = 60;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  void _startResendCooldown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        setState(() {
          _canResendEmail = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailVerification() async {
    try {
      await _authService.checkEmailVerification();
      
      if (_authService.isEmailVerified) {
        _timer?.cancel();
        if (mounted) {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      // Tichá chyba - nepotřebujeme zobrazovat
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail || _isResendingEmail) return;

    setState(() {
      _isResendingEmail = true;
    });

    try {
      await _authService.resendEmailVerification();
      
      if (mounted) {
        _showSuccessMessage('Verifikační email byl znovu odeslán');
        setState(() {
          _canResendEmail = false;
          _resendCooldown = 60;
        });
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        title: const Text('Email ověřen!'),
        content: const Text('Váš email byl úspěšně ověřen. Nyní se můžete přihlásit do aplikace.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(); // Zavřít dialog
              Navigator.of(context).pop(); // Zavřít verification screen
            },
            child: const Text('Pokračovat'),
          ),
        ],
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ověření emailu'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikona emailu
            const Icon(
              Icons.mark_email_read_outlined,
              size: 120,
              color: Color(0xFF0A84FF),
            ),
            const SizedBox(height: 32),
            
            // Nadpis
            const Text(
              'Ověřte svůj email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Popis
            Text(
              'Odeslali jsme verifikační email na adresu:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Email adresa
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A84FF),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Instrukce
            Text(
              'Klikněte na odkaz v emailu pro ověření svého účtu. Poté se můžete přihlásit do aplikace.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // Indikátor načítání
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text(
                  'Čekáme na ověření...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Tlačítko pro znovu odeslání
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _canResendEmail && !_isResendingEmail ? _resendVerificationEmail : null,
                icon: _isResendingEmail 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  _canResendEmail 
                      ? 'Odeslat email znovu'
                      : 'Znovu odeslat za ${_resendCooldown}s',
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tlačítko zpět k přihlášení
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zpět k přihlášení'),
            ),
            
          ],
        ),
      ),
    );
  }
}
