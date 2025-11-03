import 'package:flutter/material.dart';
import '../models/la_liga_team.dart';
import '../services/google_sheets_service.dart';

class LaLigaScreen extends StatefulWidget {
  const LaLigaScreen({super.key});

  @override
  State<LaLigaScreen> createState() => _LaLigaScreenState();
}

class _LaLigaScreenState extends State<LaLigaScreen> {
  List<LaLigaTeam> teams = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await GoogleSheetsService.getLaLigaData();
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
        title: const Text('La Liga'),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.primaryContainer,
                        ),
                        columns: const [
                          DataColumn(label: Text('Poz.', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Logo', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Tým', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Z', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('V', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Skóre', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('GD', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Body', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: teams.map((team) {
                          return DataRow(
                            cells: [
                              DataCell(Text(team.position)),
                              DataCell(
                                team.logo.isNotEmpty
                                    ? Image.network(
                                        team.logo,
                                        width: 24,
                                        height: 24,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.sports_soccer, size: 24);
                                        },
                                      )
                                    : const Icon(Icons.sports_soccer, size: 24),
                              ),
                              DataCell(Text(team.team, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(team.matches)),
                              DataCell(Text(team.wins)),
                              DataCell(Text(team.draws)),
                              DataCell(Text(team.losses)),
                              DataCell(Text(team.scoresStr)),
                              DataCell(Text(team.goalDifference)),
                              DataCell(Text(team.points, style: const TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }
}
