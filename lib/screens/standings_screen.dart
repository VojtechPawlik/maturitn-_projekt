import 'dart:async';
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
  Timer? _autoUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadStandings();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    super.dispose();
  }

  // Spustit automatickou aktualizaci každých 6 hodin (360 minut)
  void _startAutoUpdate() {
    _autoUpdateTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _refreshStandings(silent: true),
    );
  }

  Future<void> _loadStandings() async {
    setState(() => _isLoading = true);
    
    try {
      // Aktuální sezóna
      final currentSeason = 2023;
      
      // Načíst z Firebase
      final standings = await _firestoreService.getStandings(
        leagueId: widget.leagueId,
        season: currentSeason,
      );

      setState(() {
        _standings = standings;
        _isLoading = false;
      });

      // Pokud nejsou data, načti z API
      if (standings.isEmpty) {
        await _refreshStandings();
      } else {
        // Pokud data existují, aktualizovat na pozadí (bez zobrazení loading)
        _refreshStandings(silent: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Chyba při načítání tabulky: $e');
      // Zkusit načíst z API jako fallback
      await _refreshStandings();
    }
  }

  Future<void> _refreshStandings({bool silent = false}) async {
    if (!silent) {
      setState(() => _isRefreshing = true);
    }
    
    try {
      // Aktuální sezóna
      final currentSeason = 2023;
      
      // Načíst nová data z API a uložit do Firebase
      await _firestoreService.fetchAndSaveStandings(
        leagueId: widget.leagueId,
        apiLeagueId: widget.apiLeagueId,
        season: currentSeason,
      );

      // Znovu načíst z Firebase
      final standings = await _firestoreService.getStandings(
        leagueId: widget.leagueId,
        season: currentSeason,
      );

      if (mounted) {
        setState(() {
          _standings = standings;
          if (!silent) {
            _isRefreshing = false;
          }
        });

        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Tabulka aktualizována!'),
              duration: Duration(seconds: 2),
            ),
          );
          print('✅ Tabulka aktualizována!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _isRefreshing = false;
          }
        });
        
        // Logovat chybu do konzole
        print('❌ Chyba při aktualizaci tabulky: $e');
        
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Chyba při aktualizaci: ${e.toString()}'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Zkusit znovu',
                onPressed: () => _refreshStandings(),
              ),
            ),
          );
        }
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
                          Table(
                        columnWidths: {
                          0: FixedColumnWidth(40),  // #
                          1: FlexColumnWidth(3.0),  // Tým - flexibilní
                          2: FixedColumnWidth(35),  // Z
                          3: FixedColumnWidth(60),  // G
                          4: FixedColumnWidth(40),  // B
                        },
                        children: [
                          // Header row
                          TableRow(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3E5F44).withOpacity(0.1),
                            ),
                            children: const [
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('#', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Tým', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Z', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('G', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('B', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                              ),
                            ],
                          ),
                          // Data rows
                          ..._standings.map((team) {
                            return TableRow(
                              children: [
                                TableCell(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: team.position <= 4
                                          ? Colors.green.withOpacity(0.2)
                                          : team.position >= 18
                                              ? Colors.red.withOpacity(0.2)
                                              : null,
                                    ),
                                    child: Text(
                                      team.position.toString(),
                                      textAlign: TextAlign.center,
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
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
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
                                        Expanded(
                                          child: Text(
                                            team.teamName,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: team.teamName.length > 20 ? 11 : 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      team.played.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                    child: Text(
                                      '${team.goalsFor}:${team.goalsAgainst}',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      team.points.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                          const SizedBox(height: 16),
                          // Legenda
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(Colors.green, '1-4: Kvalifikace'),
                                _buildLegendItem(Colors.red, '18-20: Sestup'),
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
