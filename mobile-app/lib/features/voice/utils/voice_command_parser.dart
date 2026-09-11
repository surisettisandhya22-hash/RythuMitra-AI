
class VoiceCommandParser {
  static final Map<String, Map<String, String>> _commandMap = {
    'en': {
      'home': 'home',
      'dashboard': 'home',
      'my crops': 'my_crops',
      'weather': 'weather',
      'market': 'market_prices',
      'prices': 'market_prices',
      'ai assistant': 'ai_assistant',
      'reminders': 'alerts',
      'alerts': 'alerts',
      'tasks': 'alerts',
      'planner': 'alerts',
      'daily planner': 'alerts',
      'calendar': 'calendar',
      'expenses': 'expenses',
      'income': 'income',
      'financial summary': 'financial_summary',
      'reports': 'reports',
      'profile': 'profile',
      'location': 'location',
      'photos': 'photos',
      'health': 'crop_health',
      'diagnosis': 'crop_health',
      'emergency': 'emergency',
      'help': 'emergency',
      'knowledge': 'knowledge',
      'search': 'search',
      'insights': 'insights',
      'farm insights': 'insights',
      'farm summary': 'insights',
      'farm alerts': 'alerts_center',
      'smart alerts': 'alerts_center',
      'alerts center': 'alerts_center',
    },
    'te': {
      'హోమ్': 'home',
      'పంటలు': 'my_crops',
      'వాతావరణం': 'weather',
      'మార్కెట్': 'market_prices',
      'ధరలు': 'market_prices',
      'సహాయకుడు': 'ai_assistant',
      'రిమైండర్లు': 'alerts',
      'పనులు': 'alerts',
      'ప్రణాళిక': 'alerts',
      'రోజువారీ ప్రణాళిక': 'alerts',
      'క్యాలెండర్': 'calendar',
      'ఖర్చులు': 'expenses',
      'ఆదాయం': 'income',
      'సారాంశం': 'financial_summary',
      'నివేదికలు': 'reports',
      'ప్రొఫైల్': 'profile',
      'ప్రాంతం': 'location',
      'ఫోటోలు': 'photos',
      'ఆరోగ్యం': 'crop_health',
      'అత్యవసర': 'emergency',
      'సహాయం': 'emergency',
      'జ్ఞానం': 'knowledge',
      'వెతకండి': 'search',
      'అంతర్దృష్టులు': 'insights',
      'వ్యవసాయ అంతర్దృష్టులు': 'insights',
      'అలర్ట్‌లు': 'alerts_center',
      'వ్యవసాయ అలర్ట్‌లు': 'alerts_center',
    },
    'hi': {
      'होम': 'home',
      'फसलें': 'my_crops',
      'मौसम': 'weather',
      'बाजार': 'market_prices',
      'कीमतें': 'market_prices',
      'सहायक': 'ai_assistant',
      'रिमाइंडर': 'alerts',
      'कार्य': 'alerts',
      'योजना': 'alerts',
      'दैनिक योजना': 'alerts',
      'कैलेंडर': 'calendar',
      'खर्च': 'expenses',
      'आय': 'income',
      'सारांश': 'financial_summary',
      'रिपोर्ट': 'reports',
      'प्रोफ़ाइल': 'profile',
      'स्थान': 'location',
      'तस्वीरें': 'photos',
      'स्वास्थ्य': 'crop_health',
      'आपातकालीन': 'emergency',
      'मदद': 'emergency',
      'ज्ञान': 'knowledge',
      'खोज': 'search',
      'अंतर्दृष्टि': 'insights',
      'कृषि अंतर्दृष्टि': 'insights',
      'अलर्ट': 'alerts_center',
      'कृषि अलर्ट': 'alerts_center',
    }
  };

  static String? parseCommand(String recognizedText, String languageId) {
    if (recognizedText.isEmpty) return null;
    final lowerText = recognizedText.toLowerCase();
    
    final langMap = _commandMap[languageId] ?? _commandMap['en']!;
    
    for (final entry in langMap.entries) {
      if (lowerText.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    
    // Fallback to english matching
    if (languageId != 'en') {
      for (final entry in _commandMap['en']!.entries) {
        if (lowerText.contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }
    }
    
    return null;
  }
}
