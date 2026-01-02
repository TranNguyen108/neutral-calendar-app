import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart' hide Priority;

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<NotificationService> init() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    return this;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to task detail
    if (response.payload != null) {
      // You can parse the payload and navigate to the task
      // Get.toNamed(AppRoutes.TASK_DETAIL, arguments: taskId);
    }
  }

  /// Schedule a notification for a task
  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) {
      await init();
    }

    // Only schedule if task has a reminder and start time
    if (task.reminderMinutesBefore == null || task.startTime == null) {
      return;
    }

    // Don't schedule notifications for completed tasks
    if (task.status == TaskStatus.done) {
      return;
    }

    // Calculate notification time
    final notificationTime = task.startTime!
        .subtract(Duration(minutes: task.reminderMinutesBefore!));

    // Don't schedule notifications in the past
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      task.id.hashCode, // Use task ID hash as notification ID
      'Upcoming Task: ${task.title}',
      task.note ?? 'Your task is starting soon',
      tz.TZDateTime.from(notificationTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );
  }

  /// Cancel a specific task's notification
  Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) {
      await init();
    }
    await _notifications.cancel(taskId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) {
      await init();
    }
    await _notifications.cancelAll();
  }

  /// Request notification permissions (primarily for iOS)
  Future<bool> requestPermissions() async {
    if (!_initialized) {
      await init();
    }

    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? false;
  }

  /// Show an immediate notification
  Future<void> showNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    if (!_initialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
