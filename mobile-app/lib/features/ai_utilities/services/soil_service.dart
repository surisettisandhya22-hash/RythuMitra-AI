import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

class SoilGuideStep {
  final int stepNumber;
  final String title;
  final String description;
  final String icon;
  final List<String> tips;

  SoilGuideStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.tips,
  });

  factory SoilGuideStep.fromJson(Map<String, dynamic> json) {
    return SoilGuideStep(
      stepNumber: json['stepNumber'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'map',
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
}

class SoilSamplingGuide {
  final String title;
  final String importance;
  final String bestTiming;
  final List<SoilGuideStep> steps;
  final List<String> dos;
  final List<String> donts;

  SoilSamplingGuide({
    required this.title,
    required this.importance,
    required this.bestTiming,
    required this.steps,
    required this.dos,
    required this.donts,
  });

  factory SoilSamplingGuide.fromJson(Map<String, dynamic> json) {
    final dosAndDonts = json['dosAndDonts'] as Map<String, dynamic>? ?? {};
    return SoilSamplingGuide(
      title: json['title'] ?? 'Soil Sampling Guide',
      importance: json['importance'] ?? '',
      bestTiming: json['bestTiming'] ?? '',
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((s) => SoilGuideStep.fromJson(s))
          .toList(),
      dos: List<String>.from(dosAndDonts['dos'] ?? []),
      donts: List<String>.from(dosAndDonts['donts'] ?? []),
    );
  }
}

class SoilHealthReportResult {
  final String overallHealth;
  final String summary;
  final String? phAnalysis;
  final Map<String, dynamic>? nutrientAssessments;
  final List<String> conditioningRecommendations;
  final List<String> fertilizerPlan;
  final List<String> suitableCrops;
  final String? warningNotes;

  SoilHealthReportResult({
    required this.overallHealth,
    required this.summary,
    this.phAnalysis,
    this.nutrientAssessments,
    required this.conditioningRecommendations,
    required this.fertilizerPlan,
    required this.suitableCrops,
    this.warningNotes,
  });

  factory SoilHealthReportResult.fromJson(Map<String, dynamic> json) {
    return SoilHealthReportResult(
      overallHealth: json['overallHealth'] ?? 'Good',
      summary: json['summary'] ?? '',
      phAnalysis: json['phAnalysis'],
      nutrientAssessments: json['nutrientAssessments'] as Map<String, dynamic>?,
      conditioningRecommendations:
          List<String>.from(json['conditioningRecommendations'] ?? []),
      fertilizerPlan: List<String>.from(json['fertilizerPlan'] ?? []),
      suitableCrops: List<String>.from(json['suitableCrops'] ?? []),
      warningNotes: json['warningNotes'],
    );
  }
}

class SoilService {
  String get _baseUrl => ApiConfig.baseUrl;

  Future<SoilSamplingGuide> fetchSamplingGuide({String languageId = 'en'}) async {
    try {
      final url = Uri.parse('$_baseUrl/api/soil/guide?languageId=$languageId');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return SoilSamplingGuide.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching soil guide from server: $e. Falling back to local copy.');
    }

    // High quality offline fallback
    return _getLocalSamplingGuide(languageId);
  }

  Future<SoilHealthReportResult> analyzeSoilParameters({
    String? crop,
    String? soilType,
    double? ph,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? organicCarbon,
    double? electricalConductivity,
    String languageId = 'en',
  }) async {
    final url = Uri.parse('$_baseUrl/api/soil/analyze');
    final payload = {
      'crop': crop,
      'soilType': soilType,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'organicCarbon': organicCarbon,
      'electricalConductivity': electricalConductivity,
      'languageId': languageId,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return SoilHealthReportResult.fromJson(data);
      } else {
        throw Exception('Server returned code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Soil analysis API error: $e');
      // Graceful fallback heuristic
      return _generateLocalHeuristicAnalysis(
        crop: crop ?? 'General Crops',
        ph: ph,
        nitrogen: nitrogen,
        phosphorus: phosphorus,
        potassium: potassium,
        organicCarbon: organicCarbon,
        languageId: languageId,
      );
    }
  }

  Future<SoilHealthReportResult> uploadSoilReportImage({
    required File imageFile,
    String? crop,
    String languageId = 'en',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/soil/analyze-card-image');
    final request = http.MultipartRequest('POST', uri);

    request.fields['languageId'] = languageId;
    if (crop != null && crop.isNotEmpty) {
      request.fields['crop'] = crop;
    }

    final fileBytes = await imageFile.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      fileBytes,
      filename: 'soil_report.jpg',
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return SoilHealthReportResult.fromJson(data);
    } else {
      throw Exception('Failed to analyze soil card image. Server error: ${response.statusCode}');
    }
  }

  SoilSamplingGuide _getLocalSamplingGuide(String languageId) {
    if (languageId == 'te') {
      return SoilSamplingGuide(
        title: 'మట్టి నమూనా సేకరణ సమగ్ర మార్గదర్శి',
        importance: 'మట్టి పరీక్ష ద్వారా నేలలోని పోషకాలు, pH విలువ, కర్బనాన్ని గుర్తించి అనవసర ఎరువుల ఖర్చు తగ్గించుకోవచ్చు.',
        bestTiming: 'విత్తనాలు వేయడానికి 1 నెల ముందు లేదా పంట కోత తర్వాత సేకరించాలి.',
        steps: [
          SoilGuideStep(
            stepNumber: 1,
            title: 'పొలంలో గుర్తులు పెట్టడం (Zig-Zag పద్ధతి)',
            description: 'పొలమంతా జిగ్-జాగ్ మార్గంలో ఎకరాకు 8-10 చోట్ల స్థలాలు ఎంపిక చేయండి. గట్లు, కాలువలు, చెట్ల నీడను వదిలివేయండి.',
            icon: 'map',
            tips: ['గట్ల నుండి 2-3 మీటర్ల లోపలికి ఉండాలి', 'చెట్ల కింద నమూనా తీయవద్దు'],
          ),
          SoilGuideStep(
            stepNumber: 2,
            title: 'ఉపరితల శుభ్రత',
            description: 'పైనున్న గడ్డి, చెత్తాచెదారాన్ని తేలికగా పారతో తొలగించండి.',
            icon: 'cleaning_services',
            tips: ['మట్టిని లోతుగా తవ్వవద్దు, పై చెత్తను మాత్రమే తీయండి'],
          ),
          SoilGuideStep(
            stepNumber: 3,
            title: "'V' ఆకారంలో గుంత తవ్వడం (15 సెం.మీ)",
            description: "పారతో 15 సెం.మీ (6 అంగుళాలు) లోతు వరకు 'V' ఆకారంలో గుంత తీయండి.",
            icon: 'content_cut',
            tips: ['సాధారణ పంటలకు 15 సెం.మీ, తోటలకు 30-60 సెం.మీ అవసరం'],
          ),
          SoilGuideStep(
            stepNumber: 4,
            title: 'మట్టి పొరను సేకరించడం',
            description: "'V' గుంత పక్క అంచు నుండి పైనుంచి కిందవరకు 1-2 సెం.మీ మందం గీకి ప్లాస్టిక్ బకెట్ లో వేయండి.",
            icon: 'layers',
            tips: ['శుభ్రమైన ప్లాస్టిక్ బకెట్ వాడండి'],
          ),
          SoilGuideStep(
            stepNumber: 5,
            title: 'కలపడం & పావు భాగం (Quartering)',
            description: 'సేకరించిన మట్టిని బాగా కలిపి, గుండ్రంగా చేసి 4 భాగాలుగా విభజించండి. అర కిలో (500 గ్రాములు) మిగిలేవరకు ఎదురెదురు భాగాలు తీసివేయండి.',
            icon: 'pie_chart',
            tips: ['500 గ్రాముల నమూనా సరిపోతుంది', 'రాళ్ళు, వేర్లు తొలగించండి'],
          ),
          SoilGuideStep(
            stepNumber: 6,
            title: 'నీడలో ఆరబెట్టడం & లేబుల్',
            description: 'నీడలో ఆరబెట్టి, పాలిథీన్ లేదా బట్ట సంచిలో పోసి రైతు పేరు, సర్వే నంబర్, పంట వివరాలు వేసి ల్యాబ్‌కు పంపండి.',
            icon: 'label',
            tips: ['ఎండలో ఆరబెట్టవద్దు', 'రైతు భరోసా కేంద్రం (RBK) లేదా ల్యాబ్‌కు ఇవ్వండి'],
          ),
        ],
        dos: [
          'ఎకరాకు 8-10 ప్రదేశాల నుండి సేకరించండి',
          'ప్లాస్టిక్ బకెట్ & శుభ్రమైన సంచి వాడండి',
          'వివరాల చీటీ తప్పనిసరిగా వేయండి',
        ],
        donts: [
          'ఎరువులు వేసిన వెంటనే నమూనా తీయవద్దు',
          'రసాయన సంచులలో మట్టి నింపవద్దు',
          'ఎండలో ఆరబెట్టవద్దు',
        ],
      );
    }

    if (languageId == 'ta') {
      return SoilSamplingGuide(
        title: 'மண் மாதிரி சேகரிப்பு முழுமையான வழிகாட்டி',
        importance: 'மண் பரிசோதனை மூலம் உங்கள் நிலத்தின் pH அளவு, ஊட்டச்சத்துக்களை அறிந்து சரியான உரங்களை பயன்படுத்தி செலவை குறைக்கலாம்.',
        bestTiming: 'விதைப்பதற்கு 1 மாதத்திற்கு முன்போ அல்லது அறுவடை முடிந்த உடனோ மாதிரிகள் சேகரிக்க வேண்டும்.',
        steps: [
          SoilGuideStep(
            stepNumber: 1,
            title: 'மாதிரி இடங்களை தேர்வு செய்தல் (Zig-Zag முறை)',
            description: 'வயல் முழுவதும் ஒரே நேர்கோட்டில் எடுக்காமல் ஜிக்-ஜாக் முறையில் நடந்து ஏக்கருக்கு 8-10 இடங்களில் புள்ளிகளை தேர்வு செய்யவும்.',
            icon: 'map',
            tips: ['வரப்புகளிலிருந்து 2-3 மீட்டர் தள்ளி எடுக்கவும்', 'மரங்களின் நிழல் மற்றும் எரு குவியல்களை தவிர்க்கவும்'],
          ),
          SoilGuideStep(
            stepNumber: 2,
            title: 'மேற்பரப்பை சுத்தம் செய்தல்',
            description: 'தேர்வு செய்த இடத்தில் உள்ள காய்ந்த இலைகள், புல் மற்றும் குப்பைகளை கத்தியால் லேசாக அகற்றவும்.',
            icon: 'cleaning_services',
            tips: ['மேல்புறத்தில் 1-2 செ.மீ குப்பைகளை மட்டும் அகற்றவும், மண்ணை தோண்ட வேண்டாம்'],
          ),
          SoilGuideStep(
            stepNumber: 3,
            title: "'V' வடிவ குழி தோண்டுதல் (15 செ.மீ ஆழம்)",
            description: "மண்வெட்டியால் 15 செ.மீ (6 அங்குலம்) ஆழத்திற்கு 'V' வடிவில் குழி தோண்டவும். பழத்தோட்டங்களுக்கு 30-60 செ.மீ ஆழம் தேவை.",
            icon: 'content_cut',
            tips: ['நெல், பருத்தி, காய்கறி பயிர்களுக்கு 15 செ.மீ போதுமானது'],
          ),
          SoilGuideStep(
            stepNumber: 4,
            title: 'மண் படலத்தை சேகரித்தல்',
            description: "'V' வடிவ குழியின் ஒரு பக்க சுவரிலிருந்து மேலிருந்து கீழ் வரை 1-2 செ.மீ தடிமனில் மண் அடுக்கை சீவி பிளாஸ்டிக் வாளியில் போடவும்.",
            icon: 'layers',
            tips: ['சுத்தமான பிளாஸ்டிக் வாளி பயன்படுத்தவும்'],
          ),
          SoilGuideStep(
            stepNumber: 5,
            title: 'நன்கு கலக்குதல் & கால் பகுதி முறை (Quartering)',
            description: 'அனைத்து இடங்களில் எடுத்த மண்ணை நன்கு கலந்து 4 பகுதிகளாக பிரித்து, எதிர் இரண்டு பகுதிகளை நீக்கவும். 500 கிராம் மிஞ்சும் வரை இதை செய்யவும்.',
            icon: 'pie_chart',
            tips: ['இறுதி மாதிரி அரை கிலோ (500 கிராம்) இருக்க வேண்டும்', 'கற்கள், வேர்களை அகற்றிவிடவும்'],
          ),
          SoilGuideStep(
            stepNumber: 6,
            title: 'நிழலில் உலர்த்துதல் & லேபிளிடுதல்',
            description: 'மண்ணை நிழலில் உலர்த்தி சுத்தமான துணி அல்லது பாலித்தீன் பையில் போட்டு விவசாயி பெயர், புல எண், பயிர் விவரம் எழுதி லேப்-க்கு அனுப்பவும்.',
            icon: 'label',
            tips: ['நேரடி வெயிலில் உலர்த்த வேண்டாம்', 'அருகிலுள்ள மண் பரிசோதனை ஆய்வகத்திற்கு அனுப்பவும்'],
          ),
        ],
        dos: [
          'ஏக்கருக்கு 8-10 இடங்களில் மாதிரி எடுக்கவும்',
          'சுத்தமான பிளாஸ்டிக் வாளி மற்றும் பையை பயன்படுத்தவும்',
          'விவர சீட்டை பையுடன் இணைக்கவும்',
        ],
        donts: [
          'உரமிட்ட உடனே மண் மாதிரி எடுக்கக்கூடாது',
          'பழைய உர அல்லது பூச்சிக்கொல்லி பைகளை பயன்படுத்த வேண்டாம்',
          'நேரடி வெயிலில் உலர்த்த வேண்டாம்',
        ],
      );
    }

    if (languageId == 'hi') {
      return SoilSamplingGuide(
        title: 'मृदा नमूना संग्रह संपूर्ण मार्गदर्शिका',
        importance: 'मृदा परीक्षण से आपकी मिट्टी में पोषक तत्वों, pH मान और जैविक कार्बन का सही स्तर पता चलता है, जिससे संतुलित खाद डालकर लागत घटाई जा सकती है।',
        bestTiming: 'बुवाई से 1 महीने पहले या फसल कटाई के तुरंत बाद नमूना लें।',
        steps: [
          SoilGuideStep(
            stepNumber: 1,
            title: 'नमूना स्थलों का चयन (ज़िग-ज़ैग विधि)',
            description: 'खेत में सीधे न चलकर ज़िग-ज़ैग में घूमें और प्रति एकड़ 8 से 10 स्थानों का चयन करें। मेड़ों और पेड़ों के नीचे से नमूना न लें।',
            icon: 'map',
            tips: ['मेड़ से कम से कम 2-3 मीटर की दूरी रखें', 'खाद के गड्ढे या पेड़ों के नीचे से नमूना न लें'],
          ),
          SoilGuideStep(
            stepNumber: 2,
            title: 'सतह की सफाई',
            description: 'चिह्नित स्थान से घास-फूस, खरपतवार और सूखे कचरे को खुरपी से धीरे से हटा दें।',
            icon: 'cleaning_services',
            tips: ['केवल 1-2 सेमी ऊपरी कचरा हटाएं, मिट्टी को न खोदें'],
          ),
          SoilGuideStep(
            stepNumber: 3,
            title: "'V' आकार का गड्ढा खोदना (15 सेमी गहराई)",
            description: "खुरपी या फावड़े से 15 सेमी (लगभग 6 इंच) गहरा 'V' आकार का गड्ढा बनाएं। बागवानी फसलों के लिए 30-60 सेमी गहरा गड्ढा खोदें।",
            icon: 'content_cut',
            tips: ['अनाज, कपास और सब्जियों के लिए 15 सेमी गहराई पर्याप्त है'],
          ),
          SoilGuideStep(
            stepNumber: 4,
            title: 'मिट्टी की परत खुरचना',
            description: "'V' आकार के गड्ढे की दीवार से ऊपर से नीचे तक 1-2 सेमी मोटी मिट्टी की परत खुरचकर प्लास्टिक की बाल्टी में डालें।",
            icon: 'layers',
            tips: ['लोहे के बर्तन के बजाय साफ प्लास्टिक बाल्टी का उपयोग करें'],
          ),
          SoilGuideStep(
            stepNumber: 5,
            title: 'मिश्रण और चौथाईकरण (Quartering विधि)',
            description: 'सभी स्थानों की मिट्टी को अच्छी तरह मिलाएं और 4 हिस्सों में बांटकर आमने-सामने के दो हिस्से हटा दें। जब तक 500 ग्राम मिट्टी न बचे, दोहराएं।',
            icon: 'pie_chart',
            tips: ['अंतिम नमूना 500 ग्राम होना चाहिए', 'कंकड़, पत्थर और जड़ें निकाल दें'],
          ),
          SoilGuideStep(
            stepNumber: 6,
            title: 'छाया में सुखाना और लेबल लगाना',
            description: 'नमूने को छाया में सुखाएं। कपड़े या पॉलीथीन की थैली में भरकर किसान का नाम, खसरा नंबर और फसल की जानकारी लिखकर प्रयोगशाला में भेजें।',
            icon: 'label',
            tips: ['धूप में या आग के पास न सुखाएं', 'निकटतम मृदा परीक्षण प्रयोगशाला में जमा करें'],
          ),
        ],
        dos: [
          'प्रति एकड़ 8-10 अलग-अलग स्थानों से नमूना लें',
          'साफ प्लास्टिक या कपड़े की थैली का ही उपयोग करें',
          'नमूने पर पूरी जानकारी वाला लेबल अवश्य लगाएं',
        ],
        donts: [
          'खाद या कीटनाशक डालने के तुरंत बाद नमूना न लें',
          'खाद या यूरिया की पुरानी बोरी में मिट्टी न भरें',
          'धूप में सीधे न सुखाएं',
        ],
      );
    }

    if (languageId == 'kn') {
      return SoilSamplingGuide(
        title: 'ಮಣ್ಣಿನ ಮಾದರಿ ಸಂಗ್ರಹಣೆ ಹಂತ-ಹಂತದ ಮಾರ್ಗದರ್ಶಿ',
        importance: 'ಮಣ್ಣು ಪರೀಕ್ಷೆಯು ನಿಖರವಾದ NPK ಮಟ್ಟಗಳು, pH ಮತ್ತು ಸೂಕ್ಷ್ಮ ಪೋಷಕಾಂಶಗಳನ್ನು ತಿಳಿಸುತ್ತದೆ, ಇದರಿಂದ ಅನಗತ್ಯ ಗೊಬ್ಬರದ ವೆಚ್ಚವನ್ನು ತಪ್ಪಿಸಬಹುದು ಮತ್ತು ಇಳುವರಿಯನ್ನು ಹೆಚ್ಚಿಸಬಹುದು.',
        bestTiming: 'ಬಿತ್ತನೆಗೆ 1 ತಿಂಗಳ ಮೊದಲು ಅಥವಾ ಕೊಯ್ಲಿನ ನಂತರ ಮಾದರಿಗಳನ್ನು ಸಂಗ್ರಹಿಸಿ.',
        steps: [
          SoilGuideStep(
            stepNumber: 1,
            title: 'ಮಾದರಿ ಸ್ಥಳಗಳನ್ನು ಗುರುತಿಸಿ (ಜಿಗ್-ಜಾಗ್ ವಿಧಾನ)',
            description: 'ಜಿಗ್-ಜಾಗ್ ಮಾದರಿಯಲ್ಲಿ ನಡೆದು ಎಕರೆಗೆ 8-10 ಸಮಾನ ಸ್ಥಳಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ. ಬದುಗಳು, ಕಾಲುವೆಗಳು ಮತ್ತು ಮರದ ನೆರಳುಗಳನ್ನು ತಪ್ಪಿಸಿ.',
            icon: 'map',
            tips: ['ಗಡಿಗಳಿಂದ 2-3 ಮೀಟರ್ ದೂರವಿರಿ', 'ಗೊಬ್ಬರದ ಗುಂಡಿಗಳ ಬಳಿಯ ಸ್ಥಳಗಳನ್ನು ತಪ್ಪಿಸಿ'],
          ),
          SoilGuideStep(
            stepNumber: 2,
            title: 'ಮೇಲ್ಮೈ ಸ್ವಚ್ಛಗೊಳಿಸುವಿಕೆ',
            description: 'ಮಣ್ಣಿನ ಮೇಲ್ಮೈಯಿಂದ ಕಳೆಗಳು, ಕಸ ಮತ್ತು ಒಣ ಎಲೆಗಳನ್ನು ನಿಧಾನವಾಗಿ ತೆಗೆಯಿರಿ.',
            icon: 'cleaning_services',
            tips: ['ಮೇಲ್ಮಣ್ಣನ್ನು ತೆಗೆಯಬೇಡಿ, ಕೇವಲ ಕಸವನ್ನು ತೆಗೆಯಿರಿ'],
          ),
          SoilGuideStep(
            stepNumber: 3,
            title: "'V' ಆಕಾರದ ಗುಂಡಿ ತೋಡಿ (15 ಸೆಂ.ಮೀ ಆಳ)",
            description: "ಬೆಳೆಗಳಿಗೆ 15 ಸೆಂ.ಮೀ ಆಳದ 'V' ಆಕಾರದ ಗುಂಡಿ ತೋಡಿ (ಹಣ್ಣಿನ ತೋಟಗಳಿಗೆ 30-60 ಸೆಂ.ಮೀ).",
            icon: 'content_cut',
            tips: ['ಧಾನ್ಯ, ಹತ್ತಿ ಮತ್ತು ತರಕಾರಿಗಳಿಗೆ 15 ಸೆಂ.ಮೀ ಆಳ ಸಾಕು'],
          ),
          SoilGuideStep(
            stepNumber: 4,
            title: '1-2 ಸೆಂ.ಮೀ ಮಣ್ಣಿನ ಪದರವನ್ನು ಕತ್ತರಿಸಿ',
            description: "'V' ಗುಂಡಿಯ ಬದಿಯಿಂದ ಮೇಲಿನಿಂದ ಕೆಳಕ್ಕೆ 1-2 ಸೆಂ.ಮೀ ದಪ್ಪದ ಮಣ್ಣಿನ ಪದರವನ್ನು ಪ್ಲಾಸ್ಟಿಕ್ ಪಾತ್ರೆಗೆ ತೆಗೆದುಕೊಳ್ಳಿ.",
            icon: 'layers',
            tips: ['ಸ್ವಚ್ಛವಾದ ಪ್ಲಾಸ್ಟಿಕ್ ಬಕೆಟ್ ಬಳಸಿ'],
          ),
          SoilGuideStep(
            stepNumber: 5,
            title: 'ಮಿಶ್ರಣ ಮತ್ತು ನಾಲ್ಕು ಭಾಗ ಮಾಡುವ ವಿಧಾನ',
            description: 'ಎಲ್ಲಾ ಸ್ಥಳಗಳ ಮಣ್ಣನ್ನು ಚೆನ್ನಾಗಿ ಬೆರೆಸಿ. ವೃತ್ತಾಕಾರದಲ್ಲಿ ಹರಡಿ, 4 ಭಾಗ ಮಾಡಿ, 500 ಗ್ರಾಂ ಉಳಿಯುವವರೆಗೆ ಎದುರು ಭಾಗಗಳನ್ನು ತೆಗೆಯಿರಿ.',
            icon: 'pie_chart',
            tips: ['ಕಲ್ಲುಗಳು ಮತ್ತು ಬೇರುಗಳನ್ನು ತೆಗೆದುಹಾಕಿ', '500 ಗ್ರಾಂ ಒಟ್ಟು ಮಾದರಿ ಸಾಕು'],
          ),
          SoilGuideStep(
            stepNumber: 6,
            title: 'ನೆರಳಿನಲ್ಲಿ ಒಣಗಿಸುವುದು ಮತ್ತು ಲೇಬಲಿಂಗ್',
            description: 'ನೆರಳಿನಲ್ಲಿ ಒಣಗಿಸಿ. ರೈತರ ಹೆಸರು, ಸರ್ವೆ ನಂಬರ್ ಮತ್ತು ಬೆಳೆ ವಿವರಗಳ ಲೇಬಲ್‌ನೊಂದಿಗೆ ಚೀಲದಲ್ಲಿ ಪ್ಯಾಕ್ ಮಾಡಿ.',
            icon: 'label',
            tips: ['ನೇರ ಬಿಸಿಲಿನಲ್ಲಿ ಒಣಗಿಸಬೇಡಿ', 'ಹತ್ತಿರದ ಮಣ್ಣು ಪರೀಕ್ಷಾ ಕೇಂದ್ರಕ್ಕೆ ನೀಡಿ'],
          ),
        ],
        dos: [
          'ಎಕರೆಗೆ 8-10 ಸ್ಥಳಗಳಿಂದ ಮಾದರಿ ತೆಗೆದುಕೊಳ್ಳಿ',
          'ಸ್ವಚ್ಛ ಪ್ಲಾಸ್ಟಿಕ್ ಅಥವಾ ಬಟ್ಟೆ ಚೀಲ ಬಳಸಿ',
          'ಚೀಲದ ಮೇಲೆ ಸಂಪೂರ್ಣ ವಿವರಗಳ ಚೀಟಿ ಇರಿಸಿ',
        ],
        donts: [
          'ಗೊಬ್ಬರ ಹಾಕಿದ ತಕ್ಷಣ ಮಾದರಿ ತೆಗೆಯಬೇಡಿ',
          'ಹಳೆಯ ಗೊಬ್ಬರದ ಚೀಲ ಬಳಸಬೇಡಿ',
          'ನೇರ ಬಿಸಿಲಿನಲ್ಲಿ ಒಣಗಿಸಬೇಡಿ',
        ],
      );
    }

    if (languageId == 'ml') {
      return SoilSamplingGuide(
        title: 'മണ്ണ് സാമ്പിൾ ശേഖരണ സമ്പൂർണ്ണ മാർഗ്ഗരേഖ',
        importance: 'മണ്ണ് പരിശോധനയിലൂടെ കൃത്യമായ വളപ്രയോഗം നടത്തി ചെലവ് കുറയ്ക്കാനും വിളവ് വർദ്ധിപ്പിക്കാനും സാധിക്കും.',
        bestTiming: 'വിത്ത് വിതയ്ക്കുന്നതിന് 1 മാസം മുമ്പോ വിളവെടുപ്പിന് ശേഷമോ സാമ്പിൾ എടുക്കുക.',
        steps: [
          SoilGuideStep(stepNumber: 1, title: 'സാമ്പിൾ സ്ഥലങ്ങൾ കണ്ടെത്തുക (സിഗ്-സാഗ് രീതി)', description: 'പാടത്ത് സിഗ്-സാഗ് രീതിയിൽ നടന്ന് ഏക്കറിന് 8-10 സ്ഥലങ്ങൾ തിരഞ്ഞെടുക്കുക.', icon: 'map', tips: ['വരമ്പുകളിൽ നിന്ന് 2-3 മീറ്റർ മാറുക']),
          SoilGuideStep(stepNumber: 2, title: 'ഉപരിതലം വൃത്തിയാക്കൽ', description: 'പുല്ലും കരിയിലകളും ശ്രദ്ധയോടെ മാറ്റുക.', icon: 'cleaning_services', tips: ['മേൽമണ്ണ് മാറ്റരുത്']),
          SoilGuideStep(stepNumber: 3, title: "'V' ആകൃതിയിൽ കുഴിയെടുക്കൽ", description: "15 സെ.മീ ആഴത്തിൽ 'V' ആകൃതിയിൽ കുഴിയെടുക്കുക.", icon: 'content_cut', tips: ['15 സെ.മീ ആഴം അനുയോജ്യമാണ്']),
          SoilGuideStep(stepNumber: 4, title: 'മണ്ണ് പാളി ചുരണ്ടി എടുക്കൽ', description: "കുഴിയുടെ വശങ്ങളിൽ നിന്ന് 1-2 സെ.മീ കനത്തിൽ മണ്ണ് ചുരണ്ടി എടുക്കുക.", icon: 'layers', tips: ['പ്ലാസ്റ്റിക് പാത്രം ഉപയോഗിക്കുക']),
          SoilGuideStep(stepNumber: 5, title: 'നന്നായി ഇളക്കി നാലായി ഭാഗിക്കൽ', description: 'മണ്ണ് നന്നായി ഇളക്കി 500 ഗ്രാം ആകുന്നത് വരെ എതിർഭാഗങ്ങൾ ഒഴിവാക്കുക.', icon: 'pie_chart', tips: ['കല്ലുകളും വേരുകളും മാറ്റുക']),
          SoilGuideStep(stepNumber: 6, title: 'തണലിൽ ഉಣക്കലും ലേബൽ ഒട്ടിക്കലും', description: 'തണലിൽ ഉണക്കി കർഷകന്റെ വിവരങ്ങൾ എഴുതി ലാബിൽ എത്തിക്കുക.', icon: 'label', tips: ['വെയിലിൽ വെച്ച് ഉണക്കരുത്']),
        ],
        dos: ['ഏക്കറിന് 8-10 സ്ഥലങ്ങളിൽ നിന്ന് സാമ്പിൾ എടുക്കുക'],
        donts: ['രാസവളം ഇട്ട ഉടനെ സാമ്പിൾ എടുക്കരുത്'],
      );
    }

    if (languageId == 'mr') {
      return SoilSamplingGuide(
        title: 'माती नमुना संकलन संपूर्ण मार्गदर्शिका',
        importance: 'माती परीक्षणामुळे अचूक खत व्यवस्थापन करता येते व उत्पादन वाढवून खर्च कमी करता येतो.',
        bestTiming: 'पेरणीच्या १ महिना आधी किंवा पीक काढणीनंतर लगेच नमुने घ्यावेत.',
        steps: [
          SoilGuideStep(stepNumber: 1, title: 'नमुना जागांची निवड (झिग-झॅग पद्धत)', description: 'शेतभर झिग-झॅग फिरून एकरी ८ ते १० ठिकाणे निवडा.', icon: 'map', tips: ['बांधापासून २-३ मीटर लांब नमुना घ्या']),
          SoilGuideStep(stepNumber: 2, title: 'पृष्ठभाग स्वच्छ करणे', description: 'गवत आणि पालापाचोळा बाजूला करा.', icon: 'cleaning_services', tips: ['माती खणू नका']),
          SoilGuideStep(stepNumber: 3, title: "'V' आकाराचा खड्डा करणे", description: "१५ सेमी खोलीचा 'V' आकाराचा खड्डा करा.", icon: 'content_cut', tips: ['१५ सेमी खोली पुरेशी आहे']),
          SoilGuideStep(stepNumber: 4, title: 'मातीचा थर खरवडणे', description: 'खड्ड्याच्या बाजूने १-२ सेमी जाडीचा थर खरवडून बादलीत घ्या.', icon: 'layers', tips: ['स्वच्छ प्लास्टिक बादली वापरा']),
          SoilGuideStep(stepNumber: 5, title: 'मिश्रण आणि चार भाग करणे', description: 'माती एकत्र करून ५०० ग्रॅम उरेपर्यंत चार भाग पद्धत करा.', icon: 'pie_chart', tips: ['दगड व मुळे काढून टाका']),
          SoilGuideStep(stepNumber: 6, title: 'सावलीजवळ वाळवणे आणि लेबल लावणे', description: 'माती सावलीत वाळवून शेतकऱ्याच्या माहितीसह प्रयोगशाळेत पाठवा.', icon: 'label', tips: ['उन्हात वाळवू नका']),
        ],
        dos: ['एकरी ८-१० वेगवेगळ्या ठिकाणांवरून नमुने घ्या'],
        donts: ['खत टाकल्यावर लगेच नमुना घेऊ नका'],
      );
    }

    if (languageId == 'bn') {
      return SoilSamplingGuide(
        title: 'মাটির নমুনা সংগ্রহ সম্পূর্ণ নির্দেশিকা',
        importance: 'মাটি পরীক্ষার মাধ্যমে সুষম সার প্রয়োগ করে খরচ কমানো ও উৎপাদন বাড়ানো যায়।',
        bestTiming: 'বপনের ১ মাস আগে বা ফসল কাটার পরপরই নমুনা সংগ্রহ করুন।',
        steps: [
          SoilGuideStep(stepNumber: 1, title: 'নমুনার স্থান নির্বাচন (জিগ-জ্যাগ পদ্ধতি)', description: 'জমিতে জিগ-জ্যাগ পদ্ধতিতে ঘুরে প্রতি একরে ৮ থেকে ১০টি স্থান নির্বাচন করুন।', icon: 'map', tips: ['আইল থেকে ২-৩ মিটার দূরে নমুনা নিন']),
          SoilGuideStep(stepNumber: 2, title: 'উপরিভাগ পরিষ্কার করা', description: 'ঘাস ও শুকনো পাতা হালকাভাবে সরিয়ে ফেলুন।', icon: 'cleaning_services', tips: ['মাটি খুঁড়বেন না']),
          SoilGuideStep(stepNumber: 3, title: "'V' আকৃতির গর্ত তৈরি", description: "১৫ সেমি গভীর 'V' আকৃতির গর্ত করুন।", icon: 'content_cut', tips: ['১৫ সেমি গভীরতা যথেষ্ট']),
          SoilGuideStep(stepNumber: 4, title: 'মাটির স্তর চাঁছা', description: 'গর্তের ধার থেকে ১-২ সেমি পুরু মাটির স্তর কেটে বালতিতে নিন।', icon: 'layers', tips: ['প্লাস্টিক বালতি ব্যবহার করুন']),
          SoilGuideStep(stepNumber: 5, title: 'মিশ্রণ ও চার ভাগে ভাগ', description: 'মাটি মিশিয়ে ৫০০ গ্রাম অবশিষ্ট থাকা পর্যন্ত চার ভাগ পদ্ধতি করুন।', icon: 'pie_chart', tips: ['পাথর ও শিকড় সরিয়ে ফেলুন']),
          SoilGuideStep(stepNumber: 6, title: 'ছায়ায় শুকানো এবং লেবেল লাগানো', description: 'ছায়ায় শুকিয়ে তথ্যসহ থলিতে ভরে ল্যাবে পাঠান।', icon: 'label', tips: ['রোদে শুকাবেন না']),
        ],
        dos: ['প্রতি একরে ৮-১০টি জায়গা থেকে নমুনা নিন'],
        donts: ['সার দেওয়ার পরপরই নমুনা নেবেন না'],
      );
    }

    if (languageId == 'gu') {
      return SoilSamplingGuide(
        title: 'જમીન નમૂના સંગ્રહ સંપૂર્ણ માર્ગદર્શિકા',
        importance: 'જમીન ચકાસણી દ્વારા સંતુલિત ખાતર વાપરી ખર્ચ ઘટાડી ઉત્પાદન વધારી શકાય છે.',
        bestTiming: 'વાવણીના ૧ મહિના પહેલાં અથવા પાકની કાપણી પછી તરત જ નમૂનો લેવો.',
        steps: [
          SoilGuideStep(stepNumber: 1, title: 'નમૂના સ્થળોની પસંદગી (ઝિગ-ઝેગ પદ્ધતિ)', description: 'ખેતરમાં ઝિગ-ઝેગ ફરીને એકર દીઠ ૮ થી ૧૦ સ્થળો પસંદ કરો.', icon: 'map', tips: ['શેઢાથી ૨-೩ મીટર દૂર રહો']),
          SoilGuideStep(stepNumber: 2, title: 'સપાટીની સફાઈ', description: 'સૂકાં પાંદડાં અને કચરો હળવેથી દૂર કરો.', icon: 'cleaning_services', tips: ['જમીન ખોદશો નહીં']),
          SoilGuideStep(stepNumber: 3, title: "'V' આકારનો ખાડો કરવો", description: "૧૫ સેમી ઊંડો 'V' આકારનો ખાડો કરો.", icon: 'content_cut', tips: ['૧૫ સેમી ઊંડાઈ પૂરતી છે']),
          SoilGuideStep(stepNumber: 4, title: 'માટીનું સ્તર ઉતારવું', description: 'ખાડાની દીવાલ પરથી ૧-૨ સેમી જાડું સ્તર ડોલમાં લો.', icon: 'layers', tips: ['પ્લાસ્ટિક ડોલ વાપરો']),
          SoilGuideStep(stepNumber: 5, title: 'મિશ્રણ અને ચાર ભાગ કરવાની રીત', description: '૫૦૦ ગ્રામ વધે ત્યાં સુધી ચાર ભાગ પદ્ધતિ કરો.', icon: 'pie_chart', tips: ['કાંકરા અને મૂળિયાં દૂર કરો']),
          SoilGuideStep(stepNumber: 6, title: 'છાંયડે સૂકવવું અને લેબલ લગાવવું', description: 'છાંયડે સૂકવી વિગત લખી લેબમાં મોકલો.', icon: 'label', tips: ['તડકામાં ન સૂકવવી']),
        ],
        dos: ['એકર દીઠ ૮-૧૦ સ્થળોએથી નમૂનો લો'],
        donts: ['ખાતર આપ્યા પછી તરત નમૂનો ન લો'],
      );
    }

    if (languageId == 'pa') {
      return SoilSamplingGuide(
        title: 'ਮਿੱਟੀ ਪਰਖ ਨਮੂਨਾ ਇਕੱਤਰ ਕਰਨ ਦੀ ਪੂਰੀ ਗਾਈਡ',
        importance: 'ਮਿੱਟੀ ਪਰਖ ਕਰਵਾਉਣ ਨਾਲ ਸੰਤੁਲਿਤ ਖਾਦ ਪਾ ਕੇ ਖਰਚਾ ਘਟਾਇਆ ਜਾ ਸਕਦਾ ਹੈ।',
        bestTiming: 'ਬਿਜਾਈ ਤੋਂ 1 ਮਹੀਨਾ ਪਹਿਲਾਂ ਜਾਂ ਫ਼ਸਲ ਦੀ ਕਟਾਈ ਤੋਂ ਤੁਰੰਤ ਬਾਅਦ ਨਮੂਨਾ ਲਵੋ।',
        steps: [
          SoilGuideStep(stepNumber: 1, title: 'ਨਮੂਨੇ ਵਾਲੀਆਂ ਥਾਵਾਂ ਦੀ ਚੋਣ (ਜ਼ਿਗ-ਜ਼ੈਗ ਤਰੀਕਾ)', description: 'ਖੇਤ ਵਿੱਚ ਜ਼ਿਗ-ਜ਼ੈਗ ਤਰੀਕੇ ਨਾਲ ਪ੍ਰਤੀ ਏਕੜ 8 ਤੋਂ 10 ਥਾਵਾਂ ਚੁਣੋ।', icon: 'map', tips: ['ਵੱਟ ਤੋਂ 2-3 ਮੀਟਰ ਦੂਰੀ ਰੱਖੋ']),
          SoilGuideStep(stepNumber: 2, title: 'ਸਤ੍ਹਾ ਦੀ ਸਫ਼ਾਈ', description: 'ਕੂੜਾ-ਕਰਕਟ ਖੁਰਪੀ ਨਾਲ ਸਾਫ਼ ਕਰੋ।', icon: 'cleaning_services', tips: ['ਮਿੱਟੀ ਨਾ ਪੁੱਟੋ']),
          SoilGuideStep(stepNumber: 3, title: "'V' ਅਕਾਰ ਦਾ ਟੋਆ ਪੁੱਟਣਾ", description: "15 ਸੈਂਟੀਮੀਟਰ ਡੂੰਘਾ 'V' ਅਕਾਰ ਦਾ ਟੋਆ ਪੁੱਟੋ।", icon: 'content_cut', tips: ['15 ਸੈਂਟੀਮੀਟਰ ਕਾਫ਼ੀ ਹੈ']),
          SoilGuideStep(stepNumber: 4, title: 'ਮਿੱਟੀ ਦੀ ਤਹਿ ਉਤਾਰਨਾ', description: '1-2 ਸੈਂਟੀਮੀਟਰ ਮੋਟੀ ਮਿੱਟੀ ਦੀ ਪਰਤ ਬਾਲਟੀ ਵਿੱਚ ਪਾਓ।', icon: 'layers', tips: ['ਸਾਫ਼ ਬਾਲਟੀ ਵਰਤੋ']),
          SoilGuideStep(stepNumber: 5, title: 'ਰਲਾਉਣਾ ਅਤੇ ਚੌਥਾਈ ਵਿਧੀ', description: '500 ਗ੍ਰਾਮ ਬਚਣ ਤੱਕ ਚੌਥਾਈ ਵਿਧੀ ਦੁਹਰਾਓ।', icon: 'pie_chart', tips: ['ਰੋੜੇ ਅਤੇ ਜੜ੍ਹਾਂ ਕੱਢ ਦਿਓ']),
          SoilGuideStep(stepNumber: 6, title: 'ਛਾਂਵੇਂ ਸੁਕਾਉਣਾ ਅਤੇ ਲੇਬਲ ਲਗਾਉਣਾ', description: 'ਛਾਂਵੇਂ ਸੁਕਾ ਕੇ ਕਿਸਾਨ ਦੀ ਜਾਣਕਾਰੀ ਲਿਖ ਕੇ ਲੈਬ ਭੇਜੋ।', icon: 'label', tips: ['ਧੁੱਪ ਵਿੱਚ ਨਾ ਸੁਕਾਓ']),
        ],
        dos: ['ਪ੍ਰਤੀ ਏਕੜ 8-10 ਥਾਵਾਂ ਤੋਂ ਨਮੂਨਾ ਲਵੋ'],
        donts: ['ਖਾਦ ਪਾਉਣ ਤੋਂ ਤੁਰੰਤ ਬਾਅਦ ਨਮੂਨਾ ਨਾ ਲਵੋ'],
      );
    }

    return SoilSamplingGuide(
      title: 'Step-by-Step Soil Sampling Guide',
      importance: 'Soil testing reveals exact NPK levels, pH, and micronutrients so you avoid excess fertilizer spend and boost crop yield.',
      bestTiming: 'Collect samples 1 month prior to sowing or immediately post harvest.',
      steps: [
        SoilGuideStep(
          stepNumber: 1,
          title: 'Mark Sampling Spots (Zig-Zag Pattern)',
          description: 'Walk in a zig-zag pattern and choose 8-10 uniform spots per acre. Avoid bunds, channels, and tree shadows.',
          icon: 'map',
          tips: ['Stay 2-3 meters away from boundaries', 'Avoid spots near compost pits'],
        ),
        SoilGuideStep(
          stepNumber: 2,
          title: 'Surface Cleaning',
          description: 'Gently scrape away weeds, litter, and dry foliage from the soil surface.',
          icon: 'cleaning_services',
          tips: ['Do not remove topsoil, only clear vegetation'],
        ),
        SoilGuideStep(
          stepNumber: 3,
          title: 'Dig a V-Shaped Trench (15 cm Depth)',
          description: "Dig a clean 'V'-shaped hole up to 15 cm deep for field crops (30-60 cm for orchard trees).",
          icon: 'content_cut',
          tips: ['Standard 15 cm depth is sufficient for cereal, cotton & vegetables'],
        ),
        SoilGuideStep(
          stepNumber: 4,
          title: 'Slice 1-2 cm Soil Layer',
          description: 'Shave a 1-2 cm thick slice from the side of the V-notch from top to bottom into a clean plastic tray.',
          icon: 'layers',
          tips: ['Use clean plastic buckets, never rusty iron containers'],
        ),
        SoilGuideStep(
          stepNumber: 5,
          title: 'Mix & Quartering Method',
          description: 'Blend all spots thoroughly. Spread into a circle, divide into 4 quadrants, discard opposite quarters until ~500g remains.',
          icon: 'pie_chart',
          tips: ['Remove stones, roots and foreign matter', 'Target 500 grams total sample weight'],
        ),
        SoilGuideStep(
          stepNumber: 6,
          title: 'Shade Drying & Labeling',
          description: 'Air dry in shade on clean paper. Pack in a poly-bag with a label containing Farmer Name, Field/Survey No, and Target Crop.',
          icon: 'label',
          tips: ['Never dry in direct sunlight', 'Submit to nearest Soil Testing Lab or Rythu Kendra'],
        ),
      ],
      dos: [
        'Collect 8-10 samples per acre in a zig-zag line',
        'Use clean plastic or cloth containers',
        'Label sample tag clearly with farmer details',
      ],
      donts: [
        'Never sample immediately after applying chemical fertilizers',
        'Do not use old fertilizer or pesticide bags',
        'Do not dry under direct sunlight',
      ],
    );
  }

  SoilHealthReportResult _generateLocalHeuristicAnalysis({
    required String crop,
    double? ph,
    double? nitrogen,
    double? phosphorus,
    double? potassium,
    double? organicCarbon,
    String languageId = 'en',
  }) {
    if (languageId == 'te') {
      String phText = 'సాధారణం (చాలా పంటలకు అనుకూలం)';
      List<String> conditioning = [];

      if (ph != null) {
        if (ph < 6.0) {
          phText = 'ఆమ్ల నేల (pH $ph). పోషకాల గ్రహణ శక్తి తగ్గుతుంది.';
          conditioning.add('ఆమ్లత్వాన్ని తగ్గించడానికి ఎకరాకు 200-300 కిలోల వ్యవసాయ సున్నం (Calcium Carbonate) వేయండి.');
        } else if (ph > 8.0) {
          phText = 'క్షార లేదా ఉప్పు నేల (pH $ph). సూక్ష్మ పోషకాల లభ్యత తగ్గుతుంది.';
          conditioning.add('క్షారత్వాన్ని తగ్గించడానికి ఎకరాకు 400-500 కిలోల జిప్సం వేసి నీరు పెట్టండి.');
        } else {
          phText = 'సరైన pH స్థాయి ($ph). పోషకాల శోషణకు చాలా అనుకూలం.';
        }
      }

      conditioning.add('నేల సారాన్ని పెంచడానికి ఎకరాకు 4-5 టన్నుల బాగా చివికిన పశువుల ఎరువు లేదా వర్మీకంపోస్ట్ వేయండి.');

      return SoilHealthReportResult(
        overallHealth: (ph != null && (ph < 5.5 || ph > 8.5)) ? 'సవరణ అవసరం' : 'అనుకూలం',
        summary: '$crop పంటకు మట్టి విశ్లేషణ పూర్తయింది. గరిష్ట దిగుబడి కొరకు సమతుల్య ఎరువుల యాజమాన్యం పాటించండి.',
        phAnalysis: phText,
        nutrientAssessments: {
          'nitrogen': (nitrogen != null && nitrogen < 250) ? 'తక్కువ (< 250 kg/ha)' : 'సమృద్ధి',
          'phosphorus': (phosphorus != null && phosphorus < 20) ? 'తక్కువ (< 20 kg/ha)' : 'సమృద్ధి',
          'potassium': (potassium != null && potassium < 150) ? 'తక్కువ (< 150 kg/ha)' : 'సమృద్ధి',
          'organicCarbon': (organicCarbon != null && organicCarbon < 0.5) ? 'తక్కువ (< 0.5%)' : 'బాగుంది',
        },
        conditioningRecommendations: conditioning,
        fertilizerPlan: [
          'మొదటి దఫా: విత్తే సమయంలో భాస్వరం (DAP/SSP) పూర్తి మోతాదు + 50% పొటాష్ (MOP) + 25% నత్రజని',
          'రెండవ దఫా: పిలకలు తొడిగే దశలో (20-30 రోజులకు) 50% నత్రజని (యూరియా)',
          'మూడవ దఫా: పూత దశలో మిగిలిన 25% నత్రజని + 50% పొటాష్',
        ],
        suitableCrops: [crop, 'వరి', 'పత్తి', 'మొక్కజొన్న', 'వేరుశనగ', 'మిరప'],
        warningNotes: 'సూక్ష్మ పోషకాలను అధిక మోతాదులో వాడే ముందు ల్యాబ్ పరీక్ష ద్వారా నిర్ధారించుకోండి.',
      );
    }

    if (languageId == 'ta') {
      String phText = 'நடுநிலை (பெரும்பாலான பயிர்களுக்கு உகந்தது)';
      List<String> conditioning = [];

      if (ph != null) {
        if (ph < 6.0) {
          phText = 'அமில மண் (pH $ph). ஊட்டச்சத்துக்களை பயிர்கள் எடுப்பது குறையும்.';
          conditioning.add('அமிலத்தன்மையை குறைக்க ஏக்கருக்கு 200-300 கிலோ விவசாய சுண்ணாம்பு இடவும்.');
        } else if (ph > 8.0) {
          phText = 'கார/உவர் மண் (pH $ph). நுண்ணூட்டச்சத்து பற்றாக்குறை ஏற்படும்.';
          conditioning.add('காரத்தன்மையை குறைக்க ஏக்கருக்கு 400-500 கிலோ ஜிப்சம் இட்டு நீர் பாய்ச்சவும்.');
        } else {
          phText = 'சரியான pH அளவு ($ph). ஊட்டச்சத்து கிரகிப்பிற்கு சிறந்தது.';
        }
      }

      conditioning.add('மண்ணின் வளத்தை பெருக்க ஏக்கருக்கு 4-5 டன் மக்கிய தொழு உரம் அல்லது மண்புழு உரம் இடவும்.');

      return SoilHealthReportResult(
        overallHealth: (ph != null && (ph < 5.5 || ph > 8.5)) ? 'மண் சீரமைப்பு தேவை' : 'உகந்தது',
        summary: '$crop பயிருக்கான மண் பகுப்பாய்வு முடிந்தது. அதிக மகசூல் பெற சமச்சீர் உர மேலாண்மை அவசியம்.',
        phAnalysis: phText,
        nutrientAssessments: {
          'nitrogen': (nitrogen != null && nitrogen < 250) ? 'குறைவு (< 250 kg/ha)' : 'போதுமானது',
          'phosphorus': (phosphorus != null && phosphorus < 20) ? 'குறைவு (< 20 kg/ha)' : 'போதுமானது',
          'potassium': (potassium != null && potassium < 150) ? 'குறைவு (< 150 kg/ha)' : 'போதுமானது',
          'organicCarbon': (organicCarbon != null && organicCarbon < 0.5) ? 'குறைவு (< 0.5%)' : 'நன்று',
        },
        conditioningRecommendations: conditioning,
        fertilizerPlan: [
          'அடி உரம்: விதைக்கும் போது முழு மணிச்சத்து (DAP/SSP) + 50% சாம்பல் சத்து (MOP) + 25% தழைச்சத்து',
          'முதல் மேலுரம்: தூர்கட்டும் பருவத்தில் (20-30 நாட்கள்) 50% தழைச்சத்து (யூரியா)',
          'இரண்டாம் மேலுரம்: பூக்கும் பருவத்தில் மீதமுள்ள 25% தழைச்சத்து + 50% சாம்பல் சத்து',
        ],
        suitableCrops: [crop, 'நெல்', 'பருத்தி', 'மக்காச்சோளம்', 'நிலக்கடலை', 'மிளகாய்'],
        warningNotes: 'அதிக செறிவுள்ள நுண்ணூட்டச்சத்துக்களை இடுவதற்கு முன் மண் ஆய்வுக்கூட உறுதிப்படுத்தல் பெறவும்.',
      );
    }

    if (languageId == 'hi') {
      String phText = 'सामान्य (अधिकांश फसलों के लिए अनुकूल)';
      List<String> conditioning = [];

      if (ph != null) {
        if (ph < 6.0) {
          phText = 'अम्लीय मिट्टी (pH $ph)। पोषक तत्वों का अवशोषण प्रभावित हो सकता है।';
          conditioning.add('अम्लता दूर करने के लिए 200-300 किग्रा/एकड़ कृषि चूना डालें।');
        } else if (ph > 8.0) {
          phText = 'क्षारीय/लवणीय मिट्टी (pH $ph)। सूक्ष्म पोषक तत्वों की कमी हो सकती है।';
          conditioning.add('क्षारीयता कम करने हेतु 400-500 किग्रा/एकड़ जिप्सम डालें।');
        } else {
          phText = 'अनुकूल pH स्तर ($ph)। फसलों के पोषण के लिए सर्वोत्तम।';
        }
      }

      conditioning.add('मिट्टी में सूक्ष्मजीवों की सक्रियता बढ़ाने के लिए 4-5 टन/एकड़ गोबर की खाद या वर्मीकम्पोस्ट मिलाएं।');

      return SoilHealthReportResult(
        overallHealth: (ph != null && (ph < 5.5 || ph > 8.5)) ? 'सुधार आवश्यक' : 'उत्कृष्ट',
        summary: '$crop के लिए मृदा विश्लेषण पूर्ण। अधिकतम उपज हेतु संतुलित उर्वरक प्रबंधन अपनाएं।',
        phAnalysis: phText,
        nutrientAssessments: {
          'nitrogen': (nitrogen != null && nitrogen < 250) ? 'कम (< 250 kg/ha)' : 'पर्याप्त',
          'phosphorus': (phosphorus != null && phosphorus < 20) ? 'कम (< 20 kg/ha)' : 'पर्याप्त',
          'potassium': (potassium != null && potassium < 150) ? 'कम (< 150 kg/ha)' : 'पर्याप्त',
          'organicCarbon': (organicCarbon != null && organicCarbon < 0.5) ? 'कम (< 0.5%)' : 'अच्छा',
        },
        conditioningRecommendations: conditioning,
        fertilizerPlan: [
          'बुवाई के समय: फॉस्फोरस की पूरी मात्रा (DAP/SSP) + 50% पोटाश (MOP) + 25% नाइट्रोजन',
          'पहला टॉप ड्रेसिंग: कल्ले फूटते समय (20-30 दिन) 50% नाइट्रोजन (यूरिया)',
          'दूसरा टॉप ड्रेसिंग: फूल / बालियां आने के समय शेष 25% नाइट्रोजन + 50% पोटाश',
        ],
        suitableCrops: [crop, 'धान', 'कपास', 'मक्का', 'मूंगफली', 'मिर्च'],
        warningNotes: 'उच्च सांद्रता वाले सूक्ष्म पोषक तत्व डालने से पहले लैब परीक्षण रिपोर्ट अवश्य जांचें।',
      );
    }

    // Default: English
    String phText = 'Neutral (Good for most crops)';
    List<String> conditioning = [];

    if (ph != null) {
      if (ph < 6.0) {
        phText = 'Acidic (pH $ph). Nutrient uptake may be restricted.';
        conditioning.add('Apply agricultural lime (calcium carbonate) at 200-300 kg/acre to neutralize acidity.');
      } else if (ph > 8.0) {
        phText = 'Alkaline/Saline (pH $ph). Micronutrient availability is reduced.';
        conditioning.add('Apply agricultural gypsum at 400-500 kg/acre to lower alkalinity and improve permeability.');
      } else {
        phText = 'Optimal pH range ($ph). Excellent for nutrient absorption.';
      }
    }

    conditioning.add('Incorporate 4-5 tonnes/acre of well-rotted FYM or Vermicompost to boost microbial activity.');

    return SoilHealthReportResult(
      overallHealth: (ph != null && (ph < 5.5 || ph > 8.5)) ? 'Needs Conditioning' : 'Optimal',
      summary: 'Soil analysis complete for $crop. Balanced nutrient management is advised for maximum yield.',
      phAnalysis: phText,
      nutrientAssessments: {
        'nitrogen': (nitrogen != null && nitrogen < 250) ? 'Low (< 250 kg/ha)' : 'Adequate',
        'phosphorus': (phosphorus != null && phosphorus < 20) ? 'Low (< 20 kg/ha)' : 'Adequate',
        'potassium': (potassium != null && potassium < 150) ? 'Low (< 150 kg/ha)' : 'Adequate',
        'organicCarbon': (organicCarbon != null && organicCarbon < 0.5) ? 'Low (< 0.5%)' : 'Good',
      },
      conditioningRecommendations: conditioning,
      fertilizerPlan: [
        'Basal Dose: Full dose of Phosphorus (DAP/SSP) + 50% Potash (MOP) + 25% Nitrogen at sowing',
        'First Top Dressing: 50% Nitrogen (Urea) at active tillering / branching stage (20-30 days)',
        'Second Top Dressing: Remaining 25% Nitrogen + 50% Potash at panicle initiation / flowering stage',
      ],
      suitableCrops: [crop, 'Rice', 'Cotton', 'Maize', 'Groundnut', 'Chilli'],
      warningNotes: 'Get lab verification before applying high concentrations of chemical micronutrients.',
    );
  }
}
