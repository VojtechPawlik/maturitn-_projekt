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
    _days = List<DateTime>.generate(15, (int i) => _today.add(Duration(days: i - 7)));
  }

  String _formatShort(DateTime d) {
    final int day = d.day;
    final int month = d.month;
    return '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}';
  }

  String _weekdayCzShort(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Po';
      case DateTime.tuesday:
        return 'Út';
      case DateTime.wednesday:
        return 'St';
      case DateTime.thursday:
        return 'Čt';
      case DateTime.friday:
        return 'Pá';
      case DateTime.saturday:
        return 'So';
      case DateTime.sunday:
        return 'Ne';
      default:
        return '';
    }
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
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/match',
                    arguments: <String, String>{
                      'home': m['home']!,
                      'away': m['away']!,
                      'time': m['time']!,
                    },
                  );
                },
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
                final String label = isToday ? 'Dnes ${_formatShort(d)}' : '${_weekdayCzShort(d)} ${_formatShort(d)}';
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
    this.onTap,
  });

  final String kickoffTime;
  final String homeTeam;
  final String awayTeam;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  homeTeam,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('— : —', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1A1DB954),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      kickoffTime,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      awayTeam,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
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


