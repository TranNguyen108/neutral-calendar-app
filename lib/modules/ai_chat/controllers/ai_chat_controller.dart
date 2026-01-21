import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/chat_message.dart';
import '../../../core/ai/ai_service.dart';
import '../../../core/ai/ai_models.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/content_service.dart';
import '../../../core/models/task.dart';
import '../../../core/models/event.dart';
import '../../../core/models/note.dart';
import '../../../core/models/diary.dart';

class AIChatController extends GetxController {
  final AIService _aiService = Get.find<AIService>();
  final StorageService _storage = Get.find<StorageService>();
  late final ContentService _content;

  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;
  final inputText = ''.obs;

  final _box = GetStorage();
  static const String _chatHistoryKey = 'ai_chat_history';

  @override
  void onInit() {
    super.onInit();
    _content = Get.find<ContentService>();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  void _loadChatHistory() {
    try {
      final data = _box.read(_chatHistoryKey);
      if (data != null) {
        messages.value =
            (data as List).map((e) => ChatMessage.fromJson(e)).toList();
      }
    } catch (e) {
      // Error loading chat history: $e
    }
  }

  void _saveChatHistory() {
    try {
      _box.write(_chatHistoryKey, messages.map((m) => m.toJson()).toList());
    } catch (e) {
      // Error saving chat history: $e
    }
  }

  void _addWelcomeMessage() {
    if (messages.isEmpty) {
      // Check if AI Service is initialized
      if (!_aiService.isInitialized.value) {
        messages.add(ChatMessage.ai(
          '⚠️ AI chưa được cấu hình.\n\n'
          'Để sử dụng AI, vui lòng:\n'
          '1. Lấy API key từ https://console.groq.com/keys\n'
          '2. Cấu hình trong Settings\n\n'
          '📝 Bạn vẫn có thể:\n'
          '• Tạo task thủ công qua nút "+" ở màn hình chính\n'
          '• Xem lịch trình trong tab Calendar\n'
          '• Quản lý notes/diary trong tab Manage',
        ));
      } else {
        messages.add(ChatMessage.ai(
          'Xin chào! Tôi là AI Assistant của Neutral Calendar. 🤖\n\n'
          'Tôi có thể giúp bạn:\n'
          '• Tạo task/sự kiện từ câu nói tự nhiên\n'
          '• Quản lý công việc hàng ngày\n'
          '• Đặt nhắc nhở và lịch trình\n'
          '• Tạo task định kỳ\n\n'
          'Hãy thử: "mai 8h họp team" hoặc "30/1 đến 2/2 du lịch đà lạt"',
        ));
      }
      _saveChatHistory();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 🆕 Prevent multiple concurrent requests
    if (isTyping.value) {
      // Already processing a request, skipping...
      return;
    }

    // Add user message
    final userMessage = ChatMessage.user(text);
    messages.add(userMessage);
    inputText.value = '';
    _saveChatHistory();

    // Show typing indicator
    isTyping.value = true;

    try {
      // 🆕 Use new AI Personal Assistant with conversation history
      await _handleUserIntentWithAI(text);
    } catch (e) {
      // Error in sendMessage: $e
      messages.add(ChatMessage.ai(
        '❌ Lỗi: ${e.toString().contains('429') ? 'Đã gọi API quá nhiều, vui lòng đợi một chút...' : 'Không thể xử lý yêu cầu'}',
        type: MessageType.error,
      ));
    } finally {
      isTyping.value = false;
      _saveChatHistory();
    }
  }

  /// 🆕 New method using AI Personal Assistant
  Future<void> _handleUserIntentWithAI(String text) async {
    try {
      // Build context with conversation history
      final existingTasks = _storage.getTasks();
      final tasksMap = existingTasks
          .map((t) => {
                'title': t.title,
                'date':
                    '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
              })
          .toList();

      // Build conversation history (last 5 messages)
      final conversationHistory = messages
          .take(messages.length > 10 ? 10 : messages.length)
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'message': m.content,
              })
          .toList();

      final context = SystemContext(
        currentTime: DateTime.now(),
        tasks: tasksMap,
        conversationHistory: conversationHistory,
      );

      // Call AI Personal Assistant
      final response = await _aiService.processUserIntent(text, context);

      if (response.success && response.data != null) {
        final result = response.data!;

        // Handle confirmation needed
        if (result.needsConfirmation) {
          final questionsText =
              result.confirmationQuestions!.map((q) => '❓ $q').join('\n');
          messages.add(ChatMessage.ai(
            '💭 Tôi cần thêm thông tin:\n\n$questionsText',
            type: MessageType.error,
          ));
          return;
        }

        // Execute actions
        for (final action in result.actions) {
          await _executeAction(action, result);
        }
      } else {
        // Fallback to old logic if new AI fails
        await _handleUserIntent(text);
      }
    } catch (e) {
      // AI Personal Assistant error: $e
      // Fallback to old logic
      await _handleUserIntent(text);
    }
  }

  /// Execute AI action
  Future<void> _executeAction(AIAction action, AIIntentResult result) async {
    switch (action.type) {
      case AIActionType.createTask:
        await _createTaskFromAction(action, result);
        break;
      case AIActionType.createEvent:
        await _createEventFromAction(action);
        break;
      case AIActionType.createNote:
        await _createNoteFromAction(action);
        break;
      case AIActionType.createHabit:
        await _createHabitFromAction(action);
        break;
      case AIActionType.updateTask:
        await _updateTaskFromAction(action);
        break;
      case AIActionType.deleteTask:
        await _deleteTaskFromAction(action);
        break;
      case AIActionType.askConfirmation:
        messages.add(ChatMessage.ai(action.message ?? 'Cần xác nhận'));
        break;
      case AIActionType.provideInformation:
        messages.add(
            ChatMessage.ai(action.message ?? result.explanation ?? 'Done'));
        break;
    }
  }

  /// Create task from AI action
  Future<void> _createTaskFromAction(
      AIAction action, AIIntentResult result) async {
    try {
      final data = action.data;
      final title = data['title'] as String;
      final startDateTimeStr = data['startDateTime'] as String?;
      final priority = data['priority'] as String? ?? 'medium';

      DateTime? startDateTime;
      if (startDateTimeStr != null) {
        startDateTime = DateTime.parse(startDateTimeStr);
      }

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        date: startDateTime ?? DateTime.now(),
        startTime: startDateTime,
        priority: _parsePriority(priority),
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tasks = _storage.getTasks();
      tasks.add(task);
      await _storage.saveTasks(tasks);

      messages.add(ChatMessage.ai(
        action.message ?? '✅ Đã tạo task: "$title"',
        type: MessageType.taskCreated,
        metadata: {'taskId': task.id},
      ));
    } catch (e) {
      messages
          .add(ChatMessage.ai('❌ Lỗi tạo task: $e', type: MessageType.error));
    }
  }

  Future<void> _createEventFromAction(AIAction action) async {
    try {
      final data = action.data;
      final title = data['title'] as String;
      final startDateStr = data['startDateTime'] as String?;
      final location = data['location'] as String?;
      final description = data['description'] as String?;

      DateTime startDate = DateTime.now();
      if (startDateStr != null) {
        startDate = DateTime.parse(startDateStr);
      }

      final event = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        date: startDate,
        time: startDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _content.saveEvent(event);

      messages.add(ChatMessage.ai(
        action.message ??
            '🎉 Đã tạo sự kiện: "$title"\n'
                '📅 ${_formatDate(startDate)}'
                '${location != null ? "\n📍 $location" : ""}',
        type: MessageType.taskCreated,
        metadata: {'eventId': event.id},
      ));
    } catch (e) {
      messages
          .add(ChatMessage.ai('❌ Lỗi tạo event: $e', type: MessageType.error));
    }
  }

  /// Create note from AI action
  Future<void> _createNoteFromAction(AIAction action) async {
    try {
      final data = action.data;
      final title = data['title'] as String;
      final content = data['content'] as String? ?? '';
      final category = data['category'] as String?;

      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        category: category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _content.saveNote(note);

      messages.add(ChatMessage.ai(
        action.message ??
            '📝 Đã tạo ghi chú: "$title"'
                '${category != null ? "\n📂 $category" : ""}',
        type: MessageType.taskCreated,
        metadata: {'noteId': note.id},
      ));
    } catch (e) {
      messages
          .add(ChatMessage.ai('❌ Lỗi tạo note: $e', type: MessageType.error));
    }
  }

  /// Create habit/diary from AI action
  Future<void> _createHabitFromAction(AIAction action) async {
    try {
      final data = action.data;
      final content = data['content'] as String;
      final date = data['date'] != null
          ? DateTime.parse(data['date'] as String)
          : DateTime.now();
      final mood = data['mood'] as String?;

      final diary = Diary(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: data['title'] as String? ?? '',
        date: date,
        content: content,
        mood: mood,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _content.saveDiary(diary);

      messages.add(ChatMessage.ai(
        action.message ??
            '📔 Đã tạo nhật ký cho ${_formatDate(date)}'
                '${mood != null ? "\n😊 Tâm trạng: $mood" : ""}',
        type: MessageType.taskCreated,
        metadata: {'diaryId': diary.id},
      ));
    } catch (e) {
      messages
          .add(ChatMessage.ai('❌ Lỗi tạo diary: $e', type: MessageType.error));
    }
  }

  /// Update task from AI action
  Future<void> _updateTaskFromAction(AIAction action) async {
    try {
      final data = action.data;
      final taskId = data['taskId'] as String?;
      final title = data['title'] as String?;

      if (taskId == null) {
        // Search by title
        final tasks = _storage.getTasks();
        final matchedTask = tasks.firstWhereOrNull((t) =>
            title != null &&
            t.title.toLowerCase().contains(title.toLowerCase()));

        if (matchedTask == null) {
          messages.add(ChatMessage.ai(
            '❓ Không tìm thấy task phù hợp. Vui lòng chính xác hơn.',
            type: MessageType.error,
          ));
          return;
        }

        await _performTaskUpdate(matchedTask, data);
      } else {
        final tasks = _storage.getTasks();
        final task = tasks.firstWhereOrNull((t) => t.id == taskId);

        if (task == null) {
          messages.add(ChatMessage.ai(
            '❌ Không tìm thấy task với ID: $taskId',
            type: MessageType.error,
          ));
          return;
        }

        await _performTaskUpdate(task, data);
      }
    } catch (e) {
      messages.add(
          ChatMessage.ai('❌ Lỗi cập nhật task: $e', type: MessageType.error));
    }
  }

  Future<void> _performTaskUpdate(Task task, Map<String, dynamic> data) async {
    final updatedTask = task.copyWith(
      title: data['title'] as String? ?? task.title,
      date: data['date'] != null
          ? DateTime.parse(data['date'] as String)
          : task.date,
      startTime: data['startTime'] != null
          ? DateTime.parse(data['startTime'] as String)
          : task.startTime,
      priority: data['priority'] != null
          ? _parsePriority(data['priority'] as String)
          : task.priority,
      status: data['status'] != null
          ? _parseStatus(data['status'] as String)
          : task.status,
      updatedAt: DateTime.now(),
    );

    final tasks = _storage.getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = updatedTask;
      await _storage.saveTasks(tasks);

      messages.add(ChatMessage.ai(
        '✅ Đã cập nhật task: "${updatedTask.title}"',
        type: MessageType.taskCreated,
        metadata: {'taskId': updatedTask.id},
      ));
    }
  }

  /// Delete task from AI action
  Future<void> _deleteTaskFromAction(AIAction action) async {
    try {
      final data = action.data;
      final taskId = data['taskId'] as String?;
      final title = data['title'] as String?;

      final tasks = _storage.getTasks();
      Task? taskToDelete;

      if (taskId != null) {
        taskToDelete = tasks.firstWhereOrNull((t) => t.id == taskId);
      } else if (title != null) {
        taskToDelete = tasks.firstWhereOrNull(
            (t) => t.title.toLowerCase().contains(title.toLowerCase()));
      }

      if (taskToDelete == null) {
        messages.add(ChatMessage.ai(
          '❓ Không tìm thấy task để xóa.',
          type: MessageType.error,
        ));
        return;
      }

      tasks.removeWhere((t) => t.id == taskToDelete!.id);
      await _storage.saveTasks(tasks);

      messages.add(ChatMessage.ai(
        '🗑️ Đã xóa task: "${taskToDelete.title}"',
        type: MessageType.taskCreated,
      ));
    } catch (e) {
      messages
          .add(ChatMessage.ai('❌ Lỗi xóa task: $e', type: MessageType.error));
    }
  }

  TaskStatus _parseStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('done') ||
        lower.contains('hoàn thành') ||
        lower.contains('xong')) {
      return TaskStatus.done;
    }
    if (lower.contains('progress') || lower.contains('đang làm')) {
      return TaskStatus.inProgress;
    }
    return TaskStatus.todo;
  }

  /// ⚠️ OLD LOGIC - Fallback only
  Future<void> _handleUserIntent(String text) async {
    final lowerText = text.toLowerCase();

    // Intent: Create task from natural language
    if (_isCreateTaskIntent(lowerText)) {
      await _handleCreateTask(text);
    }
    // Intent: Summarize schedule
    else if (_isSummaryIntent(lowerText)) {
      await _handleSummary(text);
    }
    // Intent: Detect conflicts
    else if (_isConflictCheckIntent(lowerText)) {
      await _handleConflictCheck();
    }
    // Intent: Get suggestions
    else if (_isSuggestionIntent(lowerText)) {
      await _handleSuggestions();
    }
    // Default: General chat
    else {
      await _handleGeneralChat(text);
    }
  }

  bool _isCreateTaskIntent(String text) {
    return text.contains('tạo') ||
        text.contains('thêm') ||
        text.contains('nhắc') ||
        text.contains('lịch') ||
        text.contains('task') ||
        text.contains('ngày mai') ||
        text.contains('hôm nay') ||
        RegExp(r'\d+[hg]').hasMatch(text); // Contains time like "8h" or "8g"
  }

  bool _isSummaryIntent(String text) {
    return (text.contains('hôm nay') || text.contains('today')) &&
        (text.contains('làm gì') ||
            text.contains('việc gì') ||
            text.contains('lịch trình') ||
            text.contains('schedule'));
  }

  bool _isConflictCheckIntent(String text) {
    return text.contains('trùng') ||
        text.contains('xung đột') ||
        text.contains('conflict') ||
        text.contains('check lịch');
  }

  bool _isSuggestionIntent(String text) {
    return text.contains('gợi ý') ||
        text.contains('suggest') ||
        text.contains('nên') ||
        text.contains('recommendation');
  }

  Future<void> _handleCreateTask(String text) async {
    try {
      // Get existing tasks for duplicate check
      final existingTasks = _storage.getTasks();
      final tasksMap = existingTasks
          .map((t) => {
                'title': t.title,
                'date':
                    '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}',
              })
          .toList();

      final response =
          await _aiService.createTaskFromText(text, existingTasks: tasksMap);

      if (response.success && response.data != null) {
        final taskData = response.data!;

        // Check for duplicate
        final duplicate = existingTasks.where((t) {
          final sameTitle =
              t.title.toLowerCase() == taskData.title.toLowerCase();
          final sameDate = t.date.year == taskData.date.year &&
              t.date.month == taskData.date.month &&
              t.date.day == taskData.date.day;
          return sameTitle && sameDate;
        }).firstOrNull;

        if (duplicate != null) {
          messages.add(ChatMessage.ai(
            '⚠️ Bạn đã có task này rồi!\n\n'
            '📋 "${duplicate.title}"\n'
            '📅 Ngày: ${_formatDate(duplicate.date)}\n'
            '📊 Trạng thái: ${_getStatusText(duplicate.status)}\n\n'
            '💡 Bạn có muốn tạo task trùng không?',
            type: MessageType.error,
            metadata: {'existingTaskId': duplicate.id},
          ));
          return;
        }

        // Handle date range (create multiple tasks)
        final tasksToCreate = <Task>[];
        if (taskData.endDate != null) {
          var currentDate = taskData.date;
          while (currentDate.isBefore(taskData.endDate!) ||
              currentDate.isAtSameMomentAs(taskData.endDate!)) {
            tasksToCreate.add(_createTaskFromData(taskData, currentDate));
            currentDate = currentDate.add(const Duration(days: 1));
          }
        } else {
          tasksToCreate.add(_createTaskFromData(taskData, taskData.date));
        }

        // Save all tasks
        existingTasks.addAll(tasksToCreate);
        await _storage.saveTasks(existingTasks);

        // Build response message
        final sb = StringBuffer();
        if (tasksToCreate.length > 1) {
          sb.writeln(
              '✅ Đã tạo ${tasksToCreate.length} tasks cho khoảng thời gian:');
          sb.writeln('📋 "${taskData.title}"');
          sb.writeln(
              '📅 Từ ${_formatDate(taskData.date)} đến ${_formatDate(taskData.endDate!)}');
        } else {
          final task = tasksToCreate.first;
          sb.writeln(
              '✅ Đã tạo ${_getTypeEmoji(taskData.type)} ${_getTypeText(taskData.type)}:');
          sb.writeln('📋 "${task.title}"');
          sb.writeln('📅 ${_formatDate(task.date)}');
          if (task.startTime != null) {
            sb.writeln(
                '⏰ ${task.startTime!.hour}:${task.startTime!.minute.toString().padLeft(2, '0')}');
          }
          sb.writeln('🎯 ${_getPriorityText(task.priority)}');

          if (taskData.recurring != null && taskData.recurring != 'none') {
            sb.writeln('🔄 Lặp lại: ${_getRecurringText(taskData.recurring!)}');
          }

          if (taskData.subtasks != null && taskData.subtasks!.isNotEmpty) {
            sb.writeln('\n📝 Công việc con:');
            for (var subtask in taskData.subtasks!) {
              sb.writeln('  • $subtask');
            }
          }
        }

        messages.add(ChatMessage.ai(
          sb.toString(),
          type: MessageType.taskCreated,
          metadata: {'taskIds': tasksToCreate.map((t) => t.id).toList()},
        ));
      } else {
        messages.add(ChatMessage.ai(
          '❌ Không thể tạo task: ${response.error ?? 'Unknown error'}',
          type: MessageType.error,
        ));
      }
    } catch (e) {
      messages.add(ChatMessage.ai(
        '❌ Lỗi: Tính năng AI đang gặp sự cố.\n\n'
        '💡 Gợi ý: Bạn có thể tạo task thủ công bằng cách vào tab Today hoặc Calendar.\n\n'
        'Chi tiết: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e.toString()}',
        type: MessageType.error,
      ));
    }
  }

  Task _createTaskFromData(AiTaskResult taskData, DateTime date) {
    // Store subtasks in title if present
    String fullTitle = taskData.title;
    if (taskData.subtasks != null && taskData.subtasks!.isNotEmpty) {
      fullTitle =
          '$fullTitle\n${taskData.subtasks!.map((s) => '• $s').join('\n')}';
    }

    return Task(
      id: '${DateTime.now().millisecondsSinceEpoch}_${date.day}',
      title: fullTitle,
      date: date,
      startTime:
          taskData.time != null ? _parseTime(taskData.time!, date) : null,
      priority: _parsePriority(taskData.priority),
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handleSummary(String text) async {
    final today = DateTime.now();
    final todayTasks = _storage
        .getTasks()
        .where((t) =>
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day)
        .toList();

    if (todayTasks.isEmpty) {
      messages.add(ChatMessage.ai(
        '📅 Hôm nay bạn không có task nào. Hãy tận hưởng ngày nghỉ!',
        type: MessageType.summary,
      ));
      return;
    }

    final tasksData = todayTasks
        .map((t) => {
              'title': t.title,
              'time': t.startTime != null
                  ? '${t.startTime!.hour}:${t.startTime!.minute.toString().padLeft(2, '0')}'
                  : 'không có giờ',
              'priority': t.priority.name,
            })
        .toList();

    final response = await _aiService.summarizeSchedule(today, tasksData);

    if (response.success) {
      messages.add(ChatMessage.ai(
        '📅 Lịch trình hôm nay:\n\n${response.data}',
        type: MessageType.summary,
      ));
    } else {
      // Fallback summary
      final summary = todayTasks.map((t) {
        final timeStr = t.startTime != null
            ? '${t.startTime!.hour}:${t.startTime!.minute.toString().padLeft(2, '0')} - '
            : '';
        return '• $timeStr${t.title}';
      }).join('\n');

      messages.add(ChatMessage.ai(
        '📅 Lịch trình hôm nay:\n\n$summary',
        type: MessageType.summary,
      ));
    }
  }

  Future<void> _handleConflictCheck() async {
    final today = DateTime.now();
    final todayTasks = _storage
        .getTasks()
        .where((t) =>
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day &&
            t.startTime != null)
        .toList();

    if (todayTasks.length < 2) {
      messages.add(ChatMessage.ai(
        '✅ Không có xung đột thời gian nào trong lịch của bạn.',
        type: MessageType.conflict,
      ));
      return;
    }

    // Sort by time
    todayTasks.sort((a, b) => a.startTime!.compareTo(b.startTime!));

    // Check for overlaps (simple check: same time)
    final conflicts = <String>[];
    for (int i = 0; i < todayTasks.length - 1; i++) {
      final time1 = todayTasks[i].startTime!;
      final time2 = todayTasks[i + 1].startTime!;
      if (time1.hour == time2.hour && time1.minute == time2.minute) {
        final timeStr =
            '${time1.hour}:${time1.minute.toString().padLeft(2, '0')}';
        conflicts.add(
            '⚠️ $timeStr: "${todayTasks[i].title}" và "${todayTasks[i + 1].title}"');
      }
    }

    if (conflicts.isEmpty) {
      messages.add(ChatMessage.ai(
        '✅ Không có xung đột thời gian nào trong lịch của bạn.',
        type: MessageType.conflict,
      ));
    } else {
      messages.add(ChatMessage.ai(
        '⚠️ Phát hiện xung đột:\n\n${conflicts.join('\n')}\n\n'
        '💡 Gợi ý: Hãy dời một trong các task sang giờ khác.',
        type: MessageType.conflict,
      ));
    }
  }

  Future<void> _handleSuggestions() async {
    final tasks = _storage.getTasks();
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.done).length;
    final pendingTasks = tasks.where((t) => t.status == TaskStatus.todo).length;

    final context = {
      'total_tasks': tasks.length,
      'completed': completedTasks,
      'pending': pendingTasks,
      'completion_rate':
          tasks.isEmpty ? 0 : (completedTasks / tasks.length * 100).toInt(),
    };

    final response = await _aiService.getSuggestions(context);

    if (response.success && response.data != null) {
      final suggestions =
          response.data!.take(3).map((s) => '💡 $s').join('\n\n');

      messages.add(ChatMessage.ai(
        '🎯 Gợi ý cho bạn:\n\n$suggestions',
        type: MessageType.suggestion,
      ));
    } else {
      messages.add(ChatMessage.ai(
        '🎯 Một số gợi ý:\n\n'
        '💡 Ưu tiên hoàn thành các task quan trọng trước\n\n'
        '💡 Chia task lớn thành các task nhỏ hơn\n\n'
        '💡 Đặt thời gian cụ thể cho mỗi task',
        type: MessageType.suggestion,
      ));
    }
  }

  Future<void> _handleGeneralChat(String text) async {
    final tasks = _storage.getTasks();
    final context = {
      'total_tasks': tasks.length,
      'pending_tasks': tasks.where((t) => t.status == TaskStatus.todo).length,
      'current_date': DateTime.now().toIso8601String(),
    };

    final response = await _aiService.chat(text, context: context);

    if (response.success) {
      messages.add(ChatMessage.ai(response.data ?? 'Xin lỗi, tôi không hiểu.'));
    } else {
      messages.add(ChatMessage.ai(
        'Xin lỗi, tôi gặp lỗi khi xử lý câu hỏi của bạn.',
        type: MessageType.error,
      ));
    }
  }

  void clearHistory() {
    messages.clear();
    _addWelcomeMessage();
    _saveChatHistory();
  }

  // Helper methods

  DateTime? _parseTime(String time, DateTime date) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      // Invalid time format
    }
    return null;
  }

  Priority _parsePriority(String? priority) {
    if (priority == null) return Priority.medium;
    final p = priority.toLowerCase();
    if (p.contains('high') || p.contains('cao')) return Priority.high;
    if (p.contains('low') || p.contains('thấp')) return Priority.low;
    return Priority.medium;
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'Cao';
      case Priority.low:
        return 'Thấp';
      case Priority.medium:
        return 'Trung bình';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return 'Hôm nay';
    if (taskDate == tomorrow) return 'Ngày mai';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'Chưa làm';
      case TaskStatus.inProgress:
        return 'Đang làm';
      case TaskStatus.done:
        return 'Hoàn thành';
    }
  }

  String _getTypeEmoji(String type) {
    switch (type) {
      case 'event':
        return '🎉';
      case 'note':
        return '📝';
      default:
        return '✅';
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'event':
        return 'sự kiện';
      case 'note':
        return 'ghi chú';
      default:
        return 'task';
    }
  }

  String _getRecurringText(String recurring) {
    switch (recurring) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      case 'yearly':
        return 'Hàng năm';
      default:
        return 'Không lặp';
    }
  }
}
