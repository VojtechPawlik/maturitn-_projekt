import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userNickname;
  String? _profileImagePath;
  String? _profileImageUrl;

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserNickname = 'user_nickname';
  static const String _keyProfileImagePath = 'profile_image_path';
  static const String _keyProfileImageUrl = 'profile_image_url';

  // Gettery
  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userNickname => _userNickname;
  String? get profileImagePath => _profileImagePath;
  String? get profileImageUrl => _profileImageUrl;

  // Načíst uložený stav z SharedPreferences
  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _userEmail = prefs.getString('user_email');
    
    // Načíst přezdívku a profilovou fotku pro konkrétní email
    if (_userEmail != null) {
      _userNickname = prefs.getString('nickname_$_userEmail');
      _profileImageUrl = prefs.getString('profile_image_url_$_userEmail');
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
    
    // Načíst uloženou profilovou fotku pro tento email
    _profileImageUrl = prefs.getString('profile_image_url_$email');
    
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
    _profileImageUrl = null;
    
    // Vymazat pouze session data, ale zachovat profilovou fotku a přezdívku vázané na email
    await _clearPreferences();
  }

  // Aktualizace uživatelských dat
  Future<void> updateUserData({String? nickname, String? profileImagePath, String? profileImageUrl}) async {
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
    
    if (profileImageUrl != null) {
      _profileImageUrl = profileImageUrl;
      // Uložit profilovou fotku vázanou na email
      if (_userEmail != null) {
        await prefs.setString('profile_image_url_$_userEmail', profileImageUrl);
      }
    } else if (profileImageUrl == null && _profileImageUrl != null) {
      // Odstranit profilový obrázek
      _profileImageUrl = null;
      if (_userEmail != null) {
        await prefs.remove('profile_image_url_$_userEmail');
      }
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
      await prefs.remove(_keyProfileImageUrl);
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