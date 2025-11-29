import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/api_football_service.dart';

class MatchDetailScreen extends StatefulWidget {
  final Match match;

  const MatchDetailScreen({
    super.key,
    required this.match,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiFootballService _apiFootballService = ApiFootballService();
  MatchDetails? _matchDetails;
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Nejdříve zkusit načíst z Firestore
      MatchDetails? details = await _firestoreService.getMatchDetails(widget.match.id);

      // Pokud není v Firestore, načíst z API
      if (details == null) {
        await _apiFootballService.initializeApiKey();
        details = await _firestoreService.fetchAndSaveMatchDetails(widget.match.id);
      }

      if (mounted) {
        setState(() {
          _matchDetails = details;
          _isLoading = false;
          if (details == null) {
            _errorMessage = 'Nepodařilo se načíst detailní informace o zápase.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Chyba při načítání detailů zápasu: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail zápasu'),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Přehled'),
            Tab(text: 'Statistiky'),
            Tab(text: 'Sestavy'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Fixní sekce s logy týmů, informacemi a výsledkem
          _buildMatchHeader(),
          // Obsah podle tabu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMatchDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E5F44),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Zkusit znovu'),
                            ),
                          ],
                        ),
                      )
                    : _matchDetails == null
                        ? const Center(child: Text('Detailní informace nejsou k dispozici.'))
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildOverviewTab(),
                              _buildStatisticsTab(),
                              _buildLineupsTab(),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Liga
          if (widget.match.leagueLogo.isNotEmpty || widget.match.leagueName.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.match.leagueLogo.isNotEmpty)
                  Image.network(
                    widget.match.leagueLogo,
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                if (widget.match.leagueLogo.isNotEmpty) const SizedBox(width: 6),
                Text(
                  widget.match.leagueName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          if (widget.match.leagueLogo.isNotEmpty || widget.match.leagueName.isNotEmpty)
            const SizedBox(height: 12),
          // Týmy a výsledek
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Domácí tým
              Expanded(
                child: Column(
                  children: [
                    if (widget.match.homeLogo.isNotEmpty)
                      Image.network(
                        widget.match.homeLogo,
                        width: 64,
                        height: 64,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 64),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.match.homeTeam,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Výsledek
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      widget.match.homeScore != null && widget.match.awayScore != null
                          ? '${widget.match.homeScore} - ${widget.match.awayScore}'
                          : '- : -',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E5F44),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.match.isLive
                            ? Colors.red
                            : widget.match.isFinished
                                ? Colors.grey[300]
                                : Colors.green[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.match.statusLong,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.match.isLive ? Colors.white : Colors.black87,
                          fontWeight: widget.match.isLive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Hostující tým
              Expanded(
                child: Column(
                  children: [
                    if (widget.match.awayLogo.isNotEmpty)
                      Image.network(
                        widget.match.awayLogo,
                        width: 64,
                        height: 64,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 64),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      widget.match.awayTeam,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Místo konání
          if (widget.match.venue.isNotEmpty || widget.match.city.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${widget.match.venue}${widget.match.city.isNotEmpty ? ', ${widget.match.city}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_matchDetails == null) {
      return const Center(child: Text('Žádné informace o zápase.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Góly
          if (_matchDetails!.goals.isNotEmpty) ...[
            _buildSectionHeader('Góly'),
            ..._matchDetails!.goals.map((goal) => _buildGoalCard(goal)),
            const SizedBox(height: 16),
          ],

          // Karty
          if (_matchDetails!.cards.isNotEmpty) ...[
            _buildSectionHeader('Karty'),
            ..._matchDetails!.cards.map((card) => _buildCardCard(card)),
            const SizedBox(height: 16),
          ],

          // Střídání
          if (_matchDetails!.substitutions.isNotEmpty) ...[
            _buildSectionHeader('Střídání'),
            ..._matchDetails!.substitutions.map((sub) => _buildSubstitutionCard(sub)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3E5F44),
        ),
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final isHome = goal.team == 'home';
    final teamName = isHome ? widget.match.homeTeam : widget.match.awayTeam;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Minuta
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                '${goal.minute}\'',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5F44),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ikona gólu
            const Icon(Icons.sports_soccer, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            // Jméno hráče, asistence a tým
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.player,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (goal.assist.isNotEmpty)
                    Text(
                      'Asistence: ${goal.assist}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  Text(
                    teamName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Značky pro vlastní gól a penaltu
            if (goal.isOwnGoal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VG',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (goal.isPenalty)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'P',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCard(MatchCard card) {
    final isHome = card.team == 'home';
    final teamName = isHome ? widget.match.homeTeam : widget.match.awayTeam;
    final isYellow = card.type == 'yellow';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Minuta
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                '${card.minute}\'',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5F44),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ikona karty
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isYellow ? Colors.yellow : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Jméno hráče a tým
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.player,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    teamName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Typ karty
            Text(
              isYellow ? 'Žlutá' : 'Červená',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isYellow ? Colors.orange[700] : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubstitutionCard(Substitution sub) {
    final isHome = sub.team == 'home';
    final teamName = isHome ? widget.match.homeTeam : widget.match.awayTeam;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Minuta
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                '${sub.minute}\'',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5F44),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Ikona střídání
            const Icon(Icons.swap_horiz, color: Colors.blue, size: 24),
            const SizedBox(width: 12),
            // Hráči a tým
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sub.playerOut,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sub.playerIn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    teamName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_matchDetails == null || _matchDetails!.statistics.homeStats.isEmpty) {
      return const Center(child: Text('Statistiky nejsou k dispozici.'));
    }

    final stats = _matchDetails!.statistics;
    final statKeys = stats.homeStats.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: statKeys.length,
      itemBuilder: (context, index) {
        final key = statKeys[index];
        final homeValue = stats.homeStats[key] ?? 0;
        final awayValue = stats.awayStats[key] ?? 0;
        final total = homeValue + awayValue;
        final homePercentage = total > 0 ? (homeValue / total * 100) : 50.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translateStatKey(key),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF3E5F44),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            homeValue.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            widget.match.homeTeam,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Progress bar
                    Expanded(
                      flex: 2,
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: homePercentage / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3E5F44),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            awayValue.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            widget.match.awayTeam,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _translateStatKey(String key) {
    final translations = {
      'Ball Possession': 'Držení míče',
      'Total Shots': 'Celkem střel',
      'Shots on Goal': 'Střely na branku',
      'Shots off Goal': 'Střely vedle',
      'Shots insidebox': 'Střely v pokutovém území',
      'Shots outsidebox': 'Střely mimo pokutové území',
      'Shots blocked': 'Zablokované střely',
      'Corner Kicks': 'Rohové kopy',
      'Offsides': 'Ofsajdy',
      'Goalkeeper Saves': 'Zákroky brankáře',
      'Fouls': 'Fauly',
      'Yellow Cards': 'Žluté karty',
      'Red Cards': 'Červené karty',
      'Total Passes': 'Celkem přihrávek',
      'Passes accurate': 'Přesné přihrávky',
      'Passes %': 'Úspěšnost přihrávek',
    };
    return translations[key] ?? key;
  }

  Widget _buildLineupsTab() {
    if (_matchDetails == null) {
      return const Center(child: Text('Sestavy nejsou k dispozici.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Domácí tým
          _buildTeamLineup(
            widget.match.homeTeam,
            widget.match.homeLogo,
            _matchDetails!.homeLineup,
            true,
          ),
          const SizedBox(height: 24),
          // Hostující tým
          _buildTeamLineup(
            widget.match.awayTeam,
            widget.match.awayLogo,
            _matchDetails!.awayLineup,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLineup(String teamName, String teamLogo, Lineup lineup, bool isHome) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hlavička týmu
            Row(
              children: [
                if (teamLogo.isNotEmpty)
                  Image.network(
                    teamLogo,
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 32),
                  ),
                if (teamLogo.isNotEmpty) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teamName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E5F44),
                    ),
                  ),
                ),
                if (lineup.formation.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3E5F44).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lineup.formation,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E5F44),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Základní sestava
            if (lineup.startingXI.isNotEmpty) ...[
              const Text(
                'Základní sestava',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...lineup.startingXI.map((player) => _buildLineupPlayerCard(player)),
              const SizedBox(height: 16),
            ],
            // Náhradníci
            if (lineup.substitutes.isNotEmpty) ...[
              const Text(
                'Náhradníci',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...lineup.substitutes.map((player) => _buildLineupPlayerCard(player)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineupPlayerCard(LineupPlayer player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Číslo dresu
            if (player.number > 0)
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E5F44).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${player.number}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E5F44),
                  ),
                ),
              ),
            if (player.number > 0) const SizedBox(width: 12),
            // Jméno a pozice
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),

                  ),
                  if (player.position.isNotEmpty)
                    Text(
                      player.position,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


