import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/soil_service.dart';

class SoilHealthScreen extends StatefulWidget {
  const SoilHealthScreen({super.key});

  @override
  State<SoilHealthScreen> createState() => _SoilHealthScreenState();
}

class _SoilHealthScreenState extends State<SoilHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SoilService _soilService = SoilService();

  // Guide State
  SoilSamplingGuide? _guide;
  bool _isLoadingGuide = true;
  String? _currentLang;

  // Manual Input State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cropController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _nitrogenController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _carbonController = TextEditingController();
  final TextEditingController _ecController = TextEditingController();
  String _selectedSoilType = 'Black Cotton Soil';

  final List<String> _soilTypes = [
    'Black Cotton Soil',
    'Red Sandy Loam',
    'Alluvial Soil',
    'Clayey Soil',
    'Sandy Soil',
    'Laterite Soil',
  ];

  // Analysis Result State
  bool _isAnalyzing = false;
  SoilHealthReportResult? _analysisResult;
  File? _selectedReportImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    if (_currentLang != lang) {
      _currentLang = lang;
      _loadGuide(lang);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cropController.dispose();
    _phController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _carbonController.dispose();
    _ecController.dispose();
    super.dispose();
  }

  Future<void> _loadGuide([String? lang]) async {
    final targetLang = lang ?? _currentLang ?? (mounted ? Localizations.localeOf(context).languageCode : 'en');
    setState(() => _isLoadingGuide = true);
    final guide = await _soilService.fetchSamplingGuide(languageId: targetLang);
    if (mounted) {
      setState(() {
        _guide = guide;
        _isLoadingGuide = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedReportImage = File(picked.path);
      });
      _analyzeImageReport();
    }
  }

  Future<void> _analyzeImageReport() async {
    if (_selectedReportImage == null) return;
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    final activeLang = _currentLang ?? Localizations.localeOf(context).languageCode;

    try {
      final result = await _soilService.uploadSoilReportImage(
        imageFile: _selectedReportImage!,
        crop: _cropController.text.trim().isNotEmpty ? _cropController.text.trim() : null,
        languageId: activeLang,
      );
      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activeLang == 'te'
                  ? 'కార్డు విశ్లేషణలో లోపం: $e. ప్రామాణిక సలహా అందించబడుతుంది.'
                  : (activeLang == 'ta'
                      ? 'அட்டை பகுப்பாய்வில் பிழை: $e. நிலையான பரிந்துரை வழங்கப்படுகிறது.'
                      : (activeLang == 'hi'
                          ? 'कार्ड विश्लेषण में त्रुटि: $e. मानक सलाह प्रदान की जा रही है।'
                          : 'Error analyzing card: $e. Using standard soil advisory.')),
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  Future<void> _submitManualParameters() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    final ph = double.tryParse(_phController.text.trim());
    final n = double.tryParse(_nitrogenController.text.trim());
    final p = double.tryParse(_phosphorusController.text.trim());
    final k = double.tryParse(_potassiumController.text.trim());
    final oc = double.tryParse(_carbonController.text.trim());
    final ec = double.tryParse(_ecController.text.trim());

    final activeLang = _currentLang ?? Localizations.localeOf(context).languageCode;

    try {
      final result = await _soilService.analyzeSoilParameters(
        crop: _cropController.text.trim().isNotEmpty ? _cropController.text.trim() : 'Crop',
        soilType: _selectedSoilType,
        ph: ph,
        nitrogen: n,
        phosphorus: p,
        potassium: k,
        organicCarbon: oc,
        electricalConductivity: ec,
        languageId: activeLang,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis error: $e')),
        );
      }
    }
  }

  String _t(String key, String lang) {
    const Map<String, Map<String, String>> strings = {
      'app_title': {
        'en': 'Soil Health & Testing Guide',
        'te': 'మట్టి ఆరోగ్యం & పరీక్ష మార్గదర్శి',
        'ta': 'மண் வளம் & பரிசோதனை வழிகாட்டி',
        'hi': 'मृदा स्वास्थ्य एवं परीक्षण मार्गदर्शिका',
        'kn': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ಮತ್ತು ಪರೀಕ್ಷಾ ಮಾರ್ಗದರ್ಶಿ',
        'ml': 'മണ്ണ് ആരോഗ്യവും പരിശോധനാ മാർഗ്ഗരേഖയും',
        'mr': 'मृदा आरोग्य व चाचणी मार्गदर्शिका',
        'bn': 'মাটির স্বাস্থ্য ও পরীক্ষা নির্দেশিকা',
        'gu': 'જમીન આરોગ્ય અને પરીક્ષણ માર્ગદર્શિકા',
        'pa': 'ਮਿੱਟੀ ਦੀ ਸਿਹਤ ਅਤੇ ਪਰਖ ਗਾਈਡ',
      },
      'tab_guide': {
        'en': 'Sampling Guide',
        'te': 'నమూనా మార్గదర్శి',
        'ta': 'மாதிரி வழிகாட்டி',
        'hi': 'नमूना मार्गदर्शिका',
        'kn': 'ಮಾದರಿ ಮಾರ್ಗದರ್ಶಿ',
        'ml': 'സാമ്പിൾ മാർഗ്ഗരേഖ',
        'mr': 'नमुना मार्गदर्शिका',
        'bn': 'নমুনা সংগ্রহ নির্দেশিকা',
        'gu': 'નમૂના માર્ગદર્શિકા',
        'pa': 'ਨਮੂਨਾ ਗਾਈਡ',
      },
      'tab_analysis': {
        'en': 'AI Soil Analysis',
        'te': 'AI మట్టి విశ్లేషణ',
        'ta': 'AI மண் பகுப்பாய்வு',
        'hi': 'AI मृदा विश्लेषण',
        'kn': 'AI ಮಣ್ಣಿನ ವಿಶ್ಲೇಷಣೆ',
        'ml': 'AI മണ്ണ് വിശകലനം',
        'mr': 'AI मृदा विश्लेषण',
        'bn': 'AI মাটি বিশ্লেষণ',
        'gu': 'AI જમીન વિશ્લેષણ',
        'pa': 'AI ਮਿੱਟੀ ਵਿਸ਼ਲੇਸ਼ਣ',
      },
      'best_time': {
        'en': 'Best Time: ',
        'te': 'అనువైన సమయం: ',
        'ta': 'சிறந்த காலம்: ',
        'hi': 'उचित समय: ',
        'kn': 'ಉತ್ತಮ ಸಮಯ: ',
        'ml': 'ഏറ്റവും അനുയോജ്യമായ സമയം: ',
        'mr': 'योग्य वेळ: ',
        'bn': 'উপযুক্ত সময়: ',
        'gu': 'શ્રેષ્ઠ સમય: ',
        'pa': 'ਸਹੀ ਸਮਾਂ: ',
      },
      'sampling_process': {
        'en': 'Step-by-Step Sampling Process',
        'te': 'దశలవారీగా మట్టి నమూనా తీసే విధానం',
        'ta': 'படிப்படியான மாதிரி சேகரிப்பு முறை',
        'hi': 'चरण-दर-चरण नमूना संग्रह प्रक्रिया',
        'kn': 'ಹಂತ-ಹಂತದ ಮಾದರಿ ಸಂಗ್ರಹಣೆ ಪ್ರಕ್ರಿಯೆ',
        'ml': 'ഘട്ടം ഘട്ടമായുള്ള സാമ്പിൾ ശേഖരണം',
        'mr': 'टप्प्याटप्प्याने नमुना संकलन पद्धत',
        'bn': 'ধাপে ধাপে নমুনা সংগ্রহের পদ্ধতি',
        'gu': 'તબક્કાવાર નમૂના સંગ્રહ પ્રક્રિયા',
        'pa': 'ਕਦਮ-ਦਰ-ਕਦਮ ਨਮੂਨਾ ਇਕੱਠਾ ਕਰਨ ਦੀ ਪ੍ਰਕਿਰਿਆ',
      },
      'dos_and_donts': {
        'en': "Do's and Don'ts",
        'te': 'చేయాల్సినవి & చేయకూడనివి',
        'ta': 'செய்ய வேண்டியவை & செய்யக்கூடாதவை',
        'hi': 'क्या करें और क्या न करें',
        'kn': 'ಮಾಡಬೇಕಾದವು & ಮಾಡಬಾರದವು',
        'ml': 'ചെയ്യേണ്ടവയും ചെയ്യരുതാത്തവയും',
        'mr': 'काय करावे आणि काय करू नये',
        'bn': 'করণীয় এবং বর্জনীয়',
        'gu': 'શું કરવું અને શું ન કરવું',
        'pa': 'ਕੀ ਕਰਨਾ ਅਤੇ ਕੀ ਨਹੀਂ ਕਰਨਾ',
      },
      'dos_heading': {
        'en': "DO'S (Recommended Actions):",
        'te': "DO'S (తప్పనిసరిగా చేయాల్సినవి):",
        'ta': "DO'S (கட்டாயம் செய்ய வேண்டியவை):",
        'hi': "DO'S (अवश्य करने योग्य कार्य):",
        'kn': "ಮಾಡಬೇಕಾದ ಶಿಫಾರಸು ಕ್ರಮಗಳು:",
        'ml': "ശുപാർശ ചെയ്യുന്ന കാര്യങ്ങൾ:",
        'mr': "करावे लागणारे आवश्यक उपाय:",
        'bn': "অবশ্যই করণীয় বিষয়সমূহ:",
        'gu': "અવશ્ય કરવા યોગ્ય કાર્યો:",
        'pa': "ਜ਼ਰੂਰੀ ਕਰਨ ਯੋਗ ਕੰਮ:",
      },
      'donts_heading': {
        'en': "DON'TS (Avoid These):",
        'te': "DON'TS (చేయకూడనివి):",
        'ta': "DON'TS (தவிர்க்க வேண்டியவை):",
        'hi': "DON'TS (भूलकर भी न करें):",
        'kn': "ಮಾಡಬಾರದ ತಪ್ಪುಗಳು:",
        'ml': "ഒഴിവാക്കേണ്ട കാര്യങ്ങൾ:",
        'mr': "टाळावयाच्या गोष्टी:",
        'bn': "বর্জনীয় বিষয়সমূহ:",
        'gu': "ધ્યાનમાં રાખી ટાળવા જેવી બાબતો:",
        'pa': "ਇਹ ਗਲਤੀਆਂ ਨਾ ਕਰੋ:",
      },
      'btn_have_report': {
        'en': 'Already have Soil Report? Analyze Now',
        'te': 'మట్టి పరీక్ష నివేదిక ఉందా? ఇప్పుడే విశ్లేషించండి',
        'ta': 'மண் பரிசோதனை அறிக்கை உள்ளதா? பகுப்பாய்வு செய்க',
        'hi': 'क्या आपके पास मृदा रिपोर्ट है? अभी विश्लेषण करें',
        'kn': 'ಮಣ್ಣಿನ ವರದಿ ಇದೆಯೇ? ಈಗಲೇ ವಿಶ್ಲೇಷಿಸಿ',
        'ml': 'മണ്ണ് റിപ്പോർട്ട് ഉണ്ടോ? ഇപ്പോൾ വിശകലനം ചെയ്യുക',
        'mr': 'माती चाचणी अहवाल आहे का? आता विश्लेषण करा',
        'bn': 'মাটি পরীক্ষার রিপোর্ট আছে? এখনই বিশ্লেষণ করুন',
        'gu': 'જમીન રિપોર્ટ છે? હમણાં જ વિશ્લેષણ કરો',
        'pa': 'ਕੀ ਮਿੱਟੀ ਰਿਪੋਰਟ ਹੈ? ਹੁਣੇ ਵਿਸ਼ਲੇਸ਼ਣ ਕਰੋ',
      },
      'ocr_title': {
        'en': 'Scan Soil Health Card (OCR)',
        'te': 'మట్టి ఆరోగ్య కార్డు స్కాన్ చేయండి (OCR)',
        'ta': 'மண் வள அட்டையை ஸ்கேன் செய்க (OCR)',
        'hi': 'मृदा स्वास्थ्य कार्ड स्कैन करें (OCR)',
        'kn': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ಕಾರ್ಡ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ (OCR)',
        'ml': 'സോയിൽ ഹെൽത്ത് കാർഡ് സ്കാൻ ചെയ്യുക (OCR)',
        'mr': 'मृदा आरोग्य पत्रिका स्कॅन करा (OCR)',
        'bn': 'সয়েল হেলথ কার্ড স্ক্যান করুন (OCR)',
        'gu': 'સોઇલ હેલ્થ કાર્ડ સ્કેન કરો (OCR)',
        'pa': 'ਸੋਇਲ ਹੈਲਥ ਕਾਰਡ ਸਕੈਨ ਕਰੋ (OCR)',
      },
      'ocr_subtitle': {
        'en': 'Have a physical Soil Health Card or lab report? Take a photo or upload it directly for instant AI extraction.',
        'te': 'ల్యాబ్ నుండి మట్టి నివేదిక ఉందా? ఫొటో తీయండి లేదా అప్‌లోడ్ చేసి AI విశ్లేషణ పొందండి.',
        'ta': 'மண் பரிசோதனை அட்டை உள்ளதா? புகைப்படம் எடுக்கவும் அல்லது பதிவேற்றி உடனடி AI விவரங்களை பெறவும்.',
        'hi': 'क्या आपके पास मृदा कार्ड है? फोटो लें या अपलोड करके त्वरित AI विश्लेषण प्राप्त करें।',
        'kn': 'ಲ್ಯಾಬ್ ವರದಿ ಅಥವಾ ಮಣ್ಣಿನ ಆರೋಗ್ಯ ಕಾರ್ಡ್ ಇದೆಯೇ? ಫೋಟೋ ತೆಗೆಯಿರಿ ಅಥವಾ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ AI ವಿಶ್ಲೇಷಣೆ ಪಡೆಯಿರಿ.',
        'ml': 'നിങ്ങളുടെ സോയിൽ കാർഡിന്റെ ഫോട്ടോ എടുക്കുകയോ അപ്‌ലോഡ് ചെയ്യുകയോ ചെയ്ത് തൽക്ഷണ AI വിവരങ്ങൾ നേടുക.',
        'mr': 'प्रयोगशाळेचा अहवाल आहे का? फोटो काढा किंवा थेट अपलोड करून झटपट AI विश्लेषण मिळवा.',
        'bn': 'ল্যাবের রিপোর্ট আছে? ফটো তুলুন বা সরাসরি আপলোড করে তাৎক্ষণিক AI বিশ্লেষণ পান।',
        'gu': 'લેબ રિપોર્ટ અથવા કાર્ડ છે? ફોટો પાડો અથવા સીધું અપલોડ કરીને ત્વરિત AI વિશ્લેષણ મેળવો.',
        'pa': 'ਲੈਬ ਰਿਪੋਰਟ ਜਾਂ ਕਾਰਡ ਹੈ? ਫੋਟੋ ਖਿੱਚੋ ਜਾਂ ਅਪਲੋਡ ਕਰਕੇ ਤੁਰੰਤ AI ਵਿਸ਼ਲੇਸ਼ਣ ਪ੍ਰਾਪਤ ਕਰੋ।',
      },
      'take_photo': {
        'en': 'Take Photo',
        'te': 'ఫొటో తీయండి',
        'ta': 'புகைப்படம் எடுக்க',
        'hi': 'फोटो खींचें',
        'kn': 'ಫೋಟೋ ತೆಗೆಯಿರಿ',
        'ml': 'ഫോട്ടോ എടുക്കുക',
        'mr': 'फोटो काढा',
        'bn': 'ছবি তুলুন',
        'gu': 'ફોટો પાડો',
        'pa': 'ਫੋਟੋ ਖਿੱਚੋ',
      },
      'upload_image': {
        'en': 'Upload Image',
        'te': 'చిత్రం అప్‌లోడ్ చేయండి',
        'ta': 'படம் பதிவேற்றுக',
        'hi': 'छवि अपलोड करें',
        'kn': 'ಚಿತ್ರ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
        'ml': 'ചിത്രം അപ്‌ലോഡ് ചെയ്യുക',
        'mr': 'फोटो अपलोड करा',
        'bn': 'ছবি আপলোড করুন',
        'gu': 'છબી અપલોડ કરો',
        'pa': 'ਤਸਵੀਰ ਅਪਲੋਡ ਕਰੋ',
      },
      'or_manual': {
        'en': 'OR ENTER VALUES MANUALLY',
        'te': 'లేదా వివరాలను నేరుగా నమోదు చేయండి',
        'ta': 'அல்லது கைமுறையாக உள்ளிடவும்',
        'hi': 'या विवरण मैन्युअल रूप से दर्ज करें',
        'kn': 'ಅಥವಾ ವಿವರಗಳನ್ನು ಹಸ್ತಚಾಲಿತವಾಗಿ ನಮೂದಿಸಿ',
        'ml': 'അല്ലെങ്കിൽ വിവരങ്ങൾ നേരിട്ട് നൽകുക',
        'mr': 'किंवा मूल्ये थेट हाताने प्रविष्ट करा',
        'bn': 'অথবা বিবরণ সরাসরি টাইপ করুন',
        'gu': 'અથવા વિગતો જાતે દાખલ કરો',
        'pa': 'ਜਾਂ ਵੇਰਵੇ ਖੁਦ ਦਰਜ ਕਰੋ',
      },
      'form_title': {
        'en': 'Soil & Target Crop Details',
        'te': 'నేల & సాగు చేసే పంట వివరాలు',
        'ta': 'மண் & பயிர் விவரங்கள்',
        'hi': 'मिट्टी एवं लक्षित फसल विवरण',
        'kn': 'ಮಣ್ಣು ಮತ್ತು ಬೆಳೆ ವಿವರಗಳು',
        'ml': 'മണ്ണും വിള വിവരങ്ങളും',
        'mr': 'माती आणि पीक तपशील',
        'bn': 'মাটি ও ফসলের বিবরণ',
        'gu': 'જમીન અને પાકની વિગતો',
        'pa': 'ਮਿੱਟੀ ਅਤੇ ਫ਼ਸਲ ਦੇ ਵੇਰਵੇ',
      },
      'target_crop': {
        'en': 'Target Crop (e.g., Rice, Cotton, Chilli, Tomato)',
        'te': 'సాగు చేసే పంట (ఉదా: వరి, పత్తి, మిరప, టమోటా)',
        'ta': 'பயிர் (எ.கா: நெல், பருத்தி, மிளகாய், தக்காளி)',
        'hi': 'लक्षित फसल (उदा: धान, कपास, मिर्च, टमाटर)',
        'kn': 'ಬೆಳೆ (ಉದಾ: ಭತ್ತ, ಹತ್ತಿ, ಮೆಣಸಿನಕಾಯಿ, ಟೊಮೆಟೊ)',
        'ml': 'വിള (ഉദാ: നെല്ല്, പരുത്തി, മുളക്, തക്കാളി)',
        'mr': 'पीक (उदा: भात, कापूस, मिरची, टोमॅटो)',
        'bn': 'ফসল (যেমন: ধান, তুলা, লঙ্কা, টমেটো)',
        'gu': 'પાક (દા.ત: ડાંગર, કપાસ, મરચાં, ટામેટા)',
        'pa': 'ਫ਼ਸਲ (ਜਿਵੇਂ: ਝੋਨਾ, ਨਰਮਾ, ਮਿਰਚ, ਟਮਾਟਰ)',
      },
      'soil_type': {
        'en': 'Soil Type',
        'te': 'నేల రకం',
        'ta': 'மண் வகை',
        'hi': 'मिट्टी का प्रकार',
        'kn': 'ಮಣ್ಣಿನ ವಿಧ',
        'ml': 'മണ്ണിന്റെ തരം',
        'mr': 'मातीचा प्रकार',
        'bn': 'মাটির প্রকার',
        'gu': 'જમીનનો પ્રકાર',
        'pa': 'ਮਿੱਟੀ ਦੀ ਕਿਸਮ',
      },
      'ph_label': {
        'en': 'pH Level (0-14)',
        'te': 'pH స్థాయి (0-14)',
        'ta': 'pH அளவு (0-14)',
        'hi': 'pH मान (0-14)',
        'kn': 'pH ಮಟ್ಟ (0-14)',
        'ml': 'pH നില (0-14)',
        'mr': 'pH पातळी (0-14)',
        'bn': 'pH মাত্রা (0-14)',
        'gu': 'pH સ્તર (0-14)',
        'pa': 'pH ਪੱਧਰ (0-14)',
      },
      'carbon_label': {
        'en': 'Organic Carbon (%)',
        'te': 'సేంద్రీయ కర్బనం (%)',
        'ta': 'கரிமக் கார்பன் (%)',
        'hi': 'जैविक कार्बन (%)',
        'kn': 'ಸಾವಯವ ಇಂಗಾಲ (%)',
        'ml': 'ഓർഗാനിക് കാർബൺ (%)',
        'mr': 'सेंद्रिय कर्ब (%)',
        'bn': 'জৈব কার্বন (%)',
        'gu': 'સેન્દ્રિય કાર્બન (%)',
        'pa': 'ਜੈਵਿਕ ਕਾਰਬਨ (%)',
      },
      'ec_label': {
        'en': 'Electrical Conductivity / EC (dS/m) (Optional)',
        'te': 'విద్యుత్ వాహకత / EC (dS/m) (ఐచ్ఛికం)',
        'ta': 'மின் கடத்துத்திறன் / EC (dS/m) (விருப்பமானது)',
        'hi': 'विद्युत चालकता / EC (dS/m) (वैकल्पिक)',
        'kn': 'ವಿದ್ಯುತ್ ವಾಹಕತೆ / EC (dS/m) (ಐಚ್ಛಿಕ)',
        'ml': 'വൈദ്യുത ചാലകത / EC (dS/m) (ഓപ്ഷണൽ)',
        'mr': 'विद्युत चालकता / EC (dS/m) (पर्यायी)',
        'bn': 'তড়িৎ পরিবাহিতা / EC (dS/m) (ঐচ্ছিক)',
        'gu': 'વીજ વાહકતા / EC (dS/m) (વૈકલ્પિક)',
        'pa': 'ਬਿਜਲਈ ਚਾਲਕਤਾ / EC (dS/m) (ਵਿਕਲਪਿਕ)',
      },
      'btn_analyze': {
        'en': 'Analyze Soil Health',
        'te': 'మట్టి ఆరోగ్యాన్ని విశ్లేషించండి',
        'ta': 'மண் வளத்தை பகுப்பாய்வு செய்க',
        'hi': 'मृदा स्वास्थ्य का विश्लेषण करें',
        'kn': 'ಮಣ್ಣಿನ ಆರೋಗ್ಯ ವಿಶ್ಲೇಷಿಸಿ',
        'ml': 'മണ്ണ് ആരോഗ്യം വിശകലനം ചെയ്യുക',
        'mr': 'मातीच्या आरोग्याचे विश्लेषण करा',
        'bn': 'মাটির স্বাস্থ্য বিশ্লেষণ করুন',
        'gu': 'જમીન આરોગ્યનું વિશ્લેષણ કરો',
        'pa': 'ਮਿੱਟੀ ਦੀ ਸਿਹਤ ਦਾ ਵਿਸ਼ਲੇਸ਼ਣ ਕਰੋ',
      },
      'btn_analyzing': {
        'en': 'Analyzing with AI...',
        'te': 'AI తో విశ్లేషిస్తోంది...',
        'ta': 'AI மூலம் பகுப்பாய்வு செய்கிறது...',
        'hi': 'AI विश्लेषण जारी है...',
        'kn': 'AI ವಿಶ್ಲೇಷಣೆ ನಡೆಯುತ್ತಿದೆ...',
        'ml': 'AI വിശകലനം പുരോഗമിക്കുന്നു...',
        'mr': 'AI विश्लेषण सुरू आहे...',
        'bn': 'AI বিশ্লেষণ চলছে...',
        'gu': 'AI વિશ્લેષણ ચાલુ છે...',
        'pa': 'AI ਵਿਸ਼ਲੇਸ਼ਣ ਜਾਰੀ ਹੈ...',
      },
      'analysis_header': {
        'en': 'AI Soil Report Analysis',
        'te': 'AI మట్టి నివేదిక విశ్లేషణ',
        'ta': 'AI மண் அறிக்கை பகுப்பாய்வு',
        'hi': 'AI मृदा रिपोर्ट विश्लेषण',
        'kn': 'AI ಮಣ್ಣಿನ ವರದಿ ವಿಶ್ಲೇಷಣೆ',
        'ml': 'AI സോയിൽ റിപ്പോർട്ട് വിശകലനം',
        'mr': 'AI माती अहवाल विश्लेषण',
        'bn': 'AI মাটি রিপোর্ট বিশ্লেষণ',
        'gu': 'AI જમીન રિપોર્ટ વિશ્લેષણ',
        'pa': 'AI ਮਿੱਟੀ ਰਿਪੋਰਟ ਵਿਸ਼ਲੇਸ਼ਣ',
      },
      'conditioning_header': {
        'en': 'Soil Conditioning & Amendments:',
        'te': 'నేల యాజమాన్యం & మెరుగుపరిచే చర్యలు:',
        'ta': 'மண் சீரமைப்பு மற்றும் மேம்பாட்டு முறைகள்:',
        'hi': 'मृदा सुधार एवं आवश्यक उपाय:',
        'kn': 'ಮಣ್ಣಿನ ಸುಧಾರಣೆ ಮತ್ತು ಕ್ರಮಗಳು:',
        'ml': 'മണ്ണ് പുനരുദ്ധാരണ മാർഗ്ഗങ്ങൾ:',
        'mr': 'जमीन सुधारणा व आवश्यक उपाय:',
        'bn': 'মাটির গুণমান উন্নয়ন ও সংশোধন ব্যবস্থা:',
        'gu': 'જમીન સુધારણા અને ઉપાયો:',
        'pa': 'ਮਿੱਟੀ ਸੁਧਾਰ ਅਤੇ ਲੋੜੀਂਦੇ ਉਪਾਅ:',
      },
      'fertilizer_header': {
        'en': 'Fertilizer Application Plan:',
        'te': 'ఎరువుల యాజమాన్య ప్రణాళిక:',
        'ta': 'உர மேலாண்மை திட்டம்:',
        'hi': 'उर्वरक प्रबंधन योजना:',
        'kn': 'ಗೊಬ್ಬರ ನಿರ್ವಹಣಾ ಯೋಜನೆ:',
        'ml': 'വള പ്രയോഗ പദ്ധതി:',
        'mr': 'खत व्यवस्थापन नियोजन:',
        'bn': 'সার প্রয়োগ পরিকল্পনা:',
        'gu': 'ખાતર વ્યવસ્થાપન યોજના:',
        'pa': 'ਖਾਦ ਪ੍ਰਬੰਧਨ ਯੋਜਨਾ:',
      },
      'crops_header': {
        'en': 'Highly Suitable Crops for this Soil:',
        'te': 'ఈ నేలకు అత్యంత అనువైన పంటలు:',
        'ta': 'இந்த மண்ணிற்கு மிகவும் ஏற்ற பயிர்கள்:',
        'hi': 'इस मिट्टी के लिए उपयुक्त फसलें:',
        'kn': 'ಈ ಮಣ್ಣಿಗೆ ಹೆಚ್ಚು ಸೂಕ್ತವಾದ ಬೆಳೆಗಳು:',
        'ml': 'ഈ മണ്ണിന് ഏറ്റവും അനുയോജ്യമായ വിളകൾ:',
        'mr': 'या जमिनीसाठी अत्यंत योग्य पिके:',
        'bn': 'এই মাটির জন্য সবচেয়ে উপযোগী ফসল:',
        'gu': 'આ જમીન માટે સૌથી અનુકૂળ પાકો:',
        'pa': 'ਇਸ ਮਿੱਟੀ ਲਈ ਸਭ ਤੋਂ ਢੁੱਕਵੀਆਂ ਫ਼ਸਲਾਂ:',
      },
      'guide_not_available': {
        'en': 'Guide not available.',
        'te': 'మార్గదర్శి అందుబాటులో లేదు.',
        'ta': 'வழிகாட்டி கிடைக்கவில்லை.',
        'hi': 'मार्गदर्शिका उपलब्ध नहीं है।',
        'kn': 'ಮಾರ್ಗದರ್ಶಿ ಲಭ್ಯವಿಲ್ಲ.',
        'ml': 'മാർഗ്ഗരേഖ ലഭ്യമല്ല.',
        'mr': 'मार्गदर्शिका उपलब्ध नाही.',
        'bn': 'নির্দেশিকা পাওয়া যায়নি।',
        'gu': 'માર્ગદર્શિકા ઉપલબ્ધ નથી.',
        'pa': 'ਗਾਈਡ ਉਪਲਬਧ ਨਹੀਂ ਹੈ।',
      },
    };

    final entry = strings[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['en'] ?? key;
  }

  String _getSoilTypeName(String type, String lang) {
    const Map<String, Map<String, String>> names = {
      'Black Cotton Soil': {
        'en': 'Black Cotton Soil',
        'te': 'నల్లరేగడి నేల (Black Soil)',
        'ta': 'கரிசல் மண் (Black Soil)',
        'hi': 'काली मिट्टी (Black Cotton Soil)',
        'kn': 'ಕಪ್ಪು ಹತ್ತಿ ಮಣ್ಣು (Black Soil)',
        'ml': 'കരിമണ്ണ് (Black Cotton Soil)',
        'mr': 'काळी कसदार माती (Black Soil)',
        'bn': 'কালো মাটি (Black Soil)',
        'gu': 'કાળી કપાસની જમીન (Black Soil)',
        'pa': 'ਕਾਲੀ ਮਿੱਟੀ (Black Cotton Soil)',
      },
      'Red Sandy Loam': {
        'en': 'Red Sandy Loam',
        'te': 'ఎర్ర ఇసుక నేల (Red Loam)',
        'ta': 'செம்மண் (Red Soil)',
        'hi': 'लाल बलुई दोमट (Red Loam)',
        'kn': 'ಕೆಂಪು ಮರಳು ಮಿಶ್ರಿತ ಮಣ್ಣು (Red Loam)',
        'ml': 'ചുവന്ന മണൽ മണ്ണ് (Red Soil)',
        'mr': 'तांबडी वालुकामय माती (Red Loam)',
        'bn': 'লাল বেলে দোআঁশ মাটি (Red Soil)',
        'gu': 'લાલ રેતાળ ગોરાડુ જમીન (Red Loam)',
        'pa': 'ਲਾਲ ਰੇਤਲੀ ਮਿੱਟੀ (Red Loam)',
      },
      'Alluvial Soil': {
        'en': 'Alluvial Soil',
        'te': 'ఒండ్రు నేల (Alluvial Soil)',
        'ta': 'வண்டல் மண் (Alluvial Soil)',
        'hi': 'जलोढ़ मिट्टी (Alluvial Soil)',
        'kn': 'ಮೆಕ್ಕಲು ಮಣ್ಣು (Alluvial Soil)',
        'ml': 'എക്കൽ മണ്ണ് (Alluvial Soil)',
        'mr': 'गाळाची जमीन (Alluvial Soil)',
        'bn': 'পলি মাটি (Alluvial Soil)',
        'gu': 'કાંપની જમીન (Alluvial Soil)',
        'pa': 'ਜਲੋੜ ਮਿੱਟੀ (Alluvial Soil)',
      },
      'Clayey Soil': {
        'en': 'Clayey Soil',
        'te': 'బంకమట్టి నేల (Clayey Soil)',
        'ta': 'களிமண் (Clayey Soil)',
        'hi': 'चिकनी मिट्टी (Clayey Soil)',
        'kn': 'ಜೇಡಿ ಮಣ್ಣು (Clayey Soil)',
        'ml': 'കളിമണ്ണ് (Clayey Soil)',
        'mr': 'चिकਣমাती (Clayey Soil)',
        'bn': 'এঁটেল মাটি (Clayey Soil)',
        'gu': 'ચીકણી માટી (Clayey Soil)',
        'pa': 'ਚੀਕਣੀ ਮਿੱਟੀ (Clayey Soil)',
      },
      'Sandy Soil': {
        'en': 'Sandy Soil',
        'te': 'ఇసుక నేల (Sandy Soil)',
        'ta': 'மணல் மண் (Sandy Soil)',
        'hi': 'बलुई मिट्टी (Sandy Soil)',
        'kn': 'ಮರಳು ಮಣ್ಣು (Sandy Soil)',
        'ml': 'മണൽ മണ്ണ് (Sandy Soil)',
        'mr': 'वालुकामय जमीन (Sandy Soil)',
        'bn': 'বেলে মাটি (Sandy Soil)',
        'gu': 'રેતાળ જમીન (Sandy Soil)',
        'pa': 'ਰੇਤਲੀ ਮਿੱਟੀ (Sandy Soil)',
      },
      'Laterite Soil': {
        'en': 'Laterite Soil',
        'te': 'లాటరైట్ నేల (Laterite Soil)',
        'ta': 'சரளை மண் (Laterite Soil)',
        'hi': 'लैटेराइट मिट्टी (Laterite Soil)',
        'kn': 'ಲ್ಯಾಟರೈಟ್ ಮಣ್ಣು (Laterite Soil)',
        'ml': 'ലാറ്ററൈറ്റ് മണ്ണ് (Laterite Soil)',
        'mr': 'जांभी माती (Laterite Soil)',
        'bn': 'ল্যাটেরাইট মাটি (Laterite Soil)',
        'gu': 'લેટેરાઇટ માટી (Laterite Soil)',
        'pa': 'ਲੈਟਰਾਈਟ ਮਿੱਟੀ (Laterite Soil)',
      },
    };
    return names[type]?[lang] ?? names[type]?['en'] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langCode = _currentLang ?? Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('app_title', langCode),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF5D4037), // earthy brown
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF81C784),
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: [
            Tab(icon: const Icon(Icons.menu_book), text: _t('tab_guide', langCode)),
            Tab(icon: const Icon(Icons.biotech), text: _t('tab_analysis', langCode)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuideTab(theme, langCode),
          _buildAnalysisTab(theme, langCode),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: SAMPLING GUIDE
  // -------------------------------------------------------------
  Widget _buildGuideTab(ThemeData theme, String langCode) {
    if (_isLoadingGuide) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF5D4037)));
    }

    final guide = _guide;
    if (guide == null) {
      return Center(child: Text(_t('guide_not_available', langCode)));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Hero Header Card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5D4037), Color(0xFF795548)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.terrain, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guide.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                guide.importance,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E342E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF81C784), size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${_t('best_time', langCode)}${guide.bestTiming}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text(
          _t('sampling_process', langCode),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Steps List
        ...guide.steps.map((step) => _buildStepCard(step)),

        const SizedBox(height: 16),

        // Do's and Don'ts Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rule, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      _t('dos_and_donts', langCode),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  _t('dos_heading', langCode),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ...guide.dos.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _t('donts_heading', langCode),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ...guide.donts.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            _tabController.animateTo(1);
          },
          icon: const Icon(Icons.arrow_forward),
          label: Text(_t('btn_have_report', langCode)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5D4037),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(SoilGuideStep step) {
    IconData getIcon(String iconName) {
      switch (iconName) {
        case 'map':
          return Icons.alt_route;
        case 'cleaning_services':
          return Icons.cleaning_services;
        case 'content_cut':
          return Icons.architecture;
        case 'layers':
          return Icons.layers;
        case 'pie_chart':
          return Icons.pie_chart;
        case 'label':
          return Icons.local_offer;
        default:
          return Icons.grass;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: step.stepNumber <= 2,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFEBE9),
          foregroundColor: const Color(0xFF5D4037),
          child: Text(
            '${step.stepNumber}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          step.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(getIcon(step.icon), color: const Color(0xFF795548), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
          if (step.tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: step.tips
                    .map(
                      (t) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, size: 14, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              t,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: AI SOIL HEALTH ANALYSIS
  // -------------------------------------------------------------
  Widget _buildAnalysisTab(ThemeData theme, String langCode) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Camera / Upload Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.document_scanner, color: Color(0xFF5D4037)),
                    const SizedBox(width: 8),
                    Text(
                      _t('ocr_title', langCode),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _t('ocr_subtitle', langCode),
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                if (_selectedReportImage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(_selectedReportImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: Text(_t('take_photo', langCode)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5D4037),
                          side: const BorderSide(color: Color(0xFF5D4037)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: Text(_t('upload_image', langCode)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D4037),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                _t('or_manual', langCode),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        // Manual Input Form
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('form_title', langCode),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  // Target Crop
                  TextFormField(
                    controller: _cropController,
                    decoration: InputDecoration(
                      labelText: _t('target_crop', langCode),
                      prefixIcon: const Icon(Icons.eco, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Soil Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSoilType,
                    decoration: InputDecoration(
                      labelText: _t('soil_type', langCode),
                      prefixIcon: const Icon(Icons.landscape, color: Colors.brown),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _soilTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(_getSoilTypeName(type, langCode)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSoilType = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // pH & Organic Carbon Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _phController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: _t('ph_label', langCode),
                            hintText: 'e.g. 7.2',
                            prefixIcon: const Icon(Icons.science),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _carbonController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: _t('carbon_label', langCode),
                            hintText: 'e.g. 0.55',
                            prefixIcon: const Icon(Icons.compost),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // N, P, K row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nitrogenController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'N (kg/ha)',
                            hintText: '240',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phosphorusController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'P (kg/ha)',
                            hintText: '18',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _potassiumController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'K (kg/ha)',
                            hintText: '180',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // EC Electrical Conductivity
                  TextFormField(
                    controller: _ecController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _t('ec_label', langCode),
                      hintText: 'e.g. 0.8',
                      prefixIcon: const Icon(Icons.bolt),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _submitManualParameters,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.analytics),
                      label: Text(
                        _isAnalyzing ? _t('btn_analyzing', langCode) : _t('btn_analyze', langCode),
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5D4037),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Result Display Card
        if (_analysisResult != null) ...[
          const SizedBox(height: 20),
          _buildAnalysisResultCard(_analysisResult!, langCode),
        ],
      ],
    );
  }

  Widget _buildAnalysisResultCard(SoilHealthReportResult result, String langCode) {
    Color getStatusColor(String health) {
      final h = health.toLowerCase();
      if (h.contains('good') ||
          h.contains('optimal') ||
          h.contains('అనుకూలం') ||
          h.contains('உகந்தது') ||
          h.contains('उत्कृष्ट')) {
        return Colors.green.shade700;
      }
      if (h.contains('moderate') ||
          h.contains('conditioning') ||
          h.contains('సవరణ') ||
          h.contains('சீரமைப்பு') ||
          h.contains('सुधार')) {
        return Colors.orange.shade800;
      }
      return Colors.red.shade700;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.health_and_safety, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      _t('analysis_header', langCode),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: getStatusColor(result.overallHealth).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: getStatusColor(result.overallHealth)),
                  ),
                  child: Text(
                    result.overallHealth,
                    style: TextStyle(
                      color: getStatusColor(result.overallHealth),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Summary
            Text(
              result.summary,
              style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),

            // pH Analysis
            if (result.phAnalysis != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.science, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.phAnalysis!,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Soil Conditioning Recommendations
            if (result.conditioningRecommendations.isNotEmpty) ...[
              Text(
                _t('conditioning_header', langCode),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              const SizedBox(height: 6),
              ...result.conditioningRecommendations.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.spa, color: Colors.brown, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Fertilizer Plan
            if (result.fertilizerPlan.isNotEmpty) ...[
              Text(
                _t('fertilizer_header', langCode),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 6),
              ...result.fertilizerPlan.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(plan, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Suitable Crops
            if (result.suitableCrops.isNotEmpty) ...[
              Text(
                _t('crops_header', langCode),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: result.suitableCrops
                    .map(
                      (c) => Chip(
                        avatar: const Icon(Icons.grass, size: 16, color: Colors.white),
                        label: Text(c, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Precaution Note
            if (result.warningNotes != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.warningNotes!,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
