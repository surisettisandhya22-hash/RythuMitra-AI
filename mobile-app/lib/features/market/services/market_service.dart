import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/market_price.dart';
import '../../../../core/services/backend_config_service.dart';

class MarketService {
  String get _baseUrl => '${BackendConfigService.getBackendUrl()}/api/market'; 

  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

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
          if (data == null || data.isEmpty) {
            return [];
          }
          final prices = data.map((e) => MarketPrice.fromJson(e)).toList();
          
          _cache[cacheKey] = _CacheEntry(prices, DateTime.now());
          return prices;
        }
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final detail = body['detail'];
        throw Exception(detail ?? 'Market information is temporarily unavailable.');
      }
      return []; 
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Network error: Unable to connect to RythuMitra server.');
    }
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
