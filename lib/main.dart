import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/competitions_screen.dart';
import 'screens/login_screen.dart';
import 'screens/teams_screen.dart';
import 'screens/search_screen.dart';
import 'screens/competition_detail_screen.dart';
import 'app_state.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AppProvider(
      notifier: AppState(),
      child: Builder(builder: (BuildContext context) {
        final AppState app = AppProvider.of(context);
        return MaterialApp(
      title: 'Fotbal Live',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954), // green accent similar to Livesport vibe
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE6E8EB),
          thickness: 1,
          space: 0,
        ),
        tabBarTheme: const TabBarThemeData(
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: Color(0x1A1DB954),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: app.themeMode,
      home: const AppShell(),
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == '/search') {
          return MaterialPageRoute<void>(builder: (_) => const SearchScreen());
        }
        if (settings.name == '/competition') {
          final String title = settings.arguments as String? ?? 'Soutěž';
          return MaterialPageRoute<void>(
              builder: (_) => CompetitionDetailScreen(title: title));
        }
        if (settings.name == '/settings') {
          return MaterialPageRoute<void>(builder: (_) => const SettingsScreen());
        }
        return null;
      },
    );
      }),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const List<String> _titles = <String>['Domů', 'Oblíbené', 'Soutěže', 'Týmy'];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const <Widget>[
      HomeScreen(),
      FavoritesScreen(),
      CompetitionsScreen(),
      TeamsScreen(),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Nastavení',
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_outline),
            label: const Text('Přihlásit'),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/search'),
            icon: const Icon(Icons.search),
            tooltip: 'Hledat',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTap,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Domů'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Oblíbené'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Soutěže'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Týmy'),
        ],
      ),
    );
  }
}
