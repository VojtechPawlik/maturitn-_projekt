import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        ListTile(title: Text('Novinky brzy dostupné')), 
      ],
    );
  }
}


