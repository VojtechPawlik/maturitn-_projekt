import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'team_detail_screen.dart';

class TeamsScreen extends StatefulWidget {
  final Set<String> favoriteTeams;
  final Function(Set<String>) onFavoritesChanged;
  final bool isLoggedIn;

  const TeamsScreen({
    super.key,
    required this.favoriteTeams,
    required this.onFavoritesChanged,
    required this.isLoggedIn,
  });

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  List<String> _availableLeagues = [];
  String? _selectedLeague;
  bool _isLoading = true;
  bool _hasSearchText = false;
  bool _sortDescending = false; // false = A-Z, true = Z-A

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _searchController.addListener(() {
      setState(() {
        _hasSearchText = _searchController.text.isNotEmpty;
      });
      _filterTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _firestoreService.getTeams();
      
      // Získat seznam dostupných lig
      final leagues = teams
          .map((team) => team.league)
          .toSet()
          .toList();
      leagues.sort();
      
      // Seřadit týmy podle názvu (A-Z)
      teams.sort((a, b) => a.name.compareTo(b.name));
      
      setState(() {
        _teams = teams;
        _filteredTeams = teams;
        _availableLeagues = leagues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTeams() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      var filtered = _teams.where((team) {
        final matchesSearch = query.isEmpty || 
            team.name.toLowerCase().contains(query) ||
            team.league.toLowerCase().contains(query);
        
        final matchesLeague = _selectedLeague == null || 
            team.league == _selectedLeague;
        
        return matchesSearch && matchesLeague;
      }).toList();
      
      // Seřadit týmy podle názvu
      filtered.sort((a, b) {
        final comparison = a.name.compareTo(b.name);
        return _sortDescending ? -comparison : comparison;
      });
      
      _filteredTeams = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Načítám týmy...'),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Žádné týmy nenalezeny',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadTeams,
              child: const Text('Zkusit znovu'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Vyhledávací pole a filtr
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Vyhledávací pole
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Vyhledat tým...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _hasSearchText
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 12),
              // Filtr podle ligy a řazení
              Row(
                children: [
                  // Filtr podle ligy
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[100],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLeague,
                          isExpanded: true,
                          hint: const Row(
                            children: [
                              Icon(Icons.filter_list, size: 20),
                              SizedBox(width: 8),
                              Text('Všechny ligy'),
                            ],
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Všechny ligy'),
                            ),
                            ..._availableLeagues.map((league) {
                              return DropdownMenuItem<String>(
                                value: league,
                                child: Text(league),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedLeague = value;
                            });
                            _filterTeams();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tlačítko pro řazení
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: _sortDescending ? Colors.blue[50] : Colors.grey[100],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 20,
                        color: _sortDescending ? Colors.blue[700] : Colors.grey[700],
                      ),
                      tooltip: _sortDescending ? 'Řadit A-Z' : 'Řadit Z-A',
                      onPressed: () {
                        setState(() {
                          _sortDescending = !_sortDescending;
                        });
                        _filterTeams();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Seznam týmů
        Expanded(
          child: _filteredTeams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Žádné týmy nenalezeny',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (_hasSearchText || _selectedLeague != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedLeague = null;
                              _hasSearchText = false;
                            });
                            _filterTeams();
                          },
                          child: const Text('Zrušit filtry'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredTeams.length,
                  itemBuilder: (context, index) {
                    final team = _filteredTeams[index];
                    final isFavorite = widget.favoriteTeams.contains(team.name);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: team.logoUrl.startsWith('http')
                            ? Image.network(
                                team.logoUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.sports_soccer, size: 40);
                                },
                              )
                            : const Icon(Icons.sports_soccer, size: 40),
                        title: Text(
                          team.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(team.league),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: widget.isLoggedIn
                                    ? (isFavorite ? Colors.red : Colors.grey)
                                    : Colors.grey[300],
                              ),
                              onPressed: widget.isLoggedIn
                                  ? () {
                                final newFavorites = Set<String>.from(widget.favoriteTeams);
                                if (isFavorite) {
                                  newFavorites.remove(team.name);
                                } else {
                                  newFavorites.add(team.name);
                                }
                                widget.onFavoritesChanged(newFavorites);
                                    }
                                  : null, // Zakázat kliknutí, pokud není přihlášený
                              tooltip: widget.isLoggedIn
                                  ? (isFavorite ? 'Odebrat z oblíbených' : 'Přidat do oblíbených')
                                  : 'Pro přidání do oblíbených se musíte přihlásit',
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamDetailScreen(team: team),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}



