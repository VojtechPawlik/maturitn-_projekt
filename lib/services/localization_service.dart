class LocalizationService {
  static String _currentLanguage = 'Čeština';
  
  static String get currentLanguage => _currentLanguage;
  
  static void setLanguage(String language) {
    _currentLanguage = language;
    // TODO: Zde lze později přidat uložení do SharedPreferences
  }
  
  static void initLanguage() {
    // Inicializace při spuštění aplikace
    // TODO: Načíst z SharedPreferences
  }
  
  static bool get isEnglish => _currentLanguage == 'English';
  
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
    'dark_mode': {'Čeština': 'Tmavý režim', 'English': 'Dark Mode'},
    'dark_mode_subtitle': {'Čeština': 'Přepnout na tmavé téma', 'English': 'Switch to dark theme'},
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
    
    // Dialogy
    'restart_app': {'Čeština': 'Restart aplikace', 'English': 'Restart App'},
    'restart_message': {'Čeština': 'Pro použití nového tématu je potřeba restartovat aplikaci.', 'English': 'App restart is required to apply the new theme.'},
    'ok': {'Čeština': 'OK', 'English': 'OK'},
    'select_language': {'Čeština': 'Vyberte jazyk', 'English': 'Select Language'},
    
    // Týmy
    'search_team': {'Čeština': 'Vyhledat tým...', 'English': 'Search team...'},
    'no_teams_found': {'Čeština': 'Žádné týmy nenalezeny', 'English': 'No teams found'},
    'all': {'Čeština': 'Všechny', 'English': 'All'},
    'information': {'Čeština': 'Informace', 'English': 'Information'},
    'squad': {'Čeština': 'Soupiska', 'English': 'Squad'},
    'team_name': {'Čeština': 'Název týmu', 'English': 'Team Name'},
    'league': {'Čeština': 'Liga', 'English': 'League'},
    'season': {'Čeština': 'Sezona', 'English': 'Season'},
    'stadium': {'Čeština': 'Stadion', 'English': 'Stadium'},
    'city': {'Čeština': 'Město', 'English': 'City'},
    'country': {'Čeština': 'Země', 'English': 'Country'},
    'squad_later': {'Čeština': 'Soupiska bude přidána později', 'English': 'Squad will be added later'},
    
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