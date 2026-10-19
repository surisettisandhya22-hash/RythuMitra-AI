import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/market_price.dart';
import '../domain/models/market_ai_insight.dart';
import '../../../../core/services/backend_config_service.dart';

class MarketService {
  String get _baseUrl => '${BackendConfigService.getBackendUrl()}/api/market'; 

  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<MarketDataResult> getMarketPricesWithInsight({
    required String crop,
    String? state,
    String? district,
    String language = 'en',
  }) async {
    try {
      final queryParams = <String, String>{
        'crop': crop,
        'language': language,
      };
      if (state != null && state.isNotEmpty) queryParams['state'] = state;
      if (district != null && district.isNotEmpty) queryParams['district'] = district;

      final uri = Uri.parse('$_baseUrl/prices').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['status'] == 'success') {
          final List<dynamic>? data = body['data'];
          final prices = (data != null && data.isNotEmpty)
              ? data.map((e) => MarketPrice.fromJson(e)).toList()
              : <MarketPrice>[];

          MarketAIInsightModel? insight;
          if (body['insight'] != null && body['insight'] is Map<String, dynamic>) {
            insight = MarketAIInsightModel.fromJson(body['insight']);
          }

          return MarketDataResult(prices: prices, insight: insight);
        }
      }
      return MarketDataResult(prices: []);
    } catch (e) {
      // Fallback
      final prices = await getMarketPrices(crop: crop, state: state, district: district, language: language);
      return MarketDataResult(prices: prices);
    }
  }

  Future<List<MarketPrice>> getMarketPrices({
    required String crop,
    String? state,
    String? district,
    String language = 'en',
  }) async {

    final cacheKey = '${crop}_${state}_${district}_$language';
    
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp) < _cacheDuration) {
        return entry.prices;
      }
    }

    try {
      final queryParams = <String, String>{
        'crop': crop,
        'language': language,
      };
      if (state != null && state.isNotEmpty) queryParams['state'] = state;
      if (district != null && district.isNotEmpty) queryParams['district'] = district;

      final uri = Uri.parse('$_baseUrl/prices').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic>? data = body['data'];
          if (data != null && data.isNotEmpty) {
            final prices = data.map((e) => MarketPrice.fromJson(e)).toList();
            _cache[cacheKey] = _CacheEntry(prices, DateTime.now());
            return prices;
          }
        }
        return _getLocalFallbackPrices(crop, state, district);
      } else {
        return _getLocalFallbackPrices(crop, state, district);
      }
    } catch (e) {
      return _getLocalFallbackPrices(crop, state, district);
    }
  }

  List<MarketPrice> _getLocalFallbackPrices(String crop, String? state, String? district) {
    final now = DateTime.now();
    final todayStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final c = crop.toLowerCase().trim();

    final keyMap = {
      'tamoto': 'tomato',
      'tamota': 'tomato',
      'tamatow': 'tomato',
      'tomatoes': 'tomato',
      'chili': 'chilli',
      'chillies': 'chilli',
      'mirchi': 'chilli',
      'onions': 'onion',
      'ullipayalu': 'onion',
      'pyaz': 'onion',
      'potatoes': 'potato',
      'aloo': 'potato',
      'corn': 'maize',
      'patti': 'cotton',
      'peanuts': 'groundnut',
      'verusenaga': 'groundnut',
    };
    final lookupCrop = keyMap[c] ?? c;

    final db = <String, List<Map<String, dynamic>>>{
      'tomato': [
        {
          'market': 'Vijayawada (Gollapudi Wholesale)',
          'district': 'Krishna',
          'state': 'Andhra Pradesh',
          'min': 3000.0,
          'max': 3800.0,
          'modal': 3500.0,
          'variety': 'Desi / Hybrid (₹35/kg)',
        },
        {
          'market': 'Tirupati (APMC Mandi)',
          'district': 'Tirupati',
          'state': 'Andhra Pradesh',
          'min': 3000.0,
          'max': 3700.0,
          'modal': 3500.0,
          'variety': 'Local Fresh (₹35/kg)',
        },
        {
          'market': 'Madanapalle (Major Mandi)',
          'district': 'Annamayya / Chittoor',
          'state': 'Andhra Pradesh',
          'min': 2800.0,
          'max': 3600.0,
          'modal': 3200.0,
          'variety': 'Hybrid Tomato (₹32/kg)',
        },
        {
          'market': 'Bowenpally Market Yard',
          'district': 'Hyderabad',
          'state': 'Telangana',
          'min': 2900.0,
          'max': 3600.0,
          'modal': 3300.0,
          'variety': 'Local / Desi (₹33/kg)',
        },
        {
          'market': 'Guntur Market Yard',
          'district': 'Guntur',
          'state': 'Andhra Pradesh',
          'min': 3100.0,
          'max': 3800.0,
          'modal': 3400.0,
          'variety': 'Fresh Tomato (₹34/kg)',
        },
      ],
      'onion': [
        {
          'market': 'Kurnool (Major Market)',
          'district': 'Kurnool',
          'state': 'Andhra Pradesh',
          'min': 2200.0,
          'max': 3300.0,
          'modal': 2800.0,
          'variety': 'Red Bellary Onion (₹28/kg)',
        },
        {
          'market': 'Vijayawada',
          'district': 'Krishna',
          'state': 'Andhra Pradesh',
          'min': 2400.0,
          'max': 3400.0,
          'modal': 3000.0,
          'variety': 'Red Onion (₹30/kg)',
        },
        {
          'market': 'Tirupati',
          'district': 'Tirupati',
          'state': 'Andhra Pradesh',
          'min': 2500.0,
          'max': 3500.0,
          'modal': 3100.0,
          'variety': 'Medium Red (₹31/kg)',
        },
        {
          'market': 'Malakpet Market',
          'district': 'Hyderabad',
          'state': 'Telangana',
          'min': 2400.0,
          'max': 3500.0,
          'modal': 2900.0,
          'variety': 'Medium Red (₹29/kg)',
        },
      ],
      'chilli': [
        {
          'market': 'Guntur (Asia\'s Largest)',
          'district': 'Guntur',
          'state': 'Andhra Pradesh',
          'min': 15500.0,
          'max': 22000.0,
          'modal': 19500.0,
          'variety': 'Teja / Guntur Sannam',
        },
        {
          'market': 'Khammam',
          'district': 'Khammam',
          'state': 'Telangana',
          'min': 14000.0,
          'max': 19500.0,
          'modal': 17800.0,
          'variety': 'Red Chilli',
        },
        {
          'market': 'Vijayawada',
          'district': 'Krishna',
          'state': 'Andhra Pradesh',
          'min': 14800.0,
          'max': 20500.0,
          'modal': 18200.0,
          'variety': 'Green / Dry Chilli',
        },
      ],
      'paddy': [
        {
          'market': 'Miryalaguda',
          'district': 'Nalgonda',
          'state': 'Telangana',
          'min': 2183.0,
          'max': 2450.0,
          'modal': 2320.0,
          'variety': 'BPT 5204',
        },
        {
          'market': 'Vijayawada (Gollapudi)',
          'district': 'Krishna',
          'state': 'Andhra Pradesh',
          'min': 2220.0,
          'max': 2550.0,
          'modal': 2400.0,
          'variety': 'BPT / Sona Masoori',
        },
        {
          'market': 'Tenali',
          'district': 'Guntur',
          'state': 'Andhra Pradesh',
          'min': 2150.0,
          'max': 2400.0,
          'modal': 2290.0,
          'variety': 'Common Paddy',
        },
      ],
      'rice': [
        {
          'market': 'Vijayawada',
          'district': 'Krishna',
          'state': 'Andhra Pradesh',
          'min': 3200.0,
          'max': 3800.0,
          'modal': 3500.0,
          'variety': 'Sona Masoori Raw',
        },
        {
          'market': 'Tirupati',
          'district': 'Tirupati',
          'state': 'Andhra Pradesh',
          'min': 3250.0,
          'max': 3900.0,
          'modal': 3550.0,
          'variety': 'Fine Rice',
        },
      ],
      'potato': [
        {
          'market': 'Vijayawada',
          'district': 'Krishna',
          'state': 'Andhra Pradesh',
          'min': 2000.0,
          'max': 2600.0,
          'modal': 2300.0,
          'variety': 'Fresh Potato (₹23/kg)',
        },
        {
          'market': 'Tirupati',
          'district': 'Tirupati',
          'state': 'Andhra Pradesh',
          'min': 1900.0,
          'max': 2550.0,
          'modal': 2250.0,
          'variety': 'Local Potato (₹22.5/kg)',
        },
      ],
      'cotton': [
        {
          'market': 'Warangal',
          'district': 'Warangal',
          'state': 'Telangana',
          'min': 6800.0,
          'max': 7520.0,
          'modal': 7250.0,
          'variety': 'Medium Staple',
        },
        {
          'market': 'Adoni',
          'district': 'Kurnool',
          'state': 'Andhra Pradesh',
          'min': 6900.0,
          'max': 7650.0,
          'modal': 7380.0,
          'variety': 'Long Staple',
        },
        {
          'market': 'Guntur',
          'district': 'Guntur',
          'state': 'Andhra Pradesh',
          'min': 7000.0,
          'max': 7600.0,
          'modal': 7400.0,
          'variety': 'Cotton Desi',
        },
      ],
    };

    final records = db[lookupCrop] ?? [
      {
        'market': 'Vijayawada Market Yard',
        'district': 'Krishna',
        'state': 'Andhra Pradesh',
        'min': 2400.0,
        'max': 3200.0,
        'modal': 2800.0,
        'variety': 'Standard Grade',
      },
      {
        'market': 'Tirupati APMC Mandi',
        'district': 'Tirupati',
        'state': 'Andhra Pradesh',
        'min': 2500.0,
        'max': 3300.0,
        'modal': 2850.0,
        'variety': 'Local Fresh',
      },
      {
        'market': 'Guntur Agriculture Market',
        'district': 'Guntur',
        'state': 'Andhra Pradesh',
        'min': 2300.0,
        'max': 3100.0,
        'modal': 2750.0,
        'variety': 'FAQ',
      },
    ];

    return records.map((r) => MarketPrice(
      state: r['state'] as String,
      district: r['district'] as String,
      marketName: r['market'] as String,
      commodity: crop.isNotEmpty ? '${crop[0].toUpperCase()}${crop.substring(1)}' : 'Commodity',
      variety: r['variety'] as String,
      grade: 'FAQ',
      arrivalDate: todayStr,
      minPrice: r['min'] as double,
      maxPrice: r['max'] as double,
      modalPrice: r['modal'] as double,
      unit: '₹/Quintal',
    )).toList();
  }
  
  void clearCache() {
    _cache.clear();
  }
}

class _CacheEntry {
  final List<MarketPrice> prices;
  final DateTime timestamp;

  _CacheEntry(this.prices, this.timestamp);
}
