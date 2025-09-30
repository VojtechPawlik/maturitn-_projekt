import 'package:flutter/material.dart';
import '../app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppProvider.of(context);
    final bool isDark = app.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Nastavení')),
      body: ListView(
        children: <Widget>[
          SwitchListTile(
            title: const Text('Tmavý režim'),
            subtitle: const Text('Přepnout mezi světlým a tmavým vzhledem'),
            value: isDark,
            onChanged: (bool value) => app.toggleThemeMode(value),
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
    );
  }
}


