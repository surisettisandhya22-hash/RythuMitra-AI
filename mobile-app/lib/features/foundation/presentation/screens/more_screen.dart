import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../emergency/presentation/screens/emergency_help_screen.dart';
import '../../../emergency/services/emergency_storage_service.dart';
import 'language_selection_screen.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/backup_service.dart';
import 'action_placeholder_screen.dart';
import '../../../settings/presentation/screens/voice_settings_screen.dart';
import '../../../settings/presentation/screens/backup_restore_screen.dart';
import '../../../settings/presentation/screens/backend_settings_screen.dart';
import '../../../information/presentation/screens/help_center_screen.dart';

class MoreScreen extends StatelessWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;

  const MoreScreen({
    super.key, 
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Preferences'),
          _buildMenuItem(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Change app language',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LanguageSelectionScreen(
                    storageService: storageService,
                    profileStorageService: profileStorageService,
                    networkService: networkService,
                    isFromSettings: true,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.wifi_tethering,
            title: 'Backend Connection',
            subtitle: 'Configure local server connection',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BackendSettingsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.record_voice_over,
            title: 'Voice Settings',
            subtitle: 'Voice speed, gender, and feedback',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VoiceSettingsScreen(storageService: storageService),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.cloud_sync,
            title: AppLocalizations.of(context).translate('backup_restore'),
            subtitle: 'Backup and restore farm data',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BackupRestoreScreen(
                    backupService: BackupService(
                      profileStorageService: profileStorageService,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Support'),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'App guide and FAQs',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HelpCenterScreen(
                    storageService: storageService,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.sos,
            title: AppLocalizations.of(context).translate('emergency_help'),
            subtitle: 'Important contacts & emergency',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmergencyHelpScreen(
                    emergencyStorageService: EmergencyStorageService(),
                    profileStorageService: profileStorageService,
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'About RythuMitra',
            subtitle: 'App version and details',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActionPlaceholderScreen(
                    title: 'About RythuMitra',
                    icon: Icons.info_outline,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
