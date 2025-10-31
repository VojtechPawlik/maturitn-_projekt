import 'package:firebase_auth/firebase_auth.dart';

class AuthServiceExtension {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Získat aktuálního uživatele
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Zkontrolovat zda je uživatel přihlášen
  bool get isUserSignedIn {
    return _auth.currentUser != null;
  }

  // Stream pro sledování změn auth stavu
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}