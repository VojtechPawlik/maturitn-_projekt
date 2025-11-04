class LaLigaTeam {
  final String position;
  final String logo;
  final String team;
  final String matches;
  final String scoresStr;
  final String points;
  final String color;

  LaLigaTeam({
    required this.position,
    required this.logo,
    required this.team,
    required this.matches,
    required this.scoresStr,
    required this.points,
    required this.color,
  });

  factory LaLigaTeam.fromList(List<dynamic> row) {
    return LaLigaTeam(
      position: row.length > 0 ? row[0].toString() : '',
      logo: row.length > 1 ? row[1].toString() : '',
      team: row.length > 2 ? row[2].toString() : '',
      matches: row.length > 3 ? row[3].toString() : '',
      scoresStr: row.length > 4 ? row[4].toString() : '',
      points: row.length > 5 ? row[5].toString() : '',
      color: row.length > 6 ? row[6].toString() : '',
    );
  }
}
