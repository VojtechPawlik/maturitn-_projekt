// Modely pro sázení

class MatchOdds {
  final int matchId;
  final double homeWin; // Kurz na výhru domácích
  final double draw; // Kurz na remízu
  final double awayWin; // Kurz na výhru hostů
  final double? over25; // Kurz na více než 2.5 gólu
  final double? under25; // Kurz na méně než 2.5 gólu
  final double? bothTeamsScore; // Kurz na oba týmy dají gól (BTTS Yes)
  final double? bothTeamsNoScore; // Kurz na oba týmy nedají gól (BTTS No)
  final double? homeWinOrDraw; // Kurz na domácí neprohrají (1X)
  final double? awayWinOrDraw; // Kurz na hosté neprohrají (X2)
  final double? homeOrAway; // Kurz na remíza nebude (12)
  final DateTime updatedAt;

  MatchOdds({
    required this.matchId,
    required this.homeWin,
    required this.draw,
    required this.awayWin,
    this.over25,
    this.under25,
    this.bothTeamsScore,
    this.bothTeamsNoScore,
    this.homeWinOrDraw,
    this.awayWinOrDraw,
    this.homeOrAway,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'homeWin': homeWin,
      'draw': draw,
      'awayWin': awayWin,
      'over25': over25,
      'under25': under25,
      'bothTeamsScore': bothTeamsScore,
      'bothTeamsNoScore': bothTeamsNoScore,
      'homeWinOrDraw': homeWinOrDraw,
      'awayWinOrDraw': awayWinOrDraw,
      'homeOrAway': homeOrAway,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MatchOdds.fromMap(Map<String, dynamic> map) {
    return MatchOdds(
      matchId: map['matchId'] ?? 0,
      homeWin: (map['homeWin'] ?? 1.0).toDouble(),
      draw: (map['draw'] ?? 1.0).toDouble(),
      awayWin: (map['awayWin'] ?? 1.0).toDouble(),
      over25: map['over25'] != null ? (map['over25'] as num).toDouble() : null,
      under25: map['under25'] != null ? (map['under25'] as num).toDouble() : null,
      bothTeamsScore: map['bothTeamsScore'] != null ? (map['bothTeamsScore'] as num).toDouble() : null,
      bothTeamsNoScore: map['bothTeamsNoScore'] != null ? (map['bothTeamsNoScore'] as num).toDouble() : null,
      homeWinOrDraw: map['homeWinOrDraw'] != null ? (map['homeWinOrDraw'] as num).toDouble() : null,
      awayWinOrDraw: map['awayWinOrDraw'] != null ? (map['awayWinOrDraw'] as num).toDouble() : null,
      homeOrAway: map['homeOrAway'] != null ? (map['homeOrAway'] as num).toDouble() : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }
}

class Bet {
  final String id;
  final String userEmail;
  final int matchId;
  final String betType; // 'home', 'draw', 'away', 'over25', 'under25'
  final double amount; // Vsazená částka
  final double odds; // Kurz při sázce
  final DateTime placedAt;
  final String? status; // 'pending', 'won', 'lost', 'cancelled'
  final double? payout; // Výhra (null pokud ještě není vyhodnoceno)

  Bet({
    required this.id,
    required this.userEmail,
    required this.matchId,
    required this.betType,
    required this.amount,
    required this.odds,
    DateTime? placedAt,
    this.status,
    this.payout,
  }) : placedAt = placedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'matchId': matchId,
      'betType': betType,
      'amount': amount,
      'odds': odds,
      'placedAt': placedAt.toIso8601String(),
      'status': status ?? 'pending',
      'payout': payout,
    };
  }

  factory Bet.fromMap(Map<String, dynamic> map) {
    return Bet(
      id: map['id'] ?? '',
      userEmail: map['userEmail'] ?? '',
      matchId: map['matchId'] ?? 0,
      betType: map['betType'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      odds: (map['odds'] ?? 1.0).toDouble(),
      placedAt: map['placedAt'] != null 
          ? DateTime.parse(map['placedAt']) 
          : DateTime.now(),
      status: map['status'],
      payout: map['payout'] != null ? (map['payout'] as num).toDouble() : null,
    );
  }
}

