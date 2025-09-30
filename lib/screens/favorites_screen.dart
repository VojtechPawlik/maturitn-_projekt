import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.favorite, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          const Text('Oblíbené zápasy a týmy se objeví zde'),
        ],
      ),
    );
  }
}


