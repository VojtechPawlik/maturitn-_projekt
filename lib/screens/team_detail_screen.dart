import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

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
  List<Player> _players = [];
  bool _isLoadingPlayers = false;
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
    setState(() => _isLoadingPlayers = true);
    
    try {
      // Nejdříve zkusit načíst z Firestore
      final players = await _firestoreService.getPlayers(
        teamId: widget.team.id,
        season: widget.team.season,
      );

      if (players.isEmpty && widget.team.apiTeamId > 0) {
        // Pokud nejsou v Firestore, načíst z API a uložit
        await _firestoreService.fetchAndSavePlayers(
          teamId: widget.team.id,
          apiTeamId: widget.team.apiTeamId,
          season: widget.team.season,
        );
        
        // Znovu načíst z Firestore
        final updatedPlayers = await _firestoreService.getPlayers(
          teamId: widget.team.id,
          season: widget.team.season,
        );
        
        setState(() {
          _players = updatedPlayers;
          _isLoadingPlayers = false;
        });
      } else {
        setState(() {
          _players = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingPlayers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.name),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Hlavička s logem
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF3E5F44),
                  const Color(0xFF3E5F44).withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                // Logo týmu
                widget.team.logoUrl.startsWith('http')
                    ? Image.network(
                        widget.team.logoUrl,
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.sports_soccer,
                            size: 120,
                            color: Colors.white,
                          );
                        },
                      )
                    : const Icon(
                        Icons.sports_soccer,
                        size: 120,
                        color: Colors.white,
                      ),
                const SizedBox(height: 16),
                Text(
                  widget.team.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.team.league,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // TabBar pod logem
          Container(
            color: const Color(0xFF3E5F44),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
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
                    widget.team.season > 0;

    if (!hasInfo) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Základní informace budou brzy dostupné',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.team.league.isNotEmpty) ...[
            _buildSectionTitle('Liga'),
            _buildInfoCard(
              icon: Icons.emoji_events,
              title: 'Název ligy',
              value: widget.team.league,
            ),
          ],
          if (widget.team.country.isNotEmpty) ...[
            _buildSectionTitle('Země'),
            _buildInfoCard(
              icon: Icons.flag,
              title: 'Země týmu',
              value: widget.team.country,
            ),
          ],
          if (widget.team.season > 0) ...[
            _buildSectionTitle('Sezóna'),
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Sezóna',
              value: widget.team.season.toString(),
            ),
          ],
          if (widget.team.stadium.isNotEmpty || widget.team.city.isNotEmpty || widget.team.stadiumCountry.isNotEmpty) ...[
            _buildSectionTitle('Stadion'),
            if (widget.team.stadium.isNotEmpty)
              _buildInfoCard(
                icon: Icons.stadium,
                title: 'Název stadionu',
                value: widget.team.stadium,
              ),
            if (widget.team.city.isNotEmpty)
              _buildInfoCard(
                icon: Icons.location_city,
                title: 'Město',
                value: widget.team.city,
              ),
            if (widget.team.stadiumCountry.isNotEmpty)
              _buildInfoCard(
                icon: Icons.public,
                title: 'Země stadionu',
                value: widget.team.stadiumCountry,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3E5F44),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3E5F44).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3E5F44),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
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
        child: CircularProgressIndicator(),
      );
    }

    if (_players.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Žádní hráči nejsou k dispozici',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        return _buildPlayerCard(_players[index]);
      },
    );
  }

  Widget _buildPlayerCard(Player player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF3E5F44).withOpacity(0.1),
          backgroundImage: player.photo.isNotEmpty && player.photo.startsWith('http')
              ? NetworkImage(player.photo)
              : null,
          child: player.photo.isEmpty || !player.photo.startsWith('http')
              ? Text(
                  player.number > 0 ? player.number.toString() : player.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E5F44),
                  ),
                )
              : null,
        ),
        title: Text(
          player.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (player.position.isNotEmpty)
              Text(
                'Pozice: ${player.position}',
                style: const TextStyle(fontSize: 13),
              ),
            if (player.age > 0)
              Text(
                'Věk: ${player.age} let',
                style: const TextStyle(fontSize: 13),
              ),
            if (player.nationality.isNotEmpty)
              Text(
                'Národnost: ${player.nationality}',
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ),
        trailing: player.number > 0
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E5F44),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    player.number.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
