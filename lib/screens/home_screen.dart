import 'package:flutter/material.dart';
import '../services/fixtures_service.dart';
import '../services/notifications_service.dart';

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

  Widget _buildDayContent(DateTime date) {
    return FutureBuilder<List<Fixture>>(
      future: FixturesService.instance.loadCzechFixtures(date),
      builder: (BuildContext context, AsyncSnapshot<List<Fixture>> snap) {
        final List<Widget> children = <Widget>[const _LeagueHeader(title: 'FORTUNA:LIGA'), const Divider(height: 0)];
        if (snap.connectionState != ConnectionState.done) {
          children.add(const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())));
        } else if (snap.hasError) {
          children.add(Padding(padding: const EdgeInsets.all(16), child: Text('Chyba načítání zápasů')));
        } else {
          final List<Fixture> fixtures = snap.data ?? <Fixture>[];
          children.addAll(
            fixtures
                .map((Fixture f) => _MatchRow(
                      kickoffTime: _formatTime(f.kickoff),
                      homeTeam: f.home,
                      awayTeam: f.away,
                      onTap: () {
                        Navigator.of(context).pushNamed('/match', arguments: <String, String>{'home': f.home, 'away': f.away, 'time': _formatTime(f.kickoff)});
                      },
                      onNotify: () => NotificationsService.instance.scheduleMatchNotification(
                        id: f.kickoff.millisecondsSinceEpoch ~/ 1000,
                        title: '${f.home} vs ${f.away}',
                        body: 'Začátek zápasu v ${_formatTime(f.kickoff)}',
                        when: f.kickoff,
                      ),
                    ))
                .expand<Widget>((Widget row) => <Widget>[row, const Divider(height: 0)])
                .toList(),
          );
        }

        return ListView(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: children);
      },
    );
  }

  String _formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0') }';

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
            child: TabBarView(children: _days.map<Widget>((DateTime d) => _buildDayContent(d)).toList()),
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
    this.onNotify,
  });

  final String kickoffTime;
  final String homeTeam;
  final String awayTeam;

  final VoidCallback? onTap;
  final VoidCallback? onNotify;

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
                  if (onNotify != null) ...<Widget>[
                    const SizedBox(height: 6),
                    TextButton.icon(onPressed: onNotify, icon: const Icon(Icons.notifications_active_outlined, size: 18), label: const Text('Upozornit')),
                  ],
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


