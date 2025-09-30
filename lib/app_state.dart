import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  final Set<String> _favoriteTeams = <String>{};

  ThemeMode get themeMode => _themeMode;
  Set<String> get favoriteTeams => _favoriteTeams;

  void toggleThemeMode(bool dark) {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  bool isFavoriteTeam(String team) => _favoriteTeams.contains(team);

  void toggleFavoriteTeam(String team) {
    if (_favoriteTeams.contains(team)) {
      _favoriteTeams.remove(team);
    } else {
      _favoriteTeams.add(team);
    }
    notifyListeners();
  }
}

class AppProvider extends InheritedNotifier<AppState> {
  const AppProvider({super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final AppProvider? provider = context.dependOnInheritedWidgetOfExactType<AppProvider>();
    assert(provider != null, 'AppProvider not found in context');
    return provider!.notifier!;
  }
}


