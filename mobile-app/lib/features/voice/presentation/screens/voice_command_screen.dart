import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../services/speech_recognition_service.dart';
import '../../utils/voice_command_parser.dart';

class VoiceCommandScreen extends StatefulWidget {
  final StorageService storageService;
  final NetworkService networkService;
  final Function(String) onCommandMatched;

  const VoiceCommandScreen({
    super.key,
    required this.storageService,
    required this.networkService,
    required this.onCommandMatched,
  });

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  bool _isListening = false;
  bool _hasError = false;
  String _statusMessage = 'Tap to Speak';
  String _recognizedText = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _speechService.initialize().then((initialized) {
      if (!initialized) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Microphone permission is required for voice commands.';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _speechService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!widget.networkService.isOnline.value) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Voice recognition is currently unavailable.';
        _statusMessage = 'Offline';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _hasError = false;
      _errorMessage = null;
      _recognizedText = '';
      _statusMessage = 'Listening...';
    });

    final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
    
    final started = await _speechService.startListening(
      languageId: languageId,
      onResult: (text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
          });
          
          if (!_speechService.isListening && text.isNotEmpty) {
             _processCommand(text, languageId);
          }
        }
      },
    );

    if (!started) {
      setState(() {
        _isListening = false;
        _hasError = true;
        _errorMessage = 'Microphone permission is required for voice commands.';
        _statusMessage = 'Error';
      });
    }
  }

  void _processCommand(String text, String languageId) {
    setState(() {
      _isListening = false;
    });

    if (text.trim().isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Sorry, I did not understand that command.';
        _statusMessage = 'Command not understood';
      });
      return;
    }

    final command = VoiceCommandParser.parseCommand(text, languageId);
    
    if (command != null) {
      setState(() {
        _statusMessage = 'Opening...';
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onCommandMatched(command);
        }
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Sorry, I did not understand that command.';
        _statusMessage = 'Command not understood';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Voice Commands'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_recognizedText.isNotEmpty) ...[
                const Text(
                  'You said:',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$_recognizedText"',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
              
              if (_hasError && _errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _hasError ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),
              
              GestureDetector(
                onTap: _isListening ? () => _speechService.stopListening() : _startListening,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red.shade500 : Colors.green.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red.shade300 : Colors.green.shade300).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: _isListening ? 12 : 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              if (_hasError)
                ElevatedButton.icon(
                  onPressed: _startListening,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
