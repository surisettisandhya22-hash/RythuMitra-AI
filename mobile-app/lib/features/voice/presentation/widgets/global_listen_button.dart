import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../services/text_to_speech_service.dart';
import '../../../../core/localization/app_localizations.dart';

class GlobalListenButton extends StatefulWidget {
  final String Function() textBuilder;
  final StorageService storageService;

  const GlobalListenButton({
    super.key,
    required this.textBuilder,
    required this.storageService,
  });

  @override
  State<GlobalListenButton> createState() => _GlobalListenButtonState();
}

class _GlobalListenButtonState extends State<GlobalListenButton> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _ttsService.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      
      final text = widget.textBuilder();
      
      final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
      final speed = widget.storageService.getSpeechSpeed();
      
      await _ttsService.setSpeed(speed);
      final success = await _ttsService.speak(text, languageId);
      
      if (!success && mounted) {
        setState(() {
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('voice_not_available') == 'voice_not_available'
                  ? 'Voice is not available for the selected language on this device.'
                  : AppLocalizations.of(context).translate('voice_not_available'),
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _isPlaying ? 'Stop reading page' : 'Listen to page',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _toggleAudio,
          icon: Icon(_isPlaying ? Icons.stop_circle : Icons.volume_up, size: 28),
          label: Text(
            _isPlaying 
                ? (AppLocalizations.of(context).translate('stop') == 'stop' ? 'Stop' : AppLocalizations.of(context).translate('stop'))
                : (AppLocalizations.of(context).translate('listen') == 'listen' ? 'Listen' : AppLocalizations.of(context).translate('listen')),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPlaying ? Colors.red.shade50 : Colors.green.shade50,
            foregroundColor: _isPlaying ? Colors.red.shade900 : Colors.green.shade900,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _isPlaying ? Colors.red.shade200 : Colors.green.shade200, width: 2),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
