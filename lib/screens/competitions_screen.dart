import 'package:flutter/material.dart';

class CompetitionsScreen extends StatelessWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: <Widget>[
        const _SectionHeader('České soutěže'),
        const Divider(height: 0),
        ListTile(
          title: const Text('FORTUNA:LIGA'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDetail(context, 'FORTUNA:LIGA'),
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('FORTUNA:NÁRODNÍ LIGA'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDetail(context, 'FORTUNA:NÁRODNÍ LIGA'),
        ),
        const Divider(height: 0),
        ListTile(
          title: const Text('MOL Cup'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDetail(context, 'MOL Cup'),
        ),
      ],
    );
  }

  void _openDetail(BuildContext context, String title) {
    Navigator.of(context).pushNamed('/competition', arguments: title);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

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


