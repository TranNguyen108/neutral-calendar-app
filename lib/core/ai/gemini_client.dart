import 'dart:convert';
import 'package:http/http.dart' as http;

/// Gemini AI Client for API communication
class GeminiClient {
  final String apiKey;
  static const String model =
      'gemini-2.5-flash'; // Latest Gemini 2.5 Flash model

  // 🆕 Rate limiting
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(seconds: 2);

  GeminiClient(this.apiKey);

  Future<String> generate(String prompt, {int retryCount = 0}) async {
    // 🆕 Rate limiting check
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        // Rate limiting in progress
        await Future.delayed(waitTime);
      }
    }

    try {
      final url =
          'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey';

      _lastRequestTime = DateTime.now();

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt}
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024,
              }
            }),
          )
          .timeout(const Duration(seconds: 30));

      // 🆕 Handle rate limit error with retry
      if (response.statusCode == 429) {
        if (retryCount < 3) {
          final retryDelay = Duration(seconds: (retryCount + 1) * 2);
          await Future.delayed(retryDelay);
          return generate(prompt, retryCount: retryCount + 1);
        } else {
          throw Exception(
              'Rate limit exceeded. Please wait a moment and try again.');
        }
      }

      if (response.statusCode != 200) {
        final errorBody = response.body;

        // 🆕 Check for quota exceeded
        if (response.statusCode == 429 && errorBody.contains('quota')) {
          throw Exception('❌ QUOTA EXCEEDED\n\n'
              '🔑 API key đã hết hạn mức miễn phí (20 requests/day)\n\n'
              '💡 Giải pháp:\n'
              '1. Đợi đến ngày mai để quota reset\n'
              '2. Tạo API key mới tại: https://aistudio.google.com/apikey\n'
              '3. Hoặc upgrade lên Paid tier để có unlimited requests\n\n'
              '⏰ Retry sau: 35 giây');
        }

        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['candidates'] == null ||
          jsonResponse['candidates'].isEmpty) {
        throw Exception('No response from AI');
      }

      final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];

      if (text == null || text.isEmpty) {
        throw Exception('Empty response from AI');
      }

      return text;
    } catch (e) {
      if (e.toString().contains('QUOTA EXCEEDED')) {
        rethrow; // Keep the formatted message
      }
      if (e.toString().contains('429')) {
        throw Exception('⚠️ Đã vượt quá giới hạn API\n\n'
            'Vui lòng:\n'
            '• Đợi vài phút\n'
            '• Hoặc tạo API key mới\n'
            '• Hoặc nâng cấp lên Paid tier');
      }
      throw Exception('Failed to generate AI response: $e');
    }
  }
}
