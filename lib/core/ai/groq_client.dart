import 'dart:convert';
import 'package:http/http.dart' as http;

/// Groq AI Client for API communication
class GroqClient {
  final String apiKey;
  static const String model =
      'llama-3.3-70b-versatile'; // ✅ Working model (Jan 2026)

  // Rate limiting
  DateTime? _lastRequestTime;
  static const _minRequestInterval = Duration(milliseconds: 500);

  GroqClient(this.apiKey);

  Future<String> generate(String prompt, {int retryCount = 0}) async {
    // Rate limiting check
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        final waitTime = _minRequestInterval - timeSinceLastRequest;
        await Future.delayed(waitTime);
      }
    }

    try {
      final url = 'https://api.groq.com/openai/v1/chat/completions';

      print('Calling Groq API: $url');
      _lastRequestTime = DateTime.now();

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              "model": model,
              "messages": [
                {
                  "role": "user",
                  "content": prompt,
                }
              ],
              "temperature": 0.7,
              "max_tokens": 2048,
            }),
          )
          .timeout(const Duration(seconds: 30));

      // Handle rate limit error with retry
      if (response.statusCode == 429) {
        if (retryCount < 3) {
          final retryDelay = Duration(seconds: (retryCount + 1) * 2);
          print(
              'Rate limited (429). Retrying in ${retryDelay.inSeconds}s... (attempt ${retryCount + 1}/3)');
          await Future.delayed(retryDelay);
          return generate(prompt, retryCount: retryCount + 1);
        } else {
          throw Exception(
              'Rate limit exceeded. Please wait a moment and try again.');
        }
      }

      if (response.statusCode != 200) {
        final errorBody = response.body;

        if (response.statusCode == 429 && errorBody.contains('quota')) {
          throw Exception('❌ QUOTA EXCEEDED\n\n'
              '🔑 API key đã hết hạn mức\n\n'
              '💡 Giải pháp:\n'
              '1. Tạo API key mới tại: https://console.groq.com/keys\n'
              '2. Groq free tier: 30 requests/minute\n');
        }

        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }

      print('Raw Groq Response: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse['choices'] == null || jsonResponse['choices'].isEmpty) {
        throw Exception('No response from AI');
      }

      final text = jsonResponse['choices'][0]['message']['content'];

      print('Extracted text: $text');

      if (text == null || text.isEmpty) {
        throw Exception('Empty response from AI');
      }

      return text;
    } catch (e) {
      if (e.toString().contains('QUOTA EXCEEDED')) {
        rethrow;
      }
      if (e.toString().contains('429')) {
        throw Exception('⚠️ Đã vượt quá giới hạn API\n\n'
            'Vui lòng đợi vài giây hoặc tạo API key mới');
      }
      throw Exception('Failed to generate AI response: $e');
    }
  }
}
