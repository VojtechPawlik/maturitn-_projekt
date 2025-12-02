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
  static const double _defaultBalance = 500.0; // Výchozí zůstatek při registraci

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

  // Získat zůstatek peněz uživatele
  Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = _userEmail;
    
    if (userEmail == null) {
      return 0.0;
    }
    
    final balance = prefs.getDouble('balance_$userEmail');
    if (balance == null) {
      // Pokud uživatel nemá zůstatek, nastavit výchozí
      await setBalance(_defaultBalance);
      return _defaultBalance;
    }
    
    return balance;
  }

  // Nastavit zůstatek peněz uživatele
  Future<void> setBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = _userEmail;
    
    if (userEmail != null) {
      await prefs.setDouble('balance_$userEmail', balance);
    }
  }

  // Přidat peníze k zůstatku
  Future<bool> addBalance(double amount) async {
    if (amount <= 0) return false;
    
    final currentBalance = await getBalance();
    await setBalance(currentBalance + amount);
    return true;
  }

  // Odebrat peníze ze zůstatku
  Future<bool> subtractBalance(double amount) async {
    if (amount <= 0) return false;
    
    final currentBalance = await getBalance();
    if (currentBalance < amount) {
      return false; // Nedostatek peněz
    }
    
    await setBalance(currentBalance - amount);
    return true;
  }

  // Převést peníze mezi uživateli
  Future<bool> transferBalance(String fromEmail, String toEmail, double amount) async {
    if (amount <= 0) return false;
    
    // Zkontrolovat, zda má odesílatel dostatek peněz
    final fromBalance = await getBalanceForUser(fromEmail);
    if (fromBalance < amount) {
      return false; // Nedostatek peněz
    }
    
    // Odebrat peníze od odesílatele
    final fromPrefs = await SharedPreferences.getInstance();
    final fromKey = 'balance_$fromEmail';
    await fromPrefs.setDouble(fromKey, fromBalance - amount);
    
    // Přidat peníze příjemci
    final toBalance = await getBalanceForUser(toEmail);
    final toPrefs = await SharedPreferences.getInstance();
    final toKey = 'balance_$toEmail';
    await toPrefs.setDouble(toKey, toBalance + amount);
    
    return true;
  }

  // Přihlášení uživatele
  Future<void> loginUser({required String email, String? nickname, bool rememberMe = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    _userEmail = email;
    _isLoggedIn = true;
    
    // Načíst uloženou přezdívku pro tento email
    final savedNickname = prefs.getString('nickname_$email');
    _userNickname = savedNickname ?? nickname ?? email.split('@')[0];
    
    // Načíst uloženou profilovou fotku pro tento email
    _profileImageUrl = prefs.getString('profile_image_url_$email');
    
    // Uložit session pouze pokud má uživatel zaškrtnuté "Zůstat přihlášen"
    if (rememberMe) {
      await prefs.setString('user_email', email);
      await prefs.setBool('is_logged_in', true);
    }
    
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
    
    // Pokud je předán nickname, uložit nebo smazat
    if (nickname != null) {
      if (nickname.isNotEmpty) {
        _userNickname = nickname;
        // Uložit přezdívku pro konkrétní email
        if (_userEmail != null) {
          await prefs.setString('nickname_$_userEmail', nickname);
        }
      } else {
        // Smazat přezdívku (prázdný string)
        _userNickname = null;
        if (_userEmail != null) {
          await prefs.remove('nickname_$_userEmail');
        }
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

  // Získat zůstatek pro konkrétního uživatele (podle emailu)
  Future<double> getBalanceForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final balance = prefs.getDouble('balance_$email');
    return balance ?? 0.0;
  }

  // Získat přezdívku pro konkrétního uživatele (podle emailu)
  Future<String?> getNicknameForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nickname_$email');
  }

  // Získat URL profilového obrázku pro konkrétního uživatele (podle emailu)
  Future<String?> getProfileImageForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_url_$email');
  }

  // Zkontrolovat, zda může uživatel získat každodenní odměnu
  Future<bool> canClaimDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = _userEmail;
    
    if (userEmail == null) {
      return false;
    }

    final lastRewardDateKey = 'last_daily_reward_$userEmail';
    final lastRewardDateStr = prefs.getString(lastRewardDateKey);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Pokud uživatel dostal odměnu dnes, nemůže ji získat znovu
    if (lastRewardDateStr != null) {
      final lastRewardDate = DateTime.parse(lastRewardDateStr);
      final lastRewardDay = DateTime(lastRewardDate.year, lastRewardDate.month, lastRewardDate.day);
      
      if (lastRewardDay.isAtSameMomentAs(today)) {
        return false; // Už dostal odměnu dnes
      }
    }
    
    return true; // Může získat odměnu
  }

  // Udělit každodenní odměnu
  Future<bool> claimDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = _userEmail;
    
    if (userEmail == null) {
      return false;
    }

    final lastRewardDateKey = 'last_daily_reward_$userEmail';
    final lastRewardDateStr = prefs.getString(lastRewardDateKey);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Pokud uživatel dostal odměnu dnes, nedat ji znovu
    if (lastRewardDateStr != null) {
      final lastRewardDate = DateTime.parse(lastRewardDateStr);
      final lastRewardDay = DateTime(lastRewardDate.year, lastRewardDate.month, lastRewardDate.day);
      
      if (lastRewardDay.isAtSameMomentAs(today)) {
        return false; // Už dostal odměnu dnes
      }
    }
    
    // Udělit odměnu 20!
    await addBalance(20.0);
    
    // Uložit datum odměny
    await prefs.setString(lastRewardDateKey, today.toIso8601String());
    
    return true; // Odměna byla udělena
  }
}