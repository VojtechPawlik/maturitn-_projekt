import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'team_detail_screen.dart';

class TeamsScreen extends StatefulWidget {
  final Set<String> favoriteTeams;
  final Function(Set<String>) onFavoritesChanged;

  const TeamsScreen({
    super.key,
    required this.favoriteTeams,
    required this.onFavoritesChanged,
  });

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Team> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _firestoreService.getTeams();
      
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
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
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    final newFavorites = Set<String>.from(widget.favoriteTeams);
                    if (isFavorite) {
                      newFavorites.remove(team.name);
                    } else {
                      newFavorites.add(team.name);
                    }
                    widget.onFavoritesChanged(newFavorites);
                  },
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
    );
  }
}



