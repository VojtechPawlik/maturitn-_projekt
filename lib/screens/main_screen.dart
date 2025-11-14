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

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Hlavní stránka je uprostřed (index 2)
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
  bool _isLoadingMatches = false;
  
  // Týmy pro zobrazení oblíbených
  List<Team> _allTeams = [];
  bool _isLoadingTeams = false;
  
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
    _initializeApp();
    _loadAllMatchesForCalendar();
    _loadTeams();
    _loadFavoriteTeams();
    _setupAutoUpdate();
    // Vycentrovat kalendář na dnešní datum
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
    } catch (e) {
      setState(() => _isLoadingTeams = false);
    }
  }

  // Načíst zápasy pro všechny dny v kalendáři (5 dní zpět, dnes, 5 dní dopředu)
  Future<void> _loadAllMatchesForCalendar() async {
    setState(() => _isLoadingMatches = true);
    
    final now = DateTime.now();
    final dates = List.generate(11, (index) => now.add(Duration(days: index - 5)));
    
    final Map<String, List<Match>> matchesMap = {};
    
    for (var date in dates) {
      try {
        // Nejdřív zkusit načíst z Firestore
        var matches = await _firestoreService.getFixtures(date);
        
        // Filtrovat pouze povolené ligy
        matches = _filterMatchesByLeague(matches);
        
        // Pokud nejsou data, načíst z API
        if (matches.isEmpty) {
          final apiService = ApiFootballService();
          await apiService.initializeApiKey();
          var allMatches = await apiService.getFixtures(date: date);
          
          // Filtrovat pouze povolené ligy
          matches = _filterMatchesByLeague(allMatches);
          
          // Uložit do Firestore pouze filtrované zápasy
          if (matches.isNotEmpty) {
            await _firestoreService.saveFixtures(date: date, matches: matches);
          }
        }
        
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        matchesMap[dateKey] = matches;
      } catch (e) {
        print('Chyba při načítání zápasů pro ${date.toString()}: $e');
      }
    }
    
    setState(() {
      _matchesByDate = matchesMap;
      _isLoadingMatches = false;
    });
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

  void _setupAutoUpdate() {
    // Přidat ligy k automatické aktualizaci
    // Pouze hlavní evropské ligy
    // Pro free plán API-Football použijte sezónu 2023 (2024 není dostupná)
    // Pokud máte placený plán, změňte na 2024
    final currentSeason = 2023; // Změňte na 2024 pokud máte placený plán
    
    final Map<String, Map<String, int>> leagueConfigs = {
      'premier_league': {'apiLeagueId': 39, 'season': currentSeason},      // Anglická Premier League
      'la_liga': {'apiLeagueId': 140, 'season': currentSeason},            // Španělská La Liga
      'serie_a': {'apiLeagueId': 135, 'season': currentSeason},            // Italská Serie A
      'bundesliga': {'apiLeagueId': 78, 'season': currentSeason},          // Německá Bundesliga
      'ligue_1': {'apiLeagueId': 61, 'season': currentSeason},             // Francouzská Ligue 1
      'champions_league': {'apiLeagueId': 2, 'season': currentSeason},    // Liga mistrů
      'europa_league': {'apiLeagueId': 3, 'season': currentSeason},        // Evropská liga
    };

    for (var entry in leagueConfigs.entries) {
      _autoUpdateService.addLeague(
        leagueId: entry.key,
        apiLeagueId: entry.value['apiLeagueId']!,
        season: entry.value['season']!,
      );
    }

    // Spustit automatickou aktualizaci každých 6 hodin (360 minut)
    _autoUpdateService.startAutoUpdate(intervalMinutes: 360);
  }


  // Filtrovat zápasy podle povolených lig
  List<Match> _filterMatchesByLeague(List<Match> matches) {
    return matches.where((match) => _allowedLeagueIds.contains(match.leagueId)).toList();
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
    // Načíst uloženou session při startu aplikace
    await SessionManager().loadSavedSession();
    _checkAuthStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Znovu zkontrolovat auth stav při návratu na tuto obrazovku
    _checkAuthStatus();
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
    _calendarController.dispose();
    super.dispose();
  }

  void _checkAuthStatus() {
    // Použít SessionManager pro kontrolu přihlášení
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
      // Pokud se uživatel odhlásil v profilu, aktualizuj stav
      if (result == true) {
        _checkAuthStatus();
      }
    });
  }

  // Načíst oblíbené týmy z SharedPreferences
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
        title: Image.asset('assets/images/text.png', height: 70),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: SessionManager().profileImagePath != null
                            ? Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.photo,
                                  color: Color(0xFF0A84FF),
                                  size: 18,
                                ),
                              )
                            : Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF0A84FF),
                                  size: 18,
                                ),
                              ),
                      ),
                    ),
                    if (SessionManager().userNickname != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          SessionManager().userNickname!.length > 8
                              ? '${SessionManager().userNickname!.substring(0, 8)}...'
                              : SessionManager().userNickname!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
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
          _buildFavoriteTeamsScreen(),
          _buildCompetitionsScreen(),
          _buildMainScreen(),
          TeamsScreen(
            favoriteTeams: _favoriteTeams,
            onFavoritesChanged: (newFavorites) {
              setState(() {
                _favoriteTeams = newFavorites;
              });
              _saveFavoriteTeams();
            },
          ),
          _buildNewsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF3E5F44),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: LocalizationService.translate('favorites'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events),
            label: LocalizationService.translate('competitions'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: LocalizationService.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups),
            label: LocalizationService.translate('teams'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.article),
            label: LocalizationService.translate('news'),
          ),
        ],
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoriteTeamsList.length,
      itemBuilder: (context, index) {
        final team = favoriteTeamsList[index];
        final isFavorite = _favoriteTeams.contains(team.name);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: team.logoUrl.startsWith('http')
                ? Image.network(
                    team.logoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.sports_soccer, size: 40);
                    },
                  )
                : const Icon(Icons.sports_soccer, size: 40),
            title: Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(team.league),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleFavoriteTeam(team.name),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamDetailScreen(team: team),
                ),
              );
            },
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

  // Novinky (úplně napravo)
  Widget _buildNewsScreen() {
    return Center(
      child: Text(
        LocalizationService.isEnglish ? 'Coming soon' : 'Již brzy',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
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

    final now = DateTime.now();
    final dates = List.generate(11, (index) => now.add(Duration(days: index - 5)));
    
    final List<Widget> widgets = [];
    
    for (var date in dates) {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final matches = _matchesByDate[dateKey] ?? [];
      final isSelected = _isSameDay(date, _selectedDate);
      
      // Zobrazit pouze vybraný den nebo všechny dny s zápasy
      if (isSelected || matches.isNotEmpty) {
        widgets.add(
          _buildDateSection(date, matches, isSelected),
        );
      }
    }
    
    if (widgets.isEmpty) {
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
          ...matches.map((match) => _buildMatchCardFromMatch(match)),
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
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: competition.logo.startsWith('http')
            ? Image.network(
                competition.logo,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.sports_soccer, size: 40);
                },
              )
            : Text(
                competition.logo,
                style: const TextStyle(fontSize: 24),
              ),
        title: Text(
          competition.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          competition.country,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Mapa ID lig na jejich API ID
          final Map<String, int> leagueApiIds = {
            'premier_league': 39,
            'la_liga': 140,
            'serie_a': 135,
            'bundesliga': 78,
            'ligue_1': 61,
            'champions_league': 2,
            'europa_league': 3,
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
      ),
    );
  }

  Widget _buildMatchCardFromMatch(Match match) {
    final timeStr = _formatMatchTime(match);
    final isLive = match.isLive;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isLive ? 4 : 2,
      color: isLive ? Colors.red.withOpacity(0.05) : null,
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
                '📍 ${match.venue}${match.city.isNotEmpty ? ', ${match.city}' : ''}',
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

// Model pro soutěž
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