class Ligue1Team {
  final String position;
  final String logo;
  final String team;
  final String matches;
  final String wins;
  final String draws;
  final String losses;
  final String scoresStr;
  final String goalDifference;
  final String points;

  Ligue1Team({
    required this.position,
    required this.logo,
    required this.team,
    required this.matches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.scoresStr,
    required this.goalDifference,
    required this.points,
  });

  factory Ligue1Team.fromList(List<dynamic> row) {
    return Ligue1Team(
      position: row.length > 0 ? row[0].toString() : '',
      logo: row.length > 1 ? row[1].toString() : '',
      team: row.length > 2 ? row[2].toString() : '',
      matches: row.length > 3 ? row[3].toString() : '',
      wins: row.length > 4 ? row[4].toString() : '',
      draws: row.length > 5 ? row[5].toString() : '',
      losses: row.length > 6 ? row[6].toString() : '',
      scoresStr: row.length > 7 ? row[7].toString() : '',
      goalDifference: row.length > 8 ? row[8].toString() : '',
      points: row.length > 9 ? row[9].toString() : '',
    );
  }
}
