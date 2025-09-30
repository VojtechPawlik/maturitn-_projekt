import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
  }

  String _formatShort(DateTime d) {
    final int day = d.day;
    final int month = d.month;
    return '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}';
  }

  List<Widget> _buildMatchList(DateTime date) {
    final List<Map<String, String>> matches = <Map<String, String>>[
      {'home': 'Sparta Praha', 'away': 'Slavia Praha', 'time': '18:00'},
      {'home': 'Chelsea', 'away': 'Arsenal', 'time': '20:45'},
      {'home': 'Real Madrid', 'away': 'Barcelona', 'time': '21:00'},
    ];

    return matches
        .map((m) => _MatchCard(
              kickoffTime: m['time']!,
              homeTeam: m['home']!,
              awayTeam: m['away']!,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime yesterday = _today.subtract(const Duration(days: 1));
    final DateTime tomorrow = _today.add(const Duration(days: 1));

    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: <Widget>[
                Tab(text: 'Včera ${_formatShort(yesterday)}'),
                Tab(text: 'Dnes ${_formatShort(_today)}'),
                Tab(text: 'Zítra ${_formatShort(tomorrow)}'),
              ],
              isScrollable: true,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: _buildMatchList(yesterday),
                ),
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: _buildMatchList(_today),
                ),
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: _buildMatchList(tomorrow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.kickoffTime,
    required this.homeTeam,
    required this.awayTeam,
  });

  final String kickoffTime;
  final String homeTeam;
  final String awayTeam;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              kickoffTime,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      homeTeam,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      awayTeam,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}


