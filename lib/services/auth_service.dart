import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Klíč pro uložení stavu "Zůstat přihlášen"
  static const String _rememberMeKey = 'remember_me';

  // Stream pro sledování stavu přihlášení
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Aktuální uživatel
  User? get currentUser => _auth.currentUser;

  // Zda je uživatel přihlášen
  bool get isSignedIn => currentUser != null;

  /// Registrace pomocí email a hesla
  Future<UserCredential?> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Nastavit displayName pokud je poskytnut
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Neočekávaná chyba: $e';
    }
  }

  /// Přihlášení pomocí email a hesla
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Uložit stav "Zůstat přihlášen"
      await _setRememberMe(rememberMe);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Neočekávaná chyba: $e';
    }
  }

  /// Přihlášení pomocí Google
  Future<UserCredential?> signInWithGoogle({bool rememberMe = false}) async {
    try {
      // Spustit Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Uživatel zrušil přihlášení
        return null;
      }

      // Získat autentizační údaje
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Vytvořit credential pro Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Přihlásit se do Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Uložit stav "Zůstat přihlášen"
      await _setRememberMe(rememberMe);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Chyba při přihlášení přes Google: $e';
    }
  }

  /// Přihlášení pomocí Apple (Sign in with Apple)
  Future<UserCredential?> signInWithApple({bool rememberMe = false}) async {
    try {
      // Ověřit dostupnost Sign in with Apple
      final bool available = await SignInWithApple.isAvailable();
      if (!available) {
        throw 'Přihlášení přes Apple není na tomto zařízení dostupné';
      }

      // Spustit Apple Sign In flow
      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Vytvořit OAuth credential pro Firebase
      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Přihlásit se do Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Pokud je k dispozici jméno, aktualizovat profil uživatele
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final String displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      // Uložit stav "Zůstat přihlášen"
      await _setRememberMe(rememberMe);

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null; // Uživatel zrušil přihlášení
      }
      throw 'Chyba při přihlášení přes Apple: ${e.message}';
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Chyba při přihlášení přes Apple: $e';
    }
  }

  /// Odeslání emailu pro reset hesla
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw 'Chyba při odesílání emailu pro reset hesla: $e';
    }
  }

  /// Odhlášení
  Future<void> signOut() async {
    try {
      // Odhlásit z Google pokud byl přihlášen přes Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Odhlásit z Firebase
      await _auth.signOut();
      
      // Smazat stav "Zůstat přihlášen"
      await _clearRememberMe();
    } catch (e) {
      throw 'Chyba při odhlášení: $e';
    }
  }

  /// Zkontrolovat, zda má uživatel nastaven "Zůstat přihlášen"
  Future<bool> shouldRememberUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Uložit stav "Zůstat přihlášen"
  Future<void> _setRememberMe(bool rememberMe) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  /// Smazat stav "Zůstat přihlášen"
  Future<void> _clearRememberMe() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
  }

  /// Zpracování chyb Firebase Auth
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Uživatel s tímto emailem neexistuje.';
      case 'wrong-password':
        return 'Nesprávné heslo.';
      case 'email-already-in-use':
        return 'Tento email je již používán jiným účtem.';
      case 'weak-password':
        return 'Heslo je příliš slabé.';
      case 'invalid-email':
        return 'Neplatný formát emailu.';
      case 'user-disabled':
        return 'Tento účet byl zablokován.';
      case 'too-many-requests':
        return 'Příliš mnoho pokusů. Zkuste to později.';
      case 'operation-not-allowed':
        return 'Tato operace není povolena.';
      case 'invalid-credential':
        return 'Neplatné přihlašovací údaje.';
      case 'account-exists-with-different-credential':
        return 'Účet s tímto emailem již existuje s jiným způsobem přihlášení.';
      case 'requires-recent-login':
        return 'Tato operace vyžaduje nedávné přihlášení. Přihlaste se znovu.';
      default:
        return 'Chyba při autentizaci: ${e.message ?? 'Neznámá chyba'}';
    }
  }
}
