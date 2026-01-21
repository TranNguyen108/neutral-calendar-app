import 'package:get/get.dart';
import 'groq_client.dart'; // 🆕 Changed to Groq
import 'ai_prompt_builder.dart';
import 'ai_personal_assistant.dart';
import 'ai_response_parser.dart';
import 'ai_models.dart';
import '../services/storage_service.dart';

/// Main AI Service for handling AI operations
class AIService extends GetxService {
  late GroqClient _client; // 🆕 Changed to Groq

  // API key - should be loaded from secure storage or environment
  String? _apiKey;
  final isInitialized = false.obs;
  final isProcessing = false.obs;

  Future<AIService> init({String? apiKey}) async {
    // Priority: 1. Passed parameter, 2. Storage, 3. Default
    _apiKey = apiKey ?? _getDefaultApiKey();

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _client = GroqClient(_apiKey!);
      isInitialized.value = true;
    }

    return this;
  }

  /// Get default API key from storage or environment
  String? _getDefaultApiKey() {
    // Try to load from storage first
    try {
      final storage = Get.find<StorageService>();
      final storedKey = storage.getApiKey();
      if (storedKey != null && storedKey.isNotEmpty) {
        return storedKey;
      }
    } catch (e) {
      // Storage not available yet during init
    }

    // Fall back to environment variable
    const envKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) {
      return envKey;
    }

    return null;
  }

  /// Set API key dynamically
  Future<bool> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    _client = GroqClient(apiKey); // 🆕 Changed to Groq
    isInitialized.value = true;
    return true;
  }

  /// 🆕 PERSONAL ASSISTANT - Process user input with intent detection
  Future<AIResponse<AIIntentResult>> processUserIntent(
    String userInput,
    SystemContext context,
  ) async {
    if (!isInitialized.value) {
      return AIResponse.failure(
        'AI Service not initialized',
        errorType: AIErrorType.apiError,
      );
    }

    if (userInput.trim().isEmpty) {
      return AIResponse.failure(
        'Input is empty',
        errorType: AIErrorType.ambiguousInput,
      );
    }

    try {
      isProcessing.value = true;

      // Build AI request
      final request = AIRequest(
        prompt: userInput,
        context: context,
        type: _inferRequestType(userInput),
      );

      // Generate prompt using Personal Assistant
      final prompt = AIPersonalAssistant.buildAssistantPrompt(request);

      // Call AI
      final rawResponse = await _client.generate(prompt);

      // Parse response
      try {
        final json = AIResponseParser.parseTask(rawResponse);
        final intentResult = AIIntentResult.fromJson(json);

        return AIResponse.success(intentResult, rawResponse: rawResponse);
      } catch (parseError) {
        return AIResponse.failure(
          'Failed to parse AI response: $parseError',
          errorType: AIErrorType.parseError,
          rawResponse: rawResponse,
        );
      }
    } catch (e) {
      if (e.toString().contains('404')) {
        return AIResponse.failure(
          'Model not found or API error',
          errorType: AIErrorType.modelFailure,
        );
      }
      return AIResponse.failure(
        'Unexpected error: ${e.toString()}',
        errorType: AIErrorType.apiError,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Infer request type from user input
  AIRequestType _inferRequestType(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('sinh nhật') ||
        lower.contains('birthday') ||
        lower.contains('event')) {
      return AIRequestType.createEvent;
    }
    if (lower.contains('mỗi') ||
        lower.contains('hàng ngày') ||
        lower.contains('habit')) {
      return AIRequestType.createHabit;
    }
    if (lower.contains('ghi nhớ') ||
        lower.contains('lưu ý') ||
        lower.contains('note')) {
      return AIRequestType.createNote;
    }
    if (lower.contains('hôm nay') &&
        (lower.contains('làm gì') || lower.contains('việc gì'))) {
      return AIRequestType.analyzeSchedule;
    }
    if (lower.contains('xung đột') ||
        lower.contains('conflict') ||
        lower.contains('trùng')) {
      return AIRequestType.detectConflicts;
    }
    if (lower.contains('gợi ý') || lower.contains('suggest')) {
      return AIRequestType.generateSuggestions;
    }

    // Default to task creation
    return AIRequestType.createTask;
  }

  /// @deprecated Use processUserIntent instead
  /// Create task from natural language text
  Future<AIResponse<AiTaskResult>> createTaskFromText(String text,
      {List<Map<String, dynamic>>? existingTasks}) async {
    if (!isInitialized.value) {
      return AIResponse.failure(
          'AI Service not initialized. Please set API key in settings.');
    }

    if (text.trim().isEmpty) {
      return AIResponse.failure('Input text is empty');
    }

    try {
      isProcessing.value = true;

      // Build prompt with existing tasks context
      final prompt = AIPromptBuilder.buildCreateTaskPrompt(text,
          existingTasks: existingTasks);

      // Call AI
      final rawResponse = await _client.generate(prompt);

      // Parse response
      final json = AIResponseParser.parseTask(rawResponse);
      final taskResult = AiTaskResult.fromJson(json);

      return AIResponse.success(taskResult, rawResponse: rawResponse);
    } catch (e) {
      return AIResponse.failure('Error: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Chat with AI - send message and get response
  Future<AIResponse<String>> chat(String userMessage,
      {Map<String, dynamic>? context}) async {
    if (!isInitialized.value) {
      return AIResponse.failure('AI Service not initialized');
    }

    try {
      isProcessing.value = true;

      // Build conversational prompt
      final prompt = _buildChatPrompt(userMessage, context);

      // Call AI
      final response = await _client.generate(prompt);

      return AIResponse.success(response, rawResponse: response);
    } catch (e) {
      return AIResponse.failure('Error: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Summarize schedule for a given date
  Future<AIResponse<String>> summarizeSchedule(
      DateTime date, List<Map<String, dynamic>> tasks) async {
    if (!isInitialized.value) {
      return AIResponse.failure('AI Service not initialized');
    }

    try {
      isProcessing.value = true;

      final prompt = _buildSummaryPrompt(date, tasks);
      final response = await _client.generate(prompt);

      return AIResponse.success(response, rawResponse: response);
    } catch (e) {
      return AIResponse.failure('Error: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Detect conflicts in schedule
  Future<AIResponse<Map<String, dynamic>>> detectConflicts(
      Map<String, dynamic> newTask,
      List<Map<String, dynamic>> existingTasks) async {
    if (!isInitialized.value) {
      return AIResponse.failure('AI Service not initialized');
    }

    try {
      isProcessing.value = true;

      final prompt = _buildConflictDetectionPrompt(newTask, existingTasks);
      final response = await _client.generate(prompt);
      final json = AIResponseParser.parseTask(response);

      return AIResponse.success(json, rawResponse: response);
    } catch (e) {
      return AIResponse.failure('Error: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Get smart suggestions based on user habits
  Future<AIResponse<List<String>>> getSuggestions(
      Map<String, dynamic> userContext) async {
    if (!isInitialized.value) {
      return AIResponse.failure('AI Service not initialized');
    }

    try {
      isProcessing.value = true;

      final prompt = _buildSuggestionPrompt(userContext);
      final response = await _client.generate(prompt);

      // Parse suggestions (expecting list of strings)
      final lines =
          response.split('\n').where((line) => line.trim().isNotEmpty).toList();

      return AIResponse.success(lines, rawResponse: response);
    } catch (e) {
      return AIResponse.failure('Error: ${e.toString()}');
    } finally {
      isProcessing.value = false;
    }
  }

  // Private helper methods for building prompts

  String _buildChatPrompt(String userMessage, Map<String, dynamic>? context) {
    final now = DateTime.now();
    final contextStr = context != null
        ? '\n\nContext:\n${context.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}'
        : '';

    return '''
You are a helpful AI assistant for a task management app.

Current date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}
Current time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}
$contextStr

User: $userMessage

Respond naturally and helpfully. If the user wants to create a task, analyze the request and respond with what you understood.
''';
  }

  String _buildSummaryPrompt(DateTime date, List<Map<String, dynamic>> tasks) {
    final tasksStr = tasks
        .map((t) => '- ${t['title']} at ${t['time'] ?? 'no time'}')
        .join('\n');

    return '''
Summarize the schedule for ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}:

Tasks:
$tasksStr

Provide a brief, natural language summary of the day's schedule. Be concise and friendly.
''';
  }

  String _buildConflictDetectionPrompt(
      Map<String, dynamic> newTask, List<Map<String, dynamic>> existingTasks) {
    final existingStr = existingTasks
        .map((t) => '- ${t['title']}: ${t['date']} ${t['time'] ?? 'all day'}')
        .join('\n');

    return '''
Detect if this new task conflicts with existing tasks:

New task:
- Title: ${newTask['title']}
- Date: ${newTask['date']}
- Time: ${newTask['time'] ?? 'not specified'}

Existing tasks:
$existingStr

Respond with JSON:
{
  "hasConflict": true/false,
  "conflictWith": "task title" or null,
  "suggestion": "what to do" or null
}
''';
  }

  String _buildSuggestionPrompt(Map<String, dynamic> userContext) {
    return '''
Based on user behavior and schedule, provide 3 smart suggestions:

User context:
${userContext.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Provide 3 actionable suggestions to improve productivity or schedule. Each suggestion should be one clear sentence.
''';
  }

  /// Check if service is ready to use
  bool get isReady => isInitialized.value && !isProcessing.value;

  /// Get current API key status
  String get apiKeyStatus {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'Not configured';
    }
    if (isInitialized.value) {
      return 'Active';
    }
    return 'Invalid';
  }
}
