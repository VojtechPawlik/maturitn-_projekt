import 'package:flutter/material.dart';

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key, required this.home, required this.away, required this.kickoff});

  final String home;
  final String away;
  final String kickoff;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.home} vs ${widget.away}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const <Widget>[
            Tab(text: 'Skóre'),
            Tab(text: 'Statistiky'),
            Tab(text: 'Sestavy'),
            Tab(text: 'Hodnocení'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _ScoreTab(home: widget.home, away: widget.away, kickoff: widget.kickoff),
          const _StatsTab(),
          _LineupsTab(home: widget.home, away: widget.away),
          _RatingsTab(home: widget.home, away: widget.away),
        ],
      ),
    );
  }
}

class _ScoreTab extends StatelessWidget {
  const _ScoreTab({required this.home, required this.away, required this.kickoff});

  final String home;
  final String away;
  final String kickoff;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(child: Text(home, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)),
              Column(
                children: <Widget>[
                  Text('— : —', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Výkop $kickoff', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              Expanded(
                child: Text(
                  away,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 0),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const <Widget>[
              ListTile(leading: Icon(Icons.event), title: Text('Události zápasu se zobrazí zde')), 
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    Widget row(String l, String r, {double lVal = 50, double rVal = 50}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(l),
                Text(r),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  flex: (lVal * 10).round(),
                  child: Container(height: 6, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(3))),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: (rVal * 10).round(),
                  child: Container(height: 6, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3))),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        row('Držení míče 55%', '45%', lVal: 55, rVal: 45),
        row('Střely 12', '9', lVal: 57, rVal: 43),
        row('Na bránu 6', '3', lVal: 67, rVal: 33),
        row('Rohy 7', '4', lVal: 64, rVal: 36),
        row('Fauly 10', '14', lVal: 42, rVal: 58),
      ],
    );
  }
}

class _LineupsTab extends StatelessWidget {
  const _LineupsTab({required this.home, required this.away});

  final String home;
  final String away;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Sestava $home', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._mockPlayers().map((p) => ListTile(title: Text(p))),
        const Divider(height: 32),
        Text('Sestava $away', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._mockPlayers().map((p) => ListTile(title: Text(p))),
      ],
    );
  }

  List<String> _mockPlayers() => <String>[
        'Gólman',
        'Obránce 1',
        'Obránce 2',
        'Obránce 3',
        'Obránce 4',
        'Záložník 1',
        'Záložník 2',
        'Záložník 3',
        'Útočník 1',
        'Útočník 2',
        'Útočník 3',
      ];
}

class _RatingsTab extends StatelessWidget {
  const _RatingsTab({required this.home, required this.away});

  final String home;
  final String away;

  @override
  Widget build(BuildContext context) {
    Widget team(String name) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List<Widget>.generate(5, (int i) {
              return ListTile(
                title: Text('Hráč ${i + 1}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Icon(Icons.star, size: 18, color: Colors.amber),
                    SizedBox(width: 2),
                    Text('7.5'),
                  ],
                ),
              );
            }),
          ],
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        team(home),
        const Divider(height: 32),
        team(away),
      ],
    );
  }
}


