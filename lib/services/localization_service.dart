import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static String _currentLanguage = 'Čeština';
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('Čeština');
  
  static String get currentLanguage => _currentLanguage;
  static bool get isEnglish => _currentLanguage == 'English';

  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'Čeština';
    languageNotifier.value = _currentLanguage;
  }

  static Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    languageNotifier.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }
  
  // Překladové texty
  static const Map<String, Map<String, String>> _translations = {
    // AppBar texty
    'settings': {'Čeština': 'Nastavení', 'English': 'Settings'},
    'teams': {'Čeština': 'Týmy', 'English': 'Teams'},
    'competitions': {'Čeština': 'Soutěže', 'English': 'Competitions'},
    'favorites': {'Čeština': 'Oblíbené', 'English': 'Favorites'},
    'home': {'Čeština': 'Domů', 'English': 'Home'},
    'news': {'Čeština': 'Novinky', 'English': 'News'},
    
    // Nastavení
    'general': {'Čeština': 'Obecné', 'English': 'General'},
    'notifications': {'Čeština': 'Oznámení', 'English': 'Notifications'},
    'notifications_subtitle': {'Čeština': 'Povolit push notifikace', 'English': 'Enable push notifications'},
    'language': {'Čeština': 'Jazyk', 'English': 'Language'},
    'about_app': {'Čeština': 'O aplikaci', 'English': 'About App'},
    'app_version': {'Čeština': 'Verze aplikace', 'English': 'App Version'},
    'feedback': {'Čeština': 'Zpětná vazba', 'English': 'Feedback'},
    'feedback_subtitle': {'Čeština': 'Nahlásit chybu nebo navrhnout vylepšení', 'English': 'Report bug or suggest improvement'},
    
    // Zpětná vazba
    'feedback_title': {'Čeština': 'Zpětná vazba', 'English': 'Feedback'},
    'feedback_type': {'Čeština': 'Typ zpětné vazby:', 'English': 'Feedback Type:'},
    'bug': {'Čeština': 'Chyba', 'English': 'Bug'},
    'improvement': {'Čeština': 'Návrh na vylepšení', 'English': 'Improvement Suggestion'},
    'general_feedback': {'Čeština': 'Obecná zpětná vazba', 'English': 'General Feedback'},
    'your_message': {'Čeština': 'Vaše zpráva:', 'English': 'Your Message:'},
    'feedback_placeholder': {'Čeština': 'Popište svou připomínku nebo návrh...', 'English': 'Describe your feedback or suggestion...'},
    'cancel': {'Čeština': 'Zrušit', 'English': 'Cancel'},
    'send': {'Čeština': 'Odeslat', 'English': 'Send'},
    'thanks_feedback': {'Čeština': 'Děkujeme za zpětnou vazbu!', 'English': 'Thank you for your feedback!'},
    
    // Oznámení
    'notifications_on': {'Čeština': 'Oznámení zapnuta', 'English': 'Notifications enabled'},
    'notifications_off': {'Čeština': 'Oznámení vypnuta', 'English': 'Notifications disabled'},
    'dark_mode_on': {'Čeština': 'Tmavý režim zapnut', 'English': 'Dark mode enabled'},
    'light_mode_on': {'Čeština': 'Světlý režim zapnut', 'English': 'Light mode enabled'},
    'language_changed': {'Čeština': 'Jazyk změněn na', 'English': 'Language changed to'},
    
    // Chybové zprávy
    'error': {'Čeština': 'Chyba', 'English': 'Error'},
    'try_again': {'Čeština': 'Zkusit znovu', 'English': 'Try Again'},
    'loading': {'Čeština': 'Načítání...', 'English': 'Loading...'},
    'refresh': {'Čeština': 'Obnovit', 'English': 'Refresh'},
    
    // Hlavní stránka
    'all_competitions': {'Čeština': 'Všechny soutěže', 'English': 'All Competitions'},
    'favorite_teams': {'Čeština': 'Oblíbené týmy', 'English': 'Favorite Teams'},
    'no_favorite_teams': {'Čeština': 'Zatím nemáte oblíbené týmy', 'English': 'You have no favorite teams yet'},
    'add_favorites_hint': {'Čeština': 'Přidejte je kliknutím na srdcová na stránce týmů', 'English': 'Add them by clicking hearts on the teams page'},
    'login_for_favorites': {'Čeština': 'Přihlaste se pro sledování oblíbených týmů', 'English': 'Log in to track your favorite teams'},
    'today': {'Čeština': 'Dnes', 'English': 'Today'},
    'yesterday': {'Čeština': 'Včera', 'English': 'Yesterday'},
    'tomorrow': {'Čeština': 'Zítra', 'English': 'Tomorrow'},
    'todays_matches': {'Čeština': 'Dnešní zápasy', 'English': "Today's Matches"},
    'results': {'Čeština': 'Výsledky', 'English': 'Results'},
    'upcoming_matches': {'Čeština': 'Nadcházející zápasy', 'English': 'Upcoming Matches'},
    'latest_news': {'Čeština': 'Nejnovější zprávy', 'English': 'Latest News'},
    'live': {'Čeština': 'ŽIVĚ', 'English': 'LIVE'},
    'finished': {'Čeština': 'Konec', 'English': 'FT'},
    'no_matches': {'Čeština': 'V tento den se neodehrály žádné zápasy', 'English': 'No matches played on this day'},
    'no_matches_today': {'Čeština': 'Dnes se neodehrály žádné zápasy', 'English': 'No matches played today'},
    'no_matches_tomorrow': {'Čeština': 'Zítra se neodehrají žádné zápasy', 'English': 'No matches scheduled for tomorrow'},
    'no_matches_subtitle': {'Čeština': 'Zkuste vybrat jiný den nebo obnovit data', 'English': 'Try selecting another day or refresh data'},
    
    // Dny v týdnu
    'monday': {'Čeština': 'Po', 'English': 'Mo'},
    'tuesday': {'Čeština': 'Út', 'English': 'Tu'},
    'wednesday': {'Čeština': 'St', 'English': 'We'},
    'thursday': {'Čeština': 'Čt', 'English': 'Th'},
    'friday': {'Čeština': 'Pá', 'English': 'Fr'},
    'saturday': {'Čeština': 'So', 'English': 'Sa'},
    'sunday': {'Čeština': 'Ne', 'English': 'Su'},
    
    // Měsíce
    'jan': {'Čeština': 'Led', 'English': 'Jan'},
    'feb': {'Čeština': 'Úno', 'English': 'Feb'},
    'mar': {'Čeština': 'Bře', 'English': 'Mar'},
    'apr': {'Čeština': 'Dub', 'English': 'Apr'},
    'may': {'Čeština': 'Kvě', 'English': 'May'},
    'jun': {'Čeština': 'Čer', 'English': 'Jun'},
    'jul': {'Čeština': 'Črc', 'English': 'Jul'},
    'aug': {'Čeština': 'Srp', 'English': 'Aug'},
    'sep': {'Čeština': 'Zář', 'English': 'Sep'},
    'oct': {'Čeština': 'Říj', 'English': 'Oct'},
    'nov': {'Čeština': 'Lis', 'English': 'Nov'},
    'dec': {'Čeština': 'Pro', 'English': 'Dec'},
    
    // Profil
    'profile': {'Čeština': 'Profil', 'English': 'Profile'},
    'edit_profile': {'Čeština': 'Upravit profil', 'English': 'Edit Profile'},
    'nickname': {'Čeština': 'Přezdívka', 'English': 'Nickname'},
    'email': {'Čeština': 'E-mail', 'English': 'Email'},
    'birth_date': {'Čeština': 'Datum narození', 'English': 'Birth Date'},
    'favorite_team': {'Čeština': 'Oblíbený tým', 'English': 'Favorite Team'},
    'save_changes': {'Čeština': 'Uložit změny', 'English': 'Save Changes'},
    'profile_updated': {'Čeština': 'Profil byl aktualizován', 'English': 'Profile updated'},
    'logout': {'Čeština': 'Odhlásit se', 'English': 'Logout'},
    'login': {'Čeština': 'Přihlásit se', 'English': 'Login'},
    'register': {'Čeština': 'Registrovat se', 'English': 'Register'},
    
    // Další texty pro chybové stavy
    'no_internet': {'Čeština': 'Bez připojení k internetu', 'English': 'No internet connection'},
    'server_error': {'Čeština': 'Chyba serveru', 'English': 'Server error'},
    'data_loading': {'Čeština': 'Načítání dat', 'English': 'Loading data'},
  };
  
  static String translate(String key) {
    return _translations[key]?[_currentLanguage] ?? key;
  }
  
  static String getDayName(int weekday) {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return translate(days[weekday - 1]);
  }
  
  static String getMonthName(int month) {
    final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    return translate(months[month - 1]);
  }
}