import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'Čeština';
  
  final List<String> _languages = ['Čeština', 'English'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Načíst uložený jazyk a téma
    setState(() {
      _selectedLanguage = LocalizationService.currentLanguage;
      _darkModeEnabled = ThemeService().isDarkMode;
    });
  }

  void _saveNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? LocalizationService.translate('notifications_on') : LocalizationService.translate('notifications_off')),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  void _saveDarkMode(bool value) {
    setState(() {
      _darkModeEnabled = value;
    });
    
    // Aplikovat téma okamžitě
    ThemeService().setDarkMode(value);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? LocalizationService.translate('dark_mode_on') : LocalizationService.translate('light_mode_on')),
        backgroundColor: value ? Colors.grey[800] : Colors.blue,
      ),
    );
  }

  void _saveLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    
    LocalizationService.setLanguage(language);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${LocalizationService.translate('language_changed')} $language'),
        backgroundColor: Colors.blue,
      ),
    );
    
    // Restartovat settings screen pro aplikování změn
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
          _buildSettingsTile(
            icon: Icons.dark_mode,
            title: LocalizationService.translate('dark_mode'),
            subtitle: LocalizationService.translate('dark_mode_subtitle'),
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: _saveDarkMode,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: LocalizationService.translate('language'),
            subtitle: _selectedLanguage,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader(LocalizationService.translate('about_app')),
          _buildSettingsTile(
            icon: Icons.info,
            title: LocalizationService.translate('app_version'),
            subtitle: '1.0.0',
          ),
          _buildSettingsTile(
            icon: Icons.feedback,
            title: LocalizationService.translate('feedback'),
            subtitle: LocalizationService.translate('feedback_subtitle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFeedbackDialog(),
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) => RadioListTile<String>(
            title: Text(language),
            value: language,
            groupValue: _selectedLanguage,
            onChanged: (value) {
              _saveLanguage(value!);
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();
    String selectedType = LocalizationService.translate('bug');
    final List<String> feedbackTypes = [
      LocalizationService.translate('bug'), 
      LocalizationService.translate('improvement'), 
      LocalizationService.translate('general_feedback')
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(LocalizationService.translate('feedback_title')),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocalizationService.translate('feedback_type')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: feedbackTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                Text(LocalizationService.translate('your_message')),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: LocalizationService.translate('feedback_placeholder'),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(LocalizationService.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                if (feedbackController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocalizationService.translate('thanks_feedback')),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // TODO: Odeslat zpětnou vazbu na server
                }
              },
              child: Text(LocalizationService.translate('send')),
            ),
          ],
        ),
      ),
    );
  }


}


