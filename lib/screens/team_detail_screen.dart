import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class TeamDetailScreen extends StatelessWidget {
  final Team team;

  const TeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hlavička s logem
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF3E5F44),
                    const Color(0xFF3E5F44).withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Logo týmu
                  team.logoUrl.startsWith('http')
                      ? Image.network(
                          team.logoUrl,
                          height: 120,
                          width: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.sports_soccer,
                              size: 120,
                              color: Colors.white,
                            );
                          },
                        )
                      : const Icon(
                          Icons.sports_soccer,
                          size: 120,
                          color: Colors.white,
                        ),
                  const SizedBox(height: 16),
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.league,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Informace o týmu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Základní informace'),
                  if (team.league.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.emoji_events,
                      title: 'Liga',
                      value: team.league,
                    ),
                  if (team.country.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.flag,
                      title: 'Země',
                      value: team.country,
                    ),
                  if (team.season > 0)
                    _buildInfoCard(
                      icon: Icons.calendar_today,
                      title: 'Sezóna',
                      value: team.season.toString(),
                    ),
                  if (team.stadium.isNotEmpty) ...[
                    _buildSectionTitle('Stadion'),
                    _buildInfoCard(
                      icon: Icons.stadium,
                      title: 'Název stadionu',
                      value: team.stadium,
                    ),
                    if (team.city.isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.location_city,
                        title: 'Město',
                        value: team.city,
                      ),
                    if (team.stadiumCountry.isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.public,
                        title: 'Země stadionu',
                        value: team.stadiumCountry,
                      ),
                  ],
                  // Zobrazit všechny další fields z Firestore
                  if (team.additionalFields.isNotEmpty) ...[
                    _buildSectionTitle('Další informace'),
                    ...team.additionalFields.entries.map((entry) {
                      return _buildInfoCard(
                        icon: _getIconForField(entry.key),
                        title: _formatFieldName(entry.key),
                        value: _formatFieldValue(entry.value),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3E5F44),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3E5F44).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3E5F44),
                size: 28,
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
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  // Pomocná metoda pro získání ikony podle názvu fieldu
  IconData _getIconForField(String fieldName) {
    final lowerName = fieldName.toLowerCase();
    if (lowerName.contains('email') || lowerName.contains('mail')) {
      return Icons.email;
    } else if (lowerName.contains('phone') || lowerName.contains('tel')) {
      return Icons.phone;
    } else if (lowerName.contains('web') || lowerName.contains('url') || lowerName.contains('site')) {
      return Icons.language;
    } else if (lowerName.contains('address') || lowerName.contains('adresa')) {
      return Icons.location_on;
    } else if (lowerName.contains('year') || lowerName.contains('rok')) {
      return Icons.calendar_today;
    } else if (lowerName.contains('coach') || lowerName.contains('trener')) {
      return Icons.person;
    } else if (lowerName.contains('player') || lowerName.contains('hrac')) {
      return Icons.people;
    } else if (lowerName.contains('founded') || lowerName.contains('zaloz')) {
      return Icons.history;
    } else if (lowerName.contains('capacity') || lowerName.contains('kapacita')) {
      return Icons.people_outline;
    } else {
      return Icons.info;
    }
  }

  // Formátování názvu fieldu pro zobrazení
  String _formatFieldName(String fieldName) {
    // Převést snake_case nebo camelCase na čitelnější formát
    String formatted = fieldName
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim();
    
    // První písmeno velké
    if (formatted.isNotEmpty) {
      formatted = formatted[0].toUpperCase() + formatted.substring(1);
    }
    
    return formatted;
  }

  // Formátování hodnoty fieldu pro zobrazení
  String _formatFieldValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'Ano' : 'Ne';
    if (value is List) return value.join(', ');
    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return value.toString();
  }
}
