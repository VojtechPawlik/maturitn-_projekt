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
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.fetchAndActivate();
      _apiKey = remoteConfig.getString('api_football_key');
    } catch (e) {
      print('Chyba při načítání API klíče: $e');
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
      final response = await http.get(
        Uri.parse('$_baseUrl/standings?league=$leagueId&season=$season'),
        headers: {
          'x-rapidapi-key': _apiKey ?? '',
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final standings = data['response'][0]['league']['standings'][0] as List;
        
        return standings.map((team) => StandingTeam(
          position: team['rank'],
          teamName: team['team']['name'],
          teamLogo: team['team']['logo'],
          played: team['all']['played'],
          won: team['all']['win'],
          drawn: team['all']['draw'],
          lost: team['all']['lose'],
          goalsFor: team['all']['goals']['for'],
          goalsAgainst: team['all']['goals']['against'],
          goalDifference: team['goalsDiff'],
          points: team['points'],
        )).toList();
      }
      return [];
    } catch (e) {
      print('Chyba při načítání tabulky: $e');
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
