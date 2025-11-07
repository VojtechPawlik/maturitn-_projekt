import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/localization_service.dart';

class TeamDetailScreen extends StatelessWidget {
  final Team team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(team.name),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: const Icon(Icons.info_outline), text: LocalizationService.translate('information')),
              Tab(icon: const Icon(Icons.people_outline), text: LocalizationService.translate('squad')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildSquadTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: team.logoUrl.isNotEmpty
                ? Image.network(
                    team.logoUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.sports_soccer, size: 120);
                    },
                  )
                : const Icon(Icons.sports_soccer, size: 120),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(LocalizationService.translate('team_name'), team.name, Icons.sports_soccer),
          _buildInfoCard(LocalizationService.translate('league'), team.league, Icons.emoji_events),
          _buildInfoCard(LocalizationService.translate('season'), team.season, Icons.calendar_today),
          _buildInfoCard(LocalizationService.translate('stadium'), team.stadium, Icons.stadium),
          _buildInfoCard(LocalizationService.translate('city'), '${team.city}, ${team.stadiumCountry}', Icons.location_city),
          _buildInfoCard(LocalizationService.translate('country'), team.country, Icons.flag),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            LocalizationService.translate('squad_later'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
