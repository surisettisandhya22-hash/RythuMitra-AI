import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/utils/language_utils.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Some basic configurations for Android
    await _flutterTts.setSpeechRate(0.5); // Default, can be overridden
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _isInitialized = true;
  }

  Future<void> setSpeed(double speed) async {
    await init();
    await _flutterTts.setSpeechRate(speed);
  }

  /// Sets up handlers for the TTS lifecycle
  void setCompletionHandler(void Function() onComplete) {
    _flutterTts.setCompletionHandler(onComplete);
    _flutterTts.setCancelHandler(onComplete);
    _flutterTts.setErrorHandler((msg) => onComplete());
  }

  /// Speak the given text in the specified language ID
  Future<bool> speak(String text, String languageId) async {
    if (text.isEmpty) return false;
    
    await init();
    
    final localeId = LanguageUtils.getLocaleForLanguage(languageId);
    
    // Check if the language is available on the device
    final isLanguageAvailable = await _flutterTts.isLanguageAvailable(localeId);
    if (isLanguageAvailable != true) {
      debugPrint('TTS Error: Voice not currently available for locale: $localeId');
      return false; // Let the caller know it failed so they can show an error or reset UI
    }

    await _flutterTts.setLanguage(localeId);
    final result = await _flutterTts.speak(text);
    return result == 1; // 1 means success in flutter_tts
  }

  /// Stop current speech
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
