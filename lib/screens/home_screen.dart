import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DateTime _today;
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _days = List<DateTime>.generate(5, (int i) => _today.add(Duration(days: i - 2)));
  }

  String _formatShort(DateTime d) {
    final int day = d.day;
    final int month = d.month;
    return '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}';
  }

  List<Widget> _buildMatchList(DateTime date) {
    // Czech Fortuna Liga sample fixtures only
    final List<Map<String, String>> matches = <Map<String, String>>[
      {'home': 'Sparta Praha', 'away': 'Slavia Praha', 'time': '18:00'},
      {'home': 'Viktoria Plzeň', 'away': 'Baník Ostrava', 'time': '16:30'},
      {'home': 'Sigma Olomouc', 'away': 'Slovan Liberec', 'time': '15:00'},
      {'home': 'Jablonec', 'away': 'FK Teplice', 'time': '17:30'},
      {'home': 'Hradec Králové', 'away': 'Mladá Boleslav', 'time': '14:00'},
      {'home': 'Zlín', 'away': 'Karviná', 'time': '13:00'},
    ];

    return <Widget>[
      const _LeagueHeader(title: 'FORTUNA:LIGA'),
      const Divider(height: 0),
      ...matches
          .map((m) => _MatchRow(
                kickoffTime: m['time']!,
                homeTeam: m['home']!,
                awayTeam: m['away']!,
              ))
          .expand<Widget>((row) => <Widget>[row, const Divider(height: 0)])
          .toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: <Widget>[
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _days.map<Widget>((DateTime d) {
                final bool isToday = d.year == _today.year && d.month == _today.month && d.day == _today.day;
                final String label = isToday ? 'Dnes' : _formatShort(d);
                return Tab(text: label);
              }).toList(),
              isScrollable: true,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: _days.map<Widget>((DateTime d) {
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: _buildMatchList(d),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.kickoffTime,
    required this.homeTeam,
    required this.awayTeam,
  });

  final String kickoffTime;
  final String homeTeam;
  final String awayTeam;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0x1A1DB954),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              kickoffTime,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  homeTeam,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  awayTeam,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            alignment: Alignment.centerRight,
            child: Text(
              '—', // score placeholder
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _LeagueHeader extends StatelessWidget {
  const _LeagueHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


