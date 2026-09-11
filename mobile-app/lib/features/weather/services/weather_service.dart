import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/services/backend_config_service.dart';

class WeatherService {
  String get _baseUrl => BackendConfigService.getBackendUrl();

  Future<Map<String, dynamic>> fetchWeather({double? lat, double? lon, String? locationName}) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null && lon != null) {
        queryParams['lat'] = lat.toString();
        queryParams['lon'] = lon.toString();
      }
      if (locationName != null && locationName.isNotEmpty) {
        queryParams['location'] = locationName;
      }

      final uri = Uri.parse('$_baseUrl/api/v1/weather').replace(queryParameters: queryParams);
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw Exception('Weather service is not configured correctly.');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Location not found.');
      } else {
        throw Exception('Weather service is currently unavailable.');
      }
    } on TimeoutException {
      throw Exception('Please check your internet connection.');
    } on SocketException {
      throw Exception('Weather service is currently unavailable.');
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Weather service is not configured correctly.');
    }
  }
}
