/// Application-wide constants
class AppConstants {
  // Time Constants
  static const int urgentTaskThresholdMinutes = 120; // 2 hours
  static const int defaultReminderMinutes = 15;
  static const int defaultFocusDuration = 25; // Pomodoro default

  // Storage Keys
  static const String tasksKey = 'tasks';
  static const String focusSessionsKey = 'focus_sessions';
  static const String darkModeKey = 'darkMode';
  static const String languageKey = 'language';
  static const String customCategoriesKey = 'custom_categories';
  static const String dailyStreakKey = 'daily_streak';
  static const String lastCompletionDateKey = 'last_completion_date';
  static const String achievementsKey = 'achievements';

  // Default Categories
  static const List<String> defaultCategories = [
    'Work',
    'Study',
    'Personal',
    'Favorite',
  ];

  // Date/Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 16.0;

  // Limits
  static const int maxTasksPerDay = 50;
  static const int maxRecurrenceDays = 365;
  static const int maxNoteTitleLength = 100;
  static const int maxNoteBodyLength = 1000;

  // Cache Settings
  static const bool enableTaskCache = true;
  static const Duration cacheExpiration = Duration(minutes: 5);
}
