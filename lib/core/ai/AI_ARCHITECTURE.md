# AI Personal Assistant - Architecture

## Overview
Hệ thống AI được thiết kế như một Personal Assistant thông minh, có khả năng:
- ✅ Hiểu ý định người dùng (intent detection)
- ✅ Phân loại hành động (task, event, habit, note)
- ✅ Yêu cầu xác nhận khi thông tin mơ hồ
- ✅ Trả về kế hoạch hành động có cấu trúc
- ✅ Xử lý lỗi có phân loại rõ ràng

## Core Models

### 1. AIRequest
```dart
AIRequest(
  prompt: "mai 8h đi làm, mua nước",
  context: SystemContext(
    currentTime: DateTime.now(),
    tasks: [...],
    events: [...],
    habits: [...],
  ),
  type: AIRequestType.createTask,
)
```

### 2. AIIntentResult (Response)
```dart
AIIntentResult(
  intent: UserIntent.createTask,
  confidence: 0.95,
  needsConfirmation: false,
  actions: [
    AIAction(
      type: AIActionType.createTask,
      data: {
        'title': 'đi làm',
        'startDateTime': '2026-01-10T08:00:00',
        'subtasks': ['mua nước'],
      },
      message: 'Đã tạo task "đi làm" vào mai 8h',
    ),
  ],
)
```

## Usage Example

### Cách sử dụng mới (Recommended)
```dart
final aiService = Get.find<AIService>();
final storage = Get.find<StorageService>();

// Build context
final context = SystemContext(
  currentTime: DateTime.now(),
  tasks: storage.getTasks().map((t) => {
    'title': t.title,
    'date': t.date.toIso8601String(),
  }).toList(),
);

// Process user input
final response = await aiService.processUserIntent(
  "30/1 đến 2/2 du lịch đà lạt",
  context,
);

if (response.success) {
  final result = response.data!;
  
  // Check if needs confirmation
  if (result.needsConfirmation) {
    // Show confirmation dialog
    for (var question in result.confirmationQuestions!) {
      print('❓ $question');
    }
  } else {
    // Execute actions
    for (var action in result.actions) {
      switch (action.type) {
        case AIActionType.createTask:
          _createTaskFromAction(action);
          break;
        case AIActionType.createEvent:
          _createEventFromAction(action);
          break;
        // ... other actions
      }
    }
  }
} else {
  // Handle error with error type
  switch (response.errorType) {
    case AIErrorType.parseError:
      print('AI trả về kết quả không hợp lệ');
      break;
    case AIErrorType.ambiguousInput:
      print('Đầu vào không rõ ràng');
      break;
    case AIErrorType.missingDate:
      print('Thiếu thông tin ngày tháng');
      break;
    // ...
  }
}
```

## Intent Types

| Intent | Khi nào | Ví dụ |
|--------|---------|-------|
| `createTask` | Nhiệm vụ cần làm | "mai 8h đi làm" |
| `createEvent` | Sự kiện, sinh nhật | "sinh nhật tôi 15/3" |
| `createHabit` | Thói quen lặp lại | "tập thể dục mỗi sáng" |
| `createNote` | Ghi chú thông tin | "password wifi: abc123" |
| `querySchedule` | Hỏi lịch | "hôm nay tôi làm gì?" |
| `detectConflicts` | Kiểm tra xung đột | "lịch tôi có bị trùng không?" |
| `requestSuggestions` | Xin gợi ý | "tôi nên làm gì tiếp theo?" |
| `generalQuestion` | Câu hỏi khác | "thời tiết hôm nay thế nào?" |
| `unclear` | Không rõ ý định | "abc xyz 123" |

## Confidence Levels

| Confidence | Ý nghĩa | Hành động |
|------------|---------|-----------|
| 0.9 - 1.0 | Rất rõ ràng | Thực thi ngay |
| 0.7 - 0.89 | Rõ ràng | Thực thi hoặc xác nhận nhẹ |
| 0.5 - 0.69 | Cần xác nhận | Hỏi người dùng |
| 0.3 - 0.49 | Mơ hồ | Yêu cầu làm rõ |
| 0.0 - 0.29 | Không rõ | Từ chối xử lý |

## Error Types

```dart
enum AIErrorType {
  parseError,        // AI trả về JSON không hợp lệ
  ambiguousInput,    // Đầu vào mơ hồ, nhiều ý nghĩa
  missingTime,       // Thiếu giờ
  missingDate,       // Thiếu ngày
  modelFailure,      // Model AI lỗi (404, 500)
  apiError,          // Lỗi kết nối API
  unknownIntent,     // Không xác định được ý định
}
```

## Recurring Rules

Ví dụ recurring rule chi tiết:

```dart
RecurringRule(
  frequency: 'weekly',
  interval: 1,           // Mỗi tuần
  daysOfWeek: [1, 3, 5], // Thứ 2, 4, 6
  endDate: DateTime(2026, 12, 31),
  occurrences: null,
)
```

## Migration Guide

### Từ code cũ:
```dart
// ❌ Old way
final response = await aiService.createTaskFromText(text);
if (response.success) {
  final taskData = response.data!;
  // Create task manually
}
```

### Sang code mới:
```dart
// ✅ New way
final response = await aiService.processUserIntent(text, context);
if (response.success) {
  final result = response.data!;
  // Handle actions automatically
  for (var action in result.actions) {
    executeAction(action);
  }
}
```

## Best Practices

1. **Always provide full context**: Bao gồm tasks, events, habits hiện tại
2. **Handle needsConfirmation**: Luôn kiểm tra và hỏi người dùng khi cần
3. **Check error type**: Xử lý từng loại lỗi riêng biệt
4. **Validate confidence**: Confidence < 0.7 nên confirm
5. **Test with edge cases**: Thử với input mơ hồ, thiếu thông tin
6. **Log for debugging**: Log rawResponse khi có lỗi parse

## Performance Notes

- Request timeout: 30s
- Context limit: 10 gần nhất cho tasks/events
- Confidence threshold: 0.5 (tối thiểu để execute)
- Max confirmationQuestions: 3

## Future Enhancements

- [ ] Support multi-turn conversation
- [ ] Cache common intents
- [ ] Offline intent detection
- [ ] User preference learning
- [ ] Smart scheduling suggestions
