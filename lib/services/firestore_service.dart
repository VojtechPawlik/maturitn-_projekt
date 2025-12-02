import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_football_service.dart';
import 'news_api_service.dart';
import '../models/betting_models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiFootballService _apiFootballService = ApiFootballService();
  final NewsApiService _newsApiService = NewsApiService();

  // ---------------------------
  // NOVINKY (NEWS)
  // ---------------------------

  /// Načíst novinky z kolekce `news` (jednorázově)
  Future<List<News>> getNews({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return News(
          id: doc.id,
          title: (data['title'] ?? '').toString(),
          content: (data['content'] ?? '').toString(),
          imageUrl: (data['imageUrl'] ?? '').toString(),
          source: (data['source'] ?? '').toString(),
          url: (data['url'] ?? '').toString(),
          publishedAt: (data['publishedAt'] is Timestamp)
              ? (data['publishedAt'] as Timestamp).toDate()
              : DateTime.tryParse((data['publishedAt'] ?? '').toString()),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Real‑time stream novinek z kolekce `news`
  Stream<List<News>> getNewsStream({int limit = 20}) {
    return _firestore
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return News(
          id: doc.id,
          title: (data['title'] ?? '').toString(),
          content: (data['content'] ?? '').toString(),
          imageUrl: (data['imageUrl'] ?? '').toString(),
          source: (data['source'] ?? '').toString(),
          url: (data['url'] ?? '').toString(),
          publishedAt: (data['publishedAt'] is Timestamp)
              ? (data['publishedAt'] as Timestamp).toDate()
              : DateTime.tryParse((data['publishedAt'] ?? '').toString()),
        );
      }).toList();
    });
  }

  /// Uložit / aktualizovat novinky do kolekce `news`.
  /// Očekává se, že News.id je unikátní (např. hash URL nebo ID z API).
  Future<void> saveNews(List<News> news) async {
    if (news.isEmpty) return;
    final batch = _firestore.batch();

    for (final item in news) {
      final docRef = _firestore.collection('news').doc(item.id);
      batch.set(docRef, {
        'title': item.title,
        'content': item.content,
        'imageUrl': item.imageUrl,
        'source': item.source,
        'url': item.url,
        'publishedAt': item.publishedAt != null
            ? Timestamp.fromDate(item.publishedAt!)
            : FieldValue.serverTimestamp(),
        'updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Načíst novinky z externího API a uložit je do Firestore.
  /// Můžeš volat např. z AutoUpdateService nebo při startu aplikace.
  Future<void> fetchAndSaveNewsFromApi() async {
    try {
      final latest = await _newsApiService.fetchLatestNews();
      if (latest.isNotEmpty) {
        await saveNews(latest);
      }
    } catch (e) {
      // Ignorovat chybu, aplikace poběží dál pouze s existujícími daty
    }
  }

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


  // ---------------------------
  // SÁZENÍ (BETTING)
  // ---------------------------

  // Uložit kurzy k zápasu
  Future<void> saveMatchOdds(int matchId, MatchOdds odds) async {
    try {
      await _firestore.collection('match_odds').doc('match_$matchId').set(
        odds.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      // Chyba při ukládání kurzů
    }
  }

  // Načíst kurzy k zápasu
  Future<MatchOdds?> getMatchOdds(int matchId) async {
    try {
      final doc = await _firestore.collection('match_odds').doc('match_$matchId').get();
      
      if (doc.exists && doc.data() != null) {
        return MatchOdds.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Uložit sázku
  Future<void> saveBet(Bet bet) async {
    try {
      await _firestore.collection('bets').doc(bet.id).set(bet.toMap());
    } catch (e) {
      // Chyba při ukládání sázky
    }
  }

  // Načíst sázky uživatele
  Future<List<Bet>> getUserBets(String userEmail) async {
    try {
      // Zkusit s orderBy, pokud selže, použít bez orderBy
      try {
        final snapshot = await _firestore
            .collection('bets')
            .where('userEmail', isEqualTo: userEmail)
            .orderBy('placedAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Ujistit se, že máme všechna potřebná data
          if (data['userEmail'] == userEmail) {
            return Bet.fromMap(data);
          }
          return null;
        }).whereType<Bet>().toList();
      } catch (e) {
        // Pokud selže orderBy (kvůli chybějícímu indexu), načíst bez orderBy a seřadit lokálně
        final snapshot = await _firestore
            .collection('bets')
            .where('userEmail', isEqualTo: userEmail)
            .get();

        final bets = snapshot.docs.map((doc) {
          final data = doc.data();
          if (data['userEmail'] == userEmail) {
            return Bet.fromMap(data);
          }
          return null;
        }).whereType<Bet>().toList();
        
        // Seřadit lokálně podle data
        bets.sort((a, b) => b.placedAt.compareTo(a.placedAt));
        return bets;
      }
    } catch (e) {
      // Chyba při načítání sázek
      return [];
    }
  }

  // Načíst sázky k zápasu
  Future<List<Bet>> getMatchBets(int matchId) async {
    try {
      final snapshot = await _firestore
          .collection('bets')
          .where('matchId', isEqualTo: matchId)
          .get();

      return snapshot.docs.map((doc) => Bet.fromMap(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------
  // PŘÁTELÉ (FRIENDS)
  // ---------------------------

  // Přidat kamaráda
  Future<bool> addFriend(String userEmail, String friendEmail) async {
    try {
      // Zkontrolovat, zda už nejsou přátelé
      final currentFriends = await getUserFriends(userEmail);
      if (currentFriends.contains(friendEmail)) {
        return false; // Už jsou přátelé
      }

      // Přidat do seznamu přátel uživatele
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('friends')
          .doc(friendEmail)
          .set({
        'email': friendEmail,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Přidat opačným směrem (oboustranné přátelství)
      await _firestore
          .collection('users')
          .doc(friendEmail)
          .collection('friends')
          .doc(userEmail)
          .set({
        'email': userEmail,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Načíst seznam přátel uživatele
  Future<List<String>> getUserFriends(String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('friends')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // Odebrat kamaráda
  Future<bool> removeFriend(String userEmail, String friendEmail) async {
    try {
      // Odebrat z seznamu přátel uživatele
      await _firestore
          .collection('users')
          .doc(userEmail)
          .collection('friends')
          .doc(friendEmail)
          .delete();

      // Odebrat opačným směrem (oboustranné přátelství)
      await _firestore
          .collection('users')
          .doc(friendEmail)
          .collection('friends')
          .doc(userEmail)
          .delete();

      return true;
    } catch (e) {
      return false;
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
        
        // Filtrovat pouze zápasy, které se skutečně hrají v tento den
        // (ligu už neomezujeme – ve Firestore můžeš mít, co chceš a vše se zobrazí)
        return allMatches.where((match) {
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
  
  // Aktualizovat informace o městě, zemi a stadionu pro všechny týmy
  Future<void> updateTeamLocationInfo() async {
    try {
      // Data pro všechny týmy z top 5 lig
      final teamDataMap = {
        // Premier League (England)
        'arsenal': {'city': 'London', 'country': 'England', 'stadium': 'Emirates Stadium'},
        'aston villa': {'city': 'Birmingham', 'country': 'England', 'stadium': 'Villa Park'},
        'bournemouth': {'city': 'Bournemouth', 'country': 'England', 'stadium': 'Vitality Stadium'},
        'brentford': {'city': 'London', 'country': 'England', 'stadium': 'Gtech Community Stadium'},
        'brighton & hove albion': {'city': 'Brighton', 'country': 'England', 'stadium': 'American Express Community Stadium'},
        'burnley': {'city': 'Burnley', 'country': 'England', 'stadium': 'Turf Moor'},
        'chelsea': {'city': 'London', 'country': 'England', 'stadium': 'Stamford Bridge'},
        'crystal palace': {'city': 'London', 'country': 'England', 'stadium': 'Selhurst Park'},
        'everton': {'city': 'Liverpool', 'country': 'England', 'stadium': 'Goodison Park'},
        'fulham': {'city': 'London', 'country': 'England', 'stadium': 'Craven Cottage'},
        'liverpool': {'city': 'Liverpool', 'country': 'England', 'stadium': 'Anfield'},
        'luton town': {'city': 'Luton', 'country': 'England', 'stadium': 'Kenilworth Road'},
        'manchester city': {'city': 'Manchester', 'country': 'England', 'stadium': 'Etihad Stadium'},
        'manchester united': {'city': 'Manchester', 'country': 'England', 'stadium': 'Old Trafford'},
        'newcastle united': {'city': 'Newcastle upon Tyne', 'country': 'England', 'stadium': 'St. James\' Park'},
        'nottingham forest': {'city': 'Nottingham', 'country': 'England', 'stadium': 'City Ground'},
        'sheffield united': {'city': 'Sheffield', 'country': 'England', 'stadium': 'Bramall Lane'},
        'tottenham hotspur': {'city': 'London', 'country': 'England', 'stadium': 'Tottenham Hotspur Stadium'},
        'west ham united': {'city': 'London', 'country': 'England', 'stadium': 'London Stadium'},
        'wolverhampton wanderers': {'city': 'Wolverhampton', 'country': 'England', 'stadium': 'Molineux Stadium'},
        
        // La Liga (Spain)
        'alavés': {'city': 'Vitoria-Gasteiz', 'country': 'Spain', 'stadium': 'Mendizorroza'},
        'almería': {'city': 'Almería', 'country': 'Spain', 'stadium': 'Power Horse Stadium'},
        'athletic club': {'city': 'Bilbao', 'country': 'Spain', 'stadium': 'San Mamés'},
        'atlético madrid': {'city': 'Madrid', 'country': 'Spain', 'stadium': 'Cívitas Metropolitano'},
        'barcelona': {'city': 'Barcelona', 'country': 'Spain', 'stadium': 'Estadi Olímpic Lluís Companys'},
        'cádiz': {'city': 'Cádiz', 'country': 'Spain', 'stadium': 'Nuevo Mirandilla'},
        'celta vigo': {'city': 'Vigo', 'country': 'Spain', 'stadium': 'Balaídos'},
        'getafe': {'city': 'Getafe (Madrid area)', 'country': 'Spain', 'stadium': 'Coliseum'},
        'girona': {'city': 'Girona', 'country': 'Spain', 'stadium': 'Montilivi'},
        'granada': {'city': 'Granada', 'country': 'Spain', 'stadium': 'Nuevo Los Cármenes'},
        'las palmas': {'city': 'Las Palmas', 'country': 'Spain', 'stadium': 'Estadio Gran Canaria'},
        'mallorca': {'city': 'Palma de Mallorca', 'country': 'Spain', 'stadium': 'Estadi Mallorca Son Moix'},
        'osasuna': {'city': 'Pamplona', 'country': 'Spain', 'stadium': 'El Sadar'},
        'rayo vallecano': {'city': 'Madrid', 'country': 'Spain', 'stadium': 'Vallecas Stadium'},
        'real betis': {'city': 'Seville', 'country': 'Spain', 'stadium': 'Estadio Benito Villamarín'},
        'real madrid': {'city': 'Madrid', 'country': 'Spain', 'stadium': 'Santiago Bernabéu'},
        'real sociedad': {'city': 'San Sebastián', 'country': 'Spain', 'stadium': 'Reale Arena'},
        'sevilla': {'city': 'Seville', 'country': 'Spain', 'stadium': 'Ramón Sánchez-Pizjuán'},
        'valencia': {'city': 'Valencia', 'country': 'Spain', 'stadium': 'Mestalla'},
        'villarreal': {'city': 'Villarreal', 'country': 'Spain', 'stadium': 'Estadio de la Cerámica'},
        
        // Bundesliga (Germany)
        'fc augsburg': {'city': 'Augsburg', 'country': 'Germany', 'stadium': 'WWK Arena'},
        'union berlin': {'city': 'Berlin', 'country': 'Germany', 'stadium': 'Stadion An der Alten Försterei'},
        'vfl bochum': {'city': 'Bochum', 'country': 'Germany', 'stadium': 'Vonovia Ruhrstadion'},
        'werder bremen': {'city': 'Bremen', 'country': 'Germany', 'stadium': 'Weserstadion'},
        'darmstadt 98': {'city': 'Darmstadt', 'country': 'Germany', 'stadium': 'Stadion am Böllenfalltor'},
        'borussia dortmund': {'city': 'Dortmund', 'country': 'Germany', 'stadium': 'Signal Iduna Park'},
        'eintracht frankfurt': {'city': 'Frankfurt', 'country': 'Germany', 'stadium': 'Deutsche Bank Park'},
        'sc freiburg': {'city': 'Freiburg', 'country': 'Germany', 'stadium': 'Europa-Park Stadion'},
        'heidenheim': {'city': 'Heidenheim', 'country': 'Germany', 'stadium': 'Voith-Arena'},
        'hoffenheim': {'city': 'Sinsheim', 'country': 'Germany', 'stadium': 'PreZero Arena'},
        'fc köln': {'city': 'Cologne', 'country': 'Germany', 'stadium': 'RheinEnergieStadion'},
        'rb leipzig': {'city': 'Leipzig', 'country': 'Germany', 'stadium': 'Red Bull Arena'},
        'bayer leverkusen': {'city': 'Leverkusen', 'country': 'Germany', 'stadium': 'BayArena'},
        'mainz 05': {'city': 'Mainz', 'country': 'Germany', 'stadium': 'Mewa Arena'},
        'borussia mönchengladbach': {'city': 'Mönchengladbach', 'country': 'Germany', 'stadium': 'Borussia-Park'},
        'bayern munich': {'city': 'Munich', 'country': 'Germany', 'stadium': 'Allianz Arena'},
        'vfb stuttgart': {'city': 'Stuttgart', 'country': 'Germany', 'stadium': 'MHPArena'},
        'vfl wolfsburg': {'city': 'Wolfsburg', 'country': 'Germany', 'stadium': 'Volkswagen Arena'},
        
        // Serie A (Italy)
        'atalanta': {'city': 'Bergamo', 'country': 'Italy', 'stadium': 'Gewiss Stadium'},
        'bologna': {'city': 'Bologna', 'country': 'Italy', 'stadium': 'Stadio Renato Dall\'Ara'},
        'cagliari': {'city': 'Cagliari', 'country': 'Italy', 'stadium': 'Unipol Domus'},
        'empoli': {'city': 'Empoli', 'country': 'Italy', 'stadium': 'Stadio Carlo Castellani'},
        'fiorentina': {'city': 'Florence', 'country': 'Italy', 'stadium': 'Stadio Artemio Franchi'},
        'frosinone': {'city': 'Frosinone', 'country': 'Italy', 'stadium': 'Stadio Benito Stirpe'},
        'genoa': {'city': 'Genoa', 'country': 'Italy', 'stadium': 'Stadio Luigi Ferraris'},
        'hellas verona': {'city': 'Verona', 'country': 'Italy', 'stadium': 'Stadio Marcantonio Bentegodi'},
        'inter milan': {'city': 'Milan', 'country': 'Italy', 'stadium': 'San Siro'},
        'juventus': {'city': 'Turin', 'country': 'Italy', 'stadium': 'Allianz Stadium'},
        'lazio': {'city': 'Rome', 'country': 'Italy', 'stadium': 'Stadio Olimpico'},
        'lecce': {'city': 'Lecce', 'country': 'Italy', 'stadium': 'Stadio Via del Mare'},
        'ac milan': {'city': 'Milan', 'country': 'Italy', 'stadium': 'San Siro'},
        'monza': {'city': 'Monza', 'country': 'Italy', 'stadium': 'U-Power Stadium (Stadio Brianteo)'},
        'napoli': {'city': 'Naples', 'country': 'Italy', 'stadium': 'Stadio Diego Armando Maradona'},
        'roma': {'city': 'Rome', 'country': 'Italy', 'stadium': 'Stadio Olimpico'},
        'salernitana': {'city': 'Salerno', 'country': 'Italy', 'stadium': 'Stadio Arechi'},
        'sassuolo': {'city': 'Reggio Emilia', 'country': 'Italy', 'stadium': 'Mapei Stadium'},
        'torino': {'city': 'Turin', 'country': 'Italy', 'stadium': 'Stadio Olimpico Grande Torino'},
        'udinese': {'city': 'Udine', 'country': 'Italy', 'stadium': 'Stadio Friuli'},
        
        // Ligue 1 (France)
        'brest': {'city': 'Brest', 'country': 'France', 'stadium': 'Stade Francis-Le Blé'},
        'clermont foot': {'city': 'Clermont-Ferrand', 'country': 'France', 'stadium': 'Stade Gabriel Montpied'},
        'le havre': {'city': 'Le Havre', 'country': 'France', 'stadium': 'Stade Océane'},
        'lens': {'city': 'Lens', 'country': 'France', 'stadium': 'Stade Bollaert-Delelis'},
        'lille': {'city': 'Villeneuve-d\'Ascq', 'country': 'France', 'stadium': 'Stade Pierre-Mauroy'},
        'lorient': {'city': 'Lorient', 'country': 'France', 'stadium': 'Stade du Moustoir'},
        'lyon': {'city': 'Lyon', 'country': 'France', 'stadium': 'Groupama Stadium'},
        'marseille': {'city': 'Marseille', 'country': 'France', 'stadium': 'Orange Vélodrome'},
        'monaco': {'city': 'Monaco', 'country': 'Monaco', 'stadium': 'Stade Louis II'},
        'montpellier': {'city': 'Montpellier', 'country': 'France', 'stadium': 'Stade de la Mosson'},
        'nantes': {'city': 'Nantes', 'country': 'France', 'stadium': 'Stade de la Beaujoire'},
        'nice': {'city': 'Nice', 'country': 'France', 'stadium': 'Allianz Riviera'},
        'paris saint-germain': {'city': 'Paris', 'country': 'France', 'stadium': 'Parc des Princes'},
        'reims': {'city': 'Reims', 'country': 'France', 'stadium': 'Stade Auguste-Delaune'},
        'rennes': {'city': 'Rennes', 'country': 'France', 'stadium': 'Roazhon Park'},
        'strasbourg': {'city': 'Strasbourg', 'country': 'France', 'stadium': 'Stade de la Meinau'},
        'toulouse': {'city': 'Toulouse', 'country': 'France', 'stadium': 'Stadium Municipal'},
      };
      
      // Načíst všechny týmy z Firestore
      final teams = await getTeams();
      
      for (var team in teams) {
        // Normalizovat název týmu pro vyhledávání (lowercase, odstranit diakritiku)
        final teamNameNormalized = team.name.toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ñ', 'n')
            .replaceAll('ü', 'u')
            .replaceAll('ö', 'o')
            .replaceAll('ä', 'a')
            .replaceAll('ß', 'ss')
            .replaceAll('ç', 'c')
            .replaceAll('à', 'a')
            .replaceAll('è', 'e')
            .replaceAll('ì', 'i')
            .replaceAll('ò', 'o')
            .replaceAll('ù', 'u');
        
        // Najít odpovídající data
        Map<String, String>? teamInfo;
        
        // Zkusit najít přesný match
        if (teamDataMap.containsKey(teamNameNormalized)) {
          teamInfo = teamDataMap[teamNameNormalized];
        } else {
          // Zkusit najít částečný match
          for (var entry in teamDataMap.entries) {
            if (teamNameNormalized.contains(entry.key) || entry.key.contains(teamNameNormalized)) {
              teamInfo = entry.value;
              break;
            }
          }
        }
        
        if (teamInfo != null) {
          // Aktualizovat tým v Firestore
          await _firestore.collection('teams').doc(team.id).update({
            'city': teamInfo['city'] ?? '',
            'country': teamInfo['country'] ?? '',
            'stadium': teamInfo['stadium'] ?? '',
            'stadiumCountry': teamInfo['country'] ?? '',
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Načíst a uložit hráče pro všechny týmy
  Future<void> fetchAndSavePlayersForAllTeams({bool includeProfiles = false}) async {
    try {
      // Nejdříve zajistit, že všechny týmy mají apiTeamId
      await _ensureAllTeamsHaveApiId();
      
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
              includeProfiles: includeProfiles,
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

  // Načíst a uložit profily hráčů pro všechny týmy
  Future<void> fetchAndSavePlayerProfilesForAllTeams() async {
    try {
      // Načíst všechny týmy z Firestore
      final teams = await getTeams();
      final currentSeason = 2023;
      
      for (var team in teams) {
        try {
          await fetchAndSavePlayerProfiles(
            teamId: team.id,
            season: team.season > 0 ? team.season : currentSeason,
          );
          
          // Počkat mezi týmy, aby se nepřekročil API limit
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          // Chyba při načítání profilů - pokračovat s dalším týmem
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Zajistit, že všechny týmy mají apiTeamId (veřejná metoda pro použití z UI)
  Future<void> ensureAllTeamsHaveApiId() async {
    try {
      await _ensureAllTeamsHaveApiId();
    } catch (e) {
      rethrow; // Znovu vyhodit chybu, aby se zobrazila uživateli
    }
  }

  // Pomocná metoda: extrahovat API ID z loga URL a uložit do Firestore (bez API volání)
  Future<int> updateApiTeamIdFromLogoUrls() async {
    try {
      final teams = await getTeams();
      int updatedCount = 0;
      
      for (var team in teams) {
        if (team.apiTeamId > 0) continue; // Už má apiTeamId
        
        if (team.logoUrl.isNotEmpty) {
          final logoMatch = RegExp(r'/teams/(\d+)\.png').firstMatch(team.logoUrl);
          if (logoMatch != null) {
            final apiId = int.tryParse(logoMatch.group(1)!);
            if (apiId != null && apiId > 0) {
              await _firestore.collection('teams').doc(team.id).update({
                'apiTeamId': apiId,
              });
              updatedCount++;
            }
          }
        }
      }
      
      return updatedCount;
    } catch (e) {
      rethrow;
    }
  }

  // Zajistit, že všechny týmy mají apiTeamId
  Future<void> _ensureAllTeamsHaveApiId() async {
    // Inicializovat API klíč
    await _apiFootballService.initializeApiKey();
    
    final teams = await getTeams();
    
    if (teams.isEmpty) {
      throw Exception('V Firestore nejsou žádné týmy. Nejdříve načtěte tabulky lig.');
    }
    
    // Mapování lig - ID ligy v Firestore -> API ID ligy
    final leagueMap = [
      {'firestoreId': 'premier_league', 'apiId': 39, 'name': 'Premier League'},
      {'firestoreId': 'la_liga', 'apiId': 140, 'name': 'La Liga'},
      {'firestoreId': 'serie_a', 'apiId': 135, 'name': 'Serie A'},
      {'firestoreId': 'bundesliga', 'apiId': 78, 'name': 'Bundesliga'},
      {'firestoreId': 'ligue_1', 'apiId': 61, 'name': 'Ligue 1'},
    ];
    
    final currentSeason = 2023;
    final teamsWithoutApiId = teams.where((team) => team.apiTeamId == 0).toList();
    
    if (teamsWithoutApiId.isEmpty) {
      return; // Všechny týmy už mají apiTeamId
    }
    
    int updatedCount = 0;
    List<String> errors = [];
    List<String> debugInfo = [];
    
    // Debug: zobrazit názvy lig týmů bez API ID
    final uniqueLeagues = teamsWithoutApiId.map((t) => t.league).toSet().toList();
    debugInfo.add('Týmy bez API ID: ${teamsWithoutApiId.length}');
    debugInfo.add('Ligy: ${uniqueLeagues.join(", ")}');
    
    // Pro každou ligu načíst týmy z API a doplnit chybějící apiTeamId
    for (var league in leagueMap) {
      try {
        final apiTeams = await _apiFootballService.getTeamsFromLeague(
          leagueId: league['apiId'] as int,
          season: currentSeason,
        );
        
        if (apiTeams.isEmpty) {
          errors.add('Žádné týmy z API pro ligu ${league['name']}');
          continue;
        }
        
        debugInfo.add('Liga ${league['name']}: načteno ${apiTeams.length} týmů z API');
        
        int leagueUpdatedCount = 0;
        
        // Pro každý tým z Firestore najít odpovídající tým z API
        for (var firestoreTeam in teamsWithoutApiId) {
          final teamLeague = firestoreTeam.league.toLowerCase().trim();
          final leagueFirestoreId = league['firestoreId'] as String;
          final leagueName = league['name'] as String;
          
          // Zkontrolovat, jestli tým patří do této ligy
          bool belongsToLeague = teamLeague.contains(leagueFirestoreId) || 
                                 teamLeague.contains(leagueName.toLowerCase()) ||
                                 teamLeague == leagueFirestoreId ||
                                 teamLeague == leagueName.toLowerCase();
          
            if (belongsToLeague) {
            // Zkusit extrahovat API ID z loga URL (pokud existuje)
            int? apiIdFromLogo;
            if (firestoreTeam.logoUrl.isNotEmpty) {
              final logoMatch = RegExp(r'/teams/(\d+)\.png').firstMatch(firestoreTeam.logoUrl);
              if (logoMatch != null) {
                apiIdFromLogo = int.tryParse(logoMatch.group(1)!);
              }
            }
            
            // Pokud máme API ID z loga, zkontrolovat, jestli existuje v API
            if (apiIdFromLogo != null) {
              final teamFromLogo = apiTeams.firstWhere(
                (apiTeam) => (apiTeam['id'] ?? 0) == apiIdFromLogo,
                orElse: () => <String, dynamic>{},
              );
              
              if (teamFromLogo.isNotEmpty) {
                // Aktualizovat apiTeamId v Firestore
                await _firestore.collection('teams').doc(firestoreTeam.id).update({
                  'apiTeamId': apiIdFromLogo,
                });
                updatedCount++;
                leagueUpdatedCount++;
                continue; // Přeskočit hledání podle názvu
              }
            }
            
            // Najít tým v API podle názvu
            final matchingApiTeam = apiTeams.firstWhere(
              (apiTeam) {
                final apiName = (apiTeam['name'] ?? '').toString().toLowerCase().trim();
                final firestoreName = firestoreTeam.name.toLowerCase().trim();
                // Přesná shoda nebo obsahuje
                return apiName == firestoreName || 
                       apiName.contains(firestoreName) || 
                       firestoreName.contains(apiName);
              },
              orElse: () => <String, dynamic>{},
            );
            
            if (matchingApiTeam.isNotEmpty && matchingApiTeam['id'] != null) {
              // Aktualizovat apiTeamId v Firestore
              await _firestore.collection('teams').doc(firestoreTeam.id).update({
                'apiTeamId': matchingApiTeam['id'],
              });
              updatedCount++;
              leagueUpdatedCount++;
            } else {
              debugInfo.add('Tým "${firestoreTeam.name}" (liga: ${firestoreTeam.league}) nebyl nalezen v API pro ${league['name']}');
              if (apiIdFromLogo != null) {
                debugInfo.add('  (API ID z loga: $apiIdFromLogo, ale tým nebyl nalezen v seznamu z API)');
              }
            }
          }
        }
        
        if (leagueUpdatedCount > 0) {
          debugInfo.add('Liga ${league['name']}: aktualizováno $leagueUpdatedCount týmů');
        }
        
        // Počkat mezi ligami
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        errors.add('Chyba při načítání ligy ${league['name']}: ${e.toString()}');
        // Pokračovat s další ligou
      }
    }
    
    // Pokud se nepodařilo aktualizovat žádný tým, vyhodit chybu s detaily
    if (updatedCount == 0 && teamsWithoutApiId.isNotEmpty) {
      final errorMessage = StringBuffer();
      errorMessage.writeln('Nepodařilo se doplnit API ID pro žádný tým.\n');
      errorMessage.writeln('Debug informace:');
      errorMessage.writeln(debugInfo.join('\n'));
      if (errors.isNotEmpty) {
        errorMessage.writeln('\nChyby:');
        errorMessage.writeln(errors.join('\n'));
      }
      errorMessage.writeln('\n\nMožné příčiny:');
      errorMessage.writeln('1. Názvy týmů v Firestore se neshodují s názvy v API');
      errorMessage.writeln('2. Názvy lig v Firestore se neshodují (očekáváno: premier_league, la_liga, atd.)');
      errorMessage.writeln('3. Týmy nejsou z podporovaných lig');
      
      throw Exception(errorMessage.toString());
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
    bool includeProfiles = false,
  }) async {
    if (apiTeamId == 0) {
      throw Exception('Tým nemá platné API ID');
    }

    try {
      // Načíst hráče z API
      final players = await _apiFootballService.getPlayersFromTeam(
        teamId: apiTeamId,
        season: season,
      );

      if (players.isEmpty) {
        throw Exception('Žádní hráči nebyli nalezeni pro tento tým');
      }

      // Pokud jsou požadovány profily, načíst je pro každého hráče
      if (includeProfiles) {
        for (var player in players) {
          final playerId = player['id'] ?? 0;
          if (playerId > 0) {
            try {
              final profile = await _apiFootballService.getPlayerProfile(
                playerId: playerId,
              );
              if (profile != null) {
                player['profile'] = profile;
              }
              // Počkat mezi požadavky, aby se nepřekročil API limit
              await Future.delayed(const Duration(milliseconds: 300));
            } catch (e) {
              // Chyba při načítání profilu - pokračovat s dalším hráčem
            }
          }
        }
      }

      // Uložit do nové kolekce players
      final batch = _firestore.batch();
      
      for (var player in players) {
        final playerId = player['id'] ?? 0;
        if (playerId > 0) {
          // Vytvořit unikátní ID: teamId_playerId_season
          final docId = '${teamId}_${playerId}_$season';
          final playerRef = _firestore.collection('players').doc(docId);
          
          batch.set(playerRef, {
            'id': playerId,
            'teamId': teamId,
            'apiTeamId': apiTeamId,
            'season': season,
            'name': player['name'] ?? '',
            'number': player['number'] ?? 0,
            'position': player['position'] ?? '',
            'age': player['age'] ?? 0,
            'nationality': player['nationality'] ?? '',
            'photo': player['photo'] ?? '',
            'updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      
      await batch.commit();
      
      // Také uložit do staré struktury pro kompatibilitu
      await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('players')
          .doc('squad_$season')
          .set({
        'season': season,
        'teamId': teamId,
        'apiTeamId': apiTeamId,
        'updated': FieldValue.serverTimestamp(),
        'players': players,
        'playerCount': players.length,
      }, SetOptions(merge: false));
    } catch (e) {
      rethrow;
    }
  }

  // Načíst a uložit profily hráčů pro tým
  Future<void> fetchAndSavePlayerProfiles({
    required String teamId,
    required int season,
  }) async {
    try {
      // Načíst hráče z Firestore
      final players = await getPlayers(
        teamId: teamId,
        season: season,
      );

      if (players.isEmpty) {
        throw Exception('Žádní hráči nebyli nalezeni pro tento tým');
      }

      // Pro každého hráče načíst profil
      for (var player in players) {
        if (player.id > 0) {
          try {
            final profile = await _apiFootballService.getPlayerProfile(
              playerId: player.id,
            );
            
            if (profile != null) {
              // Uložit profil do nové struktury (do dokumentu hráče)
              final playerDocId = '${teamId}_${player.id}_$season';
              await _firestore
                  .collection('players')
                  .doc(playerDocId)
                  .update({
                'statistics': profile['statistics'] ?? [],
                'height': profile['height'] ?? '',
                'weight': profile['weight'] ?? '',
                'birth': profile['birth'] ?? {},
                'updated': FieldValue.serverTimestamp(),
              });
              
              // Také uložit do staré struktury pro kompatibilitu
              await _firestore
                  .collection('teams')
                  .doc(teamId)
                  .collection('players')
                  .doc('squad_$season')
                  .collection('profiles')
                  .doc('player_${player.id}')
                  .set({
                'playerId': player.id,
                'updated': FieldValue.serverTimestamp(),
                ...profile,
              }, SetOptions(merge: true));
            }
            
            // Počkat mezi požadavky, aby se nepřekročil API limit
            await Future.delayed(const Duration(milliseconds: 300));
          } catch (e) {
            // Chyba při načítání profilu - pokračovat s dalším hráčem
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Načíst profil hráče z Firestore
  Future<Map<String, dynamic>?> getPlayerProfile({
    required String teamId,
    required int playerId,
    required int season,
  }) async {
    try {
      // Nejdříve zkusit načíst z nové struktury (v dokumentu hráče)
      final playerDocId = '${teamId}_${playerId}_$season';
      final playerDoc = await _firestore
          .collection('players')
          .doc(playerDocId)
          .get();

      if (playerDoc.exists && playerDoc.data() != null) {
        final data = playerDoc.data()!;
        // Pokud má hráč profil přímo v dokumentu
        if (data.containsKey('statistics') || data.containsKey('profile')) {
          return data;
        }
      }

      // Pokud není v nové struktuře, zkusit ze staré struktury
      final doc = await _firestore
          .collection('teams')
          .doc(teamId)
          .collection('players')
          .doc('squad_$season')
          .collection('profiles')
          .doc('player_$playerId')
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Načíst hráče týmu z Firestore
  Future<List<Player>> getPlayers({
    required String teamId,
    required int season,
  }) async {
    try {
      // Nejdříve zkusit načíst z nové kolekce players
      final snapshot = await _firestore
          .collection('players')
          .where('teamId', isEqualTo: teamId)
          .where('season', isEqualTo: season)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Player(
            id: _parseIntFromMap(data['id']) ?? 0,
            name: data['name']?.toString() ?? '',
            number: _parseIntFromMap(data['number']) ?? 0,
            position: data['position']?.toString() ?? '',
            age: _parseIntFromMap(data['age']) ?? 0,
            nationality: data['nationality']?.toString() ?? '',
            photo: data['photo']?.toString() ?? '',
          );
        }).toList();
      }

      // Pokud nejsou v nové kolekci, zkusit načíst ze staré struktury
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
      final playersData = data['players'];

      if (playersData == null || !(playersData is List) || playersData.isEmpty) {
        return [];
      }

      return playersData.map((playerData) {
        // Zkontrolovat, jestli je playerData Map
        if (playerData is! Map) {
          return null;
        }
        
        return Player(
          id: _parseIntFromMap(playerData['id']) ?? 0,
          name: playerData['name']?.toString() ?? '',
          number: _parseIntFromMap(playerData['number']) ?? 0,
          position: playerData['position']?.toString() ?? '',
          age: _parseIntFromMap(playerData['age']) ?? 0,
          nationality: playerData['nationality']?.toString() ?? '',
          photo: playerData['photo']?.toString() ?? '',
        );
      }).whereType<Player>().toList();
    } catch (e) {
      return [];
    }
  }

  // Pomocná metoda pro parsování int z různých typů
  int? _parseIntFromMap(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
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

class News {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String source;
  final String url;
  final DateTime? publishedAt;

  News({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.source,
    required this.url,
    this.publishedAt,
  });
}

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
