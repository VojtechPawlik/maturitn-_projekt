import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_sheets_service.dart';
import '../models/team.dart';
import 'team_detail_screen.dart';
import '../services/localization_service.dart';

class TeamsScreen extends StatefulWidget {
  final Set<String>? favoriteTeams;
  final Function(Set<String>)? onFavoritesChanged;
  
  const TeamsScreen({
    super.key,
    this.favoriteTeams,
    this.onFavoritesChanged,
  });

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<Team> teams = [];
  List<Team> filteredTeams = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String? selectedLeague;
  final TextEditingController _searchController = TextEditingController();
  late Set<String> favoriteTeams; // Oblíbené týmy

  @override
  void initState() {
    super.initState();
    favoriteTeams = widget.favoriteTeams ?? {};
    _loadFavorites(); // Načíst uložené oblíbené
    _loadTeams();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Aktualizovat stránku při změně jazyka
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTeams() {
    setState(() {
      filteredTeams = teams.where((team) {
        final matchesSearch = team.name.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesLeague = selectedLeague == null || selectedLeague == 'Všechny' || team.league == selectedLeague;
        return matchesSearch && matchesLeague;
      }).toList();
    });
  }

  Future<void> _loadTeams() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Načteme všechny týmy
      final teams = await Future.wait([
        GoogleSheetsService.getTeamData('List 9'),  // Arsenal
        GoogleSheetsService.getTeamData('List 10'), // Manchester City
        GoogleSheetsService.getTeamData('List 11'), // Liverpool
        GoogleSheetsService.getTeamData('List 12'), // Sunderland
        GoogleSheetsService.getTeamData('List 13'), // Bournemouth
        GoogleSheetsService.getTeamData('List 14'), // Tottenham
      ]);
      
      // Seřadit týmy podle abecedy
      teams.sort((a, b) => a.name.compareTo(b.name));
      
      setState(() {
        this.teams = teams;
        filteredTeams = teams;
        isLoading = false;
      });
      
      _filterTeams();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _toggleFavorite(String teamName) {
    setState(() {
      if (favoriteTeams.contains(teamName)) {
        favoriteTeams.remove(teamName);
      } else {
        favoriteTeams.add(teamName);
      }
    });
    
    // Notifikovat parent o změně
    widget.onFavoritesChanged?.call(favoriteTeams);
    
    // Uložit do SharedPreferences
    _saveFavorites();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          favoriteTeams.contains(teamName)
              ? '$teamName přidán do oblíbených ❤️'
              : '$teamName odebrán z oblíbených',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: favoriteTeams.contains(teamName) ? Colors.green : Colors.grey,
      ),
    );
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_teams', favoriteTeams.toList());
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFavorites = prefs.getStringList('favorite_teams') ?? [];
    setState(() {
      favoriteTeams = savedFavorites.toSet();
    });
    // Notifikovat parent o načtených datech
    widget.onFavoritesChanged?.call(favoriteTeams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate('teams')),
        backgroundColor: const Color(0xFF5E936C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeams,
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
                      Text('${LocalizationService.translate('error')}: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeams,
                        child: Text(LocalizationService.translate('try_again')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Vyhledávání
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: LocalizationService.translate('search_team'),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                    _filterTeams();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                          _filterTeams();
                        },
                      ),
                    ),
                    // Filtr podle ligy
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildLeagueChip(LocalizationService.translate('all')),
                                  ...teams.map((t) => t.league).toSet().map((league) => _buildLeagueChip(league)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Seznam týmů
                    Expanded(
                      child: filteredTeams.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    LocalizationService.translate('no_teams_found'),
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredTeams.length,
                              itemBuilder: (context, index) {
                                final team = filteredTeams[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamDetailScreen(team: team),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              if (team.logoUrl.isNotEmpty)
                                Image.network(
                                  team.logoUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.sports_soccer, size: 40);
                                  },
                                )
                              else
                                const Icon(Icons.sports_soccer, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      team.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      team.league,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              IconButton(
                                icon: Icon(
                                  favoriteTeams.contains(team.name) ? Icons.favorite : Icons.favorite_border,
                                  color: favoriteTeams.contains(team.name) ? Colors.red : null,
                                  size: 24,
                                ),
                                onPressed: () {
                                  _toggleFavorite(team.name);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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
    );
  }

  Widget _buildLeagueChip(String league) {
    final isSelected = selectedLeague == league || (league == LocalizationService.translate('all') && selectedLeague == null);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          league,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        selected: isSelected,
        selectedColor: Theme.of(context).colorScheme.primary,
        onSelected: (selected) {
          setState(() {
            selectedLeague = league == LocalizationService.translate('all') ? null : league;
          });
          _filterTeams();
        },
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}



