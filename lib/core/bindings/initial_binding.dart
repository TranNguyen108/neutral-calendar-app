import 'package:get/get.dart';

import '../repositories/project_repository.dart';
import '../repositories/project_repository_impl.dart';
import '../repositories/task_repository.dart';
import '../repositories/task_repository_impl.dart';
import '../services/achievement_service.dart';
import '../services/attachment_service.dart';
import '../services/backup_service.dart';
import '../services/behavior_logging_service.dart';
import '../services/daily_summary_service.dart';
import '../services/migration_service.dart';
import '../services/motivational_service.dart';
import '../services/natural_language_parser.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';
import '../services/smart_suggestion_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';
import '../services/widget_service.dart';
import '../utils/logger.dart';

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    // Put logger first
    Get.put(Logger(), permanent: true);

    // MUST await StorageService to be fully initialized before other services
    await Get.putAsync<StorageService>(() async {
      return await StorageService().init();
    }, permanent: true);

    // Initialize Repositories (abstraction over storage)
    Get.put<TaskRepository>(
      TaskRepositoryImpl(Get.find<StorageService>()),
      permanent: true,
    );
    Get.put<ProjectRepository>(
      ProjectRepositoryImpl(Get.find<StorageService>()),
      permanent: true,
    );

    // Migration Service (run migrations before other services use data)
    final migrationService = MigrationService(
      Get.find<TaskRepository>(),
      Get.find<ProjectRepository>(),
      Get.find<StorageService>(),
    );
    Get.put(migrationService, permanent: true);
    await migrationService.runMigrations();

    // Backup Service (initialize and run auto-backup)
    final backupService = BackupService();
    Get.put(backupService, permanent: true);
    // Run automatic backup in background (non-blocking)
    backupService.autoBackup().catchError((e) {
      Get.log('Auto backup failed: $e', isError: true);
    });

    // Sync Service (initialize for cloud sync - optional)
    // Note: Firebase must be initialized first in main.dart
    final syncService = SyncService();
    Get.put(syncService, permanent: true);
    // Auto sign-in anonymously and sync (non-blocking)
    syncService.signInAnonymously().then((_) {
      if (syncService.isOnline.value) {
        syncService.syncAll().catchError((e) {
          Get.log('Initial sync failed: $e', isError: true);
        });
      }
    }).catchError((e) {
      Get.log('Sync service initialization failed: $e', isError: true);
    });

    // Now safe to initialize other services that depend on data
    Get.put(AttachmentService(), permanent: true);
    Get.put(RecurrenceService(), permanent: true);
    await Get.putAsync(() => NotificationService().init(), permanent: true);
    Get.put(AchievementService(), permanent: true);
    Get.put(MotivationalService(), permanent: true);
    Get.put(DailySummaryService(), permanent: true);
    Get.put(BehaviorLoggingService(), permanent: true);
    Get.put(SmartSuggestionService(), permanent: true);
    Get.put(NaturalLanguageParser(), permanent: true);

    // Widget Service (initialize for home screen widget)
    await Get.putAsync(() => WidgetService().init(), permanent: true);
    Get.find<WidgetService>().registerCallbacks();
  }
}
