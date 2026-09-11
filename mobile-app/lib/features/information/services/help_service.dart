import 'package:flutter/material.dart';
import '../data/models/help_topic.dart';

class HelpService {
  static List<HelpTopic> getTopics(String languageCode) {
    // English Content
    if (languageCode == 'te') {
      return _getTeluguTopics();
    } else if (languageCode == 'hi') {
      return _getHindiTopics();
    }
    return _getEnglishTopics();
  }

  static List<HelpTopic> searchTopics(String query, String languageCode) {
    final allTopics = getTopics(languageCode);
    final allFaqs = getFaqs(languageCode);
    
    if (query.trim().isEmpty) {
      return [...allTopics, ...allFaqs];
    }
    
    final lowerQuery = query.toLowerCase();
    
    return [...allTopics, ...allFaqs].where((topic) {
      return topic.title.toLowerCase().contains(lowerQuery) || 
             topic.description.toLowerCase().contains(lowerQuery) ||
             topic.steps.any((step) => step.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  static List<HelpTopic> getFaqs(String languageCode) {
    if (languageCode == 'te') {
      return _getTeluguFaqs();
    } else if (languageCode == 'hi') {
      return _getHindiFaqs();
    }
    return _getEnglishFaqs();
  }

  // --- ENGLISH ---

  static List<HelpTopic> _getEnglishTopics() {
    return const [
      HelpTopic(
        id: 'home',
        title: 'Home Dashboard',
        description: 'The main screen where you can see a summary of your farm, quick actions, and current weather.',
        steps: [
          'Tap the Home icon at the bottom to open the dashboard.',
          'Tap any Quick Action to jump to that feature.',
          'Tap the big microphone button to use Voice Commands.'
        ],
        icon: Icons.home,
      ),
      HelpTopic(
        id: 'crops',
        title: 'My Crops',
        description: 'Here you can add and manage information about the crops growing on your farm.',
        steps: [
          'Open My Farm from the bottom menu.',
          'Tap Add Crop.',
          'Enter crop information like name and dates.',
          'Save the details.'
        ],
        icon: Icons.agriculture,
      ),
      HelpTopic(
        id: 'weather',
        title: 'Weather',
        description: 'Check the current weather conditions and forecast for your farm.',
        steps: [
          'Go to the Home Dashboard.',
          'Look at the Weather card at the top.',
          'Tap the card to view detailed weather information for your area.'
        ],
        icon: Icons.cloud,
      ),
      HelpTopic(
        id: 'market',
        title: 'Market Prices',
        description: 'View the latest market prices for different crops.',
        steps: [
          'Go to the Home Dashboard.',
          'Tap on the Market Prices quick action.',
          'Search for a crop to see its minimum, maximum, and modal prices.'
        ],
        icon: Icons.currency_rupee,
      ),
      HelpTopic(
        id: 'ai_assistant',
        title: 'AI Farm Assistant',
        description: 'Chat with RythuMitra AI to ask questions about your farming.',
        steps: [
          'Tap the AI Assistant icon at the bottom menu.',
          'Type your question or use the microphone to speak.',
          'The AI will provide helpful farming advice.'
        ],
        icon: Icons.smart_toy,
      ),
      HelpTopic(
        id: 'reminders',
        title: 'Farm Reminders',
        description: 'Set reminders for important farming activities like watering or spraying.',
        steps: [
          'Tap the Tasks icon at the bottom menu.',
          'Select the Reminders tab.',
          'Tap Add Reminder.',
          'Enter the title, date, and time, then save.'
        ],
        icon: Icons.notifications,
      ),
      HelpTopic(
        id: 'expenses',
        title: 'Farm Expenses',
        description: 'Record and track the money you spend on your farm.',
        steps: [
          'Go to More menu, then select Farm Expenses (if available) or access via My Farm.',
          'Tap Add Expense.',
          'Select the category (like Seeds, Fertilizer), enter the amount, and save.'
        ],
        icon: Icons.receipt_long,
      ),
      HelpTopic(
        id: 'voice',
        title: 'Voice Commands',
        description: 'Navigate the app easily using your voice.',
        steps: [
          'Tap the big microphone button on the Home screen.',
          'Speak a command, for example: "Open my crops".',
          'The app will automatically open the requested screen.'
        ],
        icon: Icons.mic,
      ),
      HelpTopic(
        id: 'offline',
        title: 'Offline Mode',
        description: 'Many features of RythuMitra work even without an internet connection.',
        steps: [
          'You can view your saved crops, expenses, and read this Help Center offline.',
          'Features like Live Weather or AI Chat require an internet connection.',
        ],
        icon: Icons.wifi_off,
      ),
    ];
  }

  static List<HelpTopic> _getEnglishFaqs() {
    return const [
      HelpTopic(
        id: 'faq_add_crop',
        title: 'How do I add a crop?',
        description: 'To add a crop, go to the "My Farm" tab at the bottom, and tap the "+ Add Crop" button. Fill in the details and tap Save.',
        icon: Icons.question_mark,
        isFaq: true,
      ),
      HelpTopic(
        id: 'faq_add_reminder',
        title: 'How do I add a reminder?',
        description: 'Go to the "Tasks" tab at the bottom, switch to Reminders, and tap "Add Reminder".',
        icon: Icons.question_mark,
        isFaq: true,
      ),
      HelpTopic(
        id: 'faq_language',
        title: 'How do I change the language?',
        description: 'Go to the "More" tab, select "Language", and choose your preferred language (English, Telugu, Hindi, etc.).',
        icon: Icons.question_mark,
        isFaq: true,
      ),
      HelpTopic(
        id: 'faq_voice',
        title: 'How do I use voice commands?',
        description: 'Tap the large microphone icon on the Home screen, wait for the "Listening..." prompt, and say something like "Show weather".',
        icon: Icons.question_mark,
        isFaq: true,
      ),
    ];
  }

  // --- TELUGU ---

  static List<HelpTopic> _getTeluguTopics() {
    return const [
      HelpTopic(
        id: 'home',
        title: 'హోమ్ డ్యాష్‌బోర్డ్',
        description: 'ఇది ప్రధాన స్క్రీన్. ఇక్కడ మీరు మీ పొలం సారాంశం, త్వరిత చర్యలు మరియు ప్రస్తుత వాతావరణం చూడవచ్చు.',
        steps: [
          'కింద ఉన్న హోమ్ ఐకాన్ నొక్కండి.',
          'ఏదైనా ఫీచర్ కోసం త్వరిత చర్యలను ఉపయోగించండి.',
          'వాయిస్ కమాండ్స్ కోసం పెద్ద మైక్రోఫోన్ బటన్ నొక్కండి.'
        ],
        icon: Icons.home,
      ),
      HelpTopic(
        id: 'crops',
        title: 'నా పంటలు',
        description: 'ఇక్కడ మీరు మీ పొలంలో పెరుగుతున్న పంటల సమాచారాన్ని జోడించవచ్చు మరియు నిర్వహించవచ్చు.',
        steps: [
          'కింది మెను నుండి నా వ్యవసాయం తెరవండి.',
          'పంటను జోడించు నొక్కండి.',
          'పంట పేరు మరియు తేదీల వంటి సమాచారాన్ని నమోదు చేయండి.',
          'వివరాలను సేవ్ చేయండి.'
        ],
        icon: Icons.agriculture,
      ),
      HelpTopic(
        id: 'weather',
        title: 'వాతావరణం',
        description: 'మీ పొలానికి ప్రస్తుత వాతావరణ పరిస్థితులు మరియు అంచనాలను తనిఖీ చేయండి.',
        steps: [
          'హోమ్ డ్యాష్‌బోర్డ్‌కు వెళ్లండి.',
          'పైన ఉన్న వాతావరణ కార్డు చూడండి.',
          'వివరణాత్మక సమాచారం కోసం ఆ కార్డును నొక్కండి.'
        ],
        icon: Icons.cloud,
      ),
      HelpTopic(
        id: 'market',
        title: 'మార్కెట్ ధరలు',
        description: 'వివిధ పంటలకు తాజా మార్కెట్ ధరలను చూడండి.',
        steps: [
          'హోమ్ డ్యాష్‌బోర్డ్‌కు వెళ్లండి.',
          'మార్కెట్ ధరలు బటన్ నొక్కండి.',
          'పంట ధరలను తెలుసుకోవడానికి శోధించండి.'
        ],
        icon: Icons.currency_rupee,
      ),
      HelpTopic(
        id: 'voice',
        title: 'వాయిస్ కమాండ్స్',
        description: 'మీ వాయిస్ ఉపయోగించి యాప్‌లో సులభంగా నావిగేట్ చేయండి.',
        steps: [
          'హోమ్ స్క్రీన్‌పై పెద్ద మైక్రోఫోన్ బటన్ నొక్కండి.',
          'ఒక కమాండ్ చెప్పండి, ఉదాహరణకు: "నా పంటలు చూపించు".',
          'యాప్ స్వయంచాలకంగా మీరు అడిగిన స్క్రీన్‌ను తెరుస్తుంది.'
        ],
        icon: Icons.mic,
      ),
    ];
  }

  static List<HelpTopic> _getTeluguFaqs() {
    return const [
      HelpTopic(
        id: 'faq_add_crop',
        title: 'నేను పంటను ఎలా జోడించాలి?',
        description: '"నా వ్యవసాయం" ట్యాబ్‌కు వెళ్లి, "+ పంటను జోడించు" బటన్ నొక్కండి. వివరాలు నింపి సేవ్ చేయండి.',
        icon: Icons.question_mark,
        isFaq: true,
      ),
      HelpTopic(
        id: 'faq_language',
        title: 'నేను భాషను ఎలా మార్చాలి?',
        description: '"మరిన్ని" ట్యాబ్‌కు వెళ్లి, "భాష" ఎంచుకుని మీకు కావలసిన భాషను (తెలుగు, ఇంగ్లీష్, హిందీ మొదలైనవి) ఎంచుకోండి.',
        icon: Icons.question_mark,
        isFaq: true,
      ),
    ];
  }

  // --- HINDI ---

  static List<HelpTopic> _getHindiTopics() {
    return const [
      HelpTopic(
        id: 'home',
        title: 'होम डैशबोर्ड',
        description: 'मुख्य स्क्रीन जहां आप अपने खेत का सारांश, त्वरित कार्रवाइयां और वर्तमान मौसम देख सकते हैं।',
        steps: [
          'डैशबोर्ड खोलने के लिए नीचे दिए गए होम आइकन पर टैप करें।',
          'किसी भी फीचर पर जाने के लिए त्वरित कार्रवाई (Quick Action) पर टैप करें।',
          'आवाज़ से निर्देश देने के लिए बड़े माइक्रोफ़ोन बटन पर टैप करें।'
        ],
        icon: Icons.home,
      ),
      HelpTopic(
        id: 'crops',
        title: 'मेरी फसलें',
        description: 'यहां आप अपने खेत में उगने वाली फसलों के बारे में जानकारी जोड़ सकते हैं।',
        steps: [
          'नीचे के मेनू से "मेरा खेत" (My Farm) खोलें।',
          'फसल जोड़ें पर टैप करें।',
          'फसल की जानकारी दर्ज करें और सहेजें।'
        ],
        icon: Icons.agriculture,
      ),
      HelpTopic(
        id: 'voice',
        title: 'वॉइस कमांड',
        description: 'अपनी आवाज़ का उपयोग करके ऐप को आसानी से चलाएं।',
        steps: [
          'होम स्क्रीन पर बड़े माइक्रोफ़ोन बटन पर टैप करें।',
          'एक कमांड बोलें, उदाहरण के लिए: "मेरी फसलें दिखाओ"।',
          'ऐप स्वचालित रूप से आपकी स्क्रीन खोल देगा।'
        ],
        icon: Icons.mic,
      ),
    ];
  }

  static List<HelpTopic> _getHindiFaqs() {
    return const [
      HelpTopic(
        id: 'faq_add_crop',
        title: 'मैं फसल कैसे जोड़ूं?',
        description: '"मेरा खेत" टैब पर जाएं और "+ फसल जोड़ें" बटन पर टैप करें। विवरण भरें और सेव करें।',
        icon: Icons.question_mark,
        isFaq: true,
      ),
      HelpTopic(
        id: 'faq_language',
        title: 'मैं भाषा कैसे बदलूं?',
        description: '"और" (More) टैब पर जाएं, "भाषा" चुनें और अपनी पसंद की भाषा (हिंदी, अंग्रेजी, आदि) चुनें।',
        icon: Icons.question_mark,
        isFaq: true,
      ),
    ];
  }
}
