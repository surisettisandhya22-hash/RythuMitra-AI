import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/irrigation_service.dart';

class IrrigationScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;

  const IrrigationScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
  });

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen>
    with SingleTickerProviderStateMixin {
  late IrrigationService _irrigationService;
  late TabController _tabController;

  final TextEditingController _areaController = TextEditingController(text: '1.0');

  final List<String> _popularCrops = [
    'Rice / Paddy',
    'Cotton',
    'Chilli',
    'Maize / Corn',
    'Groundnut',
    'Sugarcane',
    'Tomato',
    'Wheat',
  ];

  final List<String> _stages = [
    'Vegetative',
    'Flowering / Critical',
    'Initial / Seedling',
    'Maturity / Ripening',
  ];

  final List<String> _soilTypes = [
    'Red Sandy Loam',
    'Black Clay Soil',
    'Clay Loam',
    'Sandy Soil',
  ];

  final List<String> _methods = [
    'Drip Irrigation',
    'Sprinkler',
    'AWD (Alternate Wetting & Drying)',
    'Flood / Furrow',
  ];

  final List<double> _pumps = [3.0, 5.0, 7.5, 10.0];

  String _selectedCrop = 'Rice / Paddy';
  String _selectedStage = 'Vegetative';
  String _selectedSoil = 'Red Sandy Loam';
  String _selectedMethod = 'Drip Irrigation';
  double _selectedPumpHp = 5.0;
  String _selectedUnit = 'Acres';

  bool _isLoading = false;
  IrrigationAdviceResponse? _advice;

  @override
  void initState() {
    super.initState();
    _irrigationService = IrrigationService(widget.networkService);
    _tabController = TabController(length: 4, vsync: this);

    // Pre-fill from user profile crops if available
    final userCrops = widget.profileStorageService.getCrops();
    if (userCrops.isNotEmpty) {
      _selectedCrop = userCrops.first.cropName;
      if (userCrops.first.area != null && userCrops.first.area! > 0) {
        _areaController.text = userCrops.first.area!.toString();
      }
    }

    _calculatePlan();
  }

  @override
  void dispose() {
    _areaController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _calculatePlan() async {
    final areaText = _areaController.text.trim();
    final double area = double.tryParse(areaText) ?? 1.0;
    final langCode = Localizations.localeOf(context).languageCode;

    setState(() => _isLoading = true);

    try {
      final res = await _irrigationService.calculateIrrigationPlan(
        crop: _selectedCrop,
        area: area,
        unit: _selectedUnit,
        growthStage: _selectedStage,
        soilType: _selectedSoil,
        irrigationMethod: _selectedMethod,
        pumpHorsepower: _selectedPumpHp,
        rainForecastMm: 0.0,
        languageId: langCode,
      );

      if (mounted) {
        setState(() {
          _advice = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _it(String key, String lang) {
    const Map<String, Map<String, String>> dict = {
      'screen_title': {
        'en': 'Smart Irrigation Agent',
        'te': 'స్మార్ట్ నీటిపారుదల అసిస్టెంట్',
        'ta': 'ஸ்மார்ட் பாசன உதவியாளர்',
        'hi': 'स्मार्ट सिंचाई सहायक',
        'kn': 'ಸ್ಮಾರ್ಟ್ ನೀರಾವರಿ ಸಹಾಯಕ',
        'ml': 'സ്മാർട്ട് ജലസേചന സഹായി',
        'mr': 'स्मार्ट सिंचन सहाय्यक',
        'bn': 'স্মার্ট সেচ সহকারী',
        'gu': 'સ્માર્ટ સિંચાઈ સહાયક',
        'pa': 'ਸਮਾਰਟ ਸਿੰਚਾਈ ਸਹਾਇਕ',
      },
      'banner_title': {
        'en': 'Precision Water Scheduling',
        'te': 'శాస్త్రీయ నీటి నిర్వహణ',
        'ta': 'துல்லியமான பாசன அட்டவணை',
        'hi': 'सटीक सिंचाई प्रबंधन',
        'kn': 'ವೈಜ್ಞಾನಿಕ ನೀರಾವರಿ ನಿರ್ವಹಣೆ',
        'ml': 'കൃത്യമായ ജലസേചന ക്രമം',
        'mr': 'अचूक पाणी व्यवस्थापन',
        'bn': 'নির্ভুল সেচ পরিকল্পনা',
        'gu': 'સૂક્ષ્મ પાણી વ્યવસ્થાપન',
        'pa': 'ਸਹੀ ਪਾਣੀ ਪ੍ਰਬੰਧਨ',
      },
      'banner_sub': {
        'en': 'Evapotranspiration-based pump runtimes, rain delays, and micro-irrigation savings.',
        'te': 'పంట రకం, నేల స్వభావం మరియు వాతావరణం ఆధారంగా మోటార్ రన్‌టైమ్ & నీటి అవసరం లెక్కించండి.',
        'ta': 'பயிர் வகை, மண் மற்றும் வானிலை அடிப்படையில் மோட்டார் நேரம் & நீர் தேவை கணக்கீடு.',
        'hi': 'फसल, मिट्टी और मौसम के आधार पर मोटर चलने का समय और पानी की आवश्यकता जानें।',
        'kn': 'ಬೆಳೆ, ಮಣ್ಣು ಮತ್ತು ಹವಾಮಾನದ ಆಧಾರದ ಮೇಲೆ ಪಂಪ್ ಸಮಯ ಮತ್ತು ನೀರಿನ ಅಗತ್ಯವನ್ನು ಲೆಕ್ಕಹಾಕಿ.',
        'ml': 'വിള, മണ്ണ്, കാലാവസ്ഥ എന്നിവ അടിസ്ഥാനമാക്കി പമ്പ് പ്രവർത്തിക്കേണ്ട സമയവും വെള്ളത്തിന്റെ അളവും കണക്കാക്കുക.',
        'mr': 'पीक, जमीन आणि हवामानानुसार पंपाची वेळ व पाण्याची गरज मोजा.',
        'bn': 'ফসল, মাটি এবং আবহাওয়ার উপর ভিত্তি করে পাম্প চলার সময় ও জলের চাহিদা গণনা করুন।',
        'gu': 'પાક, જમીન અને હવામાન અનુસાર મોટર ચલાવવાનો સમય અને પાણીની જરૂરિયાત ગણો.',
        'pa': 'ਫ਼ਸਲ, ਮਿੱਟੀ ਅਤੇ ਮੌਸਮ ਅਨੁਸਾਰ ਮੋਟਰ ਚੱਲਣ ਦਾ ਸਮਾਂ ਅਤੇ ਪਾਣੀ ਦੀ ਲੋੜ ਜਾਣੋ।',
      },
      'farm_crops': {
        'en': 'Your Farm Crops:',
        'te': 'మీ పంటలు (ప్రొఫైల్ నుండి):',
        'ta': 'உங்கள் பண்ணை பயிர்கள்:',
        'hi': 'आपके खेत की फसलें:',
        'kn': 'ನಿಮ್ಮ ತೋಟದ ಬೆಳೆಗಳು:',
        'ml': 'നിങ്ങളുടെ കൃഷിവിളകൾ:',
        'mr': 'तुमची शेतातील पिके:',
        'bn': 'আপনার খামারের ফসল:',
        'gu': 'તમારા ખેતરના પાકો:',
        'pa': 'ਤੁਹਾਡੇ ਖੇਤ ਦੀਆਂ ਫ਼ਸਲਾਂ:',
      },
      'target_crop': {
        'en': 'Target Crop:',
        'te': 'పంటను ఎంచుకోండి:',
        'ta': 'பயிரைத் தேர்ந்தெடுக்கவும்:',
        'hi': 'लक्षित फसल:',
        'kn': 'ಬೆಳೆ ಆಯ್ಕೆಮಾಡಿ:',
        'ml': 'വിള തിരഞ്ഞെടുക്കുക:',
        'mr': 'लक्षित पीक:',
        'bn': 'উদ্দিষ্ট ফসল:',
        'gu': 'લક્ષિત પાક:',
        'pa': 'ਲੋੜੀਂਦੀ ਫ਼ਸਲ:',
      },
      'farm_area': {
        'en': 'Farm Area:',
        'te': 'విస్తీర్ణం:',
        'ta': 'நிலப்பரப்பு:',
        'hi': 'क्षेत्रफल:',
        'kn': 'ವಿಸ್ತೀರ್ಣ:',
        'ml': 'വിസ്തീർണ്ണം:',
        'mr': 'क्षेत्रफळ:',
        'bn': 'জমির পরিমাণ:',
        'gu': 'વિસ્તાર:',
        'pa': 'ਰਕਬਾ:',
      },
      'unit': {
        'en': 'Unit:',
        'te': 'యూనిట్:',
        'ta': 'அலகு:',
        'hi': 'इकाई:',
        'kn': 'ಘಟಕ:',
        'ml': 'യൂണിറ്റ്:',
        'mr': 'एकक:',
        'bn': 'একক:',
        'gu': 'એકમ:',
        'pa': 'ਇਕਾਈ:',
      },
      'growth_stage': {
        'en': 'Growth Stage:',
        'te': 'ఎదుగుదల దశ:',
        'ta': 'வளர்ச்சி நிலை:',
        'hi': 'वृद्धि चरण:',
        'kn': 'ಬೆಳವಣಿಗೆ ಹಂತ:',
        'ml': 'വളർച്ചാ ഘട്ടം:',
        'mr': 'वाढीचा टप्पा:',
        'bn': 'বৃদ্ধির পর্যায়:',
        'gu': 'વિકાસનો તબક્કો:',
        'pa': 'ਵਾਧੇ ਦਾ ਪੜਾਅ:',
      },
      'soil_type': {
        'en': 'Soil Type:',
        'te': 'నేల రకం:',
        'ta': 'மண் வகை:',
        'hi': 'मिट्टी का प्रकार:',
        'kn': 'ಮಣ್ಣಿನ ವಿಧ:',
        'ml': 'മണ്ണിന്റെ തരം:',
        'mr': 'जमिनीचा प्रकार:',
        'bn': 'মাটির প্রকার:',
        'gu': 'જમીનનો પ્રકાર:',
        'pa': 'ਮਿੱਟੀ ਦੀ ਕਿਸਮ:',
      },
      'method': {
        'en': 'Method:',
        'te': 'పారుదల పద్ధతి:',
        'ta': 'பாசன முறை:',
        'hi': 'सिंचाई विधि:',
        'kn': 'ನೀರಾವರಿ ವಿಧಾನ:',
        'ml': 'നനയ്ക്കൽ രീതി:',
        'mr': 'सिंचन पद्धत:',
        'bn': 'সেচ পদ্ধতি:',
        'gu': 'સિંચાઈ પદ્ધતિ:',
        'pa': 'ਸਿੰਚਾਈ ਤਰੀਕਾ:',
      },
      'pump_hp': {
        'en': 'Pump HP:',
        'te': 'మోటార్ HP:',
        'ta': 'மோட்டார் HP:',
        'hi': 'मोटर HP:',
        'kn': 'ಪಂಪ್ HP:',
        'ml': 'മോട്ടോർ HP:',
        'mr': 'मोटार HP:',
        'bn': 'মোটর HP:',
        'gu': 'મોટર HP:',
        'pa': 'ਮੋਟਰ HP:',
      },
      'calc_plan': {
        'en': 'Calculate Water Plan',
        'te': 'నీటి అవసరాలను లెక్కించండి',
        'ta': 'பாசன திட்டத்தை கணக்கிடுக',
        'hi': 'सिंचाई योजना की गणना करें',
        'kn': 'ನೀರಿನ ಯೋಜನೆಯನ್ನು ಲೆಕ್ಕಹಾಕಿ',
        'ml': 'ജലസേചന പദ്ധതി തയ്യാറാക്കുക',
        'mr': 'पाण्याचे नियोजन मोजा',
        'bn': 'সেচ পরিকল্পনা গণনা করুন',
        'gu': 'પાણી યોજનાની ગણતરી કરો',
        'pa': 'ਪਾਣੀ ਯੋਜਨਾ ਦੀ ਗਣਨਾ ਕਰੋ',
      },
      'advised_today': {
        'en': 'Watering Advised Today',
        'te': 'ఈరోజు నీటి తడి అవసరం',
        'ta': 'இன்று நீர் பாய்ச்ச வேண்டும்',
        'hi': 'आज पानी देना आवश्यक है',
        'kn': 'ಇಂದು ನೀರುಣಿಸುವುದು ಅಗತ್ಯವಿದೆ',
        'ml': 'ഇന്ന് നനയ്ക്കാൻ ശുപാർശ ചെയ്യുന്നു',
        'mr': 'आज पाणी देणे आवश्यक आहे',
        'bn': 'আজ জল সেচ দেওয়া প্রয়োজন',
        'gu': 'આજે પાણી આપવું જરૂરી છે',
        'pa': 'ਅੱਜ ਪਾਣੀ ਲਾਉਣਾ ਜ਼ਰੂਰੀ ਹੈ',
      },
      'hold_off': {
        'en': 'Hold Off Irrigation (Rain Pause)',
        'te': 'నీటిపారుదల వాయిదా వేయండి',
        'ta': 'பாசனத்தை தள்ளிப்போடுங்கள் (மழை வாய்ப்பு)',
        'hi': 'सिंचाई टालें (वर्षा की संभावना)',
        'kn': 'ನೀರಾವರಿ ಮುಂದೂಡಿ (ಮಳೆ ಮುನ್ಸೂಚನೆ)',
        'ml': 'നന മാറ്റിവെക്കുക (മഴ സാധ്യത)',
        'mr': 'सिंचन पुढे ढकला (पावसाची शक्यता)',
        'bn': 'সেচ স্থগিত রাখুন (বৃষ্টির পূর্বাভাস)',
        'gu': 'સિંચાઈ મોકૂફ રાખો (વરસાદની સંભાવના)',
        'pa': 'ਸਿੰਚਾਈ ਟਾਲੋ (ਮੀਂਹ ਦਾ ਅਨੁਮਾਨ)',
      },
      'moisture': {
        'en': 'Moisture',
        'te': 'తేమ',
        'ta': 'ஈரப்பதம்',
        'hi': 'नमी',
        'kn': 'ತೇವಾಂಶ',
        'ml': 'ഈർപ്പം',
        'mr': 'ओलावा',
        'bn': 'আর্দ্রতা',
        'gu': 'ભેજ',
        'pa': 'ਨਮੀ',
      },
      'daily_water': {
        'en': 'Daily Water',
        'te': 'రోజువారీ నీరు',
        'ta': 'தினசரி நீர்',
        'hi': 'दैनिक पानी',
        'kn': 'ದೈನಂದಿನ ನೀರು',
        'ml': 'പ്രതിദിന വെള്ളം',
        'mr': 'दैनिक पाणी',
        'bn': 'দৈনিক জল',
        'gu': 'દૈનિક પાણી',
        'pa': 'ਰੋਜ਼ਾਨਾ ਪਾਣੀ',
      },
      'pump_runtime': {
        'en': 'Pump Run Time',
        'te': 'మోటార్ రన్‌టైమ్',
        'ta': 'மோட்டார் இயங்கும் நேரம்',
        'hi': 'पंप चलने का समय',
        'kn': 'ಪಂಪ್ ಚಾಲನೆಯ ಸಮಯ',
        'ml': 'പമ്പ് പ്രവർത്തിക്കേണ്ട സമയം',
        'mr': 'पंप चालू वेळ',
        'bn': 'পাম্প চলার সময়',
        'gu': 'પંપ ચલાવવાનો સમય',
        'pa': 'ਪੰਪ ਚੱਲਣ ਦਾ ਸਮਾਂ',
      },
      'interval': {
        'en': 'Interval',
        'te': 'తడుల వ్యవధి',
        'ta': 'பாசன இடைவெளி',
        'hi': 'सिंचाई अंतराल',
        'kn': 'ನೀರಾವರಿ ಅಂತರ',
        'ml': 'നനയ്ക്കൽ ഇടവേള',
        'mr': 'पाणी देण्याचा अवधी',
        'bn': 'সেচের ব্যবধান',
        'gu': 'સિંચાઈનું અંતર',
        'pa': 'ਸਿੰਚਾਈ ਦਾ ਵਕਫ਼ਾ',
      },
      'tab_today': {
        'en': 'Today Action',
        'te': 'ఈరోజు ప్రణాళిక',
        'ta': 'இன்றைய நடவடிக்கை',
        'hi': 'आज की कार्ययोजना',
        'kn': 'ಇಂದಿನ ಕ್ರಮ',
        'ml': 'ഇന്നത്തെ നടപടി',
        'mr': 'आजची कृती',
        'bn': 'আজকের করণীয়',
        'gu': 'આજનું પગલું',
        'pa': 'ਅੱਜ ਦੀ ਕਾਰਵਾਈ',
      },
      'tab_schedule': {
        'en': '7-Day Schedule',
        'te': '7-రోజుల షెడ్యూల్',
        'ta': '7-நாள் அட்டவணை',
        'hi': '7-दिवसीय अनुसूची',
        'kn': '7-ದಿನಗಳ ವೇಳಾಪಟ್ಟಿ',
        'ml': '7 ദിവസത്തെ ഷെഡ്യൂൾ',
        'mr': '७-दिवसीय वेळापत्रक',
        'bn': '৭ দিনের সময়সূচী',
        'gu': '૭-દિવસીય સમયપત્રક',
        'pa': '੭ ਦਿਨਾਂ ਸ਼ਡਿਊਲ',
      },
      'tab_methods': {
        'en': 'Methods & Savings',
        'te': 'పారుదల పద్ధతులు',
        'ta': 'பாசன முறைகள் & சேமிப்பு',
        'hi': 'सिंचाई विधियां व बचत',
        'kn': 'ವಿಧಾನಗಳು & ಉಳಿತಾಯ',
        'ml': 'രീതികളും ലാഭവും',
        'mr': 'पद्धती व बचत',
        'bn': 'পদ্ধতি ও সঞ্চয়',
        'gu': 'પદ્ધતિઓ અને બચત',
        'pa': 'ਤਰੀਕੇ ਅਤੇ ਬੱਚਤ',
      },
      'tab_savings': {
        'en': 'Savings & Subsidy',
        'te': 'నీటి ఆదా & సబ్సిడీ',
        'ta': 'நீர் சேமிப்பு & மானியம்',
        'hi': 'जल संरक्षण व सब्सिडी',
        'kn': 'ಉಳಿತಾಯ & ಸಬ್ಸಿಡಿ',
        'ml': 'ജലലാഭവും സബ്സിഡിയും',
        'mr': 'पाण्याची बचत व अनुदान',
        'bn': 'জল সংরক্ষণ ও ভর্তুকি',
        'gu': 'પાણી બચત અને સબસિડી',
        'pa': 'ਪਾਣੀ ਬੱਚਤ ਅਤੇ ਸਬਸਿਡੀ',
      },
      'weather_sync': {
        'en': 'Weather Sync Status',
        'te': 'వాతావరణ సమన్వయం',
        'ta': 'வானிலை ஒத்திசைவு நிலை',
        'hi': 'मौसम समन्वय स्थिति',
        'kn': 'ಹವಾಮಾನ ಹೊಂದಾಣಿಕೆ ಸ್ಥಿತಿ',
        'ml': 'കാലാവസ്ഥ സമന്വയം',
        'mr': 'हवामान ताळमेळ स्थिती',
        'bn': 'আবহাওয়া সমন্বয় স্থিতি',
        'gu': 'હવામાન સંકલન સ્થિતિ',
        'pa': 'ਮੌਸਮ ਤਾਲਮੇਲ ਸਥਿਤੀ',
      },
      'optimal_window': {
        'en': 'Optimal Application Window',
        'te': 'నీరు పెట్టడానికి ఉత్తమ సమయం',
        'ta': 'நீர் பாய்ச்ச சிறந்த நேரம்',
        'hi': 'सिंचाई का सर्वोत्तम समय',
        'kn': 'ನೀರುಣಿಸಲು ಸೂಕ್ತ ಸಮಯ',
        'ml': 'നനയ്ക്കാൻ ഏറ്റവും അനുയോജ്യമായ സമയം',
        'mr': 'पाणी देण्याची सर्वोत्तम वेळ',
        'bn': 'জল সেচ দেওয়ার উপযুক্ত সময়',
        'gu': 'પાણી આપવાનો શ્રેષ્ઠ સમય',
        'pa': 'ਪਾਣੀ ਲਾਉਣ ਦਾ ਸਭ ਤੋਂ ਵਧੀਆ ਸਮਾਂ',
      },
      'critical_stages': {
        'en': 'Critical Moisture-Sensitive Stages:',
        'te': 'పంట కీలక దశలు (నీటి ఎద్దడి రాకూడదు):',
        'ta': 'முக்கிய வளர்ச்சி நிலைகள் (நீர் பற்றாக்குறை கூடாது):',
        'hi': 'फसल के संवेदनशील चरण (पानी की कमी न होने दें):',
        'kn': 'ಬೆಳೆಯ ಸೂಕ್ಷ್ಮ ಹಂತಗಳು (ನೀರಿನ ಕೊರತೆಯಾಗಬಾರದು):',
        'ml': 'നിർണായക ഘട്ടങ്ങൾ (വെള്ളം കുറയാൻ പാടില്ല):',
        'mr': 'पिकाचे संवेदनशील टप्पे (पाण्याचा ताण पडू नये):',
        'bn': 'ফসলের সংবেদনশীল পর্যায় (জলের টান পড়তে দেবেন না):',
        'gu': 'પાકના સંવેદનશીલ તબક્કા (પાણીની અછત ન થવી જોઈએ):',
        'pa': 'ਫ਼ਸਲ ਦੇ ਨਾਜ਼ੁਕ ਪੜਾਅ (ਪਾਣੀ ਦੀ ਕਮੀ ਨਾ ਆਉਣ ਦਿਓ):',
      },
      'run_irrigation': {
        'en': 'Run Irrigation',
        'te': 'తడి ఇవ్వండి',
        'ta': 'நீர் பாய்ச்சவும்',
        'hi': 'सिंचाई करें',
        'kn': 'ನೀರುಣಿಸಿ',
        'ml': 'നനയ്ക്കുക',
        'mr': 'पाणी द्या',
        'bn': 'সেচ দিন',
        'gu': 'પાણી આપો',
        'pa': 'ਪਾਣੀ ਲਾਓ',
      },
      'rest_day': {
        'en': 'Rest Day (No Watering)',
        'te': 'విశ్రాంతి రోజు',
        'ta': 'ஓய்வு நாள் (நீர் தேவையில்லை)',
        'hi': 'विश्राम दिवस (पानी न दें)',
        'kn': 'ವಿಶ್ರಾಂತಿ ದಿನ (ನೀರು ಬೇಡ)',
        'ml': 'വിശ്രമ ദിനം (നനയ്ക്കേണ്ടതില്ല)',
        'mr': 'विश्रांतीचा दिवस (पाणी नको)',
        'bn': 'বিশ্রামের দিন (জল সেচ প্রয়োজন নেই)',
        'gu': 'વિરામનો દિવસ (પાણીની જરૂર નથી)',
        'pa': 'ਆਰਾਮ ਦਾ ਦਿਨ (ਪਾਣੀ ਨਾ ਲਾਓ)',
      },
      'today': {
        'en': 'Today',
        'te': 'ఈరోజు',
        'ta': 'இன்று',
        'hi': 'आज',
        'kn': 'ಇಂದು',
        'ml': 'ഇന്ന്',
        'mr': 'आज',
        'bn': 'আজ',
        'gu': 'આજે',
        'pa': 'ਅੱਜ',
      },
      'water_saved': {
        'en': 'Saved',
        'te': 'నీరు ఆదా',
        'ta': 'சேமிப்பு',
        'hi': 'बचत',
        'kn': 'ಉಳಿತಾಯ',
        'ml': 'ലാഭം',
        'mr': 'बचत',
        'bn': 'সঞ্চয়',
        'gu': 'બચત',
        'pa': 'ਬੱਚਤ',
      },
      'efficiency': {
        'en': 'Efficiency',
        'te': 'సామర్థ్యం',
        'ta': 'திறன்',
        'hi': 'दक्षता',
        'kn': 'ಸಾಮರ್ಥ್ಯ',
        'ml': 'കാര്യക്ഷമത',
        'mr': 'कार्यक्षमता',
        'bn': 'দক্ষতা',
        'gu': 'ક્ષમતા',
        'pa': 'ਸਮਰੱਥਾ',
      },
      'fertigation': {
        'en': 'Fertigation',
        'te': 'ఫెర్టిగేషన్ లభ్యం',
        'ta': 'உரப்பாசனம் சாத்தியம்',
        'hi': 'फर्टिगेशन संभव',
        'kn': 'ಗೊಬ್ಬರ ನೀರಾವರಿ ಸಾಧ್ಯ',
        'ml': 'ഫെർട്ടിഗേഷൻ ലഭ്യമാണ്',
        'mr': 'खत-सिंचन शक्य',
        'bn': 'ফার্টিগেশন সমর্থিত',
        'gu': 'ખાતર સાથે સિંચાઈ શક્ય',
        'pa': 'ਫ਼ਰਟੀਗੇਸ਼ਨ ਸੰਭਵ',
      },
      'conservation_practices': {
        'en': 'Proven Water Conservation Practices:',
        'te': 'నీటి ఆదా పద్ధతులు (Water Conservation):',
        'ta': 'நீர் சேமிப்பு முறைகள்:',
        'hi': 'जल संरक्षण के प्रभावी उपाय:',
        'kn': 'ನೀರು ಉಳಿಸುವ ವಿಧಾನಗಳು:',
        'ml': 'ജലസംരക്ഷണ രീതികൾ:',
        'mr': 'पाणी बचतीचे प्रभावी उपाय:',
        'bn': 'কার্যকর জল সংরক্ষণ পদ্ধতিসমূহ:',
        'gu': 'પાણી બચાવવાની અસરકારક પદ્ધતિઓ:',
        'pa': 'ਪਾਣੀ ਬਚਾਉਣ ਦੇ ਕਾਰਗਰ ਤਰੀਕੇ:',
      },
      'eligible_systems': {
        'en': 'Eligible Systems',
        'te': 'అర్హతగల పరికరాలు',
        'ta': 'தகுதியான உபகரணங்கள்',
        'hi': 'पात्र उपकरण',
        'kn': 'ಅರ್ಹ ಉಪಕರಣಗಳು',
        'ml': 'അർഹമായ ഉപകരണങ്ങൾ',
        'mr': 'पात्र उपकरणे',
        'bn': 'উপযুক্ত যন্ত্রপাতি',
        'gu': 'પાત્ર સાધનો',
        'pa': 'ਯੋਗ ਉਪਕਰਨ',
      },
    };
    final match = dict[key]?[lang] ?? dict[key]?['en'];
    return match ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      appBar: AppBar(
        title: Text(
          _it('screen_title', langCode),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalculate',
            onPressed: _calculatePlan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderBanner(langCode),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildInputCard(langCode),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'Calculating crop water requirements & pump runtimes...',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else if (_advice != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHeroDecisionCard(langCode),
              ),
              const SizedBox(height: 16),
              _buildTabBar(langCode),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          colors: [Colors.blue.shade800, Colors.teal.shade700],
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
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _it('banner_title', langCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _it('banner_sub', langCode),
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
    final userCrops = widget.profileStorageService.getCrops();

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
          // Saved Crop Quick Chips if available
          if (userCrops.isNotEmpty) ...[
            Text(
              _it('farm_crops', langCode),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: userCrops.map((c) {
                  final isSelected = _selectedCrop.toLowerCase() == c.cropName.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(c.cropName),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue.shade900 : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCrop = c.cropName;
                            if (c.area != null && c.area! > 0) {
                              _areaController.text = c.area!.toString();
                            }
                          });
                          _calculatePlan();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Crop Dropdown
          Text(
            _it('target_crop', langCode),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _popularCrops.contains(_selectedCrop) ? _selectedCrop : _popularCrops.first,
                isExpanded: true,
                items: _popularCrops.map((crop) {
                  return DropdownMenuItem<String>(
                    value: crop,
                    child: Text(crop, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCrop = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Area and Unit
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _it('farm_area', langCode),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.landscape, color: Colors.blue),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
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
                      _it('unit', langCode),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUnit,
                          isExpanded: true,
                          items: ['Acres', 'Hectares', 'Guntas'].map((u) {
                            return DropdownMenuItem<String>(
                              value: u,
                              child: Text(u, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          const SizedBox(height: 14),

          // Growth Stage and Soil Type
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _it('growth_stage', langCode),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStage,
                          isExpanded: true,
                          items: _stages.map((s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStage = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _it('soil_type', langCode),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSoil,
                          isExpanded: true,
                          items: _soilTypes.map((st) {
                            return DropdownMenuItem<String>(
                              value: st,
                              child: Text(st, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedSoil = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Irrigation Method and Pump HP
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _it('method', langCode),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMethod,
                          isExpanded: true,
                          items: _methods.map((m) {
                            return DropdownMenuItem<String>(
                              value: m,
                              child: Text(m, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMethod = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _it('pump_hp', langCode),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: _selectedPumpHp,
                          isExpanded: true,
                          items: _pumps.map((hp) {
                            return DropdownMenuItem<double>(
                              value: hp,
                              child: Text('${hp.toStringAsFixed(0)} HP', style: const TextStyle(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPumpHp = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _isLoading ? null : _calculatePlan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.water, size: 20),
            label: Text(
              _it('calc_plan', langCode),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDecisionCard(String langCode) {
    final adv = _advice!;
    final bool shouldIrrigate = adv.shouldIrrigateToday;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: shouldIrrigate ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: shouldIrrigate ? Colors.blue.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decision Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: shouldIrrigate ? Colors.blue.shade700 : Colors.orange.shade700,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  shouldIrrigate ? Icons.water_drop : Icons.pause_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shouldIrrigate
                          ? _it('advised_today', langCode)
                          : _it('hold_off', langCode),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: shouldIrrigate ? Colors.blue.shade900 : Colors.orange.shade900,
                      ),
                    ),
                    Text(
                      '${adv.cropLocalName} • ${adv.area} ${adv.unit}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: shouldIrrigate ? Colors.blue.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${adv.estimatedSoilMoisturePercent}% ${_it("moisture", langCode)}',
                  style: TextStyle(
                    color: shouldIrrigate ? Colors.blue.shade900 : Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Key metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.speed,
                  title: _it('daily_water', langCode),
                  value: '${(adv.dailyWaterRequirementLiters / 1000).toStringAsFixed(1)} kL',
                  sub: '${adv.dailyWaterRequirementLiters.toInt()} Liters',
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.timer,
                  title: _it('pump_runtime', langCode),
                  value: '${adv.pumpRuntimeMinutes} Mins',
                  sub: '${_selectedPumpHp.toStringAsFixed(0)} HP Motor',
                  color: Colors.teal.shade800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.calendar_today,
                  title: _it('interval', langCode),
                  value: '${adv.irrigationIntervalDays} Days',
                  sub: adv.soilType.split(' ').first,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            adv.summary,
            style: TextStyle(fontSize: 13, color: Colors.blue.shade900, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
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
        labelColor: Colors.blue.shade800,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.blue.shade700,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(
            icon: const Icon(Icons.water_drop_outlined, size: 20),
            text: _it('tab_today', langCode),
          ),
          Tab(
            icon: const Icon(Icons.calendar_month, size: 20),
            text: _it('tab_schedule', langCode),
          ),
          Tab(
            icon: const Icon(Icons.compare_arrows, size: 20),
            text: _it('tab_methods', langCode),
          ),
          Tab(
            icon: const Icon(Icons.lightbulb_outline, size: 20),
            text: _it('tab_savings', langCode),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String langCode) {
    final adv = _advice!;

    return SizedBox(
      height: 460,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayActionTab(adv, langCode),
          _buildSevenDayScheduleTab(adv, langCode),
          _buildMethodsComparisonTab(adv, langCode),
          _buildSavingsAndSubsidyTab(adv, langCode),
        ],
      ),
    );
  }

  Widget _buildTodayActionTab(IrrigationAdviceResponse adv, String langCode) {
    return ListView(
      children: [
        // Weather Sync Alert
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wb_sunny_outlined, color: Colors.amber.shade800, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _it('weather_sync', langCode),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adv.weatherSyncNotice,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Best Time to Irrigate
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.access_time, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _it('optimal_window', langCode),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adv.bestTimeToIrrigate,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Critical Stage Alert
        if (adv.criticalStages.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _it('critical_stages', langCode),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...adv.criticalStages.map((cs) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $cs', style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSevenDayScheduleTab(IrrigationAdviceResponse adv, String langCode) {
    return ListView.builder(
      itemCount: adv.sevenDaySchedule.length,
      itemBuilder: (context, idx) {
        final item = adv.sevenDaySchedule[idx];
        final bool isToday = idx == 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.shouldIrrigate ? Colors.blue.shade300 : Colors.grey.shade200,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: item.shouldIrrigate ? Colors.blue.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      item.dayName.substring(0, 3).toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: item.shouldIrrigate ? Colors.blue.shade900 : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      item.dateFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: item.shouldIrrigate ? Colors.blue.shade800 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.shouldIrrigate
                              ? _it('run_irrigation', langCode)
                              : _it('rest_day', langCode),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: item.shouldIrrigate ? Colors.blue.shade900 : Colors.black87,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _it('today', langCode),
                              style: TextStyle(fontSize: 10, color: Colors.green.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.actionSummary,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (item.shouldIrrigate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.recommendedRunTimeMinutes} min',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMethodsComparisonTab(IrrigationAdviceResponse adv, String langCode) {
    return ListView.builder(
      itemCount: adv.methodsComparison.length,
      itemBuilder: (context, idx) {
        final m = adv.methodsComparison[idx];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                      m.localMethodName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (m.waterSavingsPercent > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${m.waterSavingsPercent}% ${_it("water_saved", langCode)}',
                        style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_it("efficiency", langCode)}: ${m.waterEfficiencyPercent}%',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${(m.waterLitersPerAcrePerDay / 1000).toStringAsFixed(1)} kL/acre',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 14),
                  if (m.fertigationSupported)
                    Row(
                      children: [
                        const Icon(Icons.check, size: 14, color: Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          _it('fertigation', langCode),
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                m.keyRecommendation,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavingsAndSubsidyTab(IrrigationAdviceResponse adv, String langCode) {
    return ListView(
      children: [
        // Water-Saving Tips Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.teal.shade700, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _it('conservation_practices', langCode),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...adv.waterSavingTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tip, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Govt Subsidy Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.green.shade800, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      adv.subsidyInfo['schemeName'] ?? 'Micro-Irrigation Subsidy',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  adv.subsidyInfo['subsidyRate'] ?? '70% - 90% Subsidy',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_it("eligible_systems", langCode)}: ${adv.subsidyInfo["eligibleSystems"] ?? ""}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                adv.subsidyInfo['howToApply'] ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
