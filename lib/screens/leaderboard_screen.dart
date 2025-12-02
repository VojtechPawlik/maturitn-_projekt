import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SessionManager _sessionManager = SessionManager();
  final FirestoreService _firestoreService = FirestoreService();
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _expandedEntryEmail; // Email kamaráda, jehož karta je rozbalená
  String? _actionMode; // 'delete' nebo 'send' - režim akce v rozbalené kartě
  final Map<String, TextEditingController> _amountControllers = {}; // Controllery pro částky

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    // Uvolnit všechny controllery
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    _amountControllers.clear();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pokud ještě není session v paměti (např. po úplném restartu appky), načíst ji
      if (!_sessionManager.isLoggedIn && _sessionManager.userEmail == null) {
        await _sessionManager.loadSavedSession();
      }

      final userEmail = _sessionManager.userEmail;
      final isLoggedIn = _sessionManager.isLoggedIn;

      if (!isLoggedIn || userEmail == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Nejste přihlášeni';
        });
        return;
      }

      // Načíst seznam přátel uživatele
      final friends = await _firestoreService.getUserFriends(userEmail);
      
      // Přidat uživatele samotného do seznamu
      final allUsers = [userEmail, ...friends];
      
      // Načíst zůstatky, přezdívky a profilové obrázky všech uživatelů
      final entries = <LeaderboardEntry>[];
      for (var email in allUsers) {
        final balance = await _sessionManager.getBalanceForUser(email);
        final nickname = await _sessionManager.getNicknameForUser(email);
        final profileImageUrl = await _sessionManager.getProfileImageForUser(email);
        entries.add(LeaderboardEntry(
          email: email,
          nickname: nickname,
          balance: balance,
          profileImageUrl: profileImageUrl,
          isCurrentUser: email == userEmail,
        ));
      }

      // Seřadit podle zůstatku (sestupně)
      entries.sort((a, b) => b.balance.compareTo(a.balance));

      setState(() {
        _leaderboard = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chyba při načítání žebříčku: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onPressed: _loadLeaderboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E5F44),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Zkusit znovu'),
                      ),
                    ],
                  ),
                )
              : _leaderboard.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Zatím nemáte žádné přátele v žebříčku',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Přidejte kamaráda pomocí emailu v profilu.\n'
                                'Jakmile začnete sázet, porovnáme vaše ! (virtuální peníze)\n'
                                'a zobrazíme pořadí vás a vašich kamarádů.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeaderboard,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leaderboard.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Úvodní karta, která vysvětluje žebříček
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3E5F44).withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Žebříček kamarádů',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3E5F44),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Porovnáváme vás a vaše kamarády podle počtu ! (virtuálních peněz).\n'
                                      'Čím více ! máte, tím výše v žebříčku se zobrazíte.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final entry = _leaderboard[index - 1];
                          final position = index;
                          final isExpanded = _expandedEntryEmail == entry.email;

                          return Column(
                            children: [
                              Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: entry.isCurrentUser ? 4 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: entry.isCurrentUser
                                      ? const BorderSide(
                                          color: Color(0xFF3E5F44),
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Stack(
                                      children: [
                                        // Profilová fotka
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.grey[200],
                                          backgroundImage: (entry.profileImageUrl != null &&
                                                  entry.profileImageUrl!.isNotEmpty &&
                                                  entry.profileImageUrl!.startsWith('http'))
                                              ? NetworkImage(entry.profileImageUrl!)
                                              : null,
                                          child: (entry.profileImageUrl == null ||
                                                  entry.profileImageUrl!.isEmpty ||
                                                  !entry.profileImageUrl!.startsWith('http'))
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Color(0xFF3E5F44),
                                                )
                                              : null,
                                        ),
                                        // Odznak s pozicí
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: _getPositionColor(position),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$position',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Text(
                                    entry.nickname ?? entry.email.split('@')[0],
                                    style: TextStyle(
                                      fontWeight: entry.isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: entry.isCurrentUser
                                          ? const Color(0xFF3E5F44)
                                          : null,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3E5F44).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${entry.balance.toStringAsFixed(0)}!',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3E5F44),
                                      ),
                                    ),
                                  ),
                                  onTap: entry.isCurrentUser ? null : () {
                                    setState(() {
                                      _expandedEntryEmail = isExpanded ? null : entry.email;
                                    });
                                  },
                                ),
                              ),
                              // Rozbalená karta s možnostmi
                              if (isExpanded && !entry.isCurrentUser)
                                Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Color(0xFF3E5F44),
                                      width: 2,
                                    ),
                                  ),
                                  child: _actionMode == null
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _actionMode = 'send';
                                                      if (!_amountControllers.containsKey(entry.email)) {
                                                        _amountControllers[entry.email] = TextEditingController();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(
                                                          color: Colors.grey[300]!,
                                                          width: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'Poslat finance',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: Color(0xFF3E5F44),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _actionMode = 'delete';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    child: const Center(
                                                      child: Text(
                                                        'Smazat kamaráda',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : _actionMode == 'delete'
                                          ? Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  const Text(
                                                    'Opravdu chcete smazat tohoto kamaráda?',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      Expanded(
                                                        child: OutlinedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              _actionMode = null;
                                                            });
                                                          },
                                                          style: OutlinedButton.styleFrom(
                                                            side: const BorderSide(color: Colors.grey),
                                                          ),
                                                          child: const Text('Zrušit'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              _expandedEntryEmail = null;
                                                              _actionMode = null;
                                                            });
                                                            _removeFriend(entry.email);
                                                          },
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red,
                                                            foregroundColor: Colors.white,
                                                          ),
                                                          child: const Text('Smazat'),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: FutureBuilder<double>(
                                                future: _sessionManager.getBalance(),
                                                builder: (context, snapshot) {
                                                  final balance = snapshot.data ?? 0.0;
                                                  final controller = _amountControllers[entry.email] ?? TextEditingController();
                                                  
                                                  return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      const Text(
                                                        'Poslat finance',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF3E5F44),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 12),
                                                      TextField(
                                                        controller: controller,
                                                        keyboardType: TextInputType.number,
                                                        decoration: InputDecoration(
                                                          labelText: 'Částka',
                                                          hintText: 'Zadejte částku',
                                                          border: const OutlineInputBorder(),
                                                          suffixText: '!',
                                                          errorText: (() {
                                                            final amount = double.tryParse(controller.text);
                                                            if (controller.text.isNotEmpty) {
                                                              if (amount == null || amount <= 0) {
                                                                return 'Zadejte platnou částku';
                                                              }
                                                              if (amount > balance) {
                                                                return 'Dostupné: ${balance.toStringAsFixed(0)}!';
                                                              }
                                                            }
                                                            return null;
                                                          })(),
                                                        ),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            // Trigger rebuild pro zobrazení chyby
                                                          });
                                                        },
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Dostupné: ${balance.toStringAsFixed(0)}!',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          Expanded(
                                                            child: OutlinedButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  _actionMode = null;
                                                                });
                                                              },
                                                              style: OutlinedButton.styleFrom(
                                                                side: const BorderSide(color: Colors.grey),
                                                              ),
                                                              child: const Text('Zrušit'),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: ElevatedButton(
                                                              onPressed: () async {
                                                                final amount = double.tryParse(controller.text);
                                                                
                                                                // Validace
                                                                if (amount == null || amount <= 0) {
                                                                  return;
                                                                }
                                                                
                                                                if (amount > balance) {
                                                                  return; // Chyba se zobrazí v TextField
                                                                }

                                                                final userEmail = _sessionManager.userEmail;
                                                                if (userEmail == null) return;

                                                                final success = await _sessionManager.transferBalance(
                                                                  userEmail,
                                                                  entry.email,
                                                                  amount,
                                                                );

                                                                if (mounted) {
                                                                  setState(() {
                                                                    _expandedEntryEmail = null;
                                                                    _actionMode = null;
                                                                    controller.clear();
                                                                  });
                                                                  if (success) {
                                                                    _loadLeaderboard();
                                                                  }
                                                                }
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: const Color(0xFF3E5F44),
                                                                foregroundColor: Colors.white,
                                                              ),
                                                              child: const Text('Poslat'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return const Color(0xFF3E5F44);
    }
  }


  Future<void> _removeFriend(String friendEmail) async {
    final userEmail = _sessionManager.userEmail;
    if (userEmail == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat kamaráda?'),
        content: const Text('Opravdu chcete tohoto kamaráda smazat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestoreService.removeFriend(userEmail, friendEmail);
      if (mounted) {
        _loadLeaderboard();
      }
    }
  }

}

class LeaderboardEntry {
  final String email;
  final String? nickname;
  final String? profileImageUrl;
  final double balance;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.email,
    this.nickname,
    this.profileImageUrl,
    required this.balance,
    required this.isCurrentUser,
  });
}

