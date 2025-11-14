import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class ApiFootballService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  String? _apiKey;

  // Načíst API klíč z Remote Config
  Future<void> initializeApiKey() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 0), // Pro debugging povolit okamžité načtení
      ));
      await remoteConfig.fetchAndActivate();
      _apiKey = remoteConfig.getString('api_football_key');
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        print('⚠️ API klíč není nastaven v Firebase Remote Config!');
        print('Nastavte parametr "api_football_key" v Firebase Console → Remote Config');
      } else {
        print('✅ API klíč načten (délka: ${_apiKey!.length} znaků)');
      }
    } catch (e) {
      print('❌ Chyba při načítání API klíče: $e');
    }
  }

  // Načíst tabulku konkrétní ligy
  Future<List<StandingTeam>> getStandings({
    required int leagueId,
    required int season,
  }) async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      final url = '$_baseUrl/standings?league=$leagueId&season=$season';
      print('🌐 Volám API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );
      
      print('📡 HTTP Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('❌ HTTP Response body: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Debug: zobrazit celou odpověď
        print('📥 API odpověď pro ligu $leagueId, sezóna $season:');
        print('Response status: ${data['results'] ?? 'N/A'}');
        print('Response data: ${data['response']?.length ?? 0} položek');
        
        // Kontrola chyb z API
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          final errorMsg = data['errors'].values.first.toString();
          print('❌ API chyba: $errorMsg');
          
          // Pokud je to chyba s plánem a sezónou, zkusit 2023
          if (errorMsg.contains('Free plans') && errorMsg.contains('season')) {
            if (season == 2024) {
              print('🔄 Zkouším sezónu 2023 místo 2024...');
              // Rekurzivně zkusit 2023
              return await getStandings(leagueId: leagueId, season: 2023);
            }
          }
          
          throw Exception('API chyba: $errorMsg');
        }
        
        // Kontrola struktury odpovědi
        if (data['response'] == null || data['response'].isEmpty) {
          print('⚠️ API vrátilo prázdnou odpověď pro ligu $leagueId, sezóna $season');
          print('Celá odpověď: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          
          // Pokud je to sezóna 2024 a free plán, zkusit 2023
          if (season == 2024) {
            print('🔄 Zkouším sezónu 2023 místo 2024...');
            return await getStandings(leagueId: leagueId, season: 2023);
          }
          
          throw Exception('API vrátilo prázdnou odpověď pro sezónu $season');
        }
        
        final responseData = data['response'][0];
        if (responseData['league'] == null || responseData['league']['standings'] == null) {
          print('API neobsahuje standings pro ligu $leagueId');
          throw Exception('API neobsahuje tabulku pro tuto ligu');
        }
        
        final standingsList = responseData['league']['standings'];
        if (standingsList == null || standingsList.isEmpty) {
          print('Standings jsou prázdné pro ligu $leagueId');
          throw Exception('Tabulka je prázdná');
        }
        
        // Standings může být buď List<List> (pro skupiny) nebo List (pro jednu skupinu)
        List standings;
        if (standingsList[0] is List) {
          // Pokud je to pole polí, vezmeme první skupinu
          standings = standingsList[0] as List;
        } else {
          // Pokud je to přímo pole týmů
          standings = standingsList as List;
        }
        
        if (standings.isEmpty) {
          throw Exception('Tabulka neobsahuje žádné týmy');
        }
        
        return standings.map((team) {
          try {
            return StandingTeam(
              position: team['rank'] ?? 0,
              teamName: team['team']?['name'] ?? 'Neznámý tým',
              teamLogo: team['team']?['logo'] ?? '',
              played: team['all']?['played'] ?? 0,
              won: team['all']?['win'] ?? 0,
              drawn: team['all']?['draw'] ?? 0,
              lost: team['all']?['lose'] ?? 0,
              goalsFor: team['all']?['goals']?['for'] ?? 0,
              goalsAgainst: team['all']?['goals']?['against'] ?? 0,
              goalDifference: team['goalsDiff'] ?? 0,
              points: team['points'] ?? 0,
            );
          } catch (e) {
            print('Chyba při parsování týmu: $e');
            rethrow;
          }
        }).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Neplatný API klíč. Zkontrolujte Firebase Remote Config.');
      } else if (response.statusCode == 403) {
        throw Exception('API klíč nemá oprávnění. Zkontrolujte svůj plán.');
      } else if (response.statusCode == 429) {
        throw Exception('Překročen limit API požadavků. Zkuste to později.');
      } else {
        final errorData = json.decode(response.body);
        final errorMsg = errorData['errors']?[0]?['message'] ?? 'Neznámá chyba';
        throw Exception('API chyba (${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      print('Chyba při načítání tabulky pro ligu $leagueId: $e');
      rethrow; // Znovu vyhodit chybu, aby se zobrazila uživateli
    }
  }

  // Načíst zápasy pro konkrétní datum
  Future<List<Match>> getFixtures({
    required DateTime date,
    int? leagueId,
  }) async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String url = '$_baseUrl/fixtures?date=$dateStr';
      
      if (leagueId != null) {
        url += '&league=$leagueId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixtures = data['response'] as List;
        
        return fixtures.map((fixture) {
          final fixtureData = fixture['fixture'];
          final teams = fixture['teams'];
          final goals = fixture['goals'];
          final league = fixture['league'];
          
          return Match(
            id: fixtureData['id'],
            homeTeam: teams['home']['name'],
            awayTeam: teams['away']['name'],
            homeLogo: teams['home']['logo'],
            awayLogo: teams['away']['logo'],
            date: DateTime.fromMillisecondsSinceEpoch(fixtureData['timestamp'] * 1000),
            status: fixtureData['status']['short'],
            statusLong: fixtureData['status']['long'],
            homeScore: goals['home'],
            awayScore: goals['away'],
            leagueId: league['id'],
            leagueName: league['name'],
            leagueLogo: league['logo'],
            round: league['round'],
            venue: fixtureData['venue']['name'] ?? '',
            city: fixtureData['venue']['city'] ?? '',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Chyba při načítání zápasů: $e');
      return [];
    }
  }

  // Načíst živé zápasy
  Future<List<Match>> getLiveFixtures() async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures?live=all'),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fixtures = data['response'] as List;
        
        return fixtures.map((fixture) {
          final fixtureData = fixture['fixture'];
          final teams = fixture['teams'];
          final goals = fixture['goals'];
          final league = fixture['league'];
          
          return Match(
            id: fixtureData['id'],
            homeTeam: teams['home']['name'],
            awayTeam: teams['away']['name'],
            homeLogo: teams['home']['logo'],
            awayLogo: teams['away']['logo'],
            date: DateTime.fromMillisecondsSinceEpoch(fixtureData['timestamp'] * 1000),
            status: fixtureData['status']['short'],
            statusLong: fixtureData['status']['long'],
            homeScore: goals['home'],
            awayScore: goals['away'],
            leagueId: league['id'],
            leagueName: league['name'],
            leagueLogo: league['logo'],
            round: league['round'],
            venue: fixtureData['venue']['name'] ?? '',
            city: fixtureData['venue']['city'] ?? '',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Chyba při načítání živých zápasů: $e');
      return [];
    }
  }
}

// Model pro tým v tabulce
class StandingTeam {
  final int position;
  final String teamName;
  final String teamLogo;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  StandingTeam({
    required this.position,
    required this.teamName,
    required this.teamLogo,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'teamName': teamName,
      'teamLogo': teamLogo,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifference': goalDifference,
      'points': points,
    };
  }
}

// Model pro zápas
class Match {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final DateTime date;
  final String status; // FT, NS, LIVE, HT, etc.
  final String statusLong;
  final int? homeScore;
  final int? awayScore;
  final int leagueId;
  final String leagueName;
  final String leagueLogo;
  final String round;
  final String venue;
  final String city;

  Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.date,
    required this.status,
    required this.statusLong,
    this.homeScore,
    this.awayScore,
    required this.leagueId,
    required this.leagueName,
    required this.leagueLogo,
    required this.round,
    required this.venue,
    required this.city,
  });

  bool get isLive => status == 'LIVE' || status == 'HT' || status == '1H' || status == '2H';
  bool get isFinished => status == 'FT' || status == 'AET' || status == 'PEN';
  bool get isUpcoming => status == 'NS' || status == 'TBD';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeLogo': homeLogo,
      'awayLogo': awayLogo,
      'date': date.toIso8601String(),
      'timestamp': date.millisecondsSinceEpoch,
      'status': status,
      'statusLong': statusLong,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'leagueId': leagueId,
      'leagueName': leagueName,
      'leagueLogo': leagueLogo,
      'round': round,
      'venue': venue,
      'city': city,
    };
  }

  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'],
      homeTeam: map['homeTeam'],
      awayTeam: map['awayTeam'],
      homeLogo: map['homeLogo'],
      awayLogo: map['awayLogo'],
      date: DateTime.parse(map['date']),
      status: map['status'],
      statusLong: map['statusLong'],
      homeScore: map['homeScore'],
      awayScore: map['awayScore'],
      leagueId: map['leagueId'],
      leagueName: map['leagueName'],
      leagueLogo: map['leagueLogo'],
      round: map['round'],
      venue: map['venue'],
      city: map['city'],
    );
  }
}
