import 'package:get/get.dart';
import '../models/task.dart';

class NaturalLanguageParser extends GetxService {
  // Parse natural language input for quick add
  ParsedTask parseInput(String input) {
    final result = ParsedTask();

    // Clean input
    var text = input.trim();

    // Extract date keywords
    result.date = _extractDate(text);
    text = _removeDateKeywords(text);

    // Extract time
    final timeResult = _extractTime(text);
    result.startTime = timeResult.startTime;
    result.endTime = timeResult.endTime;
    text = timeResult.remainingText;

    // Extract priority
    final priorityResult = _extractPriority(text);
    result.priority = priorityResult.priority;
    text = priorityResult.remainingText;

    // What remains is the title
    result.title = text.trim();

    return result;
  }

  DateTime? _extractDate(String text) {
    final now = DateTime.now();
    final lowerText = text.toLowerCase();

    // Today
    if (lowerText.contains('today') || lowerText.contains('hôm nay')) {
      return now;
    }

    // Tomorrow
    if (lowerText.contains('tomorrow') || lowerText.contains('ngày mai')) {
      return now.add(const Duration(days: 1));
    }

    // Next week
    if (lowerText.contains('next week') || lowerText.contains('tuần sau')) {
      return now.add(const Duration(days: 7));
    }

    // Specific day names
    final weekdays = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
      'thứ 2': 1,
      'thứ 3': 2,
      'thứ 4': 3,
      'thứ 5': 4,
      'thứ 6': 5,
      'thứ 7': 6,
      'chủ nhật': 7,
    };

    for (var entry in weekdays.entries) {
      if (lowerText.contains(entry.key)) {
        final targetDay = entry.value;
        final currentDay = now.weekday;
        var daysToAdd = targetDay - currentDay;
        if (daysToAdd <= 0) daysToAdd += 7;
        return now.add(Duration(days: daysToAdd));
      }
    }

    return null;
  }

  String _removeDateKeywords(String text) {
    final keywords = [
      'today',
      'tomorrow',
      'hôm nay',
      'ngày mai',
      'next week',
      'tuần sau',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
      'thứ 2',
      'thứ 3',
      'thứ 4',
      'thứ 5',
      'thứ 6',
      'thứ 7',
      'chủ nhật'
    ];

    var result = text;
    for (var keyword in keywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }

    return result.trim();
  }

  TimeResult _extractTime(String text) {
    final result = TimeResult(remainingText: text);

    // Match patterns like "9-10", "9am-10am", "14:00-15:00"
    final timeRangePattern = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(?:am|pm)?\s*-\s*(\d{1,2})(?::(\d{2}))?\s*(?:am|pm)?',
      caseSensitive: false,
    );

    final match = timeRangePattern.firstMatch(text);
    if (match != null) {
      final startHour = int.parse(match.group(1)!);
      final startMin = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      final endHour = int.parse(match.group(3)!);
      final endMin = match.group(4) != null ? int.parse(match.group(4)!) : 0;

      final now = DateTime.now();
      result.startTime =
          DateTime(now.year, now.month, now.day, startHour, startMin);
      result.endTime = DateTime(now.year, now.month, now.day, endHour, endMin);

      result.remainingText = text.replaceFirst(match.group(0)!, '').trim();
    } else {
      // Single time like "9am", "14:00"
      final singleTimePattern = RegExp(
        r'(\d{1,2})(?::(\d{2}))?\s*(?:am|pm)?',
        caseSensitive: false,
      );

      final singleMatch = singleTimePattern.firstMatch(text);
      if (singleMatch != null) {
        final hour = int.parse(singleMatch.group(1)!);
        final min =
            singleMatch.group(2) != null ? int.parse(singleMatch.group(2)!) : 0;

        final now = DateTime.now();
        result.startTime = DateTime(now.year, now.month, now.day, hour, min);

        result.remainingText =
            text.replaceFirst(singleMatch.group(0)!, '').trim();
      }
    }

    return result;
  }

  PriorityResult _extractPriority(String text) {
    final lowerText = text.toLowerCase();

    final highKeywords = [
      'urgent',
      'important',
      'high priority',
      'khẩn cấp',
      'quan trọng'
    ];
    final lowKeywords = ['low priority', 'thấp'];

    for (var keyword in highKeywords) {
      if (lowerText.contains(keyword)) {
        return PriorityResult(
          priority: Priority.high,
          remainingText:
              text.replaceAll(RegExp(keyword, caseSensitive: false), '').trim(),
        );
      }
    }

    for (var keyword in lowKeywords) {
      if (lowerText.contains(keyword)) {
        return PriorityResult(
          priority: Priority.low,
          remainingText:
              text.replaceAll(RegExp(keyword, caseSensitive: false), '').trim(),
        );
      }
    }

    return PriorityResult(priority: Priority.medium, remainingText: text);
  }
}

class ParsedTask {
  String title = '';
  DateTime? date;
  DateTime? startTime;
  DateTime? endTime;
  Priority priority = Priority.medium;
}

class TimeResult {
  DateTime? startTime;
  DateTime? endTime;
  String remainingText;

  TimeResult({this.startTime, this.endTime, required this.remainingText});
}

class PriorityResult {
  final Priority priority;
  final String remainingText;

  PriorityResult({required this.priority, required this.remainingText});
}
