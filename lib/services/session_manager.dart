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
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      _userEmail = prefs.getString(_keyUserEmail);
      _userNickname = prefs.getString(_keyUserNickname);
      _profileImagePath = prefs.getString(_keyProfileImagePath);
    } catch (e) {
      // Pokud se nepodaří načíst, zůstanou výchozí hodnoty
      _isLoggedIn = false;
      _userEmail = null;
      _userNickname = null;
      _profileImagePath = null;
    }
  }

  // Přihlášení uživatele
  Future<void> loginUser({String? email, String? nickname, bool rememberMe = false}) async {
    _isLoggedIn = true;
    _userEmail = email;
    _userNickname = nickname;
    
    if (rememberMe) {
      await _saveToPreferences();
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
  Future<void> updateUserData({String? email, String? nickname, String? profileImagePath}) async {
    if (_isLoggedIn) {
      _userEmail = email ?? _userEmail;
      _userNickname = nickname ?? _userNickname;
      _profileImagePath = profileImagePath ?? _profileImagePath;
      
      // Uložit změny pokud je uživatel trvalě přihlášen
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_keyIsLoggedIn) == true) {
        await _saveToPreferences();
      }
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