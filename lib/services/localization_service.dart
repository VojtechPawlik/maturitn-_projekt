class LocalizationService {
  // Překladové texty - vždy čeština
  static const Map<String, String> _translations = {
    // AppBar texty
    'settings': 'Nastavení',
    'teams': 'Týmy',
    'competitions': 'Soutěže',
    'favorites': 'Oblíbené',
    'home': 'Domů',
    'news': 'Novinky',
    
    // Nastavení
    'general': 'Obecné',
    'notifications': 'Oznámení',
    'notifications_subtitle': 'Povolit push notifikace',
    'about_app': 'O aplikaci',
    'app_version': 'Verze aplikace',
    'feedback': 'Zpětná vazba',
    'feedback_subtitle': 'Nahlásit chybu nebo navrhnout vylepšení',
    
    // Zpětná vazba
    'feedback_title': 'Zpětná vazba',
    'feedback_type': 'Typ zpětné vazby:',
    'bug': 'Chyba',
    'improvement': 'Návrh na vylepšení',
    'general_feedback': 'Obecná zpětná vazba',
    'your_message': 'Vaše zpráva:',
    'feedback_placeholder': 'Popište svou připomínku nebo návrh...',
    'cancel': 'Zrušit',
    'send': 'Odeslat',
    'thanks_feedback': 'Děkujeme za zpětnou vazbu!',
    
    // Oznámení
    'notifications_on': 'Oznámení zapnuta',
    'notifications_off': 'Oznámení vypnuta',
    'dark_mode_on': 'Tmavý režim zapnut',
    'light_mode_on': 'Světlý režim zapnut',
    
    // Chybové zprávy
    'error': 'Chyba',
    'try_again': 'Zkusit znovu',
    'loading': 'Načítání...',
    'refresh': 'Obnovit',
    
    // Hlavní stránka
    'all_competitions': 'Všechny soutěže',
    'favorite_teams': 'Oblíbené týmy',
    'no_favorite_teams': 'Zatím nemáte oblíbené týmy',
    'add_favorites_hint': 'Přidejte je kliknutím na srdcová na stránce týmů',
    'login_for_favorites': 'Přihlaste se pro sledování oblíbených týmů',
    'today': 'Dnes',
    'yesterday': 'Včera',
    'tomorrow': 'Zítra',
    'todays_matches': 'Dnešní zápasy',
    'results': 'Výsledky',
    'upcoming_matches': 'Nadcházející zápasy',
    'latest_news': 'Nejnovější zprávy',
    'live': 'ŽIVĚ',
    'finished': 'Konec',
    'no_matches': 'V tento den se neodehrály žádné zápasy',
    'no_matches_today': 'Dnes se neodehrály žádné zápasy',
    'no_matches_tomorrow': 'Zítra se neodehrají žádné zápasy',
    'no_matches_subtitle': 'Zkuste vybrat jiný den nebo obnovit data',
    
    // Dny v týdnu
    'monday': 'Po',
    'tuesday': 'Út',
    'wednesday': 'St',
    'thursday': 'Čt',
    'friday': 'Pá',
    'saturday': 'So',
    'sunday': 'Ne',
    
    // Měsíce
    'jan': 'Led',
    'feb': 'Úno',
    'mar': 'Bře',
    'apr': 'Dub',
    'may': 'Kvě',
    'jun': 'Čer',
    'jul': 'Črc',
    'aug': 'Srp',
    'sep': 'Zář',
    'oct': 'Říj',
    'nov': 'Lis',
    'dec': 'Pro',
    
    // Profil
    'profile': 'Profil',
    'edit_profile': 'Upravit profil',
    'nickname': 'Přezdívka',
    'email': 'E-mail',
    'birth_date': 'Datum narození',
    'favorite_team': 'Oblíbený tým',
    'save_changes': 'Uložit změny',
    'profile_updated': 'Profil byl aktualizován',
    'logout': 'Odhlásit se',
    'login': 'Přihlásit se',
    'register': 'Registrovat se',
    
    // Další texty pro chybové stavy
    'no_internet': 'Bez připojení k internetu',
    'server_error': 'Chyba serveru',
    'data_loading': 'Načítání dat',
  };
  
  static String translate(String key) {
    return _translations[key] ?? key;
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