/// Build prompts for AI requests
class AIPromptBuilder {
  static String buildCreateTaskPrompt(String userInput,
      {List<Map<String, dynamic>>? existingTasks}) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    final tasksContext = existingTasks != null && existingTasks.isNotEmpty
        ? '\n\nEXISTING TASKS:\n${existingTasks.map((t) => '- ${t['title']} on ${t['date']}').join('\n')}'
        : '';

    return '''
You are an AI assistant for a task management app.

Your job is to extract structured task data from user input.

CURRENT CONTEXT:
- Today's date: $today (${_getWeekday(now)})
- Tomorrow's date: $tomorrowStr (${_getWeekday(tomorrow)})
- Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}$tasksContext

INTELLIGENCE RULES:

1. DATE RANGES:
   - If user mentions "từ X đến Y" / "from X to Y": set "date" to start, "endDate" to end
   - Example: "30/1 đến 2/2 du lịch" → date: 2026-01-30, endDate: 2026-02-02

2. TASK vs SUBTASKS:
   - Main action = title
   - Items after commas = subtasks array
   - Example: "đi làm, mua nước, dây rút, sữa" → title: "đi làm", subtasks: ["mua nước", "dây rút", "sữa"]

3. TYPE DETECTION:
   - "sinh nhật" / "birthday" → type: "event", recurring: "yearly"
   - "ghi nhớ" / "lưu ý" / "note" → type: "note"
   - Default → type: "task"

4. DATE PARSING:
   - "hôm nay" / "today" = $today
   - "mai" / "ngày mai" / "tomorrow" = $tomorrowStr
   - "tuần sau" / "next week" = add 7 days
   - "DD/MM" format = interpret as ${now.year}
   - Month crossing: "30/1 đến 2/2" = Jan 30 to Feb 2

5. TIME PARSING:
   - "8h" / "8g" = "08:00"
   - "14h30" = "14:30"
   - Missing time = null

6. PRIORITY:
   - "quan trọng" / "urgent" / "gấp" = "high"
   - "bình thường" = "medium"
   - Default = "medium"

OUTPUT ONLY VALID JSON (no markdown, no explanation):

{
  "title": string,
  "date": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD" | null,
  "time": "HH:mm" | null,
  "priority": "low" | "medium" | "high",
  "type": "task" | "event" | "note",
  "recurring": "none" | "daily" | "weekly" | "monthly" | "yearly",
  "subtasks": [string] | null,
  "description": string | null,
  "confidence": number (0-1)
}

User input:
"$userInput"
''';
  }

  static String _getWeekday(DateTime date) {
    const days = [
      'Chủ nhật',
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7'
    ];
    return days[date.weekday % 7];
  }

  /// Build prompt for analyzing text and suggesting actions
  static String buildAnalyzeTextPrompt(String text) {
    return '''
Analyze the following text and suggest what type of item it should be:
- Task (if it's an action item with deadline)
- Note (if it's information to remember)
- Event (if it's a scheduled occasion)
- Diary (if it's a personal reflection)

Text: "$text"

Respond with JSON:
{
  "type": "task|note|event|diary",
  "confidence": 0.0-1.0,
  "reason": "Brief explanation"
}
''';
  }

  /// Build prompt for smart scheduling
  static String buildSmartSchedulePrompt({
    required String taskTitle,
    required List<Map<String, dynamic>> existingTasks,
    DateTime? preferredDate,
  }) {
    return '''
Suggest the best time to schedule this task:
Task: "$taskTitle"

Existing tasks: ${existingTasks.map((t) => '${t['title']} at ${t['startTime']}').join(', ')}

Preferred date: ${preferredDate?.toString() ?? 'any day this week'}

Suggest optimal date and time considering:
1. Avoid conflicts with existing tasks
2. Balance workload throughout the day
3. Consider task type (morning for focused work, afternoon for meetings)

Respond with JSON:
{
  "suggestedDate": "ISO 8601 date",
  "suggestedTime": "ISO 8601 datetime",
  "reason": "Brief explanation"
}
''';
  }
}
