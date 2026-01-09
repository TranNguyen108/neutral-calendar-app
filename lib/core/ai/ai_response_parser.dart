import 'dart:convert';

/// Parse and validate AI responses
class AIResponseParser {
  static Map<String, dynamic> parseTask(String text) {
    try {
      // text is already extracted from API response by GeminiClient
      // Debug: Parsing AI response text

      // Clean and extract JSON
      String cleanedText = text.trim();

      // Remove markdown code blocks
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }

      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      cleanedText = cleanedText.trim();

      // Extract JSON if embedded
      final jsonStart = cleanedText.indexOf('{');
      final jsonEnd = cleanedText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanedText = cleanedText.substring(jsonStart, jsonEnd + 1);
      }

      // Debug: Cleaned text before parsing

      return jsonDecode(cleanedText) as Map<String, dynamic>;
    } catch (e) {
      // Parse error: $e
      throw Exception('Failed to parse AI response: $e');
    }
  }
}
