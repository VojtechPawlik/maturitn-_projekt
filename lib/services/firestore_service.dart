import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_football_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiFootballService _apiFootballService = ApiFootballService();

  // Načíst všechny ligy
  Future<List<League>> getLeagues() async {
    try {
      final snapshot = await _firestore.collection('leagues').get();
      
      return snapshot.docs.map((doc) {
        return League(
          id: doc.id,
          name: doc['name'] ?? '',
          country: doc['country'] ?? '',
          logo: doc['logo'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Načíst konkrétní ligu
  Future<League?> getLeague(String leagueId) async {
    try {
      final doc = await _firestore.collection('leagues').doc(leagueId).get();
      
      if (doc.exists) {
        return League(
          id: doc.id,
          name: doc['name'] ?? '',
          country: doc['country'] ?? '',
          logo: doc['logo'] ?? '',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Načíst a uložit tabulku z API do Firestore
  Future<void> fetchAndSaveStandings({
    required String leagueId,
    required int apiLeagueId,
    required int season,
  }) async {
    try {
      // Načíst z API
      final standings = await _apiFootballService.getStandings(
        leagueId: apiLeagueId,
        season: season,
      );

      if (standings.isEmpty) return;

      // Uložit do Firestore
      final docId = '${leagueId}_$season';
      await _firestore.collection('standings').doc(docId).set({
        'leagueId': leagueId,
        'season': season,
        'updated': FieldValue.serverTimestamp(),
        'teams': standings.map((team) => team.toMap()).toList(),
      });
    } catch (e) {
      // Chyba při ukládání
    }
  }

  // Načíst tabulku z Firestore
  Future<List<StandingTeam>> getStandings({
    required String leagueId,
    required int season,
  }) async {
    try {
      final docId = '${leagueId}_$season';
      final doc = await _firestore.collection('standings').doc(docId).get();
      
      if (doc.exists) {
        final teams = doc['teams'] as List;
        return teams.map((team) => StandingTeam(
          position: team['position'],
          teamName: team['teamName'],
          teamLogo: team['teamLogo'],
          played: team['played'],
          won: team['won'],
          drawn: team['drawn'],
          lost: team['lost'],
          goalsFor: team['goalsFor'],
          goalsAgainst: team['goalsAgainst'],
          goalDifference: team['goalDifference'],
          points: team['points'],
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Načíst týmy z Firebase
  Future<List<Team>> getTeams() async {
    try {
      final snapshot = await _firestore.collection('teams').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Team(
          id: doc.id,
          name: data['name'] ?? '',
          league: data['league'] ?? '',
          logoUrl: data['logo'] ?? '',
          country: data['country'] ?? '',
          stadium: data['stadium'] ?? '',
          stadiumCountry: data['stadiumCountry'] ?? '',
          city: data['city'] ?? '',
          season: data['season'] ?? 2024,
        );
      }).toList();
    } catch (e) {
      print('Chyba při načítání týmů: $e');
      return [];
    }
  }
}

// Model pro ligu
class League {
  final String id;
  final String name;
  final String country;
  final String logo;

  League({
    required this.id,
    required this.name,
    required this.country,
    required this.logo,
  });
}

// Model pro tým
class Team {
  final String id;
  final String name;
  final String league;
  final String logoUrl;
  final String country;
  final String stadium;
  final String stadiumCountry;
  final String city;
  final int season;

  Team({
    required this.id,
    required this.name,
    required this.league,
    required this.logoUrl,
    required this.country,
    required this.stadium,
    required this.stadiumCountry,
    required this.city,
    required this.season,
  });
}
