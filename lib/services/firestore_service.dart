import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_football_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiFootballService _apiFootballService = ApiFootballService();

  // Načíst všechny ligy (bez Champions League a Europa League)
  Future<List<League>> getLeagues() async {
    try {
      final snapshot = await _firestore.collection('leagues').get();
      
      return snapshot.docs
          .where((doc) {
            final id = doc.id.toLowerCase();
            final name = (doc['name'] ?? '').toString().toLowerCase();
            // Vyloučit Champions League a Europa League
            return !id.contains('champions') && 
                   !id.contains('europa') &&
                   !name.contains('champions league') &&
                   !name.contains('europa league');
          })
          .map((doc) {
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
      
      // Automaticky načíst a uložit týmy z této ligy
      await _saveTeamsFromStandings(standings, leagueId, apiLeagueId, season);
    } catch (e) {
      rethrow; // Znovu vyhodit chybu
    }
  }

  // Uložit týmy z tabulky do Firestore
  Future<void> _saveTeamsFromStandings(
    List<StandingTeam> standings,
    String leagueId,
    int apiLeagueId,
    int season,
  ) async {
    // Neukládat týmy z Champions League a Europa League
    final leagueIdLower = leagueId.toLowerCase();
    if (leagueIdLower.contains('champions') || leagueIdLower.contains('europa')) {
      return;
    }
    
    try {
      // Získat název ligy z API
      final teamsData = await _apiFootballService.getTeamsFromLeague(
        leagueId: apiLeagueId,
        season: season,
      );
      
      if (teamsData.isEmpty) {
        // Pokud se nepodařilo načíst z API, použít data z tabulky
        for (var standingTeam in standings) {
          final teamId = '${standingTeam.teamName}_$apiLeagueId'.toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll(RegExp(r'[^a-z0-9_]'), '');
          
          final existingDoc = await _firestore.collection('teams').doc(teamId).get();
          
          if (!existingDoc.exists) {
            await _firestore.collection('teams').doc(teamId).set({
              'name': standingTeam.teamName,
              'league': leagueId,
              'logo': standingTeam.teamLogo,
              'logoUrl': standingTeam.teamLogo,
              'country': '',
              'stadium': '',
              'stadiumCountry': '',
              'city': '',
              'season': season,
            }, SetOptions(merge: true));
          } else {
            await _firestore.collection('teams').doc(teamId).update({
              'logo': standingTeam.teamLogo,
              'logoUrl': standingTeam.teamLogo,
              'league': leagueId,
              'season': season,
            });
          }
        }
      } else {
        // Použít data z API (mají více informací včetně stadionu a města)
        for (var teamData in teamsData) {
          final teamId = '${teamData['name']}_$apiLeagueId'.toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll(RegExp(r'[^a-z0-9_]'), '');
          
          final existingDoc = await _firestore.collection('teams').doc(teamId).get();
          
          final teamMap = {
            'name': teamData['name'],
            'league': teamData['league'],
            'logo': teamData['logo'],
            'logoUrl': teamData['logo'],
            'country': teamData['country'] ?? '',
            'stadium': teamData['stadium'] ?? '',
            'city': teamData['city'] ?? '',
            'stadiumCountry': teamData['stadiumCountry'] ?? teamData['country'] ?? '',
            'season': season,
          };
          
          if (!existingDoc.exists) {
            await _firestore.collection('teams').doc(teamId).set(teamMap, SetOptions(merge: true));
          } else {
            await _firestore.collection('teams').doc(teamId).update(teamMap);
          }
        }
      }
    } catch (e) {
      // Nevyhodit chybu, protože tabulka se už uložila
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
      
      // Filtrovat zápasy - uložit pouze ty, které se skutečně hrají v tento den
      final filteredMatches = matches.where((match) {
        final matchDate = match.date;
        return matchDate.year == date.year &&
               matchDate.month == date.month &&
               matchDate.day == date.day;
      }).toList();
      
      // Použít set místo merge, aby se přepsaly všechny staré zápasy
      await _firestore.collection('fixtures').doc(docId).set({
        'date': dateStr,
        'timestamp': Timestamp.fromDate(date),
        'updated': FieldValue.serverTimestamp(),
        'matches': filteredMatches.map((match) => match.toMap()).toList(),
      });
      
      // Smazat staré zápasy (starší než 11 dní)
      await _deleteOldFixtures();
    } catch (e) {
      // Chyba při ukládání zápasů
    }
  }

  // Uložit detailní informace o zápase
  Future<void> saveMatchDetails(int fixtureId, MatchDetails details) async {
    try {
      await _firestore.collection('match_details').doc('fixture_$fixtureId').set({
        'fixtureId': fixtureId,
        'updated': FieldValue.serverTimestamp(),
        ...details.toMap(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Chyba při ukládání detailů zápasu
    }
  }

  // Načíst detailní informace o zápase
  Future<MatchDetails?> getMatchDetails(int fixtureId) async {
    try {
      final doc = await _firestore.collection('match_details').doc('fixture_$fixtureId').get();
      
      if (doc.exists && doc.data() != null) {
        return MatchDetails.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Načíst a uložit detailní informace o zápase z API
  Future<MatchDetails?> fetchAndSaveMatchDetails(int fixtureId) async {
    try {
      // Načíst z API
      final details = await _apiFootballService.getMatchDetails(fixtureId);
      
      if (details != null) {
        // Uložit do Firestore
        await saveMatchDetails(fixtureId, details);
      }
      
      return details;
    } catch (e) {
      return null;
    }
  }

  // Smazat zápasy starší než 11 dní
  Future<void> _deleteOldFixtures() async {
    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 11));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);
      
      // Načíst všechny dokumenty s timestampem starším než cutoffDate
      final snapshot = await _firestore
          .collection('fixtures')
          .where('timestamp', isLessThan: cutoffTimestamp)
          .get();
      
      // Smazat všechny staré dokumenty
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      // Chyba při mazání starých zápasů - ignorovat
    }
  }

  // Povolené ligy - pouze top 5 evropských lig
  static const Set<int> _allowedLeagueIds = {
    39,   // Premier League (Anglická)
    140,  // La Liga (Španělská)
    135,  // Serie A (Italská)
    78,   // Bundesliga (Německá)
    61,   // Ligue 1 (Francouzská)
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
        
        // Filtrovat pouze povolené ligy a zápasy, které se skutečně hrají v tento den
        return allMatches.where((match) {
          // Kontrola povolených lig
          if (!_allowedLeagueIds.contains(match.leagueId)) {
            return false;
          }
          
          // Kontrola skutečného data zápasu - musí odpovídat požadovanému datu
          final matchDate = match.date;
          return matchDate.year == date.year &&
                 matchDate.month == date.month &&
                 matchDate.day == date.day;
        }).toList();
      }
      return [];
    } catch (e) {
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
      
      // Smazat staré zápasy (starší než 11 dní)
      await _deleteOldFixtures();
    } catch (e) {
      // Chyba při automatické aktualizaci
    }
  }

  // Načíst a uložit týmy z top 5 lig do Firestore
  Future<void> fetchAndSaveTeamsFromTopLeagues({bool includePlayers = false}) async {
    try {
      // Top 5 lig: Premier League, La Liga, Serie A, Bundesliga, Ligue 1
      final leagues = [
        {'id': 39, 'name': 'Premier League', 'country': 'England'},
        {'id': 140, 'name': 'La Liga', 'country': 'Spain'},
        {'id': 135, 'name': 'Serie A', 'country': 'Italy'},
        {'id': 78, 'name': 'Bundesliga', 'country': 'Germany'},
        {'id': 61, 'name': 'Ligue 1', 'country': 'France'},
      ];
      
      final currentSeason = 2023; // Změňte na 2023 pokud máte free plán
      
      for (var league in leagues) {
        final teams = await _apiFootballService.getTeamsFromLeague(
          leagueId: league['id'] as int,
          season: currentSeason,
        );
        
        for (var teamData in teams) {
          // Vytvořit unikátní ID z názvu týmu a ligy
          final teamId = '${teamData['name']}_${league['id']}'.toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll(RegExp(r'[^a-z0-9_]'), '');
          
          // Zkontrolovat, jestli tým už existuje
          final existingDoc = await _firestore.collection('teams').doc(teamId).get();
          
          final apiTeamId = teamData['id'] ?? 0;
          
          if (!existingDoc.exists) {
            await _firestore.collection('teams').doc(teamId).set({
              'name': teamData['name'],
              'league': teamData['league'],
              'logo': teamData['logo'],
              'logoUrl': teamData['logo'],
              'country': teamData['country'] ?? '',
              'stadium': teamData['stadium'] ?? '',
              'stadiumCountry': teamData['stadiumCountry'] ?? teamData['country'] ?? '',
              'city': teamData['city'] ?? '',
              'season': currentSeason,
              'apiTeamId': apiTeamId, // Uložit API team ID
            }, SetOptions(merge: true));
          } else {
            // Aktualizovat existující tým - doplnit chybějící informace
            final updateData = <String, dynamic>{
              'logo': teamData['logo'],
              'logoUrl': teamData['logo'],
              'league': teamData['league'],
              'season': currentSeason,
              'apiTeamId': teamData['id'] ?? existingDoc.data()?['apiTeamId'] ?? 0,
            };
            
            // Doplnit chybějící informace, pokud nejsou vyplněné
            final existingData = existingDoc.data()!;
            if ((existingData['country'] ?? '').toString().isEmpty) {
              updateData['country'] = teamData['country'] ?? '';
            }
            if ((existingData['stadium'] ?? '').toString().isEmpty) {
              updateData['stadium'] = teamData['stadium'] ?? '';
            }
            if ((existingData['city'] ?? '').toString().isEmpty) {
              updateData['city'] = teamData['city'] ?? '';
            }
            if ((existingData['stadiumCountry'] ?? '').toString().isEmpty) {
              updateData['stadiumCountry'] = teamData['stadiumCountry'] ?? teamData['country'] ?? '';
            }
            
            await _firestore.collection('teams').doc(teamId).update(updateData);
          }
          
          // Pokud je zapnuto načítání hráčů, načíst hráče pro tento tým
          if (includePlayers && apiTeamId > 0) {
            try {
              await fetchAndSavePlayers(
                teamId: teamId,
                apiTeamId: apiTeamId,
                season: currentSeason,
              );
              // Počkat mezi týmy, aby se nepřekročil API limit
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              // Chyba při načítání hráčů - pokračovat s dalším týmem
            }
          }
        }
        
        // Počkat mezi ligami, aby se nepřekročil API limit
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Načíst a uložit hráče pro všechny týmy
  Future<void> fetchAndSavePlayersForAllTeams() async {
    try {
      // Načíst všechny týmy z Firestore
      final teams = await getTeams();
      final currentSeason = 2023;
      
      for (var team in teams) {
        if (team.apiTeamId > 0) {
          try {
            await fetchAndSavePlayers(
              teamId: team.id,
              apiTeamId: team.apiTeamId,
              season: team.season > 0 ? team.season : currentSeason,
            );
            
            // Počkat mezi týmy, aby se nepřekročil API limit
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            // Chyba při načítání hráčů - pokračovat s dalším týmem
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Načíst týmy z Firebase (pouze z top 5 evropských lig)
  Future<List<Team>> getTeams() async {
    try {
      // Blacklist - nejprve vyloučit Champions League a Europa League
      final excludedPatterns = [
        'champions',
        'europa',
        'uefa champions',
        'uefa europa',
        'european',
      ];
      
      // Whitelist povolených lig - ID lig i názvy (s mezerami i podtržítky)
      final allowedLeaguePatterns = [
        'premier_league',
        'premier league',
        'la_liga',
        'la liga',
        'serie_a',
        'serie a',
        'bundesliga',
        'ligue_1',
        'ligue 1',
      ];
      
      final snapshot = await _firestore.collection('teams').get();
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final league = (data['league'] ?? '').toString().toLowerCase().trim();
            
            // Nejdříve vyloučit Champions League a Europa League
            if (excludedPatterns.any((excluded) => league.contains(excluded))) {
              return false;
            }
            
            // Pak povolit pouze týmy z top 5 evropských lig
            return allowedLeaguePatterns.any((pattern) => league.contains(pattern));
          })
          .map((doc) {
            final data = doc.data();
            // Vytvořit mapu všech fields kromě základních
            final Map<String, dynamic> additionalFields = {};
            final knownFields = {'name', 'league', 'logo', 'logoUrl', 'country', 'stadium', 'stadiumCountry', 'city', 'season', 'apiTeamId'};
            
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
              season: data['season'] is int ? data['season'] : (data['season'] is String ? int.tryParse(data['season']) ?? 2023 : 2023),
              apiTeamId: data['apiTeamId'] is int ? data['apiTeamId'] : (data['apiTeamId'] is String ? int.tryParse(data['apiTeamId']) ?? 0 : 0),
              additionalFields: additionalFields,
            );
          }).toList();
    } catch (e) {
      return [];
    }
  }

  // Načíst a uložit hráče týmu
  Future<void> fetchAndSavePlayers({
    required String teamId,
    required int apiTeamId,
    required int season,
  }) async {
    if (apiTeamId == 0) {
      return;
    }

    try {
      // Načíst hráče z API
      final players = await _apiFootballService.getPlayersFromTeam(
        teamId: apiTeamId,
        season: season,
      );

      if (players.isEmpty) {
        return;
      }

      // Uložit do Firestore
      await _firestore.collection('teams').doc(teamId).collection('players').doc('squad_$season').set({
        'season': season,
        'updated': FieldValue.serverTimestamp(),
        'players': players,
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Načíst hráče týmu z Firestore
  Future<List<Player>> getPlayers({
    required String teamId,
    required int season,
  }) async {
    try {
      final doc = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('players')
          .doc('squad_$season')
          .get();

      if (!doc.exists || doc.data() == null) {
        return [];
      }

      final data = doc.data()!;
      final playersData = data['players'] as List?;

      if (playersData == null || playersData.isEmpty) {
        return [];
      }

      return playersData.map((playerData) {
        return Player(
          id: playerData['id'] ?? 0,
          name: playerData['name'] ?? '',
          number: playerData['number'] ?? 0,
          position: playerData['position'] ?? '',
          age: playerData['age'] ?? 0,
          nationality: playerData['nationality'] ?? '',
          photo: playerData['photo'] ?? '',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Aktualizovat názvy lig u všech týmů
  Future<int> updateLeagueNames() async {
    try {
      // Mapování starých názvů na nové
      final leagueNameMap = {
        'premier_league': 'Premier League',
        'la_liga': 'La Liga',
        'serie_a': 'Serie A',
        'ligue_1': 'Ligue 1',
        'bundesliga': 'Bundesliga',
      };

      // Načíst všechny týmy
      final snapshot = await _firestore.collection('teams').get();
      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final currentLeague = (data['league'] ?? '').toString().trim();
        
        // Zkontrolovat, jestli potřebuje aktualizaci
        String? newLeagueName;
        
        // Zkontrolovat přesné shody (case-insensitive)
        final currentLeagueLower = currentLeague.toLowerCase();
        for (var entry in leagueNameMap.entries) {
          if (currentLeagueLower == entry.key.toLowerCase() || 
              currentLeagueLower.contains(entry.key.toLowerCase())) {
            newLeagueName = entry.value;
            break;
          }
        }

        // Pokud našel nový název, aktualizovat
        if (newLeagueName != null && currentLeague != newLeagueName) {
          await _firestore.collection('teams').doc(doc.id).update({
            'league': newLeagueName,
          });
          updatedCount++;
        }
      }

      return updatedCount;
    } catch (e) {
      rethrow;
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
  final int apiTeamId;
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
    this.apiTeamId = 0,
    this.additionalFields = const {},
  });
}

// Model pro hráče
class Player {
  final int id;
  final String name;
  final int number;
  final String position;
  final int age;
  final String nationality;
  final String photo;

  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.age,
    required this.nationality,
    required this.photo,
  });
}
