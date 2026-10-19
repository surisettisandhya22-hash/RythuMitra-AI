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
import '../../../../shared/models/language.dart';
import '../../../../core/utils/language_utils.dart';

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
  late String _activeLanguageId;

  late List<String> _suggestions;

  final List<Language> _supportedLanguages = const [
    Language(id: 'en', nativeName: 'English', englishName: 'English'),
    Language(id: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
    Language(id: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    Language(id: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
    Language(id: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
    Language(id: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
    Language(id: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
    Language(id: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
    Language(id: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
    Language(id: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshSuggestions();
  }

  void _refreshSuggestions() {
    _suggestions = [
      AppLocalizations.of(context).translate('sug_my_crop'),
      AppLocalizations.of(context).translate('sug_weather_quick'),
      AppLocalizations.of(context).translate('sug_market_price'),
      AppLocalizations.of(context).translate('sug_crop_problem'),
      AppLocalizations.of(context).translate('sug_irrigation'),
      AppLocalizations.of(context).translate('sug_farming_advice'),
    ];
  }

  Future<void> _changeLanguage(String newLangId) async {
    if (_activeLanguageId == newLangId) return;
    
    // Stop any ongoing speech or recognition
    if (_speakingMessageId != null) {
      await _handleStopTTS();
    }
    if (_isListening) {
      await _speechService.stopListening();
      _isListening = false;
    }

    await widget.storageService.saveSelectedLanguage(newLangId);
    
    // Also sync farmer profile if present
    final currentProfile = widget.profileStorageService?.getFarmerProfile();
    if (currentProfile != null) {
      await widget.profileStorageService?.saveFarmerProfile(
        currentProfile.copyWith(preferredLanguage: newLangId),
      );
    }

    if (mounted) {
      setState(() {
        _activeLanguageId = newLangId;
        _refreshSuggestions();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to ${LanguageUtils.getLanguageName(newLangId)}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _activeLanguageId = widget.storageService.getSelectedLanguage() ?? 'en';
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

  Future<void> _handleSendMessage(String text, {bool speakResponse = false}) async {
    if (!widget.networkService.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('feature_requires_internet') == 'feature_requires_internet' ? 'This feature requires an internet connection.' : AppLocalizations.of(context).translate('feature_requires_internet'))),
      );
      return;
    }

    _textController.clear();
    
    if (_isListening) {
      await _speechService.stopListening();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
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

    final languageId = _activeLanguageId;
    
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

      if (speakResponse || widget.storageService.getAutoSpeakEnabled()) {
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

    final languageId = _activeLanguageId;
    final success = await _ttsService.speak(text, languageId);

    if (!success && mounted) {
      setState(() {
        _speakingMessageId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice is not currently available for ${LanguageUtils.getLanguageName(_activeLanguageId)} on this device.'),
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
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      final currentText = _textController.text.trim();
      if (currentText.isNotEmpty) {
        _handleSendMessage(currentText, speakResponse: true);
      }
      return;
    }

    final languageId = _activeLanguageId;
    
    final started = await _speechService.startListening(
      languageId: languageId,
      onResult: (recognizedText) {
        if (mounted) {
          setState(() {
            _textController.text = recognizedText;
          });
        }
      },
      onFinalResult: (finalText) {
        if (mounted && finalText.trim().isNotEmpty) {
          setState(() {
            _isListening = false;
            _textController.text = finalText.trim();
          });
          _speechService.stopListening();
          _handleSendMessage(finalText.trim(), speakResponse: true);
        }
      },
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted && _isListening) {
            setState(() {
              _isListening = false;
            });
            final pendingText = _textController.text.trim();
            if (pendingText.isNotEmpty && !_isThinking) {
              _handleSendMessage(pendingText, speakResponse: true);
            }
          }
        }
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
          PopupMenuButton<String>(
            tooltip: 'Change Language',
            initialValue: _activeLanguageId,
            onSelected: (String langId) {
              _changeLanguage(langId);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (BuildContext context) {
              return _supportedLanguages.map((Language lang) {
                final isSelected = lang.id == _activeLanguageId;
                return PopupMenuItem<String>(
                  value: lang.id,
                  child: Row(
                    children: [
                      Text(
                        lang.nativeName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.green.shade800 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${lang.englishName})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check, size: 18, color: Colors.green.shade700),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _supportedLanguages.firstWhere(
                      (l) => l.id == _activeLanguageId,
                      orElse: () => const Language(id: 'en', nativeName: 'English', englishName: 'English'),
                    ).nativeName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
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
