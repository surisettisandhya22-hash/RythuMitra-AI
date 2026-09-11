import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/profile/services/profile_storage_service.dart';

class BackupService {
  final ProfileStorageService profileStorageService;

  BackupService({
    required this.profileStorageService,
  });

  Future<XFile?> createBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> backupData = {
        'appName': 'RythuMitra',
        'backupVersion': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {
          'farmerProfile': prefs.getString('farmerProfile'),
          'farmProfile': prefs.getString('farmProfile'),
          'crops': prefs.getString('crops'),
          'growthUpdates': prefs.getString('growthUpdates'),
          'activities': prefs.getString('activities'),
          'farmExpenses': prefs.getString('farmExpenses'),
          'farmSales': prefs.getString('farmSales'),
          'farm_reminders': prefs.getString('farm_reminders'),
          'health_history_data': prefs.getString('health_history_data'),
        }
      };

      final String jsonString = jsonEncode(backupData);

      final directory = await getTemporaryDirectory();
      final File backupFile = File('${directory.path}/RythuMitra_Backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonString);

      return XFile(backupFile.path);
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return null;
    }
  }

  Future<BackupRestoreResult> restoreBackup(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        return BackupRestoreResult(success: false, errorType: BackupErrorType.invalidFile);
      }

      final String jsonString = await file.readAsString();
      Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(jsonString);
      } catch (_) {
        return BackupRestoreResult(success: false, errorType: BackupErrorType.invalidFormat);
      }

      if (backupData['appName'] != 'RythuMitra') {
        return BackupRestoreResult(success: false, errorType: BackupErrorType.notRythuMitraBackup);
      }

      final int version = backupData['backupVersion'] ?? 0;
      if (version > 1) {
        return BackupRestoreResult(success: false, errorType: BackupErrorType.unsupportedVersion);
      }

      final data = backupData['data'] as Map<String, dynamic>?;
      if (data == null) {
        return BackupRestoreResult(success: false, errorType: BackupErrorType.invalidFormat);
      }

      final prefs = await SharedPreferences.getInstance();

      // We only restore the supported keys
      final keys = [
        'farmerProfile',
        'farmProfile',
        'crops',
        'growthUpdates',
        'activities',
        'farmExpenses',
        'farmSales',
        'farm_reminders',
        'health_history_data'
      ];

      for (String key in keys) {
        if (data.containsKey(key) && data[key] != null) {
          await prefs.setString(key, data[key] as String);
        }
      }

      // Refresh the services so that notifiers update
      await profileStorageService.init();

      return BackupRestoreResult(success: true);
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return BackupRestoreResult(success: false, errorType: BackupErrorType.unknown);
    }
  }
}

enum BackupErrorType {
  none,
  invalidFile,
  invalidFormat,
  notRythuMitraBackup,
  unsupportedVersion,
  unknown,
}

class BackupRestoreResult {
  final bool success;
  final BackupErrorType errorType;

  BackupRestoreResult({
    required this.success,
    this.errorType = BackupErrorType.none,
  });
}
