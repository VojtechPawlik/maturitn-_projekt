import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/localization_service.dart';
import '../services/session_manager.dart';
import '../services/firestore_service.dart';
import 'betting_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _handleFeedbackTap() async {
    // Feedback je dostupný jen pro přihlášené uživatele
    if (!SessionManager().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pro poslání zpětné vazby se prosím nejdříve přihlas.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const _FeedbackDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.translate('settings')),
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(LocalizationService.translate('general')),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: LocalizationService.translate('notifications'),
            subtitle: LocalizationService.translate('notifications_subtitle'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _saveNotifications,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Sázení'),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Color(0xFFFFFDE7),
                width: 2,
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF3E5F44)),
              title: const Text('Historie sázek'),
              subtitle: const Text('Zobrazit všechny vaše sázky'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BettingHistoryScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Feedback'),
          _buildSettingsTile(
            icon: Icons.feedback,
            title: 'Poslat zpětnou vazbu',
            subtitle: 'Chyba nebo nápad? Neváhejte mi napsat',
            onTap: _handleFeedbackTap,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(LocalizationService.translate('about_app')),
          _buildSettingsTile(
            icon: Icons.info,
            title: LocalizationService.translate('app_version'),
            subtitle: '1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog();

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedProblemType;
  bool _isSending = false;
  bool _isSuccess = false;

  final List<String> _problemTypes = const [
    'Technický problém',
    'Nápad na vylepšení',
    'Chyba v datech / zápasech',
    'Jiné',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userEmail = SessionManager().userEmail ?? 'neznámý uživatel';
    final problemType = _selectedProblemType ?? 'Jiné';
    final message = _messageController.text.trim();

    setState(() {
      _isSending = true;
      _isSuccess = false;
    });

    try {
      await FirestoreService().sendFeedback(
        userEmail: userEmail,
        problemType: problemType,
        message: message,
      );

      if (!mounted) return;

      setState(() {
        _isSuccess = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nepodařilo se odeslat zpětnou vazbu. Zkus to prosím znovu později.'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Zvětšit okno téměř přes celou šířku obrazovky
      insetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF3E5F44),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Zpětná vazba',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Vyber typ problému',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedProblemType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: _problemTypes
                          .map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: _isSending || _isSuccess
                          ? null
                          : (value) {
                              setState(() {
                                _selectedProblemType = value;
                              });
                            },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Prosím vyber typ problému.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Váš názor / popis problému:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: TextFormField(
                        controller: _messageController,
                        maxLines: null,
                        expands: true,
                        enabled: !_isSending && !_isSuccess,
                        decoration: const InputDecoration(
                          hintText:
                              'Např. nefunguje mi načítání zápasů, chtěl bych přidat novou funkci...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Prosím napiš aspoň krátkou zprávu.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isSuccess)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Zpětná vazba byla úspěšně odeslána. Děkuju!',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isSending || _isSuccess ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3E5F44),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Odeslat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



