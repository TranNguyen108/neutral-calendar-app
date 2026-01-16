import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Service xử lý Voice Input
class VoiceInputService extends GetxService {
  late stt.SpeechToText _speech;

  final isListening = false.obs;
  final isAvailable = false.obs;
  final recognizedText = ''.obs;
  final confidence = 0.0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _speech = stt.SpeechToText();
    await _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      final available = await _speech.initialize(
        onError: (error) {
          isListening.value = false;
        },
        onStatus: (status) {
          if (status == 'notListening') {
            isListening.value = false;
          }
        },
      );
      isAvailable.value = available;
    } catch (e) {
      isAvailable.value = false;
    }
  }

  /// Check và request microphone permission
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// Bắt đầu listening
  Future<bool> startListening({
    required Function(String text) onResult,
    String? localeId, // 'vi_VN' or 'en_US'
  }) async {
    if (!isAvailable.value) {
      await _checkAvailability();
      if (!isAvailable.value) {
        return false;
      }
    }

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      return false;
    }

    recognizedText.value = '';
    confidence.value = 0.0;
    isListening.value = true;

    try {
      await _speech.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          confidence.value = result.confidence;

          // Call callback with final result
          if (result.finalResult) {
            onResult(result.recognizedWords);
            stopListening();
          }
        },
        localeId: localeId ?? 'vi_VN', // Default Vietnamese
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onSoundLevelChange: (level) {
          // You can use this for visual feedback
        },
      );
      return true;
    } catch (e) {
      isListening.value = false;
      return false;
    }
  }

  /// Dừng listening
  Future<void> stopListening() async {
    if (isListening.value) {
      await _speech.stop();
      isListening.value = false;
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (isListening.value) {
      await _speech.cancel();
      isListening.value = false;
      recognizedText.value = '';
    }
  }

  /// Get available locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!isAvailable.value) {
      await _checkAvailability();
    }
    return await _speech.locales();
  }

  /// Check if locale is available
  Future<bool> isLocaleAvailable(String localeId) async {
    final locales = await getAvailableLocales();
    return locales.any((locale) => locale.localeId == localeId);
  }

  @override
  void onClose() {
    stopListening();
    super.onClose();
  }
}
