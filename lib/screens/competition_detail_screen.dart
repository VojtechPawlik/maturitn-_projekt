import 'package:flutter/material.dart';

class CompetitionDetailScreen extends StatefulWidget {
  const CompetitionDetailScreen({super.key, required this.title});

  final String title;

  @override
  State<CompetitionDetailScreen> createState() => _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends State<CompetitionDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Tabulka'),
            Tab(text: 'Pavouk'),
          ],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const <Widget>[
          _LeagueTablePlaceholder(),
          _BracketPlaceholder(),
        ],
      ),
    );
  }
}

class _LeagueTablePlaceholder extends StatelessWidget {
  const _LeagueTablePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const <Widget>[
        ListTile(leading: Text('1.'), title: Text('Sparta Praha'), trailing: Text('75 b.')),
        Divider(height: 0),
        ListTile(leading: Text('2.'), title: Text('Slavia Praha'), trailing: Text('72 b.')),
        Divider(height: 0),
        ListTile(leading: Text('3.'), title: Text('Viktoria Plzeň'), trailing: Text('64 b.')),
      ],
    );
  }
}

class _BracketPlaceholder extends StatelessWidget {
  const _BracketPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.account_tree, size: 48),
          SizedBox(height: 12),
          Text('Pavouk brzy dostupný'),
        ],
      ),
    );
  }
}


