import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userNickname;
  String? _profileImagePath;

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserNickname = 'user_nickname';
  static const String _keyProfileImagePath = 'profile_image_path';

  // Gettery
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userNickname => _userNickname;
  String? get profileImagePath => _profileImagePath;

  // Načíst uložený stav z SharedPreferences
  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _userEmail = prefs.getString('user_email');
    
    // Načíst přezdívku pro konkrétní email
    if (_userEmail != null) {
      _userNickname = prefs.getString('nickname_$_userEmail');
    }
    
    _profileImagePath = prefs.getString('profile_image_path');
  }

  // Přihlášení uživatele
  Future<void> loginUser({required String email, String? nickname}) async {
    final prefs = await SharedPreferences.getInstance();
    
    _userEmail = email;
    _isLoggedIn = true;
    
    // Načíst uloženou přezdívku pro tento email
    final savedNickname = prefs.getString('nickname_$email');
    _userNickname = savedNickname ?? nickname ?? email.split('@')[0];
    
    // Uložit session
    await prefs.setString('user_email', email);
    await prefs.setBool('is_logged_in', true);
    
    // Pokud není uložená přezdívka, ulož výchozí
    if (savedNickname == null && _userNickname != null) {
      await prefs.setString('nickname_$email', _userNickname!);
    }
  }

  // Odhlášení uživatele
  Future<void> logoutUser() async {
    _isLoggedIn = false;
    _userEmail = null;
    _userNickname = null;
    _profileImagePath = null;
    
    await _clearPreferences();
  }

  // Aktualizace uživatelských dat
  Future<void> updateUserData({String? nickname, String? profileImagePath}) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (nickname != null) {
      _userNickname = nickname;
      // Uložit přezdívku pro konkrétní email
      if (_userEmail != null) {
        await prefs.setString('nickname_$_userEmail', nickname);
      }
    }
    
    if (profileImagePath != null) {
      _profileImagePath = profileImagePath;
      await prefs.setString('profile_image_path', profileImagePath);
    } else if (profileImagePath == null && _profileImagePath != null) {
      // Odstranit profilový obrázek
      _profileImagePath = null;
      await prefs.remove('profile_image_path');
    }
  }

  // Uložit do SharedPreferences
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, _isLoggedIn);
      if (_userEmail != null) {
        await prefs.setString(_keyUserEmail, _userEmail!);
      }
      if (_userNickname != null) {
        await prefs.setString(_keyUserNickname, _userNickname!);
      }
      if (_profileImagePath != null) {
        await prefs.setString(_keyProfileImagePath, _profileImagePath!);
      }
    } catch (e) {
      // Chyba při ukládání - ignorovat
    }
  }

  // Vymazat SharedPreferences
  Future<void> _clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserNickname);
      await prefs.remove(_keyProfileImagePath);
    } catch (e) {
      // Chyba při mazání - ignorovat
    }
  }

  // Zkontrolovat zda má uživatel uložené přihlášení
  Future<bool> hasRememberedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      return false;
    }
  }
}