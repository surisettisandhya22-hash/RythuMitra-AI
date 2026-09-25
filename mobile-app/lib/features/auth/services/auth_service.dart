import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';

class AuthService {
  /// Sends an OTP to a given phone number or email via the backend.
  /// Returns null on success, or an error category string on failure.
  Future<String?> sendOtp(String contact) async {
    try {
      final isEmail = contact.contains('@');
      final endpoint = isEmail ? '/api/auth/request-email-otp' : '/api/auth/request-phone-otp';
      final payload = isEmail ? {'email': contact} : {'phone': contact};

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else if (response.statusCode == 404) {
        return 'ENDPOINT_NOT_FOUND';
      } else if (response.statusCode == 429) {
        return 'RATE_LIMIT_EXCEEDED';
      } else if (response.statusCode == 400) {
        return 'VALIDATION_ERROR';
      } else if (response.statusCode >= 500) {
        return 'SERVER_ERROR';
      } else {
        return 'PROVIDER_REQUEST_FAILED';
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return 'BACKEND_UNREACHABLE';
    }
  }

  /// Verifies the OTP via the backend and returns the JWT token.
  Future<String?> verifyOtp(String contact, String otp) async {
    try {
      final isEmail = contact.contains('@');
      final endpoint = isEmail ? '/api/auth/verify-email-otp' : '/api/auth/verify-phone-otp';
      final payload = isEmail ? {'email': contact, 'otp': otp} : {'phone': contact, 'otp': otp};

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['token'] as String?;
      } else {
        debugPrint('Failed to verify OTP: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return null;
    }
  }
}
