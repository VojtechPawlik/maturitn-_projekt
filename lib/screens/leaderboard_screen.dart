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

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
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

      // Načíst seznam přátel uživatele
      final friends = await _firestoreService.getUserFriends(userEmail);
      
      // Přidat uživatele samotného do seznamu
      final allUsers = [userEmail, ...friends];
      
      // Načíst zůstatky všech uživatelů
      final entries = <LeaderboardEntry>[];
      for (var email in allUsers) {
        final balance = await _sessionManager.getBalanceForUser(email);
        final nickname = await _sessionManager.getNicknameForUser(email);
        entries.add(LeaderboardEntry(
          email: email,
          nickname: nickname,
          balance: balance,
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
                  ? const Center(
                      child: Text(
                        'Zatím nemáte žádné přátele v žebříčku',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLeaderboard,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final entry = _leaderboard[index];
                          final position = index + 1;
                          
                          return Card(
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
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getPositionColor(position),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$position',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
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
                            ),
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
}

class LeaderboardEntry {
  final String email;
  final String? nickname;
  final double balance;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.email,
    this.nickname,
    required this.balance,
    required this.isCurrentUser,
  });
}

