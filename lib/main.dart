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
import 'screens/match_detail_screen.dart';
import 'screens/news_screen.dart';
import 'screens/feedback_screen.dart';

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
          seedColor: const Color(0xFF0A84FF), // dark blue accent
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
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
          indicatorColor: Color(0x1A0A84FF),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF),
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
        if (settings.name == '/match') {
          final Map<String, String> args = (settings.arguments as Map<String, String>?) ?? <String, String>{};
          return MaterialPageRoute<void>(
            builder: (_) => MatchDetailScreen(
              home: args['home'] ?? 'Domácí',
              away: args['away'] ?? 'Hosté',
              kickoff: args['time'] ?? '--:--',
            ),
          );
        }
        if (settings.name == '/settings') {
          return MaterialPageRoute<void>(builder: (_) => const SettingsScreen());
        }
        if (settings.name == '/feedback') {
          return MaterialPageRoute<void>(builder: (_) => const FeedbackScreen());
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
  int _currentIndex = 2; // center is Home

  static const int _homeIndex = 2;
  static const List<String> _titles = <String>['Oblíbené', 'Soutěže', 'Domů', 'Týmy', 'Novinky'];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const <Widget>[
      FavoritesScreen(),
      CompetitionsScreen(),
      HomeScreen(),
      TeamsScreen(),
      NewsScreen(),
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
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Nastavení',
        ),
        title: _currentIndex == _homeIndex ? const SizedBox.shrink() : Text(_titles[_currentIndex]),
        actions: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/search'),
            icon: const Icon(Icons.search),
            tooltip: 'Hledat',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_outline),
            tooltip: 'Přihlásit',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTap,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Oblíbené'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Soutěže'),
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Domů'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Týmy'),
          NavigationDestination(icon: Icon(Icons.article_outlined), selectedIcon: Icon(Icons.article), label: 'Novinky'),
        ],
      ),
    );
  }
}
