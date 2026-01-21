import 'package:flutter/material.dart';

class MoodConstants {
  // Mood types
  static const String veryBad = 'very_bad';
  static const String bad = 'bad';
  static const String normal = 'normal';
  static const String good = 'good';
  static const String veryGood = 'very_good';

  // Mood colors - from dark to bright
  static const Map<String, Color> moodColors = {
    veryBad: Color(0xFFE57373), // Light Red
    bad: Color(0xFFFFB74D), // Light Orange
    normal: Color(0xFFFFEB3B), // Yellow
    good: Color(0xFF81C784), // Light Green
    veryGood: Color(0xFF64B5F6), // Light Blue
  };

  // Mood labels
  static const Map<String, String> moodLabels = {
    veryBad: 'Very Bad',
    bad: 'Bad',
    normal: 'Normal',
    good: 'Good',
    veryGood: 'Very Happy',
  };

  // Mood emojis
  static const Map<String, String> moodEmojis = {
    veryBad: '😢',
    bad: '😕',
    normal: '😐',
    good: '🙂',
    veryGood: '😄',
  };

  // Get all moods in order
  static List<String> get allMoods => [veryBad, bad, normal, good, veryGood];

  // Get color for mood
  static Color getColorForMood(String? mood) {
    if (mood == null) return moodColors[normal]!;
    return moodColors[mood] ?? moodColors[normal]!;
  }

  // Get label for mood
  static String getLabelForMood(String? mood) {
    if (mood == null) return moodLabels[normal]!;
    return moodLabels[mood] ?? moodLabels[normal]!;
  }

  // Get emoji for mood
  static String getEmojiForMood(String? mood) {
    if (mood == null) return moodEmojis[normal]!;
    return moodEmojis[mood] ?? moodEmojis[normal]!;
  }

  // === NEW: Numeric Mood Scale (1-5) ===
  // Convert mood string to numeric value for comparison
  // This enables mood change detection logic
  static const Map<String, int> moodToNumeric = {
    veryBad: 1,
    bad: 2,
    normal: 3,
    good: 4,
    veryGood: 5,
  };

  static int getMoodNumericValue(String? mood) {
    if (mood == null) return 3; // Default to normal
    return moodToNumeric[mood] ?? 3;
  }

  // === NEW: Mood Comparison Logic ===
  // Calculate the absolute difference between two moods
  // Used to detect "significant mood changes" (threshold: >= 2)
  static int getMoodDifference(String? mood1, String? mood2) {
    final value1 = getMoodNumericValue(mood1);
    final value2 = getMoodNumericValue(mood2);
    return (value1 - value2).abs();
  }

  // Check if mood change is significant enough to prompt user
  // Threshold: difference >= 2 (e.g., very_bad to normal, or normal to very_good)
  static bool isSignificantMoodChange(String? previousMood, String? newMood) {
    return getMoodDifference(previousMood, newMood) >= 2;
  }
}
