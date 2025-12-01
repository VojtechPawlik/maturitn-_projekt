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

