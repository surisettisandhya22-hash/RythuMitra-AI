import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/language_utils.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );

    return _isInitialized;
  }

  Future<bool> startListening({
    required String languageId,
    required Function(String) onResult,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    final localeId = LanguageUtils.getLocaleForLanguage(languageId);

    if (!_speech.isListening) {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          partialResults: true,
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;
}
