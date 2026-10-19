import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/fertilizer_service.dart';
import 'fertilizer_schedule_screen.dart';

class FertilizerCalculatorScreen extends StatefulWidget {
  final String? initialCrop;
  final double? initialArea;

  const FertilizerCalculatorScreen({
    super.key,
    this.initialCrop,
    this.initialArea,
  });

  @override
  State<FertilizerCalculatorScreen> createState() => _FertilizerCalculatorScreenState();
}

class _FertilizerCalculatorScreenState extends State<FertilizerCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final FertilizerService _fertilizerService = FertilizerService();
  final TextEditingController _areaController = TextEditingController(text: '1.0');

  List<SupportedCrop> _crops = FertilizerService.defaultCrops;
  SupportedCrop? _selectedCrop;
  String _selectedUnit = 'Acres';
  String _farmingType = 'Integrated'; // 'Integrated' or 'Organic'
  bool _isLoading = false;
  bool _isLoadingCrops = false;
  FertilizerRecommendation? _recommendation;

  late TabController _tabController;

  final List<String> _units = ['Acres', 'Hectares', 'Guntas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (widget.initialArea != null && widget.initialArea! > 0) {
      _areaController.text = widget.initialArea!.toString();
    }
    _selectedCrop = _crops.first;
    _loadCrops();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    setState(() => _isLoadingCrops = true);
    final fetched = await _fertilizerService.fetchSupportedCrops();
    if (mounted) {
      setState(() {
        _crops = fetched;
        if (widget.initialCrop != null) {
          final match = _crops.firstWhere(
            (c) => c.nameEn.toLowerCase().contains(widget.initialCrop!.toLowerCase()),
            orElse: () => _crops.first,
          );
          _selectedCrop = match;
        } else {
          _selectedCrop = _crops.first;
        }
        _isLoadingCrops = false;
      });
      // Run initial calculation
      _calculatePlan();
    }
  }

  Future<void> _calculatePlan() async {
    final areaText = _areaController.text.trim();
    final double? area = double.tryParse(areaText);
    if (area == null || area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('enter_valid_area') != 'enter_valid_area'
                ? AppLocalizations.of(context).translate('enter_valid_area')
                : 'Please enter a valid farm area greater than 0',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final currentLang = Localizations.localeOf(context).languageCode;

    setState(() => _isLoading = true);

    final result = await _fertilizerService.calculateFertilizerPlan(
      crop: _selectedCrop?.nameEn ?? 'Rice / Paddy',
      area: area,
      unit: _selectedUnit,
      farmingType: _farmingType,
      languageId: currentLang,
    );

    if (mounted) {
      setState(() {
        _recommendation = result;
        _isLoading = false;
      });
    }
  }

  String _ft(String key, String lang) {
    const Map<String, Map<String, String>> dict = {
      'screen_title': {
        'en': 'Fertilizer Calculator & Plan',
        'te': 'ఎరువుల కాలిక్యులేటర్ & ప్రణాళిక',
        'ta': 'உர கால்குலேட்டர் & திட்டம்',
        'hi': 'उर्वरक कैलकुलेटर एवं योजना',
        'kn': 'ಗೊಬ್ಬರ ಕ್ಯಾಲ್ಕುಲೇಟರ್ ಮತ್ತು ಯೋಜನೆ',
        'ml': 'വള കാൽക്കുലേറ്ററും പദ്ധതിയും',
        'mr': 'खत गणक आणि योजना',
        'bn': 'সার ক্যালকুলেটর ও পরিকল্পনা',
        'gu': 'ખાતર કેલ્ક્યુલેટર અને આયોજન',
        'pa': 'ਖਾਦ ਕੈਲਕੁਲੇਟਰ ਅਤੇ ਯੋਜਨਾ',
      },
      'banner_title': {
        'en': 'Scientific Fertilizer Dosage',
        'te': 'శాస్త్రీయ ఎరువుల మోతాదు',
        'ta': 'அறிவியல் உர அளவு',
        'hi': 'वैज्ञानिक उर्वरक मात्रा',
        'kn': 'ವೈಜ್ಞಾನಿಕ ಗೊಬ್ಬರ ಪ್ರಮಾಣ',
        'ml': 'ശാസ്ത്രീയ വള പ്രയോഗം',
        'mr': 'शास्त्रीय खत मात्रा',
        'bn': 'বৈজ্ঞানিক সার প্রয়োগ মাত্রা',
        'gu': 'વૈજ્ઞાનિક ખાતર માત્રા',
        'pa': 'ਵਿਗਿਆਨਕ ਖਾਦ ਖ਼ੁਰਾਕ',
      },
      'banner_subtitle': {
        'en': 'Accurate ICAR-standard NPK bag counts, stage-wise splits & cost estimation.',
        'te': 'ICAR & వ్యవసాయ విశ్వవిద్యాలయాల సిఫార్సుల ఆధారంగా రూపొందించిన మోతాదు మరియు ఖర్చు వివరాలు.',
        'ta': 'ICAR தரநிலைகளின்படி NPK மூட்டைகளின் எண்ணிக்கை மற்றும் செலவு மதிப்பீடு.',
        'hi': 'ICAR मानकों के अनुसार सटीक NPK बोरी गणना, चरणबद्ध विभाजन एवं लागत अनुमान।',
        'kn': 'ICAR ಮಾನದಂಡಗಳ ಪ್ರಕಾರ NPK ಚೀಲಗಳ ಲೆಕ್ಕಾಚಾರ, ಹಂತವಾರು ವಿಭಜನೆ ಮತ್ತು ವೆಚ್ಚದ ಅಂದಾಜು.',
        'ml': 'ICAR മാനദണ്ഡങ്ങൾ അനുസരിച്ചുള്ള NPK വള പ്രയോഗവും ചിലവ് കണക്കാക്കലും.',
        'mr': 'ICAR मानकांनुसार अचूक NPK पोती गणना, टप्प्याटप्प्याने नियोजन व खर्चाचा अंदाज.',
        'bn': 'ICAR মান অনুযায়ী NPK ব্যাগের হিসাব, পর্যায়ভিত্তিক প্রয়োগ ও আনুমানিক খরচ।',
        'gu': 'ICAR ધોરણો મુજબ NPK થેલીઓની ગણતરી, તબક્કાવાર વહેંચણી અને ખર્ચનો અંદાજ.',
        'pa': 'ICAR ਮਾਪਦੰਡਾਂ ਅਨੁਸਾਰ NPK ਬੋਰਿਆਂ ਦੀ ਗਿਣਤੀ, ਪੜਾਅਵਾਰ ਵੰਡ ਅਤੇ ਅੰਦਾਜ਼ਨ ਲਾਗਤ।',
      },
      'select_crop': {
        'en': 'Select Crop:',
        'te': 'పంటను ఎంచుకోండి:',
        'ta': 'பயிரைத் தேர்ந்தெடுக்கவும்:',
        'hi': 'फसल चुनें:',
        'kn': 'ಬೆಳೆ ಆಯ್ಕೆಮಾಡಿ:',
        'ml': 'വിള തിരഞ്ഞെടുക്കുക:',
        'mr': 'पीक निवडा:',
        'bn': 'ফসল নির্বাচন করুন:',
        'gu': 'પાક પસંદ કરો:',
        'pa': 'ਫ਼ਸਲ ਚੁਣੋ:',
      },
      'farm_area': {
        'en': 'Farm Area:',
        'te': 'పొలం విస్తీర్ణం:',
        'ta': 'நிலப்பரப்பு:',
        'hi': 'खेत का क्षेत्रफल:',
        'kn': 'ಜಮೀನಿನ ವಿಸ್ತೀರ್ಣ:',
        'ml': 'കൃഷിഭൂമിയുടെ വിസ്തൃതി:',
        'mr': 'शेताचे क्षेत्रफळ:',
        'bn': 'জমির পরিমাণ:',
        'gu': 'ખેતરનો વિસ્તાર:',
        'pa': 'ਖੇਤ ਦਾ ਰਕਬਾ:',
      },
      'unit': {
        'en': 'Unit:',
        'te': 'కొలత యూనిట్:',
        'ta': 'அலகு:',
        'hi': 'इकाई:',
        'kn': 'ಘಟಕ:',
        'ml': 'യൂണിറ്റ്:',
        'mr': 'एकक:',
        'bn': 'একক:',
        'gu': 'એકમ:',
        'pa': 'ਇਕਾਈ:',
      },
      'unit_acres': {
        'en': 'Acres',
        'te': 'ఎకరాలు',
        'ta': 'ஏக்கர்',
        'hi': 'एकड़',
        'kn': 'ಎಕರೆ',
        'ml': 'ഏക്കർ',
        'mr': 'एकर',
        'bn': 'একর',
        'gu': 'એકર',
        'pa': 'ਏਕੜ',
      },
      'unit_hectares': {
        'en': 'Hectares',
        'te': 'హెక్టార్లు',
        'ta': 'ஹெக்டேர்',
        'hi': 'हेक्टेयर',
        'kn': 'ಹೆಕ್ಟೇರ್',
        'ml': 'ഹെക്ടർ',
        'mr': 'हेक्टर',
        'bn': 'হেক্টর',
        'gu': 'હેક્ટર',
        'pa': 'ਹੈਕਟੇਅਰ',
      },
      'unit_guntas': {
        'en': 'Guntas',
        'te': 'గుంటలు',
        'ta': 'குண்டாக்கள்',
        'hi': 'गुंठा',
        'kn': 'ಗುಂಟೆ',
        'ml': 'ഗുണ്ട',
        'mr': 'गुंठा',
        'bn': 'গুন্ঠা',
        'gu': 'ગુંઠા',
        'pa': 'ਗੁੰਠਾ',
      },
      'integrated_type': {
        'en': 'Integrated (Chemical + Organic)',
        'te': 'సమగ్ర ఎరువులు (రసాయన + సేంద్రీయ)',
        'ta': 'ஒருங்கிணைந்த உரம் (இரசாயனம் + இயற்கை)',
        'hi': 'एकीकृत उर्वरक (रासायनिक + जैविक)',
        'kn': 'ಸಮಗ್ರ ಗೊಬ್ಬರ (ರಾಸಾಯನಿಕ + ಸಾವಯವ)',
        'ml': 'സംയോജിത വളം (രാസവളം + ജൈവവളം)',
        'mr': 'एकात्मिक खत (रासायनिक + सेंद्रिय)',
        'bn': 'সমন্বিত সার (রাসায়নিক + জৈব)',
        'gu': 'સંકલિત ખાતર (રાસાયણિક + સેન્દ્રિય)',
        'pa': 'ਸੰਤੁਲਿਤ ਖਾਦ (ਰਸਾਇਣਕ + ਜੈਵਿਕ)',
      },
      'organic_type': {
        'en': 'Organic Only',
        'te': 'సేంద్రీయ పద్ధతి',
        'ta': 'இயற்கை உரம் மட்டும்',
        'hi': 'केवल जैविक खाद',
        'kn': 'ಸಾವಯವ ಮಾತ್ರ',
        'ml': 'ജൈവവളം മാത്രം',
        'mr': 'फक्त सेंद्रिय',
        'bn': 'শুধুমাত্র জৈব সার',
        'gu': 'માત્ર સેન્દ્રિય',
        'pa': 'ਸਿਰਫ਼ ਜੈਵਿਕ ਖਾਦ',
      },
      'calc_button': {
        'en': 'Calculate Fertilizer Plan',
        'te': 'ఎరువుల లెక్కలను లెక్కించండి',
        'ta': 'உரத் தேவையை கணக்கிடுக',
        'hi': 'उर्वरक योजना की गणना करें',
        'kn': 'ಗೊಬ್ಬರ ಯೋಜನೆಯನ್ನು ಲೆಕ್ಕಾಚಾರ ಮಾಡಿ',
        'ml': 'വള പ്രയോഗം കണക്കാക്കുക',
        'mr': 'खत नियोजन मोजा',
        'bn': 'সার পরিকল্পনা গণনা করুন',
        'gu': 'ખાતર યોજનાની ગણતરી કરો',
        'pa': 'ਖਾਦ ਯੋਜਨਾ ਦੀ ਗਣਨਾ ਕਰੋ',
      },
      'calculating': {
        'en': 'Calculating scientific NPK & schedules...',
        'te': 'శాస్త్రీయ NPK & షెడ్యూల్‌ను లెక్కిస్తోంది...',
        'ta': 'அறிவியல் NPK மற்றும் கால அட்டவணை கணக்கிடப்படுகிறது...',
        'hi': 'वैज्ञानिक NPK और समय सारिणी की गणना हो रही है...',
        'kn': 'ವೈಜ್ಞಾನಿಕ NPK ಮತ್ತು ವೇಳಾಪಟ್ಟಿಯನ್ನು ಲೆಕ್ಕಹಾಕಲಾಗುತ್ತಿದೆ...',
        'ml': 'NPK വള പ്രയോഗ വിവരങ്ങൾ കണക്കാക്കുന്നു...',
        'mr': 'शास्त्रीय NPK आणि वेळापत्रकाची गणना सुरू आहे...',
        'bn': 'বৈজ্ঞানিক NPK এবং সময়সূচী গণনা করা হচ্ছে...',
        'gu': 'વૈજ્ઞાનિક NPK અને સમયપત્રકની ગણતરી થઈ રહી છે...',
        'pa': 'ਵਿਗਿਆਨਕ NPK ਅਤੇ ਸਮਾਂ-ਸਾਰਣੀ ਦੀ ਗਣਨਾ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ...',
      },
      'cost_label': {
        'en': 'Estimated Total Cost (Subsidized):',
        'te': 'మొత్తం అంచనా వ్యయం (సబ్సిడీ ధరల్లో):',
        'ta': 'மதிப்பிடப்பட்ட மொத்த செலவு (மானியம்):',
        'hi': 'अनुमानित कुल लागत (सब्सिडी दरों पर):',
        'kn': 'ಒಟ್ಟು ಅಂದಾಜು ವೆಚ್ಚ (ಸಬ್ಸಿಡಿ ದರ):',
        'ml': 'ആകെ പ്രതീക്ഷിക്കുന്ന ചിലവ് (സബ്സിഡി നിരക്കിൽ):',
        'mr': 'अंदाजे एकूण खर्च (अनुदानित दरात):',
        'bn': 'মোট আনুমানিক খরচ (ভর্তুকি মূল্য):',
        'gu': 'અંદાજિત કુલ ખર્ચ (સબસિડી ભાવે):',
        'pa': 'ਕੁੱਲ ਅੰਦਾਜ਼ਨ ਲਾਗਤ (ਸਬਸਿਡੀ ਵਾਲੀ):',
      },
      'tab_bags': {
        'en': 'Bags & Cost',
        'te': 'ఎరువుల సంచులు',
        'ta': 'உர மூட்டைகள் & செலவு',
        'hi': 'खाद बोरी व लागत',
        'kn': 'ಚೀಲಗಳು & ವೆಚ್ಚ',
        'ml': 'വള ചാക്കുകൾ & ചിലവ്',
        'mr': 'खतांची पोती व खर्च',
        'bn': 'সারের ব্যাগ ও খরচ',
        'gu': 'ખાતરની થેલીઓ અને ખર્ચ',
        'pa': 'ਖਾਦ ਦੇ ਬੋਰੇ ਅਤੇ ਲਾਗਤ',
      },
      'tab_schedule': {
        'en': 'Stage Schedule',
        'te': 'దఫాల షెడ్యూల్',
        'ta': 'பருவ கால அட்டவணை',
        'hi': 'चरणबद्ध अनुसूची',
        'kn': 'ಹಂತವಾರು ವೇಳಾಪಟ್ಟಿ',
        'ml': 'ഘട്ട ഷെഡ്യൂൾ',
        'mr': 'टप्पानिहाय वेळापत्रक',
        'bn': 'পর্যায়ভিত্তিক সময়সূচী',
        'gu': 'તબક્કાવાર સમયપત્રક',
        'pa': 'ਪੜਾਅਵਾਰ ਸ਼ਡਿਊਲ',
      },
      'tab_organic': {
        'en': 'Organic',
        'te': 'సేంద్రీయ ఎరువులు',
        'ta': 'இயற்கை உரம்',
        'hi': 'जैविक विकल्प',
        'kn': 'ಸಾವಯವ ಗೊಬ್ಬರ',
        'ml': 'ജൈവവളങ്ങൾ',
        'mr': 'सेंद्रिय पर्याय',
        'bn': 'জৈব সার',
        'gu': 'સેન્દ્રિય ખાતર',
        'pa': 'ਜੈਵਿਕ ਖਾਦ',
      },
      'tab_micro': {
        'en': 'Micronutrients',
        'te': 'సూక్ష్మ పోషకాలు & నియమాలు',
        'ta': 'நுண்ணூட்டச்சத்துக்கள்',
        'hi': 'सूक्ष्म पोषक तत्व',
        'kn': 'ಸೂಕ್ಷ್ಮ ಪೋಷಕಾಂಶಗಳು',
        'ml': 'സൂക്ഷ്മ മൂലകങ്ങൾ',
        'mr': 'सूक्ष्म अन्नद्रव्ये',
        'bn': 'অণুখাদ্য উপাদান',
        'gu': 'સૂક્ષ્મ પોષકતત્વો',
        'pa': 'ਸੂਖਮ ਪੋਸ਼ਕ ਤੱਤ',
      },
      'approx_cost': {
        'en': 'Approx Cost',
        'te': 'సుమారు ఖర్చు',
        'ta': 'தோராய செலவு',
        'hi': 'अनुमानित लागत',
        'kn': 'ಅಂದಾಜು ವೆಚ್ಚ',
        'ml': 'ഏകദേശ ചിലവ്',
        'mr': 'अंदाजे खर्च',
        'bn': 'আনুমানিক খরচ',
        'gu': 'અંદાજિત ખર્ચ',
        'pa': 'ਅੰਦਾਜ਼ਨ ਲਾਗਤ',
      },
      'bags_unit': {
        'en': 'Bags',
        'te': 'సంచులు',
        'ta': 'மூட்டைகள்',
        'hi': 'बोरी',
        'kn': 'ಚೀಲಗಳು',
        'ml': 'ചാക്കുകൾ',
        'mr': 'पोती',
        'bn': 'ব্যাগ',
        'gu': 'થેલીઓ',
        'pa': 'ਬੋਰੇ',
      },
      'view_calendar': {
        'en': 'View Detailed Application Instructions ->',
        'te': 'వివరమైన దఫాల వారీ క్యాలెండర్ చూడండి ->',
        'ta': 'விரிவான பயன்பாட்டு வழிகாட்டியை காண்க ->',
        'hi': 'विस्तृत चरणबद्ध कैलेंडर देखें ->',
        'kn': 'ವಿವರವಾದ ಹಂತವಾರು ಕ್ಯಾಲೆಂಡರ್ ವೀಕ್ಷಿಸಿ ->',
        'ml': 'വിശദമായ വള പ്രയോഗ കലണ്ടർ കാണുക ->',
        'mr': 'तपशीलवार टप्प्यांचे कॅलेंडर पहा ->',
        'bn': 'বিস্তারিত প্রয়োগ নির্দেশিকা দেখুন ->',
        'gu': 'વિગતવાર તબક્કાવાર કેલેન્ડર જુઓ ->',
        'pa': 'ਵਿਸਤ੍ਰਿਤ ਪੜਾਅਵਾਰ ਕੈਲੰਡਰ ਵੇਖੋ ->',
      },
      'no_schedule': {
        'en': 'No schedule data available.',
        'te': 'షెడ్యూల్ సమాచారం అందుబాటులో లేదు',
        'ta': 'கால அட்டவணை விவரங்கள் கிடைக்கவில்லை',
        'hi': 'कोई अनुसूची डेटा उपलब्ध नहीं है।',
        'kn': 'ವೇಳಾಪಟ್ಟಿ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ',
        'ml': 'ഷെഡ്യൂൾ വിവരങ്ങൾ ലഭ്യമല്ല',
        'mr': 'वेळापत्रक माहिती उपलब्ध नाही',
        'bn': 'সময়সূচীর তথ্য উপলব্ধ নেই',
        'gu': 'સમયપત્રકની માહિતી ઉપલબ્ધ નથી',
        'pa': 'ਕੋਈ ਸ਼ਡਿਊਲ ਡਾਟਾ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
      },
      'no_organic': {
        'en': 'No organic alternatives available.',
        'te': 'సేంద్రీయ సమాచారం అందుబాటులో లేదు',
        'ta': 'இயற்கை உர மாற்று விவரங்கள் கிடைக்கவில்லை',
        'hi': 'जैविक विकल्प उपलब्ध नहीं हैं।',
        'kn': 'ಸಾವಯವ ಪರ್ಯಾಯಗಳು ಲಭ್ಯವಿಲ್ಲ',
        'ml': 'ജൈവ ബദലുകൾ ലഭ്യമല്ല',
        'mr': 'सेंद्रिय पर्याय उपलब्ध नाहीत',
        'bn': 'কোনো জৈব বিকল্প তথ্য নেই',
        'gu': 'સેન્દ્રિય વિકલ્પો ઉપલબ્ધ નથી',
        'pa': 'ਕੋਈ ਜੈਵਿਕ ਬਦਲ ਉਪਲਬਧ ਨਹੀਂ ਹੈ',
      },
      'essential_micro': {
        'en': 'Essential Micronutrients:',
        'te': 'ముఖ్యమైన సూక్ష్మ పోషకాలు (Micronutrients):',
        'ta': 'முக்கிய நுண்ணூட்டச்சத்துக்கள்:',
        'hi': 'आवश्यक सूक्ष्म पोषक तत्व:',
        'kn': 'ಪ್ರಮುಖ ಸೂಕ್ಷ್ಮ ಪೋಷಕಾಂಶಗಳು:',
        'ml': 'പ്രധാന സൂക്ഷ്മ മൂലകങ്ങൾ:',
        'mr': 'महत्त्वाची सूक्ष्म अन्नद्रव्ये:',
        'bn': 'প্রয়োজনীয় অণুখাদ্য উপাদান:',
        'gu': 'મહત્વના સૂક્ષ્મ પોષકતત્વો:',
        'pa': 'ਜ਼ਰੂਰੀ ਸੂਖਮ ਪੋਸ਼ਕ ਤੱਤ:',
      },
      'dose': {
        'en': 'Dose',
        'te': 'మోతాదు',
        'ta': 'அளவு',
        'hi': 'मात्रा',
        'kn': 'ಪ್ರಮಾಣ',
        'ml': 'അളവ്',
        'mr': 'मात्रा',
        'bn': 'মাত্রা',
        'gu': 'માત્રા',
        'pa': 'ਖ਼ੁਰਾਕ',
      },
      'farmer_rules': {
        'en': "Farmer Best Practices & Precautions:",
        'te': "రైతులకు ముఖ్యమైన నియమాలు (Do's & Don'ts):",
        'ta': "விவசாயிகளுக்கான சிறந்த நடைமுறைகள் & எச்சரிக்கைகள்:",
        'hi': "किसानों के लिए आवश्यक सावधानियां एवं नियम:",
        'kn': "ರೈತರಿಗೆ ಪ್ರಮುಖ ನಿಯಮಗಳು & ಮುನ್ನೆಚ್ಚರಿಕೆಗಳು:",
        'ml': "കർഷകർ ശ്രദ്ധിക്കേണ്ട കാര്യങ്ങൾ:",
        'mr': "शेतकऱ्यांसाठी महत्त्वाचे नियम व खबरदारी:",
        'bn': "কৃষকদের জন্য গুরুত্বপূর্ণ সতর্কতা ও নিয়ম:",
        'gu': "ખેડૂતો માટે મહત્વપૂર્ણ સાવચેતી અને નિયમો:",
        'pa': "ਕਿਸਾਨਾਂ ਲਈ ਜ਼ਰੂਰੀ ਸਾਵਧਾਨੀਆਂ ਅਤੇ ਨਿਯਮ:",
      },
      'about_title': {
        'en': 'About Fertilizer Calculator',
        'te': 'ఎరువుల కాలిక్యులేటర్ గురించి',
        'ta': 'உர கால்குலேட்டர் பற்றி',
        'hi': 'उर्वरक कैलकुलेटर के बारे में',
        'kn': 'ಗೊಬ್ಬರ ಕ್ಯಾಲ್ಕುಲೇಟರ್ ಬಗ್ಗೆ',
        'ml': 'വള കാൽക്കുലേറ്ററിനെക്കുറിച്ച്',
        'mr': 'खत गणकाबद्दल माहिती',
        'bn': 'সার ক্যালকুলেটর সম্পর্কে',
        'gu': 'ખાતર કેલ્ક્યુલેટર વિશે',
        'pa': 'ਖਾਦ ਕੈਲਕੁਲੇਟਰ ਬਾਰੇ',
      },
      'about_content': {
        'en': 'This calculator is developed adhering to ICAR and Agricultural University standard packages of practices. Prices reflect current subsidized MRP standards in India.',
        'te': 'ఈ కాలిక్యులేటర్ భారతీయ వ్యవసాయ పరిశోధనా మండలి (ICAR) మరియు వ్యవసాయ విశ్వవిద్యాలయాల సిఫార్సుల ప్రకారం రూపొందించబడింది. ప్రభుత్వ సబ్సిడీ ధరల ఆధారంగా అంచనా వ్యయం లెక్కించబడుతుంది.',
        'ta': 'இந்த கால்குலேட்டர் ICAR மற்றும் வேளாண் பல்கலைக்கழக பரிந்துரைகளின்படி வடிவமைக்கப்பட்டுள்ளது. அரசு மானிய விலைகளின் அடிப்படையில் செலவு கணக்கிடப்படுகிறது.',
        'hi': 'यह कैलकुलेटर भारतीय कृषि अनुसंधान परिषद (ICAR) और कृषि विश्वविद्यालयों की सिफारिशों के आधार पर तैयार किया गया है। सरकारी सब्सिडी दरों पर लागत की गणना की जाती है।',
        'kn': 'ಈ ಕ್ಯಾಲ್ಕುಲೇಟರ್ ಅನ್ನು ICAR ಮತ್ತು ಕೃಷಿ ವಿಶ್ವವಿದ್ಯಾಲಯಗಳ ಶಿಫಾರಸುಗಳ ಆಧಾರದ ಮೇಲೆ ಅಭಿವೃದ್ಧಿಪಡಿಸಲಾಗಿದೆ. ಸರ್ಕಾರದ ಸಬ್ಸಿಡಿ ದರಗಳ ಆಧಾರದ ಮೇಲೆ ವೆಚ್ಚವನ್ನು ಲೆಕ್ಕಹಾಕಲಾಗುತ್ತದೆ.',
        'ml': 'ICAR, കാർഷിക സർവകലാശാലകളുടെ ശുപാർശകൾ പ്രകാരമാണ് ഈ കാൽക്കുലേറ്റർ തയ്യാറാക്കിയിട്ടുള്ളത്. സർക്കാർ സബ്സിഡി നിരക്കുകൾ അടിസ്ഥാനമാക്കിയാണ് ചിലവ് കണക്കാക്കുന്നത്.',
        'mr': 'हे गणक ICAR आणि कृषी विद्यापीठांच्या शिफारशींनुसार तयार केले आहे. सरकारी अनुदानावर आधारित खर्चाचा अंदाज लावला जातो.',
        'bn': 'এই ক্যালকুলেটরটি ICAR ও কৃষি বিশ্ববিদ্যালয়ের সুপারিশ অনুসারে তৈরি। সরকারি ভর্তুকি মূল্যের ভিত্তিতে খরচ গণনা করা হয়।',
        'gu': 'આ કેલ્ક્યુલેટર ICAR અને કૃષિ યુનિવર્સિટીઓની ભલામણો મુજબ તૈયાર કરાયું છે. સરકારી સબસિડીના ભાવોના આધારે ખર્ચ ગણાય છે.',
        'pa': 'ਇਹ ਕੈਲਕੁਲੇਟਰ ICAR ਅਤੇ ਖੇਤੀਬਾੜੀ ਯੂਨੀਵਰਸਿਟੀਆਂ ਦੀਆਂ ਸਿਫ਼ਾਰਸ਼ਾਂ ਅਨੁਸਾਰ ਤਿਆਰ ਕੀਤਾ ਗਿਆ ਹੈ। ਸਰਕਾਰੀ ਸਬਸਿਡੀ ਦਰਾਂ ਦੇ ਆਧਾਰ ਤੇ ਲਾਗਤ ਗਿਣੀ ਜਾਂਦੀ ਹੈ।',
      },
      'got_it': {
        'en': 'Got it',
        'te': 'సరే',
        'ta': 'சரி',
        'hi': 'समझ गया',
        'kn': 'ಸರಿ',
        'ml': 'ശരി',
        'mr': 'समजले',
        'bn': 'ঠিক আছে',
        'gu': 'સમજાયું',
        'pa': 'ਠੀਕ ਹੈ',
      },
    };
    final match = dict[key]?[lang] ?? dict[key]?['en'];
    return match ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(
          _ft('screen_title', langCode),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Fertilizer Guide',
            onPressed: () => _showInfoDialog(langCode),
          ),
        ],
      ),
      body: _isLoadingCrops
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderBanner(langCode),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: _buildInputCard(langCode),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              _ft('calculating', langCode),
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_recommendation != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSummaryCard(langCode),
                    ),
                    const SizedBox(height: 16),
                    _buildTabBar(langCode),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: _buildTabContent(langCode),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(String langCode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ft('banner_title', langCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _ft('banner_subtitle', langCode),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(String langCode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Crop selection
          Text(
            _ft('select_crop', langCode),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SupportedCrop>(
                value: _selectedCrop,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
                items: _crops.map((c) {
                  return DropdownMenuItem<SupportedCrop>(
                    value: c,
                    child: Row(
                      children: [
                        const Icon(Icons.eco, size: 20, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.getLocalizedName(langCode),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCrop = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Farm Area and Unit
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ft('farm_area', langCode),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'e.g. 2.5',
                        prefixIcon: const Icon(Icons.landscape_outlined, color: Colors.green),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ft('unit', langCode),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUnit,
                          isExpanded: true,
                          items: _units.map((u) {
                            String label = u;
                            if (u == 'Acres') label = _ft('unit_acres', langCode);
                            if (u == 'Hectares') label = _ft('unit_hectares', langCode);
                            if (u == 'Guntas') label = _ft('unit_guntas', langCode);
                            return DropdownMenuItem<String>(
                              value: u,
                              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedUnit = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Farming Style Toggle
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(
                    _ft('integrated_type', langCode),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _farmingType == 'Integrated' ? Colors.white : Colors.green.shade900,
                    ),
                  ),
                  selected: _farmingType == 'Integrated',
                  selectedColor: Colors.green.shade700,
                  backgroundColor: Colors.green.shade50,
                  onSelected: (selected) {
                    if (selected) setState(() => _farmingType = 'Integrated');
                  },
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(
                  _ft('organic_type', langCode),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _farmingType == 'Organic' ? Colors.white : Colors.green.shade900,
                  ),
                ),
                selected: _farmingType == 'Organic',
                selectedColor: Colors.green.shade700,
                backgroundColor: Colors.green.shade50,
                onSelected: (selected) {
                  if (selected) setState(() => _farmingType = 'Organic');
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Calculate Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _calculatePlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            icon: const Icon(Icons.calculate, size: 22),
            label: Text(
              _ft('calc_button', langCode),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String langCode) {
    final rec = _recommendation!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    rec.cropLocalName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rec.area} ${rec.unit}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rec.summary,
            style: TextStyle(fontSize: 14, color: Colors.green.shade900, height: 1.4),
          ),
          const Divider(height: 20, color: Color(0xFFC8E6C9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _ft('cost_label', langCode),
                style: TextStyle(fontSize: 13, color: Colors.green.shade800, fontWeight: FontWeight.w600),
              ),
              Text(
                '₹ ${rec.totalEstimatedCost.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(String langCode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.green.shade800,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.green.shade700,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(
            icon: const Icon(Icons.inventory_2_outlined, size: 20),
            text: _ft('tab_bags', langCode),
          ),
          Tab(
            icon: const Icon(Icons.timeline, size: 20),
            text: _ft('tab_schedule', langCode),
          ),
          Tab(
            icon: const Icon(Icons.compost, size: 20),
            text: _ft('tab_organic', langCode),
          ),
          Tab(
            icon: const Icon(Icons.health_and_safety_outlined, size: 20),
            text: _ft('tab_micro', langCode),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String langCode) {
    final rec = _recommendation!;

    return SizedBox(
      height: 480,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildBagsTab(rec, langCode),
          _buildScheduleTab(rec, langCode),
          _buildOrganicTab(rec, langCode),
          _buildMicronutrientTab(rec, langCode),
        ],
      ),
    );
  }

  Widget _buildBagsTab(FertilizerRecommendation rec, String langCode) {
    return ListView(
      children: [
        ...rec.primaryFertilizers.map((item) => _buildBagItemCard(item, langCode)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FertilizerScheduleScreen(
                  cropName: rec.cropLocalName,
                  areaInAcres: rec.areaInAcres,
                  mopAmount: rec.primaryFertilizers
                      .firstWhere((p) => p.name.contains('MOP'), orElse: () => rec.primaryFertilizers.last)
                      .quantityKg
                      .toString(),
                  tspAmount: rec.primaryFertilizers
                      .firstWhere((p) => p.name.contains('DAP') || p.name.contains('SSP'), orElse: () => rec.primaryFertilizers.first)
                      .quantityKg
                      .toString(),
                  ureaAmount: rec.primaryFertilizers
                      .firstWhere((p) => p.name.contains('Urea'), orElse: () => rec.primaryFertilizers.first)
                      .quantityKg
                      .toString(),
                ),
              ));
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.green.shade700, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.calendar_month, color: Colors.green),
            label: Text(
              _ft('view_calendar', langCode),
              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBagItemCard(FertilizerBagItem item, String langCode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.shopping_bag_outlined, color: Colors.green.shade800, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.localName.isNotEmpty ? item.localName : item.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.nutrientType,
                      style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹ ${item.totalEstimatedPrice.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                  Text(
                    _ft('approx_cost', langCode),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.scale, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${item.quantityKg} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.bagsCount} ${_ft("bags_unit", langCode)} (${item.bagWeightKg}kg/bag)',
                    style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.applicationGuide,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(FertilizerRecommendation rec, String langCode) {
    if (rec.growthStageSchedule.isEmpty) {
      return Center(
        child: Text(_ft('no_schedule', langCode)),
      );
    }

    return ListView.builder(
      itemCount: rec.growthStageSchedule.length,
      itemBuilder: (context, index) {
        final stage = rec.growthStageSchedule[index];
        final isLast = index == rec.growthStageSchedule.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicators
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.green.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Stage content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              stage.stageName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stage.timingDays,
                              style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stage.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: stage.fertilizers.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Text(
                              '${f.productName}: ${f.quantityKg} kg (${f.bagsApprox})',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          );
                        }).toList(),
                      ),
                      if (stage.waterPrecaution.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 15, color: Colors.blue),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                stage.waterPrecaution,
                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrganicTab(FertilizerRecommendation rec, String langCode) {
    if (rec.organicAlternatives.isEmpty) {
      return Center(
        child: Text(_ft('no_organic', langCode)),
      );
    }

    return ListView.builder(
      itemCount: rec.organicAlternatives.length,
      itemBuilder: (context, index) {
        final item = rec.organicAlternatives[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco, color: Colors.green.shade800, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.localName.isNotEmpty ? item.localName : item.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          item.quantityPerAcre,
                          style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.benefits,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.handyman_outlined, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.applicationMethod,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMicronutrientTab(FertilizerRecommendation rec, String langCode) {
    return ListView(
      children: [
        if (rec.micronutrients.isNotEmpty) ...[
          Text(
            _ft('essential_micro', langCode),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          ...rec.micronutrients.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.biotech, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          m.nutrient,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(m.importance, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_ft("dose", langCode)}: ${m.dosagePerAcre}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                        ),
                        Text(
                          m.recommendedProduct,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],
        Text(
          _ft('farmer_rules', langCode),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        ...rec.bestPractices.map((bp) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bp,
                      style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            )),
        if (rec.warningNotes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.warningNotes,
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showInfoDialog(String langCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_ft('about_title', langCode)),
        content: Text(_ft('about_content', langCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_ft('got_it', langCode)),
          ),
        ],
      ),
    );
  }
}
