import 'package:flutter/material.dart';
import 'champions_league_screen.dart';

class CompetitionsScreen extends StatelessWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soutěže'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CompetitionCard(
            title: 'Liga mistrů',
            subtitle: 'UEFA Champions League',
            icon: Icons.stars,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChampionsLeagueScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'Premier League',
            subtitle: 'Anglická liga',
            icon: Icons.sports_soccer,
            color: Colors.purple,
            onTap: () {
              // TODO: Přidat obrazovku pro Premier League
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'La Liga',
            subtitle: 'Španělská liga',
            icon: Icons.sports_soccer,
            color: Colors.orange,
            onTap: () {
              // TODO: Přidat obrazovku pro La Liga
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'Bundesliga',
            subtitle: 'Německá liga',
            icon: Icons.sports_soccer,
            color: Colors.red,
            onTap: () {
              // TODO: Přidat obrazovku pro Bundesliga
            },
          ),
        ],
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CompetitionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


