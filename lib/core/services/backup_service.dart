import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import 'storage_service.dart';

/// Service for creating and managing data backups
class BackupService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  static const String _backupFolderName = 'backups';
  static const int _maxBackups = 10; // Keep last 10 backups

  /// Create a full backup of all data
  Future<String> createBackup() async {
    try {
      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'tasks': _storage.getTasks().map((t) => t.toJson()).toList(),
        'focusSessions':
            _storage.getFocusSessions().map((s) => s.toJson()).toList(),
        'settings': {
          'darkMode': _storage.isDarkMode(),
          'language': _storage.getLanguage(),
          'dailyStreak': _storage.getDailyStreak(),
          'lastCompletionDate':
              _storage.getLastCompletionDate()?.toIso8601String(),
        },
        'achievements': _storage.getAchievements(),
        'behaviorLogs': _storage.getBehaviorLogs(),
      };

      final backupDir = await _getBackupDirectory();
      await backupDir.create(recursive: true);

      final timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');

      await file.writeAsString(jsonEncode(backupData));

      // Clean up old backups
      await _cleanupOldBackups(backupDir);

      Get.log('Backup created: ${file.path}');
      return file.path;
    } catch (e) {
      Get.log('Error creating backup: $e', isError: true);
      rethrow;
    }
  }

  /// Automatic backup - called periodically
  Future<void> autoBackup() async {
    try {
      // Check if we should create a backup
      final lastBackup = await getLastBackupTime();
      final now = DateTime.now();

      // Create backup if last one was more than 24 hours ago
      if (lastBackup == null || now.difference(lastBackup).inHours >= 24) {
        await createBackup();
        Get.log('Automatic backup completed');
      }
    } catch (e) {
      Get.log('Auto backup failed: $e', isError: true);
    }
  }

  /// Get list of available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final backups = <BackupInfo>[];
      for (final file in files) {
        final stat = await file.stat();
        final size = stat.size;

        // Parse timestamp from filename
        final fileName = file.uri.pathSegments.last;
        DateTime? createdAt;

        if (fileName.startsWith('backup_')) {
          final timeStr = fileName
              .replaceAll('backup_', '')
              .replaceAll('.json', '')
              .replaceAll('_', ' ');
          try {
            createdAt = DateFormat('yyyy-MM-dd HH-mm-ss').parse(timeStr);
          } catch (e) {
            // Fallback to file modification time
            createdAt = stat.modified;
          }
        } else {
          createdAt = stat.modified;
        }

        backups.add(BackupInfo(
          path: file.path,
          createdAt: createdAt,
          sizeBytes: size,
        ));
      }

      // Sort by creation time (newest first)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      Get.log('Error getting backup list: $e', isError: true);
      return [];
    }
  }

  /// Restore data from a backup file
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $backupPath');
      }

      final content = await file.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;

      // Validate backup version
      final version = backupData['version'] as int?;
      if (version == null || version != 1) {
        throw Exception('Unsupported backup version: $version');
      }

      // Create safety backup of current data before restore
      await createBackup();

      // Restore tasks
      if (backupData.containsKey('tasks')) {
        final tasksJson = backupData['tasks'] as List;
        final tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
        await _storage.saveTasks(tasks);
      }

      // Restore focus sessions
      if (backupData.containsKey('focusSessions')) {
        final sessionsJson = backupData['focusSessions'] as List;
        await _storage.write('focusSessions', sessionsJson);
      }

      // Restore settings
      if (backupData.containsKey('settings')) {
        final settings = backupData['settings'] as Map<String, dynamic>;
        if (settings.containsKey('darkMode')) {
          await _storage.setDarkMode(settings['darkMode'] as bool);
        }
        if (settings.containsKey('language')) {
          await _storage.setLanguage(settings['language'] as String);
        }
        if (settings.containsKey('dailyStreak')) {
          await _storage.setDailyStreak(settings['dailyStreak'] as int);
        }
        if (settings.containsKey('lastCompletionDate') &&
            settings['lastCompletionDate'] != null) {
          await _storage.setLastCompletionDate(
            DateTime.parse(settings['lastCompletionDate'] as String),
          );
        }
      }

      // Restore achievements
      if (backupData.containsKey('achievements')) {
        final achievements =
            (backupData['achievements'] as List).cast<Map<String, dynamic>>();
        await _storage.saveAchievements(achievements);
      }

      // Restore behavior logs
      if (backupData.containsKey('behaviorLogs')) {
        final logs =
            (backupData['behaviorLogs'] as List).cast<Map<String, dynamic>>();
        await _storage.saveBehaviorLogs(logs);
      }

      Get.log('Backup restored successfully from: $backupPath');
      return true;
    } catch (e) {
      Get.log('Error restoring backup: $e', isError: true);
      return false;
    }
  }

  /// Export data to a specific location
  Future<String?> exportBackup(String destinationPath) async {
    try {
      final backupPath = await createBackup();
      final backupFile = File(backupPath);

      final destFile = File(destinationPath);
      await backupFile.copy(destFile.path);

      Get.log('Backup exported to: $destinationPath');
      return destFile.path;
    } catch (e) {
      Get.log('Error exporting backup: $e', isError: true);
      return null;
    }
  }

  /// Import backup from external file
  Future<bool> importBackup(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Import file not found: $sourcePath');
      }

      // Copy to backup directory first
      final backupDir = await _getBackupDirectory();
      await backupDir.create(recursive: true);

      final timestamp =
          DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'imported_$timestamp.json';
      final destFile = File('${backupDir.path}/$fileName');

      await sourceFile.copy(destFile.path);

      // Restore from the imported file
      return await restoreFromBackup(destFile.path);
    } catch (e) {
      Get.log('Error importing backup: $e', isError: true);
      return false;
    }
  }

  /// Delete a specific backup
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        Get.log('Backup deleted: $backupPath');
        return true;
      }
      return false;
    } catch (e) {
      Get.log('Error deleting backup: $e', isError: true);
      return false;
    }
  }

  /// Get the time of the last backup
  Future<DateTime?> getLastBackupTime() async {
    final backups = await getAvailableBackups();
    return backups.isNotEmpty ? backups.first.createdAt : null;
  }

  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_backupFolderName');
  }

  /// Clean up old backups, keep only the most recent ones
  Future<void> _cleanupOldBackups(Directory backupDir) async {
    try {
      final backups = await getAvailableBackups();

      if (backups.length > _maxBackups) {
        // Delete oldest backups
        final toDelete = backups.skip(_maxBackups);
        for (final backup in toDelete) {
          await deleteBackup(backup.path);
        }
        Get.log('Cleaned up ${toDelete.length} old backups');
      }
    } catch (e) {
      Get.log('Error cleaning up backups: $e', isError: true);
    }
  }

  /// Get total size of all backups
  Future<int> getTotalBackupSize() async {
    final backups = await getAvailableBackups();
    return backups.fold<int>(0, (sum, backup) => sum + backup.sizeBytes);
  }
}

/// Information about a backup file
class BackupInfo {
  final String path;
  final DateTime createdAt;
  final int sizeBytes;

  BackupInfo({
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get fileName => path.split(Platform.pathSeparator).last;

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy HH:mm').format(createdAt);
  }
}
