import 'package:flutter/material.dart';
import 'teams_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allItems = <String>[
      ...TeamsScreen.czechTeams,
      'Tomáš Čvančara',
      'Lukáš Haraslín',
      'Jan Kuchta',
      'Peter Olayinka',
    ];
    final List<String> filtered = allItems
        .where((e) => e.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Vyhledávání')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Hledej tým nebo hráče...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (BuildContext context, int index) {
                final String value = filtered[index];
                return ListTile(
                  title: Text(value),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Otevřít: $value')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


