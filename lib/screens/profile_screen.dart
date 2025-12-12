import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/localization_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _profileImageUrl;
  String? _originalProfileImageUrl;
  String _userEmail = 'user@example.com';
  String? _nickname;
  String? _originalNickname;
  bool _isLoading = false;
  bool _canClaimDailyReward = false;
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  Set<String> _favoriteTeams = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFavoriteTeams().then((_) => _loadTeams());
    _searchController.addListener(_filterTeams);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Načíst oblíbené týmy při každém zobrazení screenu (např. po návratu z jiného screenu)
    _loadFavoriteTeams().then((_) {
      if (mounted) {
        _filterTeams(); // Aktualizovat seznam týmů s novými oblíbenými
      }
    });
    // Zkontrolovat každodenní odměnu při každém zobrazení
    _checkDailyReward();
  }

  Future<void> _loadFavoriteTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = SessionManager().userEmail;
      
      // Načíst oblíbené týmy vázané na email uživatele
      if (userEmail != null) {
        final favoriteTeamsList = prefs.getStringList('favorite_teams_$userEmail') ?? [];
      setState(() {
        _favoriteTeams = favoriteTeamsList.toSet();
      });
      } else {
        setState(() {
          _favoriteTeams = {};
        });
      }
    } catch (e) {
      // Chyba při načítání
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _filterTeams() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<Team> filtered;
      if (query.isEmpty) {
        filtered = _teams;
      } else {
        filtered = _teams.where((team) {
          return team.name.toLowerCase().contains(query) ||
                 team.league.toLowerCase().contains(query);
        }).toList();
      }
      
      // Seřadit: oblíbené týmy nahoře
      filtered.sort((a, b) {
        final aIsFavorite = _favoriteTeams.contains(a.name);
        final bIsFavorite = _favoriteTeams.contains(b.name);
        
        if (aIsFavorite && !bIsFavorite) return -1;
        if (!aIsFavorite && bIsFavorite) return 1;
        return a.name.compareTo(b.name);
      });
      
      _filteredTeams = filtered;
    });
  }

  Future<void> _loadUserData() async {
    // Načíst data z SessionManager
    final session = SessionManager();
    setState(() {
      _userEmail = session.userEmail ?? 'user@example.com';
      _profileImageUrl = session.profileImageUrl;
      _originalProfileImageUrl = session.profileImageUrl;
      _nickname = session.userNickname;
      _originalNickname = session.userNickname;
      _nicknameController.text = _nickname ?? '';
    });
    
    // Zkontrolovat, zda může získat každodenní odměnu
    _checkDailyReward();
  }

  Future<void> _checkDailyReward() async {
    final canClaim = await SessionManager().canClaimDailyReward();
    setState(() {
      _canClaimDailyReward = canClaim;
    });
  }

  Future<void> _shareFriendLink() async {
    final userEmail = SessionManager().userEmail;
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nejste přihlášeni'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Zobrazit dialog pro zadání emailu kamaráda
    final friendEmailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Přidat kamaráda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Zadejte email kamaráda, kterého chcete přidat do žebříčku:'),
            const SizedBox(height: 16),
            TextField(
              controller: friendEmailController,
              decoration: const InputDecoration(
                labelText: 'Email kamaráda',
                hintText: 'kamarad@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () async {
              final friendEmail = friendEmailController.text.trim();
              if (friendEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zadejte email kamaráda'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (friendEmail == userEmail) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nemůžete přidat sami sebe'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              
              // Přidat kamaráda
              setState(() {
                _isLoading = true;
              });

              final success = await _firestoreService.addFriend(
                userEmail,
                friendEmail,
              );

              setState(() {
                _isLoading = false;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Kamarád byl přidán do žebříčku'
                          : 'Nepodařilo se přidat kamaráda (možná už je přidán)',
                    ),
                    backgroundColor: success ? Colors.green : Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E5F44),
              foregroundColor: Colors.white,
            ),
            child: const Text('Přidat'),
          ),
        ],
      ),
    );
  }

  Future<void> _claimDailyReward() async {
    setState(() => _isLoading = true);
    
    try {
      final success = await SessionManager().claimDailyReward();
      
      if (success) {
        setState(() {
          _canClaimDailyReward = false;
        });
      }
    } catch (e) {
      // Chyba při vyzvedávání odměny - tichá chyba
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _hasChanges => 
      _profileImageUrl != _originalProfileImageUrl ||
      _nickname != _originalNickname;

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() => _isLoading = true);
    try {
      // Předat prázdný string pokud je přezdívka smazána, jinak hodnotu nebo null
      final nicknameToSave = _nicknameController.text.isEmpty ? '' : _nickname;
      
      await SessionManager().updateUserData(
        profileImageUrl: _profileImageUrl,
        nickname: nicknameToSave,
      );
      setState(() {
        _originalProfileImageUrl = _profileImageUrl;
        _originalNickname = _nickname;
      });
      
      if (mounted) {
        // Vrátit true pro indikaci změny, aby se aktualizovala hlavní stránka
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při ukládání: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await _firestoreService.getTeams();
      // Seřadit: oblíbené týmy nahoře
      teams.sort((a, b) {
        final aIsFavorite = _favoriteTeams.contains(a.name);
        final bIsFavorite = _favoriteTeams.contains(b.name);
        
        if (aIsFavorite && !bIsFavorite) return -1;
        if (!aIsFavorite && bIsFavorite) return 1;
        return a.name.compareTo(b.name);
      });
      
      setState(() {
        _teams = teams;
        _filteredTeams = teams;
      });
    } catch (e) {
      // Chyba při načítání týmů
    }
  }

  Future<void> _selectProfileImage() async {
    if (_teams.isEmpty) {
      await _loadTeams();
    }

    _searchController.clear();
    _filterTeams();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Vyberte logo týmu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Vyhledávací pole
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setModalState(() {
                        _filterTeams();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Hledat tým...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _teams.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredTeams.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Žádné týmy nenalezeny'),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredTeams.length + (_profileImageUrl != null ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Možnost odstranit obrázek na začátku
                                if (index == 0 && _profileImageUrl != null) {
                                  return ListTile(
                                    leading: const Icon(Icons.delete, color: Colors.red),
                                    title: const Text('Odstranit logo', style: TextStyle(color: Colors.red)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _removeProfileImage();
                                    },
                                  );
                                }
                                
                            final teamIndex = _profileImageUrl != null ? index - 1 : index;
                            final team = _filteredTeams[teamIndex];
                            final isFavorite = _favoriteTeams.contains(team.name);
                            
                            return ListTile(
                              leading: team.logoUrl.isNotEmpty && team.logoUrl.startsWith('http')
                                  ? Image.network(
                                      team.logoUrl,
                                      width: 40,
                                      height: 40,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.sports_soccer);
                                      },
                                    )
                                  : const Icon(Icons.sports_soccer),
                              title: Text(team.name),
                              subtitle: Text(team.league),
                              trailing: isFavorite
                                  ? const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                _selectTeamLogo(team.logoUrl);
                              },
                            );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectTeamLogo(String logoUrl) async {
    setState(() {
      _profileImageUrl = logoUrl;
    });
  }

  Future<void> _removeProfileImage() async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        _profileImageUrl = null;
      });
      await SessionManager().updateUserData(profileImageUrl: null);
    } catch (e) {
      // Chyba při odstraňování
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutConfirmDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      // Odhlásit z AuthService
      await _authService.signOut();
      
      // Vymazat session
      await SessionManager().logoutUser();
      
      if (mounted) {
        // Vrátit se zpět na main screen a obnovit jeho stav
        Navigator.of(context).pop(true); // Vrátí true pro indikaci změny auth stavu
      }
    } catch (e) {
      // Chyba při odhlašování
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showLogoutConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odhlášení'),
        content: const Text('Opravdu se chcete odhlásit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(LocalizationService.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(LocalizationService.translate('logout')),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate('profile')),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profilový obrázek
            Center(
              child: GestureDetector(
                onTap: _selectProfileImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _profileImageUrl == null || _profileImageUrl!.isEmpty 
                            ? Colors.grey[200] 
                            : Colors.transparent,
                        border: _profileImageUrl == null || _profileImageUrl!.isEmpty
                            ? Border.all(
                                color: const Color(0xFF3E5F44),
                                width: 2,
                              )
                            : null,
                      ),
                      child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Color(0xFF3E5F44),
                            )
                          : ClipOval(
                              child: _profileImageUrl!.startsWith('http')
                                  ? Image.network(
                                      _profileImageUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFF3E5F44),
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(0xFF3E5F44),
                                    ),
                            ),
                    ),
                    // Ikona pro úpravu
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3E5F44),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Přezdívka
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Přezdívka',
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E5F44),
                ),
                hintText: 'Zadejte přezdívku',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3E5F44),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _nickname = value.isEmpty ? null : value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Každodenní odměna a Přidat kamaráda vedle sebe
            Row(
              children: [
                // Každodenní odměna
                Expanded(
                  child: Card(
                    elevation: 2,
                    color: const Color(0xFFFFFDE7).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF3E5F44),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '+ 50! denně',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3E5F44),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_canClaimDailyReward) ? null : _claimDailyReward,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E5F44),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _canClaimDailyReward ? 'Vyzvednout' : 'Vyzvednuto',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Přidat kamaráda
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.person_add,
                                color: Color(0xFF3E5F44),
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Přátelé',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E5F44),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _shareFriendLink,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3E5F44),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Přidat',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informační karta
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informace o účtu',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(LocalizationService.translate('email')),
                      subtitle: Text(_userEmail),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tlačítko uložit změny
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_isLoading || !_hasChanges) ? null : _saveChanges,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3E5F44),
                ),
                child: Text(_isLoading 
                  ? 'Ukládám...'
                  : LocalizationService.translate('save_changes')),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tlačítko odhlásit se
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: Text(LocalizationService.translate('logout')),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}