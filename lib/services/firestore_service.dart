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

      if (standings.isEmpty) {
        throw Exception('Tabulka je prázdná. Možná liga nemá data pro sezónu $season.');
      }

      // Uložit do Firestore
      final docId = '${leagueId}_$season';
      await _firestore.collection('standings').doc(docId).set({
        'leagueId': leagueId,
        'season': season,
        'updated': FieldValue.serverTimestamp(),
        'teams': standings.map((team) => team.toMap()).toList(),
      });
      
      print('✅ Tabulka pro $leagueId uložena do Firestore');
    } catch (e) {
      print('❌ Chyba při ukládání tabulky pro $leagueId: $e');
      rethrow; // Znovu vyhodit chybu
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

  // Uložit zápasy do Firestore
  Future<void> saveFixtures({
    required DateTime date,
    required List<Match> matches,
  }) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docId = 'fixtures_$dateStr';
      
      await _firestore.collection('fixtures').doc(docId).set({
        'date': dateStr,
        'timestamp': Timestamp.fromDate(date),
        'updated': FieldValue.serverTimestamp(),
        'matches': matches.map((match) => match.toMap()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Chyba při ukládání zápasů: $e');
    }
  }

  // Povolené ligy - pouze top 5 lig a evropské soutěže
  static const Set<int> _allowedLeagueIds = {
    39,   // Premier League (Anglická)
    140,  // La Liga (Španělská)
    135,  // Serie A (Italská)
    78,   // Bundesliga (Německá)
    61,   // Ligue 1 (Francouzská)
    2,    // Champions League (Liga mistrů)
    3,    // Europa League (Evropská liga)
  };

  // Načíst zápasy z Firestore pro konkrétní datum
  Future<List<Match>> getFixtures(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final docId = 'fixtures_$dateStr';
      final doc = await _firestore.collection('fixtures').doc(docId).get();
      
      if (doc.exists) {
        final matches = doc['matches'] as List;
        final allMatches = matches.map((match) => Match.fromMap(match)).toList();
        // Filtrovat pouze povolené ligy
        return allMatches.where((match) => _allowedLeagueIds.contains(match.leagueId)).toList();
      }
      return [];
    } catch (e) {
      print('Chyba při načítání zápasů: $e');
      return [];
    }
  }

  // Načíst živé zápasy z Firestore (real-time listener)
  // Poznámka: Firestore nepodporuje dotaz na pole v array, takže načítáme všechny zápasy a filtrujeme
  Stream<List<Match>> getLiveFixturesStream() {
    // Načíst zápasy pro dnešek a zítřek
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dates = [
      'fixtures_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
      'fixtures_${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}',
    ];
    
    return _firestore
        .collection('fixtures')
        .where(FieldPath.documentId, whereIn: dates)
        .snapshots()
        .map((snapshot) {
      final allMatches = <Match>[];
      for (var doc in snapshot.docs) {
        final matches = doc['matches'] as List?;
        if (matches != null) {
          for (var matchData in matches) {
            final match = Match.fromMap(matchData);
            // Filtrovat pouze živé zápasy z povolených lig
            if (match.isLive && _allowedLeagueIds.contains(match.leagueId)) {
              allMatches.add(match);
            }
          }
        }
      }
      return allMatches;
    });
  }

  // Automatická aktualizace tabulek a zápasů
  Future<void> updateLeagueData({
    required String leagueId,
    required int apiLeagueId,
    required int season,
  }) async {
    try {
      // Aktualizovat tabulku
      await fetchAndSaveStandings(
        leagueId: leagueId,
        apiLeagueId: apiLeagueId,
        season: season,
      );
      
      // Aktualizovat zápasy pro dnešek a zítřek (pouze pokud tabulka byla úspěšně načtena)
      // Zápasy se aktualizují samostatně při zobrazení kalendáře
    } catch (e) {
      print('Chyba při automatické aktualizaci: $e');
    }
  }

  // Načíst týmy z Firebase
  Future<List<Team>> getTeams() async {
    try {
      final snapshot = await _firestore.collection('teams').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Vytvořit mapu všech fields kromě základních
        final Map<String, dynamic> additionalFields = {};
        final knownFields = {'name', 'league', 'logo', 'logoUrl', 'country', 'stadium', 'stadiumCountry', 'city', 'season'};
        
        data.forEach((key, value) {
          if (!knownFields.contains(key)) {
            additionalFields[key] = value;
          }
        });
        
        return Team(
          id: doc.id,
          name: data['name'] ?? '',
          league: data['league'] ?? '',
          logoUrl: data['logo'] ?? data['logoUrl'] ?? '',
          country: data['country'] ?? '',
          stadium: data['stadium'] ?? '',
          stadiumCountry: data['stadiumCountry'] ?? '',
          city: data['city'] ?? '',
          season: data['season'] is int ? data['season'] : (data['season'] is String ? int.tryParse(data['season']) ?? 2024 : 2024),
          additionalFields: additionalFields,
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
  final Map<String, dynamic> additionalFields;

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
    this.additionalFields = const {},
  });
}
