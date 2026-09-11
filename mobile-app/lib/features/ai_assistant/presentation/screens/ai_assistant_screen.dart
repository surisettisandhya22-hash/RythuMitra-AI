import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/farm_memory_service.dart';
import '../../domain/models/chat_message.dart';
import '../../../voice/services/speech_recognition_service.dart';
import '../../../voice/services/text_to_speech_service.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/suggestion_card.dart';
import '../widgets/ai_thinking_indicator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../../core/services/network_service.dart';

import '../../../profile/data/models/crop_profile.dart';

class AIAssistantScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService? profileStorageService;
  final CropProfile? focusedCrop;
  final String? healthContext;
  final String? alertContext;
  final WeatherRepository? weatherRepository;
  final NetworkService networkService;
  final bool autoStartListening;

  const AIAssistantScreen({
    super.key, 
    required this.storageService,
    required this.networkService,
    this.profileStorageService,
    this.focusedCrop,
    this.healthContext,
    this.alertContext,
    this.weatherRepository,
    this.autoStartListening = false,
  });

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final List<ChatMessage> _messages = [];
  bool _isThinking = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  late final FarmMemoryService? _farmMemoryService;
  
  bool _isListening = false;
  String? _speakingMessageId;
  bool _backendUnavailable = false;

  late List<String> _suggestions;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _suggestions = [
      AppLocalizations.of(context).translate('sug_my_crop'),
      AppLocalizations.of(context).translate('sug_weather_quick'),
      AppLocalizations.of(context).translate('sug_market_price'),
      AppLocalizations.of(context).translate('sug_crop_problem'),
      AppLocalizations.of(context).translate('sug_irrigation'),
      AppLocalizations.of(context).translate('sug_farming_advice'),
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.profileStorageService != null) {
      _farmMemoryService = FarmMemoryService(profileStorageService: widget.profileStorageService!);
    } else {
      _farmMemoryService = null;
    }
    
    _speechService.initialize();
    _ttsService.init();
    _ttsService.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _speakingMessageId = null;
        });
      }
    });
    
    if (widget.autoStartListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleVoiceTap();
      });
    }

    if (widget.alertContext != null) {
      _handleSendMessage("Explain this weather alert: ${widget.alertContext}");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _speechService.stopListening();
    _ttsService.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  final ApiService _apiService = ApiService();

  Future<void> _handleSendMessage(String text) async {
    if (!widget.networkService.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('feature_requires_internet') == 'feature_requires_internet' ? 'This feature requires an internet connection.' : AppLocalizations.of(context).translate('feature_requires_internet'))),
      );
      return;
    }

    _textController.clear();
    
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    }

    if (_speakingMessageId != null) {
      await _handleStopTTS();
    }

    setState(() {
      _backendUnavailable = false;
    });

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUserMessage: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isThinking = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
    
    Map<String, dynamic>? contextPayload;
    if (_farmMemoryService != null) {
      contextPayload = _farmMemoryService.buildContext(
        text, 
        focusedCrop: widget.focusedCrop,
        healthContext: widget.healthContext,
      );
    }
    
    // Relevance check for weather
    final lowerText = text.toLowerCase();
    final isWeatherRelated = lowerText.contains('weather') || lowerText.contains('rain') || lowerText.contains('temperature') || lowerText.contains('forecast') || lowerText.contains('వాతావరణం') || lowerText.contains('వర్షం') || lowerText.contains('मौसम') || lowerText.contains('बारिश');
    
    if (isWeatherRelated && widget.weatherRepository != null) {
      try {
        final weather = await widget.weatherRepository!.getWeather('current');
        contextPayload ??= {};
        contextPayload['weather'] = {
          'location': weather.locationName,
          'condition': weather.condition,
          'temperature': weather.temperature,
          'rain_expected': weather.rain,
        };
      } catch (e) {
        // Ignore weather failure, proceed with normal chat
      }
    }
    
    try {
      final aiResponseText = await _apiService.sendChatMessage(
        text, 
        languageId, 
        context: contextPayload,
      );
      
      if (!mounted) return;

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: aiResponseText,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isThinking = false;
      });

      if (widget.storageService.getAutoSpeakEnabled()) {
        _handlePlayTTS(aiMessage.id, aiResponseText);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _backendUnavailable = true;
      });
      
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.substring(11);
      } else {
        errorMsg = AppLocalizations.of(context).translate('ai_unavailable') == 'ai_unavailable' 
            ? 'RythuMitra AI is temporarily unavailable. Please try again.'
            : AppLocalizations.of(context).translate('ai_unavailable');
      }

      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: errorMsg,
        isUserMessage: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _handlePlayTTS(String messageId, String text) async {
    if (_speakingMessageId != null) {
      await _ttsService.stop();
    }

    setState(() {
      _speakingMessageId = messageId;
    });

    final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
    final success = await _ttsService.speak(text, languageId);

    if (!success && mounted) {
      setState(() {
        _speakingMessageId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Voice is not currently available for this language on your device.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  Future<void> _handleStopTTS() async {
    await _ttsService.stop();
    if (mounted) {
      setState(() {
        _speakingMessageId = null;
      });
    }
  }

  void _handleVoiceTap() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
    
    final started = await _speechService.startListening(
      languageId: languageId,
      onResult: (recognizedText) {
        setState(() {
          _textController.text = recognizedText;
          // Note: we don't auto-send here to let the farmer review
        });
      },
    );

    if (started) {
      setState(() {
        _isListening = true;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('mic_error')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildWelcomeArea() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                size: 64,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).translate('ai_welcome') == 'ai_welcome' 
                  ? 'Namaste! I am RythuMitra AI. How can I help you with your farm?'
                  : AppLocalizations.of(context).translate('ai_welcome'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _suggestions.map((suggestion) {
                return SuggestionCard(
                  text: suggestion,
                  onTap: () {
                    _textController.text = suggestion;
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).translate('ai_title'), style: const TextStyle(fontSize: 18)),
            Text(
              AppLocalizations.of(context).translate('home_subtitle'),
              style: TextStyle(fontSize: 12, color: Colors.green.shade100),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: AppLocalizations.of(context).translate('clear_chat') == 'clear_chat' ? 'Clear Chat' : AppLocalizations.of(context).translate('clear_chat'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context).translate('clear_chat_confirm') == 'clear_chat_confirm' ? 'Clear this conversation?' : AppLocalizations.of(context).translate('clear_chat_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).translate('cancel')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        setState(() {
                          _messages.clear();
                          _backendUnavailable = false;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context).translate('clear') == 'clear' ? 'Clear' : AppLocalizations.of(context).translate('clear'), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeArea()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatMessageBubble(
                        message: message,
                        isSpeaking: _speakingMessageId == message.id,
                        onPlayTap: () => _handlePlayTTS(message.id, message.text),
                        onStopTap: _handleStopTTS,
                      );
                    },
                  ),
          ),
          if (_backendUnavailable)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).translate('ai_conn_unavailable') == 'ai_conn_unavailable' ? '🔴 AI connection unavailable' : AppLocalizations.of(context).translate('ai_conn_unavailable'),
                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                  ),
                ],
              ),
            ),
          if (_isThinking) const AIThinkingIndicator(),
          ChatInput(
            controller: _textController,
            onSendMessage: _handleSendMessage,
            onVoiceTap: _handleVoiceTap,
            isThinking: _isThinking,
            isListening: _isListening,
          ),
        ],
      ),
    );
  }
}
