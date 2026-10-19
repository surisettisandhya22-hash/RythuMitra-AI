import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

class SupportedCrop {
  final String id;
  final String nameEn;
  final String nameTe;
  final String nameHi;
  final String category;
  final String icon;

  SupportedCrop({
    required this.id,
    required this.nameEn,
    required this.nameTe,
    required this.nameHi,
    required this.category,
    required this.icon,
  });

  factory SupportedCrop.fromJson(Map<String, dynamic> json) {
    return SupportedCrop(
      id: json['id'] ?? '',
      nameEn: json['nameEn'] ?? '',
      nameTe: json['nameTe'] ?? '',
      nameHi: json['nameHi'] ?? '',
      category: json['category'] ?? 'General',
      icon: json['icon'] ?? 'grass',
    );
  }

  String getLocalizedName(String languageCode) {
    if (languageCode == 'te' && nameTe.isNotEmpty) return nameTe;
    if (languageCode == 'hi' && nameHi.isNotEmpty) return nameHi;
    const Map<String, Map<String, String>> cropNames = {
      'paddy': {
        'ta': 'நெல் (Paddy)',
        'kn': 'ಭತ್ತ (Paddy)',
        'ml': 'നെല്ല് (Paddy)',
        'mr': 'भात / धान (Paddy)',
        'bn': 'ধান (Paddy)',
        'gu': 'ડાંગર (Paddy)',
        'pa': 'ਝੋਨਾ (Paddy)',
      },
      'cotton': {
        'ta': 'பருத்தி (Cotton)',
        'kn': 'ಹತ್ತಿ (Cotton)',
        'ml': 'പരുത്തി (Cotton)',
        'mr': 'कापूस (Cotton)',
        'bn': 'তুলা (Cotton)',
        'gu': 'કપાસ (Cotton)',
        'pa': 'ਨਰਮਾ / ਕਪਾਹ (Cotton)',
      },
      'chilli': {
        'ta': 'மிளகாய் (Chilli)',
        'kn': 'ಮೆಣಸಿನಕಾಯಿ (Chilli)',
        'ml': 'മുളക് (Chilli)',
        'mr': 'मिरची (Chilli)',
        'bn': 'লঙ্কা (Chilli)',
        'gu': 'મરચાં (Chilli)',
        'pa': 'ਮਿਰਚ (Chilli)',
      },
      'maize': {
        'ta': 'மக்காச்சோளம் (Maize)',
        'kn': 'ಮೆಕ್ಕೆಜೋಳ (Maize)',
        'ml': 'മക്കച്ചോളം (Maize)',
        'mr': 'मका (Maize)',
        'bn': 'ভুট্টা (Maize)',
        'gu': 'મકાઈ (Maize)',
        'pa': 'ਮੱਕੀ (Maize)',
      },
      'groundnut': {
        'ta': 'நிலக்கடலை (Groundnut)',
        'kn': 'ಕಡಲೆಕಾಯಿ (Groundnut)',
        'ml': 'നിലക്കടല (Groundnut)',
        'mr': 'भुईमूग (Groundnut)',
        'bn': 'চীনাবাদাম (Groundnut)',
        'gu': 'મગફળી (Groundnut)',
        'pa': 'ਮੂੰਗਫਲੀ (Groundnut)',
      },
      'sugarcane': {
        'ta': 'கரும்பு (Sugarcane)',
        'kn': 'ಕಬ್ಬು (Sugarcane)',
        'ml': 'കരിമ്പ് (Sugarcane)',
        'mr': 'ऊस (Sugarcane)',
        'bn': 'আখ (Sugarcane)',
        'gu': 'શેરડી (Sugarcane)',
        'pa': 'ਗੰਨਾ (Sugarcane)',
      },
      'tomato': {
        'ta': 'தக்காளி (Tomato)',
        'kn': 'ಟೊಮೆಟೊ (Tomato)',
        'ml': 'തക്കാളി (Tomato)',
        'mr': 'टोमॅटो (Tomato)',
        'bn': 'টমেটো (Tomato)',
        'gu': 'ટામેટા (Tomato)',
        'pa': 'ਟਮਾਟਰ (Tomato)',
      },
      'wheat': {
        'ta': 'கோதுமை (Wheat)',
        'kn': 'ಗೋಧಿ (Wheat)',
        'ml': 'ഗോതമ്പ് (Wheat)',
        'mr': 'गहू (Wheat)',
        'bn': 'গম (Wheat)',
        'gu': 'ઘઉં (Wheat)',
        'pa': 'ਕਣਕ (Wheat)',
      },
      'pulses': {
        'ta': 'துவரை / பருப்பு (Pulses)',
        'kn': 'ತೊಗರಿ / ಬೇಳೆಕಾಳುಗಳು (Pulses)',
        'ml': 'പയറുവർഗ്ഗങ്ങൾ (Pulses)',
        'mr': 'तूर / कडधान्ये (Pulses)',
        'bn': 'ডাল / অড়হর (Pulses)',
        'gu': 'તુવેર / કઠોળ (Pulses)',
        'pa': 'ਦਾਲਾਂ / ਅਰਹਰ (Pulses)',
      },
      'onion': {
        'ta': 'வெங்காயம் (Onion)',
        'kn': 'ಈರುಳ್ಳಿ (Onion)',
        'ml': 'സവാള (Onion)',
        'mr': 'कांदा (Onion)',
        'bn': 'পেঁয়াজ (Onion)',
        'gu': 'ડુંગળી (Onion)',
        'pa': 'ਪਿਆਜ਼ (Onion)',
      },
    };
    final match = cropNames[id.toLowerCase()]?[languageCode];
    if (match != null && match.isNotEmpty) return match;
    return nameEn;
  }
}

class FertilizerBagItem {
  final String name;
  final String localName;
  final String nutrientType;
  final double quantityKg;
  final double bagsCount;
  final int bagWeightKg;
  final double looseKgRemaining;
  final double estimatedPricePerBag;
  final double totalEstimatedPrice;
  final String applicationGuide;

  FertilizerBagItem({
    required this.name,
    required this.localName,
    required this.nutrientType,
    required this.quantityKg,
    required this.bagsCount,
    required this.bagWeightKg,
    required this.looseKgRemaining,
    required this.estimatedPricePerBag,
    required this.totalEstimatedPrice,
    required this.applicationGuide,
  });

  factory FertilizerBagItem.fromJson(Map<String, dynamic> json) {
    return FertilizerBagItem(
      name: json['name'] ?? '',
      localName: json['localName'] ?? '',
      nutrientType: json['nutrientType'] ?? '',
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0.0,
      bagsCount: (json['bagsCount'] as num?)?.toDouble() ?? 0.0,
      bagWeightKg: (json['bagWeightKg'] as num?)?.toInt() ?? 50,
      looseKgRemaining: (json['looseKgRemaining'] as num?)?.toDouble() ?? 0.0,
      estimatedPricePerBag: (json['estimatedPricePerBag'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedPrice: (json['totalEstimatedPrice'] as num?)?.toDouble() ?? 0.0,
      applicationGuide: json['applicationGuide'] ?? '',
    );
  }
}

class StageFertilizerDose {
  final String productName;
  final double quantityKg;
  final String bagsApprox;
  final String instruction;

  StageFertilizerDose({
    required this.productName,
    required this.quantityKg,
    required this.bagsApprox,
    required this.instruction,
  });

  factory StageFertilizerDose.fromJson(Map<String, dynamic> json) {
    return StageFertilizerDose(
      productName: json['productName'] ?? '',
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0.0,
      bagsApprox: json['bagsApprox'] ?? '',
      instruction: json['instruction'] ?? '',
    );
  }
}

class GrowthStageScheduleItem {
  final String stageName;
  final String timingDays;
  final String description;
  final List<StageFertilizerDose> fertilizers;
  final String waterPrecaution;

  GrowthStageScheduleItem({
    required this.stageName,
    required this.timingDays,
    required this.description,
    required this.fertilizers,
    required this.waterPrecaution,
  });

  factory GrowthStageScheduleItem.fromJson(Map<String, dynamic> json) {
    return GrowthStageScheduleItem(
      stageName: json['stageName'] ?? '',
      timingDays: json['timingDays'] ?? '',
      description: json['description'] ?? '',
      fertilizers: (json['fertilizers'] as List<dynamic>? ?? [])
          .map((f) => StageFertilizerDose.fromJson(f as Map<String, dynamic>))
          .toList(),
      waterPrecaution: json['waterPrecaution'] ?? '',
    );
  }
}

class OrganicAlternativeItem {
  final String name;
  final String localName;
  final String quantityPerAcre;
  final String benefits;
  final String applicationMethod;

  OrganicAlternativeItem({
    required this.name,
    required this.localName,
    required this.quantityPerAcre,
    required this.benefits,
    required this.applicationMethod,
  });

  factory OrganicAlternativeItem.fromJson(Map<String, dynamic> json) {
    return OrganicAlternativeItem(
      name: json['name'] ?? '',
      localName: json['localName'] ?? '',
      quantityPerAcre: json['quantityPerAcre'] ?? '',
      benefits: json['benefits'] ?? '',
      applicationMethod: json['applicationMethod'] ?? '',
    );
  }
}

class MicronutrientItem {
  final String nutrient;
  final String importance;
  final String recommendedProduct;
  final String dosagePerAcre;
  final String applicationTiming;

  MicronutrientItem({
    required this.nutrient,
    required this.importance,
    required this.recommendedProduct,
    required this.dosagePerAcre,
    required this.applicationTiming,
  });

  factory MicronutrientItem.fromJson(Map<String, dynamic> json) {
    return MicronutrientItem(
      nutrient: json['nutrient'] ?? '',
      importance: json['importance'] ?? '',
      recommendedProduct: json['recommendedProduct'] ?? '',
      dosagePerAcre: json['dosagePerAcre'] ?? '',
      applicationTiming: json['applicationTiming'] ?? '',
    );
  }
}

class FertilizerRecommendation {
  final String crop;
  final String cropLocalName;
  final double area;
  final String unit;
  final double areaInAcres;
  final String farmingType;
  final String summary;
  final double totalEstimatedCost;
  final List<FertilizerBagItem> primaryFertilizers;
  final List<GrowthStageScheduleItem> growthStageSchedule;
  final List<OrganicAlternativeItem> organicAlternatives;
  final List<MicronutrientItem> micronutrients;
  final List<String> bestPractices;
  final String warningNotes;

  FertilizerRecommendation({
    required this.crop,
    required this.cropLocalName,
    required this.area,
    required this.unit,
    required this.areaInAcres,
    required this.farmingType,
    required this.summary,
    required this.totalEstimatedCost,
    required this.primaryFertilizers,
    required this.growthStageSchedule,
    required this.organicAlternatives,
    required this.micronutrients,
    required this.bestPractices,
    required this.warningNotes,
  });

  factory FertilizerRecommendation.fromJson(Map<String, dynamic> json) {
    return FertilizerRecommendation(
      crop: json['crop'] ?? '',
      cropLocalName: json['cropLocalName'] ?? json['crop'] ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'Acres',
      areaInAcres: (json['areaInAcres'] as num?)?.toDouble() ?? 1.0,
      farmingType: json['farmingType'] ?? 'Integrated',
      summary: json['summary'] ?? '',
      totalEstimatedCost: (json['totalEstimatedCost'] as num?)?.toDouble() ?? 0.0,
      primaryFertilizers: (json['primaryFertilizers'] as List<dynamic>? ?? [])
          .map((item) => FertilizerBagItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      growthStageSchedule: (json['growthStageSchedule'] as List<dynamic>? ?? [])
          .map((item) => GrowthStageScheduleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      organicAlternatives: (json['organicAlternatives'] as List<dynamic>? ?? [])
          .map((item) => OrganicAlternativeItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      micronutrients: (json['micronutrients'] as List<dynamic>? ?? [])
          .map((item) => MicronutrientItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      bestPractices: List<String>.from(json['bestPractices'] ?? []),
      warningNotes: json['warningNotes'] ?? '',
    );
  }
}

class FertilizerService {
  String get _baseUrl => ApiConfig.baseUrl;

  static final List<SupportedCrop> defaultCrops = [
    SupportedCrop(id: 'paddy', nameEn: 'Rice / Paddy', nameTe: 'వరి (Paddy / Rice)', nameHi: 'धान (Paddy)', category: 'Cereals', icon: 'grass'),
    SupportedCrop(id: 'cotton', nameEn: 'Cotton', nameTe: 'ప్రత్తి (Cotton)', nameHi: 'कपास (Cotton)', category: 'Cash Crops', icon: 'local_florist'),
    SupportedCrop(id: 'chilli', nameEn: 'Chilli', nameTe: 'మిరప (Chilli)', nameHi: 'मिर्च (Chilli)', category: 'Spices / Vegetables', icon: 'eco'),
    SupportedCrop(id: 'maize', nameEn: 'Maize / Corn', nameTe: 'మొక్కజొన్న (Maize)', nameHi: 'मक्का (Maize)', category: 'Cereals', icon: 'grain'),
    SupportedCrop(id: 'groundnut', nameEn: 'Groundnut / Peanut', nameTe: 'వేరుశనగ (Groundnut)', nameHi: 'मूंगफली (Groundnut)', category: 'Oilseeds', icon: 'spa'),
    SupportedCrop(id: 'sugarcane', nameEn: 'Sugarcane', nameTe: 'చెరకు (Sugarcane)', nameHi: 'गन्ना (Sugarcane)', category: 'Cash Crops', icon: 'park'),
    SupportedCrop(id: 'tomato', nameEn: 'Tomato', nameTe: 'టమాటా (Tomato)', nameHi: 'टमाटर (Tomato)', category: 'Vegetables', icon: 'soup_kitchen'),
    SupportedCrop(id: 'wheat', nameEn: 'Wheat', nameTe: 'గోధుమ (Wheat)', nameHi: 'गेहूं (Wheat)', category: 'Cereals', icon: 'agriculture'),
    SupportedCrop(id: 'pulses', nameEn: 'Red Gram / Pulses', nameTe: 'కంది / పప్పుధాన్యాలు (Red Gram)', nameHi: 'अरहर / दालें (Red Gram)', category: 'Pulses', icon: 'spa'),
    SupportedCrop(id: 'onion', nameEn: 'Onion', nameTe: 'ఉల్లి (Onion)', nameHi: 'प्याज (Onion)', category: 'Vegetables', icon: 'circle'),
  ];

  Future<List<SupportedCrop>> fetchSupportedCrops() async {
    try {
      final url = Uri.parse('$_baseUrl/api/fertilizer/crops');
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((c) => SupportedCrop.fromJson(c as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Fetching crops error: $e. Using local defaults.');
    }
    return defaultCrops;
  }

  Future<FertilizerRecommendation> calculateFertilizerPlan({
    required String crop,
    required double area,
    String unit = 'Acres',
    String farmingType = 'Integrated',
    String? soilType,
    String languageId = 'en',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/fertilizer/calculate');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'crop': crop,
              'area': area,
              'unit': unit,
              'farmingType': farmingType,
              'soilType': soilType,
              'languageId': languageId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return FertilizerRecommendation.fromJson(data);
      }
    } catch (e) {
      debugPrint('Fertilizer calculate API error: $e. Falling back to local scientific engine.');
    }

    return _calculateLocally(crop, area, unit, farmingType, languageId);
  }

  FertilizerRecommendation _calculateLocally(
    String crop,
    double area,
    String unit,
    String farmingType,
    String languageId,
  ) {
    final bool isTelugu = languageId == 'te';
    double areaInAcres = area;
    if (unit.toLowerCase().contains('hectare')) {
      areaInAcres = area * 2.47105;
    } else if (unit.toLowerCase().contains('gunta')) {
      areaInAcres = area * 0.025;
    }

    // Baseline ICAR standards
    double dapKg = (areaInAcres * 50.0);
    double ureaKg = (areaInAcres * 90.0);
    double mopKg = (areaInAcres * 35.0);

    double dapBags = (dapKg / 50.0);
    double ureaBags = (ureaKg / 45.0);
    double mopBags = (mopKg / 50.0);

    double totalCost = (dapBags.ceil() * 1350.0) + (ureaBags.ceil() * 266.5) + (mopBags.ceil() * 1700.0);

    return FertilizerRecommendation(
      crop: crop,
      cropLocalName: isTelugu ? '$crop (శాస్త్రీయ ప్రణాళిక)' : crop,
      area: area,
      unit: unit,
      areaInAcres: double.parse(areaInAcres.toStringAsFixed(2)),
      farmingType: farmingType,
      summary: isTelugu
          ? '$area $unit $crop పంటకు అవసరమైన సమగ్ర ఎరువుల మోతాదు. మొత్తం అంచనా వ్యయం ₹${totalCost.toStringAsFixed(0)}.'
          : 'Fertilizer calculation for $area $unit of $crop. Estimated total input cost is ₹${totalCost.toStringAsFixed(0)}.',
      totalEstimatedCost: totalCost,
      primaryFertilizers: [
        FertilizerBagItem(
          name: 'DAP (Di-Ammonium Phosphate 18:46:0)',
          localName: isTelugu ? 'డి.ఎ.పి (DAP 18:46:0)' : 'DAP (18:46:0)',
          nutrientType: 'Phosphorus (P) & Starter Nitrogen',
          quantityKg: double.parse(dapKg.toStringAsFixed(1)),
          bagsCount: double.parse(dapBags.toStringAsFixed(1)),
          bagWeightKg: 50,
          looseKgRemaining: double.parse((dapKg % 50).toStringAsFixed(1)),
          estimatedPricePerBag: 1350.0,
          totalEstimatedPrice: (dapBags.ceil() * 1350.0),
          applicationGuide: isTelugu
              ? 'ఆఖరి దుక్కిలో లేదా నాటే సమయంలో వేయాలి. నేల లోపల 5-7 సెం.మీ లోతులో పడేలా చూడండి.'
              : 'Apply as basal dose during sowing/transplanting 5-7 cm below root zone.',
        ),
        FertilizerBagItem(
          name: 'Neem Coated Urea (46% N)',
          localName: isTelugu ? 'వేప పూత పూసిన యూరియా (46% N)' : 'Neem Coated Urea (46% N)',
          nutrientType: 'Nitrogen (N) - Vegetative Canopy',
          quantityKg: double.parse(ureaKg.toStringAsFixed(1)),
          bagsCount: double.parse(ureaBags.toStringAsFixed(1)),
          bagWeightKg: 45,
          looseKgRemaining: double.parse((ureaKg % 45).toStringAsFixed(1)),
          estimatedPricePerBag: 266.5,
          totalEstimatedPrice: (ureaBags.ceil() * 266.5),
          applicationGuide: isTelugu
              ? 'దఫాల వారీగా 2-3 సార్లు మాత్రమే వేయాలి. నేలలో తేమ ఉన్నప్పుడు సాయంత్రం వేళల్లో వేయండి.'
              : 'Apply strictly in 2-3 splits. Never apply all at once; broadcast in moist soil.',
        ),
        FertilizerBagItem(
          name: 'MOP (Muriate of Potash 60% K2O)',
          localName: isTelugu ? 'పొటాష్ / ఎం.ఓ.పి (MOP 60%)' : 'MOP (Muriate of Potash)',
          nutrientType: 'Potassium (K) - Disease Resistance & Grain Weight',
          quantityKg: double.parse(mopKg.toStringAsFixed(1)),
          bagsCount: double.parse(mopBags.toStringAsFixed(1)),
          bagWeightKg: 50,
          looseKgRemaining: double.parse((mopKg % 50).toStringAsFixed(1)),
          estimatedPricePerBag: 1700.0,
          totalEstimatedPrice: (mopBags.ceil() * 1700.0),
          applicationGuide: isTelugu
              ? 'కంకి బలం, గింజ నాణ్యత మరియు తెగుళ్ళ నిరోధకత కోసం వేయాలి.'
              : 'Enhances grain filling, test weight, and pest/disease resistance.',
        ),
      ],
      growthStageSchedule: [
        GrowthStageScheduleItem(
          stageName: isTelugu ? 'ఆఖరి దుక్కిలో / నాటేటప్పుడు (Basal)' : 'Basal Dose (At Sowing / Transplanting)',
          timingDays: isTelugu ? '0వ రోజు (నాటే సమయంలో)' : 'Day 0 (At Sowing)',
          description: isTelugu
              ? 'వేర్లు బలంగా నాటుకోవడానికి పూర్తి భాస్వరం మరియు సగం పొటాష్ వేయాలి.'
              : 'Apply full phosphorus and 50% potassium alongside starter nitrogen for rapid root growth.',
          fertilizers: [
            StageFertilizerDose(
              productName: isTelugu ? 'DAP' : 'DAP',
              quantityKg: dapKg,
              bagsApprox: '${dapBags.toStringAsFixed(1)} bags',
              instruction: isTelugu ? 'దుక్కిలో మట్టిలో కలిసేలా వేయాలి' : 'Incorporate into soil at plowing',
            ),
            StageFertilizerDose(
              productName: isTelugu ? 'Urea (యూరియా)' : 'Urea',
              quantityKg: double.parse((ureaKg * 0.25).toStringAsFixed(1)),
              bagsApprox: '${(ureaBags * 0.25).toStringAsFixed(1)} bags',
              instruction: isTelugu ? 'మొలకల ఎదుగుదలకు' : 'Starter vegetative dose',
            ),
          ],
          waterPrecaution: isTelugu
              ? 'నేలలో తగినంత పదును ఉండేలా చూడండి.'
              : 'Ensure adequate soil moisture; avoid water stagnation.',
        ),
        GrowthStageScheduleItem(
          stageName: isTelugu ? 'మొదటి దఫా మేత (పిలకల / శాఖీయ దశ)' : 'First Top Dressing (Vegetative / Tillering)',
          timingDays: isTelugu ? 'నాటిన 20 - 25 రోజులకు' : '20 - 25 Days After Sowing/Transplanting',
          description: isTelugu
              ? 'మొక్కలు విస్తరించి పిలకలు బాగా రావడానికి యూరియా వేయాలి.'
              : 'Top-dress nitrogen to spur strong tillering and branch formation.',
          fertilizers: [
            StageFertilizerDose(
              productName: isTelugu ? 'Urea (యూరియా)' : 'Urea',
              quantityKg: double.parse((ureaKg * 0.50).toStringAsFixed(1)),
              bagsApprox: '${(ureaBags * 0.50).toStringAsFixed(1)} bags',
              instruction: isTelugu ? 'తేమ ఉన్నప్పుడు చల్లాలి' : 'Broadcast in moist soil',
            ),
          ],
          waterPrecaution: isTelugu
              ? 'యూరియా చల్లే ముందు నీటిని తగ్గించి, 24 గంటల తర్వాత మళ్ళీ నీరు పెట్టండి.'
              : 'Drain standing water prior to broadcasting Urea; re-irrigate gently next day.',
        ),
        GrowthStageScheduleItem(
          stageName: isTelugu ? 'రెండవ దఫా మేత (పూత / చిరుపొట్ట దశ)' : 'Second Top Dressing (Panicle / Flowering)',
          timingDays: isTelugu ? 'నాటిన 45 - 55 రోజులకు' : '45 - 55 Days After Sowing/Transplanting',
          description: isTelugu
              ? 'కంకి బాగా ఏర్పడి గింజ బరువు పెరగడానికి మిగిలిన యూరియా, పొటాష్ వేయాలి.'
              : 'Sustain grain formation and reduce unfilled grains.',
          fertilizers: [
            StageFertilizerDose(
              productName: isTelugu ? 'Urea (యూరియా)' : 'Urea',
              quantityKg: double.parse((ureaKg * 0.25).toStringAsFixed(1)),
              bagsApprox: '${(ureaBags * 0.25).toStringAsFixed(1)} bags',
              instruction: isTelugu ? 'సమానంగా చల్లాలి' : 'Broadcast evenly',
            ),
            StageFertilizerDose(
              productName: isTelugu ? 'MOP (పొటాష్)' : 'MOP',
              quantityKg: mopKg,
              bagsApprox: '${mopBags.toStringAsFixed(1)} bags',
              instruction: isTelugu ? 'మొక్కల మొదళ్ల వద్ద' : 'Root zone placement',
            ),
          ],
          waterPrecaution: isTelugu
              ? 'ఈ దశలో నీటి ఎద్దడి రాకూడదు (ముఖ్యమైన దశ).'
              : 'Critical moisture stage; maintain uniform irrigation.',
        ),
      ],
      organicAlternatives: [
        OrganicAlternativeItem(
          name: 'Jeevamrutham (జీవామృతం)',
          localName: isTelugu ? 'జీవామృతం' : 'Jeevamrutham',
          quantityPerAcre: '${(200 * areaInAcres).toInt()} Liters per application',
          benefits: isTelugu
              ? 'నేలలోని సూక్ష్మజీవులను మరియు వానపాములను వేగంగా పెంచుతుంది.'
              : 'Enriches soil microbiology, improves root health and soil aeration.',
          applicationMethod: isTelugu
              ? 'ప్రతి 15 రోజులకు ఒకసారి సాగునీటితో పాటు అందించాలి.'
              : 'Apply every 15-20 days along with irrigation water.',
        ),
        OrganicAlternativeItem(
          name: 'Vermicompost (వానపాముల ఎరువు)',
          localName: isTelugu ? 'వానపాముల ఎరువు' : 'Vermicompost',
          quantityPerAcre: '${(1.5 * areaInAcres).toStringAsFixed(1)} Tonnes',
          benefits: isTelugu
              ? 'నేలలో కర్బన శాతాన్ని పెంచి, తేమను నిలుపుకునే శక్తిని ఇస్తుంది.'
              : 'Increases organic carbon, water holding capacity, and macro/micronutrients.',
          applicationMethod: isTelugu
              ? 'ఆఖరి దుక్కిలో మట్టిలో కలపాలి.'
              : 'Broadcast during final land preparation.',
        ),
      ],
      micronutrients: [
        MicronutrientItem(
          nutrient: isTelugu ? 'జింక్ సల్ఫేట్ 21%' : 'Zinc Sulphate 21%',
          importance: isTelugu
              ? 'ఆకులు తుప్పు రంగులోకి మారకుండా, ఖైరా తెగులు నివారణకు అత్యవసరం.'
              : 'Prevents zinc chlorosis and seedling stunting.',
          recommendedProduct: 'Zinc Sulphate 21%',
          dosagePerAcre: '${(10 * areaInAcres).toInt()} kg per acre',
          applicationTiming: isTelugu ? 'ఆఖరి దుక్కిలో (DAP తో కలపవద్దు)' : 'Basal soil application. Never mix with DAP.',
        ),
      ],
      bestPractices: [
        isTelugu
            ? 'ఎరువులు వేసేటప్పుడు నేలలో తగినంత తేమ (పదును) ఉండేలా చూసుకోండి.'
            : 'Always ensure optimal soil moisture when broadcasting fertilizers.',
        isTelugu
            ? 'జింక్ సల్ఫేట్ మరియు DAP ఎరువులను ఎప్పుడూ కలిపి వేయవద్దు.'
            : 'Never mix Zinc Sulphate with DAP/Phosphates as they form insoluble compounds.',
        isTelugu
            ? 'యూరియాను ఒకేసారి కాకుండా దఫాలవారీగా మాత్రమే వేయాలి.'
            : 'Apply Urea strictly in splits across vegetative and flowering stages.',
      ],
      warningNotes: isTelugu
          ? 'గమనిక: ఈ మోతాదు ICAR మార్గదర్శకాల ప్రకారం లెక్కించబడింది. మీ నేల పరీక్ష కార్డు ఆధారంగా ఖచ్చితమైన మోతాదును నిర్ణయించుకోండి.'
          : 'Note: Dosages adhere to ICAR agricultural standards. Calibrate with your Soil Health Card test values.',
    );
  }
}
