import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nicknameController = TextEditingController();
  
  String? _profileImagePath;
  String _nickname = '';
  String _userEmail = 'user@example.com';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Načíst data z SessionManager
    final session = SessionManager();
    setState(() {
      _nickname = session.userNickname ?? 'Fotbalový fanoušek'; 
      _nicknameController.text = _nickname;
      _userEmail = session.userEmail ?? 'user@example.com';
      _profileImagePath = session.profileImagePath;
    });
  }

  Future<void> _selectProfileImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Vyberte zdroj profilového obrázku',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Poznámka: Pro testování je použita simulace.\nVe finální verzi se otevře skutečná galerie/kamera.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0A84FF)),
              title: const Text('Vybrat z galerie'),
              subtitle: const Text('Otevře galerii s vašimi obrázky'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0A84FF)),
              title: const Text('Pořídit fotku'),
              subtitle: const Text('Otevře kameru pro pořízení nové fotky'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Odstranit fotku', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Smazat současný profilový obrázek'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }  Future<void> _pickImageFromGallery() async {
    setState(() => _isLoading = true);
    try {
      _showSuccessMessage('Otevírám galerii...');
      
      // Simulace načítání galerie
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 70% šance že uživatel zruší výběr (realistické)
      final random = DateTime.now().millisecondsSinceEpoch % 10;
      if (random < 7) {
        _showErrorMessage('Výběr z galerie byl zrušen');
        return;
      }
      
      // Simulace úspěšného výběru
      final imagePath = 'gallery_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      setState(() {
        _profileImagePath = imagePath;
      });
      await SessionManager().updateUserData(profileImagePath: imagePath);
      _showSuccessMessage('✅ Obrázek z galerie byl nastaven');
      
    } catch (e) {
      _showErrorMessage('Chyba při načítání z galerie: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _takePhoto() async {
    setState(() => _isLoading = true);
    try {
      _showSuccessMessage('Otevírám kameru...');
      
      // Simulace focení
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // 60% šance že uživatel zruší focení
      final random = DateTime.now().millisecondsSinceEpoch % 10;
      if (random < 6) {
        _showErrorMessage('Focení bylo zrušeno');
        return;
      }
      
      // Simulace úspěšného focení
      final imagePath = 'camera_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      setState(() {
        _profileImagePath = imagePath;
      });
      await SessionManager().updateUserData(profileImagePath: imagePath);
      _showSuccessMessage('✅ Fotka byla pořízena a nastavena');
      
    } catch (e) {
      _showErrorMessage('Chyba při focení: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        _profileImagePath = null;
      });
      await SessionManager().updateUserData(profileImagePath: null);
      _showSuccessMessage('✅ Profilový obrázek byl odstraněn');
    } catch (e) {
      _showErrorMessage('Chyba při odstraňování obrázku: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nicknameController.text.trim().isEmpty) {
      _showErrorMessage('Přezdívka nemůže být prázdná');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Uložit do SessionManager
      await SessionManager().updateUserData(nickname: _nicknameController.text.trim());
      
      setState(() {
        _nickname = _nicknameController.text.trim();
      });
      
      _showSuccessMessage('Profil byl úspěšně uložen');
    } catch (e) {
      _showErrorMessage('Chyba při ukládání profilu: ${e.toString()}');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Úspěšně odhlášen'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('Chyba při odhlašování: ${e.toString()}');
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
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Odhlásit se'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profilový obrázek
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      border: Border.all(
                        color: const Color(0xFF0A84FF),
                        width: 3,
                      ),
                    ),
                    child: _profileImagePath == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: const Icon(
                              Icons.photo,
                              size: 60,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _selectProfileImage,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A84FF),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Přezdívka
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: 'Přezdívka',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
                helperText: 'Tato přezdívka se bude zobrazovat v aplikaci',
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _saveProfile(),
            ),
            
            const SizedBox(height: 32),
            
            // Informační karta
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informace o účtu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(_userEmail),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Tlačítka
            Column(
              children: [
                // Uložit profil
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _saveProfile,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Ukládám...' : 'Uložit profil'),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Odhlásit se
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Odhlásit se'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}