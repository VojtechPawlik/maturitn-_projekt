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

  // Načíst detailní informace o zápase
  Future<MatchDetails?> getMatchDetails(int fixtureId) async {
    if (_apiKey == null) {
      await initializeApiKey();
    }

    try {
      final url = '$_baseUrl/fixtures?id=$fixtureId';
      
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

        final fixture = data['response'][0];
        final fixtureData = fixture['fixture'];
        final events = fixture['events'] as List? ?? [];
        final statistics = fixture['statistics'] as List? ?? [];
        final lineups = fixture['lineups'] as List? ?? [];

        // Parsovat góly
        final List<Goal> goals = [];
        for (var event in events) {
          if (event['type']['name'] == 'Goal') {
            final team = event['team']['id'] == fixtureData['teams']['home']['id'] ? 'home' : 'away';
            final player = event['player']['name'] ?? '';
            final minute = event['time']['elapsed'] ?? 0;
            final detail = event['detail']?.toString() ?? '';
            final isOwnGoal = detail.contains('Own Goal');
            final isPenalty = detail.contains('Penalty');
            final assist = event['assist'];
            final assistPlayer = assist != null ? (assist['name'] ?? '') : '';
            
            goals.add(Goal(
              minute: minute,
              player: player,
              team: team,
              isOwnGoal: isOwnGoal,
              isPenalty: isPenalty,
              assist: assistPlayer,
            ));
          }
        }

        // Parsovat karty
        final List<MatchCard> cards = [];
        for (var event in events) {
          if (event['type']['name'] == 'Card') {
            final team = event['team']['id'] == fixtureData['teams']['home']['id'] ? 'home' : 'away';
            final player = event['player']['name'] ?? '';
            final minute = event['time']['elapsed'] ?? 0;
            final type = event['detail'] == 'Yellow Card' ? 'yellow' : 'red';
            
            cards.add(MatchCard(
              minute: minute,
              player: player,
              team: team,
              type: type,
            ));
          }
        }

        // Parsovat střídání
        final List<Substitution> substitutions = [];
        for (var event in events) {
          if (event['type']['name'] == 'subst') {
            final team = event['team']['id'] == fixtureData['teams']['home']['id'] ? 'home' : 'away';
            // V API: player je hráč, který odchází, assist je hráč, který přichází
            final playerOut = event['player']['name'] ?? '';
            final assist = event['assist'];
            final playerIn = assist != null ? (assist['name'] ?? '') : '';
            final minute = event['time']['elapsed'] ?? 0;
            
            if (playerOut.isNotEmpty && playerIn.isNotEmpty) {
              substitutions.add(Substitution(
                minute: minute,
                playerOut: playerOut,
                playerIn: playerIn,
                team: team,
              ));
            }
          }
        }

        // Parsovat statistiky
        final Map<String, int> homeStats = {};
        final Map<String, int> awayStats = {};
        
        for (var stat in statistics) {
          final teamId = stat['team']['id'];
          final isHome = teamId == fixtureData['teams']['home']['id'];
          
          for (var statItem in stat['statistics'] ?? []) {
            final statName = statItem['type'] ?? '';
            final statValue = statItem['value'] is int 
                ? statItem['value'] 
                : (int.tryParse(statItem['value'].toString()) ?? 0);
            
            if (isHome) {
              homeStats[statName] = statValue;
            } else {
              awayStats[statName] = statValue;
            }
          }
        }

        // Parsovat sestavy
        Lineup homeLineup = Lineup(formation: '', startingXI: [], substitutes: []);
        Lineup awayLineup = Lineup(formation: '', startingXI: [], substitutes: []);
        
        for (var lineup in lineups) {
          final teamId = lineup['team']['id'];
          final isHome = teamId == fixtureData['teams']['home']['id'];
          
          final formation = lineup['formation'] ?? '';
          final startingXI = (lineup['startXI'] as List?)?.map((p) {
            final player = p['player'];
            return LineupPlayer(
              id: player['id'] ?? 0,
              name: player['name'] ?? '',
              number: player['number'] ?? 0,
              position: p['pos'] ?? '',
              grid: p['grid'],
            );
          }).toList() ?? [];
          
          final substitutes = (lineup['substitutes'] as List?)?.map((p) {
            final player = p['player'];
            return LineupPlayer(
              id: player['id'] ?? 0,
              name: player['name'] ?? '',
              number: player['number'] ?? 0,
              position: p['pos'] ?? '',
              grid: p['grid'],
            );
          }).toList() ?? [];
          
          final lineupObj = Lineup(
            formation: formation,
            startingXI: startingXI,
            substitutes: substitutes,
          );
          
          if (isHome) {
            homeLineup = lineupObj;
          } else {
            awayLineup = lineupObj;
          }
        }

        return MatchDetails(
          fixtureId: fixtureId,
          goals: goals,
          cards: cards,
          substitutions: substitutions,
          statistics: MatchStatistics(
            homeStats: homeStats,
            awayStats: awayStats,
          ),
          homeLineup: homeLineup,
          awayLineup: awayLineup,
        );
      }
      return null;
    } catch (e) {
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

class MatchDetails {
  final int fixtureId;
  final List<Goal> goals;
  final List<MatchCard> cards;
  final List<Substitution> substitutions;
  final MatchStatistics statistics;
  final Lineup homeLineup;
  final Lineup awayLineup;

  MatchDetails({
    required this.fixtureId,
    required this.goals,
    required this.cards,
    required this.substitutions,
    required this.statistics,
    required this.homeLineup,
    required this.awayLineup,
  });

  Map<String, dynamic> toMap() {
    return {
      'fixtureId': fixtureId,
      'goals': goals.map((g) => g.toMap()).toList(),
      'cards': cards.map((c) => c.toMap()).toList(),
      'substitutions': substitutions.map((s) => s.toMap()).toList(),
      'statistics': statistics.toMap(),
      'homeLineup': homeLineup.toMap(),
      'awayLineup': awayLineup.toMap(),
    };
  }

  factory MatchDetails.fromMap(Map<String, dynamic> map) {
    return MatchDetails(
      fixtureId: map['fixtureId'] ?? 0,
      goals: (map['goals'] as List?)?.map((g) => Goal.fromMap(g)).toList() ?? [],
      cards: (map['cards'] as List?)?.map((c) => MatchCard.fromMap(c)).toList() ?? [],
      substitutions: (map['substitutions'] as List?)?.map((s) => Substitution.fromMap(s)).toList() ?? [],
      statistics: MatchStatistics.fromMap(map['statistics'] ?? {}),
      homeLineup: Lineup.fromMap(map['homeLineup'] ?? {}),
      awayLineup: Lineup.fromMap(map['awayLineup'] ?? {}),
    );
  }
}

class Goal {
  final int minute;
  final String player;
  final String team; // 'home' nebo 'away'
  final bool isOwnGoal;
  final bool isPenalty;
  final String assist; // Jméno hráče, který asistoval

  Goal({
    required this.minute,
    required this.player,
    required this.team,
    this.isOwnGoal = false,
    this.isPenalty = false,
    this.assist = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'minute': minute,
      'player': player,
      'team': team,
      'isOwnGoal': isOwnGoal,
      'isPenalty': isPenalty,
      'assist': assist,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      minute: map['minute'] ?? 0,
      player: map['player'] ?? '',
      team: map['team'] ?? '',
      isOwnGoal: map['isOwnGoal'] ?? false,
      isPenalty: map['isPenalty'] ?? false,
      assist: map['assist'] ?? '',
    );
  }
}

class MatchCard {
  final int minute;
  final String player;
  final String team; // 'home' nebo 'away'
  final String type; // 'yellow' nebo 'red'

  MatchCard({
    required this.minute,
    required this.player,
    required this.team,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'minute': minute,
      'player': player,
      'team': team,
      'type': type,
    };
  }

  factory MatchCard.fromMap(Map<String, dynamic> map) {
    return MatchCard(
      minute: map['minute'] ?? 0,
      player: map['player'] ?? '',
      team: map['team'] ?? '',
      type: map['type'] ?? '',
    );
  }
}

class Substitution {
  final int minute;
  final String playerOut;
  final String playerIn;
  final String team; // 'home' nebo 'away'

  Substitution({
    required this.minute,
    required this.playerOut,
    required this.playerIn,
    required this.team,
  });

  Map<String, dynamic> toMap() {
    return {
      'minute': minute,
      'playerOut': playerOut,
      'playerIn': playerIn,
      'team': team,
    };
  }

  factory Substitution.fromMap(Map<String, dynamic> map) {
    return Substitution(
      minute: map['minute'] ?? 0,
      playerOut: map['playerOut'] ?? '',
      playerIn: map['playerIn'] ?? '',
      team: map['team'] ?? '',
    );
  }
}

class MatchStatistics {
  final Map<String, int> homeStats;
  final Map<String, int> awayStats;

  MatchStatistics({
    required this.homeStats,
    required this.awayStats,
  });

  Map<String, dynamic> toMap() {
    return {
      'homeStats': homeStats,
      'awayStats': awayStats,
    };
  }

  factory MatchStatistics.fromMap(Map<String, dynamic> map) {
    return MatchStatistics(
      homeStats: Map<String, int>.from(map['homeStats'] ?? {}),
      awayStats: Map<String, int>.from(map['awayStats'] ?? {}),
    );
  }
}

class Lineup {
  final String formation;
  final List<LineupPlayer> startingXI;
  final List<LineupPlayer> substitutes;

  Lineup({
    required this.formation,
    required this.startingXI,
    required this.substitutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'formation': formation,
      'startingXI': startingXI.map((p) => p.toMap()).toList(),
      'substitutes': substitutes.map((p) => p.toMap()).toList(),
    };
  }

  factory Lineup.fromMap(Map<String, dynamic> map) {
    return Lineup(
      formation: map['formation'] ?? '',
      startingXI: (map['startingXI'] as List?)?.map((p) => LineupPlayer.fromMap(p)).toList() ?? [],
      substitutes: (map['substitutes'] as List?)?.map((p) => LineupPlayer.fromMap(p)).toList() ?? [],
    );
  }
}

class LineupPlayer {
  final int id;
  final String name;
  final int number;
  final String position;
  final String? grid; // Pozice na hřišti (např. "4:3")

  LineupPlayer({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    this.grid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'position': position,
      'grid': grid,
    };
  }

  factory LineupPlayer.fromMap(Map<String, dynamic> map) {
    return LineupPlayer(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      number: map['number'] ?? 0,
      position: map['position'] ?? '',
      grid: map['grid'],
    );
  }
}
