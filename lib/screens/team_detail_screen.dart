import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/api_football_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;

  const TeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiFootballService _apiFootballService = ApiFootballService();
  List<Player> _players = [];
  bool _isLoadingPlayers = false;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoadingPlayers = true;
      _errorMessage = null;
    });
    
    try {
      // Nejdříve zkusit načíst z Firestore
      List<Player> players = await _firestoreService.getPlayers(
        teamId: widget.team.id,
        season: widget.team.season,
      );

      // Pokud nejsou v Firestore a tým má API ID, načíst z API
      if (players.isEmpty) {
        if (widget.team.apiTeamId > 0) {
        try {
            // Inicializovat API klíč
            await _apiFootballService.initializeApiKey();
            
            // Načíst a uložit hráče z API
          await _firestoreService.fetchAndSavePlayers(
            teamId: widget.team.id,
            apiTeamId: widget.team.apiTeamId,
            season: widget.team.season,
          );
          
            // Znovu načíst z Firestore po uložení
          players = await _firestoreService.getPlayers(
            teamId: widget.team.id,
            season: widget.team.season,
          );
            
            if (players.isEmpty) {
              setState(() {
                _errorMessage = 'Nepodařilo se načíst hráče z API. Zkuste to později.';
              });
            }
        } catch (e) {
            // Chyba při načítání z API
            setState(() {
              _errorMessage = 'Chyba při načítání hráčů: ${e.toString()}';
            });
          }
        } else {
          // Tým nemá API ID
          setState(() {
            _errorMessage = 'Tento tým nemá nastavené API ID. Hráči nemohou být načteni.';
          });
        }
      }
      
      setState(() {
        _players = players;
        _isLoadingPlayers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlayers = false;
        _players = [];
        _errorMessage = 'Neočekávaná chyba: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
            children: [
              // Hlavička s logem
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.25 + MediaQuery.of(context).padding.top,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E3A2E),
                      const Color(0xFF2D4A3E),
                      const Color(0xFF3E5F44),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo týmu
                          widget.team.logoUrl.startsWith('http')
                              ? Image.network(
                                  widget.team.logoUrl,
                                  height: 140,
                                  width: 140,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.sports_soccer,
                                      size: 140,
                                      color: Colors.white,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.sports_soccer,
                                  size: 140,
                                  color: Colors.white,
                                ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: Text(
                              widget.team.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
              // TabBar pod logem
              Container(
                color: const Color(0xFF3E5F44).withOpacity(0.1),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF3E5F44),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF3E5F44),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontFamily: 'Roboto',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    fontFamily: 'Roboto',
                  ),
                  tabs: const [
                    Tab(text: 'Informace'),
                    Tab(text: 'Hráči'),
                  ],
                ),
              ),
              // Obsah záložek
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Záložka 1: Základní informace
                    _buildInfoTab(),
                    // Záložka 2: Sestavy
                    _buildPlayersTab(),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildInfoTab() {
    final hasInfo = widget.team.country.isNotEmpty || 
                    widget.team.stadium.isNotEmpty || 
                    widget.team.city.isNotEmpty ||
                    widget.team.stadiumCountry.isNotEmpty ||
                    widget.team.season > 0 ||
                    widget.team.league.isNotEmpty;

    if (!hasInfo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Základní informace budou brzy dostupné',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.team.league.isNotEmpty)
            _buildSimpleInfoCard(
              icon: Icons.emoji_events,
              iconColor: Colors.grey[600]!,
              label: 'Liga',
              value: widget.team.league,
            ),
          if (widget.team.season > 0)
            _buildSimpleInfoCard(
              icon: Icons.calendar_today,
              iconColor: Colors.grey[600]!,
              label: 'Sezóna',
              value: '${widget.team.season}/${widget.team.season + 1}',
            ),
          if (widget.team.country.isNotEmpty)
            _buildSimpleInfoCard(
              icon: Icons.flag,
              iconColor: Colors.grey[600]!,
              label: 'Země',
              value: widget.team.country,
            ),
          if (widget.team.city.isNotEmpty)
            _buildSimpleInfoCard(
              icon: Icons.location_city,
              iconColor: Colors.grey[600]!,
              label: 'Město',
              value: widget.team.city,
            ),
          if (widget.team.stadium.isNotEmpty)
            _buildSimpleInfoCard(
              icon: Icons.stadium,
              iconColor: Colors.grey[600]!,
              label: 'Stadion',
              value: widget.team.stadium,
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  Widget _buildPlayersTab() {
    if (_isLoadingPlayers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Načítám hráče...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Žádní hráči nejsou k dispozici',
                style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
                textAlign: TextAlign.center,
              ),
              if (widget.team.apiTeamId > 0 && _errorMessage != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadPlayers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Zkusit znovu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E5F44),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Seskládat hráče podle pozic
    final playersByPosition = <String, List<Player>>{};
    for (var player in _players) {
      final position = _normalizePosition(player.position);
      if (!playersByPosition.containsKey(position)) {
        playersByPosition[position] = [];
      }
      playersByPosition[position]!.add(player);
    }

    // Pokud nejsou žádné pozice, zobrazit všechny hráče v jedné sekci
    if (playersByPosition.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          return _buildPlayerCard(_players[index]);
        },
      );
    }

    // Seřadit pozice podle priority
    final positionOrder = ['Brankář', 'Obránce', 'Záložník', 'Útočník', 'Jiné'];
    final sortedPositions = playersByPosition.keys.toList()
      ..sort((a, b) {
        final indexA = positionOrder.indexOf(a);
        final indexB = positionOrder.indexOf(b);
        if (indexA == -1 && indexB == -1) return a.compareTo(b);
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedPositions.length,
      itemBuilder: (context, index) {
        final position = sortedPositions[index];
        final players = playersByPosition[position]!;
        return _buildPositionSection(position, players);
      },
    );
  }

  String _normalizePosition(String position) {
    if (position.isEmpty) {
      return 'Jiné';
    }
    final pos = position.toLowerCase();
    if (pos.contains('goalkeeper') || pos.contains('brankář') || pos == 'g') {
      return 'Brankář';
    } else if (pos.contains('defender') || pos.contains('obránce') || pos.contains('back') || pos == 'd') {
      return 'Obránce';
    } else if (pos.contains('midfielder') || pos.contains('záložník') || pos.contains('midfield') || pos == 'm') {
      return 'Záložník';
    } else if (pos.contains('attacker') || pos.contains('útočník') || pos.contains('forward') || pos.contains('striker') || pos.contains('winger') || pos == 'f') {
      return 'Útočník';
    }
    return 'Jiné';
  }

  Widget _buildPositionSection(String position, List<Player> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            position,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E5F44),
            ),
          ),
        ),
        ...players.map((player) => _buildPlayerCard(player)),
      ],
    );
  }

  Widget _buildPlayerCard(Player player) {
    // Rozdělit jméno na jméno a příjmení
    final nameParts = player.name.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Fotka hráče
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3E5F44).withOpacity(0.1),
              ),
              child: player.photo.isNotEmpty && player.photo.startsWith('http')
                  ? ClipOval(
                      child: Image.network(
                        player.photo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E5F44),
                                fontSize: 20,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3E5F44),
                          fontSize: 20,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Jméno a příjmení
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jméno a příjmení vedle sebe
                  if (firstName.isNotEmpty || lastName.isNotEmpty)
                    Text(
                      '$firstName $lastName'.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  // Věk hráče
                  if (player.age > 0)
                    Text(
                      '${player.age} let',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Číslo dresu
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Číslo dresu v ikoně dresu
                if (player.number > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Obrázek dresu jako pozadí
                        Image.asset(
                          'assets/images/jersey.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback, pokud se obrázek nenačte
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3E5F44),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            );
                          },
                        ),
                        // Číslo dresu uprostřed
                        Text(
                          '${player.number}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E5F44),
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          ),
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
  }

}
