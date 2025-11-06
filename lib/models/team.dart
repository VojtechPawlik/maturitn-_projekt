class Team {
  final String name;
  final String season;
  final String country;
  final String logoUrl;
  final String stadium;
  final String stadiumCountry;
  final String city;
  final String league;

  Team({
    required this.name,
    required this.season,
    required this.country,
    required this.logoUrl,
    required this.stadium,
    required this.stadiumCountry,
    required this.city,
    required this.league,
  });

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      name: map['D2'] ?? '',
      season: map['E2'] ?? '',
      country: map['G2'] ?? '',
      logoUrl: map['S6'] ?? '',
      stadium: map['V6'] ?? '',
      stadiumCountry: map['X6'] ?? '',
      city: map['Y6'] ?? '',
      league: map['AD6'] ?? '',
    );
  }
}
