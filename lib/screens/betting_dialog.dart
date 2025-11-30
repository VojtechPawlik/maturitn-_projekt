import 'package:flutter/material.dart';
import '../models/betting_models.dart';
import '../services/api_football_service.dart';
import '../services/firestore_service.dart';
import '../services/session_manager.dart';

class BettingDialog extends StatefulWidget {
  final Match match;

  const BettingDialog({
    super.key,
    required this.match,
  });

  @override
  State<BettingDialog> createState() => _BettingDialogState();
}

class _BettingDialogState extends State<BettingDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final SessionManager _sessionManager = SessionManager();
  final ApiFootballService _apiFootballService = ApiFootballService();
  MatchOdds? _odds;
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _selectedBetTypes = {}; // Může být více sázek z různých kategorií
  final Map<String, TextEditingController> _amountControllers = {}; // Samostatný controller pro každou sázku
  final Map<String, String> _fieldErrors = {}; // Chyby pro jednotlivá pole
  final Map<String, String> _categoryErrors = {}; // Chyby pro kategorie
  String? _generalError; // Obecná chyba
  double _totalPotentialWin = 0.0;
  double _userBalance = 0.0;
  
  // Kategorie sázek
  static const Map<String, String> _betCategories = {
    'home': 'result',
    'draw': 'result',
    'away': 'result',
    'over25': 'goals',
    'under25': 'goals',
    'btts_yes': 'btts',
    'btts_no': 'btts',
    '1x': 'double',
    'x2': 'double',
    '12': 'double',
  };

  @override
  void initState() {
    super.initState();
    _loadOdds();
    _loadBalance();
  }

  @override
  void dispose() {
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final balance = await _sessionManager.getBalance();
    setState(() {
      _userBalance = balance;
    });
  }

  Future<void> _loadOdds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Nejdříve zkusit načíst z Firestore
      MatchOdds? odds = await _firestoreService.getMatchOdds(widget.match.id);

      // Pokud není v Firestore, zkusit načíst z API
      if (odds == null) {
        await _apiFootballService.initializeApiKey();
        final apiOdds = await _apiFootballService.getMatchOdds(widget.match.id);
        
        if (apiOdds != null) {
          // Použít kurzy z API
          odds = MatchOdds(
            matchId: widget.match.id,
            homeWin: apiOdds['homeWin'] ?? 2.0,
            draw: apiOdds['draw'] ?? 3.0,
            awayWin: apiOdds['awayWin'] ?? 2.5,
            over25: apiOdds['over25'],
            under25: apiOdds['under25'],
            bothTeamsScore: apiOdds['bothTeamsScore'],
            bothTeamsNoScore: apiOdds['bothTeamsNoScore'],
            homeWinOrDraw: apiOdds['homeWinOrDraw'],
            awayWinOrDraw: apiOdds['awayWinOrDraw'],
            homeOrAway: apiOdds['homeOrAway'],
          );
          
          // Uložit do Firestore
          await _firestoreService.saveMatchOdds(widget.match.id, odds);
        }
      }

      // Pokud stále není, vytvořit výchozí kurzy
      if (odds == null) {
        // Vytvořit realistické kurzy na základě výsledku (pokud je znám)
        double homeWin = 2.5;
        double draw = 3.0;
        double awayWin = 2.8;

        if (widget.match.homeScore != null && widget.match.awayScore != null) {
          final homeScore = widget.match.homeScore!;
          final awayScore = widget.match.awayScore!;
          final totalGoals = homeScore + awayScore;

          // Upravit kurzy podle výsledku
          if (homeScore > awayScore) {
            homeWin = 1.8;
            draw = 3.5;
            awayWin = 4.0;
          } else if (awayScore > homeScore) {
            homeWin = 4.0;
            draw = 3.5;
            awayWin = 1.8;
          } else {
            homeWin = 3.0;
            draw = 2.2;
            awayWin = 3.0;
          }

          // Kurzy na počet gólů
          if (totalGoals > 2.5) {
            // Více gólů bylo, takže kurz na over bude nižší
            odds = MatchOdds(
              matchId: widget.match.id,
              homeWin: homeWin,
              draw: draw,
              awayWin: awayWin,
              over25: 1.6,
              under25: 2.3,
              bothTeamsScore: 1.7,
              bothTeamsNoScore: 2.1,
              homeWinOrDraw: 1.3,
              awayWinOrDraw: 1.4,
              homeOrAway: 1.5,
            );
          } else {
            odds = MatchOdds(
              matchId: widget.match.id,
              homeWin: homeWin,
              draw: draw,
              awayWin: awayWin,
              over25: 2.3,
              under25: 1.6,
              bothTeamsScore: 2.2,
              bothTeamsNoScore: 1.6,
              homeWinOrDraw: 1.4,
              awayWinOrDraw: 1.3,
              homeOrAway: 1.5,
            );
          }
        } else {
          // Zápas ještě nezačal nebo není znám výsledek - výchozí kurzy
          // Vypočítat kurzy pro dvojice na základě základních kurzů
          final calculated1X = 1 / (1 / homeWin + 1 / draw);
          final calculatedX2 = 1 / (1 / draw + 1 / awayWin);
          final calculated12 = 1 / (1 / homeWin + 1 / awayWin);
          
          odds = MatchOdds(
            matchId: widget.match.id,
            homeWin: homeWin,
            draw: draw,
            awayWin: awayWin,
            over25: 1.9,
            under25: 1.9,
            bothTeamsScore: 1.9,
            bothTeamsNoScore: 1.9,
            homeWinOrDraw: calculated1X,
            awayWinOrDraw: calculatedX2,
            homeOrAway: calculated12,
          );
        }

        // Uložit do Firestore
        await _firestoreService.saveMatchOdds(widget.match.id, odds);
      }

      setState(() {
        _odds = odds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Nepodařilo se načíst kurzy: ${e.toString()}';
      });
    }
  }

  String? _getBetCategory(String betType) {
    return _betCategories[betType];
  }

  double _getBetOdds(String betType) {
    if (_odds == null) return 1.0;
    
    switch (betType) {
      case 'home':
        return _odds!.homeWin;
      case 'draw':
        return _odds!.draw;
      case 'away':
        return _odds!.awayWin;
      case 'over25':
        return _odds!.over25 ?? 1.0;
      case 'under25':
        return _odds!.under25 ?? 1.0;
      case 'btts_yes':
        return _odds!.bothTeamsScore ?? 1.0;
      case 'btts_no':
        return _odds!.bothTeamsNoScore ?? 1.0;
      case '1x':
        return _odds!.homeWinOrDraw ?? 1.0;
      case 'x2':
        return _odds!.awayWinOrDraw ?? 1.0;
      case '12':
        return _odds!.homeOrAway ?? 1.0;
      default:
        return 1.0;
    }
  }

  void _calculatePotentialWin() {
    double total = 0.0;
    
    for (var betType in _selectedBetTypes) {
      final controller = _amountControllers[betType];
      if (controller != null && controller.text.isNotEmpty) {
        final amount = double.tryParse(controller.text) ?? 0.0;
        if (amount > 0) {
          total += amount * _getBetOdds(betType);
        }
      }
    }

    setState(() {
      _totalPotentialWin = total;
    });
  }

  void _toggleBetSelection(String betType) {
    setState(() {
      final category = _getBetCategory(betType);
      
      // Zkontrolovat, jestli už není vybrána sázka ze stejné kategorie
      bool hasSameCategory = _selectedBetTypes.any((selected) => 
        _getBetCategory(selected) == category && selected != betType
      );
      
      if (hasSameCategory) {
        // Zobrazit chybu pod kategorií
        if (category != null) {
          _categoryErrors[category] = 'Můžete vybrat pouze jednu sázku z této kategorie';
        }
        return;
      }
      
      // Vymazat chybu kategorie při úspěšném výběru
      if (category != null) {
        _categoryErrors.remove(category);
      }
      _generalError = null;
      
      if (_selectedBetTypes.contains(betType)) {
        // Odstranit sázku
        _selectedBetTypes.remove(betType);
        _amountControllers[betType]?.dispose();
        _amountControllers.remove(betType);
        _fieldErrors.remove(betType);
      } else {
        // Přidat sázku
        _selectedBetTypes.add(betType);
        _amountControllers[betType] = TextEditingController();
        _amountControllers[betType]!.addListener(() {
          _validateAmount(betType);
          _calculatePotentialWin();
        });
      }
      
      _calculatePotentialWin();
    });
  }

  void _validateAmount(String betType) {
    setState(() {
      final controller = _amountControllers[betType];
      if (controller == null || controller.text.isEmpty) {
        _fieldErrors[betType] = 'Zadejte částku';
        return;
      }
      
      final amount = double.tryParse(controller.text);
      if (amount == null || amount <= 0) {
        _fieldErrors[betType] = 'Zadejte platnou částku větší než 0';
        return;
      }
      
      // Vypočítat celkovou částku všech sázek
      double totalAmount = 0.0;
      for (var type in _selectedBetTypes) {
        if (type != betType) {
          final otherController = _amountControllers[type];
          if (otherController != null && otherController.text.isNotEmpty) {
            final otherAmount = double.tryParse(otherController.text) ?? 0.0;
            totalAmount += otherAmount;
          }
        }
      }
      totalAmount += amount;
      
      if (totalAmount > _userBalance) {
        final available = _userBalance - (totalAmount - amount);
        if (available <= 0) {
          _fieldErrors[betType] = 'Nemáte dostatek peněz';
        } else {
          _fieldErrors[betType] = 'Dostupné: ${available.toStringAsFixed(0)} Kč';
        }
        // Automaticky upravit hodnotu na maximum
        if (amount > available && available > 0) {
          controller.text = available.toStringAsFixed(0);
        }
        return;
      }
      
      // Vymazat chybu pokud je vše v pořádku
      _fieldErrors.remove(betType);
    });
  }

  Future<void> _placeBet() async {
    setState(() {
      _generalError = null;
    });

    if (_selectedBetTypes.isEmpty) {
      setState(() {
        _generalError = 'Vyberte alespoň jednu sázku';
      });
      return;
    }

    // Validovat všechny částky
    bool hasErrors = false;
    for (var betType in _selectedBetTypes) {
      _validateAmount(betType);
      if (_fieldErrors.containsKey(betType)) {
        hasErrors = true;
      }
    }

    if (hasErrors) {
      return;
    }

    // Zkontrolovat celkovou částku
    double totalAmount = 0.0;
    final Map<String, double> betAmounts = {};
    
    for (var betType in _selectedBetTypes) {
      final controller = _amountControllers[betType];
      if (controller == null) continue;
      
      final amount = double.tryParse(controller.text) ?? 0.0;
      betAmounts[betType] = amount;
      totalAmount += amount;
    }

    if (totalAmount > _userBalance) {
      setState(() {
        _generalError = 'Celková částka všech sázek (${totalAmount.toStringAsFixed(0)} Kč) přesahuje váš zůstatek (${_userBalance.toStringAsFixed(0)} Kč)';
      });
      return;
    }

    if (!_sessionManager.isLoggedIn) {
      setState(() {
        _generalError = 'Pro sázení se musíte přihlásit';
      });
      return;
    }

    final userEmail = _sessionManager.userEmail;
    if (userEmail == null) {
      setState(() {
        _generalError = 'Chyba při načítání uživatelského účtu';
      });
      return;
    }

    try {
      // Odebrat peníze z účtu
      final success = await _sessionManager.subtractBalance(totalAmount);
      if (!success) {
        setState(() {
          _generalError = 'Nepodařilo se odebrat peníze z účtu';
        });
        return;
      }

      // Vytvořit všechny sázky
      final List<Bet> bets = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      for (var i = 0; i < _selectedBetTypes.length; i++) {
        final betType = _selectedBetTypes.elementAt(i);
        final amount = betAmounts[betType]!;
        final odds = _getBetOdds(betType);
        
        final bet = Bet(
          id: 'bet_${timestamp}_${widget.match.id}_$i',
          userEmail: userEmail,
          matchId: widget.match.id,
          betType: betType,
          amount: amount,
          odds: odds,
          status: 'pending',
        );
        
        bets.add(bet);
      }

      // Uložit všechny sázky do Firestore
      for (var bet in bets) {
        await _firestoreService.saveBet(bet);
      }

      // Aktualizovat zůstatek
      await _loadBalance();

      if (mounted) {
        // Zavřít dialog bez zprávy
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _generalError = 'Chyba při umisťování sázek: ${e.toString()}';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Zkontrolovat, jestli je zápas už dokončený nebo probíhá
    final isMatchFinished = widget.match.isFinished;
    final isMatchLive = widget.match.isLive;
    final canBet = !isMatchFinished && !isMatchLive; // Sázet lze pouze na budoucí zápasy
    
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hlavička
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF3E5F44),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      // Logo a název ligy na středu
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.match.leagueLogo.isNotEmpty)
                              Image.network(
                                widget.match.leagueLogo,
                                width: 16,
                                height: 16,
                                errorBuilder: (context, error, stackTrace) => const SizedBox(),
                              ),
                            if (widget.match.leagueLogo.isNotEmpty) const SizedBox(width: 4),
                            Text(
                              widget.match.leagueName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tlačítko zavřít vpravo
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Týmy a výsledek
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Domácí tým
                      Expanded(
                        child: Column(
                          children: [
                            if (widget.match.homeLogo.isNotEmpty)
                              Image.network(
                                widget.match.homeLogo,
                                width: 48,
                                height: 48,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 48, color: Colors.white),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              widget.match.homeTeam,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Výsledek a stav
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              widget.match.homeScore != null && widget.match.awayScore != null
                                  ? '${widget.match.homeScore} - ${widget.match.awayScore}'
                                  : '- : -',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isMatchLive
                                    ? Colors.red
                                    : isMatchFinished
                                        ? Colors.grey[700]
                                        : Colors.green[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isMatchLive
                                    ? widget.match.status
                                    : isMatchFinished
                                        ? 'FT'
                                        : _formatMatchTime(widget.match),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (canBet) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Zůstatek: ${_userBalance.toStringAsFixed(0)} Kč',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Hostující tým
                      Expanded(
                        child: Column(
                          children: [
                            if (widget.match.awayLogo.isNotEmpty)
                              Image.network(
                                widget.match.awayLogo,
                                width: 48,
                                height: 48,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_soccer, size: 48, color: Colors.white),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              widget.match.awayTeam,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Obsah
            Flexible(
              child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _errorMessage != null
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          : _odds == null
                              ? const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text('Kurzy nejsou k dispozici'),
                                  ),
                                )
                              : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Informace o stavu zápasu
                                  if (!canBet) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isMatchFinished
                                                  ? 'Zápas již skončil. Sázení není možné.'
                                                  : 'Zápas právě probíhá. Sázení není možné.',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  // Obecná chybová zpráva
                                  if (_generalError != null) ...[
                                    Text(
                                      _generalError!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  // Typ sázky
                                  const Text(
                                    'Kurzy:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3E5F44),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Výsledek zápasu
                                  _buildBetOption('home', 'Výhra ${widget.match.homeTeam}', _odds!.homeWin, canBet),
                                  const SizedBox(height: 8),
                                  _buildBetOption('draw', 'Remíza', _odds!.draw, canBet),
                                  const SizedBox(height: 8),
                                  _buildBetOption('away', 'Výhra ${widget.match.awayTeam}', _odds!.awayWin, canBet),
                                  if (_categoryErrors.containsKey('result')) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _categoryErrors['result']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // Počet gólů
                                  if (_odds!.over25 != null && _odds!.under25 != null) ...[
                                    const Text(
                                      'Počet gólů:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3E5F44),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildBetOption('over25', 'Více než 2.5 gólu', _odds!.over25!, canBet),
                                    const SizedBox(height: 8),
                                    _buildBetOption('under25', 'Méně než 2.5 gólu', _odds!.under25!, canBet),
                                    if (_categoryErrors.containsKey('goals')) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _categoryErrors['goals']!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                  ],
                                  // Oba týmy dají gól
                                  const Text(
                                    'Oba týmy dají gól:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3E5F44),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildBetOption('btts_yes', 'Ano', _odds!.bothTeamsScore ?? 1.9, canBet),
                                  const SizedBox(height: 8),
                                  _buildBetOption('btts_no', 'Ne', _odds!.bothTeamsNoScore ?? 1.9, canBet),
                                  if (_categoryErrors.containsKey('btts')) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _categoryErrors['btts']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // Dvojice
                                  const Text(
                                    'Dvojice:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3E5F44),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildBetOption('1x', '${widget.match.homeTeam} neprohraje (1X)', _odds!.homeWinOrDraw ?? 1.35, canBet),
                                  const SizedBox(height: 8),
                                  _buildBetOption('x2', '${widget.match.awayTeam} neprohraje (X2)', _odds!.awayWinOrDraw ?? 1.35, canBet),
                                  const SizedBox(height: 8),
                                  _buildBetOption('12', 'Remíza nebude (12)', _odds!.homeOrAway ?? 1.5, canBet),
                                  if (_categoryErrors.containsKey('double')) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _categoryErrors['double']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  // Částka a tlačítko pouze pokud lze sázet
                                  if (canBet) ...[
                                    // Částky pro vybrané sázky
                                    if (_selectedBetTypes.isNotEmpty) ...[
                                      const Text(
                                        'Vsazené částky:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3E5F44),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ..._selectedBetTypes.map((betType) => _buildBetAmountField(betType)),
                                      const SizedBox(height: 16),
                                      // Celková možná výhra
                                      if (_totalPotentialWin > 0) ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3E5F44).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Celková možná výhra:',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${_totalPotentialWin.toStringAsFixed(2)} Kč',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3E5F44),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Vyberte sázky výše a zadejte částky',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    // Tlačítko pro sázku
                                    if (_selectedBetTypes.isNotEmpty)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _placeBet,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF3E5F44),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            _selectedBetTypes.length > 1
                                                ? 'Vsadit ${_selectedBetTypes.length} sázky'
                                                : 'Vsadit',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMatchTime(Match match) {
    if (match.isLive) {
      return match.status;
    } else if (match.isFinished) {
      return 'FT';
    } else {
      final hour = match.date.hour.toString().padLeft(2, '0');
      final minute = match.date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }

  Widget _buildBetAmountField(String betType) {
    final controller = _amountControllers[betType];
    if (controller == null) return const SizedBox();
    
    String label = _getBetLabel(betType);
    final error = _fieldErrors[betType];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3E5F44),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Zadejte částku (max: ${_getMaxAmountForBet(betType).toStringAsFixed(0)} Kč)',
              suffixText: 'Kč',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: error != null ? Colors.red : const Color(0xFF3E5F44),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
            ),
            onChanged: (value) {
              // Omezit hodnotu na maximum
              final maxAmount = _getMaxAmountForBet(betType);
              if (value.isNotEmpty) {
                final amount = double.tryParse(value);
                if (amount != null && amount > maxAmount) {
                  controller.text = maxAmount.toStringAsFixed(0);
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              }
              _validateAmount(betType);
              _calculatePotentialWin();
            },
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getMaxAmountForBet(String betType) {
    // Vypočítat dostupnou částku (zůstatek minus ostatní sázky)
    double usedAmount = 0.0;
    for (var type in _selectedBetTypes) {
      if (type != betType) {
        final controller = _amountControllers[type];
        if (controller != null && controller.text.isNotEmpty) {
          final amount = double.tryParse(controller.text) ?? 0.0;
          usedAmount += amount;
        }
      }
    }
    return (_userBalance - usedAmount).clamp(0.0, _userBalance);
  }

  String _getBetLabel(String betType) {
    switch (betType) {
      case 'home':
        return 'Výhra ${widget.match.homeTeam}';
      case 'draw':
        return 'Remíza';
      case 'away':
        return 'Výhra ${widget.match.awayTeam}';
      case 'over25':
        return 'Více než 2.5 gólu';
      case 'under25':
        return 'Méně než 2.5 gólu';
      case 'btts_yes':
        return 'Oba týmy dají gól - Ano';
      case 'btts_no':
        return 'Oba týmy dají gól - Ne';
      case '1x':
        return '${widget.match.homeTeam} neprohraje (1X)';
      case 'x2':
        return '${widget.match.awayTeam} neprohraje (X2)';
      case '12':
        return 'Remíza nebude (12)';
      default:
        return betType;
    }
  }

  Widget _buildBetOption(String betType, String label, double odds, bool enabled) {
    final isSelected = _selectedBetTypes.contains(betType);
    return InkWell(
      onTap: enabled ? () => _toggleBetSelection(betType) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled
              ? (isSelected
                  ? const Color(0xFF3E5F44).withOpacity(0.2)
                  : Colors.grey[100])
              : Colors.grey[200],
          border: Border.all(
            color: enabled
                ? (isSelected
                    ? const Color(0xFF3E5F44)
                    : Colors.grey[300]!)
                : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: enabled
                    ? (isSelected ? const Color(0xFF3E5F44) : Colors.black87)
                    : Colors.grey[600],
              ),
            ),
            Text(
              odds.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: enabled
                    ? (isSelected ? const Color(0xFF3E5F44) : Colors.black87)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



