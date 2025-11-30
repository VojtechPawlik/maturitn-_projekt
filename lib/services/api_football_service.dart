import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';

class ApiFootballService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  static const String _rapidApiBaseUrl = 'https://api-football-v1.p.rapidapi.com/v3';
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
    } catch (e) {
      // Chyba při načítání API klíče
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
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Kontrola chyb z API
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          final errorMsg = data['errors'].values.first.toString();
          throw Exception('API chyba: $errorMsg');
        }
        
        // Kontrola struktury odpovědi
        if (data['response'] == null || data['response'].isEmpty) {
          throw Exception('API vrátilo prázdnou odpověď pro sezónu $season');
        }
        
        final responseData = data['response'][0];
        if (responseData['league'] == null || responseData['league']['standings'] == null) {
          throw Exception('API neobsahuje tabulku pro tuto ligu');
        }
        
        final standingsList = responseData['league']['standings'];
        if (standingsList == null || standingsList.isEmpty) {
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
      return [];
    }
  }

  // Načíst týmy z ligy s detailními informacemi
  Future<List<Map<String, dynamic>>> getTeamsFromLeague({
    required int leagueId,
    required int season,
  }) async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      // Použijeme teams endpoint pro detailní informace o týmech
      final url = '$_baseUrl/teams?league=$leagueId&season=$season';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          final errorMsg = data['errors'].values.first.toString();
          throw Exception('API chyba: $errorMsg');
        }

        if (data['response'] == null || data['response'].isEmpty) {
          return [];
        }

        final List<Map<String, dynamic>> teams = [];
        final leagueInfo = data['response'][0]['league'];
        
        for (var teamData in data['response']) {
          final team = teamData['team'];
          final venue = teamData['venue'] ?? {};
          
          teams.add({
            'id': team['id'] ?? 0, // API team ID
            'name': team['name'] ?? '',
            'logo': team['logo'] ?? '',
            'country': leagueInfo['country'] ?? '',
            'league': leagueInfo['name'] ?? '',
            'stadium': venue['name'] ?? '',
            'city': venue['city'] ?? '',
            'stadiumCountry': venue['country'] ?? leagueInfo['country'] ?? '',
          });
        }
        
        return teams;
      }
      return [];
    } catch (e) {
      return [];
    }
  }


  // Načíst kurzy k zápasu
  Future<Map<String, dynamic>?> getMatchOdds(int fixtureId) async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      final url = '$_baseUrl/odds?fixture=$fixtureId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          return null;
        }

        if (data['response'] == null || data['response'].isEmpty) {
          return null;
        }

        // API vrací kurzy od různých bookmakerů
        // Vezmeme první dostupný bookmaker (obvykle je to Bet365 nebo podobný)
        final oddsData = data['response'][0];
        final bookmaker = oddsData['bookmakers']?[0];
        
        if (bookmaker == null || bookmaker['bets'] == null) {
          return null;
        }

        // Najít kurzy na výsledek zápasu (1X2)
        final bets = bookmaker['bets'] as List;
        final matchResultBet = bets.firstWhere(
          (bet) => bet['name'] == 'Match Winner' || bet['name'] == '1X2',
          orElse: () => null,
        );

        if (matchResultBet == null || matchResultBet['values'] == null) {
          return null;
        }

        final values = matchResultBet['values'] as List;
        double homeWin = 2.0;
        double draw = 3.0;
        double awayWin = 2.5;

        for (var value in values) {
          final option = value['value']?.toString().toLowerCase() ?? '';
          final odd = double.tryParse(value['odd']?.toString() ?? '') ?? 1.0;
          
          if (option == 'home' || option == '1') {
            homeWin = odd;
          } else if (option == 'draw' || option == 'x') {
            draw = odd;
          } else if (option == 'away' || option == '2') {
            awayWin = odd;
          }
        }

        // Najít kurzy na počet gólů (Over/Under 2.5)
        double? over25;
        double? under25;
        
        final goalsBet = bets.firstWhere(
          (bet) => bet['name']?.toString().toLowerCase().contains('goals') == true ||
                   bet['name']?.toString().toLowerCase().contains('over') == true,
          orElse: () => null,
        );

        if (goalsBet != null && goalsBet['values'] != null) {
          final goalValues = goalsBet['values'] as List;
          for (var value in goalValues) {
            final option = value['value']?.toString().toLowerCase() ?? '';
            final odd = double.tryParse(value['odd']?.toString() ?? '') ?? 1.0;
            
            if (option.contains('over') && option.contains('2.5')) {
              over25 = odd;
            } else if (option.contains('under') && option.contains('2.5')) {
              under25 = odd;
            }
          }
        }

        // Najít kurzy na BTTS (Both Teams To Score)
        double? bothTeamsScore;
        double? bothTeamsNoScore;
        
        final bttsBet = bets.firstWhere(
          (bet) => bet['name']?.toString().toLowerCase().contains('both teams') == true ||
                   bet['name']?.toString().toLowerCase().contains('btts') == true,
          orElse: () => null,
        );

        if (bttsBet != null && bttsBet['values'] != null) {
          final bttsValues = bttsBet['values'] as List;
          for (var value in bttsValues) {
            final option = value['value']?.toString().toLowerCase() ?? '';
            final odd = double.tryParse(value['odd']?.toString() ?? '') ?? 1.0;
            
            if (option == 'yes' || option.contains('yes')) {
              bothTeamsScore = odd;
            } else if (option == 'no' || option.contains('no')) {
              bothTeamsNoScore = odd;
            }
          }
        }

        // Najít kurzy na dvojice (1X, X2, 12)
        double? homeWinOrDraw;
        double? awayWinOrDraw;
        double? homeOrAway;
        
        final doubleChanceBet = bets.firstWhere(
          (bet) => bet['name']?.toString().toLowerCase().contains('double chance') == true ||
                   bet['name']?.toString().toLowerCase().contains('1x') == true,
          orElse: () => null,
        );

        if (doubleChanceBet != null && doubleChanceBet['values'] != null) {
          final doubleChanceValues = doubleChanceBet['values'] as List;
          for (var value in doubleChanceValues) {
            final option = value['value']?.toString().toUpperCase() ?? '';
            final odd = double.tryParse(value['odd']?.toString() ?? '') ?? 1.0;
            
            if (option == '1X' || option.contains('1X')) {
              homeWinOrDraw = odd;
            } else if (option == 'X2' || option.contains('X2')) {
              awayWinOrDraw = odd;
            } else if (option == '12' || option == '1/2') {
              homeOrAway = odd;
            }
          }
        }

        return {
          'homeWin': homeWin,
          'draw': draw,
          'awayWin': awayWin,
          'over25': over25,
          'under25': under25,
          'bothTeamsScore': bothTeamsScore,
          'bothTeamsNoScore': bothTeamsNoScore,
          'homeWinOrDraw': homeWinOrDraw,
          'awayWinOrDraw': awayWinOrDraw,
          'homeOrAway': homeOrAway,
        };
      }
      return null;
    } catch (e) {
      // Pokud API nevrátí kurzy, vrátit null (budou použity výchozí)
      return null;
    }
  }

  // Načíst hráče týmu
  Future<List<Map<String, dynamic>>> getPlayersFromTeam({
    required int teamId,
    required int season,
  }) async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      // Endpoint pro soupisky hráčů - nepotřebuje season parametr
      final url = '$_baseUrl/players/squads?team=$teamId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Kontrola chyb z API
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          final errorMsg = data['errors'].values.first.toString();
          throw Exception('API chyba: $errorMsg');
        }

        // Kontrola struktury odpovědi
        if (data['response'] == null || data['response'].isEmpty) {
          return [];
        }

        final List<Map<String, dynamic>> players = [];
        
        // Projít všechny odpovědi (může jich být více)
        for (var squadData in data['response']) {
          if (squadData['players'] != null && squadData['players'] is List) {
            for (var playerData in squadData['players']) {
              // Zkontrolovat, jestli hráč už není v seznamu (podle ID)
              final playerId = playerData['id'] ?? 0;
              if (playerId > 0 && !players.any((p) => p['id'] == playerId)) {
                players.add({
                  'id': playerId,
                  'name': playerData['name'] ?? '',
                  'number': playerData['number'] ?? 0,
                  'position': playerData['position'] ?? '',
                  'age': playerData['age'] ?? 0,
                  'nationality': playerData['nationality'] ?? '',
                  'photo': playerData['photo'] ?? '',
                });
              }
            }
          }
        }
        
        return players;
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
      rethrow; // Znovu vyhodit chybu, aby se zobrazila uživateli
    }
  }

  // Načíst profil hráče
  Future<Map<String, dynamic>?> getPlayerProfile({
    required int playerId,
  }) async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      final url = '$_rapidApiBaseUrl/players/profiles?player=$playerId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'api-football-v1.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Kontrola chyb z API
        if (data['errors'] != null && data['errors'].isNotEmpty) {
          final errorMsg = data['errors'].values.first.toString();
          throw Exception('API chyba: $errorMsg');
        }

        // Kontrola struktury odpovědi
        if (data['response'] == null || data['response'].isEmpty) {
          return null;
        }

        final playerData = data['response'][0];
        
        // Extrahovat relevantní informace o profilu hráče
        final player = playerData['player'] ?? {};
        final statistics = playerData['statistics'] ?? [];
        
        return {
          'id': player['id'] ?? playerId,
          'name': player['name'] ?? '',
          'firstname': player['firstname'] ?? '',
          'lastname': player['lastname'] ?? '',
          'age': player['age'] ?? 0,
          'birth': {
            'date': player['birth']?['date'] ?? '',
            'place': player['birth']?['place'] ?? '',
            'country': player['birth']?['country'] ?? '',
          },
          'nationality': player['nationality'] ?? '',
          'height': player['height'] ?? '',
          'weight': player['weight'] ?? '',
          'injured': player['injured'] ?? false,
          'photo': player['photo'] ?? '',
          'statistics': statistics.map((stat) {
            final team = stat['team'] ?? {};
            final league = stat['league'] ?? {};
            final games = stat['games'] ?? {};
            final goals = stat['goals'] ?? {};
            final cards = stat['cards'] ?? {};
            
            return {
              'team': {
                'id': team['id'] ?? 0,
                'name': team['name'] ?? '',
                'logo': team['logo'] ?? '',
              },
              'league': {
                'id': league['id'] ?? 0,
                'name': league['name'] ?? '',
                'country': league['country'] ?? '',
                'logo': league['logo'] ?? '',
              },
              'games': {
                'appearences': games['appearences'] ?? 0,
                'lineups': games['lineups'] ?? 0,
                'minutes': games['minutes'] ?? 0,
                'position': games['position'] ?? '',
                'rating': games['rating'] ?? '',
                'captain': games['captain'] ?? false,
              },
              'goals': {
                'total': goals['total'] ?? 0,
                'conceded': goals['conceded'] ?? 0,
                'assists': goals['assists'] ?? 0,
                'saves': goals['saves'] ?? 0,
              },
              'cards': {
                'yellow': cards['yellow'] ?? 0,
                'red': cards['red'] ?? 0,
              },
              'season': stat['season'] ?? '',
            };
          }).toList(),
        };
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
      rethrow;
    }
  }
}

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

