import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/api_football_service.dart';

class StandingsScreen extends StatefulWidget {
  final String leagueId;
  final String leagueName;
  final int apiLeagueId;

  const StandingsScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
    required this.apiLeagueId,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<StandingTeam> _standings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    setState(() => _isLoading = true);
    
    try {
      // Načíst z Firebase
      final standings = await _firestoreService.getStandings(
        leagueId: widget.leagueId,
        season: 2024,
      );

      setState(() {
        _standings = standings;
        _isLoading = false;
      });

      // Pokud nejsou data, načti z API
      if (standings.isEmpty) {
        await _refreshStandings();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStandings() async {
    setState(() => _isRefreshing = true);
    
    try {
      // Načíst nová data z API a uložit do Firebase
      await _firestoreService.fetchAndSaveStandings(
        leagueId: widget.leagueId,
        apiLeagueId: widget.apiLeagueId,
        season: 2024,
      );

      // Znovu načíst z Firebase
      final standings = await _firestoreService.getStandings(
        leagueId: widget.leagueId,
        season: 2024,
      );

      setState(() {
        _standings = standings;
        _isRefreshing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tabulka aktualizována!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isRefreshing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshStandings,
            tooltip: 'Obnovit tabulku',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _standings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_chart, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Žádná data'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _refreshStandings,
                        child: const Text('Načíst tabulku'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Tabulka
                      DataTable(
                        columnSpacing: 16,
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFF3E5F44).withOpacity(0.1),
                        ),
                        columns: const [
                          DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Tým', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Z', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('V', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Skóre', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _standings.map((team) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: team.position <= 4
                                        ? Colors.green.withOpacity(0.2)
                                        : team.position >= 18
                                            ? Colors.red.withOpacity(0.2)
                                            : null,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    team.position.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: team.position <= 4
                                          ? Colors.green.shade700
                                          : team.position >= 18
                                              ? Colors.red.shade700
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Image.network(
                                      team.teamLogo,
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.sports_soccer, size: 20);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        team.teamName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(team.played.toString())),
                              DataCell(Text(team.won.toString())),
                              DataCell(Text(team.drawn.toString())),
                              DataCell(Text(team.lost.toString())),
                              DataCell(Text('${team.goalsFor}:${team.goalsAgainst}')),
                              DataCell(
                                Text(
                                  team.points.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Legenda
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Legenda:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildLegendItem(Colors.green, '1-4: Champions League'),
                            _buildLegendItem(Colors.red, '18-20: Sestup'),
                            const SizedBox(height: 8),
                            const Text(
                              'Z = Zápasy, V = Výhry, R = Remízy, P = Prohry, B = Body',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
