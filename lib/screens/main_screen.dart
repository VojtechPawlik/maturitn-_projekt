import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'champions_league_screen.dart';
import 'premier_league_screen.dart';
import 'serie_a_screen.dart';
import 'la_liga_screen.dart';
import 'ligue1_screen.dart';
import 'europa_league_screen.dart';
import 'bundesliga_screen.dart';
import 'teams_screen.dart';
import 'settings_screen.dart';
import 'standings_screen.dart';
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
  
  // Seznam dostupných soutěží - načte se z Firebase
  List<Competition> _competitions = [];
  bool _isLoadingLeagues = true;
  
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
    _initializeApp();
    // Vycentrovat kalendář na dnešní datum
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCalendarOnToday();
    });
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

  void _toggleFavoriteTeam(String teamName) {
    setState(() {
      if (_favoriteTeams.contains(teamName)) {
        _favoriteTeams.remove(teamName);
      } else {
        _favoriteTeams.add(teamName);
      }
    });
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
            },
          ), // Použití samostatné TeamsScreen z Google Sheets
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoggedIn) ...[
            if (_favoriteTeams.isNotEmpty) ...[
              ..._favoriteTeams.map((teamName) {
                // Použít základní zobrazení týmu
                return _buildTeamCard(teamName, '⚽', LocalizationService.translate('league'), isFavorite: true);
              }).toList(),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
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
            ],
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
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
          ],
        ],
      ),
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
                        onTap: () => setState(() => _selectedDate = date),
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
        // Zápasy pro vybraný den
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(_getMatchesSectionTitle()),
                _buildMatchesForDate(_selectedDate),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Týmy (napravo od hlavní) - SMAZÁNO, používá se TeamsScreen
  // Widget _buildTeamsScreen() - odstraněno

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

  String _getMatchesSectionTitle() {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) return LocalizationService.translate('todays_matches');
    if (_selectedDate.isBefore(now)) return LocalizationService.translate('results');
    return LocalizationService.translate('upcoming_matches');
  }

  Widget _buildMatchesForDate(DateTime date) {
    final now = DateTime.now();
    
    if (_isSameDay(date, now)) {
      // Dnešní zápasy
      return Column(
        children: [
          _buildMatchCard('Manchester United', 'Liverpool', '15:30', isLive: true),
          _buildMatchCard('Arsenal', 'Chelsea', '18:00'),
          _buildMatchCard('Barcelona', 'Real Madrid', '20:45'),
        ],
      );
    } else if (date.isBefore(now)) {
      // Minulé zápasy - výsledky
      return Column(
        children: [
          _buildMatchCard('PSG', 'Monaco', 'Konec', homeScore: 3, awayScore: 0),
          _buildMatchCard('Juventus', 'Inter Milan', 'Konec', homeScore: 1, awayScore: 2),
          _buildMatchCard('Bayern Munich', 'Dortmund', 'Konec', homeScore: 2, awayScore: 1),
        ],
      );
    } else {
      // Budoucí zápasy
      return Column(
        children: [
          _buildMatchCard('Milan', 'Napoli', '16:00'),
          _buildMatchCard('Atletico Madrid', 'Sevilla', '19:30'),
          _buildMatchCard('Lyon', 'Marseille', '21:00'),
        ],
      );
    }
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

          // Jinak použij původní navigaci (starý systém)
          if (competition.id == '7') { // Champions League má ID '7'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChampionsLeagueScreen(),
              ),
            );
          } else if (competition.id == '1') { // Premier League má ID '1'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PremierLeagueScreen(),
              ),
            );
          } else if (competition.id == '3') { // Serie A má ID '3'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SerieAScreen(),
              ),
            );
          } else if (competition.id == '2') { // La Liga má ID '2'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LaLigaScreen(),
              ),
            );
          } else if (competition.id == '4') { // Bundesliga má ID '4'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BundesligaScreen(),
              ),
            );
          } else if (competition.id == '5') { // Ligue 1 má ID '5'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Ligue1Screen(),
              ),
            );
          } else if (competition.id == '8') { // Europa League má ID '8'
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EuropaLeagueScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTeamCard(String teamName, String flag, String league, {bool isFavorite = false}) {
    final isFav = _favoriteTeams.contains(teamName);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          teamName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(league),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFavorite) // Nezobrazeovat srditko na stránce oblíbených
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey,
                ),
                onPressed: () => _toggleFavoriteTeam(teamName),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () {
          // TODO: Navigace na detail týmu
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMatchCard(String homeTeam, String awayTeam, String time, 
      {int? homeScore, int? awayScore, bool isLive = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                homeTeam,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  if (homeScore != null && awayScore != null)
                    Text(
                      '$homeScore - $awayScore',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Text('- : -'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLive ? Colors.red : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLive ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                awayTeam,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
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