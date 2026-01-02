import 'package:get/get.dart';
import '../utils/logger.dart';
import '../services/storage_service.dart';
import '../services/recurrence_service.dart';
import '../services/notification_service.dart';
import '../services/achievement_service.dart';
import '../services/motivational_service.dart';
import '../services/daily_summary_service.dart';
import '../services/behavior_logging_service.dart';
import '../services/smart_suggestion_service.dart';
import '../services/natural_language_parser.dart';

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    // Put logger first
    Get.put(Logger(), permanent: true);

    // MUST await StorageService to be fully initialized before other services
    await Get.putAsync<StorageService>(() async {
      return await StorageService().init();
    }, permanent: true);

    // Now safe to initialize other services that depend on StorageService
    Get.put(RecurrenceService(), permanent: true);
    await Get.putAsync(() => NotificationService().init(), permanent: true);
    Get.put(AchievementService(), permanent: true);
    Get.put(MotivationalService(), permanent: true);
    Get.put(DailySummaryService(), permanent: true);
    Get.put(BehaviorLoggingService(), permanent: true);
    Get.put(SmartSuggestionService(), permanent: true);
    Get.put(NaturalLanguageParser(), permanent: true);
  }
}
