import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session_manager.dart';
import '../services/firestore_service.dart';
import '../services/api_football_service.dart';
import '../services/auto_update_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'teams_screen.dart';
import 'settings_screen.dart';
import 'standings_screen.dart';
import 'team_detail_screen.dart';
import '../services/localization_service.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0; // Hlavní stránka je první (index 0)
  DateTime _selectedDate = DateTime.now();
  final ScrollController _calendarController = ScrollController();
  Set<String> _favoriteTeams = {};
  final FirestoreService _firestoreService = FirestoreService();
  final AutoUpdateService _autoUpdateService = AutoUpdateService();
  
  // Seznam dostupných soutěží - načte se z Firebase
  List<Competition> _competitions = [];
  bool _isLoadingLeagues = true;
  
  // Zápasy pro všechny dny v kalendáři (5 dní zpět, dnes, 5 dní dopředu)
  Map<String, List<Match>> _matchesByDate = {};
  bool _isLoadingMatches = true; // Začít s true, aby se zobrazil loading
  bool _isLoadingMatchesInProgress = false; // Zabraňuje více současným voláním
  
  // Týmy pro zobrazení oblíbených
  List<Team> _allTeams = [];
  bool _isLoadingTeams = false;
  Map<String, int> _teamPositions = {}; // Mapování názvu týmu na pozici v tabulce
  
  bool _isLoggedIn = false;
  
  // Animace pro logo v AppBar
  late AnimationController _titleAnimationController;
  late Animation<double> _titleSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _titleSlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleAnimationController.forward();
    });
    
    _loadLeagues();
    _initializeApp();
    _loadAllMatchesForCalendar();
    _loadTeams();
    _loadFavoriteTeams();
    _setupAutoUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCalendarOnToday();
    });
  }
  
  // Načíst týmy z Firestore
  Future<void> _loadTeams() async {
    try {
      setState(() => _isLoadingTeams = true);
      final teams = await _firestoreService.getTeams();
      setState(() {
        _allTeams = teams;
        _isLoadingTeams = false;
      });
      // Načíst pozice týmů v tabulkách
      _loadTeamPositions();
    } catch (e) {
      setState(() => _isLoadingTeams = false);
    }
  }

  // Načíst pozice týmů v tabulkách
  Future<void> _loadTeamPositions() async {
    try {
      final positions = <String, int>{};
      final currentSeason = 2023;
      
      // Mapování lig na jejich ID
      final leagues = [
        {'id': 'premier_league', 'apiId': 39},
        {'id': 'la_liga', 'apiId': 140},
        {'id': 'serie_a', 'apiId': 135},
        {'id': 'bundesliga', 'apiId': 78},
        {'id': 'ligue_1', 'apiId': 61},
      ];
      
      for (var league in leagues) {
        try {
          final standings = await _firestoreService.getStandings(
            leagueId: league['id'] as String,
            season: currentSeason,
          );
          
          for (var standing in standings) {
            positions[standing.teamName] = standing.position;
          }
        } catch (e) {
          // Chyba při načítání tabulky - pokračovat
        }
      }
      
      setState(() {
        _teamPositions = positions;
      });
    } catch (e) {
      // Chyba při načítání pozic
    }
  }

  Future<void> _loadAllMatchesForCalendar() async {
    // Zabraň více současným voláním
    if (_isLoadingMatchesInProgress) {
      return;
    }
    
    setState(() {
      _isLoadingMatches = true;
      _isLoadingMatchesInProgress = true;
    });
    
    try {
      final now = DateTime.now();
      final dates = List.generate(11, (index) => now.add(Duration(days: index - 5)));
      
      final Map<String, List<Match>> allMatchesMap = {};
      final Set<int> processedMatchIds = {}; // Pro kontrolu duplicit
      final apiService = ApiFootballService();
      await apiService.initializeApiKey();
    
      for (var date in dates) {
        try {
          // 1) Načíst zápasy z API
          var apiMatches = await apiService.getFixtures(date: date);
          var allowedApiMatches = apiMatches
              .where((match) => _allowedLeagueIds.contains(match.leagueId))
              .toList();

          // 2) Načíst zápasy z Firestore pro stejné datum
          var firestoreMatches = await _firestoreService.getFixtures(date);

          // 3) Sloučit API + Firestore (primárně podle ID, bez duplicit)
          final Map<int, Match> combinedMap = {};
          for (var match in firestoreMatches) {
            combinedMap[match.id] = match;
          }
          for (var match in allowedApiMatches) {
            combinedMap[match.id] = match;
          }
          final combinedMatches = combinedMap.values.toList();
          
          // Pokud nemáme žádné zápasy ani z API ani z Firestore, pokračovat na další datum
          if (combinedMatches.isEmpty) {
            continue;
          }
          
          // Rozdělit zápasy podle jejich skutečného data pro ukládání do Firestore
          final Map<String, List<Match>> matchesByActualDate = {};
          for (var match in combinedMatches) {
          final matchDate = match.date;
          final matchDateKey = '${matchDate.year}-${matchDate.month.toString().padLeft(2, '0')}-${matchDate.day.toString().padLeft(2, '0')}';
          
          if (!matchesByActualDate.containsKey(matchDateKey)) {
            matchesByActualDate[matchDateKey] = [];
          }
          matchesByActualDate[matchDateKey]!.add(match);
        }
        
          // Uložit / aktualizovat zápasy ve Firestore podle skutečného data
          for (var entry in matchesByActualDate.entries) {
            final matchDateKey = entry.key;
            final matchesForDate = entry.value;
            final parts = matchDateKey.split('-');
            if (parts.length == 3) {
              final matchDate = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              
              if (matchesForDate.isNotEmpty) {
                await _firestoreService.saveFixtures(date: matchDate, matches: matchesForDate);
              }
            }
          }
          
          final today = DateTime.now();
          for (var match in combinedMatches) {
            if (processedMatchIds.contains(match.id)) continue;
            
            final matchDate = match.date;
            
            if (date.year == today.year && 
                date.month == today.month && 
                date.day == today.day) {
              final yesterday = today.subtract(const Duration(days: 1));
              if (matchDate.year == yesterday.year &&
                  matchDate.month == yesterday.month &&
                  matchDate.day == yesterday.day) {
                continue;
              }
            }
            
            final matchDateKey = '${matchDate.year}-${matchDate.month.toString().padLeft(2, '0')}-${matchDate.day.toString().padLeft(2, '0')}';
            
            if (!allMatchesMap.containsKey(matchDateKey)) {
              allMatchesMap[matchDateKey] = [];
            }
            allMatchesMap[matchDateKey]!.add(match);
            processedMatchIds.add(match.id);
            
            if (match.isLive || match.isFinished) {
              _loadMatchDetails(match.id);
            }
          }
        } catch (e) {
          try {
            // Pokud API selže, načti alespoň zápasy z Firestore
            var matches = await _firestoreService.getFixtures(date);
            
            for (var match in matches) {
              if (processedMatchIds.contains(match.id)) continue;
              
              final matchDate = match.date;
              final matchDateKey = '${matchDate.year}-${matchDate.month.toString().padLeft(2, '0')}-${matchDate.day.toString().padLeft(2, '0')}';
              
              if (matchDate.year != date.year ||
                  matchDate.month != date.month ||
                  matchDate.day != date.day) {
                continue;
              }
              
              if (!allMatchesMap.containsKey(matchDateKey)) {
                allMatchesMap[matchDateKey] = [];
              }
              allMatchesMap[matchDateKey]!.add(match);
              processedMatchIds.add(match.id);
              
              if (match.isLive || match.isFinished) {
                _loadMatchDetails(match.id);
              }
            }
          } catch (e2) {
            // Ignorovat chyby při načítání z Firestore
          }
        }
      }
    
    
    final Map<String, List<Match>> cleanedMatchesMap = {};
    final Set<int> globalSeenIds = {};
    
    final sortedEntries = allMatchesMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    for (var entry in sortedEntries) {
      final dateKey = entry.key;
      final matches = entry.value;
      
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        
        final filteredMatches = <Match>[];
        for (var match in matches) {
          final matchDate = match.date;
          final matchesDate = matchDate.year == year &&
                 matchDate.month == month &&
                 matchDate.day == day;
          
          if (!matchesDate) {
            continue;
          }
          
          if (!globalSeenIds.contains(match.id)) {
            globalSeenIds.add(match.id);
            filteredMatches.add(match);
          }
        }
        
        if (filteredMatches.isNotEmpty) {
          cleanedMatchesMap[dateKey] = filteredMatches;
        }
      }
    }
    
      setState(() {
        _matchesByDate = cleanedMatchesMap;
        _isLoadingMatches = false;
        _isLoadingMatchesInProgress = false;
      });
    } catch (e) {
      // V případě chyby zkusit načíst z Firestore
      try {
        final now = DateTime.now();
        final dates = List.generate(11, (index) => now.add(Duration(days: index - 5)));
        final Map<String, List<Match>> allMatchesMap = {};
        
        for (var date in dates) {
          try {
            var matches = await _firestoreService.getFixtures(date);
            for (var match in matches) {
              final matchDate = match.date;
              final matchDateKey = '${matchDate.year}-${matchDate.month.toString().padLeft(2, '0')}-${matchDate.day.toString().padLeft(2, '0')}';
              
              if (!allMatchesMap.containsKey(matchDateKey)) {
                allMatchesMap[matchDateKey] = [];
              }
              allMatchesMap[matchDateKey]!.add(match);
            }
          } catch (e2) {
            // Ignorovat chyby při načítání z Firestore
          }
        }
        
        setState(() {
          _matchesByDate = allMatchesMap;
          _isLoadingMatches = false;
          _isLoadingMatchesInProgress = false;
        });
      } catch (e2) {
        setState(() {
          _isLoadingMatches = false;
          _isLoadingMatchesInProgress = false;
        });
      }
    }
  }

  Future<void> _loadMatchDetails(int fixtureId) async {
    try {
      final details = await _firestoreService.getMatchDetails(fixtureId);
      if (details == null) {
        await _firestoreService.fetchAndSaveMatchDetails(fixtureId);
      }
    } catch (e) {
      // Ignorovat chyby při načítání detailů
    }
  }

  // Načíst zápasy pro konkrétní datum
  Future<void> _loadMatchesForDate(DateTime date) async {
    try {
      // 1) Nejprve zkusit načíst zápasy z Firestore
      var firestoreMatches = await _firestoreService.getFixtures(date);
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (firestoreMatches.isNotEmpty) {
        final Map<String, List<Match>> updatedMatches = Map.from(_matchesByDate);
        updatedMatches[dateKey] = firestoreMatches;

        setState(() {
          _matchesByDate = updatedMatches;
        });
        return;
      }

      // 2) Pokud ve Firestore nic není, zkusit načíst z API a uložit
      final apiService = ApiFootballService();
      await apiService.initializeApiKey();
      
      var allMatches = await apiService.getFixtures(date: date);
      var allowedMatches = allMatches.where((match) => _allowedLeagueIds.contains(match.leagueId)).toList();
      
      // Uložit do Firestore
      if (allowedMatches.isNotEmpty) {
        await _firestoreService.saveFixtures(date: date, matches: allowedMatches);
      }
      
      // Přidat do _matchesByDate
      if (allowedMatches.isNotEmpty) {
        final Map<String, List<Match>> updatedMatches = Map.from(_matchesByDate);
        
        for (var match in allowedMatches) {
          final matchDate = match.date;
          final matchDateKey = '${matchDate.year}-${matchDate.month.toString().padLeft(2, '0')}-${matchDate.day.toString().padLeft(2, '0')}';
          
          if (!updatedMatches.containsKey(matchDateKey)) {
            updatedMatches[matchDateKey] = [];
          }
          
          // Zkontrolovat, jestli už tam není
          if (!updatedMatches[matchDateKey]!.any((m) => m.id == match.id)) {
            updatedMatches[matchDateKey]!.add(match);
          }
        }
        
        setState(() {
          _matchesByDate = updatedMatches;
        });
      }
    } catch (e) {
      // Pokud API selže, zkusit načíst z Firestore
      try {
        var matches = await _firestoreService.getFixtures(date);
        if (matches.isNotEmpty) {
          final matchDateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          
          final Map<String, List<Match>> updatedMatches = Map.from(_matchesByDate);
          updatedMatches[matchDateKey] = matches;
          
          setState(() {
            _matchesByDate = updatedMatches;
          });
        }
      } catch (e2) {
        // Ignorovat chyby
      }
    }
  }

  static const Set<int> _allowedLeagueIds = {
    39,   // Premier League
    140,  // La Liga
    135,  // Serie A
    78,   // Bundesliga
    61,   // Ligue 1
  };

  void _setupAutoUpdate() {
    final currentSeason = 2023;
    
    final Map<String, Map<String, int>> leagueConfigs = {
      'premier_league': {'apiLeagueId': 39, 'season': currentSeason},
      'la_liga': {'apiLeagueId': 140, 'season': currentSeason},
      'serie_a': {'apiLeagueId': 135, 'season': currentSeason},
      'bundesliga': {'apiLeagueId': 78, 'season': currentSeason},
      'ligue_1': {'apiLeagueId': 61, 'season': currentSeason},
    };

    for (var entry in leagueConfigs.entries) {
      _autoUpdateService.addLeague(
        leagueId: entry.key,
        apiLeagueId: entry.value['apiLeagueId']!,
        season: entry.value['season']!,
      );
    }

    _autoUpdateService.startAutoUpdate(intervalMinutes: 360);
  }


  Future<void> _loadLeagues() async {
    try {
      final leagues = await _firestoreService.getLeagues();
      
      setState(() {
        _competitions = leagues.map((league) => Competition(
          id: league.id,
          name: league.name,
          country: league.country,
          logo: league.logo,
        )).toList();
        _isLoadingLeagues = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLeagues = false;
      });
    }
  }

  Future<void> _initializeApp() async {
    await SessionManager().loadSavedSession();
    _checkAuthStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthStatus();
    // Nevolat _loadAllMatchesForCalendar() znovu, už se volá v initState
  }

  void _centerCalendarOnToday() {
    // Vycentrovat scroll na dnešní datum (index 5 z 11 položek)
    const itemWidth = 58.0; // 50 width + 8 padding
    const centerIndex = 5; // Střed z 11 položek
    final offset = centerIndex * itemWidth - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
    
    if (_calendarController.hasClients) {
      _calendarController.animateTo(
        offset.clamp(0.0, _calendarController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  void _checkAuthStatus() {
    setState(() {
      _isLoggedIn = SessionManager().isLoggedIn;
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) => _checkAuthStatus());
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((result) {
      if (result == true) {
        _checkAuthStatus();
        setState(() {});
      }
    });
  }

  Future<void> _loadFavoriteTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteTeamsList = prefs.getStringList('favorite_teams') ?? [];
      setState(() {
        _favoriteTeams = favoriteTeamsList.toSet();
      });
    } catch (e) {
      // Chyba při načítání - ignorovat
    }
  }

  // Uložit oblíbené týmy do SharedPreferences
  Future<void> _saveFavoriteTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_teams', _favoriteTeams.toList());
    } catch (e) {
      // Chyba při ukládání - ignorovat
    }
  }

  void _toggleFavoriteTeam(String teamName) {
    setState(() {
      if (_favoriteTeams.contains(teamName)) {
        _favoriteTeams.remove(teamName);
      } else {
        _favoriteTeams.add(teamName);
      }
    });
    _saveFavoriteTeams();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _titleSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                MediaQuery.of(context).size.width * _titleSlideAnimation.value,
                0,
              ),
              child: Image.asset('assets/images/text.png', height: 70),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        actions: [
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _navigateToProfile,
                child: SessionManager().profileImageUrl != null && 
                       SessionManager().profileImageUrl!.isNotEmpty &&
                       SessionManager().profileImageUrl!.startsWith('http')
                    ? Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.network(
                            SessionManager().profileImageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              );
                            },
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: _navigateToLogin,
              tooltip: 'Přihlásit se',
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMainScreen(), // index 0: Home
          _buildCompetitionsScreen(), // index 1: Soutěže
          TeamsScreen( // index 2: Týmy
            favoriteTeams: _favoriteTeams,
            onFavoritesChanged: (newFavorites) {
              setState(() {
                _favoriteTeams = newFavorites;
              });
              _saveFavoriteTeams();
            },
          ),
          _buildFavoriteTeamsScreen(), // index 3: Oblíbené
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 4,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 0), // Home
              _buildNavItem(Icons.emoji_events, 1), // Soutěže
              _buildNavItem(Icons.groups, 2), // Týmy
              _buildNavItem(Icons.favorite, 3), // Oblíbené
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? const Color(0xFF3E5F44).withOpacity(0.1) : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF3E5F44) : Colors.grey,
            size: 26,
          ),
        ),
      ),
    );
  }

  // Oblíbené týmy (úplně vlevo)
  Widget _buildFavoriteTeamsScreen() {
    if (!_isLoggedIn) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate('login_for_favorites'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingTeams) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Načítám týmy...'),
          ],
        ),
      );
    }

    // Filtrovat pouze oblíbené týmy
    final favoriteTeamsList = _allTeams
        .where((team) => _favoriteTeams.contains(team.name))
        .toList();

    if (favoriteTeamsList.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate('no_favorite_teams'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationService.translate('add_favorites_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: favoriteTeamsList.length,
      itemBuilder: (context, index) {
        final team = favoriteTeamsList[index];
        final position = _teamPositions[team.name];
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamDetailScreen(team: team),
              ),
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: Color(0xFF3E5F44),
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  // Text uprostřed
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Název týmu
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Liga
                        Text(
                          team.league,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Pozice v tabulce
                        if (position != null)
                          Text(
                            '$position. místo',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E5F44),
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                  // Logo týmu vlevo
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        child: team.logoUrl.startsWith('http')
                            ? Image.network(
                                team.logoUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.sports_soccer,
                                    size: 60,
                                    color: Color(0xFF3E5F44),
                                  );
                                },
                              )
                            : const Icon(
                                Icons.sports_soccer,
                                size: 60,
                                color: Color(0xFF3E5F44),
                              ),
                      ),
                    ),
                  ),
                  // Srdíčko vpravo
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _toggleFavoriteTeam(team.name);
                        },
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Soutěže (vlevo od hlavní)
  Widget _buildCompetitionsScreen() {
    if (_isLoadingLeagues) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Načítám ligy...'),
          ],
        ),
      );
    }
    
    if (_competitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Žádné ligy nenalezeny',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadLeagues,
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._competitions.map((competition) => _buildCompetitionCard(competition)),
        ],
      ),
    );
  }

  // Hlavní stránka (uprostřed) s kalendářem a dnešními zápasy
  Widget _buildMainScreen() {
    return Column(
      children: [
        // Kalendář
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D2D2D) 
              : Colors.grey[100],
          child: Column(
            children: [
              Text(
                _getFormattedDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  controller: _calendarController,
                  scrollDirection: Axis.horizontal,
                  itemCount: 11, // 5 dní zpět, dnes, 5 dní dopředu
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index - 5));
                    final isSelected = _isSameDay(date, _selectedDate);
                    final isToday = _isSameDay(date, DateTime.now());
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedDate = date);
                          // Pokud nejsou zápasy pro vybrané datum, zkusit je načíst
                          final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          if (!_matchesByDate.containsKey(dateKey) || _matchesByDate[dateKey]!.isEmpty) {
                            _loadMatchesForDate(date);
                          }
                        },
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF5E936C) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday 
                              ? Border.all(color: const Color(0xFF5E936C), width: 3)
                              : null,
                            boxShadow: isToday && !isSelected ? [
                              BoxShadow(
                                color: const Color(0xFF5E936C).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ] : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected 
                                    ? Colors.white 
                                    : isToday 
                                      ? const Color(0xFF5E936C)
                                      : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.grey[600],
                                ),
                              ),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected 
                                    ? Colors.white 
                                    : isToday
                                      ? const Color(0xFF5E936C)
                                      : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Zápasy pro všechny dny v kalendáři
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildAllMatches(),
          ),
        ),
      ],
    );
  }

  // Pomocné metody pro datum
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return LocalizationService.translate('today');
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return LocalizationService.translate('yesterday');
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return LocalizationService.translate('tomorrow');
    
    return '${date.day}. ${LocalizationService.getMonthName(date.month)}';
  }

  String _getDayName(DateTime date) {
    return LocalizationService.getDayName(date.weekday);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }


  Widget _buildAllMatches() {
    if (_isLoadingMatches) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Vždy zobrazit pouze zápasy pro aktuálně vybraný den
    final List<MapEntry<DateTime, bool>> dateEntries = [
      MapEntry(_selectedDate, true), // Vybraný den
    ];
    
    // Seřadit data chronologicky
    dateEntries.sort((a, b) => a.key.compareTo(b.key));
    
    final List<Widget> widgets = [];
    bool hasAnyMatches = false;
    
    // Projít všechna data a zobrazit zápasy
    for (var entry in dateEntries) {
      final date = entry.key;
      final isSelected = entry.value;
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final allMatches = _matchesByDate[dateKey] ?? [];
      
      // Primárně zkusit filtrovat zápasy přesné na daný den
      var matches = allMatches.where((match) {
        final matchDate = match.date;
        return matchDate.year == date.year &&
               matchDate.month == date.month &&
               matchDate.day == date.day;
      }).toList();

      // Pokud by kvůli časovému posunu / formátu zůstalo prázdné,
      // ale pro tento klíč nějaké zápasy máme, zobraz je všechny.
      if (matches.isEmpty && allMatches.isNotEmpty) {
        matches = allMatches;
      }
      
      if (matches.isNotEmpty) {
        hasAnyMatches = true;
        widgets.add(
          _buildDateSection(date, matches, isSelected),
        );
      }
    }
    
    if (!hasAnyMatches) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                LocalizationService.translate('no_matches'),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                LocalizationService.translate('no_matches_subtitle'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildDateSection(DateTime date, List<Match> matches, bool isSelected) {
    // Seřadit zápasy: nejdřív ty s oblíbenými týmy
    final sortedMatches = List<Match>.from(matches);
    sortedMatches.sort((a, b) {
      final aHasFavorite = _favoriteTeams.contains(a.homeTeam) || _favoriteTeams.contains(a.awayTeam);
      final bHasFavorite = _favoriteTeams.contains(b.homeTeam) || _favoriteTeams.contains(b.awayTeam);
      
      if (aHasFavorite && !bHasFavorite) return -1;
      if (!aHasFavorite && bHasFavorite) return 1;
      return 0; // Zachovat původní pořadí pro zápasy se stejnou prioritou
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matches.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              top: isSelected ? 0 : 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                Text(
                  _getFormattedDate(date),
                  style: TextStyle(
                    fontSize: isSelected ? 20 : 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? const Color(0xFF3E5F44) : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E5F44).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E5F44),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100]?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  _getNoMatchesMessage(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ...sortedMatches.map((match) => _buildMatchCardFromMatch(match)),
        const SizedBox(height: 8),
      ],
    );
  }

  String _getNoMatchesMessage(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return LocalizationService.translate('no_matches_today');
    } else if (_isSameDay(date, now.add(const Duration(days: 1)))) {
      return LocalizationService.translate('no_matches_tomorrow');
    }
    return LocalizationService.translate('no_matches');
  }


  Widget _buildCompetitionCard(Competition competition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Mapa ID lig na jejich API ID
          final Map<String, int> leagueApiIds = {
            'premier_league': 39,
            'la_liga': 140,
            'serie_a': 135,
            'bundesliga': 78,
            'ligue_1': 61,
          };

          // Pokud liga má API ID, otevři novou obrazovku s tabulkou
          if (leagueApiIds.containsKey(competition.id)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StandingsScreen(
                  leagueId: competition.id,
                  leagueName: competition.name,
                  apiLeagueId: leagueApiIds[competition.id]!,
                ),
              ),
            );
            return;
          }

          // Jinak zobrazit zprávu, že liga není podporována
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${competition.name} není momentálně podporována'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: competition.logo.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          competition.logo,
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.sports_soccer,
                              size: 32,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          competition.logo,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Název a země
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      competition.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      competition.country,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Šipka
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCardFromMatch(Match match) {
    final timeStr = _formatMatchTime(match);
    final isLive = match.isLive;
    final hasFavoriteTeam = _favoriteTeams.contains(match.homeTeam) || _favoriteTeams.contains(match.awayTeam);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isLive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLive 
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Liga a kolo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (match.leagueLogo.isNotEmpty)
                  Image.network(
                    match.leagueLogo,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                if (match.leagueLogo.isNotEmpty) const SizedBox(width: 4),
                Text(
                  match.leagueName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasFavoriteTeam) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.favorite,
                    size: 14,
                    color: Colors.red,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Zápas
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          match.homeTeam,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (match.homeLogo.isNotEmpty)
                        Image.network(
                          match.homeLogo,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.sports_soccer, size: 24);
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      if (match.homeScore != null && match.awayScore != null)
                        Text(
                          '${match.homeScore} - ${match.awayScore}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isLive ? Colors.red : null,
                          ),
                        )
                      else
                        const Text('- : -', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLive 
                              ? Colors.red 
                              : match.isFinished 
                                  ? Colors.grey[300] 
                                  : Colors.green[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: isLive ? Colors.white : Colors.black87,
                            fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      if (match.awayLogo.isNotEmpty)
                        Image.network(
                          match.awayLogo,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.sports_soccer, size: 24);
                          },
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          match.awayTeam,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Místo konání
            if (match.venue.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${match.venue}${match.city.isNotEmpty ? ', ${match.city}' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMatchTime(Match match) {
    if (match.isLive) {
      return match.status; // LIVE, HT, 1H, 2H
    } else if (match.isFinished) {
      return 'FT';
    } else {
      // Budoucí zápas - zobrazit čas
      final hour = match.date.hour.toString().padLeft(2, '0');
      final minute = match.date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }
}

class Competition {
  final String id;
  final String name;
  final String country;
  final String logo;

  Competition({
    required this.id,
    required this.name,
    required this.country,
    required this.logo,
  });
}