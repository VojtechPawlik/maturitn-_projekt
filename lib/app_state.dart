import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  final Set<String> _favoriteTeams = <String>{};
  bool _notificationsEnabled = false;

  ThemeMode get themeMode => _themeMode;
  Set<String> get favoriteTeams => _favoriteTeams;
  bool get notificationsEnabled => _notificationsEnabled;

  void toggleThemeMode(bool dark) {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
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


