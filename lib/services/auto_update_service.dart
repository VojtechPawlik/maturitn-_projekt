import 'dart:async';
import 'firestore_service.dart';

/// Služba pro automatickou aktualizaci dat z API do Firestore
/// 
/// Tato služba pravidelně aktualizuje:
/// - Tabulky soutěží
/// - Zápasy pro aktuální a následující dny
/// - Živé zápasy
class AutoUpdateService {
  static final AutoUpdateService _instance = AutoUpdateService._internal();
  factory AutoUpdateService() => _instance;
  AutoUpdateService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  Timer? _updateTimer;
  bool _isRunning = false;

  // Mapa lig k aktualizaci: {leagueId: {apiLeagueId: int, season: int}}
  final Map<String, Map<String, int>> _leaguesToUpdate = {};

  /// Přidat ligu k automatické aktualizaci
  void addLeague({
    required String leagueId,
    required int apiLeagueId,
    required int season,
  }) {
    _leaguesToUpdate[leagueId] = {
      'apiLeagueId': apiLeagueId,
      'season': season,
    };
  }

  /// Spustit automatickou aktualizaci
  /// 
  /// [intervalMinutes] - interval aktualizace v minutách (výchozí: 10)
  void startAutoUpdate({int intervalMinutes = 10}) {
    if (_isRunning) {
      return;
    }

    _isRunning = true;

    // Okamžitá aktualizace při startu
    _performUpdate();

    // Pravidelná aktualizace
    _updateTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _performUpdate(),
    );
  }

  /// Zastavit automatickou aktualizaci
  void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isRunning = false;
  }

  /// Provede aktualizaci všech lig
  Future<void> _performUpdate() async {
    // 1) Aktualizovat ligová data (pokud jsou nakonfigurována)
    if (_leaguesToUpdate.isNotEmpty) {
      for (var entry in _leaguesToUpdate.entries) {
        final leagueId = entry.key;
        final config = entry.value;
        
        try {
          await _firestoreService.updateLeagueData(
            leagueId: leagueId,
            apiLeagueId: config['apiLeagueId']!,
            season: config['season']!,
          );
        } catch (e) {
          // Chyba při aktualizaci ligy
        }
      }
    }

    // 2) Automaticky aktualizovat novinky z externího API
    try {
      await _firestoreService.fetchAndSaveNewsFromApi();
    } catch (e) {
      // Chyba při aktualizaci novinek – ignorovat
    }
  }

  /// Manuální aktualizace všech lig
  Future<void> updateAll() async {
    await _performUpdate();
  }

  /// Zkontrolovat, zda služba běží
  bool get isRunning => _isRunning;

  /// Počet lig k aktualizaci
  int get leaguesCount => _leaguesToUpdate.length;
}

