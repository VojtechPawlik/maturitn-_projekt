import 'package:flutter/material.dart';
import 'champions_league_screen.dart';
import '../services/google_sheets_service.dart';

class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  String championsLeagueLogo = '';
  String premierLeagueLogo = '';
  String serieALogo = '';
  String laLigaLogo = '';
  String bundesligaLogo = '';
  String ligue1Logo = '';
  String europaLeagueLogo = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLogos();
  }

  Future<void> loadLogos() async {
    print('Začínám načítat loga...'); // Debug
    try {
      final logos = await Future.wait([
        GoogleSheetsService.getCompetitionLogo('List 8', 'A2'), // Champions League
        GoogleSheetsService.getCompetitionLogo('List 8', 'A3'), // Premier League
        GoogleSheetsService.getCompetitionLogo('List 8', 'A4'), // Serie A
        GoogleSheetsService.getCompetitionLogo('List 8', 'A5'), // La Liga
        GoogleSheetsService.getCompetitionLogo('List 8', 'A6'), // Bundesliga
        GoogleSheetsService.getCompetitionLogo('List 8', 'A7'), // Ligue 1
        GoogleSheetsService.getCompetitionLogo('List 8', 'A8'), // Europa League
      ]);
      
      print('Načtená loga:');
      print('Champions League (${logos[0].length} znaků): "${logos[0]}"');
      print('Premier League (${logos[1].length} znaků): "${logos[1]}"');
      print('Serie A (${logos[2].length} znaků): "${logos[2]}"');
      print('La Liga (${logos[3].length} znaků): "${logos[3]}"');
      print('Bundesliga (${logos[4].length} znaků): "${logos[4]}"');
      print('Ligue 1 (${logos[5].length} znaků): "${logos[5]}"');
      print('Europa League (${logos[6].length} znaků): "${logos[6]}"');
      
      setState(() {
        championsLeagueLogo = logos[0];
        premierLeagueLogo = logos[1];
        serieALogo = logos[2];
        laLigaLogo = logos[3];
        bundesligaLogo = logos[4];
        ligue1Logo = logos[5];
        europaLeagueLogo = logos[6];
        isLoading = false;
      });
      
      print('State aktualizován:');
      print('championsLeagueLogo: $championsLeagueLogo');
      print('premierLeagueLogo: $premierLeagueLogo');
      print('serieALogo: $serieALogo');
    } catch (e) {
      print('Chyba při načítání log: $e'); // Debug
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soutěže'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CompetitionCard(
                  title: 'Liga mistrů',
                  subtitle: 'UEFA Champions League',
                  logoUrl: championsLeagueLogo,
                  icon: Icons.stars,
                  color: Colors.blue,
                  onTap: () {
                    print('Logo URL při kliknutí: "$championsLeagueLogo"'); // Debug
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChampionsLeagueScreen(),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'Premier League',
            subtitle: 'Anglická liga',
            logoUrl: premierLeagueLogo,
            icon: Icons.sports_soccer,
            color: Colors.purple,
            onTap: () {
              // TODO: Přidat obrazovku pro Premier League
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'Serie A',
            subtitle: 'Italská liga',
            logoUrl: serieALogo,
            icon: Icons.sports_soccer,
            color: Colors.green,
            onTap: () {
              // TODO: Přidat obrazovku pro Serie A
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'La Liga',
            subtitle: 'Španělská liga',
            logoUrl: laLigaLogo,
            icon: Icons.sports_soccer,
            color: Colors.orange,
            onTap: () {
              // TODO: Přidat obrazovku pro La Liga
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'Bundesliga',
            subtitle: 'Německá liga',
            logoUrl: bundesligaLogo,
            icon: Icons.sports_soccer,
            color: Colors.red,
            onTap: () {
              // TODO: Přidat obrazovku pro Bundesliga
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'Ligue 1',
            subtitle: 'Francouzská liga',
            logoUrl: ligue1Logo,
            icon: Icons.sports_soccer,
            color: Colors.blueAccent,
            onTap: () {
              // TODO: Přidat obrazovku pro Ligue 1
            },
          ),
          const SizedBox(height: 12),
          _CompetitionCard(
            title: 'Evropská liga',
            subtitle: 'UEFA Europa League',
            logoUrl: europaLeagueLogo,
            icon: Icons.stars_outlined,
            color: Colors.deepOrange,
            onTap: () {
              // TODO: Přidat obrazovku pro Europa League
            },
          ),
        ],
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String logoUrl;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CompetitionCard({
    required this.title,
    required this.subtitle,
    required this.logoUrl,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Chyba při načítání obrázku: $error'); // Debug
                          return Icon(
                            icon,
                            size: 32,
                            color: color,
                          );
                        },
                      )
                    : Icon(
                        icon,
                        size: 32,
                        color: color,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


