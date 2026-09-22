import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class BackendConfigService {
  static const String _keyBackendUrl = 'backendUrl';
  static const String _defaultDevBackendUrl = 'https://rythumitra-ai-86bt.onrender.com';
  static const String _productionBackendUrl = 'https://rythumitra-ai-86bt.onrender.com';

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
    try {
      return _prefs.getString(_keyBackendUrl) ?? _productionBackendUrl;
    } catch (e) {
      // _prefs might not be initialized yet
      return _productionBackendUrl;
    }
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
