import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BackendConfigService {
  static const String _keyBackendUrl = 'backendUrl';
  static const String _defaultDevBackendUrl = 'http://10.10.10.10:8000';
  static const String _productionBackendUrl = 'https://rythumitra-api.onrender.com';

  static late SharedPreferences _prefs;
  static final ValueNotifier<String> backendUrlNotifier = ValueNotifier<String>(_defaultDevBackendUrl);

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    backendUrlNotifier.value = getBackendUrl();
  }

  static String getBackendUrl() {
    if (kReleaseMode) {
      return _productionBackendUrl;
    }
    return _prefs.getString(_keyBackendUrl) ?? _defaultDevBackendUrl;
  }

  static Future<void> setBackendUrl(String url) async {
    if (kReleaseMode) {
      return; // Prevent changing URL in production
    }
    
    if (url.isEmpty || !url.startsWith('http')) {
      throw const FormatException('Invalid URL format. Must start with http:// or https://');
    }
    
    // Remove trailing slash if present
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    await _prefs.setString(_keyBackendUrl, url);
    backendUrlNotifier.value = url;
  }
}
