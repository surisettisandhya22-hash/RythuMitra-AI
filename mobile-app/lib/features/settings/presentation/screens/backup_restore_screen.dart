import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  final BackupService backupService;

  const BackupRestoreScreen({
    super.key,
    required this.backupService,
  });

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;
  String _loadingMessage = '';

  void _setLoading(bool loading, [String message = '']) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        _loadingMessage = message;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleCreateBackup() async {
    _setLoading(true, 'Creating Backup...');
    try {
      final xFile = await widget.backupService.createBackup();
      if (!mounted) return;
      _setLoading(false);

      if (xFile != null) {
        // ignore: deprecated_member_use
        final result = await Share.shareXFiles([xFile], text: 'RythuMitra Backup');
        if (!mounted) return;
        if (result.status == ShareResultStatus.success) {
          _showSnackBar(AppLocalizations.of(context).translate('backup_success'));
        }
      } else {
        _showSnackBar('Failed to create backup.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _setLoading(false);
      _showSnackBar('An error occurred during backup.', isError: true);
    }
  }

  Future<void> _handleRestoreBackup() async {
    // Show confirmation dialog first
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('restore_farm_data')),
        content: Text(AppLocalizations.of(context).translate('backup_warning')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).translate('cancel'), style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).translate('continue_btn'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      PlatformFile? result = await FilePicker.pickFile(
        type: FileType.any,
      );

      if (!mounted) return;

      if (result != null && result.path != null) {
        _setLoading(true, AppLocalizations.of(context).translate('restoring_data'));
        
        final restoreResult = await widget.backupService.restoreBackup(result.path!);
        if (!mounted) return;
        
        _setLoading(false);
        
        if (restoreResult.success) {
          _showSnackBar(AppLocalizations.of(context).translate('restore_success'));
          // Pop back to MoreScreen so the UI fully refreshes the state
          if (mounted) Navigator.of(context).pop();
        } else {
          String errorMsg = AppLocalizations.of(context).translate('invalid_backup_file');
          if (restoreResult.errorType == BackupErrorType.unsupportedVersion) {
            errorMsg = AppLocalizations.of(context).translate('backup_not_supported');
          }
          _showSnackBar(errorMsg, isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _setLoading(false);
      _showSnackBar(AppLocalizations.of(context).translate('invalid_backup_file'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('backup_restore')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.cloud_sync,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context).translate('backup_restore'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Backup files contain your RythuMitra application data including profile, crops, reminders, and activities.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).translate('backup_photos_not_included'),
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Create Backup Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleCreateBackup,
                  icon: const Icon(Icons.upload_file, size: 28),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      AppLocalizations.of(context).translate('create_backup'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Restore Backup Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleRestoreBackup,
                  icon: Icon(Icons.download_rounded, size: 28, color: Colors.green.shade700),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      AppLocalizations.of(context).translate('restore_backup'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green.shade700, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessage,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
