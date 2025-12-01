import 'package:flutter/material.dart';
import '../models/betting_models.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';
import '../services/api_football_service.dart';

class BettingHistoryScreen extends StatefulWidget {
  const BettingHistoryScreen({super.key});

  @override
  State<BettingHistoryScreen> createState() => _BettingHistoryScreenState();
}

class _BettingHistoryScreenState extends State<BettingHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final SessionManager _sessionManager = SessionManager();
  List<Bet> _bets = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, Match> _matchCache = {}; // Cache pro zápasy
  final Set<String> _settledBets = {}; // Sázky, které už byly zúčtovány

  @override
  void initState() {
    super.initState();
    _loadBets();
  }

  Future<void> _loadBets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userEmail = _sessionManager.userEmail;
      if (userEmail == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nejste přihlášeni';
        });
        return;
      }

      final bets = await _firestoreService.getUserBets(userEmail);
      
      setState(() {
        _bets = bets;
        _isLoading = false;
      });
      
      // Načíst informace o zápasech asynchronně po zobrazení sázek
      if (bets.isNotEmpty) {
        _loadMatchesForBets(bets);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chyba při načítání sázek: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMatchesForBets(List<Bet> bets) async {
    // Načíst informace o zápasech - zkusit najít v různých datech
    final apiService = ApiFootballService();
    await apiService.initializeApiKey();
    
    // Zkusit najít zápasy v rozmezí 30 dní (před a po dnešku)
    for (var bet in bets) {
      if (!_matchCache.containsKey(bet.matchId)) {
        Match? foundMatch;
        
        // Zkusit najít zápas v různých datech
        for (int i = -15; i <= 15; i++) {
          final date = DateTime.now().add(Duration(days: i));
          final matches = await _firestoreService.getFixtures(date);
          try {
            foundMatch = matches.firstWhere((m) => m.id == bet.matchId);
            break;
          } catch (e) {
            // Zápas nenalezen v tomto datu, zkusit další
          }
        }
        
        if (foundMatch != null) {
          setState(() {
            _matchCache[bet.matchId] = foundMatch!;
          });
        }
      }
    }
  }

  String _getBetTypeLabel(String betType, Match? match) {
    if (match == null) return betType;
    
    switch (betType) {
      case 'home':
        return 'Výhra ${match.homeTeam}';
      case 'draw':
        return 'Remíza';
      case 'away':
        return 'Výhra ${match.awayTeam}';
      case 'over25':
        return 'Více než 2.5 gólu';
      case 'under25':
        return 'Méně než 2.5 gólu';
      case 'btts_yes':
        return 'Oba týmy dají gól - Ano';
      case 'btts_no':
        return 'Oba týmy dají gól - Ne';
      case '1x':
        return '${match.homeTeam} neprohraje (1X)';
      case 'x2':
        return '${match.awayTeam} neprohraje (X2)';
      case '12':
        return 'Remíza nebude (12)';
      default:
        return betType;
    }
  }

  bool? _isBetWon(Bet bet, Match? match) {
    if (match == null) return null;
    
    // Pokud zápas ještě není dohraný
    if (!match.isFinished || match.homeScore == null || match.awayScore == null) {
      return null; // Zatím nevyhodnoceno
    }
    
    final homeScore = match.homeScore!;
    final awayScore = match.awayScore!;
    final totalGoals = homeScore + awayScore;
    
    switch (bet.betType) {
      case 'home':
        return homeScore > awayScore;
      case 'draw':
        return homeScore == awayScore;
      case 'away':
        return awayScore > homeScore;
      case 'over25':
        return totalGoals > 2.5;
      case 'under25':
        return totalGoals < 2.5;
      case 'btts_yes':
        return homeScore > 0 && awayScore > 0;
      case 'btts_no':
        return homeScore == 0 || awayScore == 0;
      case '1x':
        return homeScore >= awayScore;
      case 'x2':
        return awayScore >= homeScore;
      case '12':
        return homeScore != awayScore;
      default:
        return null;
    }
  }

  String _getBetStatusText(Bet bet, Match? match) {
    final isWon = _isBetWon(bet, match);
    
    if (isWon == null) {
      return 'Zatím nevyhodnoceno';
    } else if (isWon) {
      return 'Úspěšná sázka';
    } else {
      return 'Neúspěšná sázka';
    }
  }

  Color _getBetStatusColor(Bet bet, Match? match) {
    final isWon = _isBetWon(bet, match);
    
    if (isWon == null) {
      return Colors.grey;
    } else if (isWon) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  // Zúčtovat sázku - přičíst výhru a uložit stav do Firestore
  Future<void> _settleBet(Bet bet, bool isWon) async {
    if (_settledBets.contains(bet.id)) return;
    _settledBets.add(bet.id);

    try {
      String newStatus = isWon ? 'won' : 'lost';
      double? payout = bet.payout;

      if (isWon) {
        // Spočítat výhru, pokud ještě není uložená
        payout ??= bet.amount * bet.odds;
        // Přičíst výhru k rozpočtu
        await _sessionManager.addBalance(payout);
      }

      // Uložit aktualizovanou sázku do Firestore
      final updatedBet = Bet(
        id: bet.id,
        userEmail: bet.userEmail,
        matchId: bet.matchId,
        betType: bet.betType,
        amount: bet.amount,
        odds: bet.odds,
        placedAt: bet.placedAt,
        status: newStatus,
        payout: payout,
      );

      await _firestoreService.saveBet(updatedBet);
    } catch (e) {
      // Ignorovat chyby při zúčtování, aby neblokovaly UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historie sázek'),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBets,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E5F44),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Zkusit znovu'),
                      ),
                    ],
                  ),
                )
              : _bets.isEmpty
                  ? const Center(
                      child: Text(
                        'Zatím nemáte žádné sázky',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bets.length,
                        itemBuilder: (context, index) {
                          final bet = _bets[index];
                          final match = _matchCache[bet.matchId];
                          
                          final isWon = _isBetWon(bet, match);
                          final borderColor = isWon == null 
                              ? Colors.grey[300] 
                              : (isWon ? Colors.green : Colors.red);

                          // Pokud je zápas dohraný a sázka ještě nebyla zúčtována, zúčtovat ji
                          if (isWon != null && (bet.status == null || bet.status == 'pending') && !_settledBets.contains(bet.id)) {
                            _settleBet(bet, isWon);
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: borderColor ?? Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hlavička s týmami
                                  if (match != null) ...[
                                    Row(
                                      children: [
                                        if (match.homeLogo.isNotEmpty)
                                          Image.network(
                                            match.homeLogo,
                                            width: 32,
                                            height: 32,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 32),
                                          ),
                                        if (match.homeLogo.isNotEmpty) const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            match.homeTeam,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            match.homeScore != null && match.awayScore != null
                                                ? '${match.homeScore} - ${match.awayScore}'
                                                : '- : -',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            match.awayTeam,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (match.awayLogo.isNotEmpty) const SizedBox(width: 8),
                                        if (match.awayLogo.isNotEmpty)
                                          Image.network(
                                            match.awayLogo,
                                            width: 32,
                                            height: 32,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 32),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  // Typ sázky
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getBetTypeLabel(bet.betType, match),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _getBetStatusText(bet, match),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _getBetStatusColor(bet, match),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Detaily sázky
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Částka: ${bet.amount.toStringAsFixed(2)}!',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Kurz: ${bet.odds.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Výhra při úspěšné sázce
                                      if (isWon == true)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Výhra: ${(bet.payout ?? (bet.amount * bet.odds)).toStringAsFixed(2)}!',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Datum
                                  Text(
                                    'Datum: ${bet.placedAt.day}.${bet.placedAt.month}.${bet.placedAt.year} ${bet.placedAt.hour.toString().padLeft(2, '0')}:${bet.placedAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

