import 'package:flutter/material.dart';
import '../models/team.dart';
import 'team_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final Set<String> favoriteTeams;
  final List<Team> allTeams;

  const FavoritesScreen({
    super.key,
    required this.favoriteTeams,
    required this.allTeams,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final favoriteTeamsList = widget.allTeams
        .where((team) => widget.favoriteTeams.contains(team.name))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oblíbené týmy'),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: favoriteTeamsList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Žádné oblíbené týmy',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Přidej týmy do oblíbených kliknutím na ❤️',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favoriteTeamsList.length,
              itemBuilder: (context, index) {
                final team = favoriteTeamsList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF5E936C),
                      child: Text(
                        team.name.substring(0, 2).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      team.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Liga: ${team.league}'),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: Colors.red),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios),
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
    );
  }
}


