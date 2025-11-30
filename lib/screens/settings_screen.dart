import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/firestore_service.dart';
import '../services/api_football_service.dart';
import 'betting_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiFootballService _apiFootballService = ApiFootballService();
  bool _notificationsEnabled = true;
  bool _isLoadingPlayers = false;
  String? _loadingStatus;

  void _saveNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate('settings')),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(LocalizationService.translate('general')),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: LocalizationService.translate('notifications'),
            subtitle: LocalizationService.translate('notifications_subtitle'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _saveNotifications,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Sázení'),
          _buildSettingsTile(
            icon: Icons.history,
            title: 'Historie sázek',
            subtitle: 'Zobrazit všechny vaše sázky',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BettingHistoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Správa dat'),
          _buildSettingsTile(
            icon: Icons.people,
            title: 'Načíst všechny hráče',
            subtitle: _isLoadingPlayers 
                ? (_loadingStatus ?? 'Načítám hráče...')
                : 'Načte hráče pro všechny týmy z API do Firestore',
            trailing: _isLoadingPlayers
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isLoadingPlayers ? null : _loadAllPlayers,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(LocalizationService.translate('about_app')),
          _buildSettingsTile(
            icon: Icons.info,
            title: LocalizationService.translate('app_version'),
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }

  Future<void> _loadAllPlayers() async {
    // Potvrdit akci
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Načíst všechny hráče?'),
        content: const Text(
          'Tato akce načte hráče pro všechny týmy z API do Firestore. '
          'Může to trvat několik minut a spotřebuje API volání. '
          'Chcete pokračovat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E5F44),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ano, načíst'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoadingPlayers = true;
      _loadingStatus = 'Inicializuji API...';
    });

    try {
      // Inicializovat API klíč
      await _apiFootballService.initializeApiKey();
      
      setState(() {
        _loadingStatus = 'Načítám týmy...';
      });

      // Načíst všechny týmy
      final teams = await _firestoreService.getTeams();
      final teamsWithApiId = teams.where((t) => t.apiTeamId > 0).toList();
      
      // Pokud některé týmy nemají apiTeamId, zkusit ho doplnit
      if (teamsWithApiId.length < teams.length) {
        setState(() {
          _loadingStatus = 'Doplňuji API ID pro týmy (${teams.length - teamsWithApiId.length} týmů)...';
        });
        
        try {
          // Zkusit doplnit apiTeamId pro týmy, které ho nemají
          await _firestoreService.ensureAllTeamsHaveApiId();
          
          // Znovu načíst týmy po doplnění apiTeamId
          final updatedTeams = await _firestoreService.getTeams();
          final updatedTeamsWithApiId = updatedTeams.where((t) => t.apiTeamId > 0).toList();
          
          if (updatedTeamsWithApiId.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nepodařilo se doplnit API ID pro týmy. Zkuste nejdříve načíst tabulky lig.'),
                  duration: Duration(seconds: 5),
                ),
              );
            }
            setState(() {
              _isLoadingPlayers = false;
              _loadingStatus = null;
            });
            return;
          }
          
          setState(() {
            _loadingStatus = 'Načítám hráče pro ${updatedTeamsWithApiId.length} týmů...';
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chyba při doplňování API ID: ${e.toString()}'),
                duration: const Duration(seconds: 6),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // I přes chybu zkusit pokračovat, pokud některé týmy už mají apiTeamId
          final updatedTeams = await _firestoreService.getTeams();
          final updatedTeamsWithApiId = updatedTeams.where((t) => t.apiTeamId > 0).toList();
          
          if (updatedTeamsWithApiId.isEmpty) {
            setState(() {
              _isLoadingPlayers = false;
              _loadingStatus = null;
            });
            return;
          }
          
          setState(() {
            _loadingStatus = 'Načítám hráče pro ${updatedTeamsWithApiId.length} týmů...';
          });
        }
      } else {
        setState(() {
          _loadingStatus = 'Načítám hráče pro ${teamsWithApiId.length} týmů...';
        });
      }

      // Načíst hráče pro všechny týmy
      await _firestoreService.fetchAndSavePlayersForAllTeams(includeProfiles: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hráči byli úspěšně načteni!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při načítání hráčů: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
          _loadingStatus = null;
        });
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

}


