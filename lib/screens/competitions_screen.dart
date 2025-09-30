import 'package:flutter/material.dart';

class CompetitionsScreen extends StatelessWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        ListTile(title: Text('Premier League')),
        Divider(height: 0),
        ListTile(title: Text('La Liga')),
        Divider(height: 0),
        ListTile(title: Text('Serie A')),
        Divider(height: 0),
        ListTile(title: Text('Bundesliga')),
        Divider(height: 0),
        ListTile(title: Text('Ligue 1')),
      ],
    );
  }
}


