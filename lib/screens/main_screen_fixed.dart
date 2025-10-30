import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 2; // Hlavní stránka je uprostřed (index 2)
  DateTime _selectedDate = DateTime.now();
  final ScrollController _calendarController = ScrollController();
  List<String> _favoriteTeams = [];
  
  // Seznam dostupných soutěží
  final List<Competition> _competitions = [
    Competition(id: '1', name: 'Premier League', country: 'Anglie', logo: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
    Competition(id: '2', name: 'La Liga', country: 'Španělsko', logo: '🇪🇸'),
    Competition(id: '3', name: 'Serie A', country: 'Itálie', logo: '🇮🇹'),
    Competition(id: '4', name: 'Bundesliga', country: 'Německo', logo: '🇩🇪'),
    Competition(id: '5', name: 'Ligue 1', country: 'Francie', logo: '🇫🇷'),
    Competition(id: '6', name: 'Fortuna Liga', country: 'Česká republika', logo: '🇨🇿'),
    Competition(id: '7', name: 'Champions League', country: 'Evropa', logo: '🏆'),
    Competition(id: '8', name: 'Europa League', country: 'Evropa', logo: '🥈'),
  ];
  
  Competition? _selectedCompetition;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _selectedCompetition = _competitions.first;
    _checkAuthStatus();
    // Vycentrovat kalendář na dnešní datum
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCalendarOnToday();
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
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

  Future<void> _checkAuthStatus() async {
    // Zkontrolujeme, jestli je uživatel přihlášen pomocí remember me preference
    final rememberMe = await _authService.shouldRememberUser();
    setState(() {
      _isLoggedIn = rememberMe;
    });
  }

  void _selectCompetition(Competition competition) {
    setState(() {
      _selectedCompetition = competition;
    });
    Navigator.of(context).pop(); // Zavřít drawer
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ).then((_) => _checkAuthStatus());
  }

  Future<void> _logout() async {
    await _authService.signOut();
    setState(() {
      _isLoggedIn = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Úspěšně odhlášen'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleFavoriteTeam(String teamName) {
    setState(() {
      if (_favoriteTeams.contains(teamName)) {
        _favoriteTeams.remove(teamName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$teamName odebrán z oblíbených')),
        );
      } else {
        _favoriteTeams.add(teamName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$teamName přidán do oblíbených')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_selectedCompetition?.logo ?? '⚽'),
            const SizedBox(width: 8),
            Text(_selectedCompetition?.name ?? 'Strike!'),
          ],
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: _logout,
              tooltip: 'Profil / Odhlásit se',
            )
          else
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: _navigateToLogin,
              tooltip: 'Přihlásit se',
            ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Header drawer
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF0A84FF),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Vyberte soutěž',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Seznam soutěží
            Expanded(
              child: ListView.builder(
                itemCount: _competitions.length,
                itemBuilder: (context, index) {
                  final competition = _competitions[index];
                  final isSelected = competition.id == _selectedCompetition?.id;
                  
                  return ListTile(
                    leading: Text(
                      competition.logo,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      competition.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0A84FF) : null,
                      ),
                    ),
                    subtitle: Text(competition.country),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFF0A84FF).withOpacity(0.1),
                    onTap: () => _selectCompetition(competition),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildFavoriteTeamsScreen(),
          _buildCompetitionsScreen(),
          _buildMainScreen(),
          _buildTeamsScreen(),
          _buildNewsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF0A84FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Oblíbené',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Soutěže',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Domů',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Týmy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Novinky',
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
          _buildSectionHeader('Oblíbené týmy'),
          if (_isLoggedIn) ...[
            if (_favoriteTeams.isNotEmpty) ...[
              ..._favoriteTeams.map((team) => _buildTeamCard(team, '⚽', 'Liga', isFavorite: true)),
            ] else ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Zatím nemáte oblíbené týmy',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Přidejte je kliknutím na srdcová na stránce týmů',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Přihlaste se pro sledování oblíbených týmů',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Všechny soutěže'),
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
          color: Colors.grey[100],
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
                            color: isSelected ? const Color(0xFF0A84FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday ? Border.all(color: const Color(0xFF0A84FF), width: 2) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                ),
                              ),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black,
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

  // Týmy (napravo od hlavní)
  Widget _buildTeamsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Týmy - ${_selectedCompetition?.name ?? 'Všechny'}'),
          _buildTeamCard('Manchester City', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Premier League'),
          _buildTeamCard('Arsenal', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Premier League'),
          _buildTeamCard('Liverpool', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Premier League'),
          _buildTeamCard('Chelsea', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Premier League'),
          _buildTeamCard('Tottenham', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', 'Premier League'),
        ],
      ),
    );
  }

  // Novinky (úplně napravo)
  Widget _buildNewsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Nejnovější zprávy'),
          _buildNewsCard(
            'Nový přestup sezóny',
            'Hvězdný hráč přestupuje do Premier League za rekordní částku...',
            '2 hodiny',
          ),
          _buildNewsCard(
            'Zranění klíčového hráče',
            'Kapitán týmu bude chybět následující 3 zápasy kvůli zranění...',
            '4 hodiny',
          ),
          _buildNewsCard(
            'Změna v trenérském štábu',
            'Klub oznámil jmenování nového asistenta trenéra...',
            '6 hodin',
          ),
        ],
      ),
    );
  }

  // Pomocné metody pro datum
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Dnes';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Včera';
    if (_isSameDay(date, now.add(const Duration(days: 1)))) return 'Zítra';
    
    final months = ['Led', 'Úno', 'Bře', 'Dub', 'Kvě', 'Čer', 
                   'Črc', 'Srp', 'Zář', 'Říj', 'Lis', 'Pro'];
    return '${date.day}. ${months[date.month - 1]}';
  }

  String _getDayName(DateTime date) {
    final days = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
    return days[date.weekday - 1];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  String _getMatchesSectionTitle() {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) return 'Dnešní zápasy';
    if (_selectedDate.isBefore(now)) return 'Výsledky';
    return 'Nadcházející zápasy';
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
    final isSelected = competition.id == _selectedCompetition?.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? const Color(0xFF0A84FF).withOpacity(0.1) : null,
      child: ListTile(
        leading: Text(
          competition.logo,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          competition.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF0A84FF) : null,
          ),
        ),
        subtitle: Text(competition.country),
        trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF0A84FF)) : null,
        onTap: () => _selectCompetition(competition),
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

  Widget _buildNewsCard(String title, String content, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
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