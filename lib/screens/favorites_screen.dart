import 'package:flutter/material.dart';
import '../app_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppProvider.of(context);
    final List<String> favorites = app.favoriteTeams.toList()..sort();

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.favorite_border, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('Zatím nemáte žádné oblíbené týmy'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (BuildContext context, int index) {
        final String team = favorites[index];
        return ListTile(
          title: Text(team),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => app.toggleFavoriteTeam(team),
            tooltip: 'Odebrat',
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Otevřít tým: $team')),
            );
          },
        );
      },
    );
  }
}


