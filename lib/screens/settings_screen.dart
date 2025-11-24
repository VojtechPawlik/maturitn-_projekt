import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoadingPlayers = false;
  bool _isUpdatingTeamInfo = false;

  void _saveNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _loadPlayersForAllTeams() async {
    setState(() => _isLoadingPlayers = true);
    
    try {
      await _firestoreService.fetchAndSavePlayersForAllTeams();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hráči pro všechny týmy byly úspěšně načteni'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při načítání hráčů: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlayers = false);
      }
    }
  }

  Future<void> _updateTeamLocationInfo() async {
    setState(() => _isUpdatingTeamInfo = true);
    
    try {
      await _firestoreService.updateTeamLocationInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informace o městech, zemích a stadionech byly úspěšně aktualizovány'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při aktualizaci: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingTeamInfo = false);
      }
    }
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
          _buildSectionHeader('Data'),
          _buildSettingsTile(
            icon: Icons.people,
            title: 'Načíst hráče pro všechny týmy',
            subtitle: 'Načte soupisky hráčů pro všechny týmy z API',
            trailing: _isLoadingPlayers
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isLoadingPlayers ? null : _loadPlayersForAllTeams,
          ),
          _buildSettingsTile(
            icon: Icons.location_on,
            title: 'Aktualizovat informace o týmech',
            subtitle: 'Doplní města, země a stadiony pro všechny týmy',
            trailing: _isUpdatingTeamInfo
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _isUpdatingTeamInfo ? null : _updateTeamLocationInfo,
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


