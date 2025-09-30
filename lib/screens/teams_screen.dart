import 'package:flutter/material.dart';
import '../app_state.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  static const List<String> czechTeams = <String>[
    'Sparta Praha',
    'Slavia Praha',
    'Viktoria Plzeň',
    'Baník Ostrava',
    'Sigma Olomouc',
    'Slovan Liberec',
    'Mladá Boleslav',
    'Jablonec',
    'Hradec Králové',
    'Bohemians 1905',
    'Teplice',
    'Karviná',
    'Zlín',
    'Dynamo České Budějovice',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: czechTeams.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (BuildContext context, int index) {
        final String team = czechTeams[index];
        return _TeamTile(team: team);
      },
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team});

  final String team;

  @override
  Widget build(BuildContext context) {
    final AppState appState = AppProvider.of(context);
      final bool isFav = appState.isFavoriteTeam(team);
      return ListTile(
        title: Text(team),
        trailing: IconButton(
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_outline, color: isFav ? Colors.red : null),
          onPressed: () => appState.toggleFavoriteTeam(team),
          tooltip: isFav ? 'Odebrat z oblíbených' : 'Přidat do oblíbených',
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Otevřít tým: $team')),
          );
        },
      );
  }
}



