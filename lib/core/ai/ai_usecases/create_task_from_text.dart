import '../gemini_client.dart';
import '../ai_prompt_builder.dart';
import '../ai_response_parser.dart';
import '../ai_models.dart';

/// Use case: Create task from natural language text using AI
class CreateTaskFromTextUseCase {
  final GeminiClient client;

  CreateTaskFromTextUseCase(this.client);

  Future<AiTaskResult> execute(String input) async {
    final prompt = AIPromptBuilder.buildCreateTaskPrompt(input);
    final raw = await client.generate(prompt);
    final json = AIResponseParser.parseTask(raw);

    return AiTaskResult.fromJson(json);
  }
}
