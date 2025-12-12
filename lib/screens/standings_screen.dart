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

  @override
  void initState() {
    super.initState();
    _loadStandings();
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
        try {
          final currentSeason = 2023;
          await _firestoreService.fetchAndSaveStandings(
            leagueId: widget.leagueId,
            apiLeagueId: widget.apiLeagueId,
            season: currentSeason,
          );
          
          final newStandings = await _firestoreService.getStandings(
            leagueId: widget.leagueId,
            season: currentSeason,
          );
          
          if (mounted) {
            setState(() {
              _standings = newStandings;
            });
          }
        } catch (e) {
          // Ignorovat chybu při načítání z API
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _standings.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_chart, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Žádná data'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Table(
                        columnWidths: {
                          0: FixedColumnWidth(50),  // #
                          1: FlexColumnWidth(3.0),  // Tým - flexibilní
                          2: FixedColumnWidth(40),  // Z
                          3: FixedColumnWidth(70),  // G
                          4: FixedColumnWidth(50),  // B
                        },
                        children: [
                          // Header row
                          TableRow(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3E5F44).withOpacity(0.1),
                            ),
                            children: const [
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                ),
                              ),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  child: Text('Tým', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  child: Text('Z', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                ),
                              ),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  child: Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                ),
                              ),
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  child: Text('B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                ),
                              ),
                            ],
                          ),
                          // Data rows
                          ..._standings.map((team) {
                            return TableRow(
                              children: [
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (team.position <= 4 || team.position >= 18)
                                          Container(
                                            width: 3,
                                            height: 20,
                                            margin: const EdgeInsets.only(right: 6),
                                            decoration: BoxDecoration(
                                              color: team.position <= 4
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        Text(
                                          team.position.toString(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: team.position <= 4
                                                ? Colors.green.shade700
                                                : team.position >= 18
                                                    ? Colors.red.shade700
                                                    : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                    child: Text(
                                      team.played.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                    child: Text(
                                      '${team.goalsFor}:${team.goalsAgainst}',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                    child: Text(
                                      team.points.toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
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
    Color barColor;
    if (color == Colors.green) {
      barColor = Colors.green.shade700;
    } else if (color == Colors.red) {
      barColor = Colors.red.shade700;
    } else {
      barColor = color;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
