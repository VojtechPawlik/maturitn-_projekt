import 'package:flutter/material.dart';
import '../models/champions_league_team.dart';
import '../services/google_sheets_service.dart';

class ChampionsLeagueScreen extends StatefulWidget {
  const ChampionsLeagueScreen({super.key});

  @override
  State<ChampionsLeagueScreen> createState() => _ChampionsLeagueScreenState();
}

class _ChampionsLeagueScreenState extends State<ChampionsLeagueScreen> {
  List<ChampionsLeagueTeam> teams = [];
  bool isLoading = true;
  String? error;
  String competitionLogo = '';

  @override
  void initState() {
    super.initState();
    loadData();
    loadLogo();
  }

  Future<void> loadLogo() async {
    final logo = await GoogleSheetsService.getCompetitionLogo('List 8', 'A2');
    setState(() {
      competitionLogo = logo;
    });
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await GoogleSheetsService.getChampionsLeagueData();
      setState(() {
        teams = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (competitionLogo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.network(
                  competitionLogo,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.emoji_events, size: 24);
                  },
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.emoji_events, size: 24),
              ),
            const Text('Liga mistrů'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Chyba: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadData,
                        child: const Text('Zkusit znovu'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width,
                          ),
                          child: DataTable(
                            horizontalMargin: 8,
                            columnSpacing: 8,
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 56,
                            headingRowColor: MaterialStateProperty.all(
                              Theme.of(context).colorScheme.primaryContainer,
                            ),
                            columns: const [
                              DataColumn(label: SizedBox(width: 40, child: Center(child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: Text('Tým', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: SizedBox(width: 30, child: Center(child: Text('Z', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 50, child: Center(child: Text('G', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 30, child: Center(child: Text('B', style: TextStyle(fontWeight: FontWeight.bold))))),
                            ],
                            rows: teams.map((team) {
                              Color? indicatorColor;
                              if (team.color.isNotEmpty) {
                                try {
                                  String colorString = team.color.replaceAll('#', '');
                                  if (colorString.length == 6) {
                                    indicatorColor = Color(int.parse('FF$colorString', radix: 16));
                                  }
                                } catch (e) {}
                              }
                              
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        if (indicatorColor != null)
                                          Container(
                                            width: 4,
                                            height: 30,
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: indicatorColor,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          )
                                        else
                                          const SizedBox(width: 12),
                                        Expanded(
                                          child: Center(
                                            child: Text(team.position),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (team.logo.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Image.network(
                                              team.logo,
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.sports_soccer, size: 20);
                                              },
                                            ),
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Icon(Icons.sports_soccer, size: 20),
                                          ),
                                        Expanded(
                                          child: Text(
                                            team.team,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Center(child: Text(team.matches))),
                                  DataCell(Center(child: Text(team.scoresStr))),
                                  DataCell(Center(child: Text(team.points, style: const TextStyle(fontWeight: FontWeight.bold)))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem('Postup do osmifinále', const Color(0xFF4CAF50)),
                            _buildLegendItem('Postup do 1/16-finále', const Color(0xFF2196F3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
